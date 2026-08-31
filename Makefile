VIRTUALENV = virtualenv -p /opt/pypy/bin/pypy
VENV := $(shell echo $${VIRTUAL_ENV-local})
PTYPE = pypy
PYTHON = $(VENV)/bin/pypy
NOSE = $(VENV)/bin/nosetests
DEV_STAMP = $(VENV)/.dev_env_installed.stamp
INSTALL_STAMP = $(VENV)/.install.stamp
TEMPDIR := $(shell mktemp -d)

# Hackety-hack around OSX system python bustage.
# The need for this should go away with a future osx/xcode update.
ARCHFLAGS = -Wno-error=unused-command-line-argument-hard-error-in-future
CFLAGS = -Wno-error=write-strings

INSTALL = ARCHFLAGS=$(ARCHFLAGS) CFLAGS=$(CFLAGS) $(VENV)/bin/pip install

.IGNORE: clean distclean maintainer-clean
.PHONY: all install install-dev virtualenv tests

help:
	@echo "Since Python 2.7 is no longer supported, but is used by this project,"
	@echo "please be sure to install pypy 2.7 <http://pypy.org/download.html> and"
	@echo "the system appropriate `pypy-dev` package"
	@echo ""
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  install                     install dependencies and prepare environment"
	@echo "  install-dev                 install dependencies and everything needed to run tests"
	@echo "  build-requirements          install all requirements and freeze them in requirements.txt"
	@echo "  flake8                      run the flake8 linter"
	@echo "  tests                       run all the tests with all the supported python interpreters (same as travis)"
	@echo "  version-file                update the version.json file"
	@echo "  clean                       remove *.pyc files and __pycache__ directory"
	@echo "  distclean                   remove *.egg-info files and *.egg, build and dist directories"
	@echo "  maintainer-clean            remove the .tox and the .venv directories"
	@echo "Check the Makefile to know exactly what each target is doing."

all: install
install: $(INSTALL_STAMP)
$(INSTALL_STAMP): $(PYTHON) setup.py
	$(INSTALL) -Ue .
	touch $(INSTALL_STAMP)

install-dev: $(INSTALL_STAMP) $(DEV_STAMP)
$(DEV_STAMP): $(PYTHON) dev-requirements.txt
	$(INSTALL) -Ur dev-requirements.txt
	touch $(DEV_STAMP)

virtualenv: $(PYTHON)
$(PYTHON):
	# The latest `pip` doesn't work with pypy 2.7 on some platforms.
	# Pin to a working version; ref https://github.com/pypa/pip/issues/8653
	$(VIRTUALENV) -p $(PTYPE) --no-setuptools --no-pip $(VENV)
	$(VENV)/bin/pypy -m ensurepip --upgrade
	$(VENV)/bin/pip install "pip<21" "setuptools<45"

build-requirements:
	$(VIRTUALENV) -p $(PTYPE) --no-setuptools --no-pip $(TEMPDIR)
	$(VENV)/bin/pypy -m ensurepip --upgrade
	$(VENV)/bin/pip install "pip<21" "setuptools<45"
	ARCHFLAGS=$(ARCHFLAGS) $(TEMPDIR)/bin/pip install -Ue .
	$(TEMPDIR)/bin/pip freeze | grep -v -- '^-e' > requirements.txt

tests: install-dev
	# By default nose will skip tests in executable files, but that's annoying
	# when working in WSL with a checkout mounted from the native filesystem.
	$(VENV)/bin/nosetests --nocapture --exe tokenserver/tests

flake8: install-dev
	$(VENV)/bin/flake8 tokenserver

clean:
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d | xargs rm -fr
	rm -fr docs/_build/

distclean: clean
	rm -fr *.egg *.egg-info/ dist/ build/

maintainer-clean: distclean
	rm -fr local/ .tox/
