load("@rules_deb_packages//:deb_packages.bzl", "deb_packages")

def debian_buster_amd64():
    deb_packages(
        name = "debian_buster_amd64_macro",
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
