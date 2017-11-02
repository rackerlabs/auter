pkg_name := "auter"
git_tag := $(shell git describe --exact-match --tags 2>/dev/null | sed "s/^v\?//g")
version := ${git_tag}
# This is for testing purposes
version := 0.10
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
	@mkdir -p ${pkg_name}-${version}
	@cp -pr ${files} ${pkg_name}-${version}
	@mv ${pkg_name}-${version}/auter.cron ${pkg_name}-${version}/debian/auter.cron.d
	@mv ${pkg_name}-${version}/auter.aptModule ${pkg_name}-${version}/auter.module
	@find ${pkg_name}-${version}/ -type f | xargs sed -i 's|/usr/bin/auter|/usr/sbin/auter|g'
	@rm -f ${pkg_name}-${version}/auter.yumdnfModule
	@mkdir ${pkg_name}-${version}/docs
	@/usr/bin/help2man --include=${pkg_name}-${version}/auter.help2man -n auter --no-info ./auter -o ${pkg_name}-${version}/docs/auter.1
	@echo "auter (${version}) UNRELEASED; urgency=medium" >${pkg_name}-${version}/debian/changelog
	@echo "  * Release ${version}." >>${pkg_name}-${version}/debian/changelog
	@echo " -- Paolo Gigante <paolo.gigante.sa@gmail.com>  ${datelong}" >>${pkg_name}-${version}/debian/changelog
