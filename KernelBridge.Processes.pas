unit KernelBridge.Processes;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, kbapi, NtUtils;

{ ------------------------------- Descriptors ------------------------------- }

// Determine the address of EPROCESS structure for a process
function KbxGetEprocess(
  out eProcess: IMemory;
  ProcessId: TProcessId32
): TNtxStatus;

// Determine the address of ETHREAD structure for a process
function KbxGetEthread(
  out eThread: IMemory;
  ThreadId: TThreadId32
): TNtxStatus;

// Open a process by ID
function KbxOpenProcess(
  out hxProcess: IHandle;
  ProcessId: TProcessId32;
  Access: TProcessAccessMask;
  Attributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a process by a pointer to EPROCESS
function KbxOpenProcessByPointer(
  out hxProcess: IHandle;
  Address: PEProcess;
  Access: TProcessAccessMask;
  Attributes: TObjectAttributesFlags = 0;
  ProcessorMode: TProcessorMode = KernelMode
): TNtxStatus;

// Open a thread by ID
function KbxOpenThread(
  out hxThread: IHandle;
  ThreadId: TProcessId32;
  Access: TThreadAccessMask;
  Attributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a thread by a pointer to ETHREAD
function KbxOpenThreadByPointer(
  out hxThread: IHandle;
  Address: PEThread;
  Access: TThreadAccessMask;
  Attributes: TObjectAttributesFlags = 0;
  ProcessorMode: TProcessorMode = KernelMode
): TNtxStatus;

{ ------------------------------- Information ------------------------------- }

// Query variable-size information for a process
function KbxQueryInformationProcess(
  hProcess: THandle;
  InfoClass: TProcessInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-size information for a process
function KbxSetInformationProcess(
  hProcess: THandle;
  InfoClass: TProcessInfoClass;
  Buffer: Pointer;
  Size: Cardinal
): TNtxStatus;

type
  KbProcess = class abstract
    // Query constant-size information for a process
    class function Query<T>(hProcess: THandle; InfoClass: TProcessInfoClass;
      out Buffer: T): TNtxStatus; static;

    // Set constant-size information for a process
    class function &Set<T>(hProcess: THandle; InfoClass: TProcessInfoClass;
      const Buffer: T): TNtxStatus; static;
  end;

// Query variable-size information for a thread
function KbxQueryInformationThread(
  hThread: THandle;
  InfoClass: TThreadInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-size information for a process
function KbxSetInformationThread(
  hThread: THandle;
  InfoClass: TThreadInfoClass;
  Buffer: Pointer;
  Size: Cardinal
): TNtxStatus;

type
  KbThread = class abstract
    // Query constant-size information for a thread
    class function Query<T>(hThread: THandle; InfoClass: TThreadInfoClass;
      out Buffer: T): TNtxStatus; static;

    // Set constant-size information for a thread
    class function &Set<T>(hThread: THandle; InfoClass: TThreadInfoClass;
      const Buffer: T): TNtxStatus; static;
  end;

implementation

uses
  DelphiUtils.AutoObject;

{ Descriptors }

type
  TKbAutoObject = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

  TKbAutoHandle = class (TCustomAutoHandle, IHandle)
    procedure Release; override;
  end;

procedure TKbAutoObject.Release;
begin
  KbDereferenceObject(FAddress);
  inherited;
end;

procedure TKbAutoHandle.Release;
begin
  KbCloseHandle(FHandle);
  inherited;
end;

function KbxGetEprocess;
var
  Address: PEProcess;
begin
  Result.Location := 'KbGetEprocess';
  Result.Win32Result := KbGetEprocess(ProcessId, Address);

  if Result.IsSuccess then
    eProcess := TKbAutoObject.Capture(Address, 0);
end;

function KbxGetEthread;
var
  Address: PEThread;
begin
  Result.Location := 'KbGetEthread';
  Result.Win32Result := KbGetEthread(ThreadId, Address);

  if Result.IsSuccess then
    eThread := TKbAutoObject.Capture(Address, 0);
end;

function KbxOpenProcess;
var
  hProcess: THandle;
begin
  Result.Location := 'KbOpenProcess';
  Result.LastCall.AttachAccess<TProcessAccessMask>(Access);
  Result.Win32Result := KbOpenProcess(ProcessId, hProcess, Access, Attributes);

  if Result.IsSuccess then
    hxProcess := TKbAutoHandle.Capture(hProcess);
end;

function KbxOpenProcessByPointer;
var
  hProcess: THandle;
begin
  Result.Location := 'KbOpenProcessByPointer';
  Result.LastCall.AttachAccess<TProcessAccessMask>(Access);
  Result.Win32Result := KbOpenProcessByPointer(Address, hProcess, Access,
    Attributes, ProcessorMode);

  if Result.IsSuccess then
    hxProcess := TKbAutoHandle.Capture(hProcess);
end;

function KbxOpenThread;
var
  hThread: THandle;
begin
  Result.Location := 'KbOpenThread';
  Result.LastCall.AttachAccess<TThreadAccessMask>(Access);
  Result.Win32Result := KbOpenThread(ThreadId, hThread, Access, Attributes);

  if Result.IsSuccess then
    hxThread := TKbAutoHandle.Capture(hThread);
end;

function KbxOpenThreadByPointer;
var
  hThread: THandle;
begin
  Result.Location := 'KbOpenThreadByPointer';
  Result.LastCall.AttachAccess<TThreadAccessMask>(Access);
  Result.Win32Result := KbOpenThreadByPointer(Address, hThread, Access,
    Attributes, ProcessorMode);

  if Result.IsSuccess then
    hxThread := TKbAutoHandle.Capture(hThread);
end;

function KbxQueryInformationProcess;
var
  Required: Cardinal;
begin
  Result.Location := 'KbQueryInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := KbQueryInformationProcess(hProcess, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function KbxSetInformationProcess;
begin
  Result.Location := 'KbSetInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbSetInformationProcess(hProcess, InfoClass, Buffer,
    Size);
end;

class function KbProcess.Query<T>;
begin
  Result.Location := 'KbQueryInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbQueryInformationProcess(hProcess, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function KbProcess.&Set<T>;
begin
  Result.Location := 'KbSetInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbSetInformationProcess(hProcess, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

function KbxQueryInformationThread;
var
  Required: Cardinal;
begin
  Result.Location := 'KbQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := KbQueryInformationThread(hThread, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function KbxSetInformationThread;
begin
  Result.Location := 'KbSetInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbSetInformationThread(hThread, InfoClass, Buffer,
    Size);
end;

{ KbThread }

class function KbThread.Query<T>;
begin
  Result.Location := 'KbQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbQueryInformationThread(hThread, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function KbThread.&Set<T>;
begin
  Result.Location := 'KbSetInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbSetInformationThread(hThread, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

end.
