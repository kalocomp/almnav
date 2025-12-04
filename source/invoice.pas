unit invoice;

interface

uses System.Classes, System.SysUtils, StrUtils;

type
	TInvoiceDirection = ( id_Inbound, id_Outbound );
	TNAVVersion = ( rv_10, rv_20, rv_30 );
	TTestMode = ( tm_Real, tm_Test );
	TElectricInvoice = ( ei_Electronic, ei_Normal );

	TFactory = class( TPersistent )
	private
		FCode : integer;
		FAlmiraLetter : string;
		FName : string;
		FNAVType : integer;
		FTaxPayerID : string;
		FVatCode : string;
		FCountyCode : string;
		FEUTAXID : string;
		FCountryCode : string;
		FPostalCode : string;
		FCity : string;
		FAddress : string;
		FLogin : string;
		FPassword : string;
		FSignKey : string;
		FChangeKey : string;
		function GetFullTAXID : string;
	public
		constructor Create;
		destructor Destroy; override;
	published
		property Code : integer read FCode write FCode;
		property AlmiraLetter : string read FAlmiraLetter write FAlmiraLetter;
		property Name : string read FName write FName;
		property NAVType : integer read FNAVType write FNAVType;
		property TAXPayerID : string read FTAXPayerID write FTAXPayerID;
		property VATCode : string read FVATCode write FVATCode;
		property CountyCode : string read FCountyCode write FCountyCode;
		property EUTAXID : string read FEUTAXID write FEUTAXID;
		property CountryCode : string read FCountryCode write FCountryCode;
		property PostalCode : string read FPostalCode write FPostalCode;
		property City : string read FCity write FCity;
		property Address : string read FAddress write FAddress;
		property Login : string read FLogin write FLogin;
		property Password : string read FPassword write FPassword;
		property SignKey : string read FSignKey write FSignKey;
		property ChangeKey : string read FChangeKey write FChangeKey;
		property FullTAXID : string read GetFullTAXID;
	end;

	TInvoice = class;

	TInvoiceList = class( TCollection )
	private
		function GetItem( Index : integer ) : TInvoice;
		procedure SetItem( Index : integer; const Value : TInvoice );
	protected
	public
		constructor Create;
		destructor Destroy; override;
		procedure Clear;
		function Add : TInvoice;
		function Insert( Index : integer ) : TInvoice;
		property Items[ Index : integer ] : TInvoice read GetItem write SetItem; default;
	end;

	TInvoiceLine = class( TCollectionItem )
	private
		FLine : integer;
		FAlmiraCode : string;
		FCodeCategory : string;
		FProductCode : string;
		FProductName : string;
		FProductUnit : string;
		FVatCode : integer;
		FVatPercent : single;
		FNAVVatCode : string;
		FQuantity : single;
		FUnitPrice : single;
		FNetAmount : single;
		FNetAmountHUF : single;
		FVatAmount : single;
		FVatAmountHUF : single;
		FGrossAmount : single;
		FGrossAmountHUF : single;
	public
		constructor Create( Collection: TCollection ); override;
		destructor Destroy; override;
		procedure Assign(Source: TPersistent); override;
		procedure ResetLine;
	published
		property Sor : integer read FLine write FLine default 0;
		property ProductName : string read FProductName write FProductName;
		property ProductUnit : string read FProductUnit write FProductUnit;
		property AlmiraCode: string read FAlmiraCode write FAlmiraCode;
		property CodeCategory : string read FCodeCategory write FCodeCategory;
		property ProductCode : string read FProductCode write FProductCode;
		property VatCode : integer read FVatCode write FVatCode;
		property AFASzaz : single read FVatPercent write FVatPercent;
		property NAVVatCode : string read FNAVVatCode write FNAVVatCode;
		property VatPercent : single read FVatPercent write FVatPercent;
		property Quantity : single read FQuantity write FQuantity;
		property UnitPrice : single read FUnitPrice write FUnitPrice;
		property NetAmount : single read FNetAmount write FNetAmount;
		property NetAmountHUF : single read FNetAmountHUF write FNetAmountHUF;
		property VatAmount : single read FVatAmount write FVatAmount;
		property VatAmountHUF : single read FVatAmountHUF write FVatAmountHUF;
		property GrossAmount : single read FGrossAmount write FGrossAmount;
		property GrossAmountHUF : single read FGrossAmountHUF write FGrossAmountHUF;
	end;

	TInvoiceLines = class( TCollection )
	private
		FInvoice : TInvoice;
		function GetItem( Index : integer ) : TInvoiceLine;
		procedure SetItem( Index : integer; const Value : TInvoiceLine );
	protected
	public
		constructor Create( AOwner : TInvoice );
		destructor Destroy; override;
		function Add : TInvoiceLine;
		function Insert( Index : integer ) : TInvoiceLine;
		property Items[ Index : integer ] : TInvoiceLine read GetItem write SetItem; default;
//		function CompareItems( Index1, Index2 : integer ) : boolean;
	end;

	TInvoice = class( TCollectionItem )
	private
		FDirection : TInvoiceDirection;
		FInvoiceNumber : string;
		FIssueDate : TDate;
		FDeliveryDate : TDate;
		FPaymentDate : TDate;
		FPaymentMethod : integer;
		FCurrency : string;
		FExchangeRate : single;
		FNetAmountHUF : single;
		FNetAmount : single;
		FVatAmountHUF : single;
		FVatAmount : single;
		FGrossAmountHUF : single;
		FGrossAmount : single;
		FOriginalInvoice : string;
		FNAVDate : TDateTime;
		FSendSw : string;
		FRecordNumber : integer;
		FTransactionID : string;
		FRequestID : string;
		FCompressed : boolean;
		FElectronic : TElectricInvoice;
		FApperance : string;
		FInvoiceLines : TInvoiceLines;
		FSupplier : TFactory;
		FCustomer : TFactory;
		FStatusDateTime : TDateTime;
		FResultText : string;
		FOperationType : string;
		FTestMode : TTestMode;
		FInvStatusNum : string;
		FInvStatus : string;
		FInvStatusText : string;
		FNAVError : string;
		FErrorText : string;
		FSendDateTime : TDateTime;
		FSendMail : integer;
		FRequestDateTime : TDateTime;
		FRequestVersion : TNAVVersion;
		FXMLFile : string;
	public
		constructor Create;
		destructor Destroy; override;
		procedure WriteToDBF;
		procedure ClearStatusData;
		procedure SetNAVStatus;
	published
		property InvoiceLines : TInvoiceLines read FInvoiceLines write FInvoiceLines;
		property Direction : TInvoiceDirection read FDirection write FDirection;
		property Supplier : TFActory read FSupplier write FSupplier;
		property Customer : TFActory read FCustomer write FCustomer;
		property InvoiceNumber : string read FInvoiceNumber write FInvoiceNumber;
		property DeliveryDate : TDate read FDeliveryDate write FDeliveryDate;
		property IssueDate : TDate read FIssueDate write FIssueDate;
		property PaymentDate : TDate read FPaymentDate write FPaymentDate;
		property PaymentMethod : integer read FPaymentMethod write FPaymentMethod;
		property Currency : string read FCurrency write FCurrency;
		property ExchangeRate : single read FExchangeRate write FExchangeRate;
		property OriginalInvoice : string read FOriginalInvoice write FOriginalInvoice;
		property SendSw : string read FSendSw write FSendSw;
		property Apperance : string read FApperance write FApperance;
		property TransactionID : string read FTransactionID write FTransactionID;
		property RequestID : string read FRequestID write FRequestID;
		property NetAmount : single read FNetAmount write FNetAmount;
		property NetAmountHUF : single read FNetAmountHUF write FNetAmountHUF;
		property VatAmount : single read FVatAmount write FVatAmount;
		property VatAmountHUF : single read FVatAmountHUF write FVatAmountHUF;
		property GrossAmount : single read FGrossAmount write FGrossAmount;
		property GrossAmountHUF : single read FGrossAmount write FGrossAmount;
		property Compressed : boolean read FCompressed write FCompressed;
		property Electronic : TElectricInvoice read FElectronic write FElectronic;
		property RequestVersion : TNAVVersion read FRequestVersion write FRequestVersion;
		property NAVDate : TDateTime read FNAVDate write FNAVDate;
		property InvStatusNum : string read FInvStatusNum write FInvStatusNum;
		property InvStatus : string read FInvStatus write FInvStatus;
		property InvStatusText : string read FInvStatusText write FInvStatusText;
		property NAVError : string read FNAVError write FNAVError;
		property ErrorText : string read FErrorText write FErrorText;
		property XMLFile : string read FXMLFile write FXMLFile;
		property RequestDateTime : TDateTime read FRequestDateTime write FRequestDateTime;
		property StatusDateTime : TDateTime read FStatusDateTime write FStatusDateTime;
		property SendDateTime : TDateTime read FSendDateTime write FSendDateTime;
		property TestMode : TTestMode read FTestMode write FTestMode;
		property RecordNumber : integer read FRecordNumber write FRecordNumber;
		property SendMail : integer read FSendMail write FSendMail;
		property OperationType : string read FOperationType write FOperationType;
		property ResultText : string read FResultText write FResultText;
	end;

implementation

uses main, crypt, xmlhandler, reading;

// TFactory
constructor TFactory.Create;
begin
	inherited;
	FCode := 0;
	FName := '';
	FNAVType := 1;
	FTaxPayerID := '';
	FVatCode := '';
	FCountyCode := '';
	FCountryCode := '';
	FPostalCode := '';
	FCity := '';
	FAddress := '';
end;

destructor TFactory.Destroy;
begin
	inherited;
end;

function TFactory.GetFullTAXID : string;
begin
	Result := FTaxPayerID + FVATCode + FCountyCode;
end;

// TInvoiceLine
constructor TInvoiceLine.Create( Collection: TCollection );
begin
	inherited;
	FLine := 0;
	FAlmiraCode := '00000000';
	FCodeCategory := 'VTSZ';
	FProductCode := '';
	FProductName := '';
	FProductUnit := '';
	FVatCode := 0;
	FVatPercent := 0;
	FNAVVatCode := '';
	FQuantity := 0;
	FUnitPrice := 0;
	FNetAmount := 0;
	FNetAmountHUF := 0;
	FVatAmount := 0;
	FVatAmountHUF := 0;
	FGrossAmount := 0;
	FGrossAmountHUF := 0;
end;

destructor TInvoiceLine.Destroy;
begin
	inherited;
end;

procedure TInvoiceLine.Assign( Source: TPersistent );
begin
	if ( Source is TInvoiceLine ) then begin
		FLine := TInvoiceLine( Source ).FLine;
		FAlmiraCode := TInvoiceLine( Source ).FAlmiraCode;
		FCodeCategory := TInvoiceLine( Source ).FCodeCategory;
		FProductCode := TInvoiceLine( Source ).FProductCode;
		FProductName := TInvoiceLine( Source ).FProductName;
		FProductUnit := TInvoiceLine( Source ).FProductUnit;
		FVatCode := TInvoiceLine( Source ).FVatCode;
		FVatPercent := TInvoiceLine( Source ).FVatPercent;
		FNAVVatCode := TInvoiceLine( Source ).FNAVVatCode;
		FQuantity := TInvoiceLine( Source ).FQuantity;
		FUnitPrice := TInvoiceLine( Source ).FUnitPrice;
		FNetAmount := TInvoiceLine( Source ).FNetAmount;
		FNetAmountHUF := TInvoiceLine( Source ).FNetAmountHUF;
		FVatAmount := TInvoiceLine( Source ).FVatAmount;
		FVatAmountHUF := TInvoiceLine( Source ).FVatAmountHUF;
		FGrossAmount := TInvoiceLine( Source ).FGrossAmount;
		FGrossAmountHUF := TInvoiceLine( Source ).FGrossAmountHUF;
	end else begin
		inherited Assign( Source );
	end;
end;

procedure TInvoiceLine.ResetLine;
begin
	FAlmiraCode := '00000000';
	FCodeCategory := 'VTSZ';
	FProductCode := '';
	FProductName := '';
	FProductUnit := '';
	FVatCode := 0;
	FVatPercent := 0;
	FNAVVatCode := '';
	FQuantity := 0;
	FUnitPrice := 0;
	FNetAmount := 0;
	FNetAmountHUF := 0;
	FVatAmount := 0;
	FVatAmountHUF := 0;
	FGrossAmount := 0;
	FGrossAmountHUF := 0;
end;

// TInvoiceLines
constructor TInvoiceLines.Create( AOwner : TInvoice );
begin
  inherited Create( TInvoiceLine );
  FInvoice := AOwner;
end;

destructor TInvoiceLines.Destroy;
begin
	while ( Self.Count > 0 ) do begin
		Self.Items[ Self.Count - 1 ].Free;
		Self.Items[ Self.Count - 1 ].Destroy;
	end;
	inherited;
end;

function TInvoiceLines.Add : TInvoiceLine;
begin
	Result := TInvoiceLine( inherited Add );
	Result.FLine := 0;
	Result.FAlmiraCode := '00000000';
	Result.FCodeCategory := 'VTSZ';
	Result.FProductCode := '';
	Result.FProductName := '';
	Result.FProductUnit := '';
	Result.FVatCode := 0;
	Result.FVatPercent := 0;
	Result.FNAVVatCode := '';
	Result.FQuantity := 0;
	Result.FUnitPrice := 0;
	Result.FNetAmount := 0;
	Result.FNetAmountHUF := 0;
	Result.FVatAmount := 0;
	Result.FVatAmountHUF := 0;
	Result.FGrossAmount := 0;
	Result.FGrossAmountHUF := 0;
end;

function TInvoiceLines.GetItem( Index: integer) : TInvoiceLine;
begin
  Result := TInvoiceLine( inherited Items[ Index ]);
end;

function TInvoiceLines.Insert(Index: integer) : TInvoiceLine;
begin
  Result := TInvoiceLine( inherited Insert( Index ));
end;

procedure TInvoiceLines.SetItem( Index : integer; const Value : TInvoiceLine);
begin
  inherited Items[ Index ] := Value;
end;

// TInvoiceData
constructor TInvoice.Create;
begin
	inherited Create( NIL );
	FDirection := id_Outbound;
	FInvoiceNumber := '';
	FIssueDate := Now();
	FDeliveryDate := Now();
	FPaymentDate := Now();
	FPaymentMethod := 1;
	FCurrency := 'HUF';
	FExchangeRate := 1;
	FNetAmountHUF := 0;
	FNetAmount := 0;
	FVatAmountHUF := 0;
	FVatAmount := 0;
	FGrossAmountHUF := 0;
	FGrossAmount := 0;
	FOriginalInvoice := '';
	FNAVDate := Now();
	FSendSw := '';
	FRecordNumber := 0;
	FTransactionID := '';
	FRequestID := '';
	FCompressed := FALSE;
	FElectronic := ei_Normal;
	FApperance := 'PAPER';
	FStatusDateTime := Now;
	FResultText := '';
	FOperationType := '';
	FTestMode := tm_Test;
	FInvStatusNum := '';
	FInvStatus := '';
	FInvStatusText := '';
	FNAVError := '';
	FErrorText := '';
	FSendDateTime := Now();
	FSendMail := 0;
	FRequestDateTime := Now();
	FRequestVersion := rv_30;
	FXMLFile := '';;
	FSupplier := TFactory.Create;
	FSupplier.Name := '';
	FSupplier.FCode := 0;
	FSupplier.FAlmiraLetter := '';
	FSupplier.FNAVType := 0;
	FSupplier.FTaxPayerID := '';
	FSupplier.FVatCode := '';
	FSupplier.FCountyCode := '';
	FSupplier.FEUTAXID := '';
	FSupplier.FCountryCode := 'HU';
	FSupplier.FPostalCode := '';
	FSupplier.FCity := '';
	FSupplier.FAddress := '';
	FSupplier.FLogin := '';
	FSupplier.FPassword := '';
	FSupplier.FSignKey := '';
	FSupplier.FChangeKey := '';
	FCustomer := TFactory.Create;
	FCustomer.Name := '';
	FCustomer.FCode := 0;
	FCustomer.FAlmiraLetter := '';
	FCustomer.FNAVType := 0;
	FCustomer.FTaxPayerID := '';
	FCustomer.FVatCode := '';
	FCustomer.FCountyCode := '';
	FCustomer.FEUTAXID := '';
	FCustomer.FCountryCode := 'HU';
	FCustomer.FPostalCode := '';
	FCustomer.FCity := '';
	FCustomer.FAddress := '';
	FCustomer.FLogin := '';
	FCustomer.FPassword := '';
	FCustomer.FSignKey := '';
	FCustomer.FChangeKey := '';
	FInvoiceLines := TInvoiceLines.Create( Self );
end;

destructor TInvoice.Destroy;
begin
	while ( FInvoiceLines.Count > 0 ) do begin
		FInvoiceLines.Items[ FInvoiceLines.Count - 1 ].Destroy;
	end;
	FInvoiceLines.Destroy;
	FCustomer.Destroy;
	FSupplier.Destroy;
	Inherited;
end;

procedure TInvoice.WriteToDBF;
var
	cDirection,cTaxNumber							: string;
	cFactoryCode										: string[ 1 ];
	I														: integer;
begin
	WriteLogFile( 'Számla felírása a P38-ba.',2 );
	MainForm.AlmiraEnv.SetSoftSeek( FALSE );
// Megnyitjuk a P38-at két kulccsal
	if ( MainForm.DBFTable1.Active ) then begin
		MainForm.DBFTable1.Close;
	end;
	cFactoryCode := MainForm.CegekTable.FieldByName( 'KOD' ).AsString;
	MainForm.DBFTable1.DatabaseName := MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\';
	MainForm.DBFTable1.TableName := cFactoryCode + 'P38.DBF';
	try
		MainForm.DBFTable1.Open;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\' + cFactoryCode + 'P381.NTX' );
		MainForm.DBFTable1.IndexOpen( MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\' + cFactoryCode + 'P382.NTX' );
		MainForm.DBFTable1.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + cFactoryCode + 'P38.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
// Ha közösségi adószám
	WriteLogFile( 'P38 sikeresen megnyitva.',4 );
	if ( Self.Direction = id_Outbound ) then begin
		cTaxNumber := Self.Customer.TAXPayerID;
		cDirection := 'K';
	end else begin
		cTaxNumber := Self.Supplier.TAXPayerID;
		cDirection := 'B';
	end;
	WriteLogFile( 'Keresési kulcs :' + cDirection + '-' + PadR( cTaxNumber,20,' ' ) + '-' + PadR( Self.InvoiceNumber,50,' ' ),4 );
// Rákeresünk, hogy már van-e ilyen számla letöltve
	if ( MainForm.DBFTable1.Seek( cDirection + PadR( cTaxNumber,20,' ' ) + PadR( Self.InvoiceNumber,50,' ' ))) then begin
		WriteLogFile( 'Számla módosítása.',4 );
		MainForm.DBFTable1.Edit;
	end else begin
		WriteLogFile( 'Új Számla beszúrása.',4 );
		MainForm.DBFTable1.Append;
		MainForm.DBFTable1.FieldValues[ 'IRANY' ] := cDirection;
		MainForm.DBFTable1.FieldValues[ 'ADOSZAM' ] := cTaxNumber;
		MainForm.DBFTable1.FieldValues[ 'KSORSZAM' ] := Self.InvoiceNumber;
	end;
	if ( Self.Direction = id_Outbound ) then begin
		MainForm.DBFTable1.FieldValues[ 'PKOD' ] := IntToStr( Self.Customer.FCode );
		MainForm.DBFTable1.FieldValues[ 'NAVTIPUS' ] := Self.Customer.NAVType;
		MainForm.DBFTable1.FieldValues[ 'NEV' ] := Self.Customer.Name;
		MainForm.DBFTable1.FieldValues[ 'ORSZAG' ] := Self.Customer.CountryCode;
		MainForm.DBFTable1.FieldValues[ 'IRSZAM' ] := Self.Customer.PostalCode;
		MainForm.DBFTable1.FieldValues[ 'HELYSEG' ] := Self.Customer.City;
		MainForm.DBFTable1.FieldValues[ 'CIM' ] := Self.Customer.Address;
		MainForm.DBFTable1.FieldValues[ 'FULLADOSZ' ] := Self.Customer.FullTAXID;
		MainForm.DBFTable1.FieldValues[ 'KIADOSZAM' ] := Self.Supplier.FullTAXID;
	end else begin
		MainForm.DBFTable1.FieldValues[ 'PKOD' ] := IntToStr( Self.Supplier.FCode );
		MainForm.DBFTable1.FieldValues[ 'NAVTIPUS' ] := Self.Supplier.NAVType;
		MainForm.DBFTable1.FieldValues[ 'NEV' ] := Self.Supplier.Name;
		MainForm.DBFTable1.FieldValues[ 'ORSZAG' ] := Self.Supplier.CountryCode;
		MainForm.DBFTable1.FieldValues[ 'IRSZAM' ] := Self.Supplier.PostalCode;
		MainForm.DBFTable1.FieldValues[ 'HELYSEG' ] := Self.Supplier.City;
		MainForm.DBFTable1.FieldValues[ 'CIM' ] := Self.Supplier.Address;
		MainForm.DBFTable1.FieldValues[ 'FULLADOSZ' ] := Self.Supplier.FullTAXID;
		MainForm.DBFTable1.FieldValues[ 'KIADOSZAM' ] := Self.Customer.FullTAXID;
	end;
	MainForm.DBFTable1.FieldValues[ 'TELJ' ] := Self.DeliveryDate;
	MainForm.DBFTable1.FieldValues[ 'KELT' ] := Self.IssueDate;
	MainForm.DBFTable1.FieldValues[ 'HATARIDO' ] := Self.PaymentDate;
	MainForm.DBFTable1.FieldValues[ 'PENZNEM' ] := Self.Currency;
	MainForm.DBFTable1.FieldValues[ 'ARFOLYAM' ] := Self.ExchangeRate;
	MainForm.DBFTable1.FieldValues[ 'FIZMOD' ] := Self.PaymentMethod;
	MainForm.DBFTable1.FieldValues[ 'DEVNETTO' ] := Self.NetAmount;
	MainForm.DBFTable1.FieldValues[ 'NETTO' ] := Self.NetAmountHUF;
	MainForm.DBFTable1.FieldValues[ 'DEVAFA' ] := Self.VatAmount;
	MainForm.DBFTable1.FieldValues[ 'AFA' ] := Self.VatAmountHUF;
	MainForm.DBFTable1.FieldValues[ 'SENDDATE' ] := Self.NAVDate;
	MainForm.DBFTable1.FieldValues[ 'SENDTIME' ] := FormatDateTime( 'hh:mm:ss', Self.NAVDate );
	MainForm.DBFTable1.FieldValues[ 'EREDSZLA' ] := Self.OriginalInvoice;
	MainForm.DBFTable1.FieldValues[ 'SENDSW' ] := Self.SendSw;
	MainForm.DBFTable1.Post;
	MainForm.DBFTable1.Close;
	WriteLogFile( 'P38 állomány lezárása.',4 );
	MainForm.DBFTable1.DatabaseName := MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\';
	MainForm.DBFTable1.TableName := cFactoryCode + 'P39.DBF';
	try
		MainForm.DBFTable1.Open;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\' + cFactoryCode + 'P391.NTX' );
		MainForm.DBFTable1.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + cFactoryCode + 'P39.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
	WriteLogFile( 'P39 sikeresen megnyitva.',4 );
	for I := 0 to Self.InvoiceLines.Count - 1 do begin
		WriteLogFile( 'Számla sorok felírása' + IntToStr( I + 1 ) + '. sor',4 );
		Reading.NewLine := Self.InvoiceLines.Items[ I ];
		WriteLogFile( 'Keresési kulcs :' + cDirection + '-' + PadR( cTaxNumber,20,' ' ) + '-' + PadR( Self.InvoiceNumber,50,' ' ) + '-' + PadL( Trim( IntToStr( Reading.NewLine.Sor)), 3, ' ' ),4 );
		if ( MainForm.DBFTable1.Seek( cDirection + PadR( cTaxNumber,20,' ' ) + PadR( Self.InvoiceNumber,50,' ' ) + PadL( Trim( IntToStr( Reading.NewLine.Sor)), 3, ' ' ))) then begin
			WriteLogFile( 'Számlasor módosítása.',4 );
			MainForm.DBFTable1.Edit;
		end else begin
			WriteLogFile( 'Új számlasor beszúrása.',4 );
			MainForm.DBFTable1.Append;
			MainForm.DBFTable1.FieldValues[ 'IRANY' ] := cDirection;
			MainForm.DBFTable1.FieldValues[ 'ADOSZAM' ] := cTaxNumber;
			MainForm.DBFTable1.FieldValues[ 'KSORSZAM' ] := Self.InvoiceNumber;
			MainForm.DBFTable1.FieldValues[ 'SOR' ] := Reading.NewLine.Sor;
		end;
		MainForm.DBFTable1.FieldValues[ 'ASZ' ] := Reading.NewLine.AlmiraCode;
		MainForm.DBFTable1.FieldValues[ 'AFAKOD' ] := Reading.NewLine.VatCode;
		MainForm.DBFTable1.FieldValues[ 'VTSZ' ] := Reading.NewLine.ProductCode;
		MainForm.DBFTable1.FieldValues[ 'NEV' ] := Reading.NewLine.ProductName;
		MainForm.DBFTable1.FieldValues[ 'ME' ] := Reading.NewLine.ProductUnit;
		MainForm.DBFTable1.FieldValues[ 'MENNY' ] := Reading.NewLine.Quantity;
		MainForm.DBFTable1.FieldValues[ 'AFASZAZ' ] := Reading.NewLine.VatPercent;
		MainForm.DBFTable1.FieldValues[ 'NULLAFA' ] := Reading.NewLine.NAVVatCode;
		MainForm.DBFTable1.FieldValues[ 'EGYSAR' ] := Reading.NewLine.UnitPrice;
		MainForm.DBFTable1.FieldValues[ 'DEVEGYSAR' ] := Reading.NewLine.UnitPrice;
		MainForm.DBFTable1.FieldValues[ 'DEVNETTO' ] := Reading.NewLine.NetAmount;
		MainForm.DBFTable1.FieldValues[ 'NETTO' ] := Reading.NewLine.NetAmountHUF;
		MainForm.DBFTable1.FieldValues[ 'DEVAFA' ] := Reading.NewLine.VatAmount;
		MainForm.DBFTable1.FieldValues[ 'AFA' ] := Reading.NewLine.VatAmountHUF;
		MainForm.DBFTable1.Post;
	end;
	MainForm.DBFTable1.Close;
	WriteLogFile( 'Számlasor felírása kész.',4 );
end;

procedure TInvoice.ClearStatusData;
begin
	InvStatusNum := '0';
	InvStatusText := '';
	InvStatus := '';
	NAVError := '0';
//	TransactionID := '';
	ResultText := '';
	ErrorText := '';
	StatusDateTime := Now;
end;

procedure TInvoice.SetNAVStatus;
begin
	MainForm.DBFTable1.DatabaseName := ExtractFilePath( MainForm.NAVASzSettings.cDBFPath );
	MainForm.DBFTable1.TableName := ExtractFileName( MainForm.NAVASzSettings.cDBFPath );
	try
		MainForm.DBFTable1.Open;
// Ha sikerült a DBF file megnyitása, akkor újraolvassuk
		if ( MainForm.DBFTable1.Active ) then begin
			MainForm.DBFTable1.First;
			MainForm.DBFTable1.MoveBy( Self.RecordNumber - 1 );
			MainForm.DBFTable1.Edit;
			MainForm.DBFTable1.FieldValues[ 'STATUS' ] := Self.InvStatusNum;
			MainForm.DBFTable1.FieldValues[ 'NAVERROR' ] := Self.NAVError;
			if Self.InvStatusNum < '5' then begin
				MainForm.DBFTable1.FieldValues[ 'INVSTATUS' ] := '';
			end;
			if Self.InvStatusNum = '2' then begin
				MainForm.DBFTable1.FieldValues[ 'REQDATE' ] := Self.RequestDateTime;
				MainForm.DBFTable1.FieldValues[ 'REQTIME' ] := FormatDateTime( 'hh:mm:ss',Self.RequestDateTime );
				MainForm.DBFTable1.FieldValues[ 'REQVER' ] := Self.RequestVersion;
			end else begin
				MainForm.DBFTable1.FieldValues[ 'RESDATE' ] := Self.StatusDateTime;
				MainForm.DBFTable1.FieldValues[ 'RESTIME' ] := FormatDateTime( 'hh:mm:ss',Self.StatusDateTime );
			end;
			if Self.ResultText <> '' then begin
				MainForm.DBFTable1.FieldValues[ 'RESULT' ] := Self.ResultText;
			end;
			if Self.TransactionID <> '' then begin
				MainForm.DBFTable1.FieldValues[ 'ACTIONID' ] := Self.TransactionID;
			end;
			if Self.InvStatusText <> '' then begin
				MainForm.DBFTable1.FieldValues[ 'STATUSTEXT' ] := Self.InvStatusText;
			end;
			if Self.InvStatus <> '' then begin
				MainForm.DBFTable1.FieldValues[ 'INVSTATUS' ] := Self.InvStatus;
			end;
			if Self.ErrorText <> '' then begin
				MainForm.DBFTable1.FieldValues[ 'ERRORTEXT' ] := Self.ErrorText;
			end;
			MainForm.DBFTable1.FieldValues[ 'SENDMAIL' ] := Self.SendMail;
			MainForm.DBFTable1.Post;
			MainForm.DBFTable1.Close;
		end;
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a NAV.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;
end;

// TInvoiceList
constructor TInvoiceList.Create;
begin
  inherited Create( TInvoice );
end;

destructor TInvoiceList.Destroy;
begin
	while ( Self.Count > 0 ) do begin
//		Self.Delete( 0 );
//		Self.Items[ Self.Count - 1 ].Free;
//		Self.Items[ Self.Count - 1 ].FCustomer.Destroy;
//		Self.Items[ Self.Count - 1 ].FSupplier.Destroy;
		Self.Items[ Self.Count - 1 ].Destroy;
	end;
	inherited;
end;

procedure TInvoiceList.Clear;
begin
	while ( Self.Count > 0 ) do begin
		Self.Items[ Self.Count - 1 ].Destroy;
//		Self.Delete( Self.Count - 1 );
	end;
	inherited;
end;

function TInvoiceList.GetItem( Index: integer) : TInvoice;
begin
  Result := TInvoice( inherited Items[ Index ]);
end;

function TInvoiceList.Insert(Index: integer) : TInvoice;
begin
  Result := TInvoice( inherited Insert( Index ));
end;

procedure TInvoiceList.SetItem( Index : integer; const Value : TInvoice);
begin
  inherited Items[ Index ] := Value;
end;

function TInvoiceList.Add : TInvoice;
begin
	Result := TInvoice( inherited Add );
	Result.FDirection := id_Outbound;
	Result.FInvoiceNumber := '';
	Result.FIssueDate := Now();
	Result.FDeliveryDate := Now();
	Result.FPaymentDate := Now();
	Result.FPaymentMethod := 1;
	Result.FCurrency := 'HUF';
	Result.FExchangeRate := 1;
	Result.FNetAmountHUF := 0;
	Result.FNetAmount := 0;
	Result.FVatAmountHUF := 0;
	Result.FVatAmount := 0;
	Result.FGrossAmountHUF := 0;
	Result.FGrossAmount := 0;
	Result.FOriginalInvoice := '';
	Result.FNAVDate := Now();
	Result.FSendSw := '';
	Result.FRecordNumber := 0;
	Result.FTransactionID := '';
	Result.FRequestID := '';
	Result.FCompressed := FALSE;
	Result.FElectronic := ei_Normal;
	Result.FApperance := 'PAPER';
	Result.FStatusDateTime := Now;
	Result.FResultText := '';
	Result.FOperationType := '';
	Result.FTestMode := tm_Test;
	Result.FInvStatusNum := '';
	Result.FInvStatus := '';
	Result.FInvStatusText := '';
	Result.FNAVError := '';
	Result.FErrorText := '';
	Result.FSendDateTime := Now();
	Result.FSendMail := 0;
	Result.FRequestDateTime := Now();
	Result.FRequestVersion := rv_30;
	Result.FXMLFile := '';;
	Result.FSupplier := TFactory.Create;
	Result.FSupplier.Name := '';
	Result.FSupplier.FCode := 0;
	Result.FSupplier.FAlmiraLetter := '';
	Result.FSupplier.FNAVType := 0;
	Result.FSupplier.FTaxPayerID := '';
	Result.FSupplier.FVatCode := '';
	Result.FSupplier.FCountyCode := '';
	Result.FSupplier.FEUTAXID := '';
	Result.FSupplier.FCountryCode := 'HU';
	Result.FSupplier.FPostalCode := '';
	Result.FSupplier.FCity := '';
	Result.FSupplier.FAddress := '';
	Result.FSupplier.FLogin := '';
	Result.FSupplier.FPassword := '';
	Result.FSupplier.FSignKey := '';
	Result.FSupplier.FChangeKey := '';
	Result.FCustomer := TFactory.Create;
	Result.FCustomer.Name := '';
	Result.FCustomer.FCode := 0;
	Result.FCustomer.FAlmiraLetter := '';
	Result.FCustomer.FNAVType := 0;
	Result.FCustomer.FTaxPayerID := '';
	Result.FCustomer.FVatCode := '';
	Result.FCustomer.FCountyCode := '';
	Result.FCustomer.FEUTAXID := '';
	Result.FCustomer.FCountryCode := 'HU';
	Result.FCustomer.FPostalCode := '';
	Result.FCustomer.FCity := '';
	Result.FCustomer.FAddress := '';
	Result.FCustomer.FLogin := '';
	Result.FCustomer.FPassword := '';
	Result.FCustomer.FSignKey := '';
	Result.FCustomer.FChangeKey := '';
	Result.FInvoiceLines := TInvoiceLines.Create( Result );
end;


end.
