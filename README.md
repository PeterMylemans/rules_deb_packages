# Deb Packages Rule

## Gettng started

`deb_packages` is a repository rule, and therefore made to be used in the `WORKSPACE`.

First, tell bazel to load the rule and its dependencies with a `load()` statement.

```bzl
load("//:repositories/deps.bzl", "deb_packages_dependencies")

deb_packages_dependencies()
```

Next, for every source of deb packages, create a `deb_packages` rule.
You can define additional mirrors per package source, but it is assumed that all these mirrors will serve the exact same files.
Hashes are checked after downloading files.

```bzl
load("@rules_deb_packages//:deb_packages.bzl", "deb_packages")

deb_packages(
    name = "debian_buster_amd64",
    arch = "amd64",
    mirrors = [
        "http://deb.debian.org/debian",
        "http://deb.debian.org/debian-security",
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
    sources = [
        "http://deb.debian.org/debian buster main",
        "http://deb.debian.org/debian buster-updates main",
        "http://deb.debian.org/debian-security buster/updates main",
    ],
)
```

Internally `.deb` files referenced here will be downloaded by Bazel, renamed to their SHA256 hash (not all characters used in file names are legal in bazel names) and made available in a dictionary named the same as the `deb_packages` rule.
This dictionary is made available in a file named `deb_packages.bzl` in the `debs` subfolder of this rule.
You can find the generated and downloaded files in the `./bazel-YourWorkSpace/external/your_rule_name/debs` folder after building the project if you're interested.

To actually use the `.deb` files in a BUILD file rule like `container_image`, you first have to load all dictionaries of package sources you want to use.
This is done with the `load("@your_rule_name//debs:deb_packages.bzl", "your_rule_name")` line.
Then you can use the dictionary named the same as the `deb_packages` rule to refer to the packages you defined in the WORKSPACE file.

```bzl
load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("@debian_buster_amd64//debs:deb_packages.bzl", "debian_buster_amd64")

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
```

## Adding/updating new packages or package sources

### Automatically using the `update_deb_packages` tool

As you saw, most of the information is already available on mirrors anyways as soon as you know the distro, exact package name, architecture and version.
If you enter the correct rule name for the `pgp_key` field, this also means that you can do this in a verified chain of trust.

The `update_deb_packages` tool can help you with this.

To use it, first add an update_deb_packages rule to your workspaces top-level BUILD file.

```bzl
load("@rules_deb_packages//tools/update_deb_packages:update_deb_packages.bzl", "update_deb_packages")

update_deb_packages(
    name = "update_deb_packages",
    pgp_keys = [
        "@buster_archive_key//file",
        "@buster_security_archive_key//file",
    ],
)
```

The update tool will check the signatures of the release info before updating the hashes of the packages. So you need to tell it about the trusted PGP keys typically obtained from https://ftp-master.debian.org/keys.html.

Also create a `http_file` rule in your WORKSPACE that references this key and make sure to include a SHA256 hash, so it won't change later:

```bzl
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
```

Next create a `deb_packages` rule in your WORKSPACE file without any packages defined:

```bzl
deb_packages(
    name = "debian_buster_amd64",
    arch = "amd64",
    mirrors = [
        "http://deb.debian.org/debian",
        "http://deb.debian.org/debian-security",
    ],
    packages = {
        "base-files": "",
        "busybox": "",
    },
    packages_sha256 = {
        "base-files": "",
        "busybox": "",
    },
    sources = [
        "http://deb.debian.org/debian buster main",
        "http://deb.debian.org/debian buster-updates main",
        "http://deb.debian.org/debian-security buster/updates main",
    ],
)
```

Now run `bazel run update_deb_packages` (similar to the `gazelle` tool used by the golang Bazel rules) and the helper tool will fetch the relevant files from the mirror(s) and add the data for missing packages at the respective `deb_packages` rule.

It will also update any existing packages to either the most recent version available on the mirror or a version you specified in the package name (`package=version`).
The string `latest` is also supported if you want to use version pinning.

### Manually

Choose a Debian mirror that you want to use, for example http://deb.debian.org/debian.

Visit the `/dists/` directory on that mirror and choose the distro you want to use, for example `jessie`.

Download the `Release` and `Release.gpg` files in the distro's folder (in our example: http://deb.debian.org/debian/dists/jessie/Release and http://deb.debian.org/debian/dists/jessie/Release.gpg).

Verify the file's signature: `gpg --verify Release.gpg Release`
It **must** be signed with a vald signature by one of the keys on this site: https://ftp-master.debian.org/keys.html

Also create a `http_file` rule that references this key and make sure to include a SHA256 hash, so it won't change later:

```bzl
http_file(
    name = "jessie_archive_key",
    sha256 = "e42141a829b9fde8392ea2c0e329321bb29e5c0453b0b48e33c9f88bdc4873c5",
    urls = ["https://ftp-master.debian.org/keys/archive-key-8.asc"],
)
```

This file contains the paths to various other files and their hashes.
Scroll down to the SHA256 section and choose the path to the `Packages` file that you want to use (for example `main/binary-amd64/Packages.xz`) and also note down its hash.

Append the `Packages` file path to your mirror URL + `/dists/yourdistro` (for example http://deb.debian.org/debian/dists/jessie/main/binary-amd64/Packages.xz) and download the resulting file.

Verify the hash of the file you received (with the exception of the GPG keys site, all these downloads happen on insecure channels by design) with `sha256sum`:
`sha256sum Packages.xz`

Unpack the archive (if you downloaded the `Packages.gz` or `Packages.xz` file) and now you'll have a huge text file that contains hashes and paths to all Debian packages in that repository.

Open this file and start looking for the package names you want to use in your `BUILD` files.
You can do this for example in a text editor or using `grep` (the -A switch prints that many lines after each match): `grep -A 25 "Package: python2.7-minimal" Packages`

Now you finally have the info that you must enter in the `deb_packages` rule:
The value at `Filename` is the path to the exact package to be used and the value at `SHA256` is the verified hash that this file will have.

Now enter this information in the `WORKSPACE` file in a `deb_packages` rule:

```bzl
deb_packages(
    name = "my_new_manual_source",
    arch = "amd64",
    mirrors = [
        "http://deb.debian.org/debian",
        "http://my.private.mirror/debian",
    ],
    packages = {
        "libpython2.7-minimal": "pool/main/p/python2.7/libpython2.7-minimal_2.7.9-2+deb8u1_amd64.deb",
    },
    packages_sha256 = {
        "libpython2.7-minimal": "916e2c541aa954239cb8da45d1d7e4ecec232b24d3af8982e76bf43d3e1758f3",
    },
)
```

# Reference

## deb_packages

```python
deb_packages(name, arch, mirrors, packages, packages_sha256, sources)
```

A **workspace** rule that downloads `.deb` packages from a Debian style repository and makes them available in the WORKSPACE.

For a `deb_packages` rule named `foo_bar`, packages can be used by loading `load("@foo_bar//debs:deb_packages.bzl", "foo_bar")` into your `BUILD` file, then referencing the package with `foo_bar['packagename']`.

The packagename is expected to be the exact package name as available upstream, with an optional version string appended.
This is not enforced by bazel or these rules, but makes automatic parsing and updating much easier.
If you use the `update_deb_packages` helper, version pinning with `packagename=version` is supported.

Every key name in the `packages` section must exactly match a key name in the `packages_sha256` section.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>rule name, required</code></p>
      </td>
    </tr>
    <tr>
      <td><code>arch</code></td>
      <td>
        <p><code>the target package architecture, required</code></p>
        <p>Examples: amd64, arm64, s390x etc.</p>
      </td>
    </tr>
    <tr>
      <td><code>mirrors</code></td>
      <td>
        <p><code>the full url of the package repository, required</code></p>
        <p>All of these mirrors are expected to host a Debian style mirror and to host the same versions of files</p>
        <p>Many mirrors host their packages in a subdirectory (e.g. <code>http://deb.debian.org/debian</code> instead of <code>http://deb.debian.org</code>), in that case use the former URL.</p>
      </td>
    </tr>
    <tr>
      <td><code>packages</code></td>
      <td>
        <p><code>a dictionary mapping packagename to package_path, required</code></p>
        <p>The deb file is expected to be found at <code>mirror</code> + <code>package_path</code></p>
        <p>Package names can optionally contain a version (<code>packagename=1.2.3-4</code>)</p>
      </td>
    </tr>
    <tr>
      <td><code>packages_sha256</code></td>
      <td>
        <p><code>a dictionary mapping packagename to package_hash, required</code></p>
        <p>The deb file at package_path is expected to have this sha256 hash</p>
        <p>Keys need to be the same as in the <code>packages</code> dictionary</p>
      </td>
    </tr>
    <tr>
      <td><code>sources</code></td>
      <td>
        <p><code>a list of full sources of the package repository in format similar to apt sources.list without the deb prefix</code></p>
        <p>e.g. <code>'http://deb.debian.org/debian buster main'</code></p>
      </td>
    </tr>
  </tbody>
</table>

## update_deb_packages


```python
update_deb_packages(name, pgp_keys)
```

A rule that helps keep all deb_package repository rules up to date, by checking current version against the latest available version in the specified sources.

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>rule name, required</code></p>
      </td>
    </tr>
    <tr>
      <td><code>pgp_keys</code></td>
      <td>
        <p><code>a list of trusted PGP keys that were used to sign release information of source repositories</code>
      </td>
    </tr>
  </tbody>
</table>