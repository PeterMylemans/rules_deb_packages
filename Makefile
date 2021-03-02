LD_FLAGS = "-s -w"
version ?= main

default: clean all

clean:
	rm -rf dist

binaries:
	GOOS=linux GOARCH=amd64 go build -o "./dist/update_deb_packages_linux_amd64" -ldflags=${LD_FLAGS} ./update_deb_packages/update_deb_packages.go
	GOOS=linux GOARCH=arm64 go build -o "./dist/update_deb_packages_linux_arm64" -ldflags=${LD_FLAGS} ./update_deb_packages/update_deb_packages.go
	GOOS=darwin GOARCH=amd64 go build -o "./dist/update_deb_packages_darwin_amd64" -ldflags=${LD_FLAGS} ./update_deb_packages/update_deb_packages.go
	GOOS=darwin GOARCH=arm64 go build -o "./dist/update_deb_packages_darwin_arm64" -ldflags=${LD_FLAGS} ./update_deb_packages/update_deb_packages.go
	GOOS=windows GOARCH=amd64 go build -o "./dist/update_deb_packages_windows_amd64.exe" -ldflags=${LD_FLAGS} ./update_deb_packages/update_deb_packages.go

rule:
	./scripts/generate_repositories.sh ${version}
	tar --sort=name --numeric-owner --owner=0 --group=0  --mtime="$(git show --no-patch --no-notes --pretty='%cI' HEAD)" --create --gzip --directory=rules --file=dist/rules_deb_packages.tar.gz .

all: binaries rule
