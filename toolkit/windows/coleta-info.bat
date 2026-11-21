@echo off
setlocal EnableExtensions
rem ============================================================
rem  coleta-info.bat
rem  Junta num unico arquivo .txt as informacoes que eu sempre
rem  preciso quando vou atender uma maquina: sistema, rede, disco,
rem  atualizacoes, administradores locais, servicos parados e erros
rem  recentes no log do Windows.
rem
rem  Uso:   coleta-info.bat            (salva na Area de Trabalho)
rem         coleta-info.bat C:\Temp    (salva na pasta informada)
rem  Dica:  rode como administrador para pegar GPO e BitLocker.
rem ============================================================

set "DEST=%~1"
if "%DEST%"=="" set "DEST=%USERPROFILE%\Desktop"
if not exist "%DEST%" mkdir "%DEST%"

for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm"') do set "STAMP=%%i"
set "OUT=%DEST%\info_%COMPUTERNAME%_%STAMP%.txt"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -Command"

echo Coletando informacoes de %COMPUTERNAME%. Isso leva cerca de 1 minuto...

> "%OUT%" echo Relatorio de %COMPUTERNAME% - %DATE% %TIME%
>>"%OUT%" echo Usuario: %USERDOMAIN%\%USERNAME%

call :secao "SISTEMA"
systeminfo >> "%OUT%" 2>&1

call :secao "TEMPO LIGADO"
%PS% "$b=(Get-CimInstance Win32_OperatingSystem).LastBootUpTime; 'Ultimo boot: {0}  (ligado ha {1:N1} dias)' -f $b, ((Get-Date)-$b).TotalDays" >> "%OUT%" 2>&1

call :secao "DISCOS"
%PS% "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID, VolumeName, @{n='TamanhoGB';e={[math]::Round($_.Size/1GB,1)}}, @{n='LivreGB';e={[math]::Round($_.FreeSpace/1GB,1)}}, @{n='LivrePct';e={[math]::Round($_.FreeSpace/$_.Size*100,1)}} | Format-Table -AutoSize | Out-String -Width 200" >> "%OUT%" 2>&1

call :secao "REDE (ipconfig /all)"
ipconfig /all >> "%OUT%" 2>&1

call :secao "ROTAS"
route print -4 >> "%OUT%" 2>&1

call :secao "CONEXOES ESTABELECIDAS"
netstat -ano | findstr /i "ESTABLISHED" >> "%OUT%" 2>&1

call :secao "PORTAS ESCUTANDO"
netstat -ano | findstr /i "LISTENING" >> "%OUT%" 2>&1

call :secao "UNIDADES MAPEADAS E COMPARTILHAMENTOS"
net use >> "%OUT%" 2>&1
net share >> "%OUT%" 2>&1

call :secao "ADMINISTRADORES LOCAIS"
%PS% "Get-LocalGroupMember -SID S-1-5-32-544 | Select-Object Name, ObjectClass, PrincipalSource | Format-Table -AutoSize | Out-String -Width 200" >> "%OUT%" 2>&1

call :secao "ULTIMAS ATUALIZACOES INSTALADAS"
%PS% "Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledOn | Format-Table -AutoSize | Out-String -Width 200" >> "%OUT%" 2>&1

call :secao "SERVICOS AUTOMATICOS QUE ESTAO PARADOS"
%PS% "Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | Select-Object Name, DisplayName, State | Format-Table -AutoSize | Out-String -Width 200" >> "%OUT%" 2>&1

call :secao "ANTIVIRUS (WINDOWS DEFENDER)"
%PS% "Get-MpComputerStatus | Select-Object AMServiceEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated | Format-List | Out-String" >> "%OUT%" 2>&1

call :secao "BITLOCKER"
manage-bde -status C: >> "%OUT%" 2>&1

call :secao "GPO APLICADAS (resumo)"
gpresult /r >> "%OUT%" 2>&1

call :secao "PROGRAMAS INSTALADOS"
%PS% "Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName | Sort-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher | Format-Table -AutoSize | Out-String -Width 250" >> "%OUT%" 2>&1

call :secao "ERROS E CRITICOS NO LOG DE SISTEMA (ULTIMAS 24 HORAS)"
%PS% "Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-1)} -MaxEvents 25 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName, Message | Format-Table -Wrap | Out-String -Width 250" >> "%OUT%" 2>&1

echo.
echo Pronto. Relatorio salvo em:
echo   %OUT%
endlocal
exit /b 0

:secao
>>"%OUT%" echo.
>>"%OUT%" echo ============================================================
>>"%OUT%" echo  %~1
>>"%OUT%" echo ============================================================
exit /b 0
