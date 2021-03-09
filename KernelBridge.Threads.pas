unit KernelBridge.Threads;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, kbapi,
  NtUtils, NtUtils.Threads;

type
  IThreadHandle = interface (IHandle)
    function GetClientId: TClientId;
    property ClientId: TClientId read GetClientId;
  end;

// Determine the address of ETHREAD structure for a thread
function KbxGetEthread(
  out eThread: IMemory;
  ThreadId: TThreadId32
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
  KbxThread = class abstract
    // Query constant-size information for a thread
    class function Query<T>(
      hThread: THandle;
      InfoClass: TThreadInfoClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set constant-size information for a thread
    class function &Set<T>(
      hThread: THandle;
      InfoClass: TThreadInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Create a user-mode thread in a process
function KbxCreateUserThread(
  out Thread: IThreadHandle;
  ProcessId: TProcessId32;
  ThreadRoutine: TUserThreadStartRoutine;
  Argument: Pointer;
  CreateSuspended: Boolean
): TNtxStatus;

// Create a system thread in a process
function KbxCreateSystemThread(
  out Thread: IThreadHandle;
  ProcessId: TProcessId32;
  ThreadRoutine: TUserThreadStartRoutine;
  Argument: Pointer
): TNtxStatus;

// Get a context of a thread
function KbxGetThreadContext(
  ThreadId: TThreadId32;
  out Context: IContext;
  ProcessorMode: TProcessorMode = UserMode
): TNtxStatus;

// Set a context of thread
function KbxSetThreadContext(
  ThreadId: TThreadId32;
  Context: PContext;
  ProcessorMode: TProcessorMode = UserMode
): TNtxStatus;

implementation

uses
  KernelBridge;

function KbxGetEthread;
var
  Address: PEThread;
begin
  Result.Location := 'KbGetEthread';
  Result.Win32Result := KbGetEthread(ThreadId, Address);

  if Result.IsSuccess then
    eThread := TKbAutoObject.Capture(Address, 0);
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

class function KbxThread.Query<T>;
begin
  Result.Location := 'KbQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbQueryInformationThread(hThread, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function KbxThread.&Set<T>;
begin
  Result.Location := 'KbSetInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbSetInformationThread(hThread, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

type
  TKbAutoThread = class (TKbAutoHandle, IThreadHandle)
    FClientId: TClientId;
    function GetClientId: TClientId;
    constructor Capture(hThread: THandle; ClientId: TClientId);
  end;

constructor TKbAutoThread.Capture;
begin
  inherited Capture(hThread);
  FClientId := ClientId;
end;

function TKbAutoThread.GetClientId: TClientId;
begin
  Result := FClientId;
end;

function KbxCreateUserThread;
var
  ClientId: TClientId;
  hThread: THandle;
begin
  Result.Location := 'KbCreateUserThread';
  Result.Win32Result := KbCreateUserThread(ProcessId, ThreadRoutine, Argument,
    CreateSuspended, @ClientId, hThread);

  if Result.IsSuccess then
    Thread := TKbAutoThread.Capture(hThread, ClientId);
end;

function KbxCreateSystemThread;
var
  ClientId: TClientId;
  hThread: THandle;
begin
  Result.Location := 'KbCreateSystemThread';
  Result.Win32Result := KbCreateSystemThread(ProcessId, ThreadRoutine, Argument,
    @ClientId, hThread);

  if Result.IsSuccess then
    Thread := TKbAutoThread.Capture(hThread, ClientId);
end;

function KbxGetThreadContext;
begin
  IMemory(Context) := TAutoMemory.Allocate(SizeOf(TContext));

  Result.Location := 'KbGetThreadContext';
  Result.Win32Result := KbGetThreadContext(ThreadId, Context.Data, Context.Size,
    ProcessorMode);

  if not Result.IsSuccess then
    Context := nil;
end;

function KbxSetThreadContext;
begin
  Result.Location := 'KbSetThreadContext';
  Result.Win32Result := KbSetThreadContext(ThreadId, Context, SizeOf(TContext),
    ProcessorMode);
end;

end.
