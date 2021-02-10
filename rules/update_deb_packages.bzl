# Copyright 2017 mgIT GmbH All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Defines a rule for automatically updating deb_packages repository rules."""

_script_content = """
BASE=$(pwd)
WORKSPACE=$(dirname $(readlink WORKSPACE))
cd "$WORKSPACE"
$BASE/{update_deb_packages} {args} $@
"""

def _update_deb_packages_script_impl(ctx):
    args = ctx.attr.args + ["--pgp-key=\"" + f.path + "\"" for f in ctx.files.pgp_keys] + ctx.attr.bzl_files
    script_content = _script_content.format(update_deb_packages = ctx.file.update_deb_packages_exec.short_path, args = " ".join(args))
    script_file = ctx.actions.declare_file(ctx.label.name + ".bash")
    ctx.actions.write(script_file, script_content, True)
    return [DefaultInfo(
        files = depset([script_file]),
        runfiles = ctx.runfiles([ctx.file.update_deb_packages_exec]),
        executable = script_file,
    )]

_update_deb_packages_script = rule(
    _update_deb_packages_script_impl,
    attrs = {
        "args": attr.string_list(),
        "bzl_files": attr.string_list(),
        "pgp_keys": attr.label_list(),
        "update_deb_packages_exec": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
    },
)

def update_deb_packages(name, pgp_keys, **kwargs):
    script_name = name + "_script"
    _update_deb_packages_script(
        name = script_name,
        tags = ["manual"],
        pgp_keys = pgp_keys,
        update_deb_packages_exec = select({
            "@bazel_tools//src/conditions:linux_aarch64": Label("@update_deb_packages_linux_arm64//file"),
            "@bazel_tools//src/conditions:linux_x86_64": Label("@update_deb_packages_linux_amd64//file"),
            "@bazel_tools//src/conditions:windows": Label("@update_deb_packages_windows_amd64//file"),
            "@bazel_tools//src/conditions:darwin_x86_64": Label("@update_deb_packages_darwin_amd64//file"),
        }),
        **kwargs
    )
    native.sh_binary(
        name = name,
        srcs = [script_name],
        data = ["//:WORKSPACE"] + pgp_keys,
        tags = ["manual"],
    )
