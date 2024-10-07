# TODO: change to systemd user service, that seems to work™
# hisame.nix configures stuff from my Fujitsu Quaderno A4.
{ config, lib, pkgs, ... }:
let
  cfg = config.hisame.services.sync;
  tmpIPAddrPath = "/tmp/hisame-ip-addr";
  clientId = config.age.secrets."hisame/deviceid.dat".path;
  key = config.age.secrets."hisame/privatekey.dat".path;
in {
  options.hisame.services.sync = with lib;
    with types; {
      enable = mkEnableOption "digital paper sync";
      path = mkOption {
        type = path;
        description = "path to sync digital paper with";
      };
    };
  config = lib.mkIf cfg.enable {
    users.groups.hisame = { };
    users.users.hisame = {
      isSystemUser = true;
      group = "hisame";
      extraGroups = [ "nyiyui" ];
      description = "sync with digital paper";
    };
    age.secrets."hisame/privatekey.dat" = {
      file = ./secrets/hisame/privatekey.dat.age;
      owner = "nyiyui";
      group = "nyiyui";
      mode = "400";
    };
    age.secrets."hisame/deviceid.dat" = {
      file = ./secrets/hisame/deviceid.dat.age;
      owner = "nyiyui";
      group = "nyiyui";
      mode = "400";
    };
    services.avahi.enable = true;

    systemd.services.hisame-sync = {
      description = "sync digital paper";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre =
          "${pkgs.python3.withPackages (p: [ p.pyserial ])}/bin/python -u ${
            pkgs.writeText "dptmount-generate-config.py" ''
              import subprocess
              import json
              import time
              import serial
              import re


              # see https://github.com/janten/dpt-rp1-py/blob/master/docs/linux-ethernet-over-usb.md

              RNDIS = b"\x01\x00\x00\x01\x00\x00\x00\x01\x00\x04"
              CDC_ECM = b"\x01\x00\x00\x01\x00\x00\x00\x01\x01\x04"

              def wait_for_resolve(timeout=30):
                deadline = time.time() + timeout
                while True:
                  if time.time() >= deadline:
                    raise RuntimeError('timeout')
                  completed = subprocess.run(['${pkgs.avahi}/bin/avahi-resolve', '-n', 'Android.local'], capture_output=True)
                  stdout = completed.stdout.decode('ascii')
                  stderr = completed.stderr.decode('ascii')
                  if 'failed' in stdout.lower() or len(stderr) > 0:
                    print('failed, trying again…')
                    time.sleep(1)
                    continue
                  split = stdout.split()
                  if len(split) != 2:
                    raise RuntimeError(f'failed to parse stdout: {stdout} ; stderr: {stderr}')
                  addr = split[1]
                  print(f'found addr {addr}')
                  break
                return addr

              def get_interfaces():
                "Selects a good-looking (i.e. starts with enp) interface, and hope that it's the correct (i.e. USB-to-Ethernet) interface."
                completed = subprocess.run(['/run/current-system/sw/bin/ip', 'a'], capture_output=True)
                stdout = completed.stdout.decode('ascii')
                stderr = completed.stderr.decode('ascii')
                if 'failed' in stdout.lower() or len(stderr) > 0:
                  raise RuntimeError(f'failed to get interfaces: {stderr}')
                m = re.search('enp.*u.:', stdout)
                if not m:
                  raise TypeError(f'interface not found: {stdout}')
                return m.group(0)[:-1]


              print('checking already connected…')
              try:
                addr = wait_for_resolve(timeout=1)
              except RuntimeError as e:
                if str(e) == 'timeout':
                  print('resolve doesn\'t work now; connecting via USB…')
                  print('writing control sequence…')
                  with serial.Serial('/dev/ttyACM0') as port: # assume this is Quaderno
                    port.write(RNDIS)
                  print('waiting for resolve to succeed…')
                  addr = wait_for_resolve()
                else:
                  raise e
              print('connected.')

              #iface = get_interfaces()
              #print(f'interface to use: {iface}')
              print('writing ip address…')
              with open('${tmpIPAddrPath}', 'w') as file:
                #file.write(f'[{addr}%{iface}]')
                file.write(f'{addr}')
              print('done.')
            ''
          }";
        ExecStart = pkgs.writeShellScript "hisame-sync.sh" ''
          ${pkgs.dpt-rp1-py}/bin/dptrp1 --yes --key '${key}' --addr $(cat '${tmpIPAddrPath}') --client-id '${clientId}' sync '${cfg.path}' 'Document'
        '';
        Restart = "always";
        RestartSec = "600";
        #PrivateTmp = true;
        #NoNewPrivileges = true;
        #ProtectSystem = "full";
      };
    };
    systemd.timers.hisame-sync = {
      description = "copy hisame contents to disk";
      wantedBy = [ "multi-user.target" ];
      timerConfig.OnCalendar = "*:0/15";
    };
  };
}
