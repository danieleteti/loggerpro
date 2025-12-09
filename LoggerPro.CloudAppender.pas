// *************************************************************************** }
//
// LoggerPro
//
// Copyright (c) 2010-2025 Daniele Teti
//
// https://github.com/danieleteti/loggerpro
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit LoggerPro.CloudAppender;

{ LoggerPro Cloud Appender
  Sends logs to LoggerPro Cloud service using the LoggerPro.Cloud SDK.

  Usage (simple):
    Log := BuildLogWriter([
      TLoggerProFileAppender.Create,
      TLoggerProConsoleAppender.Create,
      TLoggerProCloudAppender.Create('lpc_desk_your_api_key', 'customer_id')
    ]);

  Usage (with custom device info and callbacks):
    Log := BuildLogWriter([
      TLoggerProCloudAppender.Create('lpc_desk_key', 'customer_id', 'http://localhost:8000',
        procedure(const Err: string)
        begin
          WriteLn('[CLOUD ERROR] ' + Err);
        end,
        procedure(Accepted, Rejected: Integer)
        begin
          WriteLn(Format('[CLOUD] Sent: %d accepted', [Accepted]));
        end,
        procedure(const CustomInfo: TDictionary<string, string>)
        begin
          CustomInfo.Add('license', 'professional');
          CustomInfo.Add('app_mode', 'production');
        end
      )
    ]);
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  LoggerPro,
  LoggerProCloud.SDK;

type
  /// <summary>
  /// Callback type for cloud errors.
  /// </summary>
  TCloudErrorProc = reference to procedure(const ErrorMessage: string);

  /// <summary>
  /// Callback type for logs sent notification.
  /// </summary>
  TCloudLogsSentProc = reference to procedure(AcceptedCount, RejectedCount: Integer);

  /// <summary>
  /// Callback type for collecting custom device info.
  /// Add key-value pairs to the dictionary; they will be sent with hardware info.
  /// </summary>
  TCustomDeviceInfoProc = reference to procedure(const CustomDeviceInfo: TDictionary<string, string>);

  TLoggerProCloudAppender = class(TLoggerProAppenderBase)
  private
    FApiKey: string;
    FCustomerId: string;
    FEndpoint: string;
    FCloudLogger: TLoggerProCloud;
    FOnCloudError: TCloudErrorProc;
    FOnCloudLogsSent: TCloudLogsSentProc;
    FOnCustomDeviceInfo: TCustomDeviceInfoProc;
    function MapLogType(ALogType: TLogType): LoggerProCloud.SDK.TLogLevel;
  protected
    procedure DoCloudError(const ErrorMessage: string);
    procedure DoCloudLogsSent(AcceptedCount, RejectedCount: Integer);
  public
    /// <summary>
    /// Creates a new LoggerPro Cloud appender with all options.
    /// </summary>
    /// <param name="AApiKey">The API key for LoggerPro Cloud (starts with lpc_desk_)</param>
    /// <param name="ACustomerId">The customer identifier in your system</param>
    /// <param name="AEndpoint">Custom endpoint URL (default: http://localhost:8000)</param>
    /// <param name="AOnError">Optional callback for errors</param>
    /// <param name="AOnLogsSent">Optional callback when logs are sent</param>
    /// <param name="AOnCustomDeviceInfo">Optional callback to provide custom device info</param>
    constructor Create(const AApiKey, ACustomerId: string;
      const AEndpoint: string = 'http://localhost:8000';
      const AOnError: TCloudErrorProc = nil;
      const AOnLogsSent: TCloudLogsSentProc = nil;
      const AOnCustomDeviceInfo: TCustomDeviceInfoProc = nil); reintroduce; overload;

    /// <summary>
    /// Creates an empty appender (requires configuration via properties before use).
    /// </summary>
    constructor Create; overload; override;
    destructor Destroy; override;

    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;

    /// <summary>
    /// Callback for cloud errors. Can be set after construction if needed.
    /// </summary>
    property OnCloudError: TCloudErrorProc read FOnCloudError write FOnCloudError;

    /// <summary>
    /// Callback for logs sent notification. Can be set after construction if needed.
    /// </summary>
    property OnCloudLogsSent: TCloudLogsSentProc read FOnCloudLogsSent write FOnCloudLogsSent;

    /// <summary>
    /// Callback to provide custom device info during Setup.
    /// Must be set before Setup is called (i.e., before passing to BuildLogWriter).
    /// </summary>
    property OnCustomDeviceInfo: TCustomDeviceInfoProc read FOnCustomDeviceInfo write FOnCustomDeviceInfo;
  end;

implementation

{ TLoggerProCloudAppender }

constructor TLoggerProCloudAppender.Create(const AApiKey, ACustomerId: string;
  const AEndpoint: string;
  const AOnError: TCloudErrorProc;
  const AOnLogsSent: TCloudLogsSentProc;
  const AOnCustomDeviceInfo: TCustomDeviceInfoProc);
begin
  inherited Create;
  FApiKey := AApiKey;
  FCustomerId := ACustomerId;
  FEndpoint := AEndpoint;
  FOnCloudError := AOnError;
  FOnCloudLogsSent := AOnLogsSent;
  FOnCustomDeviceInfo := AOnCustomDeviceInfo;
  FCloudLogger := nil;
end;

constructor TLoggerProCloudAppender.Create;
begin
  inherited Create;
  FApiKey := '';
  FCustomerId := '';
  FEndpoint := 'http://localhost:8000';
  FOnCloudError := nil;
  FOnCloudLogsSent := nil;
  FOnCustomDeviceInfo := nil;
  FCloudLogger := nil;
end;

destructor TLoggerProCloudAppender.Destroy;
begin
  // TearDown should have been called, but just in case
  if Assigned(FCloudLogger) then
  begin
    FCloudLogger.Shutdown;
    FreeAndNil(FCloudLogger);
  end;
  inherited;
end;

procedure TLoggerProCloudAppender.Setup;
var
  Config: TLoggerProCloudConfig;
  CustomInfo: TDictionary<string, string>;
  Pair: TPair<string, string>;
  CustomInfoArray: TArray<TPair<string, string>>;
  I: Integer;
begin
  inherited;

  if FApiKey = '' then
    raise ELoggerPro.Create('LoggerProCloudAppender: ApiKey is required');
  if FCustomerId = '' then
    raise ELoggerPro.Create('LoggerProCloudAppender: CustomerId is required');

  Config := TLoggerProCloudConfig.Create(FApiKey, FCustomerId);
  Config.Endpoint := FEndpoint;
  Config.FlushIntervalMs := 3000;  // Flush every 3 seconds

  // Collect custom device info BEFORE creating the cloud logger
  // so it gets sent together with hardware info
  if Assigned(FOnCustomDeviceInfo) then
  begin
    CustomInfo := TDictionary<string, string>.Create;
    try
      FOnCustomDeviceInfo(CustomInfo);
      if CustomInfo.Count > 0 then
      begin
        SetLength(CustomInfoArray, CustomInfo.Count);
        I := 0;
        for Pair in CustomInfo do
        begin
          CustomInfoArray[I] := Pair;
          Inc(I);
        end;
        Config.InitialCustomDeviceInfo := CustomInfoArray;
      end;
    finally
      CustomInfo.Free;
    end;
  end;

  FCloudLogger := TLoggerProCloud.Create(Config);
  FCloudLogger.OnError := DoCloudError;
  FCloudLogger.OnLogsSent := DoCloudLogsSent;
end;

procedure TLoggerProCloudAppender.TearDown;
begin
  if Assigned(FCloudLogger) then
  begin
    FCloudLogger.Shutdown;
    FreeAndNil(FCloudLogger);
  end;
  inherited;
end;

function TLoggerProCloudAppender.MapLogType(ALogType: TLogType): LoggerProCloud.SDK.TLogLevel;
begin
  case ALogType of
    TLogType.Debug:   Result := LoggerProCloud.SDK.TLogLevel.llDebug;
    TLogType.Info:    Result := LoggerProCloud.SDK.TLogLevel.llInfo;
    TLogType.Warning: Result := LoggerProCloud.SDK.TLogLevel.llWarning;
    TLogType.Error:   Result := LoggerProCloud.SDK.TLogLevel.llError;
    TLogType.Fatal:   Result := LoggerProCloud.SDK.TLogLevel.llFatal;
  else
    Result := LoggerProCloud.SDK.TLogLevel.llInfo;
  end;
end;

procedure TLoggerProCloudAppender.WriteLog(const aLogItem: TLogItem);
var
  CloudLevel: LoggerProCloud.SDK.TLogLevel;
begin
  if not Assigned(FCloudLogger) then
    Exit;

  CloudLevel := MapLogType(aLogItem.LogType);
  FCloudLogger.Log(CloudLevel, aLogItem.LogMessage, aLogItem.LogTag);
end;

procedure TLoggerProCloudAppender.DoCloudError(const ErrorMessage: string);
begin
  if Assigned(FOnCloudError) then
    FOnCloudError(ErrorMessage);
end;

procedure TLoggerProCloudAppender.DoCloudLogsSent(AcceptedCount, RejectedCount: Integer);
begin
  if Assigned(FOnCloudLogsSent) then
    FOnCloudLogsSent(AcceptedCount, RejectedCount);
end;

end.
