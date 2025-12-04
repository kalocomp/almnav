unit test;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.DateUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Main, Crypt, Reading,
  Vcl.ComCtrls, AdvDateTimePicker, AdvOfficeButtons, Vcl.Mask;

type
  TTestForm = class(TForm)
	 TestButton: TButton;
	 InvDirGroup: TRadioGroup;
	 SzamlaszamEdit: TLabeledEdit;
	 CegCombo: TComboBox;
	 AdoszamEdit: TLabeledEdit;
    StartDateEdit: TAdvDateTimePicker;
    EndDateEdit: TAdvDateTimePicker;
    WriteCheckBox: TAdvOfficeCheckBox;
	 procedure TestButtonClick(Sender: TObject);
	 procedure FormShow(Sender: TObject);
	 procedure CegComboChange(Sender: TObject);
  private
	 { Private declarations }
  public
	 { Public declarations }
  end;

var
  TestForm: TTestForm;

implementation

uses NAVRead, NAV, invoice;

{$R *.dfm}

procedure TTestForm.CegComboChange(Sender: TObject);
begin
	MainForm.CegekTable.Locate( 'NEV', CegCombo.Items[ CegCombo.ItemIndex ]);
	AdoszamEdit.Text := Copy( MainForm.CegekTable.FieldByName( 'ADOSZAM').AsString,1,8 );
end;

procedure TTestForm.FormShow(Sender: TObject);
var
	nMonth, nYear, nDay								: word;
begin
	CegCombo.Items.Clear;
	MainForm.CegekTable.First;
	while ( not ( MainForm.CegekTable.Eof)) do begin
		if ( Trim( MainForm.CegekTable.FieldByName( 'LOGIN' ).AsString ) <> '' ) then begin
			CegCombo.Items.Add( MainForm.CegekTable.FieldByName( 'NEV').AsString );
			MainForm.CegekTable.Next;
		end;
	end;
	CegCombo.ItemIndex := 0;
	StartDateEdit.Date := EncodeDate( YearOf( Now ), MonthOf( Now ), 1 );
	EndDateEdit.Date := IncDay( EncodeDate( YearOf( IncDay( StartDateEdit.Date, 40 )), MonthOf( IncDay( StartDateEdit.Date, 40 )), 1 ), -1 );
end;

procedure TTestForm.TestButtonClick(Sender: TObject);
var
	cInvNumber,cTaxNumber							: AnsiString;
	InvoiceDirection									: TInvoiceDirection;
	cNewFileName										: string;
	nActPage, nMaxPage								: integer;
	NAVInvoice											: TInvoice;
begin
	MainForm.CegekTable.Locate( 'NEV', CegCombo.Items[ CegCombo.ItemIndex ]);
	if ( InvDirGroup.ItemIndex = 1 ) then begin
		InvoiceDirection := id_Inbound;
		cTaxNumber := Copy( AdoszamEdit.Text,1,8 );
	end else begin
		InvoiceDirection := id_Outbound;
		cTaxNumber := Copy( MainForm.CegekTable.FieldByName( 'ADOSZAM').AsString,1,8 );
	end;
	if ( Length( Trim( SzamlaszamEdit.Text )) <> 0 ) then begin
		cInvNumber := SzamlaszamEdit.Text;
		NAVInvoice := TInvoice.Create;
		NAVReadForm.InvoiceLabel.Caption := 'Beolvasás: ' + cInvNumber;
		NAVReadForm.Refresh;
		cNewFileName := ReadInvoiceData( WriteCheckBox.Checked, InvoiceDirection, cTaxNumber, cInvNumber );
		if cNewFileName <> '' then begin
			NAVReadForm.InvoiceLabel.Caption := 'Írás: ' + cInvNumber;
			NAVReadForm.Refresh;
			WriteInvoice( WriteCheckBox.Checked, MainForm.CegekTable.FieldByName( 'KOD' ).AsString, cNewFileName, InvoiceDirection );
		end;
		NAVInvoice.Destroy;
	end else begin
		nMaxPage := 999;
		nActPage := 1;
		while ( nActPage < nMaxPage ) do begin
			nMaxPage := ReadInvoiceList( TRUE, WriteCheckBox.Checked, InvoiceDirection, cTaxNumber, StartDateEdit.Date, EndDateEdit.Date, nActPage );
			Inc( nActPage );
		end;
	end;
end;

end.
