# Disco cheio no servidor

**Primeiro:** não apagar nada às cegas. Descobrir o que cresceu e por quê.

## 1. Quanto falta e o que está ocupando

```powershell
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
    Select-Object DeviceID, @{n='LivreGB';e={[math]::Round($_.FreeSpace/1GB,1)}}, @{n='LivrePct';e={[math]::Round($_.FreeSpace/$_.Size*100,1)}}

# as 15 maiores pastas na raiz do C: (pode demorar)
Get-ChildItem C:\ -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    [pscustomobject]@{ Pasta = $_.FullName; GB = [math]::Round((Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1GB, 2) }
} | Sort-Object GB -Descending | Select-Object -First 15
```

## 2. Os suspeitos de sempre

| Onde | O que é | Pode limpar? |
| --- | --- | --- |
| `C:\Windows\SoftwareDistribution\Download` | Cache do Windows Update | Sim, com o serviço parado ([`limpeza-disco.bat`](../../toolkit/windows/limpeza-disco.bat)) |
| `C:\Windows\Temp` e `%TEMP%` | Temporários | Sim |
| `C:\inetpub\logs\LogFiles` | Logs do IIS | Sim, os antigos. Criar rotina de retenção |
| Logs de aplicação | Aplicação sem rotação de log | Arquivar os antigos e configurar rotação |
| `C:\Windows\WinSxS` | Componentes do Windows | Nunca apagar à mão. Usar `Dism /Online /Cleanup-Image /StartComponentCleanup` |
| `pagefile.sys` / `hiberfil.sys` | Memória virtual e hibernação | Hibernação pode ser desligada em servidor: `powercfg /h off` |
| Pastas de usuários no servidor | Arquivos salvos onde não deviam | Combinar com o dono antes |

## 3. Resolver de verdade

- Se é log, configurar retenção para não voltar.
- Se é crescimento normal de dados, planejar aumento de disco (no Hyper-V: `Resize-VHD` e depois estender a partição).
- Criar ou ajustar o alerta de disco no Zabbix para avisar com 15% livres, e não quando já estiver em 2%.

## Registrar no chamado

Quanto estava livre, o que ocupava, o que foi limpo e qual ação evita que volte.
