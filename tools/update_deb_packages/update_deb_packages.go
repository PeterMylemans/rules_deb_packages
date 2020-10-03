package main

import (
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"path"
	"reflect"
	"sort"
	"strings"

	"github.com/bazelbuild/buildtools/build"
	version "github.com/knqyf263/go-deb-version"
	"github.com/stapelberg/godebiancontrol"
	"golang.org/x/crypto/openpgp"
)

func appendUniq(slice []string, v string) []string {
	for _, x := range slice {
		if x == v {
			return slice
		}
	}
	return append(slice, v)
}

func logFatalErr(e error) {
	if e != nil {
		log.Fatal(e)
	}
}

// https://stackoverflow.com/a/33853856/5441396
func downloadFile(filepath string, url string) (err error) {

	// Create the file
	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()

	// Get the data
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	if resp.StatusCode != 200 {
		return fmt.Errorf("Download from %s failed with statuscode %d", url, resp.StatusCode)
	}
	defer resp.Body.Close()

	// Writer the body to file
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return err
	}

	return nil
}

func getFileFromURLList(filepath string, filename string, urls []string) {
	// no chunked downloads, just tries URLs one by one until it succeeds or fails because no URLs are left
	success := false

	for _, u := range urls {
		parsed, err := url.Parse(u)
		logFatalErr(err)
		err = downloadFile(filepath, parsed.String())
		if err != nil {
			log.Print(err)
		} else {
			success = true
			// log.Printf("Sucessfully fetched %s\n", parsed.String())
			break
		}
	}
	if success == false {
		log.Fatalf("No mirror had the file %s available.\n URLS: %s", filename, urls)
	}
}

func getFileFromMirror(filepath string, filename string, distro string, mirrors []string) {
	urls := make([]string, 0)
	for _, mirror := range mirrors {
		baseURL, err := url.Parse(mirror)
		logFatalErr(err)
		ref, err := url.Parse(path.Join(baseURL.Path, "dists", distro, filename))
		logFatalErr(err)
		urls = append(urls, baseURL.ResolveReference(ref).String())
	}
	getFileFromURLList(filepath, filename, urls)
}

func compareFileWithHash(filepath string, sha256Hash string) bool {
	target, err := hex.DecodeString(sha256Hash)
	logFatalErr(err)

	f, err := os.Open(filepath)
	logFatalErr(err)
	defer f.Close()

	h := sha256.New()
	_, err = io.Copy(h, f)
	logFatalErr(err)

	actual := h.Sum(nil)

	if bytes.Equal(actual, target) != true {
		log.Printf("Hash mismatch: Expected %x, got %x", target, actual)
	}

	return bytes.Equal(actual, target)
}

func checkPgpSignature(keyfile string, checkfile string, sigfile string) {
	key, err := os.Open(keyfile)
	logFatalErr(err)

	sig, err := os.Open(sigfile)
	logFatalErr(err)

	check, err := os.Open(checkfile)
	logFatalErr(err)

	keyring, err := openpgp.ReadArmoredKeyRing(key)
	logFatalErr(err)

	_, err = openpgp.CheckArmoredDetachedSignature(keyring, check, sig)
	logFatalErr(err)
}

func getPackages(arch string, distroType string, distro string, mirrors []string, components []string, pgpKeyFile string) (packages []godebiancontrol.Paragraph) {
	releasefile, err := ioutil.TempFile("", "Release")
	logFatalErr(err)

	releasegpgfile, err := ioutil.TempFile("", "Releasegpg")
	logFatalErr(err)

	// download Release + Release.gpg
	getFileFromMirror(releasefile.Name(), "Release", distro, mirrors)
	getFileFromMirror(releasegpgfile.Name(), "Release.gpg", distro, mirrors)

	// check signature
	checkPgpSignature(pgpKeyFile, releasefile.Name(), releasegpgfile.Name())

	os.Remove(releasegpgfile.Name())

	// read/parse Release file
	release, err := godebiancontrol.Parse(releasefile)
	logFatalErr(err)
	os.Remove(releasefile.Name())

	// this will be the merged Packages file
	packagesfile, err := ioutil.TempFile("", "Packages")
	logFatalErr(err)

	// download all binary-<arch> Packages.gz files
	for _, line := range strings.Split(release[0]["SHA256"], "\n") {
		fields := strings.Fields(line)
		if len(fields) == 0 {
			//last line is an empty line
			continue
		}
		hash := fields[0]
		path := fields[2]
		isAcceptedComponent := true
		if len(components) > 0 {
			isAcceptedComponent = false
			for _, component := range components {
				if strings.HasPrefix(path, component+"/") {
					isAcceptedComponent = true
					break
				}
			}
		}
		if isAcceptedComponent && strings.HasSuffix(path, "/binary-"+arch+"/Packages.gz") {
			tmpPackagesfile, err := ioutil.TempFile("", "Packages")
			logFatalErr(err)
			getFileFromMirror(tmpPackagesfile.Name(), path, distro, mirrors)
			// check hash of Packages.gz files
			if compareFileWithHash(tmpPackagesfile.Name(), hash) != true {
				log.Fatalf("Downloaded file %s corrupt", path)
			}

			// unzip Packages.gz files
			handle, err := os.Open(tmpPackagesfile.Name())
			logFatalErr(err)
			defer handle.Close()

			zipReader, err := gzip.NewReader(handle)
			logFatalErr(err)
			defer zipReader.Close()

			content, err := ioutil.ReadAll(zipReader)
			logFatalErr(err)
			os.Remove(tmpPackagesfile.Name())

			// append content to merged Packages file
			f, err := os.OpenFile(packagesfile.Name(), os.O_APPEND|os.O_WRONLY, 0600)
			logFatalErr(err)
			defer f.Close()

			_, err = f.Write(content)
			logFatalErr(err)
		}
	}

	// read/parse merged Packages file
	parsed, err := godebiancontrol.Parse(packagesfile)
	logFatalErr(err)
	os.Remove(packagesfile.Name())

	return parsed
}

func getMapFieldExpr(expr build.Expr) map[string]string {
	list, ok := expr.(*build.DictExpr)
	if !ok {
		return nil
	}

	m := make(map[string]string)
	for _, l := range list.List {
		key := l.(*build.KeyValueExpr).Key.(*build.StringExpr).Value
		val := l.(*build.KeyValueExpr).Value.(*build.StringExpr).Value
		m[key] = val
	}

	return m
}

func updateWorkspaceRule(rule *build.Rule) {
	tags := rule.AttrStrings("tags")
	for _, tag := range tags {
		// skip rules with the "manual_update" tag
		if tag == "manual_update" {
			return
		}
	}

	arch := rule.AttrString("arch")
	distroType := rule.AttrString("distro_type")
	distro := rule.AttrString("distro")
	mirrors := rule.AttrStrings("mirrors")
	components := rule.AttrStrings("components")
	packages := getMapFieldExpr(rule.Attr("packages"))
	packagesSha256 := getMapFieldExpr(rule.Attr("packages_sha256"))
	pgpKeyRuleName := rule.AttrString("pgp_key")

	packageNames := make([]string, 0, len(packages))
	for p := range packages {
		packageNames = append(packageNames, p)
	}
	sort.Strings(packageNames)

	packageShaNames := make([]string, 0, len(packagesSha256))
	for p := range packages {
		packageShaNames = append(packageShaNames, p)
	}
	sort.Strings(packageShaNames)
	if reflect.DeepEqual(packageNames, packageShaNames) == false {
		log.Fatalf("Mismatch between package names in packages and packages_sha256 in rule %s.\npackages: %s\npackages_sha256: %s", rule.Name(), packageNames, packageShaNames)
	}

	wd, err := os.Getwd()
	logFatalErr(err)
	projectName := path.Base(wd)
	pgpKeyname := path.Join("bazel-"+projectName, "external", pgpKeyRuleName, "file", "downloaded")

	allPackages := getPackages(arch, distroType, distro, mirrors, components, pgpKeyname)

	newPackages := make(map[string]string)
	newPackagesSha256 := make(map[string]string)

	for _, pack := range packageNames {
		packlist := strings.Split(pack, "=")
		var packname string
		var packversion string
		var targetVersion version.Version
		if len(packlist) > 1 && packlist[1] != "latest" {
			packname = packlist[0]
			packversion = packlist[1]
			var err error
			targetVersion, err = version.NewVersion(packlist[1])
			logFatalErr(err)
		} else {
			packname = packlist[0]
			packversion = "latest"
			var err error
			targetVersion, err = version.NewVersion("0")
			logFatalErr(err)
		}

		done := false
		for _, pkg := range allPackages {
			if pkg["Package"] == packname {
				currentVersion, err := version.NewVersion(pkg["Version"])
				logFatalErr(err)
				if packversion == "latest" {
					// iterate over all packages and keep the highest version
					if targetVersion.LessThan(currentVersion) {
						newPackages[pack] = pkg["Filename"]
						newPackagesSha256[pack] = pkg["SHA256"]
						targetVersion = currentVersion
						done = true
					}
				} else {
					// version is fixed, break once found
					if targetVersion.Equal(currentVersion) {
						newPackages[pack] = pkg["Filename"]
						newPackagesSha256[pack] = pkg["SHA256"]
						done = true
						break
					}
				}
			}
		}
		if done == false {
			log.Fatalf("Package %s isn't available in %s (rule: %s)", pack, distro, rule.Name())
		}
	}

	var newPackagesKV []build.Expr
	var newPackagesSha256KV []build.Expr
	for _, pkgName := range packageNames {
		newPackagesKV = append(newPackagesKV, &build.KeyValueExpr{Key: &build.StringExpr{Value: pkgName}, Value: &build.StringExpr{Value: newPackages[pkgName]}})
		newPackagesSha256KV = append(newPackagesSha256KV, &build.KeyValueExpr{Key: &build.StringExpr{Value: pkgName}, Value: &build.StringExpr{Value: newPackagesSha256[pkgName]}})
	}
	rule.SetAttr("packages", &build.DictExpr{List: newPackagesKV})
	rule.SetAttr("packages_sha256", &build.DictExpr{List: newPackagesSha256KV})
}

func updateWorkspace(workspaceContents []byte) string {
	f, err := build.Parse("WORKSPACE", workspaceContents)
	logFatalErr(err)

	for _, rule := range f.Rules("deb_packages") {
		updateWorkspaceRule(rule)
	}

	return string(build.Format(f))
}

// update WORKSPACE rule with new paths/hashes from mirrors
func main() {
	workspacefile, err := os.Open("WORKSPACE")
	logFatalErr(err)
	wscontent, err := ioutil.ReadAll(workspacefile)
	logFatalErr(err)
	workspacefile.Close()

	err = ioutil.WriteFile("WORKSPACE", []byte(updateWorkspace(wscontent)), 0664)
	logFatalErr(err)
}
