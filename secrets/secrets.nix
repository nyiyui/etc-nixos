let
  hinanawi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGymaXxH/rgi5nqrasYg6dDeu4NHf516LU2sBSHDQfKC root@hinanawi";
  rei =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSteZOknWCI5z6gEXB7zWrkS8/zOOGObGs9yEIe8wXg root@rei.us-east1-b.c.nyiyui.internal";
  naha =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwTgUcH5u+ieH442iImkn+H11B+1n160MriM50+sIm/ root@nixos";
in {
  "kuromiya-key.pem.age".publicKeys = [ rei ];
  "kuromiya-hinanawi.qrystalct.age".publicKeys = [ hinanawi ];
  "kuromiya-naha.qrystalct.age".publicKeys = [ naha ];
}
