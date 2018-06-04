pkg_name := "auter"

# Version info:
#git_tag := $(shell git describe --exact-match --tags 2>/dev/null | sed "s/^v\?//g")
git_tag := $(shell awk '/Version:/ {print $$2}' auter.spec)
git_commit := $(shell git log --pretty=format:'%h' -n 1)
release := $(shell awk '/Release:/ {gsub(/%.*/,""); print $$2}' auter.spec)
date := $(shell date +%Y%m%d)
datelong := $(shell date +"%a, %d %b %Y %T %z")


ifeq ($(strip ${git_tag}),)
  version := $(shell git describe --tags 2>/dev/null | sed "s/^v\?//g")-${release}
  release := ${date}.git${git_commit}
  release_message := "This seems to be an untagged version - ${release}. If this is not for testing you should checkout a tagged version before running make"
else
  version := ${git_tag}
endif
version_release := ${version}-${release}

# Build release for debian
distribution := $(shell python -c "import platform; print platform.linux_distribution()[0]")
ifeq (${distribution}, Debian)
  distributionrelease := unstable
  lintian-standards-version := $(shell grep -o -m1 "^[0-9].* " /usr/share/lintian/data/standards-version/release-dates)
else ifeq (${distribution}, Ubuntu)
  distributionrelease := $(shell lsb_release -cs)
  lintian-standards-version := $(shell grep -o -m1 "^[0-9].* " /usr/share/lintian/data/standards-version/release-dates)
else
  distributionrelease := "FAILED... distribution=${distribution}"
endif

ignore_files_regexp_rpmbuild := "^Makefile\|${pkg_name}.spec.*$$\|.*.md\|buildguide.txt\|contrib\|debian\|tests"
files := $(shell ls -1 | egrep -ve ${ignore_files_regexp_rpmbuild})

clean:
	@rm -rf ${pkg_name}-*.tar.gz
	@rm -rf ${pkg_name}-${version}*
	@rm -rf ${pkg_name}_${version}*

sources:
	@mkdir -p ${pkg_name}-${version}
	@cp -pr ${files} ${pkg_name}-${version}
	@rm -rf ${pkg_name}-${version}/contrib ${pkg_name}-${version}/debian ${pkg_name}-${version}/tests
	@tar -zcf ${pkg_name}-${version}.tar.gz ${pkg_name}-${version}
	@rm -rf ${pkg_name}-${version}

deb:
	@echo ${release_message}
	@mkdir -p ${pkg_name}-${version}
	@cp -pr ${files} ${pkg_name}-${version}
	@sed -i 's/^Standards-Version:.*$$/Standards-Version: ${lintian-standards-version}/g' ${pkg_name}-${version}/debian/control
	@mv ${pkg_name}-${version}/auter.cron ${pkg_name}-${version}/debian/auter.cron.d
	@mv ${pkg_name}-${version}/auter.aptModule ${pkg_name}-${version}/auter.module
	@find ${pkg_name}-${version}/ -type f | xargs sed -i 's|/usr/bin/auter|/usr/sbin/auter|g'
	@rm -f ${pkg_name}-${version}/auter.yumdnfModule
	@rm -f ${pkg_name}-${version}/LICENSE
	@mkdir ${pkg_name}-${version}/docs
	@/usr/bin/help2man --include=auter.help2man -n auter --no-info ./auter -o ${pkg_name}-${version}/docs/auter.1
	@echo "auter (${version}) ${distributionrelease}; urgency=medium" >${pkg_name}-${version}/debian/changelog
	@echo "  * Release ${version}." >>${pkg_name}-${version}/debian/changelog
	# DON'T FORGET TO CHANGE THIS VERSION AT NEXT RELEASE
	@/usr/bin/awk '/0.11/,/^$$/' NEWS | sed 's/*/ */g' | grep -v "^[0-9]" >>${pkg_name}-${version}/debian/changelog
	@echo " -- Paolo Gigante <paolo.gigante.sa@gmail.com>  ${datelong}" >>${pkg_name}-${version}/debian/changelog
	@cp -ar ${pkg_name}-${version} ${pkg_name}-${version}.orig
	@tar -czf ${pkg_name}_${version}.orig.tar.gz ${pkg_name}-${version}.orig

showvariables:
	@echo ${release_message}
	@echo "date  =  ${date}"
	@echo "datelong  =  ${datelong}"
	@echo "distribution  =  ${distribution}"
	@echo "distributionrelease  =  ${distributionrelease}"
	@echo "files  =  ${files}"
	@echo "git_commit  =  ${git_commit}"
	@echo "git_tag  =  ${git_tag}"
	@echo "ignore_files_regexp  =  ${ignore_files_regexp}"
	@echo "pkg_name  =  ${pkg_name}"
	@echo "release  =  ${release}"
	@echo "version  =  ${version}"
