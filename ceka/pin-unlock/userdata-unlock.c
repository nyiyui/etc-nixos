/*
 * Cf. default.nix.
 *
 * Opens userdata (LUKS2 volume with, well, user data) with user input, which
 * is either a PIN for the TPM or a LUKS passphrase (in case TPM-backed unlock
 * is unavailable for some reason, like a lockout by the TPM). Digit-only inputs
 * are treated as PINs and anything else as a passphrase.
 *
 * Since our PIN validation comes from unlocking itself, this is also
 * automatically time-limited by the TPM. libcryptsetup refuses to activate onto
 * a mapper name that already exists, so here a concurrent unlock makes this
 * attempt fail with EEXIST rather than take credit for someone else's.
 *
 * Format this with clang-format.
 */

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <sys/prctl.h>
#include <unistd.h>

#include <libcryptsetup.h>
// https://mbroz.fedorapeople.org/libcryptsetup_API/index.html

#ifndef USERDATA_DEVICE
#error USERDATA_DEVICE is not defined
#endif
#ifndef USERDATA_VOLUME
#error USERDATA_VOLUME is not defined
#endif
#ifndef TOKEN_PATH
#error TOKEN_PATH is not defined
#endif

char user_input[512];
size_t user_input_length;

bool read_user_input() {
  size_t n_read = 0;

  while (n_read < sizeof user_input) {
    ssize_t n =
        read(STDIN_FILENO, &user_input[n_read], sizeof user_input - n_read);
    if (n < 0) {
      if (errno == EINTR)
        continue;
      return false;
    }
    if (n == 0)
      break;
    n_read += n;
  }
  if (n_read == 0)
    return false;
  user_input_length = n_read;
  return true;
}

bool user_input_is_pin() {
  for (size_t i = 0; i < user_input_length; i++) {
    char c = user_input[i];
    if (c < '0' || c > '9') {
      return false;
    }
  }
  return true;
}

int main(void) {
  {
    int r = prctl(PR_SET_DUMPABLE, 0);
    if (r < 0)
      return 1;
  }
  if (!read_user_input()) {
    return 2;
  }
  struct crypt_device *cd = NULL;
  {
    int r = crypt_init(&cd, USERDATA_DEVICE);
    if (r < 0)
      return 3;
  }
  assert(cd != NULL);
  {
    int r = crypt_load(cd, CRYPT_LUKS2, NULL);
    if (r < 0)
      return 4;
  }

  if (user_input_is_pin()) {
    // PIN
    {
      int r = crypt_token_set_external_path(TOKEN_PATH);
      if (r < 0)
        return 5;
    }
    {
      int r = crypt_activate_by_token_pin(cd, USERDATA_VOLUME, "systemd-tpm2",
                                          CRYPT_ANY_TOKEN, user_input,
                                          user_input_length, NULL,
                                          CRYPT_ACTIVATE_ALLOW_DISCARDS);
      if (r < 0)
        return 6;
    }
  } else {
    // passphrase
    int r = crypt_activate_by_passphrase(cd, USERDATA_VOLUME, CRYPT_ANY_SLOT,
                                         user_input, user_input_length,
                                         CRYPT_ACTIVATE_ALLOW_DISCARDS);
    if (r < 0)
      return 7;
  }
  return 0;
}
