program ParentTokenId;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.WinNt,
  Ntapi.ntstatus,
  Ntapi.ntpsapi,
  Ntapi.ntseapi,
  NtUtils,
  NtUtils.Tokens,
  NtUtils.Tokens.Query,
  NtUtils.Objects,
  NtUtils.Objects.Snapshots,
  NtUtils.SysUtils,
  DelphiUiLib.Strings,
  NtUiLib.Errors,
  KernelBridgeApi,
  KernelBridge,
  KernelBridge.Processes,
  KernelBridge.Threads,
  KernelBridge.Memory;

// Determine the kernel address of an object's body
function GetObjectAddress(
  hObject: THandle;
  out Address: Pointer
): TNtxStatus;
var
  Handles: TArray<TSystemHandleEntry>;
  HandleEntry: TSystemHandleEntry;
begin
  // Snapshot all handles on the system
  Result := NtxEnumerateHandles(Handles);

  if not Result.IsSuccess then
    Exit;

  // Find the entry for the specified handle
  Result := NtxFindHandleEntry(Handles, NtCurrentProcessId, hObject,
    HandleEntry);

  if Result.IsSuccess then
    Address := HandleEntry.PObject;
end;

// Determine the offset of the ParentTokenId field in KTOKEN
function GetParentTokenIdOffset(out Offset: Cardinal): TNtxStatus;
var
  Statistics: TTokenStatistics;
  hxToken: IHandle;
  Address: Pointer;
  Buffer: array [0..63] of Cardinal;
  i: Integer;
begin
  // Figure out our token's ID
  Result := NtxToken.Query(NtCurrentProcessToken, TokenStatistics, Statistics);

  if not Result.IsSuccess then
    Exit;

  // Create a child token with a known parent
  Result := NtxFilterToken(hxToken, NtCurrentProcessToken, 0);

  if not Result.IsSuccess then
    Exit;

  // Determine the address of the object in kernel memory
  Result := GetObjectAddress(hxToken.Handle, Address);

  if not Result.IsSuccess then
    Exit;

  // Read the beggining of the structure
  Result := KbxMemory.Read(Address, Buffer);

  if not Result.IsSuccess then
    Exit;

  // Search for the offset with a matching value
  for i := 0 to Pred(High(Buffer)) do
    if PLuid(@Buffer[i])^ = Statistics.TokenId then
    begin
      Offset := i * SizeOf(Cardinal);
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

  Result.Location := 'GetParentTokenIdOffset';
  Result.Status := STATUS_NOT_FOUND;
end;

// Read the ID of the parent token from kernel memory
function QueryParentTokenId(
  out ParentTokenId: TLuid;
  hToken: THandle
): TNtxStatus;
var
  Address: Pointer;
  Offset: Cardinal;
begin
  // Determine the address of the kernel object
  Result := GetObjectAddress(hToken, Address);

  if not Result.IsSuccess then
    Exit;

  // Determine the offset for the Parent Token ID field
  Result := GetParentTokenIdOffset(Offset);

  if not Result.IsSuccess then
    Exit;

  // Read its content
  Result := KbxMemory.Read(PByte(Address) + Offset, ParentTokenId);
end;

// Ask a user for a process ID and open its token
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

// Ask a user for a thread ID and open its token
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

// Copy a token handle from a process
function CopyTokenFrom(out hxToken: IHandle): TNtxStatus;
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
    Result.Location := 'CopyTokenFrom';
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
    3: Result := CopyTokenFrom(hxToken);
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
