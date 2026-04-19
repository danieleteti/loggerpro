unit LogFmtRendererTestU;

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  LoggerPro.Renderers,
  System.Rtti,
  System.SysUtils,
  System.Classes;

type
  [TestFixture]
  TLogFmtRendererTest = class
  private
    FRenderer: ILogItemRenderer;
    function RenderItem(const aMsg, aTag: string; const aContext: LogParams = nil): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // Base output
    [Test]
    procedure TestRendersBaseFields;

    // Value escaping
    [Test]
    procedure TestBareValueHasNoQuotes;
    [Test]
    procedure TestValueWithSpaceIsQuoted;
    [Test]
    procedure TestValueWithEqualsIsQuoted;
    [Test]
    procedure TestEmptyValueIsQuoted;
    [Test]
    procedure TestDoubleQuoteEscapedAsBackslashQuote;
    [Test]
    procedure TestBackslashEscapedAsDoubleBackslash;
    [Test]
    procedure TestNewlineEscaped;
    [Test]
    procedure TestCarriageReturnEscaped;
    [Test]
    procedure TestTabEscaped;
    [Test]
    procedure TestControlCharacterEscaped;

    // Tag handling
    [Test]
    procedure TestTagWithSpaceIsQuoted;

    // Key sanitization
    [Test]
    procedure TestContextKeyWithSpaceIsSanitized;
    [Test]
    procedure TestContextKeyAllowsDotAndDash;

    // Context types
    [Test]
    procedure TestContextIntegerRendersBare;
    [Test]
    procedure TestContextBooleanLowercase;
    [Test]
    procedure TestContextFloatUsesDotDecimal;
    [Test]
    procedure TestContextStringWithSpaceIsQuoted;

    // Separator
    [Test]
    procedure TestPairsSeparatedBySingleSpace;
  end;

implementation

uses
  System.DateUtils,
  System.StrUtils;

{ TLogFmtRendererTest }

procedure TLogFmtRendererTest.Setup;
begin
  FRenderer := TLogItemRendererLogFmt.Create;
  FRenderer.Setup;
end;

procedure TLogFmtRendererTest.TearDown;
begin
  FRenderer.TearDown;
  FRenderer := nil;
end;

function TLogFmtRendererTest.RenderItem(const aMsg, aTag: string;
  const aContext: LogParams): string;
var
  lItem: TLogItem;
begin
  lItem := TLogItem.Create(TLogType.Info, aMsg, aTag, aContext);
  try
    Result := FRenderer.RenderLogItem(lItem);
  finally
    lItem.Free;
  end;
end;

procedure TLogFmtRendererTest.TestRendersBaseFields;
var
  lOut: string;
begin
  lOut := RenderItem('hello', 'APP');
  Assert.Contains(lOut, 'time=');
  Assert.Contains(lOut, 'threadid=');
  Assert.Contains(lOut, 'type=INFO');
  Assert.Contains(lOut, 'msg=hello');
  Assert.Contains(lOut, 'tag=APP');
end;

procedure TLogFmtRendererTest.TestBareValueHasNoQuotes;
var
  lOut: string;
begin
  lOut := RenderItem('hello', 'APP');
  Assert.Contains(lOut, 'msg=hello ');
  Assert.DoesNotContain(lOut, 'msg="hello"');
end;

procedure TLogFmtRendererTest.TestValueWithSpaceIsQuoted;
var
  lOut: string;
begin
  lOut := RenderItem('hello world', 'APP');
  Assert.Contains(lOut, 'msg="hello world"');
end;

procedure TLogFmtRendererTest.TestValueWithEqualsIsQuoted;
var
  lOut: string;
begin
  lOut := RenderItem('a=b', 'APP');
  Assert.Contains(lOut, 'msg="a=b"');
end;

procedure TLogFmtRendererTest.TestEmptyValueIsQuoted;
var
  lOut: string;
begin
  lOut := RenderItem('hello', '');
  Assert.Contains(lOut, 'tag=""');
end;

procedure TLogFmtRendererTest.TestDoubleQuoteEscapedAsBackslashQuote;
var
  lOut: string;
begin
  lOut := RenderItem('say "hi"', 'APP');
  // Expect \"  (backslash + quote), NOT Delphi's ""
  Assert.Contains(lOut, 'msg="say \"hi\""');
  Assert.DoesNotContain(lOut, 'say ""hi""');
end;

procedure TLogFmtRendererTest.TestBackslashEscapedAsDoubleBackslash;
var
  lOut: string;
begin
  lOut := RenderItem('C:\path', 'APP');
  Assert.Contains(lOut, 'msg="C:\\path"');
end;

procedure TLogFmtRendererTest.TestNewlineEscaped;
var
  lOut: string;
begin
  lOut := RenderItem('line1'#10'line2', 'APP');
  Assert.Contains(lOut, 'msg="line1\nline2"');
  // No raw newline in output
  Assert.IsFalse(lOut.Contains(#10), 'output must be single-line');
end;

procedure TLogFmtRendererTest.TestCarriageReturnEscaped;
var
  lOut: string;
begin
  lOut := RenderItem('a'#13'b', 'APP');
  Assert.Contains(lOut, 'msg="a\rb"');
  Assert.IsFalse(lOut.Contains(#13), 'output must not contain raw CR');
end;

procedure TLogFmtRendererTest.TestTabEscaped;
var
  lOut: string;
begin
  lOut := RenderItem('a'#9'b', 'APP');
  Assert.Contains(lOut, 'msg="a\tb"');
end;

procedure TLogFmtRendererTest.TestControlCharacterEscaped;
var
  lOut: string;
begin
  lOut := RenderItem('x'#1'y', 'APP');
  Assert.Contains(lOut, '\u0001');
end;

procedure TLogFmtRendererTest.TestTagWithSpaceIsQuoted;
var
  lOut: string;
begin
  lOut := RenderItem('ok', 'my tag');
  Assert.Contains(lOut, 'tag="my tag"');
end;

procedure TLogFmtRendererTest.TestContextKeyWithSpaceIsSanitized;
var
  lCtx: LogParams;
  lOut: string;
begin
  lCtx := [LogParam.S('user name', 'alice')];
  lOut := RenderItem('ok', 'APP', lCtx);
  Assert.Contains(lOut, 'user_name=alice');
  Assert.DoesNotContain(lOut, 'user name=');
end;

procedure TLogFmtRendererTest.TestContextKeyAllowsDotAndDash;
var
  lCtx: LogParams;
  lOut: string;
begin
  lCtx := [LogParam.S('http.user-agent', 'Mozilla')];
  lOut := RenderItem('ok', 'APP', lCtx);
  Assert.Contains(lOut, 'http.user-agent=Mozilla');
end;

procedure TLogFmtRendererTest.TestContextIntegerRendersBare;
var
  lCtx: LogParams;
  lOut: string;
begin
  lCtx := [LogParam.I('count', 42)];
  lOut := RenderItem('ok', 'APP', lCtx);
  Assert.Contains(lOut, 'count=42');
  Assert.DoesNotContain(lOut, 'count="42"');
end;

procedure TLogFmtRendererTest.TestContextBooleanLowercase;
var
  lCtx: LogParams;
  lOut: string;
begin
  lCtx := [LogParam.B('ok', True), LogParam.B('done', False)];
  lOut := RenderItem('x', 'APP', lCtx);
  Assert.Contains(lOut, 'ok=true');
  Assert.Contains(lOut, 'done=false');
end;

procedure TLogFmtRendererTest.TestContextFloatUsesDotDecimal;
var
  lCtx: LogParams;
  lOut: string;
begin
  lCtx := [LogParam.F('price', 3.14)];
  lOut := RenderItem('x', 'APP', lCtx);
  // Must use '.' independent of OS locale (invariant settings)
  Assert.Contains(lOut, 'price=3.14');
  Assert.DoesNotContain(lOut, 'price=3,14');
end;

procedure TLogFmtRendererTest.TestContextStringWithSpaceIsQuoted;
var
  lCtx: LogParams;
  lOut: string;
begin
  lCtx := [LogParam.S('name', 'John Doe')];
  lOut := RenderItem('x', 'APP', lCtx);
  Assert.Contains(lOut, 'name="John Doe"');
end;

procedure TLogFmtRendererTest.TestPairsSeparatedBySingleSpace;
var
  lOut: string;
begin
  lOut := RenderItem('m', 't');
  // No double spaces anywhere
  Assert.DoesNotContain(lOut, '  ');
end;

initialization
  TDUnitX.RegisterTestFixture(TLogFmtRendererTest);

end.
