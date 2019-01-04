#!/usr/bin/env python3
#
# depends on python3-xmltodict
#

import subprocess
import xmltodict
import json
import argparse


parser = argparse.ArgumentParser(description="json wrapper for uscan")
parser.add_argument("-f", "--field", help="Field to output. All are printed as json if empty")
args = parser.parse_args()


uscanout = subprocess.check_output(["uscan", "--dehs", "--report"]).decode()
uscandict = xmltodict.parse(uscanout)

if args.field:
	print(uscandict["dehs"][args.field])
else:
	print(json.dumps(uscandict, sort_keys=True, indent=4))
