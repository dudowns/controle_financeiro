[Setup]
AppName=Controle Financeiro
AppVersion=1.3.0
AppPublisher=Dudowns
DefaultDirName={autopf}\ControleFinanceiro
DefaultGroupName=Controle Financeiro
UninstallDisplayIcon={app}\controle_financeiro_app.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.
OutputBaseFilename=ControleFinanceiro_Setup

[Files]
; 🔥 AGORA USANDO A PASTA DEBUG!
Source: "C:\Deepseek\build\windows\x64\runner\Debug\controle_financeiro_app.exe"; DestDir: "{app}"
Source: "C:\Deepseek\build\windows\x64\runner\Debug\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Controle Financeiro"; Filename: "{app}\controle_financeiro_app.exe"
Name: "{autodesktop}\Controle Financeiro"; Filename: "{app}\controle_financeiro_app.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Criar ícone na área de trabalho"; GroupDescription: "Ícones adicionais:"; Flags: checkedonce

[Run]
Filename: "{app}\controle_financeiro_app.exe"; Description: "Executar Controle Financeiro"; Flags: postinstall nowait skipifsilent