#!/usr/bin/env bash
# Atualiza o servidor de RuneScape: Dragonwilds.
# Roda como bruno: sudo -u bruno /opt/titan-agent/acoes/atualizar-runescape.sh
#
# Com UPDATE_ON_START=true, recriar o container já baixa a versão nova do jogo
# via SteamCMD. Antes disso, faz backup dos saves.
set -euo pipefail

PROJETO=/home/bruno/lab/runescape-dw-server/servidor
CONTAINER=runescape-dw-server
ESPERA_MAX_S=540  # o Bash do Claude Code corta em 10 min

cd "$PROJETO"

backup="saves-pre-update-$(date +%Y%m%d-%H%M).tar.gz"
echo "==> Backup dos saves em $PROJETO/$backup"
tar czf "$backup" -C dragonwilds-data/RSDragonwilds/Saved SaveGames

echo "==> Baixando a imagem mais nova"
docker compose pull --quiet

echo "==> Recriando o container (o jogo se atualiza ao subir)"
docker compose up -d --force-recreate

echo "==> Esperando ficar healthy (até $((ESPERA_MAX_S / 60)) min)"
status="?"
for ((t = 0; t < ESPERA_MAX_S; t += 10)); do
    sleep 10
    status=$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "?")
    [[ "$status" == healthy ]] && break
done

echo "==> Últimas linhas do log"
docker logs --tail 20 "$CONTAINER" 2>&1

if [[ "$status" == healthy ]]; then
    echo "OK: servidor atualizado e healthy."
else
    echo "ATENÇÃO: o container ainda está '$status'. Pode estar baixando a atualização; confira os logs daqui a pouco."
    exit 1
fi
