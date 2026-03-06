package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/BurntSushi/toml"
)

var (
	wrapperDirName = ".lsp-sandboxes"
	interpreter    = "/usr/bin/env bash"
	wrapCommand    = "wrap"
)

// Helix configuration structure for extracting language server commands.
type HelixConfig struct {
	LanguageServers map[string]LanguageServer `toml:"language-server"`
	Languages       []Language                `toml:"language"`
}

type LanguageServer struct {
	Command string `toml:"command"`
}

type Language struct {
	Name           string          `toml:"name"`
	LanguageServer *LanguageServer `toml:"language-server"` // Sometimes embedded
}

func main() {
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting current directory: %v\n", err)
		os.Exit(1)
	}

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

	// 1. Global config (~/.config/helix/languages.toml)
	globalDir := os.Getenv("HELIX_CONFIG_HOME")
	if globalDir == "" {
		home := os.Getenv("HOME")
		globalDir = filepath.Join(home, ".config", "helix")
	}
	parseFile(filepath.Join(globalDir, "languages.toml"), lspNames)

	// 2. Project-specific config (.helix/languages.toml)
	parseFile(filepath.Join(cwd, ".helix", "languages.toml"), lspNames)

	// 3. Built-in config fallback
	// Helix often embeds this, but we'll try common Nix store locations based on the hx path.
	if realPath, err := filepath.EvalSymlinks(hxPath); err == nil {
		// If /nix/store/...-helix/bin/hx, runtime is often in /nix/store/...-helix/lib/runtime
		runtimeDir := filepath.Join(filepath.Dir(filepath.Dir(realPath)), "lib", "runtime")
		parseFile(filepath.Join(runtimeDir, "languages.toml"), lspNames)
	}

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

		wrapperPath := filepath.Join(wrapperDir, lsp)
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

func parseFile(path string, lspNames map[string]struct{}) {
	f, err := os.Open(path)
	if err != nil {
		return
	}
	defer f.Close()
	parseHelixConfig(f, lspNames)
}

func parseHelixConfig(r io.Reader, lspNames map[string]struct{}) {
	var cfg HelixConfig
	if _, err := toml.NewDecoder(r).Decode(&cfg); err != nil {
		return
	}

	// Case 1: [language-server.name]
	for _, ls := range cfg.LanguageServers {
		if ls.Command != "" {
			lspNames[ls.Command] = struct{}{}
		}
	}

	// Case 2: [[language]] with embedded language-server
	for _, lang := range cfg.Languages {
		if lang.LanguageServer != nil && lang.LanguageServer.Command != "" {
			lspNames[lang.LanguageServer.Command] = struct{}{}
		}
	}
}
