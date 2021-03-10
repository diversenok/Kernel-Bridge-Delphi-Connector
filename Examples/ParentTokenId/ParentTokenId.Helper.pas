unit ParentTokenId.Helper;

interface

uses
  Winapi.WinNt, NtUtils;

// Determine the ID of the parent token
function QueryParentTokenId(
  out ParentTokenId: TLuid;
  hToken: THandle
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntseapi, Ntapi.ntpsapi, NtUtils.Tokens,
  NtUtils.Tokens.Query, NtUtils.Objects.Snapshots, KernelBridge.Memory;

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

function QueryParentTokenId;
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

end.
