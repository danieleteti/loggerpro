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

unit LoggerPro.Builder;

{ Fluent interface builder for LoggerPro configuration }

interface

uses
  LoggerPro,
  LoggerPro.CallbackAppender,
  LoggerPro.TimeRotatingFileAppender,
  LoggerPro.HTTPAppender,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  ILoggerProBuilder = interface;

  { Base interface for all appender configurators }
  IAppenderConfigurator = interface
    ['{A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D}']
    function Done: ILoggerProBuilder;
  end;

  { Console appender configurator }
  IConsoleAppenderConfigurator = interface(IAppenderConfigurator)
    ['{B2C3D4E5-F6A7-5B6C-9D0E-1F2A3B4C5D6E}']
    function WithLogLevel(aLogLevel: TLogType): IConsoleAppenderConfigurator;
    function WithLogFormat(aLogFormat: string): IConsoleAppenderConfigurator;
  end;

  { File appender configurator }
  IFileAppenderConfigurator = interface(IAppenderConfigurator)
    ['{C3D4E5F6-A7B8-6C7D-0E1F-2A3B4C5D6E7F}']
    function WithLogsFolder(const aLogsFolder: string): IFileAppenderConfigurator;
    function WithFileBaseName(const aFileBaseName: string): IFileAppenderConfigurator;
    function WithMaxBackupFiles(aMaxBackupFiles: Integer): IFileAppenderConfigurator;
    function WithMaxFileSizeInKB(aMaxFileSizeInKB: Integer): IFileAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IFileAppenderConfigurator;
    function WithEncoding(aEncoding: TEncoding): IFileAppenderConfigurator;
  end;

  { JSONL file appender configurator }
  IJSONLFileAppenderConfigurator = interface(IAppenderConfigurator)
    ['{D4E5F6A7-B8C9-7D8E-1F2A-3B4C5D6E7F8A}']
    function WithLogsFolder(const aLogsFolder: string): IJSONLFileAppenderConfigurator;
    function WithFileBaseName(const aFileBaseName: string): IJSONLFileAppenderConfigurator;
    function WithMaxBackupFiles(aMaxBackupFiles: Integer): IJSONLFileAppenderConfigurator;
    function WithMaxFileSizeInKB(aMaxFileSizeInKB: Integer): IJSONLFileAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IJSONLFileAppenderConfigurator;
  end;

  { Time rotating file appender configurator }
  ITimeRotatingFileAppenderConfigurator = interface(IAppenderConfigurator)
    ['{E5F6A7B8-C9D0-8E9F-2A3B-4C5D6E7F8A9B}']
    function WithInterval(aInterval: TTimeRotationInterval): ITimeRotatingFileAppenderConfigurator;
    function WithMaxBackupFiles(aMaxBackupFiles: Integer): ITimeRotatingFileAppenderConfigurator;
    function WithLogsFolder(const aLogsFolder: string): ITimeRotatingFileAppenderConfigurator;
    function WithFileBaseName(const aFileBaseName: string): ITimeRotatingFileAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): ITimeRotatingFileAppenderConfigurator;
  end;

  { HTTP appender configurator }
  IHTTPAppenderConfigurator = interface(IAppenderConfigurator)
    ['{F6A7B8C9-D0E1-9F0A-3B4C-5D6E7F8A9B0C}']
    function WithURL(const aURL: string): IHTTPAppenderConfigurator;
    function WithContentType(aContentType: THTTPContentType): IHTTPAppenderConfigurator;
    function WithTimeout(aTimeoutSeconds: Integer): IHTTPAppenderConfigurator;
    function WithRetryCount(aRetryCount: Integer): IHTTPAppenderConfigurator;
    function WithHeader(const aName, aValue: string): IHTTPAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IHTTPAppenderConfigurator;
  end;

  { ElasticSearch appender configurator }
  IElasticSearchAppenderConfigurator = interface(IAppenderConfigurator)
    ['{A7B8C9D0-E1F2-0A1B-4C5D-6E7F8A9B0C1D}']
    function WithURL(const aURL: string): IElasticSearchAppenderConfigurator;
    function WithHost(const aHost: string): IElasticSearchAppenderConfigurator;
    function WithPort(aPort: Integer): IElasticSearchAppenderConfigurator;
    function WithIndex(const aIndex: string): IElasticSearchAppenderConfigurator;
    function WithTimeout(aTimeoutSeconds: Integer): IElasticSearchAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IElasticSearchAppenderConfigurator;
  end;

  { Memory appender configurator }
  IMemoryAppenderConfigurator = interface(IAppenderConfigurator)
    ['{B8C9D0E1-F2A3-1B2C-5D6E-7F8A9B0C1D2E}']
    function WithMaxSize(aMaxSize: Integer): IMemoryAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IMemoryAppenderConfigurator;
  end;

  { Callback appender configurator }
  ICallbackAppenderConfigurator = interface(IAppenderConfigurator)
    ['{C9D0E1F2-A3B4-2C3D-6E7F-8A9B0C1D2E3F}']
    function WithCallback(aCallback: TLogItemCallback): ICallbackAppenderConfigurator;
    function WithSynchronizeToMainThread(aValue: Boolean): ICallbackAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): ICallbackAppenderConfigurator;
  end;

  { Simple callback appender configurator (message only) }
  ISimpleCallbackAppenderConfigurator = interface(IAppenderConfigurator)
    ['{D0E1F2A3-B4C5-3D4E-7F8A-9B0C1D2E3F4A}']
    function WithCallback(aCallback: TLogMessageCallback): ISimpleCallbackAppenderConfigurator;
    function WithSynchronizeToMainThread(aValue: Boolean): ISimpleCallbackAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): ISimpleCallbackAppenderConfigurator;
  end;

  { OutputDebugString appender configurator }
  IOutputDebugStringAppenderConfigurator = interface(IAppenderConfigurator)
    ['{E1F2A3B4-C5D6-4E5F-8A9B-0C1D2E3F4A5B}']
    function WithLogLevel(aLogLevel: TLogType): IOutputDebugStringAppenderConfigurator;
  end;

  { UDP Syslog appender configurator }
  IUDPSyslogAppenderConfigurator = interface(IAppenderConfigurator)
    ['{F2A3B4C5-D6E7-5F6A-9B0C-1D2E3F4A5B6C}']
    function WithHost(const aHost: string): IUDPSyslogAppenderConfigurator;
    function WithPort(aPort: Integer): IUDPSyslogAppenderConfigurator;
    function WithHostName(const aHostName: string): IUDPSyslogAppenderConfigurator;
    function WithUserName(const aUserName: string): IUDPSyslogAppenderConfigurator;
    function WithApplication(const aApplication: string): IUDPSyslogAppenderConfigurator;
    function WithVersion(const aVersion: string): IUDPSyslogAppenderConfigurator;
    function WithProcID(const aProcID: string): IUDPSyslogAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IUDPSyslogAppenderConfigurator;
  end;

{$IFDEF CONSOLE}
  { Simple console appender configurator (cross-platform, uses Writeln) }
  ISimpleConsoleAppenderConfigurator = interface(IAppenderConfigurator)
    ['{A3B4C5D6-E7F8-6A7B-0C1D-2E3F4A5B6C7D}']
    function WithLogLevel(aLogLevel: TLogType): ISimpleConsoleAppenderConfigurator;
  end;
{$ENDIF}

{$IF Defined(MSWINDOWS)}
  { VCL Memo appender configurator (requires VCL, Windows only) }
  IVCLMemoAppenderConfigurator = interface(IAppenderConfigurator)
    ['{B4C5D6E7-F8A9-7B8C-1D2E-3F4A5B6C7D8E}']
    function WithMaxLogLines(aMaxLogLines: Word): IVCLMemoAppenderConfigurator;
    function WithClearOnStartup(aValue: Boolean): IVCLMemoAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IVCLMemoAppenderConfigurator;
  end;

  { VCL ListBox appender configurator (requires VCL, Windows only) }
  IVCLListBoxAppenderConfigurator = interface(IAppenderConfigurator)
    ['{C5D6E7F8-A9B0-8C9D-2E3F-4A5B6C7D8E9F}']
    function WithMaxLogLines(aMaxLogLines: Word): IVCLListBoxAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IVCLListBoxAppenderConfigurator;
  end;

  { VCL ListView appender configurator (requires VCL, Windows only) }
  IVCLListViewAppenderConfigurator = interface(IAppenderConfigurator)
    ['{D6E7F8A9-B0C1-9D0E-3F4A-5B6C7D8E9F0A}']
    function WithMaxLogLines(aMaxLogLines: Word): IVCLListViewAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IVCLListViewAppenderConfigurator;
  end;
{$ENDIF}

  { FireDAC DB appender configurator (cross-platform) }
  IFireDACAppenderConfigurator = interface(IAppenderConfigurator)
    ['{E7F8A9B0-C1D2-0E1F-4A5B-6C7D8E9F0A1B}']
    function WithConnectionDefName(const aConnectionDefName: string): IFireDACAppenderConfigurator;
    function WithStoredProcName(const aStoredProcName: string): IFireDACAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IFireDACAppenderConfigurator;
  end;

  { Main builder interface }
  ILoggerProBuilder = interface
    ['{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}']
    // Simple appender methods (with defaults)
    function AddConsoleAppender: ILoggerProBuilder; overload;
    function AddConsoleAppender(aLogLevel: TLogType): ILoggerProBuilder; overload;
{$IFDEF CONSOLE}
    function AddSimpleConsoleAppender: ILoggerProBuilder; overload;
    function AddSimpleConsoleAppender(aLogLevel: TLogType): ILoggerProBuilder; overload;
{$ENDIF}
    function AddFileAppender: ILoggerProBuilder; overload;
    function AddFileAppender(const aLogsFolder: string; const aFileBaseName: string = ''): ILoggerProBuilder; overload;
    function AddJSONLFileAppender: ILoggerProBuilder; overload;
    function AddJSONLFileAppender(const aLogsFolder: string; const aFileBaseName: string = ''): ILoggerProBuilder; overload;
    function AddMemoryAppender(aMaxSize: Integer = 1000): ILoggerProBuilder;
    function AddOutputDebugStringAppender: ILoggerProBuilder; overload;
    function AddOutputDebugStringAppender(aLogLevel: TLogType): ILoggerProBuilder; overload;

    // Generic method for adding pre-configured appenders
    function AddAppender(aAppender: ILogAppender): ILoggerProBuilder;

    // Configurator methods (for advanced configuration)
    function ConfigureConsoleAppender: IConsoleAppenderConfigurator;
{$IFDEF CONSOLE}
    function ConfigureSimpleConsoleAppender: ISimpleConsoleAppenderConfigurator;
{$ENDIF}
    function ConfigureFileAppender: IFileAppenderConfigurator;
    function ConfigureJSONLFileAppender: IJSONLFileAppenderConfigurator;
    function ConfigureTimeRotatingFileAppender: ITimeRotatingFileAppenderConfigurator;
    function ConfigureHTTPAppender: IHTTPAppenderConfigurator;
    function ConfigureElasticSearchAppender: IElasticSearchAppenderConfigurator;
    function ConfigureMemoryAppender: IMemoryAppenderConfigurator;
    function ConfigureCallbackAppender: ICallbackAppenderConfigurator;
    function ConfigureSimpleCallbackAppender: ISimpleCallbackAppenderConfigurator;
    function ConfigureOutputDebugStringAppender: IOutputDebugStringAppenderConfigurator;
    function ConfigureUDPSyslogAppender: IUDPSyslogAppenderConfigurator;
{$IF Defined(MSWINDOWS)}
    { VCL appenders - require VCL units (Windows only) }
    function ConfigureVCLMemoAppender(aMemo: TObject): IVCLMemoAppenderConfigurator;
    function ConfigureVCLListBoxAppender(aListBox: TObject): IVCLListBoxAppenderConfigurator;
    function ConfigureVCLListViewAppender(aListView: TObject): IVCLListViewAppenderConfigurator;
{$ENDIF}
    { FireDAC appender (cross-platform) }
    function ConfigureFireDACAppender: IFireDACAppenderConfigurator;

    // Global configuration
    function WithDefaultLogLevel(aLogLevel: TLogType): ILoggerProBuilder;

    // Build the logger
    function Build: ILogWriter;
  end;

{ Helper function for fluent builder creation }
function LoggerProBuilder: ILoggerProBuilder;

implementation

uses
  LoggerPro.ConsoleAppender,
{$IFDEF CONSOLE}
  LoggerPro.SimpleConsoleAppender,
{$ENDIF}
  LoggerPro.FileAppender,
  LoggerPro.JSONLFileAppender,
  LoggerPro.ElasticSearchAppender,
  LoggerPro.MemoryAppender,
  LoggerPro.OutputDebugStringAppender,
  LoggerPro.UDPSyslogAppender,
  LoggerPro.DBAppender.FireDAC
{$IF Defined(MSWINDOWS)}
  , LoggerPro.VCLMemoAppender
  , LoggerPro.VCLListBoxAppender
  , LoggerPro.VCLListViewAppender
  , Vcl.StdCtrls
  , Vcl.ComCtrls
{$ENDIF}
  ;

type
  { Forward declaration }
  TLoggerProBuilder = class;

  { Base configurator class }
  TBaseAppenderConfigurator = class(TInterfacedObject)
  protected
    FBuilder: TLoggerProBuilder;
    FLogLevel: TLogType;
    FLogLevelSet: Boolean;
    procedure ApplyLogLevel(aAppender: ILogAppender);
  public
    constructor Create(aBuilder: TLoggerProBuilder);
  end;

  { Console appender configurator }
  TConsoleAppenderConfigurator = class(TBaseAppenderConfigurator, IConsoleAppenderConfigurator)
  private
    FLogFormat: string;
  public
    function WithLogLevel(aLogLevel: TLogType): IConsoleAppenderConfigurator;
    function WithLogFormat(aLogFormat: string): IConsoleAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { File appender configurator }
  TFileAppenderConfigurator = class(TBaseAppenderConfigurator, IFileAppenderConfigurator)
  private
    FLogsFolder: string;
    FFileBaseName: string;
    FMaxBackupFiles: Integer;
    FMaxFileSizeInKB: Integer;
    FEncoding: TEncoding;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    function WithLogsFolder(const aLogsFolder: string): IFileAppenderConfigurator;
    function WithFileBaseName(const aFileBaseName: string): IFileAppenderConfigurator;
    function WithMaxBackupFiles(aMaxBackupFiles: Integer): IFileAppenderConfigurator;
    function WithMaxFileSizeInKB(aMaxFileSizeInKB: Integer): IFileAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IFileAppenderConfigurator;
    function WithEncoding(aEncoding: TEncoding): IFileAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { JSONL file appender configurator }
  TJSONLFileAppenderConfigurator = class(TBaseAppenderConfigurator, IJSONLFileAppenderConfigurator)
  private
    FLogsFolder: string;
    FFileBaseName: string;
    FMaxBackupFiles: Integer;
    FMaxFileSizeInKB: Integer;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    function WithLogsFolder(const aLogsFolder: string): IJSONLFileAppenderConfigurator;
    function WithFileBaseName(const aFileBaseName: string): IJSONLFileAppenderConfigurator;
    function WithMaxBackupFiles(aMaxBackupFiles: Integer): IJSONLFileAppenderConfigurator;
    function WithMaxFileSizeInKB(aMaxFileSizeInKB: Integer): IJSONLFileAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IJSONLFileAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { Time rotating file appender configurator }
  TTimeRotatingFileAppenderConfigurator = class(TBaseAppenderConfigurator, ITimeRotatingFileAppenderConfigurator)
  private
    FInterval: TTimeRotationInterval;
    FMaxBackupFiles: Integer;
    FLogsFolder: string;
    FFileBaseName: string;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    function WithInterval(aInterval: TTimeRotationInterval): ITimeRotatingFileAppenderConfigurator;
    function WithMaxBackupFiles(aMaxBackupFiles: Integer): ITimeRotatingFileAppenderConfigurator;
    function WithLogsFolder(const aLogsFolder: string): ITimeRotatingFileAppenderConfigurator;
    function WithFileBaseName(const aFileBaseName: string): ITimeRotatingFileAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): ITimeRotatingFileAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { HTTP appender configurator }
  THTTPAppenderConfigurator = class(TBaseAppenderConfigurator, IHTTPAppenderConfigurator)
  private
    FURL: string;
    FContentType: THTTPContentType;
    FTimeoutSeconds: Integer;
    FRetryCount: Integer;
    FHeaders: TDictionary<string, string>;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    destructor Destroy; override;
    function WithURL(const aURL: string): IHTTPAppenderConfigurator;
    function WithContentType(aContentType: THTTPContentType): IHTTPAppenderConfigurator;
    function WithTimeout(aTimeoutSeconds: Integer): IHTTPAppenderConfigurator;
    function WithRetryCount(aRetryCount: Integer): IHTTPAppenderConfigurator;
    function WithHeader(const aName, aValue: string): IHTTPAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IHTTPAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { ElasticSearch appender configurator }
  TElasticSearchAppenderConfigurator = class(TBaseAppenderConfigurator, IElasticSearchAppenderConfigurator)
  private
    FURL: string;
    FHost: string;
    FPort: Integer;
    FIndex: string;
    FTimeoutSeconds: Integer;
    FUseHostPortIndex: Boolean;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    function WithURL(const aURL: string): IElasticSearchAppenderConfigurator;
    function WithHost(const aHost: string): IElasticSearchAppenderConfigurator;
    function WithPort(aPort: Integer): IElasticSearchAppenderConfigurator;
    function WithIndex(const aIndex: string): IElasticSearchAppenderConfigurator;
    function WithTimeout(aTimeoutSeconds: Integer): IElasticSearchAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IElasticSearchAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { Memory appender configurator }
  TMemoryAppenderConfigurator = class(TBaseAppenderConfigurator, IMemoryAppenderConfigurator)
  private
    FMaxSize: Integer;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    function WithMaxSize(aMaxSize: Integer): IMemoryAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IMemoryAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { Callback appender configurator }
  TCallbackAppenderConfigurator = class(TBaseAppenderConfigurator, ICallbackAppenderConfigurator)
  private
    FCallback: TLogItemCallback;
    FSynchronizeToMainThread: Boolean;
  public
    function WithCallback(aCallback: TLogItemCallback): ICallbackAppenderConfigurator;
    function WithSynchronizeToMainThread(aValue: Boolean): ICallbackAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): ICallbackAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { Simple callback appender configurator }
  TSimpleCallbackAppenderConfigurator = class(TBaseAppenderConfigurator, ISimpleCallbackAppenderConfigurator)
  private
    FCallback: TLogMessageCallback;
    FSynchronizeToMainThread: Boolean;
  public
    function WithCallback(aCallback: TLogMessageCallback): ISimpleCallbackAppenderConfigurator;
    function WithSynchronizeToMainThread(aValue: Boolean): ISimpleCallbackAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): ISimpleCallbackAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { OutputDebugString appender configurator }
  TOutputDebugStringAppenderConfigurator = class(TBaseAppenderConfigurator, IOutputDebugStringAppenderConfigurator)
  public
    function WithLogLevel(aLogLevel: TLogType): IOutputDebugStringAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { UDP Syslog appender configurator }
  TUDPSyslogAppenderConfigurator = class(TBaseAppenderConfigurator, IUDPSyslogAppenderConfigurator)
  private
    FHost: string;
    FPort: Integer;
    FHostName: string;
    FUserName: string;
    FApplication: string;
    FVersion: string;
    FProcID: string;
  public
    constructor Create(aBuilder: TLoggerProBuilder);
    function WithHost(const aHost: string): IUDPSyslogAppenderConfigurator;
    function WithPort(aPort: Integer): IUDPSyslogAppenderConfigurator;
    function WithHostName(const aHostName: string): IUDPSyslogAppenderConfigurator;
    function WithUserName(const aUserName: string): IUDPSyslogAppenderConfigurator;
    function WithApplication(const aApplication: string): IUDPSyslogAppenderConfigurator;
    function WithVersion(const aVersion: string): IUDPSyslogAppenderConfigurator;
    function WithProcID(const aProcID: string): IUDPSyslogAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IUDPSyslogAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

{$IFDEF CONSOLE}
  { Simple console appender configurator }
  TSimpleConsoleAppenderConfigurator = class(TBaseAppenderConfigurator, ISimpleConsoleAppenderConfigurator)
  public
    function WithLogLevel(aLogLevel: TLogType): ISimpleConsoleAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;
{$ENDIF}

{$IF Defined(MSWINDOWS)}
  { VCL Memo appender configurator }
  TVCLMemoAppenderConfigurator = class(TBaseAppenderConfigurator, IVCLMemoAppenderConfigurator)
  private
    FMemo: TMemo;
    FMaxLogLines: Word;
    FClearOnStartup: Boolean;
  public
    constructor Create(aBuilder: TLoggerProBuilder; aMemo: TMemo);
    function WithMaxLogLines(aMaxLogLines: Word): IVCLMemoAppenderConfigurator;
    function WithClearOnStartup(aValue: Boolean): IVCLMemoAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IVCLMemoAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { VCL ListBox appender configurator }
  TVCLListBoxAppenderConfigurator = class(TBaseAppenderConfigurator, IVCLListBoxAppenderConfigurator)
  private
    FListBox: TListBox;
    FMaxLogLines: Word;
  public
    constructor Create(aBuilder: TLoggerProBuilder; aListBox: TListBox);
    function WithMaxLogLines(aMaxLogLines: Word): IVCLListBoxAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IVCLListBoxAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { VCL ListView appender configurator }
  TVCLListViewAppenderConfigurator = class(TBaseAppenderConfigurator, IVCLListViewAppenderConfigurator)
  private
    FListView: TListView;
    FMaxLogLines: Word;
  public
    constructor Create(aBuilder: TLoggerProBuilder; aListView: TListView);
    function WithMaxLogLines(aMaxLogLines: Word): IVCLListViewAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IVCLListViewAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

{$ENDIF}

  { FireDAC DB appender configurator (cross-platform) }
  TFireDACAppenderConfigurator = class(TBaseAppenderConfigurator, IFireDACAppenderConfigurator)
  private
    FConnectionDefName: string;
    FStoredProcName: string;
  public
    function WithConnectionDefName(const aConnectionDefName: string): IFireDACAppenderConfigurator;
    function WithStoredProcName(const aStoredProcName: string): IFireDACAppenderConfigurator;
    function WithLogLevel(aLogLevel: TLogType): IFireDACAppenderConfigurator;
    function Done: ILoggerProBuilder;
  end;

  { Builder implementation - hidden from interface }
  TLoggerProBuilder = class(TInterfacedObject, ILoggerProBuilder)
  private
    FAppenders: TList<ILogAppender>;
    FDefaultLogLevel: TLogType;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: ILoggerProBuilder;
    // Simple appender methods
    function AddConsoleAppender: ILoggerProBuilder; overload;
    function AddConsoleAppender(aLogLevel: TLogType): ILoggerProBuilder; overload;
{$IFDEF CONSOLE}
    function AddSimpleConsoleAppender: ILoggerProBuilder; overload;
    function AddSimpleConsoleAppender(aLogLevel: TLogType): ILoggerProBuilder; overload;
{$ENDIF}
    function AddFileAppender: ILoggerProBuilder; overload;
    function AddFileAppender(const aLogsFolder: string; const aFileBaseName: string = ''): ILoggerProBuilder; overload;
    function AddJSONLFileAppender: ILoggerProBuilder; overload;
    function AddJSONLFileAppender(const aLogsFolder: string; const aFileBaseName: string = ''): ILoggerProBuilder; overload;
    function AddMemoryAppender(aMaxSize: Integer = 1000): ILoggerProBuilder;
    function AddOutputDebugStringAppender: ILoggerProBuilder; overload;
    function AddOutputDebugStringAppender(aLogLevel: TLogType): ILoggerProBuilder; overload;
    // Generic method for adding pre-configured appenders
    function AddAppender(aAppender: ILogAppender): ILoggerProBuilder;
    // Configurator methods
    function ConfigureConsoleAppender: IConsoleAppenderConfigurator;
{$IFDEF CONSOLE}
    function ConfigureSimpleConsoleAppender: ISimpleConsoleAppenderConfigurator;
{$ENDIF}
    function ConfigureFileAppender: IFileAppenderConfigurator;
    function ConfigureJSONLFileAppender: IJSONLFileAppenderConfigurator;
    function ConfigureTimeRotatingFileAppender: ITimeRotatingFileAppenderConfigurator;
    function ConfigureHTTPAppender: IHTTPAppenderConfigurator;
    function ConfigureElasticSearchAppender: IElasticSearchAppenderConfigurator;
    function ConfigureMemoryAppender: IMemoryAppenderConfigurator;
    function ConfigureCallbackAppender: ICallbackAppenderConfigurator;
    function ConfigureSimpleCallbackAppender: ISimpleCallbackAppenderConfigurator;
    function ConfigureOutputDebugStringAppender: IOutputDebugStringAppenderConfigurator;
    function ConfigureUDPSyslogAppender: IUDPSyslogAppenderConfigurator;
{$IF Defined(MSWINDOWS)}
    // VCL appenders (Windows only)
    function ConfigureVCLMemoAppender(aMemo: TObject): IVCLMemoAppenderConfigurator;
    function ConfigureVCLListBoxAppender(aListBox: TObject): IVCLListBoxAppenderConfigurator;
    function ConfigureVCLListViewAppender(aListView: TObject): IVCLListViewAppenderConfigurator;
{$ENDIF}
    // FireDAC appender (cross-platform)
    function ConfigureFireDACAppender: IFireDACAppenderConfigurator;
    // Global configuration
    function WithDefaultLogLevel(aLogLevel: TLogType): ILoggerProBuilder;
    // Build the logger
    function Build: ILogWriter;
    // Used by configurators
    procedure InternalAddAppender(aAppender: ILogAppender);
  end;

{ TBaseAppenderConfigurator }

constructor TBaseAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create;
  FBuilder := aBuilder;
  FLogLevel := TLogType.Debug;
  FLogLevelSet := False;
end;

procedure TBaseAppenderConfigurator.ApplyLogLevel(aAppender: ILogAppender);
begin
  if FLogLevelSet then
    aAppender.SetLogLevel(FLogLevel);
end;

{ TLoggerProBuilder }

constructor TLoggerProBuilder.Create;
begin
  inherited Create;
  FAppenders := TList<ILogAppender>.Create;
  FDefaultLogLevel := TLogType.Debug;
end;

destructor TLoggerProBuilder.Destroy;
begin
  FAppenders.Free;
  inherited;
end;

class function TLoggerProBuilder.New: ILoggerProBuilder;
begin
  Result := TLoggerProBuilder.Create;
end;

procedure TLoggerProBuilder.InternalAddAppender(aAppender: ILogAppender);
begin
  FAppenders.Add(aAppender);
end;

function TLoggerProBuilder.AddAppender(aAppender: ILogAppender): ILoggerProBuilder;
begin
  FAppenders.Add(aAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddConsoleAppender: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProConsoleAppender.Create;
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddConsoleAppender(aLogLevel: TLogType): ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProConsoleAppender.Create;
  lAppender.SetLogLevel(aLogLevel);
  FAppenders.Add(lAppender);
  Result := Self;
end;

{$IFDEF CONSOLE}
function TLoggerProBuilder.AddSimpleConsoleAppender: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProSimpleConsoleAppender.Create;
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddSimpleConsoleAppender(aLogLevel: TLogType): ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProSimpleConsoleAppender.Create;
  lAppender.SetLogLevel(aLogLevel);
  FAppenders.Add(lAppender);
  Result := Self;
end;
{$ENDIF}

function TLoggerProBuilder.AddFileAppender: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProFileAppender.Create;
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddFileAppender(const aLogsFolder: string; const aFileBaseName: string): ILoggerProBuilder;
var
  lAppender: ILogAppender;
  lFileNameFormat: string;
begin
  if aFileBaseName.IsEmpty then
    lFileNameFormat := TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT
  else
    lFileNameFormat := aFileBaseName + '.{number}.{tag}.log';
  lAppender := TLoggerProFileAppender.Create(
    TLoggerProFileAppender.DEFAULT_MAX_BACKUP_FILE_COUNT,
    TLoggerProFileAppender.DEFAULT_MAX_FILE_SIZE_KB,
    aLogsFolder,
    lFileNameFormat);
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddJSONLFileAppender: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProJSONLFileAppender.Create;
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddJSONLFileAppender(const aLogsFolder: string; const aFileBaseName: string): ILoggerProBuilder;
var
  lAppender: ILogAppender;
  lFileNameFormat: string;
begin
  if aFileBaseName.IsEmpty then
    lFileNameFormat := TLoggerProSimpleFileAppender.DEFAULT_FILENAME_FORMAT
  else
    lFileNameFormat := aFileBaseName + '.{number}.log';
  lAppender := TLoggerProJSONLFileAppender.Create(
    TLoggerProJSONLFileAppender.DEFAULT_MAX_BACKUP_FILE_COUNT,
    TLoggerProJSONLFileAppender.DEFAULT_MAX_FILE_SIZE_KB,
    aLogsFolder,
    lFileNameFormat);
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddMemoryAppender(aMaxSize: Integer): ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(aMaxSize);
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddOutputDebugStringAppender: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProOutputDebugStringAppender.Create;
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.AddOutputDebugStringAppender(aLogLevel: TLogType): ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProOutputDebugStringAppender.Create;
  lAppender.SetLogLevel(aLogLevel);
  FAppenders.Add(lAppender);
  Result := Self;
end;

function TLoggerProBuilder.ConfigureConsoleAppender: IConsoleAppenderConfigurator;
begin
  Result := TConsoleAppenderConfigurator.Create(Self);
end;

{$IFDEF CONSOLE}
function TLoggerProBuilder.ConfigureSimpleConsoleAppender: ISimpleConsoleAppenderConfigurator;
begin
  Result := TSimpleConsoleAppenderConfigurator.Create(Self);
end;
{$ENDIF}

function TLoggerProBuilder.ConfigureFileAppender: IFileAppenderConfigurator;
begin
  Result := TFileAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureJSONLFileAppender: IJSONLFileAppenderConfigurator;
begin
  Result := TJSONLFileAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureTimeRotatingFileAppender: ITimeRotatingFileAppenderConfigurator;
begin
  Result := TTimeRotatingFileAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureHTTPAppender: IHTTPAppenderConfigurator;
begin
  Result := THTTPAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureElasticSearchAppender: IElasticSearchAppenderConfigurator;
begin
  Result := TElasticSearchAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureMemoryAppender: IMemoryAppenderConfigurator;
begin
  Result := TMemoryAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureCallbackAppender: ICallbackAppenderConfigurator;
begin
  Result := TCallbackAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureSimpleCallbackAppender: ISimpleCallbackAppenderConfigurator;
begin
  Result := TSimpleCallbackAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureOutputDebugStringAppender: IOutputDebugStringAppenderConfigurator;
begin
  Result := TOutputDebugStringAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.ConfigureUDPSyslogAppender: IUDPSyslogAppenderConfigurator;
begin
  Result := TUDPSyslogAppenderConfigurator.Create(Self);
end;

{$IF Defined(MSWINDOWS)}
function TLoggerProBuilder.ConfigureVCLMemoAppender(aMemo: TObject): IVCLMemoAppenderConfigurator;
begin
  if not (aMemo is TMemo) then
    raise ELoggerPro.Create('ConfigureVCLMemoAppender requires a TMemo instance');
  Result := TVCLMemoAppenderConfigurator.Create(Self, TMemo(aMemo));
end;

function TLoggerProBuilder.ConfigureVCLListBoxAppender(aListBox: TObject): IVCLListBoxAppenderConfigurator;
begin
  if not (aListBox is TListBox) then
    raise ELoggerPro.Create('ConfigureVCLListBoxAppender requires a TListBox instance');
  Result := TVCLListBoxAppenderConfigurator.Create(Self, TListBox(aListBox));
end;

function TLoggerProBuilder.ConfigureVCLListViewAppender(aListView: TObject): IVCLListViewAppenderConfigurator;
begin
  if not (aListView is TListView) then
    raise ELoggerPro.Create('ConfigureVCLListViewAppender requires a TListView instance');
  Result := TVCLListViewAppenderConfigurator.Create(Self, TListView(aListView));
end;

{$ENDIF}

function TLoggerProBuilder.ConfigureFireDACAppender: IFireDACAppenderConfigurator;
begin
  Result := TFireDACAppenderConfigurator.Create(Self);
end;

function TLoggerProBuilder.WithDefaultLogLevel(aLogLevel: TLogType): ILoggerProBuilder;
begin
  FDefaultLogLevel := aLogLevel;
  Result := Self;
end;

function TLoggerProBuilder.Build: ILogWriter;
var
  lAppendersArray: TArray<ILogAppender>;
  I: Integer;
begin
  if FAppenders.Count = 0 then
    raise ELoggerPro.Create('No appenders configured. Add at least one appender before calling Build.');

  SetLength(lAppendersArray, FAppenders.Count);
  for I := 0 to FAppenders.Count - 1 do
    lAppendersArray[I] := FAppenders[I];

  Result := BuildLogWriter(lAppendersArray);
end;

{ TConsoleAppenderConfigurator }

function TConsoleAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IConsoleAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TConsoleAppenderConfigurator.WithLogFormat(aLogFormat: string): IConsoleAppenderConfigurator;
begin
  FLogFormat := aLogFormat;
  Result := Self;
end;

function TConsoleAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProConsoleAppender.Create;
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TFileAppenderConfigurator }

constructor TFileAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FLogsFolder := '';
  FFileBaseName := '';
  FMaxBackupFiles := TLoggerProFileAppender.DEFAULT_MAX_BACKUP_FILE_COUNT;
  FMaxFileSizeInKB := TLoggerProFileAppender.DEFAULT_MAX_FILE_SIZE_KB;
  FEncoding := nil;
end;

function TFileAppenderConfigurator.WithLogsFolder(const aLogsFolder: string): IFileAppenderConfigurator;
begin
  FLogsFolder := aLogsFolder;
  Result := Self;
end;

function TFileAppenderConfigurator.WithFileBaseName(const aFileBaseName: string): IFileAppenderConfigurator;
begin
  FFileBaseName := aFileBaseName;
  Result := Self;
end;

function TFileAppenderConfigurator.WithMaxBackupFiles(aMaxBackupFiles: Integer): IFileAppenderConfigurator;
begin
  FMaxBackupFiles := aMaxBackupFiles;
  Result := Self;
end;

function TFileAppenderConfigurator.WithMaxFileSizeInKB(aMaxFileSizeInKB: Integer): IFileAppenderConfigurator;
begin
  FMaxFileSizeInKB := aMaxFileSizeInKB;
  Result := Self;
end;

function TFileAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IFileAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TFileAppenderConfigurator.WithEncoding(aEncoding: TEncoding): IFileAppenderConfigurator;
begin
  FEncoding := aEncoding;
  Result := Self;
end;

function TFileAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
  lFileNameFormat: string;
begin
  if FFileBaseName.IsEmpty then
    lFileNameFormat := TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT
  else
    lFileNameFormat := FFileBaseName + '.{number}.{tag}.log';
  lAppender := TLoggerProFileAppender.Create(
    FMaxBackupFiles,
    FMaxFileSizeInKB,
    FLogsFolder,
    lFileNameFormat,
    nil,
    FEncoding);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TJSONLFileAppenderConfigurator }

constructor TJSONLFileAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FLogsFolder := '';
  FFileBaseName := '';
  FMaxBackupFiles := TLoggerProJSONLFileAppender.DEFAULT_MAX_BACKUP_FILE_COUNT;
  FMaxFileSizeInKB := TLoggerProJSONLFileAppender.DEFAULT_MAX_FILE_SIZE_KB;
end;

function TJSONLFileAppenderConfigurator.WithLogsFolder(const aLogsFolder: string): IJSONLFileAppenderConfigurator;
begin
  FLogsFolder := aLogsFolder;
  Result := Self;
end;

function TJSONLFileAppenderConfigurator.WithFileBaseName(const aFileBaseName: string): IJSONLFileAppenderConfigurator;
begin
  FFileBaseName := aFileBaseName;
  Result := Self;
end;

function TJSONLFileAppenderConfigurator.WithMaxBackupFiles(aMaxBackupFiles: Integer): IJSONLFileAppenderConfigurator;
begin
  FMaxBackupFiles := aMaxBackupFiles;
  Result := Self;
end;

function TJSONLFileAppenderConfigurator.WithMaxFileSizeInKB(aMaxFileSizeInKB: Integer): IJSONLFileAppenderConfigurator;
begin
  FMaxFileSizeInKB := aMaxFileSizeInKB;
  Result := Self;
end;

function TJSONLFileAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IJSONLFileAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TJSONLFileAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
  lFileNameFormat: string;
begin
  if FFileBaseName.IsEmpty then
    lFileNameFormat := TLoggerProSimpleFileAppender.DEFAULT_FILENAME_FORMAT
  else
    lFileNameFormat := FFileBaseName + '.{number}.log';
  lAppender := TLoggerProJSONLFileAppender.Create(
    FMaxBackupFiles,
    FMaxFileSizeInKB,
    FLogsFolder,
    lFileNameFormat);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TTimeRotatingFileAppenderConfigurator }

constructor TTimeRotatingFileAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FInterval := TTimeRotationInterval.Daily;
  FMaxBackupFiles := TLoggerProTimeRotatingFileAppender.DEFAULT_MAX_BACKUP_FILES;
  FLogsFolder := '';
  FFileBaseName := '';
end;

function TTimeRotatingFileAppenderConfigurator.WithInterval(aInterval: TTimeRotationInterval): ITimeRotatingFileAppenderConfigurator;
begin
  FInterval := aInterval;
  Result := Self;
end;

function TTimeRotatingFileAppenderConfigurator.WithMaxBackupFiles(aMaxBackupFiles: Integer): ITimeRotatingFileAppenderConfigurator;
begin
  FMaxBackupFiles := aMaxBackupFiles;
  Result := Self;
end;

function TTimeRotatingFileAppenderConfigurator.WithLogsFolder(const aLogsFolder: string): ITimeRotatingFileAppenderConfigurator;
begin
  FLogsFolder := aLogsFolder;
  Result := Self;
end;

function TTimeRotatingFileAppenderConfigurator.WithFileBaseName(const aFileBaseName: string): ITimeRotatingFileAppenderConfigurator;
begin
  FFileBaseName := aFileBaseName;
  Result := Self;
end;

function TTimeRotatingFileAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): ITimeRotatingFileAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TTimeRotatingFileAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    FInterval,
    FMaxBackupFiles,
    FLogsFolder,
    FFileBaseName);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ THTTPAppenderConfigurator }

constructor THTTPAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FURL := '';
  FContentType := THTTPContentType.JSON;
  FTimeoutSeconds := TLoggerProHTTPAppender.DEFAULT_TIMEOUT_SECONDS;
  FRetryCount := TLoggerProHTTPAppender.DEFAULT_MAX_RETRY_COUNT;
  FHeaders := TDictionary<string, string>.Create;
end;

destructor THTTPAppenderConfigurator.Destroy;
begin
  FHeaders.Free;
  inherited;
end;

function THTTPAppenderConfigurator.WithURL(const aURL: string): IHTTPAppenderConfigurator;
begin
  FURL := aURL;
  Result := Self;
end;

function THTTPAppenderConfigurator.WithContentType(aContentType: THTTPContentType): IHTTPAppenderConfigurator;
begin
  FContentType := aContentType;
  Result := Self;
end;

function THTTPAppenderConfigurator.WithTimeout(aTimeoutSeconds: Integer): IHTTPAppenderConfigurator;
begin
  FTimeoutSeconds := aTimeoutSeconds;
  Result := Self;
end;

function THTTPAppenderConfigurator.WithRetryCount(aRetryCount: Integer): IHTTPAppenderConfigurator;
begin
  FRetryCount := aRetryCount;
  Result := Self;
end;

function THTTPAppenderConfigurator.WithHeader(const aName, aValue: string): IHTTPAppenderConfigurator;
begin
  FHeaders.AddOrSetValue(aName, aValue);
  Result := Self;
end;

function THTTPAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IHTTPAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function THTTPAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: TLoggerProHTTPAppender;
  lPair: TPair<string, string>;
begin
  if FURL.Trim.IsEmpty then
    raise ELoggerPro.Create('HTTP appender requires a URL. Use WithURL to set it.');

  lAppender := TLoggerProHTTPAppender.Create(FURL, FContentType, FTimeoutSeconds);
  lAppender.MaxRetryCount := FRetryCount;
  for lPair in FHeaders do
    lAppender.AddHeader(lPair.Key, lPair.Value);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TElasticSearchAppenderConfigurator }

constructor TElasticSearchAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FURL := '';
  FHost := 'http://localhost';
  FPort := 9200;
  FIndex := 'logs';
  FTimeoutSeconds := TLoggerProElasticSearchAppender.DEFAULT_TIMEOUT_SECONDS;
  FUseHostPortIndex := False;
end;

function TElasticSearchAppenderConfigurator.WithURL(const aURL: string): IElasticSearchAppenderConfigurator;
begin
  FURL := aURL;
  FUseHostPortIndex := False;
  Result := Self;
end;

function TElasticSearchAppenderConfigurator.WithHost(const aHost: string): IElasticSearchAppenderConfigurator;
begin
  FHost := aHost;
  FUseHostPortIndex := True;
  Result := Self;
end;

function TElasticSearchAppenderConfigurator.WithPort(aPort: Integer): IElasticSearchAppenderConfigurator;
begin
  FPort := aPort;
  FUseHostPortIndex := True;
  Result := Self;
end;

function TElasticSearchAppenderConfigurator.WithIndex(const aIndex: string): IElasticSearchAppenderConfigurator;
begin
  FIndex := aIndex;
  FUseHostPortIndex := True;
  Result := Self;
end;

function TElasticSearchAppenderConfigurator.WithTimeout(aTimeoutSeconds: Integer): IElasticSearchAppenderConfigurator;
begin
  FTimeoutSeconds := aTimeoutSeconds;
  Result := Self;
end;

function TElasticSearchAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IElasticSearchAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TElasticSearchAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  if FUseHostPortIndex then
    lAppender := TLoggerProElasticSearchAppender.Create(FHost, FPort, FIndex, FTimeoutSeconds)
  else if not FURL.Trim.IsEmpty then
    lAppender := TLoggerProElasticSearchAppender.Create(FURL, FTimeoutSeconds)
  else
    raise ELoggerPro.Create('ElasticSearch appender requires either a URL or Host/Port/Index configuration.');

  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TMemoryAppenderConfigurator }

constructor TMemoryAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FMaxSize := TLoggerProMemoryRingBufferAppender.DEFAULT_MAX_SIZE;
end;

function TMemoryAppenderConfigurator.WithMaxSize(aMaxSize: Integer): IMemoryAppenderConfigurator;
begin
  FMaxSize := aMaxSize;
  Result := Self;
end;

function TMemoryAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IMemoryAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TMemoryAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(FMaxSize);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TCallbackAppenderConfigurator }

function TCallbackAppenderConfigurator.WithCallback(aCallback: TLogItemCallback): ICallbackAppenderConfigurator;
begin
  FCallback := aCallback;
  Result := Self;
end;

function TCallbackAppenderConfigurator.WithSynchronizeToMainThread(aValue: Boolean): ICallbackAppenderConfigurator;
begin
  FSynchronizeToMainThread := aValue;
  Result := Self;
end;

function TCallbackAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): ICallbackAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TCallbackAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  if not Assigned(FCallback) then
    raise ELoggerPro.Create('Callback appender requires a callback. Use WithCallback to set it.');
  lAppender := TLoggerProCallbackAppender.Create(FCallback, FSynchronizeToMainThread);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TSimpleCallbackAppenderConfigurator }

function TSimpleCallbackAppenderConfigurator.WithCallback(aCallback: TLogMessageCallback): ISimpleCallbackAppenderConfigurator;
begin
  FCallback := aCallback;
  Result := Self;
end;

function TSimpleCallbackAppenderConfigurator.WithSynchronizeToMainThread(aValue: Boolean): ISimpleCallbackAppenderConfigurator;
begin
  FSynchronizeToMainThread := aValue;
  Result := Self;
end;

function TSimpleCallbackAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): ISimpleCallbackAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TSimpleCallbackAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  if not Assigned(FCallback) then
    raise ELoggerPro.Create('Simple callback appender requires a callback. Use WithCallback to set it.');
  lAppender := TLoggerProCallbackAppender.Create(FCallback, FSynchronizeToMainThread);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TOutputDebugStringAppenderConfigurator }

function TOutputDebugStringAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IOutputDebugStringAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TOutputDebugStringAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProOutputDebugStringAppender.Create;
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TUDPSyslogAppenderConfigurator }

constructor TUDPSyslogAppenderConfigurator.Create(aBuilder: TLoggerProBuilder);
begin
  inherited Create(aBuilder);
  FHost := 'localhost';
  FPort := 514;
  FHostName := '';
  FUserName := '';
  FApplication := '';
  FVersion := '1.0';
  FProcID := '';
end;

function TUDPSyslogAppenderConfigurator.WithHost(const aHost: string): IUDPSyslogAppenderConfigurator;
begin
  FHost := aHost;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithPort(aPort: Integer): IUDPSyslogAppenderConfigurator;
begin
  FPort := aPort;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithHostName(const aHostName: string): IUDPSyslogAppenderConfigurator;
begin
  FHostName := aHostName;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithUserName(const aUserName: string): IUDPSyslogAppenderConfigurator;
begin
  FUserName := aUserName;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithApplication(const aApplication: string): IUDPSyslogAppenderConfigurator;
begin
  FApplication := aApplication;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithVersion(const aVersion: string): IUDPSyslogAppenderConfigurator;
begin
  FVersion := aVersion;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithProcID(const aProcID: string): IUDPSyslogAppenderConfigurator;
begin
  FProcID := aProcID;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IUDPSyslogAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TUDPSyslogAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProUDPSyslogAppender.Create(FHost, FPort, FHostName, FUserName, FApplication, FVersion, FProcID, False);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{$IFDEF CONSOLE}
{ TSimpleConsoleAppenderConfigurator }

function TSimpleConsoleAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): ISimpleConsoleAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TSimpleConsoleAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TLoggerProSimpleConsoleAppender.Create;
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;
{$ENDIF}

{ TVCLMemoAppenderConfigurator }

constructor TVCLMemoAppenderConfigurator.Create(aBuilder: TLoggerProBuilder; aMemo: TMemo);
begin
  inherited Create(aBuilder);
  FMemo := aMemo;
  FMaxLogLines := 100;
  FClearOnStartup := False;
end;

function TVCLMemoAppenderConfigurator.WithMaxLogLines(aMaxLogLines: Word): IVCLMemoAppenderConfigurator;
begin
  FMaxLogLines := aMaxLogLines;
  Result := Self;
end;

function TVCLMemoAppenderConfigurator.WithClearOnStartup(aValue: Boolean): IVCLMemoAppenderConfigurator;
begin
  FClearOnStartup := aValue;
  Result := Self;
end;

function TVCLMemoAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IVCLMemoAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TVCLMemoAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TVCLMemoLogAppender.Create(FMemo, FMaxLogLines, FClearOnStartup);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TVCLListBoxAppenderConfigurator }

constructor TVCLListBoxAppenderConfigurator.Create(aBuilder: TLoggerProBuilder; aListBox: TListBox);
begin
  inherited Create(aBuilder);
  FListBox := aListBox;
  FMaxLogLines := 500;
end;

function TVCLListBoxAppenderConfigurator.WithMaxLogLines(aMaxLogLines: Word): IVCLListBoxAppenderConfigurator;
begin
  FMaxLogLines := aMaxLogLines;
  Result := Self;
end;

function TVCLListBoxAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IVCLListBoxAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TVCLListBoxAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TVCLListBoxAppender.Create(FListBox, FMaxLogLines);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TVCLListViewAppenderConfigurator }

constructor TVCLListViewAppenderConfigurator.Create(aBuilder: TLoggerProBuilder; aListView: TListView);
begin
  inherited Create(aBuilder);
  FListView := aListView;
  FMaxLogLines := 500;
end;

function TVCLListViewAppenderConfigurator.WithMaxLogLines(aMaxLogLines: Word): IVCLListViewAppenderConfigurator;
begin
  FMaxLogLines := aMaxLogLines;
  Result := Self;
end;

function TVCLListViewAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IVCLListViewAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TVCLListViewAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  lAppender := TVCLListViewAppender.Create(FListView, FMaxLogLines);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ TFireDACAppenderConfigurator }

function TFireDACAppenderConfigurator.WithConnectionDefName(const aConnectionDefName: string): IFireDACAppenderConfigurator;
begin
  FConnectionDefName := aConnectionDefName;
  Result := Self;
end;

function TFireDACAppenderConfigurator.WithStoredProcName(const aStoredProcName: string): IFireDACAppenderConfigurator;
begin
  FStoredProcName := aStoredProcName;
  Result := Self;
end;

function TFireDACAppenderConfigurator.WithLogLevel(aLogLevel: TLogType): IFireDACAppenderConfigurator;
begin
  FLogLevel := aLogLevel;
  FLogLevelSet := True;
  Result := Self;
end;

function TFireDACAppenderConfigurator.Done: ILoggerProBuilder;
var
  lAppender: ILogAppender;
begin
  if FConnectionDefName.Trim.IsEmpty then
    raise ELoggerPro.Create('FireDAC appender requires a ConnectionDefName. Use WithConnectionDefName to set it.');
  if FStoredProcName.Trim.IsEmpty then
    raise ELoggerPro.Create('FireDAC appender requires a StoredProcName. Use WithStoredProcName to set it.');

  lAppender := TLoggerProDBAppenderFireDAC.Create(FConnectionDefName, FStoredProcName, nil);
  ApplyLogLevel(lAppender);
  FBuilder.InternalAddAppender(lAppender);
  Result := FBuilder;
end;

{ Helper function }

function LoggerProBuilder: ILoggerProBuilder;
begin
  Result := TLoggerProBuilder.Create;
end;

end.
