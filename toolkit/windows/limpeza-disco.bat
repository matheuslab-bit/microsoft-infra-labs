@echo off
setlocal EnableExtensions
rem ============================================================
rem  limpeza-disco.bat
rem  Libera espaco no C: apagando o que e seguro apagar:
rem  temporarios do usuario, temporarios do Windows e o cache de
rem  download do Windows Update. Mostra quanto espaco foi liberado.
rem
rem  Uso: executar como administrador
rem ============================================================

net session >nul 2>&1
if errorlevel 1 (
    echo Este script precisa ser executado como administrador.
    pause
    exit /b 1
)

set "PS=powershell -NoProfile -Command"
for /f %%a in ('%PS% "[math]::Round((Get-PSDrive C).Free/1GB,2)"') do set "ANTES=%%a"
echo Espaco livre no C: antes: %ANTES% GB
choice /c SN /m "Apagar temporarios e o cache do Windows Update"
if errorlevel 2 exit /b 0

echo Limpando temporarios do usuario...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%p in ("%TEMP%\*") do rd /s /q "%%p" >nul 2>&1

echo Limpando temporarios do Windows...
del /f /s /q "%WINDIR%\Temp\*" >nul 2>&1
for /d %%p in ("%WINDIR%\Temp\*") do rd /s /q "%%p" >nul 2>&1

echo Limpando cache de download do Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /f /s /q "%WINDIR%\SoftwareDistribution\Download\*" >nul 2>&1
for /d %%p in ("%WINDIR%\SoftwareDistribution\Download\*") do rd /s /q "%%p" >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1

for /f %%a in ('%PS% "[math]::Round((Get-PSDrive C).Free/1GB,2)"') do set "DEPOIS=%%a"
echo.
echo Espaco livre no C: depois: %DEPOIS% GB  (antes: %ANTES% GB)
echo Arquivos em uso sao ignorados, isso e normal.
echo Para ir alem, use "cleanmgr /sageset:1" e depois "cleanmgr /sagerun:1".
pause
endlocal
