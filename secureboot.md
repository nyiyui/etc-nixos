# Secure Boot
Note: these is a highly abridged version of [Lanzaboote's Quickstart](https://github.com/nix-community/lanzaboote/blob/995637eb3ab78eac33f8ee6b45cc2ecd5ede12ba/docs/QUICK_START.md).

## Prerequisites
- Check `bootctl status` - bootloader is `systemd-boot` and firmware is `UEFI`
- Use full disk encryption
  - Secret! files stored in `/etc/secureboot` etc
- Set a BIOS password
  - ThinkPad: Supervisor Password has higher prio than System Management Password

## Create Keys
`sudo sbctl create-keys`

## Nix System Config
Import `./secureboot.nix` to your system config.

## Verify Install Worked
`sudo sbctl verify`

## Enter Secure Boot's Setup Mode
trivial

## Enroll Keys
`sudo sbctl enroll-keys -microsoft`
- `-microsoft` is worked for me so far, don't change it lol
- > We include Microsoft keys here to avoid boot issues.

## Reboot, Check Secure Boot Status
`sudo sbctl status`

## Unlock with TPM
Run the following command on each partition that you want to unlock with TPM (usually swap and root partitions):

```
# systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/partition
```

and use `./secureboot.nix`.
