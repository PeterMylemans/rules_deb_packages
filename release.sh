#/bin/sh

set -o errexit
set -o xtrace

rm -Rf dist
mkdir dist

(cd tools && \
    bazel clean && \
    bazel build --platforms=@io_bazel_rules_go//go/toolchain:windows_amd64 //update_deb_packages:update_deb_packages && \
    cp bazel-bin/update_deb_packages/update_deb_packages_/update_deb_packages.exe ../dist/update_deb_packages_windows_amd64.exe)

(cd tools && \
    bazel clean && \
    bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //update_deb_packages:update_deb_packages && \
    cp bazel-bin/update_deb_packages/update_deb_packages_/update_deb_packages ../dist/update_deb_packages_linux_amd64)

(cd tools && \
    bazel clean && \
    bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_arm64 //update_deb_packages:update_deb_packages && \
    cp bazel-bin/update_deb_packages/update_deb_packages_/update_deb_packages ../dist/update_deb_packages_linux_arm64)

(cd tools && \
    bazel clean && \
    bazel build --platforms=@io_bazel_rules_go//go/toolchain:darwin_amd64 //update_deb_packages:update_deb_packages && \
    cp bazel-bin/update_deb_packages/update_deb_packages_/update_deb_packages ../dist/update_deb_packages_darwin_amd64)

version=v0.1.0

cat > rules/repositories.bzl <<EOF
# WARNING!!!
# DO NOT MODIFY THIS FILE DIRECTLY.
# TO GENERATE THIS RUN: ./release.sh
"""
Provides functions to pull all external package dependencies of this repository.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def deb_packages_dependencies():
    """Pull in external Go packages needed by Go binaries in this repo. """

    excludes = native.existing_rules().keys()

    if "update_deb_packages_darwin_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_darwin_amd64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/$version/update_deb_packages_darwin_amd64"],
            sha256 = "`sha256sum dist/update_deb_packages_darwin_amd64 | cut -d " " -f 1 `",
        )

    if "update_deb_packages_linux_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_amd64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/$version/update_deb_packages_linux_amd64"],
            sha256 = "`sha256sum dist/update_deb_packages_linux_amd64 | cut -d " " -f 1 `",
        )

    if "update_deb_packages_linux_arm64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_arm64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/$version/update_deb_packages_linux_arm64"],
            sha256 = "`sha256sum dist/update_deb_packages_linux_arm64 | cut -d " " -f 1 `",
        )

    if "update_deb_packages_windows_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_windows_amd64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/$version/update_deb_packages_windows_amd64.exe"],
            sha256 = "`sha256sum dist/update_deb_packages_windows_amd64.exe | cut -d " " -f 1 `",
        )
EOF
