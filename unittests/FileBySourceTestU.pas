unit FileBySourceTestU;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFileBySourceTest = class
  private
    FTestFolder: string;
    procedure CleanupTestFolder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestBasicWriteCreatesSourceFolder;
    [Test]
    procedure TestMultipleSourcesSeparateFolders;
    [Test]
    procedure TestTagSeparation;
    [Test]
    procedure TestDefaultSourceWhenNoContext;
    [Test]
    procedure TestSizeRotation;
    [Test]
    procedure TestRetainDaysCleanup;
    [Test]
    procedure TestBuilderIntegration;
    [Test]
    procedure TestInlineSourceOverridesDefaultContext;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Rtti,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.FileBySourceAppender;

{ TFileBySourceTest }

procedure TFileBySourceTest.Setup;
begin
  FTestFolder := TPath.Combine(TPath.GetTempPath,
    'LoggerProTest_FileBySource_' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  TDirectory.CreateDirectory(FTestFolder);
end;

procedure TFileBySourceTest.TearDown;
begin
  CleanupTestFolder;
end;

procedure TFileBySourceTest.CleanupTestFolder;
begin
  if TDirectory.Exists(FTestFolder) then
  begin
    try
      TDirectory.Delete(FTestFolder, True);
    except
      // Ignore cleanup errors in tests
    end;
  end;
end;

procedure TFileBySourceTest.TestBasicWriteCreatesSourceFolder;
var
  lLog: ILogWriter;
  lSourceFolder: string;
  lFiles: TArray<string>;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .Done
    .Build;

  lLog.Info('Test message', 'ORDERS', [LogParam.S('source', 'ClientA')]);
  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  lSourceFolder := TPath.Combine(FTestFolder, 'ClientA');
  Assert.IsTrue(TDirectory.Exists(lSourceFolder),
    'Source folder ClientA should exist');

  lFiles := TDirectory.GetFiles(lSourceFolder, '*.log');
  Assert.AreEqual(1, Length(lFiles), 'Should have exactly 1 log file');
  Assert.IsTrue(TPath.GetFileName(lFiles[0]).StartsWith('ClientA.ORDERS.'),
    'File name should start with ClientA.ORDERS.');
end;

procedure TFileBySourceTest.TestMultipleSourcesSeparateFolders;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .Done
    .Build;

  lLog.Info('Message A', 'ORDERS', [LogParam.S('source', 'ClientA')]);
  lLog.Info('Message B', 'ORDERS', [LogParam.S('source', 'ClientB')]);
  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTestFolder, 'ClientA')),
    'ClientA folder should exist');
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTestFolder, 'ClientB')),
    'ClientB folder should exist');
end;

procedure TFileBySourceTest.TestTagSeparation;
var
  lLog: ILogWriter;
  lFiles: TArray<string>;
  lSourceFolder: string;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .Done
    .Build;

  lLog.Info('Order msg', 'ORDERS', [LogParam.S('source', 'ClientA')]);
  lLog.Info('Payment msg', 'PAYMENTS', [LogParam.S('source', 'ClientA')]);
  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  lSourceFolder := TPath.Combine(FTestFolder, 'ClientA');
  lFiles := TDirectory.GetFiles(lSourceFolder, '*.log');
  Assert.AreEqual(2, Length(lFiles),
    'Should have 2 log files (one per tag) in ClientA folder');
end;

procedure TFileBySourceTest.TestDefaultSourceWhenNoContext;
var
  lLog: ILogWriter;
  lDefaultFolder: string;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .WithDefaultSource('unknown')
      .Done
    .Build;

  lLog.Info('No source context');
  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  lDefaultFolder := TPath.Combine(FTestFolder, 'unknown');
  Assert.IsTrue(TDirectory.Exists(lDefaultFolder),
    'Default source folder "unknown" should exist');
end;

procedure TFileBySourceTest.TestSizeRotation;
var
  lLog: ILogWriter;
  lFiles: TArray<string>;
  lSourceFolder: string;
  I: Integer;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .WithMaxFileSizeInKB(1) // 1 KB - very small to trigger rotation
      .Done
    .Build;

  // Write enough data to exceed 1 KB
  for I := 1 to 50 do
    lLog.Info(Format('Size rotation test message number %d with padding to fill up space quickly', [I]),
      'TEST', [LogParam.S('source', 'SizeTest')]);

  Sleep(300);
  lLog.Shutdown;
  lLog := nil;

  lSourceFolder := TPath.Combine(FTestFolder, 'SizeTest');
  lFiles := TDirectory.GetFiles(lSourceFolder, '*.log');
  Assert.IsTrue(Length(lFiles) >= 2,
    Format('Should have at least 2 files after size rotation, got %d', [Length(lFiles)]));
end;

procedure TFileBySourceTest.TestRetainDaysCleanup;
var
  lLog: ILogWriter;
  lSourceFolder, lOldFile: string;
  lOldDate: string;
begin
  // Create a source folder with an old file
  lSourceFolder := TPath.Combine(FTestFolder, 'CleanTest');
  TDirectory.CreateDirectory(lSourceFolder);
  lOldDate := FormatDateTime('yyyymmdd', Date - 60); // 60 days ago
  lOldFile := TPath.Combine(lSourceFolder,
    Format('CleanTest.ORDERS.%s.00.log', [lOldDate]));
  TFile.WriteAllText(lOldFile, 'old log data');

  Assert.IsTrue(TFile.Exists(lOldFile), 'Old file should exist before cleanup');

  // Create logger with 7 day retention — cleanup runs on Setup
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .WithRetainDays(7)
      .Done
    .Build;

  lLog.Info('Current message', 'ORDERS', [LogParam.S('source', 'CleanTest')]);
  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  Assert.IsFalse(TFile.Exists(lOldFile),
    'Old file should have been deleted by retention cleanup');
end;

procedure TFileBySourceTest.TestBuilderIntegration;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .WithMaxFileSizeInKB(5000)
      .WithRetainDays(30)
      .WithDefaultSource('svc')
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created via builder');

  lLog.Info('Builder test', 'APP', [LogParam.S('source', 'TestClient')]);
  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTestFolder, 'TestClient')),
    'Source folder should exist after logging');
end;

procedure TFileBySourceTest.TestInlineSourceOverridesDefaultContext;
var
  lLog, lClientA: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToFileBySource
      .WithLogsFolder(FTestFolder)
      .Done
    .Build;

  // Create sub-logger with default source
  lClientA := lLog.WithDefaultContext([LogParam.S('source', 'ClientA')]);

  // This should go to ClientA
  lClientA.Info('Goes to ClientA', 'ORDERS');

  // This should go to Override (inline source wins because it comes after default)
  lClientA.Info('Goes to Override', 'ORDERS', [LogParam.S('source', 'Override')]);

  Sleep(200);
  lLog.Shutdown;
  lLog := nil;

  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTestFolder, 'ClientA')),
    'ClientA folder should exist');
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTestFolder, 'Override')),
    'Override folder should exist (inline source wins)');
end;

initialization
  TDUnitX.RegisterTestFixture(TFileBySourceTest);

end.
