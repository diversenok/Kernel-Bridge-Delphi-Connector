unit KernelBridge.Processes;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, kbapi, NtUtils;

// Determine the address of EPROCESS structure for a process
function KbxGetEprocess(
  out eProcess: IMemory;
  ProcessId: TProcessId32
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
  KbxProcess = class abstract
    // Query constant-size information for a process
    class function Query<T>(
      hProcess: THandle;
      InfoClass: TProcessInfoClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set constant-size information for a process
    class function &Set<T>(
      hProcess: THandle;
      InfoClass: TProcessInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Suspend all threads in a process
function KbxSuspendProcess(
  ProcessId: TProcessId32
): TNtxStatus;

// Resume all threads in a process
function KbxResumeProcess(
  ProcessId: TProcessId32
): TNtxStatus;

implementation

uses
  KernelBridge, DelphiUtils.AutoObject;

function KbxGetEprocess;
var
  Address: PEProcess;
begin
  Result.Location := 'KbGetEprocess';
  Result.Win32Result := KbGetEprocess(ProcessId, Address);

  if Result.IsSuccess then
    eProcess := TKbAutoObject.Capture(Address, 0);
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

class function KbxProcess.Query<T>;
begin
  Result.Location := 'KbQueryInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbQueryInformationProcess(hProcess, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function KbxProcess.&Set<T>;
begin
  Result.Location := 'KbSetInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := KbSetInformationProcess(hProcess, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

function KbxSuspendProcess;
begin
  Result.Location := 'KbSuspendProcess';
  Result.Win32Result := KbSuspendProcess(ProcessId);
end;

function KbxResumeProcess;
begin
  Result.Location := 'KbResumeProcess';
  Result.Win32Result := KbResumeProcess(ProcessId);
end;

end.
