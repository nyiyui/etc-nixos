package main

import (
	"crypto/sha256"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

var (
	wrapperDirName = ".lsp-sandboxes"
	interpreter    = "/usr/bin/env bash"
	wrapCommand    = "wrap"
)

func main() {
	hxPath, err := exec.LookPath("hx")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Helix (hx) not found in PATH: %v\n", err)
		os.Exit(1)
	}

	wrapperDir, err := os.MkdirTemp("", "wrap-lsps-")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating temporary directory: %v\n", err)
		os.Exit(1)
	}
	// Note: Since we use syscall.Exec, we cannot easily defer os.RemoveAll(wrapperDir) 
	// as the process is replaced. The temp dir will remain until system cleanup.

	lspNames := make(map[string]struct{})

	// Rely solely on hx --health as it's the most reliable way to find LSPs 
	// for the current helix binary, especially when runtime files are 
	// hidden in the Nix store.
	parseHealth(lspNames)

	// Wrap found LSPs
	for lsp := range lspNames {
		lspPath, err := exec.LookPath(lsp)
		if err != nil {
			continue
		}

		absLSPPath, err := filepath.Abs(lspPath)
		if err != nil {
			continue
		}

		if strings.HasPrefix(absLSPPath, wrapperDir) {
			continue
		}

		wrapperPath := filepath.Join(wrapperDir, filepath.Base(lsp))
		content := fmt.Sprintf(`#!%s
exec %s "%s" "$@"
`, interpreter, wrapCommand, absLSPPath)

		if err := os.WriteFile(wrapperPath, []byte(content), 0755); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing wrapper for %s: %v\n", lsp, err)
			continue
		}
	}

	// Launch Helix with the sandboxed PATH
	newPath := wrapperDir + string(os.PathListSeparator) + os.Getenv("PATH")
	os.Setenv("PATH", newPath)

	args := append([]string{"hx"}, os.Args[1:]...)
	if err := syscall.Exec(hxPath, args, os.Environ()); err != nil {
		fmt.Fprintf(os.Stderr, "Error executing hx: %v\n", err)
		os.Exit(1)
	}
}

func parseHealth(lspNames map[string]struct{}) {
	hxReal, err := exec.LookPath("hx")
	if err != nil {
		return
	}
	realPath, err := filepath.EvalSymlinks(hxReal)
	if err != nil {
		realPath = hxReal
	}

	// Use a deterministic cache path based on the store path
	h := sha256.New()
	h.Write([]byte(realPath))
	cacheHash := fmt.Sprintf("%x", h.Sum(nil))
	cachePath := filepath.Join(os.TempDir(), "wrap-lsps-health-languages-"+cacheHash+".txt")

	var output []byte
	if _, err := os.Stat(cachePath); err == nil {
		output, _ = os.ReadFile(cachePath)
	}

	if len(output) == 0 {
		cmd := exec.Command("hx", "--health", "languages")
		cmd.Env = append(os.Environ(), "COLUMNS=1000")
		output, err = cmd.Output()
		if err != nil {
			return
		}
		os.WriteFile(cachePath, output, 0644)
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}
		
		// Skip header
		if strings.ToLower(fields[0]) == "language" {
			continue
		}

		// Heuristic: The LSP is in the second column.
		// If it starts with a status icon (✓ or ✘), it's the LSP.
		// Example: "ada ✘ ada-language-server None" -> ["ada", "✘", "ada-language-server", "None"]
		// OR: "ada ada-language-server None" -> ["ada", "ada-language-server", "None"]
		
		var lsp string
		if len(fields) >= 2 {
			if fields[1] == "✓" || fields[1] == "✘" {
				if len(fields) >= 3 {
					lsp = fields[2]
				}
			} else {
				lsp = fields[1]
			}
		}

		if lsp == "" || lsp == "None" || strings.ContainsAny(lsp, "()[]…") {
			continue
		}

		lspNames[lsp] = struct{}{}
	}
}
