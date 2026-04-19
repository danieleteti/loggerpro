program exewatch_appender;

{$APPTYPE CONSOLE}

(*
  ExeWatch appender sample - routes LoggerPro log items to the ExeWatch
  cloud (https://exewatch.com) via the official Delphi SDK.

  Three integration modes demonstrated below (pick ONE; the others are
  kept commented out for reference):

    1) Imperative                 - one-liner for scripts / quick bootstraps
    2) Fluent builder             - idiomatic LoggerPro 2.x style
    3) JSON config file           - reshape the logger at deploy time

  The unit LoggerPro.ExeWatchAppender lives OUTSIDE the LoggerPro runtime
  package: the SDK is a third-party dependency, so only projects that
  actually want ExeWatch pick it up by adding the .pas + the SDK search
  path. Simply adding the unit to the `uses` clause (or via JSON) enables
  the integration.

  Prerequisites:
    - Register at https://exewatch.com and grab an API key + customer id
    - Place the ExeWatch SDK (ExeWatchSDKv1.pas) on the compiler search
      path. This sample expects it at C:\dev\exewatchsamples\DelphiCommons.
    - Replace 'ew_win_DEMO_XXXX_REPLACE_ME' with your real key.

  What the SDK does:
    - Buffers events locally, ships them to the cloud asynchronously
    - Collects breadcrumbs, timings, user identity, periodic metrics
      (the appender only sends the LoggerPro log stream; for the richer
      SDK features, call EW.* directly alongside LoggerPro)
*)

uses
  System.SysUtils,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.ExeWatchAppender;

const
  // >>> Replace these with your real credentials from https://exewatch.com
  EXEWATCH_API_KEY     = 'ew_win_U9DDSZs1GPRgq_Mkyz_5R4EIzlpQ-RdDdr0ooeHXbrY';
  EXEWATCH_CUSTOMER_ID = 'SampleCustomer';
  APP_VERSION          = '1.0.0';

var
  Log: ILogWriter;
  i: Integer;

begin
  try
    // -----------------------------------------------------------------
    // Mode 1) Imperative factory. Lowest friction when values are
    // already in variables / config objects.
    // -----------------------------------------------------------------
    // Log := LoggerProBuilder
    //   .WriteToAppender(NewExeWatchAppender(
    //     EXEWATCH_API_KEY, EXEWATCH_CUSTOMER_ID, APP_VERSION))
    //   .WriteToConsole.WithColors.Done
    //   .Build;

    // -----------------------------------------------------------------
    // Mode 2) Fluent builder. Recommended default.
    // -----------------------------------------------------------------
    Log := WithExeWatch(LoggerProBuilder)
        .WithAPIKey(EXEWATCH_API_KEY)
        .WithCustomerId(EXEWATCH_CUSTOMER_ID)
        .WithAppVersion(APP_VERSION)
        .WithAnonymizeDeviceId(False) // True = GDPR-friendly, per-install ID
        .Done
      .WriteToConsole.WithColors.Done  // also mirror to the console
      .WithDefaultTag('DEMO')
      .Build;

    // -----------------------------------------------------------------
    // Mode 3) JSON config (alternative). See loggerpro.json next to the
    // EXE. With that file, the entire block above collapses to:
    //
    //   Log := LoggerProFromJSONFile('loggerpro.json');
    //
    // The ExeWatch factory auto-registers from
    // LoggerPro.ExeWatchAppender's `initialization` section, so just
    // `uses LoggerPro.ExeWatchAppender` is enough for the JSON to
    // resolve the "ExeWatch" type.
    // -----------------------------------------------------------------

    Log.Info('ExeWatch sample started', 'BOOT');
    Log.Debug('Build config / environment / ...', 'BOOT');

    // Simulate a short work cycle - these show up both on the console
    // and in the ExeWatch dashboard (under the same CustomerId).
    for i := 1 to 5 do
    begin
      Log.Info('Processed batch item', 'WORK', [
        LogParam.I('item_id', 1000 + i),
        LogParam.F('elapsed_ms', 12.5 + i * 3.1)
      ]);
    end;

    Log.Warn('Cache hit ratio below target', 'CACHE',
      [LogParam.F('hit_ratio', 0.62)]);

    try
      raise Exception.Create('Simulated downstream timeout');
    except
      on E: Exception do
        Log.LogException(E, 'Payment gateway unavailable', 'ORDERS');
    end;

    Log.Info('ExeWatch sample complete', 'BOOT');

    Log.Shutdown;   // blocks until every queued event is shipped
    Log := nil;

    Writeln;
    Write('Done. Check the ExeWatch dashboard for this CustomerId.');
    ReadLn;
  except
    on E: Exception do
    begin
      Writeln('Unrecoverable: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;

end.
