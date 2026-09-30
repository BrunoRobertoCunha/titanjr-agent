#!/usr/bin/env bash
# Preparação do sistema. Roda uma vez só (e é seguro rodar de novo).
#   sudo ./scripts/instalar-sistema.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
REPO=$(cd "$(dirname "$0")/.." && pwd)
HOME_TITAN=/var/lib/titan-agent
como_titan() { sudo -u titan -H env PATH="$HOME_TITAN/.local/bin:$HOME_TITAN/.bun/bin:/usr/bin:/bin" "$@"; }

echo "==> Pacotes"
apt-get install -y tmux curl unzip rsync

echo "==> Usuário titan (home em $HOME_TITAN, sem login por senha)"
if ! id titan &>/dev/null; then
    useradd --system --create-home --home-dir "$HOME_TITAN" --shell /bin/bash titan
fi
usermod -aG docker titan
chmod 750 "$HOME_TITAN"

echo "==> sudoers (titan pode agir como bruno)"
install -m 440 "$REPO/deploy/sudoers-titan" /etc/sudoers.d/titan
visudo -cf /etc/sudoers.d/titan

echo "==> Claude Code e Bun para o titan"
[[ -x "$HOME_TITAN/.local/bin/claude" ]] || como_titan bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
[[ -x "$HOME_TITAN/.bun/bin/bun" ]] || como_titan bash -c 'curl -fsSL https://bun.sh/install | bash'
como_titan claude --version
como_titan bun --version

echo "==> Plugin oficial do Telegram"
if ! como_titan claude plugin install telegram@claude-plugins-official --scope user; then
    como_titan claude plugin marketplace add anthropics/claude-plugins-official
    como_titan claude plugin install telegram@claude-plugins-official --scope user
fi

echo "==> Token do bot do Telegram"
ENV_TELEGRAM="$HOME_TITAN/.claude/channels/telegram/.env"
if [[ -s "$ENV_TELEGRAM" ]]; then
    echo "    Já configurado em $ENV_TELEGRAM, não mexi."
else
    read -rsp "    Cole o token do @BotFather (não aparece na tela) e Enter: " token; echo
    token=$(printf '%s' "$token" | tr -d '[:space:]')
    if [[ ! "$token" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        echo "    Isso não parece um token do BotFather (formato 123456:ABC...). Rode de novo."
        exit 1
    fi
    if ! curl -fsS "https://api.telegram.org/bot$token/getMe" >/dev/null; then
        echo "    O Telegram recusou esse token. Confira no @BotFather e rode de novo."
        exit 1
    fi
    install -d -o titan -g titan -m 700 "$(dirname "$ENV_TELEGRAM")"
    install -o titan -g titan -m 600 /dev/null "$ENV_TELEGRAM"
    printf 'TELEGRAM_BOT_TOKEN=%s\n' "$token" > "$ENV_TELEGRAM"
fi

echo
echo "Pronto. Próximo passo: sudo ./scripts/deploy.sh"
