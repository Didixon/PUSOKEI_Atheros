# PUSOKEI AR9271 ath9k_htc Regulatory Domain Patch

A patch for the **PUSOKEI Atheros AR9271** USB Wi-Fi adapter to enable monitoring and scanning on all channels (1–13) in the UK and most of Europe and Asia.

The patch is **non-persistent**. You compile the patched driver once, and after every reboot (or whenever you want to use the Wi-Fi adapter with the full channel range) you unload the stock kernel modules and load the patched ones instead.

## Background

This adapter's EEPROM does not have a regulatory domain programmed. As a result, the `ath9k_htc` driver in Kali Linux falls back to a hardcoded **United States** default, regardless of your local regulatory domain settings. This limits the adapter to channels 1–11 only.

The fallback happens in [`regd.c`](https://github.com/torvalds/linux/blob/master/drivers/net/wireless/ath/regd.c) in the mainline Linux kernel:

```c
if (reg->country_code == CTRY_DEFAULT &&
    regdmn == CTRY_DEFAULT) {
        printk(KERN_DEBUG "ath: EEPROM indicates default "
               "country code should be used\n");
        reg->country_code = CTRY_UNITED_STATES;
}
```

This patch changes `CTRY_UNITED_STATES` to `CTRY_UNITED_KINGDOM`. This works for the UK, most of Europe, and most of Asia, since the majority of countries in those regions permit Wi-Fi channels 1–13 (2.412–2.472 GHz). It does not apply to devices whose EEPROM already has a valid country code or regulatory domain programmed — this fallback only triggers when both are unset (`CTRY_DEFAULT`).

**Note:** I have not tested whether this patch also enables deauthentication or packet injection functionality, since my use case only required scanning. I expect it should, but this is unverified.

## Requirements

- Kali Linux (or any distro using the `ath9k_htc` driver)
- PUSOKEI AR9271 (or another ath9k_htc-based adapter exhibiting the same EEPROM/regulatory fallback behavior)
- `git`, `build-essential`, and kernel headers matching your running kernel

## Files

| File | Purpose |
|---|---|
| `build-patched-ath9k.sh` | Commands to fetch the matching kernel source, apply the patch, and compile the driver |
| `load-patched-ath9k.sh` | Commands to unload the stock driver and load the patched one (and revert back) |

## Usage

**Do not run `build-patched-ath9k.sh` directly.** Run each command one by one so you can:

1. Confirm the driver compiles cleanly for your exact kernel version.
2. Catch and troubleshoot any unexpected errors as they happen, rather than partway through an unattended script.

Once the patched driver is compiled, run `load-patched-ath9k.sh` line by line to unload the stock `ath9k_htc` modules from memory and load the patched ones in their place.

Plug in the Wi-Fi adapter and confirm channels 12–13 are listed and `iw reg get` reports `country GB`:

```
$ iwlist wlan1 frequency
wlan1     13 channels in total; available frequencies :
          Channel 01 : 2.412 GHz
          Channel 02 : 2.417 GHz
          Channel 03 : 2.422 GHz
          Channel 04 : 2.427 GHz
          Channel 05 : 2.432 GHz
          Channel 06 : 2.437 GHz
          Channel 07 : 2.442 GHz
          Channel 08 : 2.447 GHz
          Channel 09 : 2.452 GHz
          Channel 10 : 2.457 GHz
          Channel 11 : 2.462 GHz
          Channel 12 : 2.467 GHz
          Channel 13 : 2.472 GHz

$ iw reg get
...
phy#1
country GB: DFS-ETSI
        (2400 - 2483 @ 40), (N/A, 20), (N/A)
        (5150 - 5250 @ 80), (N/A, 23), (N/A), NO-OUTDOOR, AUTO-BW
        (5250 - 5350 @ 80), (N/A, 20), (0 ms), NO-OUTDOOR, DFS, AUTO-BW
        (5470 - 5730 @ 160), (N/A, 26), (0 ms), DFS
        (5725 - 5850 @ 80), (N/A, 23), (N/A), NO-OUTDOOR
        (5925 - 6425 @ 320), (N/A, 23), (N/A), NO-OUTDOOR
        (57000 - 71000 @ 2160), (N/A, 40), (N/A)
```

## Reloading after reboot

The patch is not persisted into the system's module tree (`/lib/modules/$(uname -r)/kernel/`), so a reboot always reverts you to the stock driver. To bring the patched driver back:

```bash
cd ~/ath9k-build
sudo rmmod ath9k_htc
sudo rmmod ath9k_hw
sudo rmmod ath9k_common
sudo rmmod ath
sudo insmod ath.ko
sudo insmod ath9k/ath9k_hw.ko
sudo insmod ath9k/ath9k_common.ko
sudo insmod ath9k/ath9k_htc.ko
```

See `load-patched-ath9k.sh` for the full command sequence, including how to revert to the stock driver with `modprobe`.

## Disclaimer

This patch overrides regulatory enforcement that the driver would otherwise apply based on your system's locale. Confirm that operating on channels 12–13 is permitted in your jurisdiction before transmitting, and use this only where you're authorised to do so.
