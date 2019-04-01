NAME := "auter"
BUILD_FILES =  auter.conf auter.cron auter.help2man-sections Makefile
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
DIST := $(shell python -c "import platform; print(platform.linux_distribution()[0])")

.PHONY: deb rpm variables clean

all:

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

