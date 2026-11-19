#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Wrap a raw u-boot in the 512 byte Unisoc DHTB header the ums512 SPL expects.
# Format from https://github.com/beebono/ums512_spl (scripts/dhtb_pack.py).

import hashlib
import struct
import sys

UBOOT_MAX_SIZE = 1024 * 1024

payload = open(sys.argv[1], "rb").read()
if len(payload) + 1024 > UBOOT_MAX_SIZE:
    sys.exit("u-boot payload too large for the SPL: %d bytes" % len(payload))

header = bytearray(512)
header[0:4] = b"DHTB"
struct.pack_into("<I", header, 0x04, 1)
header[0x08:0x28] = hashlib.sha256(payload).digest()
struct.pack_into("<I", header, 0x30, len(payload))

# The SPL reads mImgSize plus a 1 KiB cert area; pad so that read stays in the image.
open(sys.argv[2], "wb").write(bytes(header) + payload + b"\0" * 1024)
