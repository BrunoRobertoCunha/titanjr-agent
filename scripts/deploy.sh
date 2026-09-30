#!/usr/bin/env bash
# Publica a configuração do Titan em /opt/titan-agent e reinicia o serviço.
#   sudo ./scripts/deploy.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }
REPO=$(cd "$(dirname "$0")/.." && pwd)
DESTINO=/opt/titan-agent

echo "==> Copiando para $DESTINO"
install -d -m 755 "$DESTINO"
# Só o que o Titan usa. O CLAUDE.md da raiz é para desenvolver o repo, não entra.
rsync -a --delete "$REPO/titan" "$REPO/acoes" "$REPO/deploy" "$DESTINO"/
# Tudo de root: o Titan lê e executa, mas não consegue mudar a própria
# personalidade, as permissões nem os scripts.
chown -R root:root "$DESTINO"
chmod -R go-w "$DESTINO"

echo "==> Serviço"
install -m 644 "$DESTINO/deploy/titan-agent.service" /etc/systemd/system/titan-agent.service
systemctl daemon-reload
systemctl enable --quiet titan-agent
systemctl restart titan-agent
sleep 2
systemctl --no-pager --lines=5 status titan-agent || true
echo
echo "Para conversar com o Titan no terminal:  sudo -u titan tmux -L titan attach"
echo "(para sair sem desligar: Ctrl+B e depois D)"
