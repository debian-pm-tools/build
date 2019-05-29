#!/usr/bin/env python3
#
# depends on python3-xmltodict
#

import subprocess
import xmltodict
import json
import argparse

# Parser
parser = argparse.ArgumentParser(description="json wrapper for uscan")
parser.add_argument("-f", "--field",
                    help="Field to output. All are printed as json if empty"
                    )
parser.add_argument("-d", "--download", action="store_true", default=False,
                    help="Download the new upstream release, not only show information about it"
                    )
args, pass_args = parser.parse_known_args()

# Run uscan subprocess
uscancommand = ["uscan", "--dehs"] + pass_args

if not args.download:
	uscancommand.append("--report")

try:
	uscanout = subprocess.check_output(uscancommand).decode()
except subprocess.CalledProcessError as error:
	uscanout = error.output

try:
	uscandict = xmltodict.parse(uscanout)
except:
	print("Could not parse uscan output:")
	for line in uscanout.split("\n"):
		print("#" + " " * 4 + line)

# Print result
if args.field:
	print(uscandict["dehs"][args.field])
else:
	print(json.dumps(uscandict, sort_keys=True, indent=4))
