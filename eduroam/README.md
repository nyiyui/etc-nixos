# GT Eduroam

## Setup

1. Follow [Connecting to Eduroam using GT's New Certificate-based Authentication](https://shibata.nyiyui.ca/log/07-eduroam-cert/) to make sure the device can connect.
2. Create `client-cert-$(hostname).p12.age` from the P12 file.
3. Create `secrets-$(hostname).env.age` with the following content:
```env
EDUROAM_PRIVATE_KEY_PASSWORD='<the passphrase>'
```
