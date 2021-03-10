unit KernelBridgeApi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, Ntapi.ntmmapi,
  DelphiApi.Reflection;

const
  kernelbridgesys = 'Kernel-Bridge.sys';
  userbridge = 'User-Bridge.dll';

type
  TCpuidInfo = record
    Eax: Cardinal;
    Ebx: Cardinal;
    Ecx: Cardinal;
    Edx: Cardinal;
  end;
  PCpuidInfo = ^TCpuidInfo;

  PMdl = Pointer;
  PEProcess = Pointer;
  PEThread = Pointer;

  {$MINENUMSIZE 1}
  [NamingStyle(nsCamelCase)]
  TProcessorMode = (
    KernelMode = 0,
    UserMode = 1
  );
  {$MINENUMSIZE 4}

  [NamingStyle(nsCamelCase, 'Io', 'Access')]
  TLockOperation = (
    IoReadAccess = 0,
    IoWriteAccess = 1,
    IoModifyAccess = 2
  );

  TMemoryCachingType = (
    MmNonCached = 0,
    MmCached = 1,
    MmWriteCombined = 2,
    MmHardwareCoherentCached = 3,
    MmNonCachedUnordered = 4,
    MmUSWCCached = 5,
    MmMaximumCacheType = 6,
    MmNotMapped = -1
  );

  TMappingInfo = record
    MappedAddress: Pointer;
    Mdl: PMdl;
  end;
  PMappingInfo = ^TMappingInfo;

  TUserApcProc = procedure (Argument: Pointer); stdcall;

  // You can obtain any function address from ntoskrnl.exe/hal.dll
  TGetKernelProcAddress = function (RoutineName: PWideChar): Pointer; stdcall;

  TShellCode = function (
    GetKernelProcAddress: TGetKernelProcAddress;
    Argument: Pointer
  ): NTSTATUS; stdcall;

  [NamingStyle(nsCamelCase, 'KbLdr')]
  TKbLdrStatus = (
    KbLdrSuccess,
    KbLdrImportNotResolved,
    KbLdrOrdinalImportNotSupported,
    KbLdrKernelMemoryNotAllocated,
    KbLdrTransitionFailure,
    KbLdrCreationFailure
  );

{ KbLoader }

function KbLoadAsDriver(
  DriverPath: PWideChar
): LongBool; stdcall; external userbridge;

function KbLoadAsFilter(
  DriverPath: PWideChar;
  Altitude: PWideChar
): LongBool; stdcall; external userbridge;

function KbUnload: LongBool; stdcall; external userbridge;

function KbGetDriverApiVersion: Cardinal; stdcall; external userbridge;

function KbGetUserApiVersion: Cardinal; stdcall; external userbridge;

function KbGetHandlesCount(
  out Count: Cardinal
): LongBool; stdcall; external userbridge;

{ IO.Beeper }

function KbSetBeeperRegime: LongBool; stdcall; external userbridge;
function KbStartBeeper: LongBool; stdcall; external userbridge;
function KbStopBeeper: LongBool; stdcall; external userbridge;
function KbSetBeeperIn: LongBool; stdcall; external userbridge;
function KbSetBeeperOut: LongBool; stdcall; external userbridge;

function KbSetBeeperDivider(
  Divider: Word
): LongBool; stdcall; external userbridge;

function KbSetBeeperFrequency(
  Frequency: Word
): LongBool; stdcall; external userbridge;

{ IO.RW }

function KbReadPortByte(
  PortNumber: Word;
  out Value: Byte
): LongBool; stdcall; external userbridge;

function KbReadPortWord(
  PortNumber: Word;
  out Value: Word
): LongBool; stdcall; external userbridge;

function KbReadPortDword(
  PortNumber: Word;
  out Value: Cardinal
): LongBool; stdcall; external userbridge;

function KbReadPortByteString(
  PortNumber: Word;
  Count: Cardinal;
  ByteString: PByte;
  ByteStringSizeInBytes: Cardinal
): LongBool; stdcall; external userbridge;

function KbReadPortWordString(
  PortNumber: Word;
  Count: Cardinal;
  ByteString: PWord;
  WordStringSizeInBytes: Cardinal
): LongBool; stdcall; external userbridge;

function KbReadPortDwordString(
  PortNumber: Word;
  Count: Cardinal;
  DwordString: PCardinal;
  DwordStringSizeInBytes: Cardinal
): LongBool; stdcall; external userbridge;

function KbWritePortByte(
  PortNumber: Word;
  Value: Byte
): LongBool; stdcall; external userbridge;

function KbWritePortWord(
  PortNumber: Word;
  Value: Word
): LongBool; stdcall; external userbridge;

function KbWritePortDword(
  PortNumber: Word;
  Value: Cardinal
): LongBool; stdcall; external userbridge;

function KbWritePortByteString(
  PortNumber: Word;
  Count: Cardinal;
  ByteString: PByte;
  ByteStringSizeInBytes: Cardinal
): LongBool; stdcall; external userbridge;

function KbWritePortWordString(
  PortNumber: Word;
  Count: Cardinal;
  WordString: PWord;
  WordStringSizeInBytes: Cardinal
): LongBool; stdcall; external userbridge;

function KbWritePortDwordString(
  PortNumber: Word;
  Count: Cardinal;
  DwordString: PCardinal;
  DwordStringSizeInBytes: Cardinal
): LongBool; stdcall; external userbridge;

{ IO.Iopl }

// Allows to use 'in/out/cli/sti' in usermode
function KbRaiseIopl: LongBool; stdcall; external userbridge;
function KbResetIopl: LongBool; stdcall; external userbridge;

{ CPU }

function KbCli: LongBool; stdcall; external userbridge;
function KbSti: LongBool; stdcall; external userbridge;
function KbHlt: LongBool; stdcall; external userbridge;

function KbReadMsr(
  Index: Cardinal;
  out MsrValue: UInt64
): LongBool; stdcall; external userbridge;

function KbWriteMsr(
  Index: Cardinal;
  MsrValue: UInt64
): LongBool; stdcall; external userbridge;

function KbCpuid(
  FunctionIdEax: Cardinal;
  out CpuidInfo: TCpuidInfo
): LongBool; stdcall; external userbridge;

function KbCpuidEx(
  FunctionIdEax: Cardinal;
  SubfunctionIdEcx: Cardinal;
  out CpuidInfo: TCpuidInfo
): LongBool; stdcall; external userbridge;

function KbReadPmc(
  Counter: Cardinal;
  out PmcValue: UInt64
): LongBool; stdcall; external userbridge;

function KbReadTsc(
  out TscValue: UInt64
): LongBool; stdcall; external userbridge;

function KbReadTscp(
  out TscValue: UInt64;
  out TscAux: Cardinal
): LongBool; stdcall; external userbridge;

{ VirtualMemory }

// Supports both user- and kernel-memory in context of current process

function KbAllocKernelMemory(
  Size: Cardinal;
  Executable: Boolean;
  out KernelAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbFreeKernelMemory(
  KernelAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbAllocNonCachedMemory(
  Size: Cardinal;
  out KernelAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbFreeNonCachedMemory(
  KernelAddress: Pointer;
  Size: Cardinal
): LongBool; stdcall; external userbridge;

function KbCopyMoveMemory(
  Dest: Pointer;
  Src: Pointer;
  Size: Cardinal;
  Intersects: Boolean
): LongBool; stdcall; external userbridge;

function KbFillMemory(
  Address: Pointer;
  Filler: Byte;
  Size: Cardinal
): LongBool; stdcall; external userbridge;

function KbEqualMemory(
  Src: Pointer;
  Dest: Pointer;
  Size: Cardinal;
  out Equals: Boolean
): LongBool; stdcall; external userbridge;

{ Mdl }

function KbAllocateMdl(
  VirtualAddress: Pointer;
  Size: Cardinal;
  out Mdl: PMdl
): LongBool; stdcall; external userbridge;

function KbProbeAndLockPages(
  ProcessId: TProcessId32;
  Mdl: PMdl;
  ProcessorMode: TProcessorMode;
  LockOperation: TLockOperation
): LongBool; stdcall; external userbridge;

function KbMapMdl(
  out MappedMemory: Pointer;
  SrcProcessId: TProcessId;
  DestProcessId: TProcessId;
  Mdl: PMdl;
  NeedProbeAndLock: Boolean;
  MapToAddressSpace: TProcessorMode = UserMode;
  Protect: Cardinal = PAGE_READWRITE;
  CacheType: TMemoryCachingType = MmNonCached;
  UserRequestedAddress: Pointer = nil
): LongBool; stdcall; external userbridge;

function KbProtectMappedMemory(
  Mdl: PMdl;
  Protect: Cardinal
): LongBool; stdcall; external userbridge;

function KbUnmapMdl(
  Mdl: PMdl;
  MappedMemory: Pointer;
  NeedUnlock: Boolean
): LongBool; stdcall; external userbridge;

function KbUnlockPages(
  Mdl: PMdl
): LongBool; stdcall; external userbridge;

function KbFreeMdl(
  Mdl: PMdl
): LongBool; stdcall; external userbridge;

function KbMapMemory(
  out MappingInfo: TMappingInfo;
  SrcProcessId: TProcessId;
  DestProcessId: TProcessId;
  VirtualAddress: Pointer;
  Size: Cardinal;
  MapToAddressSpace: TProcessorMode = UserMode;
  Protect: Cardinal = PAGE_READWRITE;
  CacheType: TMemoryCachingType = MmNonCached;
  UserRequestedAddress: Pointer = nil
): LongBool; stdcall; external userbridge;

function KbUnmapMemory(
  const MappingInfo: TMappingInfo
): LongBool; stdcall; external userbridge;

{ PhysicalMemory }

// Allocates contiguous physical memory in the specified range
function KbAllocPhysicalMemory(
  LowestAcceptableAddress: Pointer;
  HighestAcceptableAddress: Pointer;
  BoundaryAddressMultiple: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType;
  out Address: Pointer
): LongBool; stdcall; external userbridge;

// Maps physical memory to a KERNEL address-space; to work with it in usermode,
// map it to usermode by KbMapMemory
function KbFreePhysicalMemory(
  Address: Pointer
): LongBool; stdcall; external userbridge;

// Maps physical memory to a KERNEL address-space; to work with it in usermode,
// you should map it to usermode by KbMapMemory
function KbMapPhysicalMemory(
  PhysicalAddress: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType;
  out VirtualAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbUnmapPhysicalMemory(
  VirtualAddress: Pointer;
  Size: Cardinal
): LongBool; stdcall; external userbridge;

// Obtains physical address for specified virtual address in context of target
function KbGetPhysicalAddress(
  Process: PEProcess;
  VirtualAddress: Pointer;
  out PhysicalAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbGetVirtualForPhysical(
  PhysicalAddress: Pointer;
  out VirtualAddress: Pointer
): LongBool; stdcall; external userbridge;

// Reads and writes raw physical memory to buffer in context of current process
function KbReadPhysicalMemory(
  PhysicalAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType = MmNonCached
): LongBool; stdcall; external userbridge;

function KbWritePhysicalMemory(
  PhysicalAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal;
  CachingType: TMemoryCachingType = MmNonCached
): LongBool; stdcall; external userbridge;

function KbReadDmiMemory(
  DmiMemory: Pointer;
  BufferSize: Cardinal
): LongBool; stdcall; external userbridge;

{ Processes.Descriptors }

function KbGetEprocess(
  ProcessId: TProcessId32;
  out Process: PEProcess // dereferece with KbDereferenceObject
): LongBool; stdcall; external userbridge;

function KbGetEthread(
  ThreadId: TThreadId32;
  out Thread: PEThread // dereferece with KbDereferenceObject
): LongBool; stdcall; external userbridge;

function KbOpenProcess(
  ProcessId: Cardinal;
  out hProcess: THandle; // close with KbCloseHandle
  Access: TProcessAccessMask = PROCESS_ALL_ACCESS;
  Attributes: TObjectAttributesFlags = OBJ_KERNEL_HANDLE
): LongBool; stdcall; external userbridge;

function KbOpenProcessByPointer(
  Process: PEProcess;
  out hProcess: THandle;
  Access: TProcessAccessMask = PROCESS_ALL_ACCESS;
  Attributes: TObjectAttributesFlags = OBJ_KERNEL_HANDLE;
  ProcessorMode: TProcessorMode = KernelMode
): LongBool; stdcall; external userbridge;

function KbOpenThread(
  ThreadId: TThreadId32;
  out hThread: THandle; // close with KbCloseHandle
  Access: TThreadAccessMask = THREAD_ALL_ACCESS;
  Attributes: TObjectAttributesFlags = OBJ_KERNEL_HANDLE
): LongBool; stdcall; external userbridge;

function KbOpenThreadByPointer(
  Thread: PEThread;
  out hThread: THandle;
  Access: TThreadAccessMask = THREAD_ALL_ACCESS;
  Attributes: TObjectAttributesFlags = OBJ_KERNEL_HANDLE;
  ProcessorMode: TProcessorMode = KernelMode
): LongBool; stdcall; external userbridge;

function KbDereferenceObject(
  pObject: Pointer
): LongBool; stdcall; external userbridge;

function KbCloseHandle(
  Handle: THandle
): LongBool; stdcall; external userbridge;

{ Processes.Information }

function KbQueryInformationProcess(
  hProcess: THandle;
  ProcessInfoClass: TProcessInfoClass;
  Buffer: Pointer;
  Size: Cardinal;
  ReturnLength: PCardinal
): LongBool; stdcall; external userbridge;

function KbSetInformationProcess(
  hProcess: THandle;
  ProcessInfoClass: TProcessInfoClass;
  Buffer: Pointer;
  Size: Cardinal
): LongBool; stdcall; external userbridge;

function KbQueryInformationThread(
  hThread: THandle;
  ThreadInfoClass: TThreadInfoClass;
  Buffer: Pointer;
  Size: Cardinal;
  ReturnLength: PCardinal
): LongBool; stdcall; external userbridge;

function KbSetInformationThread(
  hThread: THandle;
  ThreadInfoClass: TThreadInfoClass;
  Buffer: Pointer;
  Size: Cardinal
): LongBool; stdcall; external userbridge;

{ Processes.Threads }

function KbCreateUserThread(
  ProcessId: TProcessId32;
  ThreadRoutine: TUserThreadStartRoutine;
  Argument: Pointer;
  CreateSuspended: LongBool;
  ClientId: PClientId;
  out hThread: THandle
): LongBool; stdcall; external userbridge;

function KbCreateSystemThread(
  ProcessId: TProcessId32;
  ThreadRoutine: TUserThreadStartRoutine;
  Argument: Pointer;
  ClientId: PClientId;
  out hThread: THandle
): LongBool; stdcall; external userbridge;

function KbSuspendProcess(
  ProcessId: TProcessId32
): LongBool; stdcall; external userbridge;

function KbResumeProcess(
  ProcessId: TProcessId32
): LongBool; stdcall; external userbridge;

function KbGetThreadContext(
  ThreadId: TThreadId32;
  Context: PContext;
  ContextSize: Cardinal;
  ProcessorMode: TProcessorMode = UserMode
): LongBool; stdcall; external userbridge;

function KbSetThreadContext(
  ThreadId: TThreadId32;
  Context: PContext;
  ContextSize: Cardinal;
  ProcessorMode: TProcessorMode = UserMode
): LongBool; stdcall; external userbridge;

{ Processes.MemoryManagement }

function KbAllocUserMemory(
  ProcessId: TProcessId32;
  Protect: Cardinal;
  Size: Cardinal;
  out BaseAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbFreeUserMemory(
  ProcessId: TProcessId32;
  BaseAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbSecureVirtualMemory(
  ProcessId: TProcessId32;
  BaseAddress: Pointer;
  Size: Cardinal;
  ProtectRights: Cardinal;
  out SecureHandle: THandle
): LongBool; stdcall; external userbridge;

function KbUnsecureVirtualMemory(
  ProcessId: TProcessId32;
  SecureHandle: THandle
): LongBool; stdcall; external userbridge;

function KbReadProcessMemory(
  ProcessId: TProcessId32;
  BaseAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal
): LongBool; stdcall; external userbridge;

function KbWriteProcessMemory(
  ProcessId: TProcessId32;
  BaseAddress: Pointer;
  Buffer: Pointer;
  Size: Cardinal;
  PerformCopyOnWrite: Boolean = True
): LongBool; stdcall; external userbridge;

function KbTriggerCopyOnWrite(
  ProcessId: TProcessId32;
  PageVirtualAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbGetProcessCr3Cr4(
  ProcessId: TProcessId32;
  Cr3: PUInt64;
  Cr4: PUInt64
): LongBool; stdcall; external userbridge;

{ Processes.Apc }

function KbQueueUserApc(
  ThreadId: TThreadId32;
  ApcProc: TUserApcProc;
  Argument: Pointer
): LongBool; stdcall; external userbridge;

{ Sections }

function KbCreateSection(
  out hSection: THandle;
  Name: PWideChar;
  MaximumSize: UInt64;
  DesiredAccess: TSectionAccessMask;
  SecObjFlags: TObjectAttributesFlags;
  SecPageProtection: Cardinal; // SEC_***
  AllocationAttributes: Cardinal;
  hFile: THandle
): LongBool; stdcall; external userbridge;

function KbOpenSection(
  out hSection: THandle;
  Name: PWideChar;
  DesiredAccess: TSectionAccessMask;
  SecObjFlags: TObjectAttributesFlags
): LongBool; stdcall; external userbridge;

function KbMapViewOfSection(
  hSection: THandle;
  hProcess: THandle;
  var BaseAddress: Pointer;
  CommitSize: Cardinal;
  SectionOffset: PUInt64 = nil;
  ViewSize: PUInt64 = nil;
  SectionInherit: TSectionInherit = ViewUnmap;
  AllocationType: Cardinal = MEM_RESERVE;
  Win32Protect: Cardinal = PAGE_READWRITE
): LongBool; stdcall; external userbridge;

function KbUnmapViewOfSection(
  hProcess: THandle;
  BaseAddress: Pointer
): LongBool; stdcall; external userbridge;

{ KernelShells }

// Execute the specified function in Ring0 in a SEH-section with a FPU-safe
// context in the context of the current process
function KbExecuteShellCode(
  ShellCode: TShellCode;
  Argument: Pointer;
  out Result: NTSTATUS
): LongBool; stdcall; external userbridge;

{ LoadableModules }

function KbCreateDriver(
  DriverName: PWideChar;
  DriverEntry: Pointer
): LongBool; stdcall; external userbridge;

function KbLoadModule(
  hModule: HMODULE;
  ModuleName: PWideChar;
  OnLoad: Pointer = nil;
  OnUnload: Pointer = nil;
  OnDeviceControl: Pointer = nil
): LongBool; stdcall; external userbridge;

function KbUnloadModule(
  hModule: HMODULE
): LongBool; stdcall; external userbridge;

function KbGetModuleHandle(
  ModuleName: PWideChar;
  out hModule: HMODULE
): LongBool; stdcall; external userbridge;

function KbCallModule(
  hModule: HMODULE;
  CtlCode: Cardinal;
  Argument: Pointer = nil
): LongBool; stdcall; external userbridge;

{ Hypervisor }

function KbVmmEnable: LongBool; stdcall; external userbridge;

function KbVmmDisable: LongBool; stdcall; external userbridge;

function KbVmmInterceptPage(
  PhysicalAddress: Pointer;
  OnReadPhysicalAddress: Pointer;
  OnWritePhysicalAddress: Pointer;
  OnExecutePhysicalAddress: Pointer;
  OnExecuteReadPhysicalAddress: Pointer;
  OnExecuteWritePhysicalAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbVmmDeinterceptPage(
  PhysicalAddress: Pointer
): LongBool; stdcall; external userbridge;

{ Stuff }

function KbGetKernelProcAddress(
  RoutineName: PWideChar;
  out KernelAddress: Pointer
): LongBool; stdcall; external userbridge;

function KbStallExecutionProcessor(
  Microseconds: Cardinal
): LongBool; stdcall; external userbridge;

function KbBugCheck(Status: NTSTATUS): LongBool; stdcall; external userbridge;

function KbFindSignature(
  ProcessId: TProcessId32;
  Memory: Pointer; // Both user and kernel
  Size: Cardinal;
  Signature: PByte; // "\x11\x22\x33\x00\x44"
  Mask: PByte; // "...?."
  out FoundAddress: Pointer
): LongBool; stdcall; external userbridge;

{ Rtl }

function KbRtlMapDriverMemory(
  DriverImage: Pointer; // raw *.sys file data
  DriverName: PWideChar // '\Driver\YourDriverName'
): TKbLdrStatus; stdcall; external userbridge;

function KbRtlMapDriverFile(
  DriverPath: PWideChar;
  DriverName: PWideChar
): TKbLdrStatus; stdcall; external userbridge;

function KbRtlLoadModuleMemory(
  ModuleImage: Pointer; // raw *.sys file data
  ModuleName: PWideChar; // custom unique name for the loadable module
  out hModule: HMODULE
): TKbLdrStatus; stdcall; external userbridge;

function KbRtlLoadModuleFile(
  ModulePath: PWideChar;
  ModuleName: PWideChar;
  out hModule: HMODULE
): TKbLdrStatus; stdcall; external userbridge;

implementation

end.
