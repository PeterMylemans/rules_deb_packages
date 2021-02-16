load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("@debian_buster_amd64//debs:deb_packages.bzl", "debian_buster_amd64")
load("@ubuntu_bionic_amd64//debs:deb_packages.bzl", "ubuntu_bionic_amd64")


container_image(
    name = "base_buster",
    debs = [
        debian_buster_amd64["base-files"],
        debian_buster_amd64["netbase"],
        debian_buster_amd64["tzdata"],
        debian_buster_amd64["libc6"],
        debian_buster_amd64["libssl1.1"],
        debian_buster_amd64["busybox"],
    ],
    entrypoint = [
        "busybox",
        "sh",
    ],
    env = {"PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"},
)

container_image(
    name = "base_bionic",
    debs = [
        ubuntu_bionic_amd64["base-files"],
        ubuntu_bionic_amd64["netbase"],
        ubuntu_bionic_amd64["tzdata"],
        ubuntu_bionic_amd64["libc6"],
        ubuntu_bionic_amd64["libssl1.1"],
        ubuntu_bionic_amd64["busybox"],
    ],
    entrypoint = [
        "busybox",
        "sh",
    ],
    env = {"PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"},
)
