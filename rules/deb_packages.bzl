"""This modules defines a deb_packages repository rule for managing deb_packages."""

def _deb_packages_impl(repository_ctx):
    # check that keys in "packages" and "packages_sha256" are the same
    for package in repository_ctx.attr.packages:
        if package not in repository_ctx.attr.packages_sha256:
            fail("Package named \"%s\" was not found in packages_sha256 of rule %s" % (package, repository_ctx.name))

    # download each package
    package_rule_dict = {}
    package_version_dict = {}
    package_upstream_version_dict = {}
    timestamp = repository_ctx.attr.timestamp

    # check that $(timestamp) is not present in the url if the timestamp attribute is not defined
    for url in repository_ctx.attr.urls:
        if timestamp == "":
            if url.find("$(timestamp)") != -1:
                fail("Timestamp attribute is not defined but required for the following url : %s" % (url))

    for package in repository_ctx.attr.packages:
        urllist = []
        for url in repository_ctx.attr.urls:
            urllist.append(url.replace("$(timestamp)", timestamp).replace("$(package_path)", repository_ctx.attr.packages[package]).replace("$(package_file)", repository_ctx.attr.packages[package].rpartition("/")[2]))
        repository_ctx.download(
            urllist,
            output = "debs/" + repository_ctx.attr.packages_sha256[package] + ".deb",
            sha256 = repository_ctx.attr.packages_sha256[package],
            executable = False,
        )
        package_rule_dict[package] = "@" + repository_ctx.name + "//debs:" + repository_ctx.attr.packages_sha256[package] + ".deb"
        package_version = repository_ctx.attr.packages[package].split("_")[1]
        upstream_version = package_version
        if package_version.count("-") > 0:
            upstream_version = package_version.split("-")[0]
        package_version_dict[package] = package_version
        package_upstream_version_dict[package] = upstream_version

    # create the deb_packages.bzl file that contains the package name : filename mapping
    repository_ctx.file("debs/deb_packages.bzl", repository_ctx.name + " = " + struct(**package_rule_dict).to_json(), executable = False)

    # create the deb_versions.bzl file that contains the package name : full version mapping
    repository_ctx.file("debs/deb_versions.bzl", repository_ctx.name + "_versions = " + struct(**package_version_dict).to_json(), executable = False)

    # create the deb_upstream_versions.bzl file that contains the package name : upstream version mapping (without debian revisions)
    repository_ctx.file("debs/deb_upstream_versions.bzl", repository_ctx.name + "_upstream_versions = " + struct(**package_upstream_version_dict).to_json(), executable = False)

    # create the BUILD file that globs all the deb files
    repository_ctx.file("debs/BUILD", """
package(default_visibility = ["//visibility:public"])
deb_files = glob(["*.deb"])
exports_files(deb_files + ["deb_packages.bzl"])
""", executable = False)

_deb_packages = repository_rule(
    _deb_packages_impl,
    attrs = {
        "arch": attr.string(
            doc = "the target package architecture, required - e.g. arm64 or amd64",
        ),
        "timestamp": attr.string(
            doc = "the timestamp value of the archive lookup (yyyyMMddTHHmmssZ), required - e.g. 20091004T111800Z",
        ),
        "packages": attr.string_dict(
            doc = "a dictionary mapping packagename to package_path, required - e.g. {\"foo\":\"pool/main/f/foo/foo_1.2.3-0_amd64.deb\"}",
        ),
        "packages_sha256": attr.string_dict(
            doc = "a dictionary mapping packagename to package_hash, required - e.g. {\"foo\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}",
        ),
        "urls": attr.string_list(
            doc = "a list of full URLs of the package repository, support templating with $(timestamp), $(package_path) and $(package_file), required - e.g. http://deb.debian.org/debian/$(package_path)",
        ),
        "sources": attr.string_list(
            doc = "a list of full sources of the package repository in format similar to apt sources.list without the deb prefix, required - e.g. 'http://deb.debian.org/debian buster main'",
        ),
    },
)

def deb_packages(**kwargs):
    _deb_packages(**kwargs)
