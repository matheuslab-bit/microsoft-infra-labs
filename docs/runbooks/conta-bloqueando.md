# Conta bloqueando toda hora

**Sintoma:** o usuário desbloqueia a conta, troca a senha e minutos depois está bloqueado de novo.

Quase sempre é uma senha antiga salva em algum lugar, tentando logar sozinha: celular com o e-mail corporativo, unidade de rede mapeada com credencial, tarefa agendada, serviço do Windows ou uma sessão de RDP esquecida aberta em outro servidor.

## 1. Confirmar o bloqueio

```powershell
Get-ADUser ana.ribeiro -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordLastSet |
    Select-Object Name, LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordLastSet
```

## 2. Descobrir de qual máquina vêm as tentativas

O bloqueio é registrado no PDC Emulator (evento 4740), junto com o nome do computador que mandou a senha errada:

```powershell
.\toolkit\powershell\Get-OrigemBloqueio.ps1 -UserName ana.ribeiro -Hours 24
```

## 3. Agir conforme a origem

| A origem é... | O que fazer |
| --- | --- |
| A estação do próprio usuário | Painel de Controle > Gerenciador de Credenciais: apagar as credenciais antigas. Conferir unidades mapeadas (`net use`). |
| Um servidor | Procurar tarefa agendada ou serviço rodando com a conta do usuário (`Get-ScheduledTask`, `Get-CimInstance Win32_Service`). Ver se há sessão RDP desconectada (`quser /server:NOME`). |
| Servidor de e-mail ou ActiveSync | É o celular. Atualizar a senha no app de e-mail ou remover e adicionar a conta de novo. |
| Em branco ou desconhecida | Pode ser tentativa externa. Avisar segurança, conferir logs do firewall e da VPN. |

## 4. Desbloquear e acompanhar

```powershell
Unlock-ADAccount ana.ribeiro
```

Acompanhar por meia hora. Se voltar a bloquear, a origem ainda está ativa.

## Registrar no chamado

Origem encontrada, o que foi removido ou corrigido e o horário do último bloqueio.
