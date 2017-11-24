pkg_name := "auter"

# Version info:
git_tag := $(shell git describe --exact-match --tags 2>/dev/null | sed "s/^v\?//g")
git_commit := $(shell git log --pretty=format:'%h' -n 1)
release := "1"
ifeq ($(strip ${git_tag}),)
  version-short := $(shell git describe --tags 2>/dev/null | sed "s/^v\?//g")
  version := $(shell git describe --tags 2>/dev/null | sed "s/^v\?//g")-${release}
  release := ${date}.git${git_commit}
else
  version := ${git_tag}
endif
version_release := ${version}-${release}

# Build release for debian
distributionrelease := $(lsb_release -cs)
ifeq ($(distributionrelease), "Debian")
  distributionrelease := "unstable"
else ifeq ($(distributionrelease), "Ubuntu")
  distributionrelease := $(lsb_release -cs)
else
  distributionrelease := ""
endif
#distributionrelease := "vivid wily xenial yakkety zesty artful"

date := $(shell date +%Y%m%d)
datelong := $(shell date +"%a, %d %b %Y %T %z")

ignore_files_regexp := "^(Makefile|${pkg_name}..*.tar.gz|${pkg_name}.spec.*)$$"
files := $(shell ls | egrep -ve ${ignore_files_regexp})

clean:
	@rm -rf ${pkg_name}-*.tar.gz

sources:
	@mkdir -p ${pkg_name}-${version}
	@cp -p ${files} ${pkg_name}-${version}
	@tar -zcf ${pkg_name}-${version}.tar.gz ${pkg_name}-${version}
	@rm -rf ${pkg_name}-${version}
	@sed -r -i "s/^(Name:\s*).*\$$/\1${pkg_name}/g" ${pkg_name}.spec 
	@sed -r -i "s/^(Version:\s*).*\$$/\1${version}/g" ${pkg_name}.spec

deb:
	@echo ${release} | grep git &>/dev/null && echo "This seems to be an untagged version - ${release}. If this is not for testing you should checkout a tagged version before running make"
	@mkdir -p ${pkg_name}-${version}
	@cp -pr ${files} ${pkg_name}-${version}
	@mv ${pkg_name}-${version}/auter.cron ${pkg_name}-${version}/debian/auter.cron.d
	@mv ${pkg_name}-${version}/auter.aptModule ${pkg_name}-${version}/auter.module
	@find ${pkg_name}-${version}/ -type f | xargs sed -i 's|/usr/bin/auter|/usr/sbin/auter|g'
	@rm -f ${pkg_name}-${version}/auter.yumdnfModule
	@rm -f ${pkg_name}-${version}/LICENSE
	@rm -f ${pkg_name}-${version}/*.md
	@rm -f ${pkg_name}-${version}/buildguide.txt
	@mkdir ${pkg_name}-${version}/docs
	@/usr/bin/help2man --include=auter.help2man -n auter --no-info ./auter -o ${pkg_name}-${version}/docs/auter.1
	@echo "auter (${version}) ${distributionrelease}; urgency=medium" >${pkg_name}-${version}/debian/changelog
	@echo "  * Release ${version}." >>${pkg_name}-${version}/debian/changelog
	@/usr/bin/awk '/0.10/,/^$$/' NEWS | sed 's/*/ */g' | grep -v "^[0-9]" >>${pkg_name}-${version}/debian/changelog
	@echo " -- Paolo Gigante <paolo.gigante.sa@gmail.com>  ${datelong}" >>${pkg_name}-${version}/debian/changelog
	@cp -ar ${pkg_name}-${version} ${pkg_name}-${version}.orig
	@tar -czf ${pkg_name}_${version-short}.orig.tar.gz ${pkg_name}-${version}.orig
