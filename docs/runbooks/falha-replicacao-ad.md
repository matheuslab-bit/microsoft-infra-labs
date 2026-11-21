# Falha de replicação do Active Directory

**Sintoma:** usuário criado num DC não aparece no outro, senha trocada não funciona em algumas máquinas, GPO aplicada pela metade. O Zabbix alerta pelo item `ad.replication.failures`.

## 1. Ver o tamanho do problema

```powershell
repadmin /replsummary
repadmin /showrepl * /csv | ConvertFrom-Csv | Where-Object { $_.'Number of Failures' -gt 0 } |
    Select-Object 'Destination DSA', 'Source DSA', 'Naming Context', 'Last Failure Time', 'Last Failure Status'
```

## 2. Os erros mais comuns

| Erro | Causa provável | O que verificar |
| --- | --- | --- |
| 1722 (RPC indisponível) | Firewall ou DC desligado | `Test-NetConnection DC02 -Port 135` e as portas RPC dinâmicas |
| 1256 / 1908 | DNS: um DC não encontra o outro | O DC deve apontar o DNS para outro DC e para si mesmo; `dcdiag /test:dns` |
| 8453 (acesso negado) | Permissão ou conta de computador do DC com problema | Logs de segurança, senha da conta de máquina |
| 8606 / 8614 | DC ficou desligado mais que o tombstone lifetime (180 dias) | Não forçar replicação. Rebaixar o DC e promover de novo |
| -2146893022 | Diferença de horário maior que 5 minutos (Kerberos) | `w32tm /query /status` em todos os DCs |

## 3. Depois de corrigir a causa

```powershell
repadmin /syncall /AdeP      # força a replicação em todos os parceiros
dcdiag /q                    # sem saída = tudo certo
```

## Cuidados

- Nunca restaurar um DC a partir de checkpoint de VM. Isso causa USN rollback e corrompe a replicação.
- Em ambiente com um DC só, não existe replicação. É mais um motivo para ter um segundo DC.
