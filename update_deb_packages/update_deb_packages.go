package main

import (
	"bufio"
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"flag"
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
	"time"

	"github.com/bazelbuild/buildtools/build"
	"golang.org/x/crypto/openpgp"
	"pault.ag/go/debian/control"
	"pault.ag/go/debian/version"
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
	if !success {
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

	if !bytes.Equal(actual, target) {
		log.Printf("Hash mismatch: Expected %x, got %x", target, actual)
	}

	return bytes.Equal(actual, target)
}

func checkPgpSignature(keyring openpgp.EntityList, checkfile string, sigfile string) {
	sig, err := os.Open(sigfile)
	logFatalErr(err)

	check, err := os.Open(checkfile)
	logFatalErr(err)

	_, err = openpgp.CheckArmoredDetachedSignature(keyring, check, sig)
	if err == io.EOF {
		// When the signature is binary instead of armored, the error is io.EOF.
		// Let's try with binary signatures as well
		_, err = check.Seek(0, 0)
		logFatalErr(err)

		_, err = sig.Seek(0, 0)
		logFatalErr(err)

		_, err = openpgp.CheckDetachedSignature(keyring, check, sig)
		logFatalErr(err)
	} else {
		logFatalErr(err)
	}
}

func getPackages(arch string, distro string, mirrors []string, components []string, keyring openpgp.EntityList) (packages []control.BinaryIndex) {
	releasefile, err := ioutil.TempFile("", "Release")
	logFatalErr(err)

	releasegpgfile, err := ioutil.TempFile("", "Releasegpg")
	logFatalErr(err)

	// download Release + Release.gpg
	getFileFromMirror(releasefile.Name(), "Release", distro, mirrors)
	getFileFromMirror(releasegpgfile.Name(), "Release.gpg", distro, mirrors)

	// check signature
	checkPgpSignature(keyring, releasefile.Name(), releasegpgfile.Name())

	os.Remove(releasegpgfile.Name())

	// read/parse Release file
	releaseReader, err := control.NewParagraphReader(releasefile, nil)
	logFatalErr(err)
	release, err := releaseReader.All()
	logFatalErr(err)
	os.Remove(releasefile.Name())

	// this will be the merged Packages file
	packagesfile, err := ioutil.TempFile("", "Packages")
	logFatalErr(err)

	// download all binary-<arch> Packages.gz files
	for _, line := range strings.Split(release[0].Values["SHA256"], "\n") {
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
			if !compareFileWithHash(tmpPackagesfile.Name(), hash) {
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
	parsed, err := control.ParseBinaryIndex(bufio.NewReader(packagesfile))
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
		key := l.Key.(*build.StringExpr).Value
		val := l.Value.(*build.StringExpr).Value
		m[key] = val
	}

	return m
}

func getKeyRing(projectName string, pgpKeys []string) openpgp.EntityList {
	keyring := make(openpgp.EntityList, 0)
	for _, pgpKeyRuleName := range pgpKeys {
		keyfile := path.Join("bazel-"+projectName, pgpKeyRuleName)

		key, err := os.Open(keyfile)
		logFatalErr(err)

		entry, err := openpgp.ReadArmoredKeyRing(key)
		logFatalErr(err)

		keyring = append(keyring, entry[0])
	}
	return keyring
}

func updateWorkspaceRule(keyring openpgp.EntityList, rule *build.Rule) {
	tags := rule.AttrStrings("tags")
	for _, tag := range tags {
		// skip rules with the "manual_update" tag
		if tag == "manual_update" {
			return
		}
	}

	arch := rule.AttrString("arch")
	sources := rule.AttrStrings("sources")
	packages := getMapFieldExpr(rule.Attr("packages"))
	packagesSha256 := getMapFieldExpr(rule.Attr("packages_sha256"))
	timestamp := rule.AttrString("timestamp")

	packageNames := make([]string, 0, len(packages))
	for p := range packages {
		packageNames = append(packageNames, p)
	}
	sort.Strings(packageNames)

	packageShaNames := make([]string, 0, len(packagesSha256))
	for p := range packagesSha256 {
		packageShaNames = append(packageShaNames, p)
	}
	sort.Strings(packageShaNames)
	if !reflect.DeepEqual(packageNames, packageShaNames) {
		log.Fatalf("Mismatch between package names in packages and packages_sha256 in rule %s.\npackages: %s\npackages_sha256: %s", rule.Name(), packageNames, packageShaNames)
	}

	t := time.Now().UTC()

	var mirrors = make([]string, 0)
	var allPackages []control.BinaryIndex
	for _, source := range sources {
		sourceComponents := strings.Split(source, " ")
		if len(sourceComponents) < 2 {
			log.Fatalf("Invalid format of source '%s'. Should be <url>|<distro>|<components>", source)
		}
		baseURL := strings.TrimRight(sourceComponents[0], "/")
		distro := sourceComponents[1]
		var distroComponents []string
		if len(sourceComponents) > 2 {
			distroComponents = sourceComponents[2:]
		}

		log.Printf("Fetching packages for [%s] %s %s %s", arch, sourceComponents[0], distro, distroComponents)
		packages := getPackages(arch, distro, []string{baseURL}, distroComponents, keyring)
		allPackages = append(allPackages, packages...)
		mirrors = appendUniq(mirrors, baseURL)
	}

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
			targetVersion, err = version.Parse(packlist[1])
			logFatalErr(err)
		} else {
			packname = packlist[0]
			packversion = "latest"
			var err error
			targetVersion, err = version.Parse("0")
			logFatalErr(err)
		}

		done := false
		for _, pkg := range allPackages {
			if pkg.Package == packname {
				currentVersion := pkg.Version
				if packversion == "latest" {
					// iterate over all packages and keep the highest version
					if version.Compare(targetVersion, currentVersion) < 0 {
						newPackages[pack] = pkg.Filename
						newPackagesSha256[pack] = pkg.SHA256
						targetVersion = currentVersion
						done = true
					}
				} else {
					// version is fixed, break once found
					if version.Compare(targetVersion, currentVersion) == 0 {
						newPackages[pack] = pkg.Filename
						newPackagesSha256[pack] = pkg.SHA256
						done = true
						break
					}
				}
			}
		}
		if !done {
			log.Fatalf("Package %s isn't available (rule: %s)", pack, rule.Name())
		}
	}

	var newPackagesKV []*build.KeyValueExpr
	var newPackagesSha256KV []*build.KeyValueExpr
	for _, pkgName := range packageNames {
		newPackagesKV = append(newPackagesKV, &build.KeyValueExpr{Key: &build.StringExpr{Value: pkgName}, Value: &build.StringExpr{Value: newPackages[pkgName]}})
		newPackagesSha256KV = append(newPackagesSha256KV, &build.KeyValueExpr{Key: &build.StringExpr{Value: pkgName}, Value: &build.StringExpr{Value: newPackagesSha256[pkgName]}})
	}
	if timestamp != "" && !reflect.DeepEqual(packagesSha256, newPackagesSha256) {
		timestamp = fmt.Sprintf("%d%02d%02dT%02d%02d%02dZ", t.Year(), t.Month(), t.Day(), t.Hour(), t.Minute(), t.Second())
		rule.SetAttr("timestamp", &build.StringExpr{Value: timestamp})
	}
	rule.SetAttr("packages", &build.DictExpr{List: newPackagesKV, ForceMultiLine: true})
	rule.SetAttr("packages_sha256", &build.DictExpr{List: newPackagesSha256KV, ForceMultiLine: true})
}

func updateFile(keyring openpgp.EntityList, filename string, fileContents []byte) string {
	f, err := build.Parse(filename, fileContents)
	logFatalErr(err)

	for _, rule := range f.Rules("deb_packages") {
		updateWorkspaceRule(keyring, rule)
	}

	return string(build.Format(f))
}

type keyRingFiles []string

func (i *keyRingFiles) String() string {
	return "my key ring files"
}

func (i *keyRingFiles) Set(value string) error {
	*i = append(*i, value)
	return nil
}

var keyRingFilesFlags keyRingFiles

// update WORKSPACE rule with new paths/hashes from mirrors
func main() {
	flag.Var(&keyRingFilesFlags, "pgp-key", "Location of a PGP key to include")
	flag.Parse()

	wd, err := os.Getwd()
	logFatalErr(err)
	projectName := path.Base(wd)
	keyring := getKeyRing(projectName, keyRingFilesFlags)

	workspacefile, err := os.Open("WORKSPACE")
	logFatalErr(err)
	wscontent, err := ioutil.ReadAll(workspacefile)
	logFatalErr(err)
	workspacefile.Close()

	err = ioutil.WriteFile("WORKSPACE", []byte(updateFile(keyring, "WORKSPACE", wscontent)), 0664)
	logFatalErr(err)

	for _, fileName := range flag.Args() {
		bzlFile, err := os.Open(fileName)
		logFatalErr(err)
		bzlContent, err := ioutil.ReadAll(bzlFile)
		logFatalErr(err)
		bzlFile.Close()

		err = ioutil.WriteFile(fileName, []byte(updateFile(keyring, fileName, bzlContent)), 0664)
		logFatalErr(err)
	}
}
