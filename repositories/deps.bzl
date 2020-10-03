"""
Provides functions to pull all external package dependencies of this repository.
"""

load("@bazel_gazelle//:deps.bzl", "go_repository")

def deb_packages_dependencies():
    """Pull in external Go packages needed by Go binaries in this repo. """

    excludes = native.existing_rules().keys()

    if "org_golang_x_crypto" not in excludes:
        go_repository(
            name = "org_golang_x_crypto",
            importpath = "golang.org/x/crypto",
            sum = "h1:hb9wdF1z5waM+dSIICn1l0DkLVDT3hqhhQsDNUmHPRE=",
            version = "v0.0.0-20201002170205-7f63de1d35b0",
        )

    if "com_github_stapelberg_godebiancontrol" not in excludes:
        go_repository(
            name = "com_github_stapelberg_godebiancontrol",
            importpath = "github.com/stapelberg/godebiancontrol",
            sum = "h1:9E/p5pk1eLIriw1+F5a0QoyPTnFTdMhwWd9ICYviUCE=",
            version = "v0.0.0-20180408134423-8c93e189186a",
        )

    if "com_github_knqyf263_go_deb_version" not in excludes:
        go_repository(
            name = "com_github_knqyf263_go_deb_version",
            importpath = "github.com/knqyf263/go-deb-version",
            sum = "h1:X4cedH4Kn3JPupAwwWuo4AzYp16P0OyLO9d7OnMZc/c=",
            version = "v0.0.0-20190517075300-09fca494f03d",
        )

    if "com_github_bazelbuild_buildtools" not in excludes:
        go_repository(
            name = "com_github_bazelbuild_buildtools",
            importpath = "github.com/bazelbuild/buildtools",
            sum = "h1:OfyUN/Msd8yqJww6deQ9vayJWw+Jrbe6Qp9giv51QQI=",
            version = "v0.0.0-20190731111112-f720930ceb60",
        )
