package main

import (
	"strings"
	"testing"
)

func TestParseHelixConfig(t *testing.T) {
	input := `
[language-server.rust-analyzer]
command = "rust-analyzer"

[[language]]
name = "go"
[language.language-server]
command = "gopls"

[[language]]
name = "nix"
language-server = { command = "nil" }
`
	lspNames := make(map[string]struct{})
	parseHelixConfig(strings.NewReader(input), lspNames)

	expected := []string{"rust-analyzer", "gopls", "nil"}
	for _, name := range expected {
		if _, ok := lspNames[name]; !ok {
			t.Errorf("expected LSP %s not found", name)
		}
	}

	if len(lspNames) != len(expected) {
		t.Errorf("expected %d LSPs, got %d", len(expected), len(lspNames))
	}
}
