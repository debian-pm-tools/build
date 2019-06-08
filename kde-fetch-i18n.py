#!/usr/bin/env python3

import requests
import os
import subprocess
from bs4 import BeautifulSoup
import sys

def get(url):
	# Spam detection seems to block non-real browsers quickly
	headers = {"user-agent": "Mozilla/5.0 (X11; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0"}
	return requests.get(url, headers=headers)

def detect_component(languages, module):
	for lang in languages:
		# Extract all directories (components)
		soup = BeautifulSoup(get("https://websvn.kde.org/trunk/l10n-kf5/{}/messages/".format(lang)).text, features="lxml")
		for item in soup.findAll("a", {"title": "View directory contents"}):
			# Soup extracted urls
			componentSoup = BeautifulSoup(get("https://websvn.kde.org/" + item["href"]).text, features="lxml")

			# check whether the wanted module exists in the component
			for a in componentSoup.findAll("a", {"title": "View file revision log"}):
				if module in a["name"]:
					print("Got component", item["name"], "in", lang)
					return item["name"]

def detect_files(component, module):
	lang = "es" # Files seem to be the same in all languages, only check one language
	files = []

	soup = BeautifulSoup(get("https://websvn.kde.org/trunk/l10n-kf5/{}/messages/{}".format(lang, component)).text, features="lxml")

	for a in soup.findAll("a", {"title": "View file revision log"}):
		if module in a["name"]:
			files.append(a["name"])

	print("Got files", set(files))
	return set(files)

def add_i18n_to_cmake(podir):
	file = open("CMakeLists.txt", "a")
	file.write(
		"\n".join(
			[
			"find_package(KF5I18n CONFIG REQUIRED)",
			"ki18n_install({})".format(podir)
			]
		)
	)

def mkdir_if_neccesary(path):
	if not os.path.isdir(path):
		os.mkdir(path)

def main():
	print("Fetching list of available languages ...")
	request = get("https://websvn.kde.org/*checkout*/trunk/l10n-kf5/subdirs")

	LANGUAGES = request.text.split("\n")
	PODIR = "po"

	# Use source dir from command line arg as source dir
	try:
		SOURCE_DIR = sys.argv[1]
	except:
		SOURCE_DIR = os.getcwd()

	os.chdir(SOURCE_DIR)

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

			# detect KDE component
			print("Detecting component ...")
			component = detect_component(["de", "es"] + LANGUAGES, module) # Prefer most common languages to speed up search

			print("Detecting files to download ...")
			files = detect_files(component, module)

			for lang in LANGUAGES:
				mkdir_if_neccesary(PODIR + "/" + lang)

				for file in files:
					request = get("https://websvn.kde.org/*checkout*/trunk/l10n-kf5/{}/messages/{}/{}".format(lang, component, file))

					if request.status_code == requests.codes.ok:
						print("Downloading", file, "for", lang)
						pofile = open(PODIR + "/" + lang + "/" + file, "w")
						pofile.write(request.text)
						pofile.close

	add_i18n_to_cmake(PODIR)

if __name__ == "__main__":
	main()
