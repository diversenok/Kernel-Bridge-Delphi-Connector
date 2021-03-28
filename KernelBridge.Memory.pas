unit KernelBridge.Memory;

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, KernelBridgeApi, NtUtils;

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
  Intersects: Boolean = False
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

type
  KbxMemory = class abstract
    // Copy memory from an address to a buffer
    class function Read<T>(
      Address: Pointer;
      out Buffer: T;
      Intersects: Boolean = False
    ): TNtxStatus; static;

    // Copy memory from a buffer to an address
    class function Write<T>(
      Address: Pointer;
      const Buffer: T;
      Intersects: Boolean = False
    ): TNtxStatus; static;
  end;

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
// to work with it in user-mode, map it with Mdl.KbxMapMemory
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
    class function Read<T>(
      PhysicalAddress: Pointer;
      out Buffer: T;
      CachingType: TMemoryCachingType = MmNonCached
    ): TNtxStatus; static;

    // Write content of a buffer into physical memory
    class function Write<T>(
      PhysicalAddress: Pointer;
      const Buffer: T;
      CachingType: TMemoryCachingType = MmNonCached
    ): TNtxStatus; static;
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

class function KbxMemory.Read<T>;
begin
  Result.Location := 'KbCopyMoveMemory';
  Result.Win32Result := KbCopyMoveMemory(@Buffer, Address, SizeOf(Buffer),
    Intersects);
end;

class function KbxMemory.Write<T>;
begin
  Result.Location := 'KbCopyMoveMemory';
  Result.Win32Result := KbCopyMoveMemory(Address, @Buffer, SizeOf(Buffer),
    Intersects);
end;

{ Physical Memory }

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
