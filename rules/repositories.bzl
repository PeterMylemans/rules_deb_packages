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
            sha256 = "c6b353a331201615f9cad0d0a13c71f8330b4468ffa0ebf4574d3ab4563aa240",
        )

    if "update_deb_packages_linux_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_linux_amd64"],
            sha256 = "d7f118027c24ca49d4f1d2572c858620b3ac2b61152edc5c32945a063a0c353d",
        )

    if "update_deb_packages_linux_arm64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_arm64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_linux_arm64"],
            sha256 = "7b4736bc07309d5712f95903889181a4c1a89c74d2ee91ea1e324fc51df0eda4",
        )

    if "update_deb_packages_windows_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_windows_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_windows_amd64.exe"],
            sha256 = "65a7dbeea67aa7707ea6e679903e2929b4bb7ca4f31d691edeed47b83d523316",
        )
