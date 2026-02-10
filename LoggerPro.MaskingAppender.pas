// *************************************************************************** }
//
// LoggerPro
//
// Copyright (c) 2010-2026 Daniele Teti
//
// https://github.com/danieleteti/loggerpro
//
// ***************************************************************************

unit LoggerPro.MaskingAppender;

interface

uses
  System.Classes,
  System.SysUtils,
  System.RegularExpressions,
  LoggerPro;

type
  /// <summary>
  /// 脱敏日志装饰器，用于对日志正文进行脱敏处理
  /// 隐藏 11 位中国手机号中间 4 位（如 138****5678）
  /// 隐藏 password=xxx 后面的明文值
  /// </summary>
  TLoggerProMaskingAppender = class(TLoggerProAppenderBase)
  private
    FInnerAppender: ILogAppender;
    FPhoneRegex: TRegEx;
    FPasswordRegex: TRegEx;
  protected
    function MaskPhoneNumber(const AMessage: string): string;
    function MaskPassword(const AMessage: string): string;
    function MaskMessage(const AMessage: string): string;
  public
    /// <summary>
    /// 创建脱敏装饰器实例
    /// </summary>
    /// <param name="AInnerAppender">被装饰的内部日志追加器</param>
    constructor Create(AInnerAppender: ILogAppender); reintroduce; virtual;
    
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
    procedure SetEnabled(const Value: Boolean); override;
    function IsEnabled: Boolean; override;
    procedure SetLogLevel(const Value: TLogType); override;
    function GetLogLevel: TLogType; override;
    procedure TryToRestart(var Restarted: Boolean); override;
    procedure SetLastErrorTimeStamp(const LastErrorTimeStamp: TDateTime); override;
    function GetLastErrorTimeStamp: TDateTime; override;
  end;

implementation

{ TLoggerProMaskingAppender }

constructor TLoggerProMaskingAppender.Create(AInnerAppender: ILogAppender);
begin
  inherited Create;
  FInnerAppender := AInnerAppender;
  
  // 预编译正则表达式，避免在高并发日志下产生性能瓶颈
  // 中国手机号正则：11位数字，以1开头，第二位是3-9
  FPhoneRegex := TRegEx.Create('(\b1[3-9]\d{1})(\d{4})(\d{4}\b)', [roCompiled]);
  // 密码参数正则：password=后面的值
  FPasswordRegex := TRegEx.Create('(password=)([^\s&]*)', [roCompiled, roIgnoreCase]);
end;

function TLoggerProMaskingAppender.MaskPhoneNumber(const AMessage: string): string;
begin
  // 使用预编译的正则表达式替换手机号中间4位为****
  Result := FPhoneRegex.Replace(AMessage, '$1****$3');
end;

function TLoggerProMaskingAppender.MaskPassword(const AMessage: string): string;
begin
  // 使用预编译的正则表达式替换password=后面的值为****
  Result := FPasswordRegex.Replace(AMessage, '$1****');
end;

function TLoggerProMaskingAppender.MaskMessage(const AMessage: string): string;
begin
  Result := AMessage;
  
  // 先处理密码脱敏，再处理手机号脱敏
  Result := MaskPassword(Result);
  Result := MaskPhoneNumber(Result);
end;

procedure TLoggerProMaskingAppender.Setup;
begin
  if Assigned(FInnerAppender) then
    FInnerAppender.Setup;
end;

procedure TLoggerProMaskingAppender.TearDown;
begin
  if Assigned(FInnerAppender) then
    FInnerAppender.TearDown;
end;

procedure TLoggerProMaskingAppender.WriteLog(const aLogItem: TLogItem);
var
  LMaskedLogItem: TLogItem;
  LMaskedMessage: string;
begin
  if not Assigned(FInnerAppender) then
    Exit;
    
  // 对日志消息进行脱敏处理
  LMaskedMessage := MaskMessage(aLogItem.LogMessage);
  
  // 创建脱敏后的日志项
  LMaskedLogItem := TLogItem.Create(
    aLogItem.LogType,
    LMaskedMessage,
    aLogItem.LogTag,
    aLogItem.TimeStamp,
    aLogItem.ThreadID,
    aLogItem.Context
  );
  
  try
    // 将脱敏后的日志项传递给内部追加器
    FInnerAppender.WriteLog(LMaskedLogItem);
  finally
    LMaskedLogItem.Free;
  end;
end;

procedure TLoggerProMaskingAppender.SetEnabled(const Value: Boolean);
begin
  if Assigned(FInnerAppender) then
    FInnerAppender.SetEnabled(Value);
end;

function TLoggerProMaskingAppender.IsEnabled: Boolean;
begin
  if Assigned(FInnerAppender) then
    Result := FInnerAppender.IsEnabled
  else
    Result := False;
end;

procedure TLoggerProMaskingAppender.SetLogLevel(const Value: TLogType);
begin
  if Assigned(FInnerAppender) then
    FInnerAppender.SetLogLevel(Value);
end;

function TLoggerProMaskingAppender.GetLogLevel: TLogType;
begin
  if Assigned(FInnerAppender) then
    Result := FInnerAppender.GetLogLevel
  else
    Result := TLogType.Debug;
end;

procedure TLoggerProMaskingAppender.TryToRestart(var Restarted: Boolean);
begin
  if Assigned(FInnerAppender) then
    FInnerAppender.TryToRestart(Restarted)
  else
    Restarted := False;
end;

procedure TLoggerProMaskingAppender.SetLastErrorTimeStamp(const LastErrorTimeStamp: TDateTime);
begin
  if Assigned(FInnerAppender) then
    FInnerAppender.SetLastErrorTimeStamp(LastErrorTimeStamp);
end;

function TLoggerProMaskingAppender.GetLastErrorTimeStamp: TDateTime;
begin
  if Assigned(FInnerAppender) then
    Result := FInnerAppender.GetLastErrorTimeStamp
  else
    Result := 0;
end;

end.