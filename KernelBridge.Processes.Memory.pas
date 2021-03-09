unit KernelBridge.Processes.Memory;

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, kbapi, NtUtils;

// Allocare user-mode memory in a process
function KbxAllocUserMemory(
  out Memory: IMemory;
  ProcessId: TProcessId32;
  Size: Cardinal;
  Protect: Cardinal = PAGE_READWRITE
): TNtxStatus;

// Block attempts to change memory protection
function KbxSecureVirtualMemory(
  out SecureHandle: IAutoReleasable;
  ProcessId: TProcessId32;
  BaseAddress: Pointer;
  Size: Cardinal;
  ProtectRights: Cardinal
): TNtxStatus;

// Read memory from a process
function KbxReadProcessMemory(
  ProcessId: TProcessId32;
  BaseAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal
): TNtxStatus;

// Write memory to a process
function KbxWriteProcessMemory(
  ProcessId: TProcessId32;
  BaseAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal;
  PerformCopyOnWrite: Boolean = True
): TNtxStatus;

type
  KbxProcessMemory = class abstract
    // Read memory from a process
    class function Read<T>(
      ProcessId: TProcessId32;
      BaseAddress: Pointer;
      out Buffer: T
    ): TNtxStatus; static;

    // Write memory to a process
    class function Write<T>(
      ProcessId: TProcessId32;
      BaseAddress: Pointer;
      const Buffer: T;
      PerformCopyOnWrite: Boolean = True
    ): TNtxStatus; static;
  end;

// Trigger Copy-On-Write on a specific page in a process
function KbxTriggerCopyOnWrite(
  ProcessId: TProcessId32;
  PageVirtualAddress: Pointer
): TNtxStatus;

implementation

uses
  DelphiUtils.AutoObject;

type
  TKbAutoUserMemory = class (TCustomAutoMemory, IMemory)
    FProcessId: TProcessId32;
    procedure Release; override;
    constructor Capture(ProcessId: TProcessId32; Address: Pointer;
      Size: NativeUInt);
  end;

  TKbAutoSecureMemory = class (TCustomAutoHandle, IHandle)
    FProcessId: TProcessId32;
    procedure Release; override;
    constructor Capture(ProcessId: TProcessId32; SecureHandle: THandle);
  end;

constructor TKbAutoUserMemory.Capture(ProcessId: TProcessId32; Address: Pointer;
  Size: NativeUInt);
begin
  inherited Capture(Address, Size);
  FProcessId := ProcessId;
end;

procedure TKbAutoUserMemory.Release;
begin
  KbFreeUserMemory(FProcessId, FAddress);
  inherited;
end;

constructor TKbAutoSecureMemory.Capture(ProcessId: TProcessId32;
  SecureHandle: THandle);
begin
  inherited Capture(SecureHandle);
  FProcessId := ProcessId;
end;

procedure TKbAutoSecureMemory.Release;
begin
  KbUnsecureVirtualMemory(FProcessId, FHandle);
  inherited;
end;

function KbxAllocUserMemory;
var
  Address: Pointer;
begin
  Result.Location := 'KbAllocUserMemory';
  Result.Win32Result := KbAllocUserMemory(ProcessId, Protect, Size, Address);

  if Result.IsSuccess then
    Memory := TKbAutoUserMemory.Capture(ProcessId, Address, Size);
end;

function KbxSecureVirtualMemory;
var
  hSecureHandle: THandle;
begin
  Result.Location := 'KbSecureVirtualMemory';
  Result.Win32Result := KbSecureVirtualMemory(ProcessId, BaseAddress, Size,
    ProtectRights, hSecureHandle);

  if Result.IsSuccess then
    SecureHandle := TKbAutoSecureMemory.Capture(ProcessId, hSecureHandle);
end;

function KbxReadProcessMemory;
begin
  Result.Location := 'KbReadProcessMemory';
  Result.Win32Result := KbReadProcessMemory(ProcessId, BaseAddress, Buffer,
    Size);
end;

function KbxWriteProcessMemory;
begin
  Result.Location := 'KbWriteProcessMemory';
  Result.Win32Result := KbWriteProcessMemory(ProcessId, BaseAddress, Buffer,
    Size, PerformCopyOnWrite);
end;

class function KbxProcessMemory.Read<T>;
begin
  Result.Location := 'KbReadProcessMemory';
  Result.Win32Result := KbReadProcessMemory(ProcessId, BaseAddress, @Buffer,
    SizeOf(Buffer));
end;

class function KbxProcessMemory.Write<T>;
begin
  Result.Location := 'KbWriteProcessMemory';
  Result.Win32Result := KbWriteProcessMemory(ProcessId, BaseAddress, Buffer,
    SizeOf(Buffer), PerformCopyOnWrite);
end;

function KbxTriggerCopyOnWrite;
begin
  Result.Location := 'KbTriggerCopyOnWrite';
  Result.Win32Result := KbTriggerCopyOnWrite(ProcessId, PageVirtualAddress);
end;

end.
