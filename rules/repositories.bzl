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
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.1.0/update_deb_packages_darwin_amd64"],
            sha256 = "5df76bb6fc4ed89ab2f6497fc7c03d0eddab01f448a3baa732c914992969881f",
        )

    if "update_deb_packages_linux_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_amd64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.1.0/update_deb_packages_linux_amd64"],
            sha256 = "c16ab719302d231a3b492881cad53fa4fae3aa4b49f1d291f6c0825a60c63fff",
        )

    if "update_deb_packages_linux_arm64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_arm64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.1.0/update_deb_packages_linux_arm64"],
            sha256 = "bde6f8eaad68fd4742c0a25f330e38207ace3dc2205cb4c0d0b9e3b129b0dd57",
        )

    if "update_deb_packages_windows_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_windows_amd64",
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.1.0/update_deb_packages_windows_amd64.exe"],
            sha256 = "e8a52de54d147cb0f8acde78da1750654ec7fc52f02d4b10e108f9b2f72cc58a",
        )
