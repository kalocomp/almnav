unit Reading;

interface

uses crypt, System.ZLib, Math, Forms, System.Variants, DB, NAV, NAVRead, INvoice;

procedure ReadFactories( InSave : boolean );
procedure ReadFactory( InSave : boolean; InInvoiceDirection : TInvoiceDirection );
function ReadInvoiceList( InTesting, InSave : boolean; InInvoiceDirection : TInvoiceDirection; InTaxNumber : string; InStartDate, InEndDate : TDate; InPage : integer ) : integer;
function ReadInvoiceData( InSave : boolean; InInvoiceDirection : TInvoiceDirection; InTaxNumber, InInvoiceNumber : string ) : string;
procedure WriteInvoice( InSave : boolean; InFactoryCode, InXMLFile : string; InInvoiceDirection : TInvoiceDirection );
function DecodeInvoiceData( InSave : boolean; InInvoiceData, InXMLFile : string; InInvoice : TInvoice ) : TInvoice;

var
	NewLine									: TInvoiceLine;

implementation

uses WinApi.Windows, XMLIntf, xmlhandler, main, System.SysUtils, System.DateUtils, Classes,
	XMLDoc, DCPBase64, Vcl.ExtCtrls;

function Unzip(const zipped: string): string;
var
  DecompressionStream: TDecompressionStream;
  Compressed: TStringStream;
  Decompressed: TStringStream;
begin
  Compressed := TStringStream.Create( AnsiString( zipped ));
  try
// window bits set to 15 + 16 for gzip
	 DecompressionStream := TDecompressionStream.Create(Compressed, 15 + 16);
	 try
		Decompressed := TStringStream.Create('', TEncoding.UTF8);
		try
		  Decompressed.LoadFromStream(DecompressionStream);
		  Result := Decompressed.DataString;
		finally
		  Decompressed.Free;
		end;
	 finally
		DecompressionStream.Free;
	 end;
  finally
	 Compressed.Free;
  end;
end;

// Cégek végigolvasása
procedure ReadFactories( InSave : boolean );
begin
	NAVReadForm.StatusLabel.Caption := 'Letöltés folyamatban...';
	NAVReadForm.ReadButton.Enabled := FALSE;
	NAVReadForm.TestButton.Enabled := FALSE;
//	MainForm.MyShowBalloonHint( 'Figyelem!!!', 'NAV adatok letöltése folyamatban...', bfInfo );
	WriteLogFile( 'NAV adatolvasás megkezdése',2 );
	MainForm.CegekTable.First;
	while ( not MainForm.CegekTable.Eof ) do begin
		if ( MainForm.CegekTable.FieldByName( 'NAVREAD' ).AsString = '3' ) or
			( MainForm.CegekTable.FieldByName( 'NAVREAD' ).AsString = '1' ) then begin
			WriteLogFile( MainForm.CegekTable.FieldByName( 'NEV' ).AsString + ' kimenő számláinak olvasása',2 );
			ReadFactory( InSave, id_Outbound );
		end;
		if ( MainForm.CegekTable.FieldByName( 'NAVREAD' ).AsString = '3' ) or
			( MainForm.CegekTable.FieldByName( 'NAVREAD' ).AsString = '2' ) then begin
			WriteLogFile( MainForm.CegekTable.FieldByName( 'NEV' ).AsString + ' beérkező számláinak olvasása',2 );
			ReadFactory( InSave, id_Inbound );
		end;
		MainForm.NAVReadSettings.LastRead := Now;
		NAVReadForm.LastReadLabel.Caption := FormatDateTime( 'YYYY-MM-DD hh:mm:ss', MainForm.NAVReadSettings.LastRead );
		NAVReadForm.NextReadLabel.Caption := FormatDateTime( 'YYYY-MM-DD hh:mm:ss', IncDay( MainForm.NAVReadSettings.LastRead, MainForm.NAVReadSettings.ReadInterval ));
		MainForm.CegekTable.Next;
		Application.ProcessMessages;
	end;
	NAVReadForm.ReadButton.Enabled := TRUE;
	NAVReadForm.TestButton.Enabled := TRUE;
	NAVReadForm.StatusLabel.Caption := 'Várakozás...';
end;

// Egy cég számláinak olvasása
procedure ReadFactory( InSave : boolean; InInvoiceDirection : TInvoiceDirection );
var
	dLastInDate,dLastOutDate,dEndDate,dStartDate			: TDate;
	nActPage, nMaxPage											: integer;
	XMLFile,XMLInvoice,XMLInvData								: IXMLDocument;
	MainNode,Level1Node,Level2Node							: IXMLNode;
	Level3Node														: IXMLNode;
	UTCDateTime														: TSystemTime;
	I,nCurrentPage,nAvailablePage,nInvoices				: integer;
	lMustRead														: boolean;
	cFactoryCode,cIrany,cTaxNumber							: string;
	cXMLFile,cStartDate,cEndDate								: string;
	cPassHash,cKey,cRequestID,cFileName						: string;
	cLogin,cPassword,cSignKey,cNewFileName					: string;
	cInvNumber,cInvDate											: string;
begin
	cFactoryCode := MainForm.CegekTable.FieldByName( 'KOD' ).AsString;
	cTaxNumber := Copy( MainForm.CegekTable.FieldByName( 'ADOSZAM').AsString,1,8 );
	MainForm.DBFTable1.DatabaseName := MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\';
	MainForm.DBFTable1.TableName := cFactoryCode + 'P38.DBF';
	try
		MainForm.DBFTable1.OEMTranslate := TRUE;
		MainForm.DBFTable1.Open;
//		MainForm.DBFTable1.IndexOpen( MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\' + cFactoryCode + 'P381.NTX' );
//		MainForm.DBFTable1.SetOrder( 1 );
		MainForm.DBFTable1.SetOrder( 0 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + cFactoryCode + 'P38.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
	dLastInDate := 0;
	dLastOutDate := 0;
	MainForm.DBFTable1.First;
	WriteLogFile( 'Legutolsó számla megkeresése',2 );
	while ( not MainForm.DBFTable1.Eof ) do begin
// Megkeressük a legutolsó beolvasott kimenő számlát
		if (( MainForm.DBFTable1.FieldByName( 'IRANY' ).AsString = 'K' ) and ( InInvoiceDirection = id_Outbound )) then begin
			if ( dLastOutDate < MainForm.DBFTable1.FieldByName( 'SENDDATE' ).AsDateTime ) then begin
				dLastOutDate := MainForm.DBFTable1.FieldByName( 'SENDDATE' ).AsDateTime;
			end;
//			WriteLogFile( IntToStr( MainForm.DBFTable1.RecNo ) + ' rekord - ' + FormatDateTime( 'YYYY.MM.DD', MainForm.DBFTable1.FieldByName( 'SENDDATE' ).AsDateTime ) + ' - ' + FormatDateTime( 'YYYY.MM.DD', dLastOutDate ),4 );
		end;
// Megkeressük a legutolsó beolvasott bejövő számlát
		if (( MainForm.DBFTable1.FieldByName( 'IRANY' ).AsString = 'B' ) and ( InInvoiceDirection = id_Inbound )) then begin
			if ( dLastInDate < MainForm.DBFTable1.FieldByName( 'SENDDATE' ).AsDateTime ) then begin
				dLastInDate := MainForm.DBFTable1.FieldByName( 'SENDDATE' ).AsDateTime;
			end;
//			WriteLogFile( IntToStr( MainForm.DBFTable1.RecNo ) + ' rekord - ' + FormatDateTime( 'YYYY.MM.DD', MainForm.DBFTable1.FieldByName( 'SENDDATE' ).AsDateTime ) + ' - ' + FormatDateTime( 'YYYY.MM.DD', dLastInDate ),4 );
		end;
		MainForm.DBFTable1.Next;
		NAVReadForm.Refresh;
		Application.ProcessMessages;
	end;
	MainForm.DBFTable1.Close;
	WriteLogFile( 'Legutolsó kimenő számla dátuma: ' + FormatDateTime( 'YYYY.MM.DD', dLastOutDate ),2 );
	WriteLogFile( 'Legutolsó bejövő számla dátuma: ' + FormatDateTime( 'YYYY.MM.DD', dLastInDate ),2 );
	dLastOutDate := IncDay( dLastOutDate, - MainForm.NAVReadSettings.BackDays );
	dLastInDate := IncDay( dLastInDate, - MainForm.NAVReadSettings.BackDays );
	if ( InInvoiceDirection = id_Inbound ) then begin
		dStartDate := Max( dLastInDate, MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].StartDate );
		dEndDate := Min( Now, IncDay( dStartDate, 30 ));
		cIrany := 'B';
		WriteLogFile( 'Beérkező számla lista lekérése a NAV-tól',2 );
	end else begin
		dStartDate := Max( dLastOutDate, MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].StartDate );
		dEndDate := Min( Now, IncDay( dStartDate, 30 ));
		cIrany := 'K';
		WriteLogFile( 'Kimenő számla lista lekérése a NAV-tól',2 );
	end;
	repeat
		WriteLogFile( 'Időszak: ' + FormatDateTime( 'YYYY-MM-DD', dStartDate ) + ' - ' + FormatDateTime( 'YYYY-MM-DD', dEndDate ) + '-ig',4 );
		nMaxPage := 999;
		nActPage := 1;
		while ( nActPage <= nMaxPage ) do begin
			nMaxPage := ReadInvoiceList( FALSE, InSave, InInvoiceDirection, cTaxNumber, dStartDate, dEndDate, nActPage );
			WriteLogFile( 'Számlalista lekérése ' + IntToStr( nMaxPage ) + ' oldalból ' + IntToStr( nActPage ) + ' oldal lekérve.',4 );
			Inc( nActPage );
		end;
		dStartDate := IncDay( dEndDate, 1 );
		dEndDate := Min( Now, IncDay( dStartDate, 30 ));
	until ( dStartDate > Now());
end;

// Számla lista beolvasása a NAV rendszerből
function ReadInvoiceList( InTesting, InSave : boolean; InInvoiceDirection : TInvoiceDirection; InTaxNumber : string; InStartDate, InEndDate : TDate; InPage : integer ) : integer;
var
	dLastInDate,dLastOutDate,dEndDate,dStartDate			: TDate;
	nActPage, nMaxPage											: integer;
	XMLFile,XMLInvoice,XMLInvData								: IXMLDocument;
	MainNode,Level1Node,Level2Node							: IXMLNode;
	Level3Node														: IXMLNode;
	UTCDateTime														: TSystemTime;
	I,nCurrentPage,nAvailablePage,nInvoices				: integer;
	lMustRead														: boolean;
	cFactoryCode,cIrany,cTaxNumber							: string;
	cXMLFile,cStartDate,cEndDate								: string;
	cPassHash,cKey,cRequestID,cFileName						: string;
	cLogin,cPassword,cSignKey,cNewFileName					: string;
	cInvNumber,cInvDate											: string;
begin
	Result := 0;
	if ( InInvoiceDirection = id_Inbound ) then cIrany := 'B' else cIrany := 'K';
	cFactoryCode := MainForm.CegekTable.FieldByName( 'KOD' ).AsString;
	if ( MainForm.NAVReadSettings.ReadMode = tm_Test ) then begin
		cLogin := MainForm.CegekTable.FieldByName( 'LOGINTEST' ).AsString;
		cPassword := MainForm.CegekTable.FieldByName( 'PASSWORDTEST' ).AsString;
		cSignKey := MainForm.CegekTable.FieldByName( 'SIGNKEYTEST' ).AsString;
	end else begin
		cLogin := MainForm.CegekTable.FieldByName( 'LOGIN' ).AsString;
		cPassword := MainForm.CegekTable.FieldByName( 'PASSWORD' ).AsString;
		cSignKey := MainForm.CegekTable.FieldByName( 'SIGNKEY' ).AsString;
	end;
	cStartDate := FormatDateTime( 'yyyy-mm-dd', InStartDate );
//		cStartDate := '2021-01-20';
	cEndDate := FormatDateTime( 'yyyy-mm-dd', InEndDate );
	WriteLogFile( 'Számla lekérése: ' + cStartDate + ' - ' + cEndDate + ' dátumig',2 );
	XMLFile := NewXMLDocument;
	XMLFile.Options := [ doNodeAutoIndent ];
	XMLFile.Active;
	GetSystemTime( UTCDateTime );
	WriteLogFile( 'Login : ' + cLogin, 4 );
	cPassHash := MakeSHA512( cPassword );
	cRequestID := 'R' + MainForm.CegekTable.FieldByName( 'KOD' ).AsString + FormatDateTime( 'ddhhmmsszzz', Now );
	WriteLogFile( 'Jelszó : ' + cPassword, 4 );
	WriteLogFile( 'Titkosított jelszó : ' + cPassHash,4 );
	cKey := cRequestId + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + cSignKey;
	MainNode := XMLFile.CreateNode( 'QueryInboundInvoices', ntComment );
	XMLFile.ChildNodes.Add( MainNode );
	MainNode.Text := 'A ceg neve: ' + MainForm.CegekTable.FieldByName( 'NEV' ).AsString;
	MainNode := XMLFile.AddChild( 'QueryInvoiceDigestRequest' );
	XMLInsertSchemas( MainNode );
	Level1Node := MainNode.AddChild( cNAVCommonSchema + 'header' );
	Level1Node.AddChild( cNAVCommonSchema + 'requestId' ).Text := cRequestId;
	Level1Node.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
	Level1Node.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := GetNAVVersion( MainForm.AppSettings.NAVVersion );
	Level1Node.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
	Level1Node := MainNode.AddChild( cNAVCommonSchema + 'user' );
	Level1Node.AddChild( cNAVCommonSchema + 'login' ).Text := cLogin;
	Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'passwordHash' );
	Level2Node.Text := UpperCase( cPassHash );
	Level2Node.Attributes[ 'cryptoType' ] := 'SHA-512';
	Level1Node.AddChild( cNAVCommonSchema + 'taxNumber' ).Text := Copy( MainForm.CegekTable.FieldByName( 'ADOSZAM' ).AsString,1,8 );
	Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'requestSignature' );
	Level2Node.Text := UpperCase( MakeSHA3512( cKey ));
	Level2Node.Attributes[ 'cryptoType' ] := 'SHA3-512';
	Level1Node := MainNode.AddChild( 'software' );
	Level1Node.AddChild( 'softwareId' ).Text := NAV.SoftwareData.ID;
	Level1Node.AddChild( 'softwareName' ).Text := NAV.SoftwareData.Name;
	Level1Node.AddChild( 'softwareOperation' ).Text := NAV.SoftwareData.Operation;
	Level1Node.AddChild( 'softwareMainVersion' ).Text := NAV.SoftwareData.MainVersion;
	Level1Node.AddChild( 'softwareDevName' ).Text := NAV.SoftwareData.DevName;
	Level1Node.AddChild( 'softwareDevContact' ).Text := NAV.SoftwareData.DevContact;
	Level1Node.AddChild( 'softwareDevCountryCode' ).Text := NAV.SoftwareData.DevCountryCode;
	Level1Node.AddChild( 'softwareDevTaxNumber' ).Text := NAV.SoftwareData.DevTaxNumber;
	MainNode.AddChild( 'page' ).Text := IntToStr( InPage );
	if ( InInvoiceDirection = id_Inbound ) then begin
		MainNode.AddChild( 'invoiceDirection' ).Text := 'INBOUND';
	end else begin
		MainNode.AddChild( 'invoiceDirection' ).Text := 'OUTBOUND';
	end;
	Level1Node := MainNode.AddChild( 'invoiceQueryParams' );
	Level2Node := Level1Node.AddChild( 'mandatoryQueryParams' );
	Level3Node := Level2Node.AddChild( 'invoiceIssueDate' );
	Level3Node.AddChild( 'dateFrom' ).Text := cStartDate;
	Level3Node.AddChild( 'dateTo' ).Text := cEndDate;
	cFileName := cRequestId + '.xml';
	try
		try
			cXMLFile := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
			XMLFile := LoadXMLData( cXMLFile );
			XMLFile.Encoding := 'utf-8';
			WriteLogFile( 'XML file elkészítése (' + cFileName + ')',3 );
			XMLFile.SaveToFile( MainForm.AppSettings.cSendPath + '\' + cFileName );
			WriteLogFile( 'XML file elkészítése megtörtént (' + MainForm.AppSettings.cSendPath + '\' + cFileName + ')',3 );
		finally
			XMLFile.Active := FALSE;
		end;
	except
		on E: Exception do begin
			WriteLogFile( 'Hiba az XML file elkészítésekor',3 );
			WriteLogFile( E.ClassName + ': ' + E.Message,3 );
		end;
	end;
	WriteLogFile( 'XML file küldése indul (' + cRequestID + '.xml)',3 );
	MainForm.Refresh;
	Application.ProcessMessages;
	cFileName := SendXML( cFileName, MainForm.NAVReadSettings.ReadMode, nQInvoiceDigest );
	if cFileName <> '' then begin
		WriteLogFile( 'Számla lista lekérve a NAV-tól',2 );
		XMLFile := LoadXMLDocument( MainForm.AppSettings.cReceivePath + '\' + cFileName );
		MainNode := XMLFile.ChildNodes.FindNode( 'QueryInvoiceDigestResponse' );
		Level1Node := MainNode.ChildNodes.FindNode( 'header','' );
		Level2Node := Level1Node.ChildNodes.FindNode( 'requestId','' );
		if cRequestId = Level2Node.Text then begin
			Level1Node := MainNode.ChildNodes.FindNode( 'result','' );
			Level2Node := Level1Node.ChildNodes.FindNode( 'funcCode','' );
			if Level2Node.Text = 'OK' then begin
				Level1Node := MainNode.ChildNodes.FindNode( 'invoiceDigestResult','' );
				if Level1Node <> NIL then begin
					Level2Node := Level1Node.ChildNodes.FindNode( 'currentPage','' );
					nCurrentPage := StrToInt( Level2Node.Text );
					Level2Node := Level1Node.ChildNodes.FindNode( 'availablePage','' );
					nAvailablePage := StrToInt( Level2Node.Text );
					nInvoices := Level1Node.ChildNodes.Count - 2;
					WriteLogFile( 'Számlák :' + IntToStr( nCurrentPage ) + '/' + IntToStr( nAvailablePage ) + ' (' + IntToStr( nInvoices ) + ' db számla )',3 );
					for I := 0 to nInvoices + 1 do begin
						Level2Node := Level1Node.ChildNodes[ I ];
						if ( Level2Node <> NIL ) and ( AnsiPos( 'invoiceDigest', Level2Node.NodeName ) <> 0 ) then begin
							if ( InInvoiceDirection = id_Inbound ) then begin
								cTaxNumber := ReadNodeText( Level2Node, 'supplierTaxNumber' );
							end else begin
								if ( Level2Node.ChildNodes.FindNode( 'customerTaxNumber' ) <> NIL ) then begin
									cTaxNumber := ReadNodeText( Level2Node, 'customerTaxNumber' );
								end else begin
									cTaxNumber := '*';
								end;
							end;
							cInvNumber := ReadNodeText( Level2Node, 'invoiceNumber' );
							cInvDate := ReadNodeText( Level2Node, 'insDate' );
							WriteLogFile( 'A számla keresése:' + cInvNumber, 1 );
							WriteLogFile( 'Keresési kulcs :' + cIrany + '-' + PadR( cTaxNumber,20,' ' ) + '-' + PadR( cInvNumber,50,' ' ),4 );
							MainForm.AlmiraEnv.SetSoftSeek( FALSE );
							lMustRead := FALSE;
// Ha a TESZT programból hívjuk, akkor mindig rögzítünk
							if ( InTesting ) then begin
								WriteLogFile( 'Teszt:' + cInvNumber, 1 );
								lMustRead := TRUE;
							end;
// Megnyitjuk a P38-at
							MainForm.DBFTable1.Close;
							MainForm.DBFTable1.DatabaseName := MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\';
							MainForm.DBFTable1.TableName := cFactoryCode + 'P38.DBF';
							try
								MainForm.DBFTable1.Open;
								MainForm.DBFTable1.IndexOpen( MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.CegekTable.FieldByName( 'NAVREADITEM' ).AsInteger ].AlmiraSharePath + '\' + cFactoryCode + '\' + cFactoryCode + 'P381.NTX' );
								MainForm.DBFTable1.SetOrder( 1 );
							except
								on E : Exception do begin
									WriteLogFile( 'Hiba a ' + cFactoryCode + 'P38.DBF állomány megnyitásakor :' + E.Message,2 );
									Exit;
								end;
							end;
// Rákeresünk, hogy már van-e ilyen számla letöltve
							if ( not ( MainForm.DBFTable1.Seek( cIrany + PadR( cTaxNumber,20,' ' ) + PadR( cInvNumber,50,' ' )))) then begin
								WriteLogFile( 'A új számla:' + cInvNumber, 1 );
								lMustRead := TRUE;
							end;
							WriteLogFile( 'Rekordmutató : ' + IntToStr( MainForm.DBFTable1.RecNo), 1 );
							MainForm.DBFTable1.Close;
							if ( lMustRead ) then begin
								NAVReadForm.InvoiceLabel.Caption := 'Beolvasás: ' + cInvNumber;
								NAVReadForm.Refresh;
								cNewFileName := ReadInvoiceData( InSave, InInvoiceDirection, cTaxNumber, cInvNumber );
								if cNewFileName <> '' then begin
									NAVReadForm.InvoiceLabel.Caption := cIrany + '-' + Trim( MainForm.CegekTable.FieldByName( 'NEV' ).AsString ) + ' írás: ' + cInvNumber;
									NAVReadForm.Refresh;
									WriteInvoice( InSave, cFactoryCode, cNewFileName, InInvoiceDirection );
								end;
							end else begin
								WriteLogFile( 'Már létező számla: ' + cInvNumber, 1 );
							end;
						end;
					end;
				end;
			end;
		end;
		XMLFile.Active := FALSE;
		if ( MainForm.AppSettings.nLogLevel < 4 ) then begin
			DeleteFile( MainForm.NAVReadSettings.XMLInvoicePath + cFileName );
		end;
		MainForm.DBFTable1.Close;
	end;
	Result := nAvailablePage;
end;

// Egy számla adatainak beolvasása
function ReadInvoiceData( InSave : boolean; InInvoiceDirection : TInvoiceDirection; InTaxNumber, InInvoiceNumber : string ) : string;
var
	XMLFile,XMLInvoice,XMLInvData					: IXMLDocument;
	MainNode,Level1Node,Level2Node				: IXMLNode;
	Level3Node											: IXMLNode;
	UTCDateTime											: TSystemTime;
	cPassHash,cKey,cRequestID,cFileName			: string;
	cLogin,cPassword,cSignKey,cIrany				: string;
	cXMLFile												: string;
begin
	WriteLogFile( 'Számla adat lekérése a NAV-tól : ' + InInvoiceNumber,2 );
	Result := '';
	XMLFile := NewXMLDocument;
	XMLFile.Options := [ doNodeAutoIndent ];
	XMLFile.Active;
	GetSystemTime( UTCDateTime );
	if ( MainForm.NAVReadSettings.ReadMode = tm_Test ) then begin
		cLogin := MainForm.CegekTable.FieldByName( 'LOGINTEST' ).AsString;
		cPassword := MainForm.CegekTable.FieldByName( 'PASSWORDTEST' ).AsString;
		cSignKey := MainForm.CegekTable.FieldByName( 'SIGNKEYTEST' ).AsString;
	end else begin
		cLogin := MainForm.CegekTable.FieldByName( 'LOGIN' ).AsString;
		cPassword := MainForm.CegekTable.FieldByName( 'PASSWORD' ).AsString;
		cSignKey := MainForm.CegekTable.FieldByName( 'SIGNKEY' ).AsString;
	end;
	cPassHash := MakeSHA512( cPassword );
	cRequestID := 'I' + MainForm.CegekTable.FieldByName( 'KOD' ).AsString + FormatDateTime( 'ddhhmmsszzz', Now );
	cKey := cRequestID + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + cSignKey;
	MainNode := XMLFile.CreateNode( 'InvoiceNumber', ntComment );
	XMLFile.ChildNodes.Add( MainNode );
	MainNode := XMLFile.AddChild( 'QueryInvoiceDataRequest' );
	XMLInsertSchemas( MainNode );
	Level1Node := MainNode.AddChild( cNAVCommonSchema + 'header' );
	Level1Node.AddChild( cNAVCommonSchema + 'requestId' ).Text := cRequestId;
	Level1Node.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
	Level1Node.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := GetNAVVersion( MainForm.AppSettings.NAVVersion );
	Level1Node.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
	Level1Node := MainNode.AddChild( cNAVCommonSchema + 'user' );
	Level1Node.AddChild( cNAVCommonSchema + 'login' ).Text := cLogin;
	Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'passwordHash' );
	Level2Node.Text := UpperCase( cPassHash );
	Level2Node.Attributes[ 'cryptoType' ] := 'SHA-512';
	Level1Node.AddChild( cNAVCommonSchema + 'taxNumber' ).Text := Copy( MainForm.CegekTable.FieldByName( 'ADOSZAM' ).AsString,1,8 );
	Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'requestSignature' );
	Level2Node.Text := UpperCase( MakeSHA3512( cKey ));
	Level2Node.Attributes[ 'cryptoType' ] := 'SHA3-512';
	Level1Node := MainNode.AddChild( 'software' );
	Level1Node.AddChild( 'softwareId' ).Text := NAV.SoftwareData.ID;
	Level1Node.AddChild( 'softwareName' ).Text := NAV.SoftwareData.Name;
	Level1Node.AddChild( 'softwareOperation' ).Text := NAV.SoftwareData.Operation;
	Level1Node.AddChild( 'softwareMainVersion' ).Text := NAV.SoftwareData.MainVersion;
	Level1Node.AddChild( 'softwareDevName' ).Text := NAV.SoftwareData.DevName;
	Level1Node.AddChild( 'softwareDevContact' ).Text := NAV.SoftwareData.DevContact;
	Level1Node.AddChild( 'softwareDevCountryCode' ).Text := NAV.SoftwareData.DevCountryCode;
	Level1Node.AddChild( 'softwareDevTaxNumber' ).Text := NAV.SoftwareData.DevTaxNumber;
	Level1Node := MainNode.AddChild( 'invoiceNumberQuery' );
	Level1Node.AddChild( 'invoiceNumber' ).Text := InInvoiceNumber;
	if ( InInvoiceDirection = id_Outbound ) then begin
		Level1Node.AddChild( 'invoiceDirection' ).Text := 'OUTBOUND';
	end else begin
		Level1Node.AddChild( 'invoiceDirection' ).Text := 'INBOUND';
		Level1Node.AddChild( 'supplierTaxNumber' ).Text := Trim( InTaxNumber );
	end;
	cFileName := cRequestId + '.xml';
	try
		try
			cXMLFile := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
			XMLFile := LoadXMLData( cXMLFile );
			XMLFile.Encoding := 'utf-8';
			WriteLogFile( 'XML file elkőszétíse (' + cFileName + ')',3 );
			XMLFile.SaveToFile( MainForm.AppSettings.cSendPath + '\' + cFileName );
			WriteLogFile( 'XML file előkészítése megtörtént (' + MainForm.AppSettings.cSendPath + '\' + cFileName + ')',3 );
		finally
			XMLFile.Active := FALSE;
		end;
	except
		on E: Exception do begin
			WriteLogFile( 'Hiba az XML file elkőszítésekor',3 );
			WriteLogFile( E.ClassName + ': ' + E.Message,3 );
		end;
	end;
	MainForm.Refresh;
	Application.ProcessMessages;
	cFileName := SendXML( cFileName, MainForm.NAVReadSettings.ReadMode, nQInvoiceData );
	if cFileName <> '' then begin
		WriteLogFile( 'A számla adatai lekérdezve.',1 );
		Result := cFileName;
	end;
end;


// Számla kiírása
procedure WriteInvoice( InSave : boolean; InFactoryCode, InXMLFile : string; InInvoiceDirection : TInvoiceDirection );
var
	XMLFile													: IXMLDocument;
	MainNode,Level1Node,Level2Node					: IXMLNode;
	NAVInvoice												: TInvoice;
	cInvoiceData,cDate,cInvNumber,RequestID		: AnsiString;
begin
	NAVInvoice := TInvoice.Create;
	NAVInvoice.Direction := InInvoiceDirection;
	SetMySettings;
	cInvoiceData := '';
	WriteLogFile( 'A számla adatainak beolvasása.',2 );
	XMLFile := LoadXMLDocument( MainForm.AppSettings.cReceivePath + '\' + InXMLFile );
	MainNode := XMLFile.ChildNodes.FindNode( 'QueryInvoiceDataResponse' );
	Level1Node := MainNode.ChildNodes.FindNode( 'header','' );
	if ( Level1Node <> NIL ) then begin
		NAVInvoice.RequestId := ReadNodeText( Level1Node,'requestId' );
	end;
	Level1Node := MainNode.ChildNodes.FindNode( 'result','' );
	if ( Level1Node <> NIL ) then begin
		if ReadNodeText( Level1Node, 'funcCode' ) = 'OK' then begin
			Level1Node := MainNode.ChildNodes.FindNode( 'invoiceDataResult','' );
			if Level1Node <> NIL then begin
				cInvoiceData := ReadNodeText( Level1Node, 'invoiceData' );
				NAVInvoice.Compressed := ( ReadNodeText( Level1Node, 'compressedContentIndicator' ) = 'true' );
				Level2Node := Level1Node.ChildNodes.FindNode( 'auditData','' );
				if Level2Node <> NIL then begin
					cDate := ReadNodeText( Level2Node, 'insdate' );
					NAVInvoice.NAVDate := StrToDateTime( Copy( cDate,1,10 ) + ' ' + Copy( cDate,12,8 ), NAV.MySettings );
					NAVInvoice.RequestVersion := SetNAVVersion( ReadNodeText( Level2Node, 'originalRequestVersion' ));
				end;
			end else begin
				WriteLogFile( 'Nincs adat a megadott számláról.',1 );
			end;
		end;
	end else begin
		WriteLogFile( 'Hiba a számla adatainak lekérdezésekor!!!',1 );
		WriteLogFile( 'A lekérdezés eredménye nem OK (' + Level1Node.Text + ')',3 );
	end;
	XMLFile.Active := FALSE;
	if ( MainForm.AppSettings.nLogLevel < 4 ) then begin
		DeleteFile( MainForm.AppSettings.cReceivePath + '\' + InXMLFile );
	end;
	if ( cInvoiceData <> '' ) then begin
		DecodeInvoiceData( InSave, cInvoiceData, InXMLFile, NAVInvoice );
		if ( InSave ) then begin
			NAVInvoice.WriteToDBF;
		end;
	end;
	NAVInvoice.Destroy;
end;

// Számla XML beolvasása TInvoice-ba
function DecodeInvoiceData( InSave : boolean; InInvoiceData, InXMLFile : string; InInvoice : TInvoice ) : TInvoice;
var
	XMLFile											: IXMLDocument;
	MainNode,Level1Node,Level2Node			: IXMLNode;
	Level3Node,Level4Node,Level5Node			: IXMLNode;
	Level6Node,Level7Node,Level8Node			: IXMLNode;
	ZLibComp											: TDecompressionStream;
	InvoiceData,CompressedData					: TStringStream;
	cDate,cInvNumber,cVATType					: string;
	cTaxID,cAddress,cFullTaxID,cOutTaxID	: string;
	ActInvoiceData									: AnsiString;
	dInvoiceDate									: TDateTime;
	I													: integer;
	nAFASzaz,nEgysar								: double;
	nDevAFA,nAFA									: double;
	nDevNetto,nNetto								: double;
	nDevBrutto,nBrutto							: double;
begin
// Ha a számla adat megvan.
	if ( InInvoiceData <> '' ) then begin
		WriteLogFile( 'Számla dekódolásának megkezdése',4 );
		InInvoice.InvoiceLines.Clear;
		ActInvoiceData := AnsiString( InInvoiceData );
		ActInvoiceData := Base64DecodeStr( ActInvoiceData );
// Ha tömörítve van a számla az XML-ben
		if ( InInvoice.Compressed ) then begin
			CompressedData := TStringStream.Create( AnsiString( ActInvoiceData ));
			CompressedData.Seek( 0, soBeginning );
			try
				ZLibComp := TDecompressionStream.Create( CompressedData, 15 + 16 );
				try
					InvoiceData := TStringStream.Create( '' );
					try
						InvoiceData.LoadFromStream( ZLibComp );
						ActInvoiceData := InvoiceData.DataString;
					finally
						InvoiceData.Free;
					end;
				finally
					ZLibComp.Free;
				end;
			finally
				CompressedData.Free;
			end;
		end;
//		ActInvoiceData := UTF8Decode( ActInvoiceData );
		XMLFile := NewXMLDocument;
		XMLFile.Encoding := 'UTF-8';
		XMLFile.Options := [ doNodeAutoIndent ];
		XMLFile.LoadFromXML( ActInvoiceData );
		XMLFile.XML.Text := XMLDoc.FormatXMLData( XMLFile.XML.Text );
		XMLFile.Active := TRUE;
		if ( MainForm.AppSettings.nLogLevel = 4 ) or ( not InSave ) then begin
			XMLFile.SaveToFile( MainForm.NAVReadSettings.InvoicePath + '\' + InXMLFile );
		end;
		cInvNumber := '';
		cTaxID := '';
		cFullTaxID := '';
		case ( InInvoice.RequestVersion ) of
			rv_10 : begin

			end;
			rv_20 : begin
			WriteLogFile( '2.0-ás NAV verzió.',1 );
			MainNode := XMLFile.ChildNodes.FindNode( 'InvoiceData' );
			if MainNode <> NIL then begin
				InInvoice.InvoiceNumber := ReadNodeText( MainNode, 'invoiceNumber' );;
				InInvoice.IssueDate := StrToDate( ReadNodeText( MainNode, 'invoiceIssueDate' ), NAV.MySettings );
				MainNode := MainNode.ChildNodes.FindNode( 'invoiceMain' );
				if MainNode <> NIL  then begin
					MainNode := MainNode.ChildNodes.FindNode( 'invoice' );
					if MainNode <> NIL  then begin
						Level1Node := MainNode.ChildNodes.FindNode( 'invoiceHead' );
						if Level1Node <> NIL then begin
// Az eladó adatait rögzítjük
							Level2Node := Level1Node.ChildNodes.FindNode( 'supplierInfo' );
							if Level2Node <> NIL then begin
								Level3Node := Level2Node.ChildNodes.FindNode( 'supplierTaxNumber' );
								if Level3Node <> NIL then begin
									InInvoice.Supplier.TAXPayerID := ReadNodeText( Level3Node, 'taxpayerId' );
									Level4Node := Level3Node.ChildNodes.FindNode( 'vatCode' );
									if Level4Node <> NIL then begin
										InInvoice.Supplier.VATCode := ReadNodeText( Level3Node, 'vatCode' );
										InInvoice.Supplier.CountyCode := ReadNodeText( Level3Node, 'countyCode' );
									end;
								end;
								InInvoice.Supplier.Name := ReadNodeText( Level2Node, 'supplierName' );
								Level3Node := Level2Node.ChildNodes.FindNode( 'supplierAddress' );
								if Level3Node <> NIL then begin
									Level4Node := Level3Node.ChildNodes.FindNode( 'simpleAddress' );
// Ha sima címe van a partnernek
									if Level4Node <> NIL then begin
										InInvoice.Supplier.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
										InInvoice.Supplier.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
										InInvoice.Supplier.City := ReadNodeText( Level4Node, 'city' );
										InInvoice.Supplier.Address := ReadNodeText( Level4Node, 'additionalAddressDetail' );
									end;
									Level4Node := Level3Node.ChildNodes.FindNode( 'detailedAddress','' );
// Ha részletes címe van a partnernek
									if Level4Node <> NIL then begin
										cAddress := '';
										InInvoice.Supplier.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
										InInvoice.Supplier.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
										InInvoice.Supplier.City := ReadNodeText( Level4Node, 'city' );
										InInvoice.Supplier.Address := ReadNodeText( Level4Node, 'streetName' ) + ' ' +
											ReadNodeText( Level4Node, 'publicPlaceCategory' ) + ' ' +
											ReadNodeText( Level4Node, 'number' ) + '.';
									end;
								end;
								InInvoice.Supplier.NAVType := 1;
							end;
// A vevő nevét tároljuk le
							Level2Node := Level1Node.ChildNodes.FindNode( 'customerInfo' );
							if Level2Node <> NIL then begin
								Level3Node := Level2Node.ChildNodes.FindNode( 'customerTaxNumber' );
								if Level3Node <> NIL then begin
									InInvoice.Customer.TAXPayerID := ReadNodeText( Level3Node, 'taxpayerId' );
									Level4Node := Level3Node.ChildNodes.FindNode( 'vatCode' );
									if Level4Node <> NIL then begin
										InInvoice.Customer.VATCode := ReadNodeText( Level3Node, 'vatCode' );
										InInvoice.Customer.CountyCode := ReadNodeText( Level3Node, 'countyCode' );
									end;
								end;
								InInvoice.Customer.Name := ReadNodeText( Level2Node, 'customerName' );
								Level3Node := Level2Node.ChildNodes.FindNode( 'customerAddress' );
								if Level3Node <> NIL then begin
									Level4Node := Level3Node.ChildNodes.FindNode( 'simpleAddress' );
									if Level4Node <> NIL then begin
										InInvoice.Customer.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
										InInvoice.Customer.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
										InInvoice.Customer.City := ReadNodeText( Level4Node, 'city' );
										InInvoice.Customer.Address := ReadNodeText( Level4Node, 'additionalAddressDetail' );
									end;
									Level4Node := Level3Node.ChildNodes.FindNode( 'detailedAddress','' );
// Ha részletes címe van a partnernek
									if Level4Node <> NIL then begin
										cAddress := '';
										InInvoice.Customer.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
										InInvoice.Customer.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
										InInvoice.Customer.City := ReadNodeText( Level4Node, 'city' );
										InInvoice.Customer.Address := ReadNodeText( Level4Node, 'streetName' ) + ' ' +
											ReadNodeText( Level4Node, 'publicPlaceCategory' ) + ' ' +
											ReadNodeText( Level4Node, 'number' ) + '.';
									end;
								end;
							end;
							Level2Node := Level1Node.ChildNodes.FindNode( 'invoiceDetail' );
							if Level2Node <> NIL then begin
								InInvoice.DeliveryDate := StrToDate( ReadNodeText( Level2Node, 'invoiceDeliveryDate' ), NAV.MySettings );
								InInvoice.Currency := ReadNodeText( Level2Node, 'currencyCode' );
								InInvoice.ExchangeRate := StrToFloat( ReadNodeText( Level2Node, 'exchangeRate' ), NAV.MySettings );
								cVATType := ReadNodeText( Level2Node, 'paymentDate' );
// Fizetési határidő
								if ( cVATType = '0' ) then begin
									InInvoice.PaymentDate := InInvoice.DeliveryDate;
								end else begin
									InInvoice.PaymentDate := StrToDate( cVATType, NAV.MySettings );
								end;
							end;
						end;
// Ha módosító számláról van szó, akkor beolvassuk az eredeti számlaszámot
						Level1Node := MainNode.ChildNodes.FindNode( 'invoiceReference','' );
						if Level1Node <> NIL then begin
							InInvoice.OriginalInvoice := ReadNodeText( Level1Node, 'originalInvoiceNumber' );
						end;
						Level1Node := MainNode.ChildNodes.FindNode( 'invoiceSummary' );
						Level2Node := Level1Node.ChildNodes.FindNode( 'summaryNormal' );
						if Level2Node <> NIL then begin
							InInvoice.NetAmount := StrToFloat( ReadNodeText( Level2Node, 'invoiceNetAmount' ), NAV.MySettings );
							InInvoice.NetAmountHUF := StrToFloat( ReadNodeText( Level2Node, 'invoiceNetAmountHUF' ), NAV.MySettings );
							InInvoice.VatAmount := StrToFloat( ReadNodeText( Level2Node, 'invoiceVatAmount' ), NAV.MySettings );
							InInvoice.VatAmountHUF := StrToFloat( ReadNodeText( Level2Node, 'invoiceVatAmountHUF' ), NAV.MySettings );
							end;
						end;
					end;
				end;
// Innen kezdődik a sorok beolvasása
				Level1Node := MainNode.ChildNodes.FindNode( 'invoiceLines' );
				if Level1Node <> NIL  then begin
					for I := 0 to Level1Node.ChildNodes.Count - 1 do begin
						Level2Node := Level1Node.ChildNodes[ I ];
						if ( Level2Node <> NIL ) and ( Level2Node.NodeName = 'line' ) then begin
							InInvoice.InvoiceLines.Add;
							NewLine := InInvoice.InvoiceLines.Items[ InInvoice.InvoiceLines.Count - 1 ];
							NewLine.ResetLine;
							NewLine.Sor := StrToInt( ReadNodeText( Level2Node, 'lineNumber' ));
							Level3Node := Level2Node.ChildNodes.FindNode( 'productCodes' );
							if Level3Node <> NIL then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'productCode' );
								if Level4Node <> NIL then begin
									if ( ReadNodeText( Level4Node, 'productCodeCategory' ) = 'VTSZ' ) then begin
										NewLine.ProductCode := ReadNodeText( Level4Node, 'productCodeValue' );
									end;
								end;
							end;
							NewLine.ProductName := ReadNodeText( Level2Node, 'lineDescription' );
							NewLine.ProductUnit := ReadNodeText( Level2Node, 'unitOfMeasure' );
							NewLine.Quantity := StrToFloat( ReadNodeText( Level2Node, 'quantity' ), NAV.MySettings );
							NEWLine.UnitPrice := StrToFloat( ReadNodeText( Level2Node, 'unitPrice' ), NAV.MySettings );
							Level3Node := Level2Node.ChildNodes.FindNode( 'lineAmountsNormal' );
// Ha normál számla
							if Level3Node <> NIL then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineNetAmountData' );
								if Level4Node <> NIL then begin
									NewLine.NetAmount := StrToFloat( ReadNodeText( Level4Node, 'lineNetAmount' ), NAV.MySettings );
									NewLine.NetAmountHUF := StrToFloat( ReadNodeText( Level4Node, 'lineNetAmountHUF' ), NAV.MySettings );
								end;
// Ha van százalékos ÁFA
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineVatRate' );
								if Level4Node <> NIL then begin
									NewLine.AFASzaz := 100 * StrToFloat( ReadNodeText( Level4Node, 'vatPercentage' ), NAV.MySettings );
								end;
// ÁFA körön kívüli
								if Level4Node <> NIL then begin
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatOutOfScope' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := 'ATK';
									end;
								end;
// Adómentes
								if Level4Node <> NIL then begin
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatExemption' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := 'AAM';
									end;
								end;
// Fordított ÁFA
								if Level4Node <> NIL then begin
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatDomesticReverseCharge' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := 'FORDITOTT';
									end;
								end;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineVatData' );
// Meg van adva a sorban az ÁFA értéke
								if Level4Node <> NIL then begin
									NewLine.VatAmount := StrToFloat( ReadNodeText( Level4Node, 'lineVatAmount' ), NAV.MySettings );
									NewLine.VatAmountHUF := StrToFloat( ReadNodeText( Level4Node, 'lineVatAmountHUF' ), NAV.MySettings );
								end else begin
// Ha nincs, akkor kiszámoljuk
									NewLine.VatAmount := NewLine.NetAmount * nAFASzaz / 100;
									NewLine.VatAmountHUF := NewLine.NetAmountHUF * nAFASzaz / 100;
								end;
							end;
// Ha egyszerűsített számla
							Level3Node := Level2Node.ChildNodes.FindNode( 'lineAmountsSimplified','' );
							if Level3Node <> NIL then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineVatContent','' );
								nAFASzaz := 0;
								if Level4Node <> NIL then begin
									nAFASzaz := StrToFloat( ReadNodeText( Level4Node, 'lineVatContent' ), NAV.MySettings );
								end;
								NewLine.AFASzaz := ( 100 * nAFASzaz ) / ( 1 - nAFASzaz );
								nBrutto := 0;
								nDevBrutto := 0;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineGrossAmountSimplified','' );
								if Level4Node <> NIL then begin
									nDevBrutto := StrToFloat( ReadNodeText( Level3Node, 'lineGrossAmountSimplified' ), NAV.MySettings );
								end;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineGrossAmountSimplifiedHUF','' );
								if Level4Node <> NIL then begin
									nBrutto := StrToFloat( ReadNodeText( Level3Node, 'lineGrossAmountSimplifiedHUF' ), NAV.MySettings );
								end;
								nEgysar := nEgysar * 100 / ( 100 + nAFASzaz );
								nDevNetto := nDevBrutto * 100 / ( 100 + nAFASzaz );
								nNetto := nBrutto * 100 / ( 100 + nAFASzaz );
								nAFA := nBrutto - nNetto;
								nDevAFA := nDevBrutto - nDevNetto;
								NewLine.Quantity := nEgysAr;
								NewLine.NetAmount := nDevNetto;
								NewLine.NetAmountHUF := nNetto;
								NewLine.VatAmount := nDevAFA;
								NewLine.VatAmountHUF := nAFA;
							end;
							InInvoice.InvoiceLines.Items[ InInvoice.InvoiceLines.Count - 1 ] := NewLine;
						end;
					end;
				end;
			end;
// 3.0-ás számla beolvasása
			rv_30 : begin
				MainNode := XMLFile.ChildNodes.FindNode( 'InvoiceData','' );
				WriteLogFile( '3.0-ás NAV verzió.',1 );
				if MainNode <> NIL then begin
					cInvNumber := ReadNodeText( MainNode, 'invoiceNumber' );
					cDate := ReadNodeText( MainNode, 'invoiceIssueDate' );
					InInvoice.InvoiceNumber := ReadNodeText( MainNode, 'invoiceNumber' );;
					InInvoice.IssueDate := StrToDate( ReadNodeText( MainNode, 'invoiceIssueDate' ), NAV.MySettings );
					MainNode := MainNode.ChildNodes.FindNode( 'invoiceMain','' );
					if MainNode <> NIL  then begin
						Level1Node := MainNode.ChildNodes.FindNode( 'batchInvoice','' );
// Ha csoporrtos módosító számla
						if Level1Node <> NIL  then begin
							MainNode := Level1Node.ChildNodes.FindNode( 'invoice','' );
						end else begin
							MainNode := MainNode.ChildNodes.FindNode( 'invoice','' );
						end;
						if MainNode <> NIL  then begin
							Level1Node := MainNode.ChildNodes.FindNode( 'invoiceHead','' );
							if Level1Node <> NIL then begin
// Az eladó adatait rögzítjük
								Level2Node := Level1Node.ChildNodes.FindNode( 'supplierInfo','' );
								if Level2Node <> NIL then begin
									Level3Node := Level2Node.ChildNodes.FindNode( 'supplierTaxNumber','' );
// Ha van adószáma a partnernek
									if Level3Node <> NIL then begin
										InInvoice.Supplier.TAXPayerID := ReadNodeText( Level3Node, 'taxpayerId' );
										Level4Node := Level3Node.ChildNodes.FindNode( 'vatCode' );
										if Level4Node <> NIL then begin
											InInvoice.Supplier.VATCode := ReadNodeText( Level3Node, 'vatCode' );
											InInvoice.Supplier.CountyCode := ReadNodeText( Level3Node, 'countyCode' );
										end;
// Ha nincs adószáma
									end else begin
										InInvoice.Supplier.TAXPayerID := '';
									end;
									InInvoice.Supplier.Name := ReadNodeText( Level2Node, 'supplierName' );
									InInvoice.Supplier.NAVType := 1;
									Level3Node := Level2Node.ChildNodes.FindNode( 'supplierAddress','' );
									if Level3Node <> NIL then begin
										Level4Node := Level3Node.ChildNodes.FindNode( 'simpleAddress','' );
// Ha egyszerű címe van a szállítónak
										if Level4Node <> NIL then begin
											InInvoice.Supplier.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
											InInvoice.Supplier.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
											InInvoice.Supplier.City := ReadNodeText( Level4Node, 'city' );
											InInvoice.Supplier.Address := ReadNodeText( Level4Node, 'additionalAddressDetail' );
										end;
										Level4Node := Level3Node.ChildNodes.FindNode( 'detailedAddress','' );
// A részletes címe van a szállítónak
										if Level4Node <> NIL then begin
											InInvoice.Supplier.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
											InInvoice.Supplier.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
											InInvoice.Supplier.City := ReadNodeText( Level4Node, 'city' );
											InInvoice.Supplier.Address := ReadNodeText( Level4Node, 'streetName' ) + ' ' +
												ReadNodeText( Level4Node, 'publicPlaceCategory' ) + ' ' +
												ReadNodeText( Level4Node, 'number' ) + '.';
										end;
									end;
								end;
// Ha kimenő számla, akkor a vevő nevét tároljuk le
								Level2Node := Level1Node.ChildNodes.FindNode( 'customerInfo','' );
								if Level2Node <> NIL then begin
									cVatType := ReadNodeText( Level2Node, 'customerVatStatus' );
// Ha magánszemély, akkor nincs neve, adószáma
									if ( cVATType = 'PRIVATE_PERSON') then begin
										InInvoice.Customer.TAXPayerID := '*';
										InInvoice.Customer.Name := 'maganszemely';
										InInvoice.Customer.NAVType := 3;
									end else begin
// Ha belföldi adóalany
										if ( cVATType = 'DOMESTIC') then begin
											Level3Node := Level2Node.ChildNodes.FindNode( 'customerVatData','' );
											if Level3Node <> NIL then begin
												Level4Node := Level3Node.ChildNodes.FindNode( 'customerTaxNumber','' );
												if Level4Node <> NIL then begin
													InInvoice.Customer.TAXPayerID := ReadNodeText( Level4Node, 'taxpayerId' );
													Level5Node := Level4Node.ChildNodes.FindNode( 'vatCode' );
													if Level5Node <> NIL then begin
														InInvoice.Customer.VATCode := ReadNodeText( Level4Node, 'vatCode' );
														InInvoice.Customer.CountyCode := ReadNodeText( Level4Node, 'countyCode' );
													end;
												end;
											end;
											InInvoice.Supplier.NAVType := 1;
										end;
// Egyéb típusú partner
										if ( cVATType = 'OTHER') then begin
											Level3Node := Level2Node.ChildNodes.FindNode( 'customerVatData','' );
											if Level3Node <> NIL then begin
												cTaxID := ReadNodeText( Level3Node, 'communityVatNumber' );
												InInvoice.Customer.TAXPayerID := cTaxID;
												InInvoice.Customer.EUTAXID := cTaxID;
											end else begin
												InInvoice.Customer.TAXPayerID := '';
											end;
											InInvoice.Customer.NAVType := 2;
										end;
										InInvoice.Customer.Name := ReadNodeText( Level2Node, 'customerName' );
										Level3Node := Level2Node.ChildNodes.FindNode( 'customerAddress','' );
										if Level3Node <> NIL then begin
											Level4Node := Level3Node.ChildNodes.FindNode( 'simpleAddress','' );
// Ha egyszerű címet adnak meg
											if Level4Node <> NIL then begin
												InInvoice.Customer.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
												InInvoice.Customer.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
												InInvoice.Customer.City := ReadNodeText( Level4Node, 'city' );
												InInvoice.Customer.Address := ReadNodeText( Level4Node, 'additionalAddressDetail' );
											end;
											Level4Node := Level3Node.ChildNodes.FindNode( 'detailedAddress','' );
// A részletes címe van a szállítónak
											if Level4Node <> NIL then begin
												InInvoice.Customer.CountryCode := ReadNodeText( Level4Node, 'countryCode' );
												InInvoice.Customer.PostalCode := ReadNodeText( Level4Node, 'postalCode' );
												InInvoice.Customer.City := ReadNodeText( Level4Node, 'city' );
												InInvoice.Customer.Address := ReadNodeText( Level4Node, 'streetName' ) + ' ' +
													ReadNodeText( Level4Node, 'publicPlaceCategory' ) + ' ' +
													ReadNodeText( Level4Node, 'number' ) + '.';
											end;
										end;
									end;
								end;
							end;
							Level2Node := Level1Node.ChildNodes.FindNode( 'invoiceDetail','' );
							if Level2Node <> NIL then begin
								InInvoice.DeliveryDate := StrToDate( ReadNodeText( Level2Node, 'invoiceDeliveryDate' ), NAV.MySettings );
								InInvoice.Currency := ReadNodeText( Level2Node, 'currencyCode' );
								InInvoice.ExchangeRate := StrToFloat( ReadNodeText( Level2Node, 'exchangeRate' ), NAV.MySettings );
								cVATType := ReadNodeText( Level2Node, 'paymentDate' );
// Fizetési mód meghatározása
								Level3Node := Level3Node.ChildNodes.FindNode( 'paymentMethod','' );
								if ( Level3Node <> NIL ) then begin
									InInvoice.PaymentMethod := 3;
									if ( ReadNodeText( Level2Node, 'paymentMethod' ) = 'TRANSFER' ) then InInvoice.PaymentMethod := 2;
									if ( ReadNodeText( Level2Node, 'paymentMethod' ) = 'CASH' ) then InInvoice.PaymentMethod := 1;
								end;
// Számla típusa
								InInvoice.Apperance := ReadNodeText( Level2Node, 'invoiceAppearance' );
// Fizetési határidő
								if ( cVATType = '0' ) then begin
									InInvoice.PaymentDate := InInvoice.IssueDate;
								end else begin
									InInvoice.PaymentDate := StrToDate( cVATType, NAV.MySettings );
								end;
// Ha saját programból jön az adat
								Level3Node := Level2Node.ChildNodes.First;
								while ( Assigned( Level3Node )) do begin
								if Level3Node <> NIL then begin
									if ( Level3Node.NodeName = 'additionalInvoiceData' ) then begin
// Saját partner kód
										if ReadNodeText( Level3Node, 'dataName' ) = 'C00001_COSTOMER_OWN' then begin
											InInvoice.Customer.Code := StrToInt( ReadNodeText( Level3Node, 'dataValue' ));
										end;
// Saját szortwer neve
										if ReadNodeText( Level3Node, 'dataName' ) = 'C00001_SENDER_SOFTWARE' then begin
											InInvoice.SendSw := ReadNodeText( Level3Node, 'dataValue' );
										end;
									end;
									Level3Node := Level3Node.NextSibling;
								end;
								end;
							end;
// Ha módosító számláról van szó, akkor beolvassuk az eredeti számlaszámot
							Level1Node := MainNode.ChildNodes.FindNode( 'invoiceReference','' );
							if Level1Node <> NIL then begin
								InInvoice.OriginalInvoice := ReadNodeText( Level1Node, 'originalInvoiceNumber' );
							end;
						end;
						Level1Node := MainNode.ChildNodes.FindNode( 'invoiceSummary','' );
						Level2Node := Level1Node.ChildNodes.FindNode( 'summaryNormal','' );
// A számla végösszege
						if Level2Node <> NIL then begin
							InInvoice.NetAmount := StrToFloat( ReadNodeText( Level2Node, 'invoiceNetAmount' ), NAV.MySettings );
							InInvoice.NetAmountHUF := StrToFloat( ReadNodeText( Level2Node, 'invoiceNetAmountHUF' ), NAV.MySettings );
							InInvoice.VatAmount := StrToFloat( ReadNodeText( Level2Node, 'invoiceVatAmount' ), NAV.MySettings );
							InInvoice.VatAmountHUF := StrToFloat( ReadNodeText( Level2Node, 'invoiceVatAmountHUF' ), NAV.MySettings );
						end;
						Level2Node := Level1Node.ChildNodes.FindNode( 'summaryGrossData','' );
// A számla végösszege
						if Level2Node <> NIL then begin
//							InInvoice.NetAmount := StrToFloat( ReadNodeText( Level2Node, 'invoiceGrossAmount' ), NAV.MySettings );
//							InInvoice.NetAmountHUF := StrToFloat( ReadNodeText( Level2Node, 'invoiceGrossAmountHUF' ), NAV.MySettings );
// Ez nem tudom mi a f...omért volt benne?
//							InInvoice.VatAmount := 0;
//							InInvoice.VatAmountHUF := 0;
						end;
					end;
				end;
// Innen jön a számlasorok beolvasása
				Level1Node := MainNode.ChildNodes.FindNode( 'invoiceLines','' );
				if Level1Node <> NIL  then begin
					for I := 0 to Level1Node.ChildNodes.Count - 1 do begin
						Level2Node := Level1Node.ChildNodes[ I ];
						if ( Level2Node <> NIL ) and ( Level2Node.NodeName = 'line' ) then begin
							InInvoice.InvoiceLines.Add;
							NewLine := InInvoice.InvoiceLines.Items[ InInvoice.InvoiceLines.Count - 1 ];
							NewLine.ResetLine;
							NewLine.Sor := StrToInt( ReadNodeText( Level2Node, 'lineNumber' ));
							Level3Node := Level2Node.ChildNodes.FindNode( 'productCodes','' );
							if Level3Node <> NIL then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'productCode','' );
								if Level4Node <> NIL then begin
									if ( ReadNodeText( Level4Node, 'productCodeCategory' ) = 'VTSZ' ) then begin
										NewLine.ProductCode := ReadNodeText( Level4Node, 'productCodeValue' );
									end;
								end;
							end;
							NewLine.ProductName := ReadNodeText( Level2Node, 'lineDescription' );
							NewLine.ProductUnit := ReadNodeText( Level2Node, 'unitOfMeasure' );
							NewLine.Quantity := StrToFloat( ReadNodeText( Level2Node, 'quantity' ), NAV.MySettings );
							nEgysar := 0;
							NeWLine.UnitPrice := StrToFloat( ReadNodeText( Level2Node, 'unitPrice' ), NAV.MySettings );
							Level3Node := Level2Node.ChildNodes.FindNode( 'lineAmountsNormal','' );
// Ha normál számláról van szó
							if Level3Node <> NIL then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineNetAmountData','' );
								if Level4Node <> NIL then begin
									NewLine.NetAmount := StrToFloat( ReadNodeText( Level4Node, 'lineNetAmount' ), NAV.MySettings );
									NewLine.NetAmountHUF := StrToFloat( ReadNodeText( Level4Node, 'lineNetAmountHUF' ), NAV.MySettings );
								end;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineVatRate','' );
								if Level4Node <> NIL then begin
// Ha van százalékos ÁFA
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatPercentage','' );
									if Level5Node <> NIL then begin
//										WriteLn( nExportFile, PadR( 'AFASZAZ', 10, ' ' ) + FormatFloat( '#.###', 100 * StrToFloat( ReadNodeText( Level4Node, 'vatPercentage' ), NAV.MySettings )));
										NewLine.AFASzaz := 100 * StrToFloat( ReadNodeText( Level4Node, 'vatPercentage' ), NAV.MySettings );
									end;
// Ha különleges 0%-os ÁFA
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatExemption','' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := ReadNodeText( Level5Node, 'case' );
										NewLine.AFASzaz := 0;
									end;
// Ha ÁFA körön kívüli
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatOutOfScope','' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := ReadNodeText( Level5Node, 'case' );
										NewLine.AFASzaz := 0;
									end;
// Ha fordított ÁFA
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatDomesticReverseCharge','' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := 'FORDITOTT';
									end;
								end;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineVatData','' );
								if Level4Node <> NIL then begin
									NewLine.VatAmount := StrToFloat( ReadNodeText( Level4Node, 'lineVatAmount' ), NAV.MySettings );
									NewLine.VatAmountHUF := StrToFloat( ReadNodeText( Level4Node, 'lineVatAmountHUF' ), NAV.MySettings );
								end;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineGrossAmountData','' );
								if Level4Node <> NIL then begin
									NewLine.GrossAmount := StrToFloat( ReadNodeText( Level4Node, 'lineGrossAmountNormal' ), NAV.MySettings );
									NewLine.GrossAmountHUF := StrToFloat( ReadNodeText( Level4Node, 'lineGrossAmountNormalHUF' ), NAV.MySettings );
								end;
							end;
// Ha egyszerűsített számla
							Level3Node := Level2Node.ChildNodes.FindNode( 'lineAmountsSimplified','' );
							if Level3Node <> NIL then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineVatRate','' );
								if Level4Node <> NIL then begin
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatContent','' );
									if Level5Node <> NIL then begin
										nAFASzaz := StrToFloat( ReadNodeText( Level4Node, 'vatContent' ), NAV.MySettings );
										nAFASzaz := ( 100 * nAFASzaz ) / ( 1 - nAFASzaz );
										NewLine.AFASzaz := nAFASzaz;
									end;
// Ha különleges 0%-os ÁFA
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatExemption','' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := ReadNodeText( Level5Node, 'case' );
										NewLine.AFASzaz := 0;
									end;
// Ha ÁFA körön kívüli
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatOutOfScope','' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := ReadNodeText( Level5Node, 'case' );
										NewLine.AFASzaz := 0;
									end;
// Ha fordított ÁFA
									Level5Node := Level4Node.ChildNodes.FindNode( 'vatDomesticReverseCharge','' );
									if Level5Node <> NIL then begin
										NewLine.NAVVatCode := 'FORDITOTT';
									end;
								end;
								nBrutto := 0;
								nDevBrutto := 0;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineGrossAmountSimplified','' );
								if Level4Node <> NIL then begin
									NewLine.GrossAmount := StrToFloat( ReadNodeText( Level3Node, 'lineGrossAmountSimplified' ), NAV.MySettings );
								end;
								Level4Node := Level3Node.ChildNodes.FindNode( 'lineGrossAmountSimplifiedHUF','' );
								if Level4Node <> NIL then begin
									NewLine.GrossAmountHUF := StrToFloat( ReadNodeText( Level3Node, 'lineGrossAmountSimplifiedHUF' ), NAV.MySettings );
								end;
								NewLine.NetAmount := NewLine.GrossAmount * 100 / ( 100 + nAFASzaz );
								NewLine.NetAmountHUF := NewLine.GrossAmountHUF * 100 / ( 100 + nAFASzaz );
								NewLine.VatAmount := NewLine.GrossAmount - NewLine.NetAmount;
								NewLine.VatAmountHUF := NewLine.GrossAmountHUF - NewLine.NetAmountHUF;
								if ( NewLine.UnitPrice = 0 ) then begin
									NewLine.UnitPrice := NewLine.NetAmount / NewLine.Quantity;
								end;
							end;
							Level3Node := Level2Node.ChildNodes.First;
// Saját adatok beolvasása
							while ( Assigned( Level3Node )) do begin
								if ( Level3Node.NodeName = 'additionalLineData' ) then begin
// Saját anyagszám
									if ReadNodeText( Level3Node, 'dataName' ) = 'C00001_PRODUCT_OWN' then begin
										NewLine.AlmiraCode := ReadNodeText( Level3Node, 'dataValue' );
									end;
// Saját ÁFA kód
									if ReadNodeText( Level3Node, 'dataName' ) = 'C00001_PRODUCTVAT_OWN' then begin
										NewLine.VatCode := StrToInt( ReadNodeText( Level3Node, 'dataValue' ));
									end;
								end;
								Level3Node := Level3Node.NextSibling;
							end;
							InInvoice.InvoiceLines.Items[ InInvoice.InvoiceLines.Count - 1 ] := NewLine;
						end;
					end;
				end;
			end;
		end;
		XMLFile.Active := FALSE;
	end;
	ActInvoiceData := '';
	Result := InInvoice;
end;

end.
