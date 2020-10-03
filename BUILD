load("@bazel_gazelle//:def.bzl", "gazelle")
load("@rules_deb_packages//tools/update_deb_packages:update_deb_packages.bzl", "update_deb_packages")

package(default_visibility = ["//visibility:public"])

gazelle(
    name = "gazelle",
    prefix = "github.com/petermylemans/rules_deb_packages",
)

update_deb_packages(
    name = "update_deb_packages",
    pgp_keys = [
        "@buster_archive_key//file",
        "@buster_security_archive_key//file",
    ],
)
