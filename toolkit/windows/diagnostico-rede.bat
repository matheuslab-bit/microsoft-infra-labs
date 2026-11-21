@echo off
setlocal EnableExtensions
rem ============================================================
rem  diagnostico-rede.bat
rem  Roteiro de "estou sem internet" em camadas: placa de rede,
rem  gateway, DNS interno, internet por IP, internet por nome e
rem  porta 443. Mostra [OK] ou [FALHA] em cada etapa e diz onde
rem  o problema provavelmente esta.
rem
rem  Uso:  diagnostico-rede.bat [site para testar]
rem        diagnostico-rede.bat www.microsoft.com
rem ============================================================

set "SITE=%~1"
if "%SITE%"=="" set "SITE=www.google.com"
set "PS=powershell -NoProfile -Command"
set "FALHOU="

echo.
echo === 1. Placa de rede e IP ===
%PS% "Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | ForEach-Object { '{0}: IP {1}  Gateway {2}  DNS {3}' -f $_.InterfaceAlias, $_.IPv4Address.IPAddress, $_.IPv4DefaultGateway.NextHop, ($_.DNSServer.ServerAddresses -join ', ') }"

for /f "delims=" %%g in ('%PS% "(Get-NetRoute -DestinationPrefix 0.0.0.0/0 -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop"') do set "GW=%%g"
for /f "delims=" %%d in ('%PS% "(Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | Select-Object -First 1).ServerAddresses[0]"') do set "DNS=%%d"

if not defined GW (
    echo [FALHA] Nenhum gateway padrao. Verifique cabo/Wi-Fi e se o DHCP entregou IP. Um IP 169.254.x.x indica que o DHCP nao respondeu.
    goto :fim
)

echo.
echo === 2. Gateway (%GW%) ===
ping -n 2 -w 1000 %GW% >nul && echo [OK] Gateway responde. || (echo [FALHA] Gateway nao responde: problema na rede local, switch, VLAN ou Wi-Fi. & set "FALHOU=1")

echo.
echo === 3. Servidor DNS (%DNS%) ===
ping -n 2 -w 1000 %DNS% >nul && echo [OK] Servidor DNS responde ao ping. || echo [ALERTA] DNS nao responde ao ping. Alguns servidores bloqueiam ICMP, o teste 5 confirma.

echo.
echo === 4. Internet por IP (1.1.1.1) ===
ping -n 2 -w 1000 1.1.1.1 >nul && echo [OK] Saida para a internet funcionando. || (echo [FALHA] Sem saida para a internet: verifique firewall, proxy ou link da operadora. & set "FALHOU=1")

echo.
echo === 5. Resolucao de nome (%SITE%) ===
nslookup %SITE% >nul 2>&1 && echo [OK] DNS resolve nomes. || (echo [FALHA] DNS nao resolve: teste "nslookup %SITE% 1.1.1.1" para saber se e o DNS interno. & set "FALHOU=1")

echo.
echo === 6. Porta 443 em %SITE% ===
%PS% "if ((Test-NetConnection -ComputerName '%SITE%' -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded) { '[OK] HTTPS acessivel.' } else { '[FALHA] Porta 443 bloqueada: firewall, proxy ou filtro de conteudo.' }"

echo.
echo === 7. Caminho ate a internet (primeiros saltos) ===
tracert -d -h 8 -w 800 1.1.1.1

:fim
echo.
if defined FALHOU (echo Resultado: encontrei falhas. Comece pela primeira etapa que falhou.) else (echo Resultado: nenhuma falha basica encontrada.)
echo Se o problema for so num sistema, teste a porta dele com: Test-NetConnection servidor -Port numero
endlocal
