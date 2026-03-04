[Setup]
AppName=Controle Financeiro
AppVersion=1.0.0
AppPublisher=Carlos Eduardo
DefaultDirName={pf}\ControleFinanceiro
DefaultGroupName=Controle Financeiro
OutputDir=installer
OutputBaseFilename=ControleFinanceiroSetup
Compression=lzma2
SolidCompression=yes

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Controle Financeiro"; Filename: "{app}\controle_financeiro_app.exe"
Name: "{autodesktop}\Controle Financeiro"; Filename: "{app}\controle_financeiro_app.exe"