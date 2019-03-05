#!/usr/bin/env python3
import subprocess
import requests
import json
import urllib.parse
import sys

def cleanUp():
    subprocess.call(["git", "remote", "remove", "salsa"])

#
# Find out which version of the package is in testing
#

suite = "testing" # The case for all debian-pm packages
package = subprocess.check_output(["dpkg-parsechangelog", "-SSource"]).decode().replace("\n", "")
version_local = subprocess.check_output(["dpkg-parsechangelog", "-SVersion"]).decode().replace("\n", "")
distribution = subprocess.check_output(["dpkg-parsechangelog", "-SDistribution"]).decode().replace("\n", "")

version_debian = json.loads(
	requests.get(
		"https://api.ftp-master.debian.org/dsc_in_suite/"
		+ suite + "/"
		+ package)
	.content.decode()
	)[0]["version"]
version_debian_no_revision = version_debian.split(":", 1)[-1]

final_version = version_debian + "dpm1"

if version_debian in version_local:
    print("Rebase not neccesary")
    sys.exit()

print("Package: {}".format(package))
print("Local Version: {}".format(version_local))
print("Debian Version: {}".format(version_debian))


#
# Find git tag on salsa
#

# Find git repo
git_repo_salsa = subprocess.check_output(
	"apt source --dry-run {} | grep 'git clone'"
	.format(package), shell=True
	).decode().replace("git clone", "").strip()

print("Found git repository {}".format(git_repo_salsa))

subprocess.call(["git", "remote", "add", "salsa", git_repo_salsa])
subprocess.call(["git", "fetch", "salsa", "--quiet"])

# Find git tag
tags = []
for line in  subprocess.check_output(["git", "tag"]).decode().split("\n"):
	tags.append(urllib.parse.unquote(line))

for tag in tags:
	if version_debian_no_revision in tag and not "ubuntu" in tag:
		print("Found tag {}".format(tag))
		git_ref = tag

if not "git_ref" in globals():
	print("No tag found, trying master")
	git_ref = "salsa/master"

#
# Extract Changelog message
#

changelog_messages = subprocess.check_output(["dpkg-parsechangelog", "-SChanges"]).decode().split("\n")[3:]
changelog_message = ""
for message in changelog_messages:
	text = message + "\n"
	changelog_message += text

print("Found changelog messages:\n" + changelog_message)


#
# Merge tag and rebase changelog
#

subprocess.call(["git", "checkout", git_ref, "--", "debian/changelog"])
if not subprocess.check_output(["dpkg-parsechangelog", "-SVersion"]).decode().strip() == version_debian:
	print("The changelog from salsa doesn't contain the required version, exiting")
	cleanUp()
	sys.exit()

subprocess.call(["git", "add", "debian/changelog"])
subprocess.call(["git", "commit", "-m", "Reset changelog for rebasing"])

subprocess.call(["git", "merge", git_ref])

for message in changelog_messages:
	subprocess.call(["dch", "-v", final_version, message.replace("*", "").strip()])

subprocess.call(["dch", "--release", "-D", distribution])
subprocess.call(["git", "add", "debian/changelog"])
subprocess.call(["git", "commit", "--amend", "-m", "Rebase changelog on {}".format(git_ref)])

#
# Clean up
#

cleanUp()
