unit KernelBridge;

interface

uses
  kbapi, NtUtils;

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

uses
  DelphiUtils.AutoObject;

type
  TKbAutoDriver = class (TCustomAutoReleasable, IAutoReleasable)
    destructor Destroy; override;
  end;

destructor TKbAutoDriver.Destroy;
begin
  if FAutoRelease then
    KbUnload;

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
