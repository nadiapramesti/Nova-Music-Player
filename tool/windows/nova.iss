; Installer Nova buat Windows (dibikin otomatis di GitHub Actions).
; Pasang ke folder user (gak minta izin admin).
#ifndef MyVersion
  #define MyVersion "0.0.0"
#endif

[Setup]
AppId={{6E8D6456-4E6F-7661-4D75-73696350C001}
AppName=Nova
AppVersion={#MyVersion}
AppPublisher=Nadia Pramesti
DefaultDirName={localappdata}\Programs\Nova
DefaultGroupName=Nova
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..
OutputBaseFilename=Nova-{#MyVersion}-setup
SetupIconFile=app_icon.ico
UninstallDisplayIcon={app}\nova.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Bikin ikon di desktop"; GroupDescription: "Tambahan:"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Nova"; Filename: "{app}\nova.exe"
Name: "{autodesktop}\Nova"; Filename: "{app}\nova.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\nova.exe"; Description: "Buka Nova"; Flags: nowait postinstall skipifsilent
