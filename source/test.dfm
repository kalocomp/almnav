object TestForm: TTestForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Sz'#225'mla tesztel'#233'se'
  ClientHeight = 244
  ClientWidth = 366
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object TestButton: TButton
    Left = 140
    Top = 210
    Width = 75
    Height = 25
    Caption = 'Teszt'
    TabOrder = 6
    OnClick = TestButtonClick
  end
  object InvDirGroup: TRadioGroup
    Left = 20
    Top = 35
    Width = 321
    Height = 58
    Caption = 'Sz'#225'mla tipusa'
    ItemIndex = 0
    Items.Strings = (
      'Kimen'#337' sz'#225'mla'
      'Be'#233'rkez'#337' sz'#225'mla')
    TabOrder = 1
  end
  object SzamlaszamEdit: TLabeledEdit
    Left = 80
    Top = 130
    Width = 261
    Height = 21
    EditLabel.Width = 61
    EditLabel.Height = 13
    EditLabel.Caption = 'Sz'#225'mlasz'#225'm:'
    LabelPosition = lpLeft
    MaxLength = 50
    TabOrder = 3
    Text = ''
  end
  object CegCombo: TComboBox
    Left = 20
    Top = 8
    Width = 321
    Height = 21
    TabOrder = 0
    Text = 'CegCombo'
    OnChange = CegComboChange
  end
  object AdoszamEdit: TLabeledEdit
    Left = 80
    Top = 103
    Width = 261
    Height = 21
    EditLabel.Width = 47
    EditLabel.Height = 13
    EditLabel.Caption = 'Ad'#243'sz'#225'm:'
    LabelPosition = lpLeft
    MaxLength = 9
    TabOrder = 2
    Text = ''
  end
  object StartDateEdit: TAdvDateTimePicker
    Left = 80
    Top = 157
    Width = 121
    Height = 21
    Date = 44284.000000000000000000
    Format = ''
    Time = 0.616516203706851200
    DoubleBuffered = True
    Kind = dkDate
    ParentDoubleBuffered = False
    TabOrder = 4
    BorderStyle = bsSingle
    Ctl3D = True
    DateTime = 44284.616516203710000000
    Version = '1.3.5.1'
    LabelCaption = 'Id'#337'szak:'
    LabelPosition = lpLeftCenter
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -11
    LabelFont.Name = 'Tahoma'
    LabelFont.Style = []
  end
  object EndDateEdit: TAdvDateTimePicker
    Left = 215
    Top = 157
    Width = 126
    Height = 21
    Date = 44284.000000000000000000
    Format = ''
    Time = 0.616516203706851200
    DoubleBuffered = True
    Kind = dkDate
    ParentDoubleBuffered = False
    TabOrder = 5
    BorderStyle = bsSingle
    Ctl3D = True
    DateTime = 44284.616516203710000000
    Version = '1.3.5.1'
    LabelCaption = '-'
    LabelPosition = lpLeftCenter
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -11
    LabelFont.Name = 'Tahoma'
    LabelFont.Style = []
  end
  object WriteCheckBox: TAdvOfficeCheckBox
    Left = 20
    Top = 184
    Width = 321
    Height = 20
    TabOrder = 7
    Alignment = taLeftJustify
    Caption = 'Adatok r'#246'gz'#237't'#233'se a DBF '#225'llom'#225'nyokba'
    ReturnIsTab = False
    Version = '1.6.1.0'
  end
end
