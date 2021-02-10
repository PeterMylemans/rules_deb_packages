load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["update_deb_packages.go"],
    importpath = "github.com/petermylemans/rules_deb_packages/update_deb_packages",
    visibility = ["//visibility:private"],
    deps = [
        "@ag_pault_go_debian//control:go_default_library",
        "@ag_pault_go_debian//version:go_default_library",
        "@com_github_bazelbuild_buildtools//build:go_default_library",
        "@org_golang_x_crypto//openpgp:go_default_library",
    ],
)

go_binary(
    name = "update_deb_packages",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
