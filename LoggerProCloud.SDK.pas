{ *******************************************************************************
  LoggerPro Cloud SDK for Delphi

  A lightweight SDK to send logs from Delphi applications to LoggerPro Cloud.

  Features:
  - Persistent log storage (logs are saved to disk before sending)
  - Automatic retry on failure
  - Log shipping: old logs are sent before new ones
  - Crash-safe: logs survive application crashes

  Copyright (c) 2025 Daniele Teti
  
******************************************************************************* }

unit LoggerProCloud.SDK;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.DateUtils,
  System.IOUtils;

const
  LOGGERPROCLOUD_SDK_VERSION = '0.5.0';
  LOGGERPROCLOUD_DEFAULT_ENDPOINT = 'https://api.loggerprocloud.com';
  LOGGERPROCLOUD_DEFAULT_BUFFER_SIZE = 100;
  LOGGERPROCLOUD_DEFAULT_FLUSH_INTERVAL_MS = 5000;
  LOGGERPROCLOUD_DEFAULT_RETRY_INTERVAL_MS = 30000;
  LOGGERPROCLOUD_LOG_FILE_EXTENSION = '.lpclog';
  LOGGERPROCLOUD_DEVICE_FILE_EXTENSION = '.lpcdevice';
  LOGGERPROCLOUD_SENDING_EXTENSION = '.sending';

type
  TLogLevel = (llDebug, llInfo, llWarning, llError, llFatal);

  TLogEvent = record
    Level: TLogLevel;
    Message: string;
    Tag: string;
    Timestamp: TDateTime;
    ThreadId: Cardinal;
    ExtraData: TJSONObject;
    class function Create(ALevel: TLogLevel; const AMessage: string;
      const ATag: string = ''; AExtraData: TJSONObject = nil): TLogEvent; static;
    function ToJSON: TJSONObject;
    class function FromJSON(AJSON: TJSONObject): TLogEvent; static;
  end;

  TDeviceInfo = record
    DeviceId: string;
    Hostname: string;
    Username: string;
    OSType: string;
    OSVersion: string;
    AppVersion: string;
    TimezoneOffset: string;  // e.g., "+01:00", "-05:00"
    class function CreateFromSystem(const AAppVersion: string = ''): TDeviceInfo; static;
    function ToJSON: TJSONObject;
    class function FromJSON(AJSON: TJSONObject): TDeviceInfo; static;
  end;

  TDiskInfo = record
    Drive: string;          // e.g. "C:"
    VolumeName: string;
    FileSystem: string;     // e.g. "NTFS"
    TotalBytes: Int64;
    FreeBytes: Int64;
    DriveType: string;      // "Fixed", "Removable", "Network", "CDRom", "RamDisk"
    function ToJSON: TJSONObject;
  end;

  TMonitorInfo = record
    Index: Integer;
    Name: string;
    Width: Integer;
    Height: Integer;
    BitsPerPixel: Integer;
    Primary: Boolean;
    function ToJSON: TJSONObject;
  end;

  TAppVersionInfo = record
    FileVersion: string;        // e.g., "1.2.3.4"
    ProductVersion: string;     // e.g., "1.2.3"
    ProductName: string;
    FileDescription: string;
    CompanyName: string;
    InternalName: string;
    OriginalFilename: string;
    LegalCopyright: string;
    class function GetFromFile(const AFileName: string = ''): TAppVersionInfo; static;
    function ToJSON: TJSONObject;
  end;

  THardwareInfo = record
    // Memory
    TotalPhysicalMemory: Int64;
    AvailablePhysicalMemory: Int64;
    // CPU
    CPUName: string;
    CPUCores: Integer;
    CPULogicalProcessors: Integer;
    CPUArchitecture: string;
    // Disks
    Disks: TArray<TDiskInfo>;
    // Monitors
    Monitors: TArray<TMonitorInfo>;
    // Paths
    ExecutablePath: string;
    WorkingDirectory: string;
    CommandLine: string;
    // System
    SystemBootTime: TDateTime;
    LocalIPAddresses: TArray<string>;
    Timezone: string;
    SystemLanguage: string;
    SystemLocale: string;
    // Application version info (from executable)
    AppVersionInfo: TAppVersionInfo;
    // Helpers
    class function Collect: THardwareInfo; static;
    function ToJSON: TJSONObject;
  end;

  TLoggerProCloudConfig = record
    ApiKey: string;
    CustomerId: string;
    Endpoint: string;
    BufferSize: Integer;
    FlushIntervalMs: Integer;
    RetryIntervalMs: Integer;
    StoragePath: string;  // Directory for persistent log files
    DeviceInfo: TDeviceInfo;
    /// <summary>
    /// Custom device info to be sent along with hardware info at startup.
    /// Set before creating TLoggerProCloud to include in the initial device info call.
    /// </summary>
    InitialCustomDeviceInfo: TArray<TPair<string, string>>;
    class function Create(const AApiKey, ACustomerId: string): TLoggerProCloudConfig; static;
  end;

  TOnLogError = reference to procedure(const ErrorMessage: string);
  TOnLogsSent = reference to procedure(AcceptedCount, RejectedCount: Integer);

  TOnDeviceInfoSent = reference to procedure(Success: Boolean; const ErrorMessage: string);

  TOnCustomDeviceInfoSent = reference to procedure(Success: Boolean; const ErrorMessage: string);

  TLoggerProCloud = class
  private
    FConfig: TLoggerProCloudConfig;
    FBuffer: TList<TLogEvent>;
    FBufferLock: TCriticalSection;
    FShipperThread: TThread;
    FShutdown: Boolean;
    FShutdownEvent: TEvent;
    FOnError: TOnLogError;
    FOnLogsSent: TOnLogsSent;
    FOnDeviceInfoSent: TOnDeviceInfoSent;
    FOnCustomDeviceInfoSent: TOnCustomDeviceInfoSent;
    FEnabled: Boolean;
    FFileCounter: Int64;
    FDeviceInfoSent: Boolean;
    FCustomDeviceInfo: TDictionary<string, string>;
    FCustomDeviceInfoLock: TCriticalSection;
    function SendToServer(const AFilePath: string): Boolean;
    procedure ShipperThreadExecute;
    procedure DoError(const AMessage: string);
    procedure DoLogsSent(AAccepted, ARejected: Integer);
    procedure DoDeviceInfoSent(ASuccess: Boolean; const AErrorMessage: string);
    function GetNextFileName: string;
    procedure PersistBuffer;
    function GetPendingLogFiles: TArray<string>;
    procedure EnsureStoragePath;
    procedure QueueDeviceInfo;
  public
    constructor Create(const AConfig: TLoggerProCloudConfig);
    destructor Destroy; override;

    procedure Log(ALevel: TLogLevel; const AMessage: string;
      const ATag: string = ''; AExtraData: TJSONObject = nil);

    procedure Debug(const AMessage: string; const ATag: string = '');
    procedure Info(const AMessage: string; const ATag: string = '');
    procedure Warning(const AMessage: string; const ATag: string = '');
    procedure Error(const AMessage: string; const ATag: string = '');
    procedure Fatal(const AMessage: string; const ATag: string = '');

    procedure ErrorWithException(E: Exception; const ATag: string = '';
      const AAdditionalMessage: string = '');

    /// <summary>
    /// Queues device hardware info and custom info to be sent to the server.
    /// Called automatically at startup. Uses persistent storage with automatic retry.
    /// To include custom device info, set Config.InitialCustomDeviceInfo before creating the logger.
    /// </summary>
    procedure SendDeviceInfo;

    /// <summary>
    /// Sets a custom device info key-value pair.
    /// These are accumulated until SendCustomDeviceInfo is called.
    /// </summary>
    procedure SetCustomDeviceInfo(const AKey, AValue: string);

    /// <summary>
    /// Clears a specific custom device info key.
    /// </summary>
    procedure ClearCustomDeviceInfo(const AKey: string);

    /// <summary>
    /// Clears all accumulated custom device info.
    /// </summary>
    procedure ClearAllCustomDeviceInfo;

    /// <summary>
    /// Sends all accumulated custom device info to the server.
    /// The data is merged with any existing custom info on the server.
    /// </summary>
    procedure SendCustomDeviceInfo; overload;

    /// <summary>
    /// Sets and immediately sends a single custom device info key-value pair.
    /// </summary>
    procedure SendCustomDeviceInfo(const AKey, AValue: string); overload;

    procedure Flush;
    procedure Shutdown;

    function GetPendingCount: Integer;

    property Enabled: Boolean read FEnabled write FEnabled;
    property OnError: TOnLogError read FOnError write FOnError;
    property OnLogsSent: TOnLogsSent read FOnLogsSent write FOnLogsSent;
    property OnDeviceInfoSent: TOnDeviceInfoSent read FOnDeviceInfoSent write FOnDeviceInfoSent;
    property OnCustomDeviceInfoSent: TOnCustomDeviceInfoSent read FOnCustomDeviceInfoSent write FOnCustomDeviceInfoSent;
    property Config: TLoggerProCloudConfig read FConfig;
    property DeviceInfoSent: Boolean read FDeviceInfoSent;
  end;

  TLoggerProCloudHelper = class
  public
    class function GetHostname: string;
    class function GetUsername: string;
    class function GetOSVersion: string;
    class function GetDeviceId: string;
    class function GetDefaultStoragePath: string;
    class function GetTimezoneOffset: string;  // Returns offset like "+01:00" or "-05:00"
    class function GetAppVersionInfo: TAppVersionInfo;  // Auto-reads from current exe
  end;

function LoggerProCloud: TLoggerProCloud;
procedure InitializeLoggerProCloud(const AConfig: TLoggerProCloudConfig);
procedure FinalizeLoggerProCloud;

implementation

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShlObj,
  Winapi.WinSock,
  System.Win.Registry,
{$ENDIF}
  System.TypInfo,
  System.NetConsts;

{$IFDEF MSWINDOWS}
// Types for GetLogicalProcessorInformation (may not be in older Delphi)
type
  TLogicalProcessorRelationship = (
    RelationProcessorCore = 0,
    RelationNumaNode = 1,
    RelationCache = 2,
    RelationProcessorPackage = 3,
    RelationGroup = 4,
    RelationAll = $FFFF
  );

  TProcessorCoreFlags = BYTE;

  TCacheDescriptor = record
    Level: BYTE;
    Associativity: BYTE;
    LineSize: WORD;
    Size: DWORD;
    CacheType: DWORD;
  end;

  TSystemLogicalProcessorInformation = record
    ProcessorMask: ULONG_PTR;
    Relationship: TLogicalProcessorRelationship;
    case Integer of
      0: (Flags: TProcessorCoreFlags);
      1: (NodeNumber: DWORD);
      2: (Cache: TCacheDescriptor);
      3: (Reserved: array[0..1] of UInt64);
  end;
  PSystemLogicalProcessorInformation = ^TSystemLogicalProcessorInformation;

function GetLogicalProcessorInformation(
  Buffer: PSystemLogicalProcessorInformation;
  var ReturnLength: DWORD): BOOL; stdcall; external kernel32;
{$ENDIF}

var
  GLoggerProCloud: TLoggerProCloud = nil;
  GLoggerProCloudLock: TCriticalSection = nil;

function LoggerProCloud: TLoggerProCloud;
begin
  if GLoggerProCloud = nil then
    raise Exception.Create('LoggerProCloud not initialized. Call InitializeLoggerProCloud first.');
  Result := GLoggerProCloud;
end;

procedure InitializeLoggerProCloud(const AConfig: TLoggerProCloudConfig);
begin
  GLoggerProCloudLock.Enter;
  try
    if GLoggerProCloud <> nil then
      FreeAndNil(GLoggerProCloud);
    GLoggerProCloud := TLoggerProCloud.Create(AConfig);
  finally
    GLoggerProCloudLock.Leave;
  end;
end;

procedure FinalizeLoggerProCloud;
begin
  GLoggerProCloudLock.Enter;
  try
    if GLoggerProCloud <> nil then
    begin
      GLoggerProCloud.Shutdown;
      FreeAndNil(GLoggerProCloud);
    end;
  finally
    GLoggerProCloudLock.Leave;
  end;
end;

{ TLogEvent }

class function TLogEvent.Create(ALevel: TLogLevel; const AMessage, ATag: string;
  AExtraData: TJSONObject): TLogEvent;
begin
  Result.Level := ALevel;
  Result.Message := AMessage;
  Result.Tag := ATag;
  Result.Timestamp := TTimeZone.Local.ToUniversalTime(Now);
  Result.ThreadId := TThread.CurrentThread.ThreadID;
  Result.ExtraData := AExtraData;
end;

function TLogEvent.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('level', GetEnumName(TypeInfo(TLogLevel), Ord(Level)));
  Result.AddPair('message', Message);
  Result.AddPair('tag', Tag);
  Result.AddPair('timestamp', DateToISO8601(Timestamp, True));
  Result.AddPair('thread_id', TJSONNumber.Create(ThreadId));
  if ExtraData <> nil then
    Result.AddPair('extra_data', ExtraData.Clone as TJSONObject);
end;

class function TLogEvent.FromJSON(AJSON: TJSONObject): TLogEvent;
var
  LevelStr: string;
  LevelIdx: Integer;
begin
  LevelStr := AJSON.GetValue<string>('level', 'llInfo');
  LevelIdx := GetEnumValue(TypeInfo(TLogLevel), LevelStr);
  if LevelIdx >= 0 then
    Result.Level := TLogLevel(LevelIdx)
  else
    Result.Level := llInfo;

  Result.Message := AJSON.GetValue<string>('message', '');
  Result.Tag := AJSON.GetValue<string>('tag', '');
  Result.Timestamp := ISO8601ToDate(AJSON.GetValue<string>('timestamp', ''), True);
  Result.ThreadId := AJSON.GetValue<Cardinal>('thread_id', 0);

  if AJSON.GetValue('extra_data') <> nil then
    Result.ExtraData := AJSON.GetValue<TJSONObject>('extra_data').Clone as TJSONObject
  else
    Result.ExtraData := nil;
end;

{ TDeviceInfo }

class function TDeviceInfo.CreateFromSystem(const AAppVersion: string): TDeviceInfo;
var
  VersionInfo: TAppVersionInfo;
begin
  Result.Hostname := TLoggerProCloudHelper.GetHostname;
  Result.Username := TLoggerProCloudHelper.GetUsername;
  Result.DeviceId := TLoggerProCloudHelper.GetDeviceId;
  Result.OSType := 'windows';
  Result.OSVersion := TLoggerProCloudHelper.GetOSVersion;
  Result.TimezoneOffset := TLoggerProCloudHelper.GetTimezoneOffset;

  // Auto-detect app version from executable if not provided
  if AAppVersion <> '' then
    Result.AppVersion := AAppVersion
  else
  begin
    VersionInfo := TLoggerProCloudHelper.GetAppVersionInfo;
    // Prefer FileVersion, fallback to ProductVersion
    if VersionInfo.FileVersion <> '' then
      Result.AppVersion := VersionInfo.FileVersion
    else if VersionInfo.ProductVersion <> '' then
      Result.AppVersion := VersionInfo.ProductVersion;
  end;
end;

function TDeviceInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('device_id', DeviceId);
  Result.AddPair('hostname', Hostname);
  Result.AddPair('username', Username);
  Result.AddPair('os_type', OSType);
  Result.AddPair('os_version', OSVersion);
  Result.AddPair('app_version', AppVersion);
  Result.AddPair('sdk_version', LOGGERPROCLOUD_SDK_VERSION);
  if TimezoneOffset <> '' then
    Result.AddPair('timezone_offset', TimezoneOffset);
end;

class function TDeviceInfo.FromJSON(AJSON: TJSONObject): TDeviceInfo;
begin
  Result.DeviceId := AJSON.GetValue<string>('device_id', '');
  Result.Hostname := AJSON.GetValue<string>('hostname', '');
  Result.Username := AJSON.GetValue<string>('username', '');
  Result.OSType := AJSON.GetValue<string>('os_type', '');
  Result.OSVersion := AJSON.GetValue<string>('os_version', '');
  Result.AppVersion := AJSON.GetValue<string>('app_version', '');
  Result.TimezoneOffset := AJSON.GetValue<string>('timezone_offset', '');
end;

{ TDiskInfo }

function TDiskInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('drive', Drive);
  if VolumeName <> '' then
    Result.AddPair('volume_name', VolumeName);
  if FileSystem <> '' then
    Result.AddPair('file_system', FileSystem);
  Result.AddPair('total_bytes', TJSONNumber.Create(TotalBytes));
  Result.AddPair('free_bytes', TJSONNumber.Create(FreeBytes));
  if DriveType <> '' then
    Result.AddPair('drive_type', DriveType);
end;

{ TMonitorInfo }

function TMonitorInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('index', TJSONNumber.Create(Index));
  if Name <> '' then
    Result.AddPair('name', Name);
  Result.AddPair('width', TJSONNumber.Create(Width));
  Result.AddPair('height', TJSONNumber.Create(Height));
  if BitsPerPixel > 0 then
    Result.AddPair('bits_per_pixel', TJSONNumber.Create(BitsPerPixel));
  Result.AddPair('primary', TJSONBool.Create(Primary));
end;

{ THardwareInfo }

class function THardwareInfo.Collect: THardwareInfo;
{$IFDEF MSWINDOWS}
const
  PROCESSOR_ARCHITECTURE_ARM64_LOCAL = 12;
  ENUM_CURRENT_SETTINGS = DWORD(-1);
var
  MemStatus: TMemoryStatusEx;
  SysInfo: TSystemInfo;
  DriveBits: DWORD;
  DriveChar: Char;
  DriveRoot: string;
  DriveTypeVal: UINT;
  VolumeNameBuf: array[0..MAX_PATH] of Char;
  FileSystemBuf: array[0..MAX_PATH] of Char;
  TotalBytesVal, FreeBytesVal: Int64;
  DiskInfoRec: TDiskInfo;
  DevMode: TDevMode;
  MonIdx: Integer;
  MonInfo: TMonitorInfo;
  Reg: TRegistry;
  TickCount64Val: UInt64;
  BootTime: TDateTime;
  WSADataRec: TWSAData;
  HostNameBuf: array[0..255] of AnsiChar;
  HostEnt: PHostEnt;
  AddrList: ^PInAddr;
  TZInfo: TTimeZoneInformation;
  LangIDVal: DWORD;
  LangName: array[0..255] of Char;
  VolSerial, MaxCompLen, FSFlags: DWORD;
  // For CPU core counting
  CPUBufferSize: DWORD;
  CPUBuffer: PSystemLogicalProcessorInformation;
  CPUPtr: PSystemLogicalProcessorInformation;
  CPUBytesRead: DWORD;
  // For monitor enumeration
  DisplayDevice: TDisplayDevice;
begin
  // Memory
  MemStatus.dwLength := SizeOf(MemStatus);
  GlobalMemoryStatusEx(MemStatus);
  Result.TotalPhysicalMemory := MemStatus.ullTotalPhys;
  Result.AvailablePhysicalMemory := MemStatus.ullAvailPhys;

  // CPU
  GetNativeSystemInfo(SysInfo);
  Result.CPUCores := 0; // Will be filled from registry
  Result.CPULogicalProcessors := SysInfo.dwNumberOfProcessors;

  case SysInfo.wProcessorArchitecture of
    PROCESSOR_ARCHITECTURE_AMD64: Result.CPUArchitecture := 'x64';
    PROCESSOR_ARCHITECTURE_INTEL: Result.CPUArchitecture := 'x86';
    PROCESSOR_ARCHITECTURE_ARM64_LOCAL: Result.CPUArchitecture := 'ARM64';
    PROCESSOR_ARCHITECTURE_ARM: Result.CPUArchitecture := 'ARM';
  else
    Result.CPUArchitecture := 'Unknown';
  end;

  // Get CPU name from registry
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('\HARDWARE\DESCRIPTION\System\CentralProcessor\0') then
    begin
      Result.CPUName := Reg.ReadString('ProcessorNameString');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

  // Get physical core count using GetLogicalProcessorInformation
  Result.CPUCores := 0;
  CPUBufferSize := 0;
  GetLogicalProcessorInformation(nil, CPUBufferSize);
  if (GetLastError = ERROR_INSUFFICIENT_BUFFER) and (CPUBufferSize > 0) then
  begin
    GetMem(CPUBuffer, CPUBufferSize);
    try
      if GetLogicalProcessorInformation(CPUBuffer, CPUBufferSize) then
      begin
        CPUPtr := CPUBuffer;
        CPUBytesRead := 0;
        while CPUBytesRead < CPUBufferSize do
        begin
          if CPUPtr.Relationship = RelationProcessorCore then
            Inc(Result.CPUCores);
          Inc(CPUPtr);
          Inc(CPUBytesRead, SizeOf(TSystemLogicalProcessorInformation));
        end;
      end;
    finally
      FreeMem(CPUBuffer);
    end;
  end;
  if Result.CPUCores = 0 then
    Result.CPUCores := Result.CPULogicalProcessors; // Fallback

  // Disks
  SetLength(Result.Disks, 0);
  DriveBits := GetLogicalDrives;
  for DriveChar := 'A' to 'Z' do
  begin
    if (DriveBits and 1) = 1 then
    begin
      DriveRoot := DriveChar + ':\';
      DriveTypeVal := GetDriveType(PChar(DriveRoot));

      // Only include fixed and removable drives
      if DriveTypeVal in [DRIVE_REMOVABLE, DRIVE_FIXED, DRIVE_REMOTE, DRIVE_RAMDISK] then
      begin
        DiskInfoRec.Drive := DriveChar + ':';

        // Get volume info
        FillChar(VolumeNameBuf, SizeOf(VolumeNameBuf), 0);
        FillChar(FileSystemBuf, SizeOf(FileSystemBuf), 0);
        VolSerial := 0;
        MaxCompLen := 0;
        FSFlags := 0;
        if GetVolumeInformation(PChar(DriveRoot), VolumeNameBuf, MAX_PATH,
          @VolSerial, MaxCompLen, FSFlags, FileSystemBuf, MAX_PATH) then
        begin
          DiskInfoRec.VolumeName := VolumeNameBuf;
          DiskInfoRec.FileSystem := FileSystemBuf;
        end
        else
        begin
          DiskInfoRec.VolumeName := '';
          DiskInfoRec.FileSystem := '';
        end;

        // Get disk space
        FreeBytesVal := 0;
        TotalBytesVal := 0;
        GetDiskFreeSpaceEx(PChar(DriveRoot), FreeBytesVal, TotalBytesVal, nil);
        DiskInfoRec.TotalBytes := TotalBytesVal;
        DiskInfoRec.FreeBytes := FreeBytesVal;

        case DriveTypeVal of
          DRIVE_REMOVABLE: DiskInfoRec.DriveType := 'Removable';
          DRIVE_FIXED: DiskInfoRec.DriveType := 'Fixed';
          DRIVE_REMOTE: DiskInfoRec.DriveType := 'Network';
          DRIVE_CDROM: DiskInfoRec.DriveType := 'CDRom';
          DRIVE_RAMDISK: DiskInfoRec.DriveType := 'RamDisk';
        else
          DiskInfoRec.DriveType := 'Unknown';
        end;

        SetLength(Result.Disks, Length(Result.Disks) + 1);
        Result.Disks[High(Result.Disks)] := DiskInfoRec;
      end;
    end;
    DriveBits := DriveBits shr 1;
  end;

  // Monitors - enumerate physical display devices
  SetLength(Result.Monitors, 0);
  MonIdx := 0;
  while True do
  begin
    FillChar(DisplayDevice, SizeOf(DisplayDevice), 0);
    DisplayDevice.cb := SizeOf(DisplayDevice);

    if not EnumDisplayDevices(nil, MonIdx, DisplayDevice, 0) then
      Break;

    // Only include active monitors (attached to desktop)
    if (DisplayDevice.StateFlags and DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) <> 0 then
    begin
      // Get current display settings for this device
      FillChar(DevMode, SizeOf(DevMode), 0);
      DevMode.dmSize := SizeOf(DevMode);
      if EnumDisplaySettings(@DisplayDevice.DeviceName[0], ENUM_CURRENT_SETTINGS, DevMode) then
      begin
        MonInfo.Index := Length(Result.Monitors);
        MonInfo.Name := DisplayDevice.DeviceString;
        MonInfo.Width := DevMode.dmPelsWidth;
        MonInfo.Height := DevMode.dmPelsHeight;
        MonInfo.BitsPerPixel := DevMode.dmBitsPerPel;
        MonInfo.Primary := (DisplayDevice.StateFlags and DISPLAY_DEVICE_PRIMARY_DEVICE) <> 0;

        SetLength(Result.Monitors, Length(Result.Monitors) + 1);
        Result.Monitors[High(Result.Monitors)] := MonInfo;
      end;
    end;

    Inc(MonIdx);
    if MonIdx > 32 then Break; // Safety limit (32 monitors should be enough)
  end;

  // Paths
  Result.ExecutablePath := ParamStr(0);
  Result.WorkingDirectory := GetCurrentDir;
  Result.CommandLine := GetCommandLine;

  // System boot time
  try
    TickCount64Val := GetTickCount64;
    BootTime := Now - (TickCount64Val / (1000 * 60 * 60 * 24));
    Result.SystemBootTime := TTimeZone.Local.ToUniversalTime(BootTime);
  except
    Result.SystemBootTime := 0;
  end;

  // Local IP addresses
  SetLength(Result.LocalIPAddresses, 0);
  if WSAStartup($0202, WSADataRec) = 0 then
  try
    if Winapi.WinSock.gethostname(HostNameBuf, SizeOf(HostNameBuf)) = 0 then
    begin
      HostEnt := gethostbyname(HostNameBuf);
      if HostEnt <> nil then
      begin
        AddrList := Pointer(HostEnt^.h_addr_list);
        while AddrList^ <> nil do
        begin
          SetLength(Result.LocalIPAddresses, Length(Result.LocalIPAddresses) + 1);
          Result.LocalIPAddresses[High(Result.LocalIPAddresses)] :=
            string(inet_ntoa(AddrList^^));
          Inc(AddrList);
        end;
      end;
    end;
  finally
    WSACleanup;
  end;

  // Timezone
  try
    case GetTimeZoneInformation(TZInfo) of
      TIME_ZONE_ID_STANDARD: Result.Timezone := TZInfo.StandardName;
      TIME_ZONE_ID_DAYLIGHT: Result.Timezone := TZInfo.DaylightName;
    else
      Result.Timezone := TZInfo.StandardName;
    end;
  except
    Result.Timezone := '';
  end;

  // System language
  LangIDVal := GetUserDefaultUILanguage;
  if GetLocaleInfo(LangIDVal, LOCALE_SENGLANGUAGE, LangName, SizeOf(LangName)) > 0 then
    Result.SystemLanguage := LangName
  else
    Result.SystemLanguage := '';

  // System locale
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SNAME, LangName, SizeOf(LangName)) > 0 then
    Result.SystemLocale := LangName
  else
    Result.SystemLocale := '';

  // Application version info from executable
  Result.AppVersionInfo := TAppVersionInfo.GetFromFile(ParamStr(0));
end;
{$ELSE}
begin
  // Non-Windows: minimal info
  Result.TotalPhysicalMemory := 0;
  Result.AvailablePhysicalMemory := 0;
  Result.CPUName := '';
  Result.CPUCores := 0;
  Result.CPULogicalProcessors := 0;
  Result.CPUArchitecture := '';
  SetLength(Result.Disks, 0);
  SetLength(Result.Monitors, 0);
  Result.ExecutablePath := ParamStr(0);
  Result.WorkingDirectory := GetCurrentDir;
  Result.CommandLine := '';
  Result.SystemBootTime := 0;
  SetLength(Result.LocalIPAddresses, 0);
  Result.Timezone := '';
  Result.SystemLanguage := '';
  Result.SystemLocale := '';
end;
{$ENDIF}

function THardwareInfo.ToJSON: TJSONObject;
var
  DisksArray, MonitorsArray, IPsArray: TJSONArray;
  Disk: TDiskInfo;
  Mon: TMonitorInfo;
  IP: string;
begin
  Result := TJSONObject.Create;

  // Memory
  if TotalPhysicalMemory > 0 then
    Result.AddPair('total_physical_memory', TJSONNumber.Create(TotalPhysicalMemory));
  if AvailablePhysicalMemory > 0 then
    Result.AddPair('available_physical_memory', TJSONNumber.Create(AvailablePhysicalMemory));

  // CPU
  if CPUName <> '' then
    Result.AddPair('cpu_name', CPUName);
  if CPUCores > 0 then
    Result.AddPair('cpu_cores', TJSONNumber.Create(CPUCores));
  if CPULogicalProcessors > 0 then
    Result.AddPair('cpu_logical_processors', TJSONNumber.Create(CPULogicalProcessors));
  if CPUArchitecture <> '' then
    Result.AddPair('cpu_architecture', CPUArchitecture);

  // Disks
  if Length(Disks) > 0 then
  begin
    DisksArray := TJSONArray.Create;
    for Disk in Disks do
      DisksArray.AddElement(Disk.ToJSON);
    Result.AddPair('disks', DisksArray);
  end;

  // Monitors
  if Length(Monitors) > 0 then
  begin
    MonitorsArray := TJSONArray.Create;
    for Mon in Monitors do
      MonitorsArray.AddElement(Mon.ToJSON);
    Result.AddPair('monitors', MonitorsArray);
  end;

  // Paths
  if ExecutablePath <> '' then
    Result.AddPair('executable_path', ExecutablePath);
  if WorkingDirectory <> '' then
    Result.AddPair('working_directory', WorkingDirectory);
  if CommandLine <> '' then
    Result.AddPair('command_line', CommandLine);

  // System
  if SystemBootTime > 0 then
    Result.AddPair('system_boot_time', DateToISO8601(SystemBootTime, True));

  if Length(LocalIPAddresses) > 0 then
  begin
    IPsArray := TJSONArray.Create;
    for IP in LocalIPAddresses do
      IPsArray.Add(IP);
    Result.AddPair('local_ip_addresses', IPsArray);
  end;

  if Timezone <> '' then
    Result.AddPair('timezone', Timezone);
  if SystemLanguage <> '' then
    Result.AddPair('system_language', SystemLanguage);
  if SystemLocale <> '' then
    Result.AddPair('system_locale', SystemLocale);

  // Application version info
  if (AppVersionInfo.FileVersion <> '') or (AppVersionInfo.ProductName <> '') then
    Result.AddPair('app_version_info', AppVersionInfo.ToJSON);
end;

{ TLoggerProCloudConfig }

class function TLoggerProCloudConfig.Create(const AApiKey, ACustomerId: string): TLoggerProCloudConfig;
begin
  Result.ApiKey := AApiKey;
  Result.CustomerId := ACustomerId;
  Result.Endpoint := LOGGERPROCLOUD_DEFAULT_ENDPOINT;
  Result.BufferSize := LOGGERPROCLOUD_DEFAULT_BUFFER_SIZE;
  Result.FlushIntervalMs := LOGGERPROCLOUD_DEFAULT_FLUSH_INTERVAL_MS;
  Result.RetryIntervalMs := LOGGERPROCLOUD_DEFAULT_RETRY_INTERVAL_MS;
  Result.StoragePath := TLoggerProCloudHelper.GetDefaultStoragePath;
  Result.DeviceInfo := TDeviceInfo.CreateFromSystem;
end;

{ TLoggerProCloudHelper }

class function TLoggerProCloudHelper.GetHostname: string;
{$IFDEF MSWINDOWS}
var
  Buffer: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  if Winapi.Windows.GetComputerName(Buffer, Size) then
    Result := Buffer
  else
    Result := 'unknown';
end;
{$ELSE}
begin
  Result := 'unknown';
end;
{$ENDIF}

class function TLoggerProCloudHelper.GetUsername: string;
{$IFDEF MSWINDOWS}
var
  Buffer: array[0..256] of Char;
  Size: DWORD;
begin
  Size := 257;
  if Winapi.Windows.GetUserName(Buffer, Size) then
    Result := Buffer
  else
    Result := 'unknown';
end;
{$ELSE}
begin
  Result := 'unknown';
end;
{$ENDIF}

class function TLoggerProCloudHelper.GetOSVersion: string;
{$IFDEF MSWINDOWS}
begin
  Result := TOSVersion.ToString;
end;
{$ELSE}
begin
  Result := 'unknown';
end;
{$ENDIF}

class function TLoggerProCloudHelper.GetDeviceId: string;
begin
  Result := GetUsername + '@' + GetHostname;
end;

class function TLoggerProCloudHelper.GetDefaultStoragePath: string;
{$IFDEF MSWINDOWS}
var
  Path: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, CSIDL_LOCAL_APPDATA, 0, SHGFP_TYPE_CURRENT, Path) = S_OK then
    Result := IncludeTrailingPathDelimiter(Path) + 'LoggerProCloud' + PathDelim + 'pending'
  else
    Result := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'LoggerProCloud' + PathDelim + 'pending';
end;
{$ELSE}
begin
  Result := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'LoggerProCloud' + PathDelim + 'pending';
end;
{$ENDIF}

class function TLoggerProCloudHelper.GetTimezoneOffset: string;
var
  TZInfo: TTimeZoneInformation;
  BiasMinutes: Integer;
  Hours, Minutes: Integer;
  Sign: Char;
begin
  // Get current timezone bias (in minutes, negative for East of UTC)
  case GetTimeZoneInformation(TZInfo) of
    TIME_ZONE_ID_STANDARD:
      BiasMinutes := TZInfo.Bias + TZInfo.StandardBias;
    TIME_ZONE_ID_DAYLIGHT:
      BiasMinutes := TZInfo.Bias + TZInfo.DaylightBias;
  else
    BiasMinutes := TZInfo.Bias;
  end;

  // Bias is negative of offset (Bias = -Offset), so invert
  BiasMinutes := -BiasMinutes;

  if BiasMinutes >= 0 then
    Sign := '+'
  else
  begin
    Sign := '-';
    BiasMinutes := Abs(BiasMinutes);
  end;

  Hours := BiasMinutes div 60;
  Minutes := BiasMinutes mod 60;

  Result := Format('%s%.2d:%.2d', [Sign, Hours, Minutes]);
end;

class function TLoggerProCloudHelper.GetAppVersionInfo: TAppVersionInfo;
begin
  Result := TAppVersionInfo.GetFromFile(ParamStr(0));
end;

{ TAppVersionInfo }

class function TAppVersionInfo.GetFromFile(const AFileName: string): TAppVersionInfo;
{$IFDEF MSWINDOWS}
var
  FileName: string;
  VerInfoSize, VerValueSize, Dummy: DWORD;
  VerInfo: Pointer;
  VerValue: PVSFixedFileInfo;
  LangCodePage: PLongInt;
  TranslateStr: string;

  function GetVersionString(const AKey: string): string;
  var
    ValuePtr: PChar;
    ValueLen: UINT;
  begin
    Result := '';
    if VerQueryValue(VerInfo, PChar('\StringFileInfo\' + TranslateStr + '\' + AKey),
      Pointer(ValuePtr), ValueLen) then
      Result := ValuePtr;
  end;

begin
  Result := Default(TAppVersionInfo);

  if AFileName = '' then
    FileName := ParamStr(0)
  else
    FileName := AFileName;

  VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
  if VerInfoSize = 0 then
    Exit;

  GetMem(VerInfo, VerInfoSize);
  try
    if not GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, VerInfo) then
      Exit;

    // Get fixed file info for version numbers
    if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
    begin
      Result.FileVersion := Format('%d.%d.%d.%d', [
        HiWord(VerValue.dwFileVersionMS),
        LoWord(VerValue.dwFileVersionMS),
        HiWord(VerValue.dwFileVersionLS),
        LoWord(VerValue.dwFileVersionLS)
      ]);
      Result.ProductVersion := Format('%d.%d.%d.%d', [
        HiWord(VerValue.dwProductVersionMS),
        LoWord(VerValue.dwProductVersionMS),
        HiWord(VerValue.dwProductVersionLS),
        LoWord(VerValue.dwProductVersionLS)
      ]);
    end;

    // Get translation info for string queries
    if VerQueryValue(VerInfo, '\VarFileInfo\Translation', Pointer(LangCodePage), VerValueSize) then
    begin
      TranslateStr := IntToHex(LoWord(LangCodePage^), 4) + IntToHex(HiWord(LangCodePage^), 4);

      Result.ProductName := GetVersionString('ProductName');
      Result.FileDescription := GetVersionString('FileDescription');
      Result.CompanyName := GetVersionString('CompanyName');
      Result.InternalName := GetVersionString('InternalName');
      Result.OriginalFilename := GetVersionString('OriginalFilename');
      Result.LegalCopyright := GetVersionString('LegalCopyright');
    end;
  finally
    FreeMem(VerInfo);
  end;
end;
{$ELSE}
begin
  Result := Default(TAppVersionInfo);
end;
{$ENDIF}

function TAppVersionInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  if FileVersion <> '' then
    Result.AddPair('file_version', FileVersion);
  if ProductVersion <> '' then
    Result.AddPair('product_version', ProductVersion);
  if ProductName <> '' then
    Result.AddPair('product_name', ProductName);
  if FileDescription <> '' then
    Result.AddPair('file_description', FileDescription);
  if CompanyName <> '' then
    Result.AddPair('company_name', CompanyName);
  if InternalName <> '' then
    Result.AddPair('internal_name', InternalName);
  if OriginalFilename <> '' then
    Result.AddPair('original_filename', OriginalFilename);
  if LegalCopyright <> '' then
    Result.AddPair('legal_copyright', LegalCopyright);
end;

{ TLoggerProCloud }

constructor TLoggerProCloud.Create(const AConfig: TLoggerProCloudConfig);
var
  SendingFiles: TArray<string>;
  SendingFile: string;
  OriginalName: string;
begin
  inherited Create;
  FConfig := AConfig;
  FBuffer := TList<TLogEvent>.Create;
  FBufferLock := TCriticalSection.Create;
  FCustomDeviceInfo := TDictionary<string, string>.Create;
  FCustomDeviceInfoLock := TCriticalSection.Create;
  FShutdown := False;
  FShutdownEvent := TEvent.Create(nil, True, False, '');
  FEnabled := True;
  FFileCounter := GetTickCount64;
  FDeviceInfoSent := False;

  // Ensure storage directory exists
  EnsureStoragePath;

  // Clean up any .sending files from previous crashed sessions
  // (rename them back to .lpclog so they get retried)
  SendingFiles := TDirectory.GetFiles(FConfig.StoragePath, '*' + LOGGERPROCLOUD_SENDING_EXTENSION);
  for SendingFile in SendingFiles do
  begin
    OriginalName := ChangeFileExt(SendingFile, LOGGERPROCLOUD_LOG_FILE_EXTENSION);
    if not TFile.Exists(OriginalName) then
      TFile.Move(SendingFile, OriginalName)
    else
      TFile.Delete(SendingFile);
  end;

  // Start background shipper thread
  FShipperThread := TThread.CreateAnonymousThread(ShipperThreadExecute);
  FShipperThread.FreeOnTerminate := False;
  FShipperThread.Start;

  // Queue device info to be sent (with retry on failure)
  QueueDeviceInfo;
end;

destructor TLoggerProCloud.Destroy;
begin
  Shutdown;
  FBuffer.Free;
  FBufferLock.Free;
  FCustomDeviceInfo.Free;
  FCustomDeviceInfoLock.Free;
  FShutdownEvent.Free;
  inherited;
end;

procedure TLoggerProCloud.EnsureStoragePath;
begin
  if not TDirectory.Exists(FConfig.StoragePath) then
    TDirectory.CreateDirectory(FConfig.StoragePath);
end;

function TLoggerProCloud.GetNextFileName: string;
begin
  Inc(FFileCounter);
  Result := TPath.Combine(FConfig.StoragePath,
    Format('%s_%d_%d%s', [
      FormatDateTime('yyyymmdd_hhnnsszzz', Now),
      FFileCounter,
      TThread.CurrentThread.ThreadID,
      LOGGERPROCLOUD_LOG_FILE_EXTENSION
    ]));
end;

function TLoggerProCloud.GetPendingLogFiles: TArray<string>;
var
  LogFiles, DeviceFiles: TArray<string>;
  I, Idx: Integer;
begin
  EnsureStoragePath;
  // Get both log files and device info files
  LogFiles := TDirectory.GetFiles(FConfig.StoragePath, '*' + LOGGERPROCLOUD_LOG_FILE_EXTENSION);
  DeviceFiles := TDirectory.GetFiles(FConfig.StoragePath, '*' + LOGGERPROCLOUD_DEVICE_FILE_EXTENSION);
  // Combine arrays properly (Move doesn't work safely with managed types like string)
  SetLength(Result, Length(LogFiles) + Length(DeviceFiles));
  Idx := 0;
  for I := 0 to Length(LogFiles) - 1 do
  begin
    Result[Idx] := LogFiles[I];
    Inc(Idx);
  end;
  for I := 0 to Length(DeviceFiles) - 1 do
  begin
    Result[Idx] := DeviceFiles[I];
    Inc(Idx);
  end;
  // Sort by name (which includes timestamp) to process oldest first
  TArray.Sort<string>(Result);
end;

procedure TLoggerProCloud.PersistBuffer;
var
  Events: TArray<TLogEvent>;
  FileContent: TJSONObject;
  EventsArray: TJSONArray;
  Event: TLogEvent;
  FileName: string;
begin
  FBufferLock.Enter;
  try
    if FBuffer.Count = 0 then
      Exit;
    Events := FBuffer.ToArray;
    FBuffer.Clear;
  finally
    FBufferLock.Leave;
  end;

  // Create JSON file with events and device info
  FileContent := TJSONObject.Create;
  try
    FileContent.AddPair('customer_id', FConfig.CustomerId);
    FileContent.AddPair('device', FConfig.DeviceInfo.ToJSON);

    EventsArray := TJSONArray.Create;
    for Event in Events do
      EventsArray.AddElement(Event.ToJSON);
    FileContent.AddPair('events', EventsArray);

    // Write to file atomically (write to temp, then rename)
    FileName := GetNextFileName;
    TFile.WriteAllText(FileName, FileContent.ToJSON, TEncoding.UTF8);
  finally
    FileContent.Free;
  end;
end;

function TLoggerProCloud.SendToServer(const AFilePath: string): Boolean;
var
  HttpClient: THTTPClient;
  FileContent: string;
  FileJSON: TJSONObject;
  Payload: TJSONObject;
  RequestContent: TStringStream;
  Response: IHTTPResponse;
  ResponseJson: TJSONObject;
  Accepted, Rejected: Integer;
  EventsArray: TJSONArray;
  DeviceJSON, HardwareJSON, CustomInfoJSON: TJSONObject;
  SendingPath: string;
  I: Integer;
  IsDeviceInfoFile: Boolean;
  Endpoint: string;
  OriginalExt: string;
  SourceEvents: TJSONArray;
  EventJSON, APIEvent: TJSONObject;
  LevelStr, TagValue: string;
  ExtraData: TJSONValue;
  NetworkError: Boolean;
begin
  Result := True;  // Default: continue to next file
  NetworkError := False;

  // Check if source file exists
  if not TFile.Exists(AFilePath) then
  begin
    Log(llWarning, 'File not found, skipping: ' + ExtractFileName(AFilePath), 'loggerprocloud');
    Exit;
  end;

  // Determine file type from original extension
  OriginalExt := ExtractFileExt(AFilePath);
  IsDeviceInfoFile := SameText(OriginalExt, LOGGERPROCLOUD_DEVICE_FILE_EXTENSION);

  // Rename file to .sending to mark it as being processed
  SendingPath := ChangeFileExt(AFilePath, LOGGERPROCLOUD_SENDING_EXTENSION);
  try
    if TFile.Exists(SendingPath) then
      TFile.Delete(SendingPath);
    TFile.Move(AFilePath, SendingPath);
  except
    on E: Exception do
    begin
      Log(llWarning, 'Cannot process file (locked?): ' + ExtractFileName(AFilePath) + ' - ' + E.Message, 'loggerprocloud');
      Exit;  // Skip this file, try next
    end;
  end;

  HttpClient := THTTPClient.Create;
  FileJSON := nil;
  Payload := nil;
  RequestContent := nil;
  try
    try
      // Read and parse the file
      if not TFile.Exists(SendingPath) then
      begin
        Log(llWarning, 'Sending file disappeared: ' + ExtractFileName(SendingPath), 'loggerprocloud');
        Exit;
      end;

      FileContent := TFile.ReadAllText(SendingPath, TEncoding.UTF8);
      FileJSON := TJSONObject.ParseJSONValue(FileContent) as TJSONObject;

      if FileJSON = nil then
      begin
        // Invalid JSON, delete the file and continue
        Log(llWarning, 'Invalid JSON in file, deleting: ' + ExtractFileName(AFilePath), 'loggerprocloud');
        TFile.Delete(SendingPath);
        Exit;
      end;

      // Build payload for API
      Payload := TJSONObject.Create;
      Payload.AddPair('customer_id', FileJSON.GetValue<string>('customer_id'));

      // Copy device info
      DeviceJSON := FileJSON.GetValue<TJSONObject>('device');
      if DeviceJSON <> nil then
        Payload.AddPair('device', DeviceJSON.Clone as TJSONObject);

      if IsDeviceInfoFile then
      begin
        // Device info file - send to device-info endpoint
        Endpoint := '/api/v1/ingest/device-info';

        // Copy hardware_info
        HardwareJSON := FileJSON.GetValue<TJSONObject>('hardware_info');
        if HardwareJSON <> nil then
          Payload.AddPair('hardware_info', HardwareJSON.Clone as TJSONObject);

        // Copy custom_device_info if present
        CustomInfoJSON := FileJSON.GetValue<TJSONObject>('custom_device_info');
        if CustomInfoJSON <> nil then
          Payload.AddPair('custom_device_info', CustomInfoJSON.Clone as TJSONObject);
      end
      else
      begin
        // Log file - send to logs endpoint
        Endpoint := '/api/v1/ingest/logs';

        // Convert events to API format
        EventsArray := TJSONArray.Create;
        SourceEvents := FileJSON.GetValue<TJSONArray>('events');
        if SourceEvents <> nil then
        begin
          for I := 0 to SourceEvents.Count - 1 do
          begin
            EventJSON := SourceEvents.Items[I] as TJSONObject;
            APIEvent := TJSONObject.Create;

            // Convert level from enum name to API string
            LevelStr := EventJSON.GetValue<string>('level', 'llInfo');
            if LevelStr.StartsWith('ll') then
              LevelStr := LowerCase(Copy(LevelStr, 3, Length(LevelStr)));
            APIEvent.AddPair('level', LevelStr);

            APIEvent.AddPair('message', EventJSON.GetValue<string>('message', ''));
            TagValue := EventJSON.GetValue<string>('tag', '');
            if TagValue <> '' then
              APIEvent.AddPair('tag', TagValue);
            APIEvent.AddPair('timestamp', EventJSON.GetValue<string>('timestamp', ''));
            APIEvent.AddPair('thread_id', TJSONNumber.Create(EventJSON.GetValue<Cardinal>('thread_id', 0)));

            ExtraData := EventJSON.GetValue('extra_data');
            if (ExtraData <> nil) and (ExtraData is TJSONObject) then
              APIEvent.AddPair('extra_data', (ExtraData as TJSONObject).Clone as TJSONObject);

            EventsArray.AddElement(APIEvent);
          end;
        end;
        Payload.AddPair('events', EventsArray);
      end;

      // Send to server
      HttpClient.ContentType := 'application/json';
      HttpClient.CustomHeaders['X-API-Key'] := FConfig.ApiKey;
      HttpClient.ConnectionTimeout := 10000;
      HttpClient.ResponseTimeout := 30000;

      RequestContent := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
      Response := HttpClient.Post(FConfig.Endpoint + Endpoint, RequestContent);

      if Response.StatusCode = 200 then
      begin
        if IsDeviceInfoFile then
          DoDeviceInfoSent(True, '')
        else
        begin
          ResponseJson := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
          try
            if ResponseJson <> nil then
            begin
              Accepted := ResponseJson.GetValue<Integer>('accepted', 0);
              Rejected := ResponseJson.GetValue<Integer>('rejected', 0);
              DoLogsSent(Accepted, Rejected);
            end;
          finally
            ResponseJson.Free;
          end;
        end;

        // Success! Delete the file
        TFile.Delete(SendingPath);
      end
      else
      begin
        // Server error - restore the file for retry later
        NetworkError := True;
        Log(llWarning, Format('Server returned HTTP %d, will retry later', [Response.StatusCode]), 'loggerprocloud');
        DoError(Format('HTTP %d: %s', [Response.StatusCode, Response.ContentAsString]));
      end;

    except
      on E: Exception do
      begin
        NetworkError := True;
        Log(llWarning, 'Send failed: ' + E.Message + ', will retry later', 'loggerprocloud');
        DoError('Send failed: ' + E.Message);
      end;
    end;
  finally
    HttpClient.Free;
    FileJSON.Free;
    Payload.Free;
    RequestContent.Free;

    // If network error, restore file for retry; otherwise it was processed
    if NetworkError then
    begin
      try
        if TFile.Exists(SendingPath) and not TFile.Exists(AFilePath) then
          TFile.Move(SendingPath, AFilePath);
      except
        // Ignore restore errors
      end;
      Result := False;  // Signal to wait before retrying
    end;
  end;
end;

procedure TLoggerProCloud.ShipperThreadExecute;
var
  PendingFiles: TArray<string>;
  WaitTime: Integer;
  LastFlushTime: TDateTime;
  LogFile: string;
begin
  LastFlushTime := Now;

  while not FShutdown do
  begin
    // Determine wait time based on whether we have pending files
    PendingFiles := GetPendingLogFiles;
    if Length(PendingFiles) > 0 then
      WaitTime := 100  // Quick retry when files are pending
    else
      WaitTime := FConfig.FlushIntervalMs;

    FShutdownEvent.WaitFor(WaitTime);

    if FShutdown then
    begin
      // Final persist before shutdown
      PersistBuffer;
      // Try to send remaining files
      PendingFiles := GetPendingLogFiles;
      for LogFile in PendingFiles do
      begin
        if not SendToServer(LogFile) then
          Break;  // Stop if sending fails
      end;
      Break;
    end;

    // Check if it's time to persist buffer
    if MilliSecondsBetween(Now, LastFlushTime) >= FConfig.FlushIntervalMs then
    begin
      PersistBuffer;
      LastFlushTime := Now;
    end;

    // Try to send pending files (oldest first)
    PendingFiles := GetPendingLogFiles;
    for LogFile in PendingFiles do
    begin
      if FShutdown then
        Break;

      if not SendToServer(LogFile) then
      begin
        // Wait before retrying
        FShutdownEvent.WaitFor(FConfig.RetryIntervalMs);
        Break;  // Don't try other files, wait for retry
      end;
    end;
  end;
end;

procedure TLoggerProCloud.DoError(const AMessage: string);
begin
  // Note: Called from background thread. Handler should use TThread.Queue if UI access needed.
  if Assigned(FOnError) then
    FOnError(AMessage);
end;

procedure TLoggerProCloud.DoLogsSent(AAccepted, ARejected: Integer);
begin
  // Note: Called from background thread. Handler should use TThread.Queue if UI access needed.
  if Assigned(FOnLogsSent) then
    FOnLogsSent(AAccepted, ARejected);
end;

procedure TLoggerProCloud.DoDeviceInfoSent(ASuccess: Boolean; const AErrorMessage: string);
begin
  // Note: Called from background thread. Handler should use TThread.Queue if UI access needed.
  if Assigned(FOnDeviceInfoSent) then
    FOnDeviceInfoSent(ASuccess, AErrorMessage);
end;

procedure TLoggerProCloud.SetCustomDeviceInfo(const AKey, AValue: string);
begin
  FCustomDeviceInfoLock.Enter;
  try
    FCustomDeviceInfo.AddOrSetValue(AKey, AValue);
  finally
    FCustomDeviceInfoLock.Leave;
  end;
end;

procedure TLoggerProCloud.ClearCustomDeviceInfo(const AKey: string);
begin
  FCustomDeviceInfoLock.Enter;
  try
    FCustomDeviceInfo.Remove(AKey);
  finally
    FCustomDeviceInfoLock.Leave;
  end;
end;

procedure TLoggerProCloud.ClearAllCustomDeviceInfo;
begin
  FCustomDeviceInfoLock.Enter;
  try
    FCustomDeviceInfo.Clear;
  finally
    FCustomDeviceInfoLock.Leave;
  end;
end;

procedure TLoggerProCloud.SendCustomDeviceInfo;
var
  FileContent: TJSONObject;
  CustomInfoJSON: TJSONObject;
  Pair: TPair<string, string>;
  InfoCopy: TDictionary<string, string>;
  FileName: string;
begin
  // Make a copy of the custom info to send
  FCustomDeviceInfoLock.Enter;
  try
    if FCustomDeviceInfo.Count = 0 then
      Exit;
    InfoCopy := TDictionary<string, string>.Create(FCustomDeviceInfo);
  finally
    FCustomDeviceInfoLock.Leave;
  end;

  EnsureStoragePath;

  FileContent := TJSONObject.Create;
  try
    // Build the file content (same format as device info file)
    FileContent.AddPair('customer_id', FConfig.CustomerId);
    FileContent.AddPair('device', FConfig.DeviceInfo.ToJSON);

    // Build custom_device_info JSON object
    CustomInfoJSON := TJSONObject.Create;
    for Pair in InfoCopy do
      CustomInfoJSON.AddPair(Pair.Key, Pair.Value);
    FileContent.AddPair('custom_device_info', CustomInfoJSON);

    // Write to file with .lpcdevice extension (will be sent by shipper thread)
    FileName := TPath.Combine(FConfig.StoragePath, FormatDateTime('yyyymmddhhnnsszzz', Now) +
      '_' + IntToStr(TThread.Current.ThreadID) + '_' + IntToStr(AtomicIncrement(FFileCounter)) +
      LOGGERPROCLOUD_DEVICE_FILE_EXTENSION);
    TFile.WriteAllText(FileName, FileContent.ToJSON, TEncoding.UTF8);
  finally
    FileContent.Free;
    InfoCopy.Free;
  end;
end;

procedure TLoggerProCloud.SendCustomDeviceInfo(const AKey, AValue: string);
begin
  SetCustomDeviceInfo(AKey, AValue);
  SendCustomDeviceInfo;
end;

procedure TLoggerProCloud.SendDeviceInfo;
begin
  // Queue device info to be sent by the shipper thread
  QueueDeviceInfo;
end;

procedure TLoggerProCloud.QueueDeviceInfo;
var
  FileContent: TJSONObject;
  HardwareInfo: THardwareInfo;
  CustomInfoJSON: TJSONObject;
  Pair: TPair<string, string>;
  FileName: string;
begin
  EnsureStoragePath;

  // Collect hardware info
  HardwareInfo := THardwareInfo.Collect;

  FileContent := TJSONObject.Create;
  try
    // Build the file content
    FileContent.AddPair('customer_id', FConfig.CustomerId);
    FileContent.AddPair('device', FConfig.DeviceInfo.ToJSON);
    FileContent.AddPair('hardware_info', HardwareInfo.ToJSON);

    // Include initial custom device info if present
    if Length(FConfig.InitialCustomDeviceInfo) > 0 then
    begin
      CustomInfoJSON := TJSONObject.Create;
      for Pair in FConfig.InitialCustomDeviceInfo do
        CustomInfoJSON.AddPair(Pair.Key, Pair.Value);
      FileContent.AddPair('custom_device_info', CustomInfoJSON);
    end;

    // Write to file with .lpcdevice extension
    FileName := TPath.Combine(FConfig.StoragePath, FormatDateTime('yyyymmddhhnnsszzz', Now) +
      '_' + IntToStr(TThread.Current.ThreadID) + '_' + IntToStr(AtomicIncrement(FFileCounter)) +
      LOGGERPROCLOUD_DEVICE_FILE_EXTENSION);
    TFile.WriteAllText(FileName, FileContent.ToJSON, TEncoding.UTF8);
  finally
    FileContent.Free;
  end;
end;

procedure TLoggerProCloud.Log(ALevel: TLogLevel; const AMessage, ATag: string;
  AExtraData: TJSONObject);
var
  Event: TLogEvent;
  ShouldPersist: Boolean;
begin
  if not FEnabled then
    Exit;

  Event := TLogEvent.Create(ALevel, AMessage, ATag, AExtraData);

  FBufferLock.Enter;
  try
    FBuffer.Add(Event);
    ShouldPersist := FBuffer.Count >= FConfig.BufferSize;
  finally
    FBufferLock.Leave;
  end;

  // Persist immediately when buffer is full
  if ShouldPersist then
    PersistBuffer;
end;

procedure TLoggerProCloud.Debug(const AMessage, ATag: string);
begin
  Log(llDebug, AMessage, ATag);
end;

procedure TLoggerProCloud.Info(const AMessage, ATag: string);
begin
  Log(llInfo, AMessage, ATag);
end;

procedure TLoggerProCloud.Warning(const AMessage, ATag: string);
begin
  Log(llWarning, AMessage, ATag);
end;

procedure TLoggerProCloud.Error(const AMessage, ATag: string);
begin
  Log(llError, AMessage, ATag);
end;

procedure TLoggerProCloud.Fatal(const AMessage, ATag: string);
begin
  Log(llFatal, AMessage, ATag);
end;

procedure TLoggerProCloud.ErrorWithException(E: Exception; const ATag,
  AAdditionalMessage: string);
var
  ExtraData: TJSONObject;
  Msg: string;
begin
  ExtraData := TJSONObject.Create;
  ExtraData.AddPair('exception_class', E.ClassName);
  ExtraData.AddPair('exception_message', E.Message);

  if AAdditionalMessage <> '' then
    Msg := AAdditionalMessage + ': ' + E.Message
  else
    Msg := E.Message;

  Log(llError, Msg, ATag, ExtraData);
end;

procedure TLoggerProCloud.Flush;
begin
  PersistBuffer;
end;

function TLoggerProCloud.GetPendingCount: Integer;
begin
  Result := Length(GetPendingLogFiles);
  FBufferLock.Enter;
  try
    Inc(Result, FBuffer.Count);
  finally
    FBufferLock.Leave;
  end;
end;

procedure TLoggerProCloud.Shutdown;
begin
  if FShutdown then
    Exit;

  FShutdown := True;
  FShutdownEvent.SetEvent;

  if FShipperThread <> nil then
  begin
    FShipperThread.WaitFor;
    FreeAndNil(FShipperThread);
  end;
end;

initialization
  GLoggerProCloudLock := TCriticalSection.Create;

finalization
  FinalizeLoggerProCloud;
  FreeAndNil(GLoggerProCloudLock);

end.
