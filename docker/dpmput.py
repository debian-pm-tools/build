#!/usr/bin/env python3

import argparse

from debian.deb822 import Dsc, Changes

import os

from typing import List

import aiohttp
import asyncio

async def handle_response(resp: aiohttp.ClientResponse):
    output = await resp.content.read()
    print(output.decode())

    if resp.status != 200:
        exit(1)


async def put_deb_package(host: str, user: str, password: str, dist: str, file: str):
    async with aiohttp.ClientSession(auth=aiohttp.BasicAuth(login=user, password=password)) as session:
        await handle_response(await session.put(f"{host}/includedeb/{dist}/", data = open(file, "rb")))

async def post_package_multipart(url: str, upload_type: str, meta: str, attachments: List[str], user: str, password: str):
        async with aiohttp.ClientSession(auth=aiohttp.BasicAuth(user, password)) as session:
            form_data = aiohttp.FormData([])
            for file in attachments:
                form_data.add_field("attachments", open(file, "rb"))

            form_data.add_field(upload_type, open(meta, "rb"))

            async with session.post(url, data=form_data) as response:
                await handle_response(response)

async def put_changes_file(host: str, user: str, password: str, dist: str, file: str):
    with open(file) as fh:
        changes = Changes(fh)

        dir: str = os.path.dirname(file)
        files: List[str] = [dir + "/" + file["name"] for file in changes["files"]]

        await post_package_multipart(f"{host}/include/{dist}", "changes", file, files, user, password)

async def put_dsc_package(host: str, user: str, password: str, dist: str, file: str):
    with open(file) as fh:
        dsc = Dsc(fh)

        dir: str = os.path.dirname(file)
        files: List[str] = [dir + "/" + file["name"] for file in dsc["files"]]

        await post_package_multipart(f"{host}/includedsc/{dist}", "dsc", file, files, user, password)

async def upload_file(file: str):
    print(f"-- Uploading {file}")
    if file.endswith(".deb"):
        await put_deb_package(args.host, args.user, args.password, args.distribution, file)
    elif file.endswith(".dsc"):
       await put_dsc_package(args.host, args.user, args.password, args.distribution, file)
    elif file.endswith(".changes"):
        await put_changes_file(args.host, args.user, args.password, args.distribution, file)
    else:
        print("Unsupported file passed")
        exit(1)

async def main():
    for file in args.files:
        await upload_file(file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload packages")
    parser.add_argument("--host", type=str, required=True)
    parser.add_argument("--files", type=str, nargs="*", required=True)
    parser.add_argument("--user", type=str, required=True)
    parser.add_argument("--password", type=str, required=True)
    parser.add_argument("--distribution", type=str, required=True)

    args = parser.parse_args()

    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
