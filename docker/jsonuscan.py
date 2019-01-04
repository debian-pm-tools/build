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
parser.add_argument("-c", "--currentversion", action="store_true", default=False,
                    help="Show information about the current, not the latest version",
                    )
args = parser.parse_args()

# Run uscan subprocess
uscancommand = ["uscan", "--dehs", "--report"]
if args.currentversion:
	uscancommand.append("--download-current-version")
uscanout = subprocess.check_output(uscancommand).decode()
uscandict = xmltodict.parse(uscanout)

# Print result
if args.field:
	print(uscandict["dehs"][args.field])
else:
	print(json.dumps(uscandict, sort_keys=True, indent=4))
