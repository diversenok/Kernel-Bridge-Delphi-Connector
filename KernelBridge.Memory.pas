unit KernelBridge.Memory;

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

{ ----------------------------- Physical Memory ----------------------------- }

// Allocate contiguous physical memory in the specified range
function KbxAllocPhysicalMemory(
  out Memory: IMemory;
  LowestAcceptableAddress: Pointer;
  HighestAcceptableAddress: Pointer;
  BoundaryAddressMultiple: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType
): TNtxStatus;

// Map physical memory to the kernel address space;
// to work with it in user-mode, map it with KbxMapMemory
function KbxMapPhysicalMemory(
  out VirtualMemory: IMemory;
  PhysicalMemory: IMemory;
  Size: Cardinal;
  CachingType: TMemoryCachingType
): TNtxStatus;

// Convert a virtual to a physical address in a context of a process
function KbxGetPhysicalAddress(
  out PhysicalAddress: Pointer;
  VirtualAddress: Pointer;
  Process: PEProcess
): TNtxStatus;

// Convery a physica to a virtual address
function KbxGetVirtualForPhysical(
  out VirtualAddress: Pointer;
  PhysicalAddress: Pointer
): TNtxStatus;

// Read content of physical memory into a buffer
function KbxReadPhysicalMemory(
  PhysicalAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType = MmNonCached
): TNtxStatus;

// Write content of a buffer into physical memory
function KbxWritePhysicalMemory(
  PhysicalAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType = MmNonCached
): TNtxStatus;

type
  KbPhysicalMemory = class abstract
    // Read content of physical memory into a buffer
    class function Read<T>(PhysicalAddress: Pointer; out Buffer: T;
      CachingType: TMemoryCachingType = MmNonCached): TNtxStatus; static;

    // Write content of a buffer into physical memory
    class function Write<T>(PhysicalAddress: Pointer; const Buffer: T;
      CachingType: TMemoryCachingType = MmNonCached): TNtxStatus; static;
  end;

implementation

uses
  DelphiUtils.AutoObject;

{ VirtualMemory }

type
  TKbAutoMemory = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

  TKbNonCachedAutoMemory = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

procedure TKbAutoMemory.Release;
begin
  KbFreeKernelMemory(FAddress);
  inherited;
end;

procedure TKbNonCachedAutoMemory.Release;
begin
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

{ Physica Memory }

type
  TKbPhysicalAutoMemory = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

  TKbMappedPhysicalAutoMemory = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

procedure TKbPhysicalAutoMemory.Release;
begin
  KbFreePhysicalMemory(FAddress);
  inherited;
end;

procedure TKbMappedPhysicalAutoMemory.Release;
begin
  KbUnmapPhysicalMemory(FAddress, FSize);
  inherited;
end;


function KbxAllocPhysicalMemory;
var
  Address: Pointer;
begin
  Result.Location := 'KbAllocPhysicalMemory';
  Result.Win32Result := KbAllocPhysicalMemory(LowestAcceptableAddress,
    HighestAcceptableAddress, BoundaryAddressMultiple, Size, CachingType,
    Address);

  if Result.IsSuccess then
    Memory := TKbPhysicalAutoMemory.Capture(Address, Size);
end;

function KbxMapPhysicalMemory;
var
  Address: Pointer;
begin
  Result.Location := 'KbMapPhysicalMemory';
  Result.Win32Result := KbMapPhysicalMemory(PhysicalMemory.Data, Size,
    CachingType, Address);

  if Result.IsSuccess then
    VirtualMemory := TKbMappedPhysicalAutoMemory.Capture(Address, Size);
end;

function KbxGetPhysicalAddress;
begin
  Result.Location := 'KbGetPhysicalAddress';
  Result.Win32Result := KbGetPhysicalAddress(Process, VirtualAddress,
    PhysicalAddress);
end;

function KbxGetVirtualForPhysical;
begin
  Result.Location := 'KbGetVirtualForPhysical';
  Result.Win32Result := KbGetVirtualForPhysical(PhysicalAddress,
    VirtualAddress);
end;

function KbxReadPhysicalMemory;
begin
  Result.Location := 'KbReadPhysicalMemory';
  Result.Win32Result := KbReadPhysicalMemory(PhysicalAddress, Buffer, Size,
    CachingType);
end;

function KbxWritePhysicalMemory;
begin
  Result.Location := 'KbWritePhysicalMemory';
  Result.Win32Result := KbWritePhysicalMemory(PhysicalAddress, Buffer, Size,
    CachingType);
end;

class function KbPhysicalMemory.Read<T>;
begin
  Result := KbxReadPhysicalMemory(PhysicalAddress, @Buffer, SizeOf(Buffer),
    CachingType);
end;

class function KbPhysicalMemory.Write<T>;
begin
  Result := KbxWritePhysicalMemory(PhysicalAddress, @Buffer, SizeOf(Buffer),
    CachingType);
end;

end.
