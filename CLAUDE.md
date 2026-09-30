# titanjr-agent

Configuração do "Titan": o Claude Code rodando no servidor TITANJR como usuário
`titan`, numa sessão tmux mantida pelo systemd, falando pelo Telegram com o
plugin oficial de Channels e logado na assinatura do Bruno (sem API key).
Leia o README.md para a arquitetura.

- Tudo em português, no mesmo estilo dos outros projetos em ~/lab.
- Este diretório é só desenvolvimento. O Titan roda de /opt/titan-agent
  (root), publicado por `sudo ./scripts/deploy.sh`.
- `titan/` é o diretório de trabalho do Titan em produção: o CLAUDE.md, o
  persona.md, o servidor.md e o .claude/settings.json dali são dele, não
  deste repo.
- Conhecimento novo sobre o servidor vai em titan/servidor.md.
- Tarefa repetitiva e sensível (update, backup)? Crie um script em acoes/ e
  cite-o em titan/servidor.md.
- O token do Telegram fica só em /var/lib/titan-agent/.claude/channels/telegram/.env.
