unit ConfigTestU;

{ Tests for LoggerPro.Config (JSON-based builder). }

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.Config;

type
  [TestFixture]
  TConfigTest = class
  public
    [Test]
    procedure TestMinimalConsole;

    [Test]
    procedure TestConsoleWithAllOptions;

    [Test]
    procedure TestFileWithAllOptions;

    [Test]
    procedure TestMultipleAppenders;

    [Test]
    procedure TestGlobalMinimumLevel;

    [Test]
    procedure TestMemoryAppender;

    [Test]
    procedure TestHTMLFileAppender;

    [Test]
    procedure TestUnknownTypeRaises;

    [Test]
    procedure TestMalformedJSONRaises;

    [Test]
    procedure TestMissingTypeRaises;

    [Test]
    procedure TestMissingAppendersArrayRaises;

    [Test]
    procedure TestInvalidLogLevelRaises;

    [Test]
    procedure TestInvalidColorSchemeRaises;

    [Test]
    procedure TestCaseInsensitiveTypeName;

    [Test]
    procedure TestCustomAppenderTypeRegistration;

    [Test]
    procedure TestConfigEndToEnd;

    [Test]
    procedure TestConfigVersionV1Explicit;

    [Test]
    procedure TestConfigVersionMissingDefaultsToLatest;

    [Test]
    procedure TestConfigVersionTooNewRaises;

    [Test]
    procedure TestConfigVersionZeroRaises;

    [Test]
    procedure TestUnknownRootFieldRaises;

    [Test]
    procedure TestUnknownAppenderFieldRaises;

    [Test]
    procedure TestErrorMessageListsValidLogLevels;

    [Test]
    procedure TestErrorMessageListsValidColorSchemes;

    [Test]
    procedure TestErrorMessageListsValidRotationIntervals;

    [Test]
    procedure TestErrorMessageListsValidRootFields;

    [Test]
    procedure TestErrorMessageListsValidAppenderFields;

    [Test]
    procedure TestWebhookAPIKeyDefaultHeader;

    [Test]
    procedure TestWebhookAPIKeyQueryString;

    [Test]
    procedure TestWebhookAPIKeyCustomHeaderName;

    [Test]
    procedure TestWebhookAPIKeyInvalidLocationRaises;

    [Test]
    procedure TestExeWatchAutoRegisteredFromConfig;

    [Test]
    procedure TestExeWatchViaFluentWithExeWatch;

    [Test]
    procedure TestExeWatchViaImperativeFactory;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  LoggerPro.MemoryAppender,
  LoggerPro.WebhookAppender,
  LoggerPro.ExeWatchAppender;

{ TConfigTest }

procedure TConfigTest.TestMinimalConsole;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"Console"}]}');
  Assert.IsNotNull(Log, 'Logger should be created');
  Assert.AreEqual(1, Log.AppendersCount, 'Should have 1 appender');
  Log.Shutdown;
end;

procedure TConfigTest.TestConsoleWithAllOptions;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{' +
    '"type":"Console",' +
    '"minimumLevel":"Info",' +
    '"colors":true,' +
    '"colorScheme":"Midnight",' +
    '"prefix":"TEST",' +
    '"utf8Output":true' +
    '}]}');
  Assert.AreEqual(1, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestFileWithAllOptions;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{' +
    '"type":"File",' +
    '"minimumLevel":"Warning",' +
    '"logsFolder":"logs_test",' +
    '"fileBaseName":"myapp",' +
    '"maxBackupFiles":3,' +
    '"maxFileSizeInKB":500' +
    '}]}');
  Assert.AreEqual(1, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestMultipleAppenders;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[' +
    '{"type":"Console"},' +
    '{"type":"Memory","maxSize":100},' +
    '{"type":"OutputDebugString"}' +
    ']}');
  Assert.AreEqual(3, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestGlobalMinimumLevel;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"minimumLevel":"Warning","appenders":[{"type":"Memory"}]}');
  Assert.IsFalse(Log.IsDebugEnabled, 'Debug should be filtered');
  Assert.IsFalse(Log.IsInfoEnabled, 'Info should be filtered');
  Assert.IsTrue(Log.IsWarningEnabled, 'Warning should pass');
  Assert.IsTrue(Log.IsErrorEnabled, 'Error should pass');
  Log.Shutdown;
end;

procedure TConfigTest.TestMemoryAppender;
var
  Log: ILogWriter;
  lObj: TObject;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"Memory","maxSize":50}]}');
  Assert.AreEqual(1, Log.AppendersCount);
  // Verify the appender class (interface->object cast)
  lObj := Log.Appenders[0] as TObject;
  Assert.IsTrue(lObj is TLoggerProMemoryRingBufferAppender,
    'Factory must create a TLoggerProMemoryRingBufferAppender');
  Log.Shutdown;
end;

procedure TConfigTest.TestHTMLFileAppender;
var
  Log: ILogWriter;
  Folder, BaseName: string;
begin
  Folder := TPath.Combine(TPath.GetTempPath,
    'loggerpro_html_' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  BaseName := 'test';
  try
    Log := TLoggerProConfig.FromJSONString(
      '{"appenders":[{"type":"HTMLFile",' +
      '"logsFolder":"' + StringReplace(Folder, '\', '\\', [rfReplaceAll]) + '",' +
      '"fileBaseName":"' + BaseName + '",' +
      '"title":"T"}]}');
    Log.Info('hello', 'T');
    Log.Shutdown;
    Log := nil;
    Assert.IsTrue(TDirectory.Exists(Folder), 'Logs folder should be created');
    Assert.IsTrue(Length(TDirectory.GetFiles(Folder, BaseName + '.*.html')) > 0,
      'An HTML file should exist in the folder');
  finally
    if TDirectory.Exists(Folder) then
      TDirectory.Delete(Folder, True);
  end;
end;

procedure TConfigTest.TestUnknownTypeRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"appenders":[{"type":"NotAThing"}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestMalformedJSONRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString('{not json');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestMissingTypeRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"appenders":[{"colors":true}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestMissingAppendersArrayRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString('{}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestInvalidLogLevelRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"minimumLevel":"Chaotic","appenders":[{"type":"Memory"}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestInvalidColorSchemeRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"appenders":[{"type":"Console","colorScheme":"NotAScheme"}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestCaseInsensitiveTypeName;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"CONSOLE"},{"type":"memory"},{"type":"HtMlFiLe","fileBaseName":"a"}]}');
  Assert.AreEqual(3, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestCustomAppenderTypeRegistration;
var
  Log: ILogWriter;
  CustomWasCalled: Boolean;
begin
  CustomWasCalled := False;
  TLoggerProConfig.RegisterAppenderType('CustomType',
    procedure(const aBuilder: ILoggerProBuilder; const aConfig: TJSONObject)
    begin
      CustomWasCalled := True;
      // Register a built-in memory appender as placeholder
      aBuilder.WriteToMemory.Done;
    end,
    []); // no fields accepted besides "type"

  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"CustomType"}]}');
  Assert.IsTrue(CustomWasCalled, 'Custom factory should have been invoked');
  Assert.AreEqual(1, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestConfigEndToEnd;
var
  Log: ILogWriter;
  lObj: TObject;
  Appender: TLoggerProMemoryRingBufferAppender;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{' +
    '"minimumLevel":"Info",' +
    '"defaultTag":"main",' +
    '"appenders":[{"type":"Memory","maxSize":100,"minimumLevel":"Info"}]' +
    '}');
  Log.Debug('should be filtered', 'main');
  Log.Info('should pass', 'main');
  Log.Warn('should pass too', 'main');
  Log.Shutdown;

  lObj := Log.Appenders[0] as TObject;
  Appender := lObj as TLoggerProMemoryRingBufferAppender;
  Assert.AreEqual(2, Appender.Count, 'Exactly 2 messages expected after filter');
end;

procedure TConfigTest.TestConfigVersionV1Explicit;
var
  Log: ILogWriter;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"configVersion":1,"appenders":[{"type":"Memory"}]}');
  Assert.AreEqual(1, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestConfigVersionMissingDefaultsToLatest;
var
  Log: ILogWriter;
begin
  // No configVersion field at all -> should parse using latest known schema.
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"Memory"}]}');
  Assert.AreEqual(1, Log.AppendersCount);
  Log.Shutdown;
end;

procedure TConfigTest.TestConfigVersionTooNewRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"configVersion":9999,"appenders":[{"type":"Memory"}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestConfigVersionZeroRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"configVersion":0,"appenders":[{"type":"Memory"}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestUnknownRootFieldRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"defaultag":"oops","appenders":[{"type":"Memory"}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestUnknownAppenderFieldRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TLoggerProConfig.FromJSONString(
        '{"appenders":[{"type":"Console","colour":true}]}');
    end, ELoggerProConfigError, '');
end;

procedure TConfigTest.TestErrorMessageListsValidLogLevels;
var
  lMsg: string;
begin
  lMsg := '';
  try
    TLoggerProConfig.FromJSONString(
      '{"minimumLevel":"Chaotic","appenders":[{"type":"Memory"}]}');
  except
    on E: ELoggerProConfigError do lMsg := E.Message;
  end;
  Assert.Contains(lMsg, 'Debug', False, 'Error message should list Debug');
  Assert.Contains(lMsg, 'Info', False, 'Error message should list Info');
  Assert.Contains(lMsg, 'Warning', False, 'Error message should list Warning');
  Assert.Contains(lMsg, 'Error', False, 'Error message should list Error');
  Assert.Contains(lMsg, 'Fatal', False, 'Error message should list Fatal');
end;

procedure TConfigTest.TestErrorMessageListsValidColorSchemes;
var
  lMsg: string;
begin
  lMsg := '';
  try
    TLoggerProConfig.FromJSONString(
      '{"appenders":[{"type":"Console","colorScheme":"NotAScheme"}]}');
  except
    on E: ELoggerProConfigError do lMsg := E.Message;
  end;
  Assert.Contains(lMsg, 'Midnight', False);
  Assert.Contains(lMsg, 'Nord', False);
  Assert.Contains(lMsg, 'Matrix', False);
  Assert.Contains(lMsg, 'GinBadge', False);
end;

procedure TConfigTest.TestErrorMessageListsValidRotationIntervals;
var
  lMsg: string;
begin
  lMsg := '';
  try
    TLoggerProConfig.FromJSONString(
      '{"appenders":[{"type":"TimeRotatingFile","interval":"Yearly"}]}');
  except
    on E: ELoggerProConfigError do lMsg := E.Message;
  end;
  Assert.Contains(lMsg, 'Hourly', False);
  Assert.Contains(lMsg, 'Daily', False);
  Assert.Contains(lMsg, 'Weekly', False);
  Assert.Contains(lMsg, 'Monthly', False);
end;

procedure TConfigTest.TestErrorMessageListsValidRootFields;
var
  lMsg: string;
begin
  lMsg := '';
  try
    TLoggerProConfig.FromJSONString(
      '{"typo":"oops","appenders":[{"type":"Memory"}]}');
  except
    on E: ELoggerProConfigError do lMsg := E.Message;
  end;
  Assert.Contains(lMsg, 'configVersion', False);
  Assert.Contains(lMsg, 'minimumLevel', False);
  Assert.Contains(lMsg, 'defaultTag', False);
  Assert.Contains(lMsg, 'appenders', False);
end;

procedure TConfigTest.TestErrorMessageListsValidAppenderFields;
var
  lMsg: string;
begin
  lMsg := '';
  try
    TLoggerProConfig.FromJSONString(
      '{"appenders":[{"type":"Console","wrongField":123}]}');
  except
    on E: ELoggerProConfigError do lMsg := E.Message;
  end;
  Assert.Contains(lMsg, 'colors', False);
  Assert.Contains(lMsg, 'colorScheme', False);
  Assert.Contains(lMsg, 'prefix', False);
  Assert.Contains(lMsg, 'utf8Output', False);
end;

function GetWebhookAppender(const aLog: ILogWriter): TLoggerProWebhookAppender;
var
  i: Integer;
  lObj: TObject;
begin
  for i := 0 to aLog.AppendersCount - 1 do
  begin
    lObj := aLog.Appenders[i] as TObject;
    if lObj is TLoggerProWebhookAppender then
      Exit(TLoggerProWebhookAppender(lObj));
  end;
  Result := nil;
end;

procedure TConfigTest.TestWebhookAPIKeyDefaultHeader;
var
  Log: ILogWriter;
  Http: TLoggerProWebhookAppender;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"Webhook","url":"http://example/","apiKey":"secret123"}]}');
  Http := GetWebhookAppender(Log);
  Assert.IsNotNull(Http);
  Assert.AreEqual('secret123', Http.APIKey);
  Assert.AreEqual('X-API-Key', Http.APIKeyName, 'Default header name');
  Assert.IsTrue(Http.APIKeyLocation = TWebhookAPIKeyLocation.Header, 'Default location is Header');
  Log.Shutdown;
end;

procedure TConfigTest.TestWebhookAPIKeyQueryString;
var
  Log: ILogWriter;
  Http: TLoggerProWebhookAppender;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"Webhook","url":"http://example/","apiKey":"k","apiKeyLocation":"QueryString"}]}');
  Http := GetWebhookAppender(Log);
  Assert.IsTrue(Http.APIKeyLocation = TWebhookAPIKeyLocation.QueryString);
  Assert.AreEqual('api_key', Http.APIKeyName, 'Default query param name');
  Log.Shutdown;
end;

procedure TConfigTest.TestWebhookAPIKeyCustomHeaderName;
var
  Log: ILogWriter;
  Http: TLoggerProWebhookAppender;
begin
  Log := TLoggerProConfig.FromJSONString(
    '{"appenders":[{"type":"Webhook","url":"http://example/",' +
    '"apiKey":"k","apiKeyLocation":"Header","apiKeyName":"Authorization"}]}');
  Http := GetWebhookAppender(Log);
  Assert.AreEqual('Authorization', Http.APIKeyName);
  Log.Shutdown;
end;

procedure TConfigTest.TestWebhookAPIKeyInvalidLocationRaises;
var
  lMsg: string;
begin
  lMsg := '';
  try
    TLoggerProConfig.FromJSONString(
      '{"appenders":[{"type":"Webhook","url":"http://x/","apiKey":"k","apiKeyLocation":"Body"}]}');
  except
    on E: ELoggerProConfigError do lMsg := E.Message;
  end;
  Assert.Contains(lMsg, 'Header', False, 'Should list Header as valid');
  Assert.Contains(lMsg, 'QueryString', False, 'Should list QueryString as valid');
end;

procedure TConfigTest.TestExeWatchAutoRegisteredFromConfig;
var
  Log: ILogWriter;
  lObj: TObject;
  A: TLoggerProExeWatchAppender;
begin
  // Just uses'ing LoggerPro.ExeWatchAppender must register the "ExeWatch"
  // type with LoggerPro.Config. The presence of this test in a unit that
  // uses'es both modules is enough to verify the registration path.
  // NOTE: Logger is NOT built here - Build() would start the appender
  // thread and call InitializeExeWatch, which tries to contact the real
  // ExeWatch server. We only verify parsing + field wiring.
  Log := nil;
  try
    Log := TLoggerProConfig.FromJSONString(
      '{"appenders":[{' +
      '"type":"ExeWatch",' +
      '"apiKey":"ew_win_test_key",' +
      '"customerId":"SampleCustomer",' +
      '"appVersion":"1.0.0",' +
      '"anonymizeDeviceId":true' +
      '}]}');
    Assert.AreEqual(1, Log.AppendersCount);
    lObj := Log.Appenders[0] as TObject;
    Assert.IsTrue(lObj is TLoggerProExeWatchAppender, 'Expected TLoggerProExeWatchAppender');
    A := TLoggerProExeWatchAppender(lObj);
    Assert.AreEqual('ew_win_test_key', A.APIKey);
    Assert.AreEqual('SampleCustomer', A.CustomerId);
    Assert.AreEqual('1.0.0', A.AppVersion);
    Assert.IsTrue(A.AnonymizeDeviceId);
  finally
    if Log <> nil then Log.Shutdown;
  end;
end;

procedure TConfigTest.TestExeWatchViaFluentWithExeWatch;
var
  Log: ILogWriter;
  lObj: TObject;
  A: TLoggerProExeWatchAppender;
begin
  Log := WithExeWatch(LoggerProBuilder)
    .WithAPIKey('ew_win_test_key')
    .WithCustomerId('SampleCustomer')
    .WithAppVersion('2.0.0')
    .Done
    .Build;
  try
    lObj := Log.Appenders[0] as TObject;
    Assert.IsTrue(lObj is TLoggerProExeWatchAppender);
    A := TLoggerProExeWatchAppender(lObj);
    Assert.AreEqual('ew_win_test_key', A.APIKey);
    Assert.AreEqual('SampleCustomer', A.CustomerId);
    Assert.AreEqual('2.0.0', A.AppVersion);
  finally
    Log.Shutdown;
  end;
end;

procedure TConfigTest.TestExeWatchViaImperativeFactory;
var
  Log: ILogWriter;
  lObj: TObject;
begin
  Log := LoggerProBuilder
    .WriteToAppender(NewExeWatchAppender('ew_win_test_key', 'SampleCustomer'))
    .Build;
  try
    lObj := Log.Appenders[0] as TObject;
    Assert.IsTrue(lObj is TLoggerProExeWatchAppender);
  finally
    Log.Shutdown;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TConfigTest);

end.
