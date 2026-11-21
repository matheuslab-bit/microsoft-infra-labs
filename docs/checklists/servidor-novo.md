# Checklist: servidor novo antes de ir para produção

Servidor que entra em produção sem backup ou sem monitoramento só é lembrado quando para. Este checklist evita isso.

## Básico

- [ ] Nome no padrão da empresa e IP fixo documentado (e reservado fora do escopo DHCP)
- [ ] Registro A e PTR no DNS
- [ ] No domínio, na OU `Computadores/Servidores` (recebe as GPOs de servidor)
- [ ] Atualizações do Windows aplicadas e servidor reiniciado
- [ ] Horário sincronizando com o domínio (`w32tm /query /status`)

## Segurança

- [ ] Só os papéis e recursos necessários instalados
- [ ] Firewall do Windows ligado, com regras só para as portas do serviço
- [ ] Administrador local com senha única (LAPS) e acesso administrativo só por grupo
- [ ] Antivírus ativo e atualizado
- [ ] RDP liberado só para o grupo de administradores e, se possível, só a partir da rede de gerência
- [ ] SMBv1 desabilitado

## Operação

- [ ] Incluído na rotina de backup e com **uma restauração testada**
- [ ] Agente do Zabbix instalado ([`Install-LabZabbixAgent.ps1`](../../labs/07-monitoring-zabbix/Install-LabZabbixAgent.ps1)) e alertas chegando
- [ ] Aparece no painel do Grafana
- [ ] Documentado: função, responsável, IP, portas usadas, dependências e como reiniciar com segurança
- [ ] Registrado no inventário

## Aceite

- [ ] Dono do sistema testou e aprovou
- [ ] Chamado ou mudança encerrado com o link da documentação
