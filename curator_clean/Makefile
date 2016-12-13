
PART = curator_clean

# Global
ENV_PATH=lib/python2.7/site-packages/
EXCLUDE='setuptools\|pip\|_markerlib\|dist-info\|pkg_resources\|easy_install.py'
# current dir
MKFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

default:
	@echo "targets: all $(PART) clean docs"

.PHONY: all
all: ${PART}
	@echo all done

build:
	@mkdir -p build

.PHONY: docs
docs: |build
	@ tox -e docs


.PHONY: clean
clean:
	@find -name "*.pyc" -delete
	@rm build .tox -rf

define template  = 
.PHONY: $(1)
$(1): build/lambda-$(1).zip

.tox/lambda-$(1):
	@echo creating $$@ env
	tox -re $$(subst .tox/,,$$@)
	@echo env $$@ created

build/lambda-$(1).zip: $(1).py .tox/lambda-$(1) | build
	@echo creating $$@
	@rm $$@ -rf
	@cd .tox/lambda-$(1)/$${ENV_PATH} && \
	zip $$(subst build/,,$$@) $$(subst .tox/lambda-$(1)/$${ENV_PATH},,$$(shell find .tox/lambda-$(1)/$${ENV_PATH} -name "*.py"|grep -v $${EXCLUDE})) >/dev/null && \
	mv $$(subst build/,,$$@) $${MKFILE_DIR}/$$@ || \
	exit 0
	@zip $$@ $(1).py
	@echo $$@ created correctly

endef


$(foreach prog,$(PART),$(eval $(call template,$(prog))))

