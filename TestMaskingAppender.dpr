program TestMaskingAppender;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  LoggerPro,
  LoggerPro.ConsoleAppender,
  LoggerPro.MaskingAppender,
  LoggerPro.Builder;

var
  Log: ILogWriter;

begin
  try
    // 创建带有脱敏功能的日志记录器
    Log := LoggerProBuilder
      .WithDefaultLogLevel(TLogType.Debug)
      .WriteToConsole
        .WithMasking
        .Done
      .Build;

    // 测试手机号脱敏
    Log.Debug('用户登录，手机号：13812345678');
    Log.Info('新用户注册，手机号：15987654321');
    
    // 测试密码脱敏
    Log.Warn('登录失败，用户名：admin，password=mypassword123');
    Log.Error('认证错误，password=admin123&username=test');
    
    // 测试混合内容脱敏
    Log.Info('用户信息：手机号=18611112222，password=userpass456');
    
    WriteLn('脱敏测试完成，请查看上面的日志输出');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.