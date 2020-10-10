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
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.2.0/update_deb_packages_darwin_amd64"],
            sha256 = "6e003f8d442a46dfabd832b0eb28fbc119c9bd82c2c67f6f78635299c8c75d47",
        )

    if "update_deb_packages_linux_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.2.0/update_deb_packages_linux_amd64"],
            sha256 = "6960fda49004294b72c0ed9dbb43e65aa509ca267c217ca2e8d71d3cc882ae09",
        )

    if "update_deb_packages_linux_arm64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_arm64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.2.0/update_deb_packages_linux_arm64"],
            sha256 = "5e6e0251ae374121bf3c530c6df4638eff4c387ae6729087d6973ba25145235a",
        )

    if "update_deb_packages_windows_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_windows_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.2.0/update_deb_packages_windows_amd64.exe"],
            sha256 = "19ccbbac416c142313ea20fe577f19db0136e1a6fc27db007b5ffd99e1836854",
        )
