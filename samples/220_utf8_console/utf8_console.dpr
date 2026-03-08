program utf8_console;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerProConfig in 'LoggerProConfig.pas';

begin
  try
    Log.Info('LoggerPro 2.0 - UTF-8 Console Output Demo');
    Log.Info('==========================================');
    Log.Info('The Modern, Async, Pluggable Logging Framework for Delphi');
    Log.Info('Cross-Platform: Windows, Linux, macOS, Android, iOS');
    Log.Debug('Async by Design - Non-blocking logging with zero impact on performance');
    Log.Info('20+ Built-in Appenders - File, Console, HTTP, Syslog, ElasticSearch, and more');

    // Unicode: Western European
    Log.Info('German: Umlaute '#$00C4' '#$00D6' '#$00DC' '#$00DF' - '#$00E4#$00F6#$00FC);
    Log.Info('French: '#$00E9' '#$00E8' '#$00EA' '#$00EB' - L'#$00E9't'#$00E9' est arriv'#$00E9'e');
    Log.Info('Italian: Citt'#$00E0' '#$00E8' bella, pi'#$00F9' che mai');

    // Unicode: CJK and other scripts
    Log.Warn('Japanese: '#$65E5#$672C#$8A9E#$30C6#$30B9#$30C8);
    Log.Warn('Korean: '#$D55C#$AD6D#$C5B4);
    Log.Warn('Russian: '#$041F#$0440#$0438#$0432#$0435#$0442);

    // Unicode: Emoji (surrogate pairs)
    Log.Error('Emoji: '#$D83D#$DE80' '#$D83D#$DCC3' '#$2705' '#$26A1' '#$D83D#$DD25);

    // Structured logging with Unicode context
    Log.Info('Order completed', 'ORDERS', [
      LogParam.S('customer', 'M'#$00FC'ller'),
      LogParam.S('city', 'Z'#$00FC'rich'),
      LogParam.F('total', 299.99)
    ]);

    Log.Debug('All UTF-8 tests completed successfully');

{$IFDEF MSWINDOWS}
    WriteLn;
    WriteLn('Press Enter to exit...');
    ReadLn;
{$ENDIF}
  except
    on E: Exception do
    begin
      Log.LogException(E, 'Unhandled exception');
      Writeln(E.ClassName, ': ', E.Message);
    end;
  end;
end.
