#!/usr/bin/env python3
import subprocess

package = subprocess.check_output(["dpkg-parsechangelog", "-SSource"]).decode().replace("\n", "")

git_repo_salsa = subprocess.check_output(
	"apt source --dry-run {} | grep 'git clone'"
	.format(package), shell=True
	).decode().replace("git clone", "").strip()

git_add_return = subprocess.call(["git", "remote", "add", "salsa", git_repo_salsa])

if git_add_return == 0:
    print("remote 'salsa' was successfully added.")
else:
    print("Couldn't add remote 'salsa'")
