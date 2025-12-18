NAME := "auter"
BUILD_FILES  = auter.conf auter.cron auter.help2man-sections Makefile
BUILD_FILES += auter.yumdnfModule auter.aptModule auter.conf.man
BUILD_FILES += LICENSE README.md MAINTAINERS.md NEWS
EXEC_FILES = auter

# package info
UPSTREAM := "https://github.com/rackerlabs/${NAME}.git"
VERSION := $(shell git tag -l | sort -V | tail -n 1)
RELEASE := $(shell gawk '/^Release:\s+/{print gensub(/%.*/,"","g",$$2)}' ${NAME}.spec)
COMMIT := $(shell git log --pretty=format:'%h' -n 1)
DATE := $(shell date --iso-8601)
DATELONG := $(shell date --iso-8601=seconds)

# build info
BUILD_ROOT := "BUILD"
BUILD_DIR := "${NAME}-${VERSION}"
OUT_DIR := "${HOME}/output"
DIST := $(shell if [ -f /etc/os-release ]; then . /etc/os-release && echo "$$NAME"; else echo "Unknown"; fi)

.PHONY: deb rpm man man-check variables clean help

all:

help:
	@echo "Available targets:"
	@echo "  deb        - Build Debian package"
	@echo "  rpm        - Build RPM package"
	@echo "  man        - Generate man page from help text (requires help2man)"
	@echo "  man-check  - Check if help2man is available"
	@echo "  variables  - Show build variables"
	@echo "  clean      - Clean build artifacts"
	@echo "  help       - Show this help message"

man-check:
	@command -v help2man >/dev/null 2>&1 || { \
		echo "ERROR: help2man is required to generate man pages"; \
		echo "Install with:"; \
		echo "  RHEL/CentOS/Fedora: sudo dnf install help2man"; \
		echo "  Ubuntu/Debian:      sudo apt-get install help2man"; \
		exit 1; \
	}

man: man-check auter auter.help2man-sections
	@echo "Generating man page from help text..."
	help2man --section=1 ./auter -N -o auter.1 \
		-n "Automatic Update Transaction Execution by Rackspace" \
		--include=auter.help2man-sections
	@echo "Man page generated: auter.1"

deb: ${BUILD_FILES} ${EXEC_FILES}
	install -d ${BUILD_ROOT}/$@/${BUILD_DIR}/
	cp -rpv debian ${BUILD_ROOT}/$@/${BUILD_DIR}/
	install -m 0644 ${BUILD_FILES} ${BUILD_ROOT}/$@/${BUILD_DIR}/
	install ${EXEC_FILES} ${BUILD_ROOT}/$@/${BUILD_DIR}/
	install -m 0644 auter.conf.man ${BUILD_ROOT}/$@/${BUILD_DIR}/auter.conf.5
	install -m 0644 -T auter.aptModule ${BUILD_ROOT}/$@/${BUILD_DIR}/auter.module
	tar -C ${BUILD_ROOT}/$@ -czf ${BUILD_ROOT}/$@/${NAME}_${VERSION}.orig.tar.gz ${BUILD_DIR}
	cd ${BUILD_ROOT}/$@/${BUILD_DIR} \
		&& debuild -i -us -uc -b

rpm: ${BUILD_FILES} ${EXEC_FILES}
	install -d ${BUILD_ROOT}/$@/${BUILD_DIR}/
	install -m 0644 ${BUILD_FILES} ${BUILD_ROOT}/$@/${BUILD_DIR}/
	install ${EXEC_FILES} ${BUILD_ROOT}/$@/${BUILD_DIR}/
	echo "%_topdir /auter/${BUILD_ROOT}/$@/rpmbuild" > ~/.rpmmacros
	rpmdev-setuptree
	tar -v -czf ${BUILD_ROOT}/$@/rpmbuild/SOURCES/${VERSION}.tar.gz -C ${BUILD_ROOT}/$@/ ${BUILD_DIR}
	install -m 0644 auter.spec ${BUILD_ROOT}/$@/rpmbuild/SPECS/
	rpmbuild -ba ${BUILD_ROOT}/$@/rpmbuild/SPECS/auter.spec

variables:
	@echo "DIST:            ${DIST}"
	@echo "NAME:            ${NAME}"
	@echo "VERSION:         ${VERSION}"
	@echo "RELEASE:         ${RELEASE}"
	@echo "COMMIT:          ${COMMIT}"
	@echo "DATE:            ${DATE}"
	@echo "DATELONG:        ${DATELONG}"
	@echo "BUILD_DIR:       ${BUILD_DIR}"

clean:
	$(RM) -r ${BUILD_ROOT}


# vim: noet:

