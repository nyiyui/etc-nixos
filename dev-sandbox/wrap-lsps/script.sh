#!/usr/bin/env bash

# 1. Define where the wrappers will live
WRAPPER_DIR="$PWD/.lsp-sandboxes"
mkdir -p "$WRAPPER_DIR"

# 2. Extract recognized LSP binary names from Helix
# 'hx --health' formats the LSP command as the last word on the line.
# We filter out table formatting characters and empty lines.
KNOWN_LSPS=$(hx --health | awk '{print $NF}' | grep -vE '(None|✓|✘|^$)' | sort -u)

# 3. Intersect with the devShell PATH and wrap
for lsp in $KNOWN_LSPS; do
    # Check if the LSP exists in our current environment
    if command -v "$lsp" >/dev/null 2>&1; then
        
        # Get the absolute path to the binary in the /nix/store
        LSP_TARGET=$(command -v "$lsp")
        
        # Prevent infinite loops if the wrapper directory is already in PATH
        if [[ "$LSP_TARGET" == "$WRAPPER_DIR/"* ]]; then
            continue
        fi

        # Generate the bwrap shim
        cat <<EOF > "$WRAPPER_DIR/$lsp"
#!/usr/bin/env bash
exec bwrap \\
    --unshare-all \\
    --ro-bind /nix /nix \\
    --bind "$PWD" "$PWD" \\
    --tmpfs /tmp \\
    --chdir "$PWD" \\
    -- \\
    "$LSP_TARGET" "\$@"
EOF
        chmod +x "$WRAPPER_DIR/$lsp"
    fi
done

# 4. Launch Helix with the sandboxed PATH
PATH="$WRAPPER_DIR:$PATH" exec hx "$@"
