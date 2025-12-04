unit currencyread;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.StdCtrls, XMLDoc, XMLIntf,
  GradientLabel, Vcl.Grids, AdvObj, BaseGrid, AdvGrid;

const
	aBankCode : array[ 0..16,0..1 ] of string = ((
		'mnb', 'Magyar Nemzeti Bank' ), (
		'erste', 'Erste Bank' ), (
		'bb', 'Budapest Bank' ), (
		'allianz', 'Allianz Bank' ), (
		'cib', 'CIB bank' ), (
		'citibank', 'Citibank' ), (
		'commerz', 'Commezbank' ), (
		'kdb', 'KDB Bank' ), (
		'kh', 'K&H Bank' ), (
		'mkb', 'MKB Bank' ), (
		'oberbank', 'Oberbank' ), (
		'otp', 'OTP' ), (
		'raiffeisen', 'Raiffeisen Bank' ), (
		'unicredit', 'Unicredit Bank' ), (
		'volksbank', 'Sperbank' ), (
		'mfb', 'Magyar Fejlesztési Bank' ), (
		'fhb', 'Takarékbank' ));
type
	TCurrencyReadSettings = class;

	TCurrencyReadItem = class( TCollectionItem )
	private
		FBankCode : integer;
		FBankName : string;
		FCurrencyCode : string;
		FLastRead : TDateTime;
		FExchangeRate : single;
	public
		constructor Create( Collection: TCollection ); override;
		procedure Assign(Source: TPersistent); override;
	published
		property BankCode : integer read FBankCode write FBankCode;
		property BankName : string read FBankName write FBankName;
		property CurrencyCode : string read FCurrencyCode write FCurrencyCode;
		property LastRead : TDateTime read FLastRead write FLastRead;
		property ExchangeRate : single read FExchangeRate write FExchangeRate;
	end;

	TCurrencyReadItems = class( TCollection )
	private
		FCurrencyReadSettings : TCurrencyReadSettings;
		function GetItem( Index : integer ) : TCurrencyReadItem;
		procedure SetItem( Index : integer; const Value : TCurrencyReadItem );
	protected
	public
		constructor Create( AOwner : TCurrencyReadSettings );
		function Add : TCurrencyReadItem;
		function Insert( Index : integer ) : TCurrencyReadItem;
		property Items[ Index : integer ] : TCurrencyReadItem read GetItem write SetItem; default;
	end;

	TCurrencyReadSettings = class( TPersistent )
	private
		FActive : boolean;
		FHTTPLink : AnsiString;
		FDBFPath : AnsiString;
		FDBFFile : AnsiString;
		FReadInterval : integer;
		FLastRead : TDateTime;
		FCurrencyReadItems : TCurrencyReadItems;
	public
		constructor Create;
		destructor Destroy; override;
		procedure GetLastRead;
	published
		property Active : boolean read FActive write FActive;
		property DBFPath : AnsiString read FDBFPath write FDBFPath;
		property HTTPLink : AnsiString read FHTTPLink write FHTTPLink;
		property DBFFile : AnsiString read FDBFFile write FDBFFile;
		property ReadInterval : integer read FReadInterval write FReadInterval;
		property LastRead : TDateTime read FLastRead write FLastRead;
		property CurrencyReadItems : TCurrencyReadItems read FCurrencyReadItems write FCurrencyReadItems;
	end;

  TCurrencyReadForm = class(TForm)
	 CurrencyGrid: TAdvStringGrid;
	 GradientLabel1: TGradientLabel;
	 DownloadButton: TButton;
	 procedure FormShow(Sender: TObject);
	 procedure DownloadButtonClick(Sender: TObject);
  private
	 { Private declarations }
  public
	 { Public declarations }
		procedure ReadCurrency( CurrencyReadItem : TCurrencyReadItem );
		procedure ReadCurrencies;
		procedure WriteToDBF( InXMLFile : string );
  end;

var
  CurrencyReadForm: TCurrencyReadForm;

implementation

{$R *.dfm}

uses main, xmlhandler, DateUtils, nav, Math, crypt, System.UITypes;

// TCurrencyReadItem
constructor TCurrencyReadItem.Create( Collection: TCollection );
begin
	inherited;
	FBankCode := 1;
	FBankName := 'mnb';
	FCurrencyCode := 'EUR';
	FLastRead := EncodeDate( YearOf( Now ),1,1 );
	FExchangeRate := 1;
end;

procedure TCurrencyReadItem.Assign( Source: TPersistent );
begin
	if ( Source is TCurrencyReadItem ) then begin
		FBankCode := TCurrencyReadItem( Source ).FBankCode;
		FCurrencyCode := TCurrencyReadItem( Source ).FCurrencyCode;
	end else begin
		inherited Assign( Source );
	end;
end;

// TCurrencyReadItems
constructor TCurrencyReadItems.Create( AOwner : TCurrencyReadSettings );
begin
  inherited Create( TCurrencyReadItem );
  FCurrencyReadSettings := AOwner;
end;

function TCurrencyReadItems.Add : TCurrencyReadItem;
begin
	Result := TCurrencyReadItem( inherited Add );
	Result.FBankCode := 1;
	Result.FBankName := 'mnb';
	Result.FCurrencyCode := 'EUR';
	Result.FLastRead := EncodeDate( YearOf( Now ),1,1 );
	Result.FExchangeRate := 1;
end;

function TCurrencyReadItems.GetItem( Index: integer) : TCurrencyReadItem;
begin
  Result := TCurrencyReadItem( inherited Items[ Index ]);
end;

function TCurrencyReadItems.Insert(Index: integer) : TCurrencyReadItem;
begin
  Result := TCurrencyReadItem( inherited Insert( Index ));
end;

procedure TCurrencyReadItems.SetItem( Index : integer; const Value : TCurrencyReadItem );
begin
  inherited Items[ Index ] := Value;
end;

// TCurrencyReadSettings
constructor TCurrencyReadSettings.Create;
begin
	inherited;
	FActive := FALSE;
	FHTTPLink := 'http://api.napiarfolyam.hu';
	FDBFPath := '';
	FDBFFile := '';
	FLastRead := Now;
	FReadInterval := 0;
	FCurrencyReadItems := TCurrencyReadItems.Create( Self );
end;

destructor TCurrencyReadSettings.Destroy;
begin
	FCurrencyReadItems.Destroy;
	inherited;
end;

procedure TCurrencyReadSettings.GetLastRead;
var
	I													: integer;
begin
	MainForm.DBFTable1.DatabaseName := MainForm.CurrencyReadSettings.DBFPath + '\';
	MainForm.DBFTable1.TableName := MainForm.CurrencyReadSettings.DBFFile + '.DBF';
	try
		MainForm.DBFTable1.Open;
		MainForm.DBFTable1.IndexOpen( MainForm.CurrencyReadSettings.DBFPath + '\' + MainForm.CurrencyReadSettings.DBFFile + '1.NTX' );
		MainForm.DBFTable1.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + 'P44.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
	for I := 0 to MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 do begin
		MainForm.DBFTable1.GoTop;
		while ( not  MainForm.DBFTable1.Eof ) do begin
			if (( MainForm.DBFTable1.FieldByName( 'BANK' ).AsInteger = MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].BankCode ) and
				( MainForm.DBFTable1.FieldByName( 'DEVIZA' ).AsString = MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].CurrencyCode )) then begin
				if ( MainForm.DBFTable1.FieldByName( 'DATUM' ).AsDateTime > MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].LastRead ) then begin
					MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].LastRead := MainForm.DBFTable1.FieldByName( 'DATUM' ).AsDateTime;
					MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].ExchangeRate := MainForm.DBFTable1.FieldByName( 'ARFOLYAM' ).AsFloat;
				end;
			end;
			MainForm.DBFTable1.Next;
		end;
	end;
	MainForm.DBFTable1.Close;
end;

procedure TCurrencyReadForm.DownloadButtonClick(Sender: TObject);
var
	CurrencyReadItem											: TCurrencyReadItem;
begin
	CurrencyReadItem := MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ CurrencyReadForm.CurrencyGrid.Selection.Top - 1 ];
	MainForm.CurrencyReadSettings.GetLastRead;
	CurrencyReadForm.ReadCurrency( CurrencyReadItem );
end;

procedure TCurrencyReadForm.FormShow(Sender: TObject);
var
	I												: integer;
begin
	SetMySettings;
	if ( MainForm.CurrencyReadSettings.CurrencyReadItems.Count = 0 ) then begin
		MessageDlg( 'Nincs letöltendõ deviza adat beállítva !!!', mtWarning, [ mbOK ], 0);
	end else begin
		MainForm.CurrencyReadSettings.GetLastRead;
		CurrencyGrid.ColCount := 4;
		CurrencyGrid.ColWidths[ 0 ] := CurrencyGrid.Width div 3;
		CurrencyGrid.ColWidths[ 1 ] := CurrencyGrid.Width div 8;
		CurrencyGrid.ColWidths[ 2 ] := CurrencyGrid.Width div 5;
		CurrencyGrid.ColWidths[ 3 ] := CurrencyGrid.Width div 3;
		CurrencyGrid.RowCount := MainForm.CurrencyReadSettings.CurrencyReadItems.Count + 1;
		CurrencyGrid.FixedRows := 1;
		CurrencyGrid.Cells[ 0,0 ] := 'Bank';
		CurrencyGrid.Cells[ 1,0 ] := 'Deviza';
		CurrencyGrid.Cells[ 2,0 ] := 'Utolsó dátum';
		CurrencyGrid.Cells[ 3,0 ] := 'Árfolyam';
		for I := 0 to MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 do begin
			CurrencyGrid.Cells[ 0,I + 1 ] := MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].BankName;
			CurrencyGrid.Cells[ 1,I + 1 ] := MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].CurrencyCode;
			CurrencyGrid.Cells[ 2,I + 1 ] := FormatDateTime( 'YYYY.MM.DD hh:mm', MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].LastRead );
			CurrencyGrid.Cells[ 3,I + 1 ] := FormatFloat( '#.####', MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].ExchangeRate, NAV.MySettings );
		end;
		MainForm.DBFTable1.Close;
	end;
end;

procedure TCurrencyReadForm.ReadCurrencies;
var
	I											: integer;
begin
	MainForm.CurrencyReadSettings.GetLastRead;
	WriteLogFile( 'Árfolyamok letöltése megkezdve. (' + IntToStr( MainForm.CurrencyReadSettings.CurrencyReadItems.Count ) + ' db)', 2 );
	for I := 0 to MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 do begin
		CurrencyReadForm.ReadCurrency( MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ]);
	end;
	WriteLogFile( 'Árfolyamok letöltése befejezve.', 2 );
	MainForm.CurrencyReadSettings.LastRead := Now;
end;

procedure TCurrencyReadForm.ReadCurrency( CurrencyReadItem : TCurrencyReadItem );
var
	cHTTPQuery, CurrencyData								: string;
	CurrencyXML													: IXMLDocument;
	dActDate, dStartDate, dEndDate						: TDateTime;
begin
	dStartDate := CurrencyReadItem.LastRead;
	dEndDate := Now;
	dActDate := dStartDate;
	while ( dActDate <= dEndDate ) do begin
		cHTTPQuery := MainForm.CurrencyReadSettings.HTTPLink + '?bank=';
		cHTTPQuery := cHTTPQuery + LowerCase( CurrencyReadItem.BankName );
		cHTTPQuery := cHTTPQuery + '&valuta=';
		cHTTPQuery := cHTTPQuery + UpperCase( CurrencyReadItem.CurrencyCode );
		cHTTPQuery := cHTTPQuery + '&datum=';
		cHTTPQuery := cHTTPQuery + FormatDateTime( 'YYYYMMDD', dActDate );
		try
			WriteLogFile( 'Árfolyam lekérdezése : ' + cHTTPQuery,2 );
			CurrencyData := MainForm.MainHTTP.Get( cHTTPQuery );
			CurrencyData := StringReplace( CurrencyData, Chr( 10 ), Chr( 13 ) + Chr( 10 ), [ rfReplaceAll ]);
			Delete( CurrencyData, 29, 1 );
			Delete( CurrencyData, 30, 1 );
			CurrencyXML := TXMLDocument.Create( NIL );
			CurrencyXML := LoadXMLData( CurrencyData );
			CurrencyXML.SaveToFile( 'currency.xml' );
			CurrencyReadForm.WriteToDBF( 'currency.xml' );
			WriteLogFile( 'Árfolyam lekérdezve.',2 );
		except
			on E: Exception do begin
				MessageDlg( E.ClassName + ': ' + E.Message, mtWarning, [ mbOK ], 0 );
			end;
		end;
		dActDate := IncDay( dActDate, 1 );
	end;
end;

procedure TCurrencyReadForm.WriteToDBF( InXMLFile : string );
var
	CurrencyXML													: IXMLDocument;
	MainNode,Level1Node,Level2Node						: IXMLNode;
	cBankCode, cCurrencyCode								: AnsiString;
	nExchangeRate												: single;
	dDate															: TDateTime;
	I,nBankCode													: integer;
begin
	if ( FileExists( InXMLFile )) then begin
		WriteLogFile( 'Árfolyam felírása.',2 );
		MainForm.DBFTable1.DatabaseName := MainForm.CurrencyReadSettings.DBFPath + '\';
		MainForm.DBFTable1.TableName := MainForm.CurrencyReadSettings.DBFFile + '.DBF';
		try
			MainForm.DBFTable1.Open;
			MainForm.DBFTable1.IndexOpen( MainForm.CurrencyReadSettings.DBFPath + '\' + MainForm.CurrencyReadSettings.DBFFile + '1.NTX' );
			MainForm.DBFTable1.SetOrder( 1 );
		except
			on E : Exception do begin
				WriteLogFile( 'Hiba a ' + 'P44.DBF állomány megnyitásakor :' + E.Message,2 );
				Exit;
			end;
		end;
		CurrencyXML := LoadXMLDocument( InXMLFile );
		MainNode := CurrencyXML.ChildNodes.FindNode( 'arfolyamok' );
		Level1Node := MainNode.ChildNodes.FindNode( 'deviza' );
		if ( Level1Node <> NIL ) then begin
			Level2Node := Level1Node.ChildNodes.FindNode( 'item' );
			while ( Level2Node <> NIL ) do begin
				cBankCode := LowerCase( ReadNodeText( Level2Node, 'bank' ));
				nBankCode := 0;
				for I := 0 to Length( aBankCode ) - 1 do begin
					if ( aBankCode[ I,0 ] = cBankCode ) then begin
						nBankCode := I + 1;
						Break;
					end;
				end;
				cCurrencyCode := UpperCase( ReadNodeText( Level2Node, 'penznem' ));
				if ( LowerCase( cBankCode ) = 'mnb' ) then begin
					nExchangeRate := StrToFloat( ReadNodeText( Level2Node, 'kozep' ), NAV.MySettings );
				end else begin
					nExchangeRate := StrToFloat( ReadNodeText( Level2Node, 'eladas' ), NAV.MySettings );
				end;
				dDate := NAVStrToDate( ReadNodeText( Level2Node, 'datum' ));
				if ( MainForm.DBFTable1.Seek( PadR( Trim( IntToStr( nBankCode )),2,' ' ) + PadR( cCurrencyCode,3,' ' ) + FormatDateTime( 'YYYYMMDD', dDate ))) then begin
					MainForm.DBFTable1.Edit;
					WriteLogFile( 'Árfolyam módosítása: ' + PadR( Trim( IntToStr( nBankCode )),2,' ' ) + ', ' + cCurrencyCode + ', ' + FormatDateTime( 'YYYYMMDD', dDate ) + ', ' + FormatFloat( '#.####', nExchangeRate ),4 );
				end else begin
					MainForm.DBFTable1.Append;
					MainForm.DBFTable1.FieldValues[ 'BANK' ] := nBankCode;
					MainForm.DBFTable1.FieldValues[ 'DEVIZA' ] := cCurrencyCode;
					MainForm.DBFTable1.FieldValues[ 'DATUM' ] := dDate;
					WriteLogFile( 'Új árfolyam felírása: ' + PadR( Trim( IntToStr( nBankCode )),2,' ' ) + ', ' + cCurrencyCode + ', ' + FormatDateTime( 'YYYYMMDD', dDate ) + ', ' + FormatFloat( '#.####', nExchangeRate ),4 );
				end;
				MainForm.DBFTable1.FieldValues[ 'ARFOLYAM' ] := nExchangeRate;
				MainForm.DBFTable1.FieldValues[ 'ROGKOD' ] := 99;
				MainForm.DBFTable1.FieldValues[ 'UTDAT' ] := Now;
				MainForm.DBFTable1.Post;
				Level2Node := Level2Node.NextSibling;
			end;
		end;
		CurrencyXML.Active := FALSE;
		MainForm.DBFTable1.Close;
	end;
end;

end.


