#!/usr/bin/env python3

from typing import Set
import requests
import os
import subprocess
from bs4 import BeautifulSoup
import sys
import pathlib

def get(url: str) -> requests.Response:
	# Spam detection seems to block non-real browsers quickly
	headers = {"user-agent": "Mozilla/5.0 (X11; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0"}
	return requests.get(url, headers=headers)

def detect_files(component: str, module: str) -> Set[str]:
	lang = "es" # Files seem to be the same in all languages, only check one language
	files = []

	soup = BeautifulSoup(get("https://websvn.kde.org/trunk/l10n-kf5/{}/messages/{}".format(lang, component)).text, features="lxml")

	for a in soup.findAll("a", {"title": "View file revision log"}):
		if module in a["name"]:
			files.append(a["name"])

	print("Got files", set(files))
	return set(files)

def add_i18n_to_cmake(srcdir: str, podir: str) -> None:
	existing_lines = [line.strip() for line in open(srcdir + "/CMakeLists.txt", "r").readlines()]
	file = open(srcdir + "/CMakeLists.txt", "a")

	def write_line_if_not_exists(line: str) -> None:
		if line in existing_lines:
			return

		file.write(line + "\n")

	file.write("\n")
	write_line_if_not_exists("find_package(KF5I18n CONFIG REQUIRED)")

	relative_podir = podir.replace(srcdir, "").strip("/")
	write_line_if_not_exists("ki18n_install({})".format(relative_podir))
	file.close()

def mkdir_if_neccesary(path: str) -> None:
	if not os.path.isdir(path):
		os.mkdir(path)

def main() -> None:
	print("Fetching list of available languages ...")
	request = get("https://websvn.kde.org/*checkout*/trunk/l10n-kf5/subdirs")

	LANGUAGES = request.text.split("\n")

	# Use source dir from command line arg as source dir
	try:
		SOURCE_DIR = sys.argv[1]
	except:
		SOURCE_DIR = os.getcwd()

	PODIR = SOURCE_DIR + "/po"

	# Create po folder
	mkdir_if_neccesary(PODIR)

	# find translation modules and iterate
	message_files = list(
		filter( # Filter out empty results
			None, subprocess.check_output( # Find all Messages.sh files
				["find", SOURCE_DIR, "-name", "Messages.sh"]
			).decode().split("\n") # Split into list
		)
	)

	if len(message_files) == 0:
		print("No Messages.sh files found, cannot continue")
		sys.exit(1)

	for file in message_files:
		# Make sure path returned from find is not empty
		if file == "":
			continue

		messagessh = open(file, "r").read().split("\n")

		for line in messagessh:
			# Skip lines not writing to a message catalog
			if not "-o $podir" in line:
				continue

			# Extract module name
			module = line.split("-o")[-1].split("/")[1].replace(".pot", "").strip()
			print("Fetching translations for", module, "...")

			component = pathlib.Path(SOURCE_DIR).name

			print("Detecting files to download ...")
			files = detect_files(component, module)

			for lang in LANGUAGES:
				mkdir_if_neccesary(PODIR + "/" + lang)

				for file in files:
					if "_desktop_" in file or ".appdata." in file:
						continue

					request = get("https://websvn.kde.org/*checkout*/trunk/l10n-kf5/{}/messages/{}/{}".format(lang, component, file))

					# Check if file is available in that language
					if request.status_code == requests.codes.ok:
						print("Downloading", file, "for", lang)
						pofile = open(PODIR + "/" + lang + "/" + file, "w")
						pofile.write(request.text)
						pofile.close

	add_i18n_to_cmake(SOURCE_DIR, PODIR)

if __name__ == "__main__":
	main()
