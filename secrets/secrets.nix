let
  hinanawi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGymaXxH/rgi5nqrasYg6dDeu4NHf516LU2sBSHDQfKC root@hananawi";
  rei =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtn+xypcthqDP/g+6TRaohewCLy22/XeyvvRSkkFBVp root@rei.us-east1-b.c.nyiyui.internal";
in {
  "kuromiya-key.pem.age".publicKeys = [ rei ];
  "kuromiya-hinanawi.qrystalct.age".publicKeys = [ hinanawi ];
}
