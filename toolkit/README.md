# Caixa de ferramentas

Scripts que eu levo num pen drive ou numa pasta compartilhada da TI, para o atendimento do dia a dia. Diferente dos labs, eles não dependem do ambiente do laboratório: funcionam em qualquer máquina.

## Windows (`.bat`, dois cliques e pronto)

| Script | Para que serve |
| --- | --- |
| [`coleta-info.bat`](windows/coleta-info.bat) | Gera um `.txt` com tudo da máquina: sistema, tempo ligado, discos, rede, rotas, conexões, unidades mapeadas, administradores locais, últimas atualizações, serviços automáticos parados, antivírus, BitLocker, GPO, programas instalados e erros do log das últimas 24 horas. Ótimo para anexar ao chamado. |
| [`diagnostico-rede.bat`](windows/diagnostico-rede.bat) | Roteiro de "estou sem internet" em 7 etapas (IP, gateway, DNS, internet por IP, por nome, porta 443 e tracert), com `[OK]` ou `[FALHA]` em cada uma. |
| [`reparo-rede.bat`](windows/reparo-rede.bat) | Limpa o cache de DNS, renova o IP e registra a máquina no DNS. Opcionalmente reseta o Winsock e a pilha TCP/IP. Pede confirmação antes. |
| [`limpeza-disco.bat`](windows/limpeza-disco.bat) | Libera espaço apagando temporários e o cache do Windows Update, e mostra quanto liberou. Pede confirmação antes. |

```cmd
coleta-info.bat            :: salva na Área de Trabalho
coleta-info.bat C:\Temp    :: salva na pasta informada
diagnostico-rede.bat www.microsoft.com
```

Os scripts de reparo e de limpeza pedem execução como administrador e confirmação antes de mexer em qualquer coisa.

## PowerShell

| Script | Para que serve |
| --- | --- |
| [`Get-InventarioRemoto.ps1`](powershell/Get-InventarioRemoto.ps1) | Inventário de várias máquinas de uma vez (modelo, número de série, sistema, CPU, memória, disco, IP, último boot e usuário logado) em CSV. Máquina desligada aparece como Offline, sem parar o script. |
| [`Test-Portas.ps1`](powershell/Test-Portas.ps1) | Responde "é o firewall?". Testa portas TCP, com listas prontas para AD, web, RDP, SQL e VoIP (SIP). |
| [`Get-OrigemBloqueio.ps1`](powershell/Get-OrigemBloqueio.ps1) | Descobre qual computador está bloqueando a conta de um usuário (evento 4740 no PDC). |
| [`Get-HistoricoReinicio.ps1`](powershell/Get-HistoricoReinicio.ps1) | Mostra quando o servidor reiniciou, quem reiniciou e se foi desligamento inesperado. |
| [`Export-MembrosGrupo.ps1`](powershell/Export-MembrosGrupo.ps1) | Exporta quem está em cada grupo do AD (incluindo grupos aninhados) para revisão de acessos, um pedido comum em auditoria. |

```powershell
.\Test-Portas.ps1 -ComputerName dc01 -Preset AD
.\Get-InventarioRemoto.ps1 -ComputerName PC01,PC02,PC03 -OutputPath .\inventario.csv
.\Get-OrigemBloqueio.ps1 -UserName ana.ribeiro
```

Todos têm ajuda: `Get-Help .\Test-Portas.ps1 -Full`.

## Linux

| Script | Para que serve |
| --- | --- |
| [`coleta-info.sh`](linux/coleta-info.sh) | Versão Linux do `coleta-info.bat`: sistema, CPU, memória, disco, rede, portas abertas, serviços com falha, últimos logins, processos que mais consomem e erros do journal. |

```bash
chmod +x coleta-info.sh && sudo ./coleta-info.sh /tmp
```

## Testado

O `coleta-info.bat`, o `diagnostico-rede.bat`, o `Test-Portas.ps1` e o `Get-HistoricoReinicio.ps1` foram executados num Windows 11. Os scripts que dependem do AD estão prontos para rodar no DC do lab. No CI, os scripts PowerShell passam pelo PSScriptAnalyzer e por testes, e o script Linux passa pelo ShellCheck.
