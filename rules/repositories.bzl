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
            sha256 = "589090e63d51234526bc3b5edd3b681a50d2441dd4ebf9366b1c618b633fe010",
        )

    if "update_deb_packages_linux_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_linux_amd64"],
            sha256 = "8b58ab7f0f89ec58a8279648a8d9da87c7172de751d409e27a144dc7ef96d09e",
        )

    if "update_deb_packages_linux_arm64" not in excludes:
        http_file(
            name = "update_deb_packages_linux_arm64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_linux_arm64"],
            sha256 = "e2f4e9376aacea9e40b4169aaf3e2edeff5aaf9480fc695891c1f7692d2b13af",
        )

    if "update_deb_packages_windows_amd64" not in excludes:
        http_file(
            name = "update_deb_packages_windows_amd64",
            executable = True,
            urls = ["https://github.com/petermylemans/rules_deb_packages/releases/download/v0.3.0/update_deb_packages_windows_amd64.exe"],
            sha256 = "f9f7f31459c3ec5ba096de230911cb664f9337b07ac25233b8ff4fa8d3283983",
        )
