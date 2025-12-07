# KiCAD NVIDIA Segfault Fix

## Issue Description

KiCAD was experiencing segmentation faults (SIGSEGV) on the `minamo` system but working correctly on `suzaku`.

```
kiyurica@minamo ~> kicad
fish: Job 1, 'kicad' terminated by signal SIGSEGV (Address boundary error)
```

## Root Cause Analysis

### System Differences

- **minamo**: Desktop with NVIDIA GPU (proprietary drivers)
- **suzaku**: Lenovo ThinkPad laptop with Intel integrated graphics

### Technical Cause

KiCAD uses OpenGL for its 3D viewer and graphics acceleration. On systems with NVIDIA GPUs running Wayland compositors (like niri), applications need specific environment variables to properly interface with the NVIDIA drivers:

- `__GLX_VENDOR_LIBRARY_NAME=nvidia`: Tells GLX to use NVIDIA's OpenGL implementation
- `GBM_BACKEND=nvidia-drm`: Specifies the GBM (Generic Buffer Management) backend for NVIDIA
- `__GL_GSYNC_ALLOWED=1`: Enables G-SYNC support
- `__GL_VRR_ALLOWED=0`: Disables Variable Refresh Rate (can cause issues with some applications)

While these environment variables were set in the niri window manager configuration (in `niri/default.nix`), they were only applied to the window manager's environment. KiCAD, being launched as a separate application, didn't inherit these settings in a way that prevented the segfault.

## Solution

The fix wraps the KiCAD package using a NixOS overlay that explicitly sets the required NVIDIA environment variables for all KiCAD binaries. This is done in two places in `minamo/configuration.nix`:

1. **System-level overlay**: Applied to the nixpkgs in the system configuration
2. **Home-manager overlay**: Applied to the nixpkgs in the home-manager user configuration

Both overlays use `symlinkJoin` and `makeWrapper` to wrap KiCAD's executables with the necessary environment variables without modifying the original package.

### Code Changes

The overlay wraps all executable binaries in the KiCAD package:

```nix
nixpkgs.overlays = [
  (final: prev: {
    kicad = prev.symlinkJoin {
      name = "kicad-nvidia";
      paths = [ prev.kicad ];
      buildInputs = [ prev.makeWrapper ];
      postBuild = ''
        for bin in $out/bin/*; do
          if [ -f "$bin" ] && [ -x "$bin" ]; then
            wrapProgram "$bin" \
              --set __GLX_VENDOR_LIBRARY_NAME nvidia \
              --set GBM_BACKEND nvidia-drm \
              --set __GL_GSYNC_ALLOWED 1 \
              --set __GL_VRR_ALLOWED 0
          fi
        done
      '';
    };
  })
];
```

## Testing Instructions

To test the fix on `minamo`:

1. **Rebuild the system configuration**:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#minamo
   ```

2. **Launch KiCAD**:
   ```bash
   kicad
   ```

3. **Verify it doesn't segfault**: The application should start normally without crashing

4. **Test 3D viewer**: Open a PCB and try using the 3D viewer feature, which heavily relies on OpenGL

5. **Check for warnings**: Look for any OpenGL or graphics-related warnings in the terminal output

## Alternative Approaches Considered

1. **Global environment variables**: Setting these variables system-wide would affect all applications, which is unnecessary and could cause issues with non-NVIDIA-aware applications

2. **Desktop entry modification**: Modifying the `.desktop` file to include environment variables, but this is less maintainable in NixOS

3. **Shell alias/function**: Creating a shell wrapper, but this wouldn't work for GUI launchers

4. **Hardware acceleration in kicad.nix**: Modifying the generic `home-manager/kicad.nix`, but this would affect all systems including `suzaku` which doesn't need it

The chosen overlay approach is the cleanest solution as it:
- Only affects the `minamo` system where NVIDIA is present
- Uses NixOS's native packaging mechanisms
- Is maintainable and clearly documented
- Doesn't affect other systems in the repository

## Related Issues

Similar issues may occur with other OpenGL/graphics-intensive applications on NVIDIA+Wayland systems. The same overlay pattern can be applied to other affected packages.

## References

- [NVIDIA Wayland Wiki](https://wiki.archlinux.org/title/NVIDIA#Wayland)
- [NixOS Hardware Acceleration](https://nixos.wiki/wiki/Accelerated_Video_Playback)
- [KiCAD OpenGL Requirements](https://docs.kicad.org/7.0/en/getting_started_in_kicad/getting_started_in_kicad.html#system-requirements)
