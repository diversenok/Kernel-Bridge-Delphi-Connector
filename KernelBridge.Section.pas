unit KernelBridge.Section;

interface

uses
  Ntapi.ntdef, Ntapi.ntmmapi, KernelBridgeApi, NtUtils;

// Create a section object
function KbxCreateSection(
  out hxSection: IHandle;
  hFile: THandle;
  MaximumSize: UInt64;
  Name: String = '';
  DesiredAccess: TSectionAccessMask = SECTION_ALL_ACCESS;
  SecPageProtection: Cardinal = PAGE_READWRITE;
  AllocationAttributes: Cardinal = SEC_COMMIT;
  SecObjFlags: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a section object by name
function KbxOpenSection(
  out hxSection: IHandle;
  Name: String;
  DesiredAccess: TSectionAccessMask;
  SecObjFlags: TObjectAttributesFlags = 0
): TNtxStatus;

// Map a section into a memory of a process
function KbxMapViewOfSection(
  out MappedSection: IAutoReleasable;
  hSection: THandle;
  hxProcess: IHandle;
  var BaseAddress: Pointer;
  CommitSize: Cardinal;
  Win32Protect: Cardinal = PAGE_READWRITE;
  ViewSize: PUInt64 = nil;
  SectionOffset: UInt64 = 0;
  AllocationType: Cardinal = MEM_RESERVE;
  SectionInherit: TSectionInherit = ViewUnmap
): TNtxStatus;

// Forsibly unmap a view of a section from process's address space
function KbxUnmapViewOfSection(
  hProcess: THandle;
  BaseAddress: Pointer
): TNtxStatus;

implementation

uses
  KernelBridge, DelphiUtils.AutoObject;

function RefStrOrNil(const S: String): PWideChar;
begin
  if S <> '' then
    Result := PWideChar(S)
  else
    Result := nil;
end;

function KbxCreateSection;
var
  hSection: THandle;
begin
  Result.Location := 'KbCreateSection';
  Result.Win32Result := KbCreateSection(hSection, RefStrOrNil(Name),
    MaximumSize, DesiredAccess, SecObjFlags, SecPageProtection,
    AllocationAttributes, hFile);

  if Result.IsSuccess then
    hxSection := TKbAutoHandle.Capture(hSection);
end;

function KbxOpenSection;
var
  hSection: THandle;
begin
  Result.Location := 'KbOpenSection';
  Result.Win32Result := KbOpenSection(hSection, PWideChar(Name), DesiredAccess,
    SecObjFlags);

  if Result.IsSuccess then
    hxSection := TKbAutoHandle.Capture(hSection);
end;

type
  TKbAutoSection = class (TCustomAutoReleasable, IAutoReleasable)
    FBaseAddress: Pointer;
    FProcess: IHandle;
    procedure Release; override;
    constructor Create(hxProcess: IHandle; BaseAddress: Pointer);
  end;

constructor TKbAutoSection.Create;
begin
  inherited Create;
  FBaseAddress := BaseAddress;
  FProcess := hxProcess;
end;

procedure TKbAutoSection.Release;
begin
  if Assigned(FProcess) then
    KbUnmapViewOfSection(FProcess.Handle, FBaseAddress);

  inherited;
end;

function KbxMapViewOfSection;
begin
  Result.Location := 'KbMapViewOfSection';
  Result.Win32Result := KbMapViewOfSection(hSection, hxProcess.Handle,
    BaseAddress, CommitSize, @SectionOffset, ViewSize, SectionInherit,
    AllocationType, Win32Protect);

  if Result.IsSuccess then
    Result := TKbAutoSection.Create(hxProcess, BaseAddress);
end;

function KbxUnmapViewOfSection;
begin
  Result.Location := 'KbUnmapViewOfSection';
  Result.Win32Result := KbUnmapViewOfSection(hProcess, BaseAddress);
end;

end.
