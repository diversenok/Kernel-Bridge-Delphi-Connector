unit KernelBridge.Memory;

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, kbapi, NtUtils;

type
  IMdl = interface (IAutoReleasable)
    function GetMdl: Pointer;
    property Mdl: Pointer read GetMdl;
  end;

  IMappedMdl = interface (IMemory)
    function GetMdl: Pointer;
    property Mdl: Pointer read GetMdl;
  end;

{ ------------------------------ VirtualMemory ------------------------------ }

// Allocate memory in the kernel space
function KbxAllocKernelMemory(
  out Memory: IMemory;
  Size: Cardinal;
  Executable: Boolean = False
): TNtxStatus;

// Allocate non-cached memory in the kernel space
function KbxAllocNonCachedMemory(
  out Memory: IMemory;
  Size: Cardinal
): TNtxStatus;

// Copy user- or kernel- memory in the context of current process
function KbxCopyMoveMemory(
  Dest: Pointer;
  Src: Pointer;
  Size: Cardinal;
  Intersects: Boolean
): TNtxStatus;

// Fill user- or kernel- memory in the context of current process
function KbxFillMemory(
  Address: Pointer;
  Filler: Byte;
  Size: Cardinal
): TNtxStatus;

// Compare user- or kernel- memory in the context of the current process
function KbxEqualMemory(
  Src: Pointer;
  Dest: Pointer;
  Size: Cardinal;
  out Equals: Boolean
): TNtxStatus;

{ ----------------------------------- Mdl ----------------------------------- }

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

{ VirtualMemory }

type
  TKbAutoMemory = class (TCustomAutoMemory, IMemory)
    destructor Destroy; override;
  end;

  TKbNonCachedAutoMemory = class (TCustomAutoMemory, IMemory)
    destructor Destroy; override;
  end;

destructor TKbAutoMemory.Destroy;
begin
  if FAutoRelease then
    KbFreeKernelMemory(FAddress);

  inherited;
end;

destructor TKbNonCachedAutoMemory.Destroy;
begin
  if FAutoRelease then
    KbFreeNonCachedMemory(FAddress, FSize);

  inherited;
end;

function KbxAllocKernelMemory;
var
  Address: Pointer;
begin
  Result.Location := 'KbAllocKernelMemory';
  Result.Win32Result := KbAllocKernelMemory(Size, Executable, Address);

  if Result.IsSuccess then
    Memory := TKbAutoMemory.Capture(Address, Size);
end;

function KbxAllocNonCachedMemory;
var
  Address: Pointer;
begin
  Result.Location := 'KbAllocNonCachedMemory';
  Result.Win32Result := KbAllocNonCachedMemory(Size, Address);

  if Result.IsSuccess then
    Memory := TKbNonCachedAutoMemory.Capture(Address, Size);
end;

function KbxCopyMoveMemory;
begin
  Result.Location := 'KbCopyMoveMemory';
  Result.Win32Result := KbCopyMoveMemory(Dest, Src, Size, Intersects);
end;

function KbxFillMemory;
begin
  Result.Location := 'KbFillMemory';
  Result.Win32Result := KbFillMemory(Address, Filler, Size)
end;

function KbxEqualMemory;
begin
  Result.Location := 'KbEqualMemory';
  Result.Win32Result := KbEqualMemory(Src, Dest, Size, Equals);
end;

{ Mdl }

type
  TKbAutoMdl = class (TCustomAutoReleasable, IMdl)
    FMdl: Pointer;
    function GetMdl: Pointer;
    constructor Capture(pMdl: Pointer);
    destructor Destroy; override;
  end;

  TKbAutoMdlLock = class (TCustomAutoReleasable, IAutoReleasable)
    FMdl: IMdl;
    constructor Create(Mdl: IMdl);
    destructor Destroy; override;
  end;

  TKbMappedAutoMdl = class (TCustomAutoMemory, IMappedMdl)
    FMdl: IMdl;
    FNeedUnlock: Boolean;
    function GetMdl: Pointer;
    constructor Capture(Mdl: IMdl; MappedAddress: Pointer; NeedUnlock: Boolean);
    destructor Destroy; override;
  end;

  TKbMappedAutoMemory = class (TCustomAutoMemory, IMappedMdl)
    FMdl: PMdl;
    function GetMdl: Pointer;
    constructor Capture(MappingInfo: TMappingInfo);
    destructor Destroy; override;
  end;

constructor TKbAutoMdl.Capture;
begin
  inherited Create;
  FMdl := pMdl;
end;

destructor TKbAutoMdl.Destroy;
begin
  if FAutoRelease then
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

destructor TKbAutoMdlLock.Destroy;
begin
  if FAutoRelease then
    KbUnlockPages(FMdl.Mdl);

  inherited;
end;

constructor TKbMappedAutoMdl.Capture;
begin
  inherited Capture(MappedAddress, 0);
  FMdl := Mdl;
  FNeedUnlock := NeedUnlock;
end;

destructor TKbMappedAutoMdl.Destroy;
begin
  if FAutoRelease then
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

destructor TKbMappedAutoMemory.Destroy;
var
  MappingInfo: TMappingInfo;
begin
  if FAutoRelease then
  begin
    MappingInfo.MappedAddress := FAddress;
    MappingInfo.Mdl := FMdl;
    KbUnmapMemory(MappingInfo)
  end;

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
