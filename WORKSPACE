workspace(name = "rules_deb_packages")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

# Go rules dependencies
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "08c3cd71857d58af3cda759112437d9e63339ac9c6e0042add43f4d94caf632d",
    urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.24.2/rules_go-v0.24.2.tar.gz"],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "cdb02a887a7187ea4d5a27452311a75ed8637379a1287d8eeb952138ea485f7d",
    urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz"],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

gazelle_dependencies()

# Docker rules dependencies
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "4521794f0fba2e20f3bf15846ab5e01d5332e587e9ce81629c7f96c793bb7036",
    strip_prefix = "rules_docker-0.14.4",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.4/rules_docker-v0.14.4.tar.gz"],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

load("@io_bazel_rules_docker//repositories:pip_repositories.bzl", "pip_deps")

pip_deps()

# Example for using the deb_packages ruleset
load("//:deb_packages.bzl", "deb_packages")

http_file(
    name = "buster_archive_key",
    sha256 = "9c854992fc6c423efe8622c3c326a66e73268995ecbe8f685129063206a18043",
    urls = ["https://ftp-master.debian.org/keys/archive-key-10.asc"],
)

http_file(
    name = "buster_security_archive_key",
    sha256 = "4cf886d6df0fc1c185ce9fb085d1cd8d678bc460e6267d80a833d7ea507a0fbd",
    urls = ["https://ftp-master.debian.org/keys/archive-key-10-security.asc"],
)

deb_packages(
    name = "debian_buster_amd64",
    arch = "amd64",
    mirrors = [
        "http://deb.debian.org/debian",
    ],
    packages = {
        "base-files": "pool/main/b/base-files/base-files_10.3+deb10u6_amd64.deb",
        "busybox": "pool/main/b/busybox/busybox_1.30.1-4_amd64.deb",
        "ca-certificates": "pool/main/c/ca-certificates/ca-certificates_20200601~deb10u1_all.deb",
        "libc6": "pool/main/g/glibc/libc6_2.28-10_amd64.deb",
        "libssl1.1": "pool/main/o/openssl/libssl1.1_1.1.1d-0+deb10u3_amd64.deb",
        "netbase": "pool/main/n/netbase/netbase_5.6_all.deb",
        "openssl": "pool/main/o/openssl/openssl_1.1.1d-0+deb10u3_amd64.deb",
        "tzdata": "pool/main/t/tzdata/tzdata_2020a-0+deb10u1_all.deb",
    },
    packages_sha256 = {
        "base-files": "ed640f8e2ab4e44731485ac7658a269012b9318ec8c6fb7b2b78825a624a9939",
        "busybox": "1e32ea742bddec4ed5a530ee2f423cdfc297c6280bfbb45c97bf12eecf5c3ec1",
        "ca-certificates": "794bd3ffa0fc268dc8363f8924b2ab7cf831ab151574a6c1584790ce9945cbb2",
        "libc6": "6f703e27185f594f8633159d00180ea1df12d84f152261b6e88af75667195a79",
        "libssl1.1": "b293309a892730986e779aea48e97ea94cd58f34f07fefbd432c210ee4a427e2",
        "netbase": "baf0872964df0ccb10e464b47d995acbba5a0d12a97afe2646d9a6bb97e8d79d",
        "openssl": "03a133833154325c731291c8a87daef5962dcfb75dee7cdb11f7fb923de2db82",
        "tzdata": "f9464df8a102259df6caff910b810b452fd6e2af34c73ec8729b474dc2f51c55",
    },
    pgp_key = "buster_archive_key",
    sources = [
        "http://deb.debian.org/debian buster main",
        "http://deb.debian.org/debian buster-updates main",
    ],
)

go_repository(
    name = "org_golang_x_crypto",
    importpath = "golang.org/x/crypto",
    sum = "h1:hb9wdF1z5waM+dSIICn1l0DkLVDT3hqhhQsDNUmHPRE=",
    version = "v0.0.0-20201002170205-7f63de1d35b0",
)

go_repository(
    name = "com_github_stapelberg_godebiancontrol",
    importpath = "github.com/stapelberg/godebiancontrol",
    sum = "h1:9E/p5pk1eLIriw1+F5a0QoyPTnFTdMhwWd9ICYviUCE=",
    version = "v0.0.0-20180408134423-8c93e189186a",
)

go_repository(
    name = "com_github_knqyf263_go_deb_version",
    importpath = "github.com/knqyf263/go-deb-version",
    sum = "h1:X4cedH4Kn3JPupAwwWuo4AzYp16P0OyLO9d7OnMZc/c=",
    version = "v0.0.0-20190517075300-09fca494f03d",
)

go_repository(
    name = "com_github_bazelbuild_buildtools",
    importpath = "github.com/bazelbuild/buildtools",
    sum = "h1:Et1IIXrXwhpDvR5wH9REPEZ0sUtzUoJSq19nfmBqzBY=",
    version = "v0.0.0-20200718160251-b1667ff58f71",
)
