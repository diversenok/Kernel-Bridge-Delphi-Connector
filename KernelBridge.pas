unit KernelBridge;

interface

uses
  kbapi, NtUtils, DelphiUtils.AutoObject;

type
  TKbAutoObject = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

  TKbAutoHandle = class (TCustomAutoHandle, IHandle)
    procedure Release; override;
  end;

// Load Kernel Bridge as a driver
function KbxLoadAsDriver(
  out Driver: IAutoReleasable;
  DriverPath: String
): TNtxStatus;

// Load Kernel Bridge as a minifilter
function KbxLoadAsFilter(
  out Driver: IAutoReleasable;
  DriverPath: String;
  Altitude: String = '260000'
): TNtxStatus;

implementation

type
  TKbAutoDriver = class (TCustomAutoReleasable, IAutoReleasable)
    procedure Release; override;
  end;

procedure TKbAutoDriver.Release;
begin
  KbUnload;
  inherited;
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

function KbxLoadAsDriver;
begin
  Result.Location := 'KbLoadAsDriver';
  Result.Win32Result := KbLoadAsDriver(PWideChar(DriverPath));

  if Result.IsSuccess then
    Driver := TKbAutoDriver.Create;
end;

function KbxLoadAsFilter;
begin
  Result.Location := 'KbLoadAsFilter';
  Result.Win32Result := KbLoadAsFilter(PWideChar(DriverPath),
    PWideChar(Altitude));

  if Result.IsSuccess then
    Driver := TKbAutoDriver.Create;
end;

end.
