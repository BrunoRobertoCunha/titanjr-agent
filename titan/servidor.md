# O servidor TITANJR

- Ubuntu 26.04 LTS, IP na rede local 192.168.68.69 (hostname `titanjr`)
- 12 núcleos, 30 GB de RAM, GPU NVIDIA (usada pela Anima)
- Tudo roda em Docker Compose. Cada projeto fica em /home/bruno/lab/<projeto>
  e tem um README.md explicando como opera.
- Dashboard (Homepage): http://192.168.68.69:3000, projeto /home/bruno/lab/homepage

# Servidores de jogo

Todos seguem o mesmo padrão: `servidor/` tem o container do jogo e `homepage/`
tem o painel web de configuração (FastAPI + nginx).

## RuneScape: Dragonwilds
- Projeto: /home/bruno/lab/runescape-dw-server (container `runescape-dw-server`)
- Porta 7777/udp. Painel de configuração: http://192.168.68.69:8100
- Joga com o Bruno: Tavão.
- `UPDATE_ON_START=true`: recriar o container já atualiza o jogo via SteamCMD.
- Para atualizar, use o script:
  `sudo -u bruno /opt/titan-agent/acoes/atualizar-runescape.sh`
  Ele faz backup dos saves, puxa a imagem nova, recria o container e espera
  ficar healthy. Pode levar alguns minutos, então rode o Bash com timeout
  de 600000 ms.
- Saves: servidor/dragonwilds-data/RSDragonwilds/Saved/SaveGames
  (backups em servidor/saves-pre-update-*.tar.gz)

## Palworld (mundo "Dark World")
- Projeto: /home/bruno/lab/palworld-server (container `palworld-darkworld`)
- Crossplay PC + PS5

## Valheim
- Projeto: /home/bruno/lab/valheim-server (container `valheim-server`)
- **Normalmente desligado.** Só ligue se o Bruno pedir.
- Valheim 1.0, crossplay PC + PS5

# A Mika (assistente de gameplay do Bruno)

A Mika é feita de três projetos:

- **Anima** (/home/bruno/lab/anima): os "sentidos". São containers
  independentes com API compatível com OpenAI: `anima-llm` (llama.cpp na GPU),
  `anima-stt` (voz → texto), `anima-tts` (texto → voz) e `anima-vision`. Cada
  um tem o seu compose em services/<sentido>.
- **Yume** (/home/bruno/lab/yume): o frontend pessoal da Mika, com
  `yume-frontend`, `yume-backend`, `yume-proxy`, `yume-db` (Postgres) e
  `yume-pgadmin`. Os composes ficam em services/app e services/db.
  O yume-db guarda dados da Mika: nunca derrube o volume dele.
- **mika-airi** (/home/bruno/lab/mika-airi): o AIRI servido a partir de um
  clone, com a configuração da Mika injetada por fora. Nenhum arquivo do AIRI
  é modificado.

A GPU é compartilhada pelos serviços da Anima. Se a Mika estiver lenta,
confira `nvidia-smi` e os logs do `anima-llm`.
