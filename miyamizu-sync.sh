#!/usr/bin/env bash

set -euox pipefail

hosts=(kotohira hinanawi)
webhook='https://discord.com/api/webhooks/1130938076504526918/cpqXSzuhK08H3lN5Io6yKMA9q-J_yxswJL3ffOq3vr4CzWG10hIJfM7k1kaFdHkV-qOK'

sync() {
  host="$1"
  pair="miyamizu-sync@$host.msb.q.nyiyui.ca"
  options="-o IdentitiesOnly=yes -i ~/.ssh/id_miya"
  ssh="ssh $options $pair"
  $ssh -- 'doas nix-collect-garbage'
  nixos-rebuild switch --flake ".#$host" --target-host "$pair" --use-remote-sudo
  deploy ".#$host" --ssh-opts "\"$options\""
  $ssh -- ' nix-env --delete-generations 1d'
  $ssh -- 'doas nix-collect-garbage -d'
  message="$(mktemp)"
  echo "$hostを更新したよ。" >> "$message"
  echo "\`df -h\`:" >> "$message"
  echo '```' >> "$message"
  $ssh -- 'df -h' >> "$message"
  echo '```' >> "$message"
  message_json="$(jq -R -s -c < "$message")"
  rm "$message"
  curl "$webhook" \
    -H 'Content-Type: application/json' \
    -d "{\"content\": $message_json}"
}

for host in "${hosts[@]}"; do
  sync "$host" || true
  if [[ $? -ne 0 ]]; then
    curl "$webhook" \
      -H 'Content-Type: application/json' \
      -d "{\"content\": "$hostの更新が失敗！"}"
  fi
done
