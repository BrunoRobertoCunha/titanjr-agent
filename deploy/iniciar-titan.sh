#!/usr/bin/env bash
# Sobe o Claude Code do Titan com o canal do Telegram.
# Chamado pelo systemd dentro de uma sessão tmux (ver titan-agent.service).
set -uo pipefail

DIRETORIO=/opt/titan-agent/titan
SESSOES="$HOME/.claude/projects/$(echo "$DIRETORIO" | tr '/' '-')"
cd "$DIRETORIO"

args=(--channels plugin:telegram@claude-plugins-official --effort high)
# Retoma a última conversa, se existir (assim o Titan lembra do que falamos).
if compgen -G "$SESSOES/*.jsonl" >/dev/null; then
    args+=(--continue)
fi

claude "${args[@]}"
status=$?
echo "Claude Code saiu com status $status. O systemd vai reiniciar em alguns segundos."
sleep 5
exit $status
