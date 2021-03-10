unit KernelBridge.Memory.Mdl;

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, KernelBridgeApi, NtUtils;

type
  IMdl = interface (IAutoReleasable)
    function GetMdl: Pointer;
    property Mdl: Pointer read GetMdl;
  end;

  IMappedMdl = interface (IMemory)
    function GetMdl: Pointer;
    property Mdl: Pointer read GetMdl;
  end;

// Allocate a Memory Descriptor List for the specified memory region
function KbxAllocateMdl(
  out Mdl: IMdl;
  VirtualAddress: Pointer;
  Size: Cardinal
): TNtxStatus;

// Probe and lock pages from a Memory Descriptor List
function KbxProbeAndLockPages(
  out Lock: IAutoReleasable;
  ProcessId: TProcessId32;
  Mdl: IMdl;
  LockOperation: TLockOperation;
  ProcessorMode: TProcessorMode
): TNtxStatus;

// Map a Memory Descriptor List into a process
function KbxMapMdl(
  out MappedMemory: IMappedMdl;
  SrcProcessId: TProcessId;
  DestProcessId: TProcessId;
  Mdl: IMdl;
  NeedProbeAndLock: Boolean;
  MapToAddressSpace: TProcessorMode = UserMode;
  Protect: Cardinal = PAGE_READWRITE;
  CacheType: TMemoryCachingType = MmNonCached;
  UserRequestedAddress: Pointer = nil
): TNtxStatus;

// Protect memory mapped for a Memory Descriptor List
function KbxProtectMappedMemory(
  Mdl: PMdl;
  Protect: Cardinal
): TNtxStatus;

// Map memory into a process throught a Memory Descriptor List
function KbxMapMemory(
  out MappingMemory: IMappedMdl;
  SrcProcessId: TProcessId;
  DestProcessId: TProcessId;
  VirtualAddress: Pointer;
  Size: Cardinal;
  MapToAddressSpace: TProcessorMode = UserMode;
  Protect: Cardinal = PAGE_READWRITE;
  CacheType: TMemoryCachingType = MmNonCached;
  UserRequestedAddress: Pointer = nil
): TNtxStatus;

implementation

uses
  DelphiUtils.AutoObject;

type
  TKbAutoMdl = class (TCustomAutoReleasable, IMdl)
    FMdl: Pointer;
    function GetMdl: Pointer;
    constructor Capture(pMdl: Pointer);
    procedure Release; override;
  end;

  TKbAutoMdlLock = class (TCustomAutoReleasable, IAutoReleasable)
    FMdl: IMdl;
    constructor Create(Mdl: IMdl);
    procedure Release; override;
  end;

  TKbMappedAutoMdl = class (TCustomAutoMemory, IMappedMdl)
    FMdl: IMdl;
    FNeedUnlock: Boolean;
    function GetMdl: Pointer;
    constructor Capture(Mdl: IMdl; MappedAddress: Pointer; NeedUnlock: Boolean);
    procedure Release; override;
  end;

  TKbMappedAutoMemory = class (TCustomAutoMemory, IMappedMdl)
    FMdl: PMdl;
    function GetMdl: Pointer;
    constructor Capture(MappingInfo: TMappingInfo);
    procedure Release; override;
  end;

constructor TKbAutoMdl.Capture;
begin
  inherited Create;
  FMdl := pMdl;
end;

procedure TKbAutoMdl.Release;
begin
  KbFreeMdl(FMdl);
  inherited;
end;

function TKbAutoMdl.GetMdl;
begin
  Result := FMdl;
end;

constructor TKbAutoMdlLock.Create;
begin
  inherited Create;
  FMdl := Mdl;
end;

procedure TKbAutoMdlLock.Release;
begin
  KbUnlockPages(FMdl.Mdl);
  inherited;
end;

constructor TKbMappedAutoMdl.Capture;
begin
  inherited Capture(MappedAddress, 0);
  FMdl := Mdl;
  FNeedUnlock := NeedUnlock;
end;

procedure TKbMappedAutoMdl.Release;
begin
  KbUnmapMdl(FMdl.Mdl, FAddress, FNeedUnlock);
  inherited;
end;

function TKbMappedAutoMdl.GetMdl;
begin
  Result := FMdl;
end;

constructor TKbMappedAutoMemory.Capture;
begin
  inherited Capture(MappingInfo.MappedAddress, 0);
  FMdl := MappingInfo.Mdl;
end;

procedure TKbMappedAutoMemory.Release;
var
  MappingInfo: TMappingInfo;
begin
  MappingInfo.MappedAddress := FAddress;
  MappingInfo.Mdl := FMdl;
  KbUnmapMemory(MappingInfo);
  inherited;
end;

function TKbMappedAutoMemory.GetMdl: Pointer;
begin
  Result := FMdl;
end;

function KbxAllocateMdl;
var
  pMdl: Pointer;
begin
  Result.Location := 'KbAllocateMdl';
  Result.Win32Result := KbAllocateMdl(VirtualAddress, Size, pMdl);

  if Result.IsSuccess then
    Mdl := TKbAutoMdl.Capture(pMdl);
end;

function KbxProbeAndLockPages;
begin
  Result.Location := 'KbProbeAndLockPages';
  Result.Win32Result := KbProbeAndLockPages(ProcessId, Mdl.Mdl, ProcessorMode,
    LockOperation);

  if Result.IsSuccess then
    Lock := TKbAutoMdlLock.Create(Mdl);
end;

function KbxMapMdl;
var
  Address: Pointer;
begin
  Result.Location := 'KbMapMdl';
  Result.Win32Result := KbMapMdl(Address, SrcProcessId, DestProcessId,
    Mdl, NeedProbeAndLock, MapToAddressSpace, Protect, CacheType,
    UserRequestedAddress);

  if Result.IsSuccess then
    MappedMemory := TKbMappedAutoMdl.Capture(Mdl, Address, NeedProbeAndLock);
end;

function KbxProtectMappedMemory;
begin
  Result.Location := 'KbProtectMappedMemory';
  Result.Win32Result := KbProtectMappedMemory(Mdl, Protect);
end;

function KbxMapMemory;
var
  MappingInfo: TMappingInfo;
begin
  Result.Location := 'KbMapMemory';
  Result.Win32Result := KbMapMemory(MappingInfo, SrcProcessId, DestProcessId,
    VirtualAddress, Size, MapToAddressSpace, Protect, CacheType,
    UserRequestedAddress);

  if Result.IsSuccess then
    MappingMemory := TKbMappedAutoMemory.Capture(MappingInfo);
end;

end.
