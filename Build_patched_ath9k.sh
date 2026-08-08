#!/bin/bash

# check the exact running kernel version, needed to match headers and git tag
uname -r

# refresh package lists
sudo apt update

# install headers matching the running kernel, plus build tools and git
sudo apt install -y linux-headers-$(uname -r) build-essential git

# list available v7.x tags on the kernel.org mirror to find the matching release
git ls-remote --tags https://github.com/torvalds/linux.git | grep -oP 'v7\.\d+(\.\d+)?$' | sort -V | tail -20

# change v7.0 in the command to whatever Kernel version. make sure the version is available (previous coomand output) 
# sparse-clone the kernel repo at the matching tag, no full history/blobs
git clone --depth 1 --branch v7.0 --filter=blob:none --sparse https://github.com/torvalds/linux.git ~/linux-ath-src
cd ~/linux-ath-src

# only check out the ath wireless driver directory, not the whole tree
git sparse-checkout set drivers/net/wireless/ath

# confirm the ath9k_htc driver and regd.c/regd.h files are present
ls drivers/net/wireless/ath

# view the CTRY_DEFAULT fallback block in regd.c to confirm it matches what we found before
cat drivers/net/wireless/ath/regd.c | grep -n -B2 -A6 'CTRY_DEFAULT'

# confirm CTRY_UNITED_KINGDOM enum exists in regd.h
grep -n 'CTRY_UNITED_KINGDOM' drivers/net/wireless/ath/regd.h

# confirm regd.c actually includes regd.h, so the enum is in scope
grep -n '#include' drivers/net/wireless/ath/regd.c

# patch the CTRY_DEFAULT fallback from US to UK
sed -i 's/reg->country_code = CTRY_UNITED_STATES;/reg->country_code = CTRY_UNITED_KINGDOM;/' drivers/net/wireless/ath/regd.c

# verify the patch applied correctly
grep -n -B2 -A6 'CTRY_DEFAULT &&' drivers/net/wireless/ath/regd.c

# copy the patched driver source out to a dedicated build directory
cp -r drivers/net/wireless/ath ~/ath9k-build
cd ~/ath9k-build

# confirm the kernel build directory exists for the running kernel
ls /lib/modules/$(uname -r)/build

# build the modules out-of-tree against the running kernel's headers
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

# list all compiled .ko files produced by the build
find ~/ath9k-build -name "*.ko"
