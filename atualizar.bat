@echo off
title Atualizador Controle Financeiro - WINDOWS
color 0A

:: Verificar se está rodando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Execute como Administrador para melhor funcionamento!
    echo.
    pause
)

:inicio
cls
echo =====================================================
echo    🔄 ATUALIZADOR CONTROLE FINANCEIRO - WINDOWS
echo =====================================================
echo.
echo 📁 Pasta do projeto: C:\Deepseek
echo 📁 Destino: C:\Program Files (x86)\ControleFinanceiro
echo.
echo [1] 📦 Compilar e Atualizar
echo [2] 🚀 Abrir o App
echo [3] 🔧 Compilar + Abrir
echo [4] 🗑️  Limpar e Recompilar
echo [5] ❌ Sair
echo.
set /p opcao=Escolha uma opcao: 

if "%opcao%"=="1" goto atualizar
if "%opcao%"=="2" goto abrir
if "%opcao%"=="3" goto compilar_abrir
if "%opcao%"=="4" goto limpar
if "%opcao%"=="5" exit
goto inicio

:atualizar
cls
echo =====================================================
echo    📦 COMPILANDO NOVA VERSAO
echo =====================================================
echo.

cd /d C:\Deepseek

echo [1/5] Verificando dependencias...
call flutter pub get

echo [2/5] Compilando versao Release Windows...
call flutter build windows --release

if %errorlevel% neq 0 (
    echo.
    echo ❌ ERRO NA COMPILACAO!
    echo.
    pause
    goto inicio
)

echo [3/5] Parando processo em execucao...
taskkill /F /IM controle_financeiro_app.exe 2>nul
timeout /t 2 /nobreak >nul

echo [4/5] Copiando arquivos...

:: Criar pasta destino se não existir
if not exist "C:\Program Files (x86)\ControleFinanceiro" (
    mkdir "C:\Program Files (x86)\ControleFinanceiro"
)

:: Copiar executável
copy /Y "build\windows\x64\runner\Release\controle_financeiro_app.exe" "C:\Program Files (x86)\ControleFinanceiro\" >nul

:: Copiar pasta data (se existir)
if exist "build\windows\x64\runner\Release\data" (
    xcopy /E /I /Y "build\windows\x64\runner\Release\data" "C:\Program Files (x86)\ControleFinanceiro\data\" >nul
)

:: Copiar DLLs necessárias
copy /Y "build\windows\x64\runner\Release\*.dll" "C:\Program Files (x86)\ControleFinanceiro\" >nul

echo [5/5] Concluido!
echo.
echo =====================================================
echo    ✅ APP ATUALIZADO COM SUCESSO!
echo =====================================================
echo.
echo 📍 Local: C:\Program Files (x86)\ControleFinanceiro\controle_financeiro_app.exe
echo.
pause
goto inicio

:compilar_abrir
cls
echo =====================================================
echo    📦 COMPILANDO E ABRINDO...
echo =====================================================
echo.

cd /d C:\Deepseek

call flutter build windows --release

if %errorlevel% neq 0 (
    echo.
    echo ❌ ERRO NA COMPILACAO!
    pause
    goto inicio
)

taskkill /F /IM controle_financeiro_app.exe 2>nul

:: Criar pasta se não existir
if not exist "C:\Program Files (x86)\ControleFinanceiro" (
    mkdir "C:\Program Files (x86)\ControleFinanceiro"
)

copy /Y "build\windows\x64\runner\Release\controle_financeiro_app.exe" "C:\Program Files (x86)\ControleFinanceiro\" >nul

echo.
echo ✅ Compilado! Abrindo aplicativo...
timeout /t 2 /nobreak >nul
start "" "C:\Program Files (x86)\ControleFinanceiro\controle_financeiro_app.exe"
echo.
pause
goto inicio

:abrir
cls
echo =====================================================
echo    🚀 ABRINDO APLICATIVO...
echo =====================================================
echo.

if exist "C:\Program Files (x86)\ControleFinanceiro\controle_financeiro_app.exe" (
    start "" "C:\Program Files (x86)\ControleFinanceiro\controle_financeiro_app.exe"
    echo ✅ App iniciado!
) else (
    echo ❌ App não encontrado!
    echo Compile primeiro com a opcao [1]
)

echo.
pause
goto inicio

:limpar
cls
echo =====================================================
echo    🗑️  LIMPANDO E RECOMPILANDO
echo =====================================================
echo.

cd /d C:\Deepseek

echo [1/4] Limpando cache...
call flutter clean

echo [2/4] Buscando dependencias...
call flutter pub get

echo [3/4] Compilando...
call flutter build windows --release

if %errorlevel% neq 0 (
    echo.
    echo ❌ ERRO NA COMPILACAO!
    pause
    goto inicio
)

echo [4/4] Copiando arquivos...

:: Criar pasta destino se não existir
if not exist "C:\Program Files (x86)\ControleFinanceiro" (
    mkdir "C:\Program Files (x86)\ControleFinanceiro"
)

copy /Y "build\windows\x64\runner\Release\controle_financeiro_app.exe" "C:\Program Files (x86)\ControleFinanceiro\" >nul

echo.
echo ✅ Limpeza e recompilação concluídas!
echo.
pause
goto inicio