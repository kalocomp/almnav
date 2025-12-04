unit TaxPayer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask,
  AdvEdit;

type
	TTaxPayerForm = class(TForm)
    TaxNumberEdit: TAdvMaskEdit;
    Panel1: TPanel;
    TaxPayerNameEdit: TAdvMaskEdit;
    TaxPayerCountryEdit: TAdvMaskEdit;
    TaxPayerPostalCodeEdit: TAdvMaskEdit;
    TaxPayerCityEdit: TAdvMaskEdit;
    TaxPayerStreetEdit: TAdvMaskEdit;
    TaxPayerPlaceEdit: TAdvMaskEdit;
    TaxPayerNumberEdit: TAdvMaskEdit;
    OKButton: TButton;
    RegDateEdit: TAdvMaskEdit;
	  procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
	private
{ Private declarations }
	public
{ Public declarations }
		cTaxNumber : string;
		cTaxPayerName : string;
		cTaxPayerCountry : string;
		cTaxPayerPostalCode : string;
		cTaxPayerCity : string;
		cTaxPayerStreet : string;
		cTaxPayerPlace : string;
		cTaxPayerNumber : string;
	end;

var
	TaxPayerForm: TTaxPayerForm;

implementation

{$R *.dfm}

procedure TTaxPayerForm.FormCreate(Sender: TObject);
begin
	cTaxNumber := '';
	cTaxPayerName := '';
	cTaxPayerCountry := '';;
	cTaxPayerPostalCode := '';
	cTaxPayerCity := '';
	cTaxPayerStreet := '';
	cTaxPayerPlace := '';
	cTaxPayerNumber := '';
end;

procedure TTaxPayerForm.FormShow(Sender: TObject);
begin
	Self.TaxNumberEdit.Text := cTaxNumber;
	Self.TaxPayerNameEdit.Text := cTaxPayerName;
	Self.TaxPayerCountryEdit.Text := cTaxPayerCountry;
	Self.TaxPayerPostalCodeEdit.Text := cTaxPayerPostalCode;
	Self.TaxPayerCityEdit.Text := cTaxPayerCity;
	Self.TaxPayerStreetEdit.Text := cTaxPayerStreet;
	Self.TaxPayerPlaceEdit.Text := cTaxPayerPlace;
	Self.TaxPayerNumberEdit.Text := cTaxPayerNumber;
end;

procedure TTaxPayerForm.OKButtonClick(Sender: TObject);
begin
	Close;
end;

end.
