; Firm Library (Biblioteca do Escritorio) - instalador para Windows
;
; Compilar:  iscc /DAppVersion=2.6.1 /DSourceExe=firmlib.exe installer\firmlib.iss
; Resultado: installer\out\firmlib-setup.exe
;
; Requer Inno Setup 6.3 ou superior.

#define AppName       "Biblioteca do Escritorio"
#define AppShortName  "Firm Library"
#define AppPublisher  "hoascv"
#define AppUrl        "https://github.com/hoascv/firmlib-releases"
#define DefaultPort   "5173"

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceExe
  #define SourceExe "firmlib.exe"
#endif

[Setup]
; Nao mudar o AppId: e o que liga uma instalacao nova a anterior.
AppId={{13700BCE-C8D9-4735-A27D-E11FC1FFEC0E}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
VersionInfoVersion={#AppVersion}

; A aplicacao escreve a base de dados em <pasta>\data, ao lado do executavel,
; e substitui-se a si propria ao atualizar. Em "Program Files" um utilizador
; sem privilegios nao conseguiria fazer nem uma coisa nem outra, por isso a
; instalacao e fora dali.
DefaultDirName=C:\FirmLibrary
DirExistsWarning=no
DefaultGroupName={#AppName}
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\firmlib.exe

PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir=out
OutputBaseFilename=firmlib-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=auto
CloseApplications=yes
CloseApplicationsFilter=firmlib.exe

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
pt.TasksGroup=Como quer que a aplicacao funcione:
pt.ServiceTask=Arrancar sozinha com o computador (recomendado)
pt.FirewallTask=Permitir o acesso a partir de outros computadores do escritorio
pt.DesktopTask=Criar um atalho no Ambiente de Trabalho
pt.OpenIcon=Abrir a Biblioteca
pt.StartIcon=Iniciar a Biblioteca
pt.InstallingService=A instalar o servico do Windows...
pt.StartingService=A arrancar a aplicacao...
pt.OpeningFirewall=A abrir a porta na rede local...
pt.RunNow=Iniciar a Biblioteca agora
pt.OpenNow=Abrir a Biblioteca no navegador
pt.DataKept=Os documentos e a base de dados ficam guardados em %1. O desinstalador nao os apaga.

en.TasksGroup=How should the application run:
en.ServiceTask=Start automatically with the computer (recommended)
en.FirewallTask=Allow access from other computers on the office network
en.DesktopTask=Create a shortcut on the Desktop
en.OpenIcon=Open the Library
en.StartIcon=Start the Library
en.InstallingService=Installing the Windows service...
en.StartingService=Starting the application...
en.OpeningFirewall=Opening the port on the local network...
en.RunNow=Start the Library now
en.OpenNow=Open the Library in the browser
en.DataKept=Your documents and database stay in %1. The uninstaller does not delete them.

[Tasks]
Name: "service";     Description: "{cm:ServiceTask}";  GroupDescription: "{cm:TasksGroup}"
Name: "firewall";    Description: "{cm:FirewallTask}"; GroupDescription: "{cm:TasksGroup}"; Flags: unchecked
Name: "desktopicon"; Description: "{cm:DesktopTask}";  GroupDescription: "{cm:TasksGroup}"

[Files]
Source: "{#SourceExe}"; DestDir: "{app}"; DestName: "firmlib.exe"; Flags: ignoreversion

[Icons]
; Atalho de internet: e por aqui que o utilizador entra na aplicacao.
Name: "{group}\{cm:OpenIcon}";           Filename: "http://localhost:{#DefaultPort}"
Name: "{autodesktop}\{#AppName}";        Filename: "http://localhost:{#DefaultPort}"; Tasks: desktopicon
; Sem servico, e preciso arrancar o programa a mao antes de abrir o navegador.
Name: "{group}\{cm:StartIcon}";          Filename: "{app}\firmlib.exe"; Tasks: not service
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\firmlib.exe"; Parameters: "install"; StatusMsg: "{cm:InstallingService}"; \
    Tasks: service; Flags: runhidden waituntilterminated
Filename: "{app}\firmlib.exe"; Parameters: "start";   StatusMsg: "{cm:StartingService}"; \
    Tasks: service; Flags: runhidden waituntilterminated

; Regra de firewall: apaga a antiga primeiro, para nao acumular duplicados.
Filename: "{sys}\netsh.exe"; \
    Parameters: "advfirewall firewall delete rule name=""{#AppShortName}"""; \
    Tasks: firewall; Flags: runhidden waituntilterminated skipifdoesntexist
Filename: "{sys}\netsh.exe"; \
    Parameters: "advfirewall firewall add rule name=""{#AppShortName}"" dir=in action=allow protocol=TCP localport={#DefaultPort} profile=private"; \
    StatusMsg: "{cm:OpeningFirewall}"; Tasks: firewall; Flags: runhidden waituntilterminated

; Ecra final. Com servico ja esta a correr, basta abrir o navegador.
Filename: "http://localhost:{#DefaultPort}"; Description: "{cm:OpenNow}"; \
    Tasks: service; Flags: postinstall shellexec nowait skipifsilent
Filename: "{app}\firmlib.exe"; Description: "{cm:RunNow}"; \
    Tasks: not service; Flags: postinstall nowait skipifsilent

[UninstallRun]
Filename: "{app}\firmlib.exe"; Parameters: "stop";      RunOnceId: "StopService";      Flags: runhidden waituntilterminated
Filename: "{app}\firmlib.exe"; Parameters: "uninstall"; RunOnceId: "RemoveService";    Flags: runhidden waituntilterminated
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""{#AppShortName}"""; \
    RunOnceId: "RemoveFirewall"; Flags: runhidden waituntilterminated

[Code]
// O executavel fica bloqueado se o servico ou uma instancia por duplo clique
// estiverem a correr, e a instalacao falharia a meio a substitui-lo.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Exe: String;
  ResultCode: Integer;
begin
  Result := '';
  Exe := ExpandConstant('{app}\firmlib.exe');
  if FileExists(Exe) then
  begin
    Exec(Exe, 'stop', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(2000);
  end;
end;

// Deixar claro que desinstalar nao apaga o acervo.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    MsgBox(FmtMessage(CustomMessage('DataKept'), [ExpandConstant('{app}\data')]),
           mbInformation, MB_OK);
end;
