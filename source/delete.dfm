object DeleteForm: TDeleteForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'F'#225'jlok t'#246'rll'#233'se...'
  ClientHeight = 108
  ClientWidth = 508
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object DirectoryBar: TAdvProgressBar
    Left = 8
    Top = 30
    Width = 492
    Height = 26
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Verdana'
    Font.Style = []
    Level0ColorTo = 14811105
    Level1Color = clLime
    Level1ColorTo = 14811105
    Level2Color = clLime
    Level2ColorTo = 14811105
    Level3Color = clLime
    Level3ColorTo = 14811105
    Level1Perc = 70
    Level2Perc = 90
    Max = 4
    Position = 0
    ShowBorder = True
    Version = '1.3.0.1'
  end
  object DirectoryLabel: TLabel
    Left = 8
    Top = 11
    Width = 492
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'Ellen'#337'rz'#246'tt k'#246'nyvt'#225'r'
  end
  object DeleteDateLabel: TLabel
    Left = 8
    Top = 62
    Width = 492
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'T'#246'rlend'#337' f'#225'jlok d'#225'tuma'
  end
  object FileNameLabel: TLabel
    Left = 8
    Top = 85
    Width = 492
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'T'#246'l'#233's alatt lev'#337' f'#225'jl'
  end
end
