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
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_darwin_amd64"],
            sha256 = "020d4b963ac403b0e5e25f8a65bbf8011ba85e0fad453772b52f9a520b281fef",
        )

    if "update_deb_packages_linux_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_linux_amd64"],
            sha256 = "bebd5b29baf09b7e5a06e324b929b64ee820b907a95b080752c1b7b39b81ea24",
        )

    if "update_deb_packages_linux_arm64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_arm64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_linux_arm64"],
            sha256 = "a52a0b6599ccda21a733cfdd0d2f6a2fac37a516eca960541859f70fe18d7da3",
        )

    if "update_deb_packages_windows_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_windows_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_windows_amd64.exe"],
            sha256 = "2b9fb89f11f01c82231fa156fb27ab082a8459eccf7822e481753f7e2eda015a",
        )
