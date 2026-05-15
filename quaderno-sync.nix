{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.kiyurica.quaderno-sync;

  python = pkgs.python3.withPackages (ps: [ ps.pyserial ]);

  quaderno-sync-script = pkgs.writeShellScriptBin "quaderno-sync" ''
    set -euo pipefail

    SERIAL_DEV="''${SERIAL_DEV:-${lib.escapeShellArg cfg.serialDevice}}"
    MDNS_NAME="''${MDNS_NAME:-${lib.escapeShellArg cfg.mdnsName}}"
    REMOTE_ADDR="''${REMOTE_ADDR:-${lib.escapeShellArg cfg.remoteAddr}}"

    USB_SYS_PATH="''${USB_SYS_PATH:-}"

    # Quaderno Gen 2: 04c5:1656 initially (serial), then 04c5:1657 after RNDIS is enabled.
    QUADERNO_VID="''${QUADERNO_VID:-04c5}"
    QUADERNO_INITIAL_PID="''${QUADERNO_INITIAL_PID:-1656}"
    QUADERNO_RNDIS_PID="''${QUADERNO_RNDIS_PID:-1657}"

    usb_path=""
    if [ -n "$USB_SYS_PATH" ]; then
      usb_path="$(readlink -f "$USB_SYS_PATH")"
    fi

    NOTIF_ID=""
    notify_update() {
      summary="$1"
      body="$2"
      if [ -z "$NOTIF_ID" ]; then
        NOTIF_ID="$(notify-desktop -a quaderno-sync "$summary" "$body" 2>/dev/null || true)"
      else
        NOTIF_ID="$(notify-desktop -r "$NOTIF_ID" -a quaderno-sync "$summary" "$body" 2>/dev/null || true)"
      fi
    }

    # Forward script args to dptrp1.
    if [ "$#" -eq 0 ]; then
      set -- sync
    fi

    has_addr=0
    has_yes=0
    for a in "$@"; do
      case "$a" in
        --addr|--addr=*) has_addr=1 ;;
        --yes|-y) has_yes=1 ;;
      esac
    done

    if [ ! -t 0 ] && [ "$has_yes" -eq 0 ]; then
      args=("$@")
      new_args=()
      inserted=0
      for a in "''${args[@]}"; do
        if [ "$a" = "--" ] && [ "$inserted" -eq 0 ]; then
          new_args+=(--yes)
          inserted=1
        fi
        new_args+=("$a")
      done
      if [ "$inserted" -eq 0 ]; then
        new_args+=(--yes)
      fi
      set -- "''${new_args[@]}"
    fi

    if [ "$has_addr" -eq 0 ]; then
      echo "quaderno-sync: trying network addr first: $REMOTE_ADDR" >&2
      notify_update "Trying network sync" "$REMOTE_ADDR" || true

      if dptrp1 --addr "$REMOTE_ADDR" "$@"; then
        notify-desktop -r "$NOTIF_ID" -a quaderno-sync -t 1000 "quaderno-sync" "Finished successfully (network)" >/dev/null 2>&1 || true
        exit 0
      else
        rc=$?
        echo "quaderno-sync: network attempt failed (rc=$rc); falling back to USB method" >&2
        notify_update "Network sync failed" "Falling back to USB" || true
      fi
    else
      echo "quaderno-sync: running with user-provided --addr" >&2
      notify_update "Running dptrp1" "$*" || true
      dptrp1 "$@"
      rc=$?
      if [ "$rc" -eq 0 ]; then
        notify-desktop -r "$NOTIF_ID" -a quaderno-sync -t 1000 "quaderno-sync" "Finished successfully" >/dev/null 2>&1 || true
      else
        notify_update "dptrp1 failed" "Exit code $rc" || true
      fi
      exit $rc
    fi

    if [ -z "$usb_path" ]; then
      for dev in /sys/bus/usb/devices/*; do
        [ -f "$dev/idVendor" ] || continue
        [ -f "$dev/idProduct" ] || continue

        [ "$(cat "$dev/idVendor")" = "$QUADERNO_VID" ] || continue

        pid="$(cat "$dev/idProduct")"
        if [ "$pid" = "$QUADERNO_INITIAL_PID" ] || [ "$pid" = "$QUADERNO_RNDIS_PID" ]; then
          usb_path="$dev"
          break
        fi
      done
    fi

    if [ -z "$usb_path" ] || [ ! -e "$usb_path/idVendor" ]; then
      echo "quaderno-sync: failed to locate Quaderno USB device (vid=$QUADERNO_VID pids=$QUADERNO_INITIAL_PID/$QUADERNO_RNDIS_PID)" >&2
      notify_update "Failed to locate Quaderno USB device" "" || true
      exit 1
    fi

    echo "quaderno-sync: using usb device: $usb_path ($(cat \"$usb_path/idVendor\"):$(cat \"$usb_path/idProduct\"))" >&2
    notify_update "Using USB device" "$usb_path" || true

    shopt -s nullglob

    iface=""
    ifindex=""
    for p in "$usb_path":*/net/*; do
      if [ -d "$p" ]; then
        iface="$(basename "$p")"
        ifindex="$(cat "$p/ifindex")"
        break
      fi
    done

    if [ -n "$iface" ]; then
      echo "quaderno-sync: found existing net interface: $iface (ifindex=$ifindex)" >&2
      notify_update "Found existing net interface" "$iface" || true
    else
      echo "quaderno-sync: no net interface yet; will try enabling RNDIS" >&2
      notify_update "No net interface yet" "Enabling RNDIS" || true
    fi

    if [ -z "$iface" ]; then
      # RNDIS isn't up yet; try to enable it over the Quaderno's serial interface (if present).
      if [ ! -e "$SERIAL_DEV" ]; then
        SERIAL_DEV=""
        for p in "$usb_path":*/tty/ttyACM*; do
          if [ -e "$p" ]; then
            SERIAL_DEV="/dev/$(basename "$p")"
            break
          fi
        done
      fi

      if [ -z "$SERIAL_DEV" ] || [ ! -e "$SERIAL_DEV" ]; then
        echo "quaderno-sync: no net interface and no ttyACM serial interface to enable RNDIS" >&2
        notify_update "No net interface and no serial interface" "" || true
        exit 1
      fi

      echo "quaderno-sync: enabling RNDIS via serial: $SERIAL_DEV" >&2
      notify_update "Enabling RNDIS via serial" "$SERIAL_DEV" || true

      export SERIAL_DEV
      python3 -c 'import os, serial; port = serial.Serial(os.environ["SERIAL_DEV"]); port.write(b"\x01\x00\x00\x01\x00\x00\x00\x01\x00\x04"); port.close()'

      for _ in $(seq 1 ${toString cfg.interfaceWaitSeconds}); do
        for p in "$usb_path":*/net/*; do
          if [ -d "$p" ]; then
            iface="$(basename "$p")"
            ifindex="$(cat "$p/ifindex")"
            break
          fi
        done
        if [ -n "$iface" ]; then
          break
        fi
        sleep 1
      done
    fi

    if [ -z "$iface" ] || [ -z "$ifindex" ]; then
      echo "quaderno-sync: timed out waiting for Quaderno RNDIS interface" >&2
      notify_update "Timed out waiting for RNDIS interface" "" || true
      exit 1
    fi

    # Use the numeric ifindex as the IPv6 zone ID to avoid races with interface renaming (usb0 -> enp...).
    echo "quaderno-sync: using net interface: $iface (ifindex=$ifindex)" >&2
    notify_update "Using net interface" "$iface" || true

    echo "quaderno-sync: resolving mDNS: $MDNS_NAME" >&2
    ip6="$(avahi-resolve -n "$MDNS_NAME" | awk '{print $2}' | head -n1 || true)"
    if [ -z "$ip6" ]; then
      echo "quaderno-sync: failed to resolve $MDNS_NAME via avahi" >&2
      notify_update "Failed to resolve mDNS" "$MDNS_NAME" || true
      exit 1
    fi

    addr="[$ip6%$ifindex]"

    echo "quaderno-sync: running: dptrp1 --addr $addr $*" >&2
    notify_update "Running dptrp1" "--addr $addr $*" || true
    dptrp1 --addr "$addr" "$@"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      # Replace previous notification with a short-lived one so it closes
      notify-desktop -r "$NOTIF_ID" -a quaderno-sync -t 1000 "quaderno-sync" "Finished successfully" >/dev/null 2>&1 || true
    else
      notify_update "dptrp1 failed" "Exit code $rc" || true
    fi
    exit $rc
  '';

  quaderno-sync-env = pkgs.symlinkJoin {
    name = "quaderno-sync-env";
    paths = [
      quaderno-sync-script
      python
    ]
    ++ (with pkgs; [
      iproute2
      gawk
      coreutils
      avahi
      notify-desktop
      dpt-rp1-py
    ]);

    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/quaderno-sync --prefix PATH : $out/bin
    '';
  };

in
{
  options.kiyurica.quaderno-sync = {
    enable = lib.mkEnableOption "Fujitsu Quaderno Gen 2 sync (RNDIS + dptrp1)";

    autoSync = {
      enable = lib.mkEnableOption "auto-run quaderno-sync on USB connect";
    };

    serialDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/ttyACM0";
      description = "Serial device to send the RNDIS enable command to.";
    };

    mdnsName = lib.mkOption {
      type = lib.types.str;
      default = "Android.local";
      description = "mDNS name to resolve for the Quaderno over RNDIS.";
    };

    remoteAddr = lib.mkOption {
      type = lib.types.str;
      default = "quaderno.2kendon.ca";
      description = "Address to try first before falling back to USB/RNDIS.";
    };

    interfaceWaitSeconds = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Seconds to wait for the RNDIS network interface to appear.";
    };

    syncLocalPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.services.syncthing.settings.folders.inaba.path}/quaderno";
      description = "Local path for `dptrp1 sync <local_path>`.";
    };

    dptrp1Args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sync"
        cfg.syncLocalPath
      ];
      description = "Arguments passed to dptrp1. If --addr is omitted, an appropriate address setting is injected.";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: somehow notify user of sync status

    environment.systemPackages = [ quaderno-sync-env ];

    # User service (runs as whichever user is currently logged in)
    systemd.user.services.quaderno-sync = lib.mkIf cfg.autoSync.enable {
      description = "Sync Fujitsu Quaderno";
      wantedBy = [ ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "${quaderno-sync-env}/bin/quaderno-sync ${lib.escapeShellArgs cfg.dptrp1Args}";
      };
    };

    services.udev.extraRules = lib.mkAfter (
      lib.optionalString cfg.autoSync.enable ''
        # Quaderno Gen 2: 04c5:1656 initially (serial), then 04c5:1657 after RNDIS is enabled.
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="04c5", ATTR{idProduct}=="1656", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="quaderno-sync.service"
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="04c5", ATTR{idProduct}=="1657", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="quaderno-sync.service"
      ''
    );

    services.avahi.enable = lib.mkDefault true;
  };
}
