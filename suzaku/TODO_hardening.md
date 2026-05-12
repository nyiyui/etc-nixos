# Hardening TODO

Copy Fail等に（動機ではないが）触発されたので、まずメインPCのsuzakuから、強固で安全なPCにする。

ゴール
- 開発用環境と一般環境を分ける
  - 特にLLM agentを実行するものはVMを使った隔離が望ましい
- OSを強固にする
  - read-only OS image
  - allowlist for kernel modules
  - HTTPS-only / secure DNS

プラン
- XenかKVMでVMを簡単に作れるようにする
- 一般と開発環境を個別のVMにする
