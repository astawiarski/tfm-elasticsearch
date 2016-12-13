#!/bin/env python2
# -*- coding: utf-8 -*-
"""
    curator clean is a simple script who will optimize snapshot and delete
    indices from the cluster
"""
from __future__ import print_function

import logging
import re
import sys

import curator
import elasticsearch

logging.basicConfig(stream=sys.stderr, level=logging.INFO)


def lambda_handler(event, dummy_contest):
    """
        this methode is called by lambda.
        event must contain:
        * es_endpoint: elasticsearch endpoint
        * delete_older_days: delete indices older than number (in days)
        * snapshot_older_days: snapshot indices older than number (in days)
        * repository: name of the repository
        * backup_bucket: name of the bucket to store backup in
        * backup_path: path in the bucket to store backup
        this function will exit when elasticsearch take more than 60 sec,
        to avoid having that running for long.
        The next run will continue, but this has to be run multiple time a day
    """
    logging.warning(event)

    logging.warning("connecting to elasticsearch")
    client = elasticsearch.Elasticsearch([event['es_endpoint']], timeout=120)
    curator.utils.override_timeout(client, 120)

    logging.warning("Checking for repositories")
    repo_dict = curator.utils.get_repository(
        client,
        repository=event["repository"]
    )
    if not repo_dict:
        repo_setting = {
            "repository": event["repository"],
            "client": client,
            "repo_type": "s3",
            "chunk_size": "100m",
            "bucket": event["backup_bucket"],
            "base_path": event["backup_path"]
        }
        if curator.utils.create_repository(**repo_setting):
            return "Snapshot's repository setup Failed"

    logging.warning("Prepare merging indices")
    # optimize/force merge
    ilo = curator.IndexList(client)
    ilo.filter_by_age(
        source='name',
        direction='older',
        timestring='%Y.%m.%d',
        unit='days',
        unit_count=1
    )
    fm_indices = curator.ForceMerge(ilo, max_num_segments=1)
    try:
        logging.warning("Merging indices %s", ilo.working_list())
        fm_indices.do_action()
    except elasticsearch.ConnectionTimeout:
        # exit on timeout make sure it's not running for nothing, next run will
        # continue
        logging.warning("Merge timeout, exiting")
        return "Wait for Merge"

    logging.warning("Prepare snapshoting indices")
    # snapshot
    ils = curator.IndexList(client)
    ils.filter_by_regex(kind='prefix', value='logs-')
    ils.filter_by_age(
        source='name',
        direction='older',
        timestring='%Y.%m.%d',
        unit='days',
        unit_count=int(event["snapshot_older_days"])
    )
    if len(ils.indices) > 0:
        snap_indices = curator.Snapshot(
            ils,
            name="logs_%Y-%m-%d_%H:%M:%S",
            repository=event["repository"],
            wait_for_completion=True
        )
        try:
            logging.warning("Snapshoting indices %s", ils.working_list())
            snap_indices.do_action()
        except curator.SnapshotInProgress:
            # exit on timeout make sure it's not running for nothing, next run
            # will continue
            logging.warning("Snapshot in progress")
            return "Wait for Snapshots"
        except elasticsearch.ConnectionTimeout:
            # exit on timeout make sure it's not running for nothing, next run
            # will continue
            logging.warning("Snapshot timeout, exiting")
            return "Wait for Snapshots"

    logging.warning("Prepare deleting indices")

    free_space = client.cluster.stats()["nodes"]["fs"]["free_in_bytes"] / 1024
    size_unit = {
        'M': 1024.0,
        'G': 1048576.0,
        'T': 1073741824.0
    }
    current_unit = size_unit[event['delete_when_free_space_remaining'][-1]]
    free_space /= current_unit
    size_needed = float(event['delete_when_free_space_remaining'][:-1])
    if free_space > size_needed:
        logging.warning("Enough space remaining, no need to delete indices")
        return
    extra_space = free_space - size_needed
    ild = curator.IndexList(client)
    ild.filter_by_regex(kind='prefix', value='logs-')
    ild.filter_by_age(
        source='name',
        direction='older',
        timestring='%Y.%m.%d',
        unit='days',
        unit_count=2
    )

    def atoi(text):
        """ transformt str to int"""
        return int(text) if text.isdigit() else text

    def natural_keys(text):
        """ transformt str to int and remove non int"""
        return [atoi(c) for c in re.split(r'(\d+)', text)]

    sorted_indices = sorted(ild.indices, key=natural_keys, reverse=True)
    stats = client.indices.stats(index=','.join(sorted_indices))

    size_indices = {}
    for indice in sorted_indices:
        size = stats["indices"][indice]["total"]["store"]["size_in_bytes"]
        size_indices[indice] = size / (current_unit * 1024)

    while extra_space < 0:
        indice_to_remove = sorted_indices.pop()
        try:
            logging.warning("Deleting indices %s", indice_to_remove)
            client.indices.delete(
                index=indice_to_remove,
                params={"timeout": "5s"}
            )
        except elasticsearch.ConnectionTimeout:
            # exit on timeout make sure it's not running for nothing, next
            # run will continue
            logging.warning("Delete timeout, exiting")
            return "Wait for Delete"
        extra_space += size_indices[indice_to_remove]
