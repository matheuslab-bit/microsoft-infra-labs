# Checklist: saída de colaborador

Conta de ex-colaborador ativa é risco de segurança e problema em auditoria. A parte do AD está automatizada no [`Invoke-LabUserOffboarding.ps1`](../../labs/09-operations-automation/Invoke-LabUserOffboarding.ps1). O resto fica neste checklist.

## No dia do desligamento (no horário combinado com o RH)

- [ ] Conta desativada, senha trocada, grupos removidos e conta movida para `Desativados` (script acima, com o número do chamado)
- [ ] Sessões encerradas no Microsoft 365 (Entra ID > Usuário > Revogar sessões)
- [ ] MFA e dispositivos móveis removidos; e-mail corporativo apagado do celular, se houver gerenciamento
- [ ] Acesso de VPN e acesso remoto bloqueados
- [ ] Ramal e usuário de telefonia desativados
- [ ] Senhas compartilhadas que a pessoa conhecia trocadas (cofre de senhas, contas de serviço, Wi-Fi de visitante, se for o caso)

## Dados e equipamento

- [ ] Caixa de e-mail convertida em compartilhada ou encaminhada para o gestor, pelo prazo combinado
- [ ] Arquivos do OneDrive e da pasta pessoal transferidos para o gestor
- [ ] Equipamentos devolvidos e conferidos com o inventário
- [ ] Estação formatada ou reimplantada antes de ir para outra pessoa

## Fechamento

- [ ] CSV dos grupos anteriores anexado ao chamado (o script gera)
- [ ] Licença do Microsoft 365 liberada
- [ ] Conta excluída após o período de retenção da empresa (por exemplo, 90 dias)
