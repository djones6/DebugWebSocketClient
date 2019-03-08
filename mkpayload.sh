#!/bin/bash

dd if=/dev/zero of=256k.bin bs=1024 count=256
dd if=/dev/zero of=128k.bin bs=1024 count=128
dd if=/dev/zero of=64k.bin bs=1024 count=64
dd if=/dev/zero of=32k.bin bs=1024 count=32
dd if=/dev/zero of=16k.bin bs=1024 count=16
dd if=/dev/zero of=8k.bin bs=1024 count=8
