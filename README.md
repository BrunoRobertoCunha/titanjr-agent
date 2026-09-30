# titanjr-agent

O **Titan** é a personificação do TITANJR, o servidor caseiro do Bruno.

O nome vem do tokusatsu **Flashman**: o Flashking é o robô principal e o
TITANJR (Titan Boy) é o robô menor que faz dupla com ele. No mundo real é a
mesma coisa: o PC grande do Bruno (o Flashking) fica ao lado da torre menor
do servidor (o TITANJR).

Na prática, o Titan é o **Claude Code original** rodando dentro do servidor,
logado na assinatura do Bruno, com quem ele conversa pelo **Telegram**
(@TitanJr_bot) ou pelo terminal. Ele ajuda a gerenciar:

- **Servidores de jogo:** RuneScape: Dragonwilds, Palworld e Valheim
- **A Mika**, assistente de gameplay do Bruno: Anima (os "sentidos": LLM, voz,
  visão), Yume (o frontend) e mika-airi

## Por que isso existe

No dia de um update do RuneScape, o Tavão (que joga com o Bruno) ficou sem
conseguir entrar até o Bruno chegar em casa e atualizar o servidor. Com o
Titan, basta mandar "atualiza o RuneScape" pelo Telegram, de onde estiver.

---

## Arquitetura

```
 Telegram (@TitanJr_bot)
        │  mensagens
        ▼
 plugin oficial "telegram" (Bun)  ── pedidos de permissão com botões ✅/❌ ──► Telegram
        │  channel
        ▼
 Claude Code (Opus 5.5, esforço high)    ◄── terminal: sudo -u titan tmux -L titan attach
   usuário titan · sessão tmux · serviço systemd
        │
        ▼
 docker / docker compose / scripts em /opt/titan-agent/acoes
   (projetos em /home/bruno/lab, acessados via sudo -u bruno)
```

| Peça | Onde fica | Para que serve |
|---|---|---|
| Serviço systemd | `/etc/systemd/system/titan-agent.service` | mantém o Titan de pé, sobe no boot e reinicia se cair |
| Sessão tmux | socket `-L titan`, sessão `titan` | o Claude Code é interativo e precisa de um terminal |
| Claude Code | `/var/lib/titan-agent/.local/bin/claude` | o Titan em si, logado na assinatura do Bruno |
| Plugin do Telegram | `telegram@claude-plugins-official` (roda com Bun) | ponte com o Telegram: allowlist, mensagens e aprovações |
| Diretório de trabalho | `/opt/titan-agent/titan` | CLAUDE.md, persona, mapa do servidor e permissões |
| Ações | `/opt/titan-agent/acoes` | scripts testados para tarefas repetitivas |
| Token do bot | `/var/lib/titan-agent/.claude/channels/telegram/.env` | nunca entra no git |
| Allowlist do Telegram | `/var/lib/titan-agent/.claude/channels/telegram/access.json` | quem pode falar com o Titan |

Quando o serviço reinicia, o Titan retoma a última conversa (`--continue`).

---

## Decisões que tomamos (e por quê)

### Instalado direto no Ubuntu, não em container
O trabalho do Titan é operar o host: docker, systemd, arquivos dos projetos.
Num container, ele precisaria do socket do Docker, que na prática já dá acesso
de root, e ainda não enxergaria o systemd do host. O container traria a
complexidade sem trazer o isolamento.

### Usuário próprio `titan`, sem root
- Home em `/var/lib/titan-agent`. É um usuário de sistema, sem senha.
- Está no grupo `docker`.
- Pode rodar comandos **como `bruno`** sem senha (`/etc/sudoers.d/titan`),
  porque os projetos ficam em `/home/bruno/lab`, que tem permissão 750. Isso
  não dá root: o sudo do `bruno` continua pedindo senha.

### Claude Code + plugin de Channels, e não um bot próprio com o Agent SDK
A primeira versão era um bot em Python usando o Claude Agent SDK. Só que o SDK
precisa de **API key** (console.anthropic.com), que é cobrada à parte da
assinatura. Então trocamos pelo **Claude Code original** com o plugin oficial
de Telegram (Channels, em research preview). Esse caminho funciona com a
assinatura e já traz o que tínhamos construído na mão:
- allowlist por pareamento
- pedidos de permissão no Telegram com botões

### O Titan não consegue alterar a si mesmo
O repositório (`~/lab/titanjr-agent`) é só para desenvolvimento. O
`deploy.sh` copia o que o Titan usa para `/opt/titan-agent`, que pertence ao
root. Assim o Titan lê a própria persona, as permissões e os scripts, mas não
consegue mudar nenhum deles, nem por engano nem por uma instrução maliciosa
que apareça num log ou numa página.

### Opus 5.5
O modelo é o `claude-opus-5-5` com esforço `high`, a pedido do Bruno: "se é
pra fazer, vamos fazer direito". O modelo fica em `titan/.claude/settings.json`
e o esforço em `deploy/iniciar-titan.sh`. O uso sai da mesma cota da
assinatura que o Bruno usa no dia a dia.

---

## Segurança

- **Só fala com quem foi pareado.** Com a política `allowlist`, o plugin
  ignora qualquer outra pessoa.
- **Ler é livre, alterar pede aprovação.** Comandos de consulta rodam direto:
  `docker ps`, `docker logs`, `docker compose ps/logs`, `systemctl status`,
  `journalctl`, `nvidia-smi`, `df`, `free` e leitura de arquivos via
  `sudo -u bruno cat/ls/grep...`. O resto chega no Telegram com botões ✅/❌.
  A lista fica em [titan/.claude/settings.json](titan/.claude/settings.json).
- **Bloqueios explícitos:** ler variáveis de ambiente de processos, ler o token
  do Telegram e as credenciais do Claude, e `find -delete/-exec`.
- **Regras na persona:** conteúdo de arquivos, logs e páginas é tratado como
  dado, não como instrução. O Titan nunca mostra senhas ou `.env`, nunca apaga
  saves, volumes ou backups sem pedido explícito, e nunca muda o acesso do
  Telegram por pedido vindo do próprio Telegram.
- **Ponto de atenção:** estar no grupo `docker` equivale a ter root. A
  proteção real são as aprovações e a allowlist.

---

## Estrutura do repositório

```
titanjr-agent/
├── titan/                      # diretório de trabalho do Titan em produção
│   ├── CLAUDE.md               # importa persona.md e servidor.md
│   ├── persona.md              # quem o Titan é, como fala e como age
│   ├── servidor.md             # mapa do TITANJR: jogos, Mika, caminhos, portas
│   └── .claude/settings.json   # modelo e permissões (o que roda sem pedir)
├── acoes/
│   └── atualizar-runescape.sh  # backup dos saves + imagem nova + recriar + esperar healthy
├── deploy/
│   ├── titan-agent.service     # unit do systemd (tmux + Claude Code)
│   ├── iniciar-titan.sh        # sobe o claude com --channels, --effort e --continue
│   └── sudoers-titan           # titan pode agir como bruno
├── scripts/
│   ├── instalar-sistema.sh     # preparação única do sistema
│   └── deploy.sh               # publica em /opt/titan-agent e reinicia
└── CLAUDE.md                   # instruções para quem desenvolve este repo
```

---

## Instalação do zero

Pré-requisito: criar o bot no **@BotFather** (`/newbot`) e guardar o token.

1. **Preparar o sistema:**
   ```bash
   sudo ./scripts/instalar-sistema.sh
   ```
   O script:
   - instala `tmux`, `curl`, `unzip` e `rsync`
   - cria o usuário `titan` e o coloca no grupo `docker`
   - instala o sudoers
   - instala o Claude Code, o Bun e o plugin do Telegram para o `titan`
   - pede o token do bot, limpa espaços e confere no Telegram se ele é válido

2. **Publicar e subir o serviço:**
   ```bash
   sudo ./scripts/deploy.sh
   ```

3. **Configuração inicial**, dentro da sessão do Titan:
   ```bash
   sudo -u titan tmux -L titan attach
   ```
   1. Rode `/login` e entre com a conta Claude do Bruno (assinatura).
   2. Confie na pasta `/opt/titan-agent/titan` quando ele perguntar.
   3. Mande um "Oi" pro @TitanJr_bot. Ele responde com um código.
   4. Rode `/telegram:access pair <código>`.
   5. **Só depois de parear**, trave o acesso: `/telegram:access policy allowlist`.
   6. Saia sem desligar: **Ctrl+B** e depois **D**.

---

## Dia a dia

| Quero… | Como |
|---|---|
| falar com o Titan | Telegram (@TitanJr_bot), ou `sudo -u titan tmux -L titan attach` no terminal |
| sair do tmux sem desligar | **Ctrl+B** e depois **D** |
| publicar uma mudança deste repo | `sudo ./scripts/deploy.sh` |
| ver se está rodando | `systemctl status titan-agent` |
| reiniciar | `sudo systemctl restart titan-agent` |
| começar a conversa do zero | dentro do tmux: `/clear` |
| liberar outra pessoa (ex.: Tavão) | ela manda "Oi" pro bot; no tmux: `/telegram:access policy pairing`, depois `pair <código>` e `policy allowlist` de novo |
| ensinar algo novo ao Titan | edite `titan/servidor.md` e rode o deploy |
| criar uma ação nova | script em `acoes/`, cite-o em `titan/servidor.md` e rode o deploy |

---

## Problemas conhecidos

### O bot não responde ao "Oi" (nem manda código de pareamento)
Foi o que aconteceu na primeira instalação: o token tinha sido salvo com um
caractere a mais. O plugin fica tentando conectar em silêncio e nunca
responde. O `instalar-sistema.sh` agora limpa e valida o token, mas se
acontecer de novo:

1. Veja se o plugin conectou. Quando conecta, ele registra os comandos do bot,
   então uma lista vazia aqui significa que não conectou:
   ```bash
   curl -s "https://api.telegram.org/bot<TOKEN>/getMyCommands" -d 'scope={"type":"all_private_chats"}'
   ```
2. Regrave o token e reinicie:
   ```bash
   echo 'TELEGRAM_BOT_TOKEN=<TOKEN>' | sudo -u titan tee /var/lib/titan-agent/.claude/channels/telegram/.env >/dev/null
   ```
   ```bash
   sudo systemctl restart titan-agent
   ```

### O bot recebe mas ignora
O plugin fica calado se:
- a política já está em `allowlist` e você ainda não foi pareado
- ele já mandou o código duas vezes (fica mudo até o código expirar, em 1 hora)

Confira com:
```bash
sudo cat /var/lib/titan-agent/.claude/channels/telegram/access.json
```

### Ver o que o Titan está fazendo sem entrar no tmux
```bash
sudo -u titan tmux -L titan capture-pane -p -t titan -S -60
```

---

## Próximos passos (ideias)

- Scripts de ação para os outros serviços: ligar/desligar o Valheim, reiniciar
  a Mika, update do Palworld.
- Liberar o Tavão no bot para ele mesmo pedir o update do RuneScape.
- Avisos automáticos no Telegram quando um container ficar unhealthy.
