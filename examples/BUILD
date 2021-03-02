load("@rules_deb_packages//:update_deb_packages.bzl", "update_deb_packages")

update_deb_packages(
    name = "update_deb_packages",
    bzl_files = [
        "debian_buster_amd64.bzl",
        "ubuntu_bionic_amd64.bzl",
    ],
    pgp_keys = [
        "@buster_archive_key//file",
        "@buster_security_archive_key//file",
        "@ubuntu_key//file",
    ],
)
