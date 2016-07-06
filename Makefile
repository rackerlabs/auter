pkg_name := "auter"
git_tag := $(shell git describe --exact-match --tags 2>/dev/null | sed "s/^v\?//g")
version := ${git_tag}

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
