@echo off
setlocal EnableExtensions
rem ============================================================
rem  reparo-rede.bat
rem  Os passos de reparo de rede que mais resolvem no dia a dia,
rem  na ordem certa: limpa o cache de DNS, renova o IP e registra
rem  a maquina no DNS. Opcionalmente reseta o Winsock e a pilha
rem  TCP/IP (pede reinicio).
rem
rem  Uso: clique com o botao direito > Executar como administrador
rem ============================================================

net session >nul 2>&1
if errorlevel 1 (
    echo Este script precisa ser executado como administrador.
    pause
    exit /b 1
)

echo Isto vai derrubar a rede desta maquina por alguns segundos.
choice /c SN /m "Continuar"
if errorlevel 2 exit /b 0

echo.
echo [1/4] Limpando cache de DNS...
ipconfig /flushdns

echo [2/4] Liberando o IP atual...
ipconfig /release >nul

echo [3/4] Pedindo um novo IP ao DHCP...
ipconfig /renew >nul
ipconfig | findstr /i "IPv4"

echo [4/4] Registrando a maquina no DNS...
ipconfig /registerdns >nul

echo.
choice /c SN /m "Resetar tambem o Winsock e a pilha TCP/IP (exige reiniciar)"
if errorlevel 2 goto :fim
netsh winsock reset
netsh int ip reset
echo Reinicie a maquina para concluir.

:fim
echo.
echo Concluido. Rode o diagnostico-rede.bat para conferir.
pause
endlocal
