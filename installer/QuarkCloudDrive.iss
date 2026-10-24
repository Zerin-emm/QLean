; ============================================================================================
;  夸克网盘 Inno Setup 安装脚本 —— x64 版
;  编译： "D:\Inno Setup 6.6.1\ISCC.exe" installer\QuarkCloudDrive.iss
;  前置： 确保 QLean\{app} 与 QLean\{userappdata}\quark-cloud-drive 已准备好
;  产物： installer\Output\QuarkCloudDrive-Setup-3.23.2-x64.exe
;  卸载： 程序目录与开机自启项清理；用户数据目录由用户选择是否删除（默认保留）
; ============================================================================================

#define MyAppName "夸克网盘"
#define MyAppPathName "QuarkCloudDrive"
#define MyAppVersion "3.23.2"
#define MyAppPublisher "QLean"
#define MyAppUrl "https://pan.quark.cn/"
#define MyAppExeName "QuarkCloudDrive.exe"
#define BuildDir "..\{app}"
#define AppDataDir "{userappdata}\quark-cloud-drive"

[Setup]
AppId={{6F1B8C2D-3A7E-4C59-9D8B-5E2A1F7C4B90}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppUrl}
AppSupportURL={#MyAppUrl}
AppUpdatesURL={#MyAppUrl}
DefaultDirName={localappdata}\Programs\{#MyAppPathName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.19041
OutputDir=Output
OutputBaseFilename=QuarkCloudDrive-Setup-{#MyAppVersion}-x64
SetupIconFile=..\{app}\app-3.23.2\resources\assets\icon_win.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern dynamic windows11
CloseApplications=yes
CloseApplicationsFilter={#MyAppExeName}
RestartApplications=no

[Languages]
Name: "chinese"; MessagesFile: "compiler:Languages\Chinese.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\{userappdata}\quark-cloud-drive\*"; DestDir: "{userappdata}\quark-cloud-drive"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
const
  StartupRunKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run';
  StartupRunValueName = '{#MyAppName}';

var
  DeleteUserData: Boolean;
  DataDirPath: String;
  AskUserDataAnswered: Boolean;

procedure RemoveStartupEntry();
var
  ExistingValue: String;
begin
  if not RegQueryStringValue(HKCU, StartupRunKey, StartupRunValueName, ExistingValue) then
  begin
    Log('未找到自启动项，无需删除');
    Exit;
  end;
  if RegDeleteValue(HKCU, StartupRunKey, StartupRunValueName) then
    Log('已删除自启动项（原值：' + ExistingValue + '）')
  else
    Log('无法删除自启动项（原值：' + ExistingValue + '）');
end;

procedure AskAboutUserData();
begin
  if AskUserDataAnswered then Exit;
  AskUserDataAnswered := True;

  if not DirExists(DataDirPath) then
  begin
    DeleteUserData := False;
    Exit;
  end;

  DeleteUserData :=
    MsgBox('是否同时删除程序数据（设置与日志）？' + #13#10 + #13#10 +
           '数据目录：' + #13#10 + DataDirPath,
           mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES;
end;

procedure RemoveUserData();
begin
  if not DeleteUserData then Exit;
  if not DirExists(DataDirPath) then Exit;
  if not DelTree(DataDirPath, True, True, True) then
    SuppressibleMsgBox('未能删除数据目录：' + #13#10 + DataDirPath + #13#10 + #13#10 +
                       '请手动删除该文件夹。', mbError, MB_OK, IDOK);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    DataDirPath := ExpandConstant('{#AppDataDir}');
    AskAboutUserData();
    RemoveStartupEntry();
  end
  else if CurUninstallStep = usPostUninstall then
  begin
    RemoveUserData();
  end;
end;
