# Claude Code

## How to generate the files

Write the following to `node-packages.json`:
```json
[
  "@anthropic-ai/claude-code"
]
```

- Run `node2nix -i node-packages.json`
- Rename `default.nix` to `package.nix`
