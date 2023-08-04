#!/usr/bin/env bash

hosts=(cirno kotohira mitsu8)
hosts=(cirno)
webhook='https://discord.com/api/webhooks/1130938076504526918/cpqXSzuhK08H3lN5Io6yKMA9q-J_yxswJL3ffOq3vr4CzWG10hIJfM7k1kaFdHkV-qOK'

sync() {
  set -euo pipefail
  host="$1"
  pair="miyamizu-sync@$host.msb.q.nyiyui.ca"
  options='-o BatchMode=yes'
  options+=' -o IdentitiesOnly=yes -i ~/.ssh/id_miya'
	options+=' -o StrictHostKeyChecking=accept-new'
	options+=' -t'
  if [[ "$host" != 'kotohira' ]]; then
    options+=' -J kotohira.msb.q.nyiyui.ca' # idk how to specify a `-i` for a JumpHost
  fi
  ssh="ssh $options $pair"
  NIX_SSHOPTS="$options" nixos-rebuild switch --flake ".#$host" --target-host "$pair" --use-remote-sudo
  #deploy ".#$host" --ssh-opts "$options"
  $ssh -- ' nix-env --delete-generations 1d'
  $ssh -- 'doas nix-collect-garbage -d'
  $ssh -- 'df -h'
}

for host in "${hosts[@]}"; do
  echo "=== sync $host"
  log="$(mktemp)"
  2>&1 sync "$host" | tee "$log"
  if [[ $? -eq 0 ]]; then
    message="$(mktemp)"
    echo '```' >> "$message"
    cat "$log" >> "$message"
    echo '```' >> "$message"
    message_json="$(jq -R -s -c < "$message")"
    rm "$message"
    curl "$webhook" \
      -H 'Content-Type: application/json' \
      -d "{\"content\": \"$hostを更新したよ。\"}"
    curl "$webhook" \
      -H 'Content-Type: application/json' \
      -d "{\"content\": $message_json}"
  else
    curl "$webhook" \
      -H 'Content-Type: application/json' \
      -d "{\"content\": "$hostの更新が失敗！"}"
  fi
  cat "$log" > /tmp/miyamizu-sync.log
  rm "$log"
done
