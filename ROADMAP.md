# Roadmap

## Feito

- [x] Scripts e documentação dos labs 01 a 10
- [x] Caixa de ferramentas com scripts `.bat`, PowerShell e Linux, testada num Windows 11
- [x] Automações em JavaScript (relatório de chamados, certificados e saúde de serviços) com testes
- [x] Runbooks de troubleshooting e checklists de processos
- [x] Template do Zabbix e painel do Grafana provisionados como código
- [x] CI com lint, testes no Ubuntu e no Windows, testes do Node, ShellCheck e validação dos docker-compose

## Agora

- [ ] Executar os labs 01 a 10 no Hyper-V e marcar os checklists
- [ ] Adicionar prints em cada lab (gpresult, painel do Grafana, relatório de saúde do AD)

## Próximos labs

- [ ] Atualizações: WSUS ou Azure Update Manager, grupos de atualização e relatório de conformidade
- [ ] Identidade híbrida: Entra Connect com sincronização de senha, MFA e acesso condicional
- [ ] Intune: registro do CL01, política de conformidade, BitLocker e instalação de aplicativos
- [ ] Certificados: AD CS com autoridade certificadora interna e emissão automática por GPO
- [ ] Segundo DC: DC02, transferência dos papéis FSMO e teste de queda do DC01
- [ ] Hardening: LAPS, delegação de permissões e separação das contas administrativas
- [ ] Alertas do Grafana e do Zabbix chegando no Teams ou no Telegram

## Rastreabilidade e auditoria

Transformar em lab o que está no [guia de rastreabilidade](docs/guias/rastreabilidade-e-auditoria.md):

- [ ] NTP: DC01 sincronizando com uma fonte externa, o domínio seguindo o DC01 e um item do Zabbix alertando relógio fora do horário
- [ ] Política de auditoria do Windows por GPO (logon, mudança de grupo, acesso a pasta) com os eventos centralizados
- [ ] Registro de instalação de um servidor gerado por script, com versões, configuração e conferência
- [ ] Revisão de acessos periódica: relatório por grupo pronto para o dono do sistema aprovar

## Certificações que quero tirar

- [ ] ITIL 4 Foundation
- [ ] AZ-900 (Azure Fundamentals)
- [ ] MS-900 (Microsoft 365 Fundamentals)
- [ ] Fortinet Certified Associate
- [ ] AZ-800 (Windows Server Hybrid Administrator)
