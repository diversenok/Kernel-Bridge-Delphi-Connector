program ParentTokenId;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  DelphiApi.Reflection in '..\..\NtUtils\Headers\DelphiApi.Reflection.pas',
  Ntapi.ntdbg in '..\..\NtUtils\Headers\Ntapi.ntdbg.pas',
  Ntapi.ntdef in '..\..\NtUtils\Headers\Ntapi.ntdef.pas',
  Ntapi.ntexapi in '..\..\NtUtils\Headers\Ntapi.ntexapi.pas',
  Ntapi.ntioapi in '..\..\NtUtils\Headers\Ntapi.ntioapi.pas',
  Ntapi.ntkeapi in '..\..\NtUtils\Headers\Ntapi.ntkeapi.pas',
  Ntapi.ntldr in '..\..\NtUtils\Headers\Ntapi.ntldr.pas',
  Ntapi.ntmmapi in '..\..\NtUtils\Headers\Ntapi.ntmmapi.pas',
  Ntapi.ntobapi in '..\..\NtUtils\Headers\Ntapi.ntobapi.pas',
  Ntapi.ntpebteb in '..\..\NtUtils\Headers\Ntapi.ntpebteb.pas',
  Ntapi.ntpsapi in '..\..\NtUtils\Headers\Ntapi.ntpsapi.pas',
  Ntapi.ntrtl in '..\..\NtUtils\Headers\Ntapi.ntrtl.pas',
  Ntapi.ntseapi in '..\..\NtUtils\Headers\Ntapi.ntseapi.pas',
  Ntapi.ntstatus in '..\..\NtUtils\Headers\Ntapi.ntstatus.pas',
  Ntapi.ntwow64 in '..\..\NtUtils\Headers\Ntapi.ntwow64.pas',
  NtUtils.Version in '..\..\NtUtils\Headers\NtUtils.Version.pas',
  Winapi.ConsoleApi in '..\..\NtUtils\Headers\Winapi.ConsoleApi.pas',
  Winapi.ntlsa in '..\..\NtUtils\Headers\Winapi.ntlsa.pas',
  Winapi.NtSecApi in '..\..\NtUtils\Headers\Winapi.NtSecApi.pas',
  Winapi.ProcessThreadsApi in '..\..\NtUtils\Headers\Winapi.ProcessThreadsApi.pas',
  Winapi.Sddl in '..\..\NtUtils\Headers\Winapi.Sddl.pas',
  Winapi.securitybaseapi in '..\..\NtUtils\Headers\Winapi.securitybaseapi.pas',
  Winapi.Shell in '..\..\NtUtils\Headers\Winapi.Shell.pas',
  Winapi.WinBase in '..\..\NtUtils\Headers\Winapi.WinBase.pas',
  Winapi.WinError in '..\..\NtUtils\Headers\Winapi.WinError.pas',
  Winapi.WinNt in '..\..\NtUtils\Headers\Winapi.WinNt.pas',
  Winapi.WinUser in '..\..\NtUtils\Headers\Winapi.WinUser.pas',
  DelphiUtils.Arrays in '..\..\NtUtils\DelphiUtils.Arrays.pas',
  DelphiUtils.Async in '..\..\NtUtils\DelphiUtils.Async.pas',
  DelphiUtils.AutoObject in '..\..\NtUtils\DelphiUtils.AutoObject.pas',
  NtUtils.Ldr in '..\..\NtUtils\NtUtils.Ldr.pas',
  NtUtils.Lsa in '..\..\NtUtils\NtUtils.Lsa.pas',
  NtUtils.Lsa.Sid in '..\..\NtUtils\NtUtils.Lsa.Sid.pas',
  NtUtils.Objects in '..\..\NtUtils\NtUtils.Objects.pas',
  NtUtils.Objects.Snapshots in '..\..\NtUtils\NtUtils.Objects.Snapshots.pas',
  NtUtils in '..\..\NtUtils\NtUtils.pas',
  NtUtils.Processes.Memory in '..\..\NtUtils\NtUtils.Processes.Memory.pas',
  NtUtils.Processes in '..\..\NtUtils\NtUtils.Processes.pas',
  NtUtils.Processes.Query in '..\..\NtUtils\NtUtils.Processes.Query.pas',
  NtUtils.Security.Acl in '..\..\NtUtils\NtUtils.Security.Acl.pas',
  NtUtils.Security in '..\..\NtUtils\NtUtils.Security.pas',
  NtUtils.Security.Sid in '..\..\NtUtils\NtUtils.Security.Sid.pas',
  NtUtils.System in '..\..\NtUtils\NtUtils.System.pas',
  NtUtils.SysUtils in '..\..\NtUtils\NtUtils.SysUtils.pas',
  NtUtils.Threads in '..\..\NtUtils\NtUtils.Threads.pas',
  NtUtils.Tokens.Impersonate in '..\..\NtUtils\NtUtils.Tokens.Impersonate.pas',
  NtUtils.Tokens.Misc in '..\..\NtUtils\NtUtils.Tokens.Misc.pas',
  NtUtils.Tokens in '..\..\NtUtils\NtUtils.Tokens.pas',
  NtUtils.Tokens.Query in '..\..\NtUtils\NtUtils.Tokens.Query.pas',
  DelphiUiLib.Strings in '..\..\NtUtils\NtUiLib\DelphiUiLib.Strings.pas',
  NtUiLib.Errors in '..\..\NtUtils\NtUiLib\NtUiLib.Errors.pas',
  KernelBridgeApi in '..\..\Headers\KernelBridgeApi.pas',
  KernelBridge.Memory in '..\..\KernelBridge.Memory.pas',
  KernelBridge in '..\..\KernelBridge.pas',
  KernelBridge.Processes.Memory in '..\..\KernelBridge.Processes.Memory.pas',
  KernelBridge.Processes in '..\..\KernelBridge.Processes.pas',
  KernelBridge.Section in '..\..\KernelBridge.Section.pas',
  KernelBridge.Threads in '..\..\KernelBridge.Threads.pas',
  ParentTokenId.Helper in 'ParentTokenId.Helper.pas',
  ParentTokenId.Main in 'ParentTokenId.Main.pas';

function Report(const Status: TNtxStatus): String;
begin
  if Status.IsSuccess then
    Result := 'Success'
  else
    Result := Status.Location + ': ' + RtlxNtStatusName(Status);
end;

begin
  writeln(Report(Main));
  readln;
end.
