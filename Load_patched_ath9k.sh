#!/bin/bash

# ---- UNLOAD stock / currently loaded modules ----

lsmod | grep ath

sudo rmmod ath9k_htc
sudo rmmod ath9k_hw
sudo rmmod ath9k_common
sudo rmmod ath

lsmod | grep ath

# ---- LOAD patched modules ----

cd ~/ath9k-build
sudo insmod ath.ko
sudo insmod ath9k/ath9k_hw.ko
sudo insmod ath9k/ath9k_common.ko
sudo insmod ath9k/ath9k_htc.ko

lsmod | grep ath

dmesg | tail -30

iw reg get

# ---- To go back to stock later, unload the patched set the same way, ----
# ---- then reload with modprobe instead of insmod: ----

# sudo rmmod ath9k_htc
# sudo rmmod ath9k_hw
# sudo rmmod ath9k_common
# sudo rmmod ath
# sudo modprobe ath9k_htc
