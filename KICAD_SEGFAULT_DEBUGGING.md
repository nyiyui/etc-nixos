# KiCAD Segfault Debugging Guide

## Current Status

KiCAD segfaults on minamo (NVIDIA GPU system) with various attempted fixes:
1. ✗ NVIDIA environment variables (`__GLX_VENDOR_LIBRARY_NAME=nvidia`, etc.)
2. ✗ Software rendering (`LIBGL_ALWAYS_SOFTWARE=1`)

Both `kicad` and `kicad-cli` segfault, suggesting this is not graphics-related but a deeper library or dependency issue.

## Next Steps to Isolate the Issue

### 1. Get Stack Trace

Run KiCAD with GDB to see where the segfault occurs:

```bash
gdb --args kicad
# Then type 'run' and when it crashes, type 'bt' for backtrace
```

Or use:
```bash
coredumpctl list
coredumpctl gdb <last-kicad-pid>
# Type 'bt' for backtrace
```

### 2. Check Library Dependencies

Verify all required libraries are present and correct:

```bash
ldd $(which kicad)
ldd $(which kicad-cli)
```

Look for any "not found" errors or unusual paths.

### 3. Run with Debugging

```bash
# Enable verbose output
kicad --verbose

# Check for missing libraries
LD_DEBUG=libs kicad 2>&1 | less

# Check for symbol issues
LD_DEBUG=symbols kicad 2>&1 | less
```

### 4. Try Alternative KiCAD Version

Since the current version segfaults, try using an older or unstable version:

**Option A: Use unstable nixpkgs**
```nix
nixpkgs.overlays = [
  (final: prev: {
    kicad = nixpkgs-unstable.legacyPackages.${prev.system}.kicad;
  })
];
```

**Option B: Try an older version**
Check if there's a known working version and pin to that.

**Option C: Try the minimal variant**
```nix
home.packages = [ pkgs.kicad-small ];
```

### 5. Compare with Suzaku

Since KiCAD works on suzaku, compare:

```bash
# On suzaku:
ldd $(which kicad) > /tmp/suzaku-kicad-deps.txt
nix-store -q --tree $(which kicad) > /tmp/suzaku-kicad-closure.txt

# On minamo:
ldd $(which kicad) > /tmp/minamo-kicad-deps.txt
nix-store -q --tree $(which kicad) > /tmp/minamo-kicad-closure.txt

# Compare the outputs
diff /tmp/suzaku-kicad-deps.txt /tmp/minamo-kicad-deps.txt
diff /tmp/suzaku-kicad-closure.txt /tmp/minamo-kicad-closure.txt
```

### 6. Check System Libraries

The issue might be with system-wide NVIDIA libraries conflicting:

```bash
# Check what GL libraries are being used
glxinfo | grep "OpenGL"
eglinfo

# Check NVIDIA driver version
nvidia-smi

# Verify mesa is installed
ls -la /run/opengl-driver/lib/
```

### 7. Investigate NixOS-Specific Issues

Search for similar issues:
- Check NixOS discourse/GitHub issues for "kicad nvidia segfault"
- Check KiCAD forums for NixOS + NVIDIA issues
- Look at the KiCAD NixOS package definition for NVIDIA-specific build flags

### 8. Try Running Without Niri

The issue might be Wayland/niri-specific with NVIDIA:

```bash
# Try under X11 instead
# Start X11 session and test there
```

## Likely Root Causes

Based on the symptoms:
1. **Library mismatch**: KiCAD might be linked against libraries that conflict with NVIDIA drivers
2. **Qt/wxWidgets issue**: The GUI framework might have NVIDIA-specific problems
3. **NixOS package build issue**: KiCAD might need special build flags for NVIDIA systems
4. **Driver incompatibility**: Specific NVIDIA driver version might be incompatible with this KiCAD build

## Recommended Investigation Order

1. Get the stack trace (most important)
2. Check library dependencies
3. Try alternative KiCAD versions
4. Compare with suzaku
5. Check for known issues in NixOS/KiCAD communities

The stack trace will be the most informative and will show exactly where the crash occurs.
