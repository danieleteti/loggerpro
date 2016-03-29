unit LoggerProTestU;

interface

uses
  DUnitX.TestFramework, LoggerPro;

type

  [TestFixture]
  TLoggerProTest = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestTLogItemClone;
    [Test]
    [TestCase('Type DEBUG', '0,DEBUG')]
    [TestCase('Type INFO', '1,INFO')]
    [TestCase('Type WARN', '2,WARNING')]
    [TestCase('Type ERROR', '3,ERROR')]
    procedure TestTLogItemTypeAsString(aLogType: Byte; aExpected: String);
    // Test with TestCase Atribute to supply parameters.
    [Test]
    [TestCase('TestA', '1,2')]
    [TestCase('TestB', '3,4')]
    procedure Test2(const AValue1: Integer; const AValue2: Integer);
  end;

implementation

function LogItemAreEquals(A, B: TLogItem): Boolean;
begin
  Assert.AreEqual(A.LogType, B.LogType, 'LogType is different');
  Assert.AreEqual(A.LogMessage, B.LogMessage, 'LogMessage is different');
  Assert.AreEqual(A.LogTag, B.LogTag, 'LogTag is different');
  Assert.AreEqual(A.TimeStamp, B.TimeStamp, 'TimeStamp is different');
  Assert.AreEqual(A.ThreadID, B.ThreadID, 'ThreadID is different');
  Assert.AreEqual(A.RetriesCount, B.RetriesCount, 'RetriesCount is different');
end;

procedure TLoggerProTest.Setup;
begin
end;

procedure TLoggerProTest.TearDown;
begin
end;

procedure TLoggerProTest.Test2(const AValue1: Integer; const AValue2: Integer);
begin
end;

procedure TLoggerProTest.TestTLogItemClone;
var
  lLogItem: TLogItem;
  lClonedLogItem: TLogItem;
begin
  lLogItem := TLogItem.Create(TLogType.Debug, 'message', 'tag', 1);
  try
    lClonedLogItem := lLogItem.Clone;
    try
      LogItemAreEquals(lLogItem, lClonedLogItem);
    finally
      lClonedLogItem.Free;
    end;
  finally
    lLogItem.Free;
  end;
end;

procedure TLoggerProTest.TestTLogItemTypeAsString(aLogType: Byte;
  aExpected: String);
var
  lLogItem: TLogItem;
begin
  lLogItem := TLogItem.Create(TLogType(aLogType), 'message', 'tag', 1);
  try
    Assert.AreEqual(aExpected, lLogItem.LogTypeAsString);
  finally
    lLogItem.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TLoggerProTest);

end.
