#!/usr/bin/env python3

import argparse
from io import BufferedReader
import requests

from requests import Response
from requests.auth import HTTPDigestAuth

from debian.deb822 import Dsc, Changes

import os

from typing import List, Set, Tuple

def handle_response(resp: Response):
    print(resp.content.decode())

    if resp.status_code != 200:
        exit(1)


def put_deb_package(host: str, user: str, password: str, dist: str, file: str) -> Response:
    return requests.put(f"{host}/includedeb/{dist}/",
                 data = open(file, "rb"),
                 auth=HTTPDigestAuth(user, password))

def put_changes_file(host: str, user: str, password: str, dist: str, file: str) -> Response:
    with open(file) as fh:
        changes = Changes(fh)

        files: List[str] = [file["name"] for file in changes["files"]]
        dir: str = os.path.dirname(file)
        attachments: List[Tuple[str, BufferedReader]] = [("attachments", open(dir + "/" + file, "rb")) for file in files]
        attachments.append(("changes", open(file, "rb")))

        return requests.post(f"{host}/include/{dist}/",
                      files = attachments,
                      auth=HTTPDigestAuth(user, password))

def put_dsc_package(host: str, user: str, password: str, dist: str, file: str) -> Response:
    with open(file) as fh:
        dsc = Dsc(fh)

        files: List[str] = [file["name"] for file in dsc["files"]]
        dir: str = os.path.dirname(file)
        attachments: List[Tuple[str, BufferedReader]] = [("attachments", open(dir + "/" + file, "rb")) for file in files]
        attachments.append(("dsc", open(file, "rb")))

        return requests.post(f"{host}/includedsc/{dist}",
                                     files = attachments,
                                     auth=HTTPDigestAuth(user, password))

def upload_file(file: str) -> Response:
    print(f"-- Uploading {file}")
    if file.endswith(".deb"):
        return put_deb_package(args.host, args.user, args.password, args.distribution, file)
    elif file.endswith(".dsc"):
       return put_dsc_package(args.host, args.user, args.password, args.distribution, file)
    elif file.endswith(".changes"):
        return put_changes_file(args.host, args.user, args.password, args.distribution, file)
    else:
        print("Unsupported file passed")
        exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload packages")
    parser.add_argument("--host", type=str, required=True)
    parser.add_argument("--files", type=str, nargs="*", required=True)
    parser.add_argument("--user", type=str, required=True)
    parser.add_argument("--password", type=str, required=True)
    parser.add_argument("--distribution", type=str, required=True)

    args = parser.parse_args()

    for file in args.files:
        handle_response(upload_file(file))
