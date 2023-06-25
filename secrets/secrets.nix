let
  kumi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJH/eStgs5aAKG+8H4v+HvXBe9dC/syvBoEe8WmTc30/";
  kumi-nyiyui =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1u97NoSW2uhTXWhVaCcIf1hxsELg+YtzQ9FlIlrxec";
  hinanawi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGymaXxH/rgi5nqrasYg6dDeu4NHf516LU2sBSHDQfKC root@hananawi";
  rei =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtn+xypcthqDP/g+6TRaohewCLy22/XeyvvRSkkFBVp root@rei.us-east1-b.c.nyiyui.internal";
in {
  "reimu-ss-key.age".publicKeys = [ kumi ];
  "kumi-inaba-ssh-key.age".publicKeys = [ kumi ];
  "kuromiya-key.pem.age".publicKeys = [ rei ];
  "kuromiya-hinanawi.qrystalct.age".publicKeys = [ hinanawi ];
}
