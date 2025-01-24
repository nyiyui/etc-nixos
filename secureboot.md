# Secure Boot

## Unlock with TPM

Run the following command on each partition that you want to unlock with TPM (usually swap and root partitions):

```
# systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/partition
```

and use `./secureboot.nix`.
