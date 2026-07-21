; ============================================================================
;  Documentum — Windows Installer Script (Inno Setup)
; ============================================================================
;  Packages the Flutter Windows release build into a single
;  Documentum-Setup.exe installer.
;
;  BEFORE COMPILING:
;    1. Run a release build first:
;         flutter build windows --release
;       This produces:
;         build\windows\x64\runner\Release\
;
;    2. Open this file in Inno Setup Compiler (or run with ISCC.exe) and
;       Build → Compile. The finished installer is written to:
;         installer_output\Documentum-Setup-<version>.exe
;
;  Get Inno Setup: https://jrsoftware.org/isinfo.php
; ============================================================================

#define MyAppName "Documentum"
#define MyAppVersion "2.0.0"
#define MyAppPublisher "Arsalan Kaleem"
#define MyAppURL "https://github.com/ArsalanKaleem/Documentum"
; NOTE: Flutter names the built exe after the "name:" field in pubspec.yaml,
; not the display app name — this project's pubspec name is
; "smart_docs_generator", so that's the actual filename in
; build\windows\x64\runner\Release\. All shortcuts/labels below still show
; "Documentum" since that's controlled separately by MyAppName.
#define MyAppExeName "smart_docs_generator.exe"
; Path to the Flutter release build output, relative to this script.
#define MyBuildDir "..\..\build\windows\x64\runner\Release"

[Setup]
; A fixed GUID uniquely identifies this app in Windows — do not change once
; you've shipped a release, or upgrades will be treated as separate installs.
AppId={{6F1E9C2B-3A4D-4E7F-9B2C-8D1A5F6E7C90}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Require admin only if installing to Program Files; switch to "lowest" if
; you'd rather install per-user without a UAC prompt.
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

OutputDir=installer_output
OutputBaseFilename=Documentum-Setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startmenu"; Description: "Create a Start Menu shortcut"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Everything Flutter produced in the release build — exe, DLLs, data\ folder.
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Clean up any local app data Documentum writes at runtime (settings,
; project cache, session history, etc). Adjust the folder name below if
; your app stores data somewhere else via path_provider.
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}"
