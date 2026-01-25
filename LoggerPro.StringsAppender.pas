// *************************************************************************** }
//
// LoggerPro
//
// Copyright (c) 2010-2026 Daniele Teti
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

unit LoggerPro.StringsAppender;

interface

uses
  LoggerPro,
  System.Classes,
  System.SyncObjs;

type
  { @abstract(Appends formatted @link(TLogItem) to a TMemo in a VCL application) }
  TStringsLogAppender = class(TLoggerProAppenderBase)
  private
    fStrings: TStrings;
    FMaxLogLines: Word;
    FClearOnStartup: Boolean;
    FCriticalSection: TCriticalSection;
  public
    constructor Create(aStringList: TStrings; aMaxLogLines: Word = 100;
        aClearOnStartup: Boolean = False; aLogItemRenderer: ILogItemRenderer =
        nil); reintroduce;
    destructor Destroy; override;
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.Messages;

{ TStringsLogAppender }

constructor TStringsLogAppender.Create(aStringList: TStrings; aMaxLogLines:
    Word = 100; aClearOnStartup: Boolean = False; aLogItemRenderer:
    ILogItemRenderer = nil);
begin
  inherited Create(aLogItemRenderer);
  fStrings := aStringList;
  FMaxLogLines := aMaxLogLines;
  FClearOnStartup := aClearOnStartup;
  FCriticalSection := TCriticalSection.Create();
end;

destructor TStringsLogAppender.Destroy;
begin
  FCriticalSection.Free;
  inherited Destroy;
end;

procedure TStringsLogAppender.Setup;
begin
  inherited;
  if FClearOnStartup then
  begin
    TThread.Synchronize(nil,
      procedure
      begin
        fStrings.Clear;
      end);
  end;
end;

procedure TStringsLogAppender.TearDown;
begin
  // do nothing
end;

procedure TStringsLogAppender.WriteLog(const aLogItem: TLogItem);
var
  lText: string;
begin
  lText := FormatLog(aLogItem);
  TThread.Queue(nil,
    procedure
    begin
      FCriticalSection.Acquire;
      try
        fStrings.BeginUpdate;
        try
          if FMaxLogLines > 0 then
            while fStrings.Count > FMaxLogLines do
              fStrings.Delete(0);
          fStrings.Add(lText)
        finally
          fStrings.EndUpdate;
        end;
      finally
        FCriticalSection.Release;
      end;
    end);
end;

end.
