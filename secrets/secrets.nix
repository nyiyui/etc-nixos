let
  kumi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJH/eStgs5aAKG+8H4v+HvXBe9dC/syvBoEe8WmTc30/";
  kumi-nyiyui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1u97NoSW2uhTXWhVaCcIf1hxsELg+YtzQ9FlIlrxec"
in {
  "reimu-ss-key.age".publicKeys = [ kumi ];
  "kumi-inaba-ssh-key.age".publicKeys = [ kumi ];
}
