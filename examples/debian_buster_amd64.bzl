load("@rules_deb_packages//:deb_packages.bzl", "deb_packages")

def debian_buster_amd64():
    deb_packages(
        name = "debian_buster_amd64_macro",
        arch = "amd64",
        urls = [
            "http://deb.debian.org/debian/$(package_path)",
            "http://deb.debian.org/debian-security/$(package_path)",
            "https://snapshot.debian.org/archive/debian/$(timestamp)/$(package_path)",
            "https://snapshot.debian.org/archive/debian-security/$(timestamp)/$(package_path)",
        ],
        packages = {
            "base-files": "pool/main/b/base-files/base-files_10.3+deb10u8_amd64.deb",
            "busybox": "pool/main/b/busybox/busybox_1.30.1-4_amd64.deb",
            "ca-certificates": "pool/main/c/ca-certificates/ca-certificates_20200601~deb10u2_all.deb",
            "libc6": "pool/main/g/glibc/libc6_2.28-10_amd64.deb",
            "libssl1.1": "pool/main/o/openssl/libssl1.1_1.1.1d-0+deb10u4_amd64.deb",
            "netbase": "pool/main/n/netbase/netbase_5.6_all.deb",
            "openssl": "pool/main/o/openssl/openssl_1.1.1d-0+deb10u4_amd64.deb",
            "tzdata": "pool/main/t/tzdata/tzdata_2021a-0+deb10u1_all.deb",
        },
        packages_sha256 = {
            "base-files": "eda9ec7196cae25adfa1cb91be0c9071b26904540fc90bab8529b2a93ece62b1",
            "busybox": "1e32ea742bddec4ed5a530ee2f423cdfc297c6280bfbb45c97bf12eecf5c3ec1",
            "ca-certificates": "a9e267a24088c793a9cf782455fd344db5fdced714f112a8857c5bfd07179387",
            "libc6": "6f703e27185f594f8633159d00180ea1df12d84f152261b6e88af75667195a79",
            "libssl1.1": "b02b468f0fad929b5d2b38ae05607c22c4f1ef70adc2688fb02b9d9514d6ac51",
            "netbase": "baf0872964df0ccb10e464b47d995acbba5a0d12a97afe2646d9a6bb97e8d79d",
            "openssl": "fa997ab8745f28ea3553ebc623872bb6809cc94898f6c72d81a757d9ee47dfe3",
            "tzdata": "00da63f221b9afa6bc766742807e398cf183565faba339649bafa3f93375fbcb",
        },
        sources = [
            "http://deb.debian.org/debian buster main",
            "http://deb.debian.org/debian buster-updates main",
            "http://deb.debian.org/debian-security buster/updates main",
        ],
        timestamp = "20210215T214319Z",
    )
