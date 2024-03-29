object FUDPServerClientForm: TFUDPServerClientForm
  Left = 0
  Top = 0
  Caption = 'UDP Server & Client'
  ClientHeight = 624
  ClientWidth = 1138
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Label1: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 1132
    Height = 19
    Align = alTop
    Caption = 'Switch on the UDP server to listen to broadcasts on 127.0.0.1.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 442
  end
  object Label2: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 28
    Width = 1132
    Height = 19
    Align = alTop
    Caption = 
      'Also switch on the UDP client to start broadcasting logs to 127.' +
      '0.0.1.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ExplicitLeft = 0
    ExplicitTop = 19
    ExplicitWidth = 490
  end
  object Label3: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 53
    Width = 1132
    Height = 19
    Align = alTop
    Caption = 'Watch server log below to see received syslog messages.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ExplicitLeft = 0
    ExplicitTop = 38
    ExplicitWidth = 402
  end
  object UDPServerReceived: TMemo
    Left = 0
    Top = 188
    Width = 1138
    Height = 436
    Align = alClient
    Color = clBackground
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clLime
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    ExplicitTop = 170
    ExplicitWidth = 1134
    ExplicitHeight = 453
  end
  object Panel1: TPanel
    Left = 0
    Top = 75
    Width = 1138
    Height = 113
    Align = alTop
    BevelInner = bvLowered
    TabOrder = 1
    ExplicitTop = 57
    ExplicitWidth = 1134
    object Label4: TLabel
      Left = 8
      Top = 6
      Width = 73
      Height = 13
      Caption = 'UDP Client Port'
    end
    object Label5: TLabel
      Left = 240
      Top = 6
      Width = 78
      Height = 13
      Caption = 'UDP Server Port'
    end
    object UDPServerControl: TRadioGroup
      Left = 367
      Top = 2
      Width = 100
      Height = 105
      Caption = 'UDP Server'
      ItemIndex = 1
      Items.Strings = (
        'On'
        'Off')
      TabOrder = 0
      OnClick = UDPServerControlClick
    end
    object UDPClientControl: TRadioGroup
      Left = 134
      Top = 2
      Width = 100
      Height = 105
      Caption = 'UDP Client'
      ItemIndex = 1
      Items.Strings = (
        'On'
        'Off')
      TabOrder = 1
      OnClick = UDPClientControlClick
    end
    object UDPClientPort: TSpinEdit
      Left = 8
      Top = 25
      Width = 121
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 2
      Value = 5114
    end
    object UDPServerPort: TSpinEdit
      Left = 240
      Top = 25
      Width = 121
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 3
      Value = 5114
    end
  end
  object IdUDPServer: TIdUDPServer
    Bindings = <
      item
        IP = '127.0.0.1'
        Port = 5114
      end>
    DefaultPort = 0
    OnUDPRead = IdUDPServerUDPRead
    Left = 536
    Top = 8
  end
  object UDPClientTimer: TTimer
    Enabled = False
    OnTimer = UDPClientTimerTimer
    Left = 616
    Top = 8
  end
end
