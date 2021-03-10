unit ParentTokenId.Main;

interface

uses
  NtUtils;

function Main: TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntstatus, Ntapi.ntpsapi, KernelBridgeApi, KernelBridge,
  KernelBridge.Processes, KernelBridge.Threads, NtUtils.Tokens, NtUtils.Objects,
  NtUtils.Objects.Snapshots, NtUtils.SysUtils, DelphiUiLib.Strings,
  ParentTokenId.Helper;

function GetProcessToken(out hxToken: IHandle): TNtxStatus;
var
  PID: TProcessId32;
  hxProcess: IHandle;
begin
  write('PID: ');
  readln(PID);

  // Use Kernel Bridge to open the process
  Result := KbxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  // Get the token
  Result := NtxOpenProcessToken(hxToken, hxProcess.Handle, MAXIMUM_ALLOWED);
end;

function GetThreadToken(out hxToken: IHandle): TNtxStatus;
var
  TID: TProcessId32;
  hxThread: IHandle;
begin
  write('TID: ');
  readln(TID);

  // Use Kernel Bridge to open the thread
  Result := KbxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  // Get the token
  Result := NtxOpenThreadToken(hxToken, hxThread.Handle, MAXIMUM_ALLOWED);
end;

function CopyTokenHandle(out hxToken: IHandle): TNtxStatus;
var
  PID: TProcessId32;
  HandleValue: THandle;
  hxProcess: IHandle;
  TokenTypeIndex: Integer;
  TypeInfo: TObjectTypeInfo;
begin
  write('PID: ');
  readln(PID);
  write('Handle value: ');
  readln(HandleValue);

  // Use Kernel Bridge to open the process
  Result := KbxOpenProcess(hxProcess, PID, PROCESS_DUP_HANDLE);

  if not Result.IsSuccess then
    Exit;

  // Duplicate the handle
  Result := NtxDuplicateHandleFrom(hxProcess.Handle, HandleValue, hxToken);

  if not Result.IsSuccess then
    Exit;

  // Determine the index of the Token object type
  Result := NtxFindType('Token', TokenTypeIndex);

  if not Result.IsSuccess then
    Exit;

  // Determine the type of the object we got
  Result := NtxQueryTypeObject(hxToken.Handle, TypeInfo);

  if not Result.IsSuccess then
    Exit;

  if TypeInfo.Other.TypeIndex <> TokenTypeIndex then
  begin
    // This is not a token
    Result.Location := 'CopyTokenHandle';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end;
end;

function Main: TNtxStatus;
var
  Driver: IAutoReleasable;
  Option: Cardinal;
  hxToken: IHandle;
  ParentId: TLuid;
begin
  writeln('Example program for determining parent token IDs via Kernel Bridge');

  Result := KbxLoadAsDriver(Driver, RtlxExtractPath(ParamStr(0)) + '\' +
    KernelBridgeSys);

  if not Result.IsSuccess then
    Exit;

  write('1 - open process token, 2 - open thread token, 3 - copy handle: ');
  readln(Option);

  case Option of
    1: Result := GetProcessToken(hxToken);
    2: Result := GetThreadToken(hxToken);
    3: Result := CopyTokenHandle(hxToken);
  else
    Result.Location := 'Main';
    Result.Status := STATUS_INVALID_PARAMETER;
  end;

  if not Result.IsSuccess then
    Exit;

  // See the main logic in ParentTokenId.Helper.pas
  Result := QueryParentTokenId(ParentId, hxToken.Handle);

  if not Result.IsSuccess then
    Exit;

  writeln('Parent Token ID = ', IntToHexEx(ParentId, 8));
end;

end.
