{ config, pkgs, specialArgs, ... }: let
  mountpoint = "${config.home.homeDirectory}/hisame";
  syncpoint = "${config.home.homeDirectory}/hisame-sync";
  tmpConfigPath = "/tmp/hisame-config.yml";
in {
  systemd.user.services.hisame-mount = {
    Unit.Description = "mount digital paper as a filesystem";
    Install.WantedBy = [ "multi-user.target" ];
    Unit.AssertPathExists = mountpoint;
    Service = {
      ExecStartPre = "${pkgs.python3.withPackages (p: [ p.pyserial ])}/bin/python ${pkgs.writeText "dptmount-generate-config.py" ''
import subprocess
import json
import serial


# see https://github.com/janten/dpt-rp1-py/blob/master/docs/linux-ethernet-over-usb.md

RNDIS = b"\x01\x00\x00\x01\x00\x00\x00\x01\x00\x04"
CDC_ECM = b"\x01\x00\x00\x01\x00\x00\x00\x01\x01\x04"

print('writing control sequence…')
with serial.Serial('/dev/ttyACM0') as port: # assume this is Quaderno
  port.write(RNDIS)

print('waiting for resolve to succeed…')
while True:
  completed = subprocess.run(['${pkgs.avahi}/bin/avahi-resolve', '-n', 'Android.local'], capture_output=True)
  stdout = completed.stdout.decode('ascii')
  if 'failed' in stdout.lower():
    print('failed, trying again…')
    time.sleep(1)
    continue
  split = stdout.split()
  if len(split) != 2:
    raise RuntimeError(f'failed to parse {completed.stdout}')
  addr = split[1]
  print(f'found addr {addr}')
  break

config = dict(
  dptrp1={
    'addr': f'[{addr}%enp0s20f0u1]',
    'client-id': '${specialArgs.dptmountData.clientId}',
    'key': '${specialArgs.dptmountData.key}',
  },
)

with open('${tmpConfigPath}', 'w') as file:
  json.dump(config, file)
''}";
      ExecStart = "${pkgs.dpt-rp1-py}/bin/dptmount --config ${tmpConfigPath} --verbose ${mountpoint}";
      Restart = "always";
      RestartSec = "600";
      PrivateTmp = true;
      #NoNewPrivileges = true;
      #ProtectSystem = "full";
    };
  };
  systemd.user.timers.hisame-copy = {
    Unit.Description = "copy hisame contents to disk";
    Unit.After = [ "hisame-mount.service" ];
    Unit.Requires = [ "hisame-mount.service" ];
    Install.WantedBy = [ "multi-user.target" ];
    Timer.OnCalendar = "*:0/15";
  };
  systemd.user.services.hisame-copy = {
    Unit.Description = "copy hisame contents to disk";
    Unit.After = [ "hisame-mount.service" ];
    Unit.Requires = [ "hisame-mount.service" ];
    Install.WantedBy = [ "multi-user.target" ];
    Service = {
      ExecStart = ''rsync -avu --delete "${mountpoint}" "${syncpoint}"'';
    };
  };
}
