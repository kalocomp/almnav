unit NAVManageInvoice;

interface

uses Windows, SysUtils, XMLDoc, XMLIntf, Main, Dialogs, Classes, XMLHandler, DCPBase64,
	IdSSL, IdSSLOpenSSL,NAV, IdHTTP, NAVTokenExchange, IdTCPConnection, IdTCPClient,
	MailSending, invoice;

function GetManageInvoice( InInvoice : TInvoice ) : string;
function MakeManageInvoice( InInvoice : TInvoice; InExchangeToken : string ) : string;

implementation

function GetManageInvoice( InInvoice : TInvoice ) : string;
var
	cXMLFile, cExchangeToken			: string;
	XMLFile									: IXMLDocument;
	MainNode,ChildNode					: IXMLNode;
begin
	WriteLogFile( 'Számla adatok küldése : ' + Trim( InInvoice.Supplier.Name ) + ' - ' + Trim( InInvoice.InvoiceNumber ) + ' (' + Trim( InInvoice.Supplier.Name ) + ')',1 );
	WriteLogFile( 'RequestID : ' + Trim( InInvoice.RequestId ) + ' (' + IntToStr( InInvoice.RecordNumber ) + '. rekord)',3 );
	cExchangeToken := NAVTokenExchange.GetToken( InInvoice );
	if Length( cExchangeToken ) > 0  then begin
		InInvoice.InvStatusNum := '2';
		InInvoice.InvStatusText := 'Token keres';
		InInvoice.InvStatus := '';
		InInvoice.RequestDateTime := Now;
		InInvoice.NAVError := '0';
		InInvoice.RequestVersion := MainForm.AppSettings.NAVVersion;
		InInvoice.SetNavStatus;
		cXMLFile := MakeManageInvoice( InInvoice, cExchangeToken );
		WriteLogFile( 'XML file küldése indul (' + MainForm.AppSettings.cSendPath + '\' + cXMLFile + ')',3 );
		if cXMLFile <> '' then begin
			InInvoice.InvStatusNum := '3';
			InInvoice.InvStatusText := 'Számla küldes';
			InInvoice.RequestDateTime := Now;
			InInvoice.NAVError := '0';
			InInvoice.TransactionID := ' ';
			InInvoice.SetNavStatus;
// Ha ANNULMENT
			if (InInvoice.OperationType = '4' ) then begin
				cXMLFile := SendXML( cXMLFile, InInvoice.TestMode, nMAnnulment );
			end else begin
				cXMLFile := SendXML( cXMLFile, InInvoice.TestMode, nMInvoice );
			end;
			if cXMLFile <> '' then begin
				XMLFile := LoadXMLDocument( MainForm.AppSettings.cReceivePath + '\' + cXMLFile );
				if (InInvoice.OperationType = '4' ) then begin
					MainNode := XMLFile.ChildNodes.FindNode( 'ManageAnnulmentResponse' );
				end else begin
					MainNode := XMLFile.ChildNodes.FindNode( 'ManageInvoiceResponse' );
				end;
				ChildNode := MainNode.ChildNodes.FindNode( 'header','' );
				ChildNode := ChildNode.ChildNodes.FindNode( 'requestId','' );
				if InInvoice.RequestId = ChildNode.Text then begin
					ChildNode := MainNode.ChildNodes.FindNode( 'result','' );
					ChildNode := ChildNode.ChildNodes.FindNode( 'funcCode','' );
					InInvoice.ResultText := ChildNode.Text;
					if ChildNode.Text = 'OK' then begin
						ChildNode := MainNode.ChildNodes.FindNode( 'transactionId' );
						Result := ChildNode.Text;
						WriteLogFile( 'A számla hibátlanul elküldve.',1 );
						WriteLogFile( 'A számla küldés azonosító : ' + Result,3 );
						InInvoice.InvStatusNum := '4';
						InInvoice.InvStatusText := 'Számla elküldve';
						InInvoice.RequestDateTime := Now;
						InInvoice.NAVError := '0';
						InInvoice.TransactionID := Result;
						InInvoice.SetNavStatus;
					end else begin
						WriteLogFile( 'Hiba a számla küldésekor!!!',1 );
						WriteLogFile( 'A válasz XML-ben nincs OK (' + cXMLFile + ')',3 );
					end;
					InInvoice.SetNavStatus;
				end else begin
					WriteLogFile( 'Hiba a számla küldésekor!!!',1 );
					WriteLogFile( 'A válasz XML-ben nem egyezõ REQUESTID (' + cXMLFile + ')',3 );
				end;
			end else begin
				WriteLogFile( 'Hiba a számla küldésekor!!!',1 );
				WriteLogFile( 'A válasz XML hibás!!!',3 );
			end;
		end;
	end else begin
		WriteLogFile( 'A válasz XML-ben nem egyezõ REQUESTID (' + cXMLFile + ')',3 );
	end;
end;

function MakeManageInvoice( InInvoice : TInvoice; InExchangeToken : string ) : string;
var
	UTCDateTime								: TSystemTime;
	cPassHash,cKey,cXML					: string;
	cDecodedToken,cBase64XML			: string;
	cInvoiceOperation,cLine				: string;
	cXMLSHA									: string;
	XMLText									: widestring;
	XMLFile									: IXMLDocument;
	MainNode,XMLChildNode,PassNode	: IXMLNode;
	XMLTextFile								: TextFile;
	HASHLines                        : TStringList;
begin
	if FileExists( InInvoice.XMLFile ) then begin
		WriteLogFile( 'Számla XML beolvasása (' + InInvoice.XMLFile + ')',4 );
		AssignFile( XMLTextFile, InInvoice.XMLFile );
		Reset( XMLTextFile );
		XMLtext := '';
		while ( not Eof( XMLTextFile )) do begin
			ReadLn( XMLTextFile, cLine );
			XMLText := XMLText + cLine + Chr( 13 ) + Chr( 10 );
		end;
		CloseFile( XMLTextFile );
		cInvoiceOperation := '';
		case StrToInt( InInvoice.OperationType ) of
			1 : begin
				cInvoiceOperation := 'CREATE';
			end;
			2 : begin
				cInvoiceOperation := 'STORNO';
			end;
			3 : begin
				cInvoiceOperation := 'MODIFY';
			end;
			4 : begin
				cInvoiceOperation := 'ANNUL';
			end;
		end;
		cBase64XML := Base64EncodeStr( AnsiString ( XMLText ));
		cXMLSHA := MakeSHA3512( cInvoiceOperation + cBase64XML );
		WriteLogFile( InInvoice.RequestId + ' - számla küldése',2 );
		WriteLogFile( 'Token dekódoklása - token:' + InExchangeToken,4 );
		WriteLogFile( 'Token dekódoklása - csere kulcs:' + InInvoice.Supplier.ChangeKey,4 );
		cDecodedToken := DecryptExchangeToken( InExchangeToken, InInvoice.Supplier.ChangeKey );
		WriteLogFile( 'Dekódolt token :' + cDecodedToken,4 );
		GetSystemTime( UTCDateTime );
		cPassHash := MakeSHA512( InInvoice.Supplier.Password );
		WriteLogFile( 'Titkosított jelszó : ' + cPassHash,4 );
		cKey := InInvoice.RequestId + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + InInvoice.Supplier.SignKey + UpperCase( cXMLSHA );
		WriteLogFile( 'RequestSiganture : ' + cKey,4 );
		WriteLogFile( 'RequestSiganture (SHA3-512) : ' + UpperCase( MakeSHA3512( cKey )),4 );
		XMLFile := NewXMLDocument;
		XMLFile.Options := [ doNodeAutoIndent ];
		XMLFile.Active;
//		XMLChildNode := XMLFile.CreateNode( 'InvoiceNumber', ntComment );
//		XMLFile.ChildNodes.Add( XMLChildNode );
//		XMLChildNode.Text := 'Szamla száma: ' + InInvoice.InvoiceNumber;
//		XMLChildNode := XMLFile.CreateNode( 'CustomerName', ntComment );
//		XMLFile.ChildNodes.Add( XMLChildNode );
//		XMLChildNode.Text := 'Ceg neve: ' + InInvoice.FinPart2Name;
		if ( InInvoice.OperationType = '4' ) then begin
			MainNode := XMLFile.AddChild( 'ManageAnnulmentRequest' );
		end else begin
			MainNode := XMLFile.AddChild( 'ManageInvoiceRequest' );
		end;
		XMLInsertSchemas( MainNode );
		XMLChildNode := MainNode.AddChild( cNAVCommonSchema + 'header' );
		XMLChildNode.AddChild( cNAVCommonSchema + 'requestId' ).Text := InInvoice.RequestId;
		XMLChildNode.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
		XMLChildNode.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := GetNAVVersion( InInvoice.RequestVersion );
		XMLChildNode.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
		XMLChildNode := MainNode.AddChild( cNAVCommonSchema + 'user' );
		XMLChildNode.AddChild( cNAVCommonSchema + 'login' ).Text := InInvoice.Supplier.Login;
		PassNode := XMLChildNode.AddChild( cNAVCommonSchema + 'passwordHash' );
		PassNode.Text := UpperCase( cPassHash );
		PassNode.Attributes[ 'cryptoType' ] := 'SHA-512';
		XMLChildNode.AddChild( cNAVCommonSchema + 'taxNumber' ).Text := Copy( InInvoice.Supplier.TAXPayerID,1,8 );
		PassNode := XMLChildNode.AddChild( cNAVCommonSchema + 'requestSignature' );
		PassNode.Text := UpperCase( MakeSHA3512( cKey ));
		PassNode.Attributes[ 'cryptoType' ] := 'SHA3-512';
		XMLChildNode := MainNode.AddChild( 'software' );
		XMLChildNode.AddChild( 'softwareId' ).Text := SoftwareData.ID;
		XMLChildNode.AddChild( 'softwareName' ).Text := SoftwareData.Name;
		XMLChildNode.AddChild( 'softwareOperation' ).Text := SoftwareData.Operation;
		XMLChildNode.AddChild( 'softwareMainVersion' ).Text := SoftwareData.MainVersion;
		XMLChildNode.AddChild( 'softwareDevName' ).Text := SoftwareData.DevName;
		XMLChildNode.AddChild( 'softwareDevContact' ).Text := SoftwareData.DevContact;
		XMLChildNode.AddChild( 'softwareDevCountryCode' ).Text := SoftwareData.DevCountryCode;
		XMLChildNode.AddChild( 'softwareDevTaxNumber' ).Text := SoftwareData.DevTaxNumber;
		MainNode.AddChild( 'exchangeToken' ).Text := cDecodedToken;
// Ha ANNULMENT
		if ( InInvoice.OperationType = '4' ) then begin
			XMLChildNode := MainNode.AddChild( 'annulmentOperations' );
			XMLChildNode := XMLChildNode.AddChild( 'annulmentOperation' );
			XMLChildNode.AddChild( 'index' ).Text := '1';
			XMLChildNode.AddChild( 'annulmentOperation' ).Text := cInvoiceOperation;
			XMLChildNode.AddChild( 'invoiceAnnulment' ).Text := cBase64XML;
		end else begin
			XMLChildNode := MainNode.AddChild( 'invoiceOperations' );
			XMLChildNode.AddChild( 'compressedContent' ).Text := 'false';
			XMLChildNode := XMLChildNode.AddChild( 'invoiceOperation' );
			XMLChildNode.AddChild( 'index' ).Text := '1';
			XMLChildNode.AddChild( 'invoiceOperation' ).Text := cInvoiceOperation;
			PassNode := XMLChildNode.AddChild( 'invoiceData' );
			PassNode.Text := cBase64XML;
			if ( InInvoice.Electronic = ei_Electronic ) then begin
				PassNode := XMLChildNode.AddChild( 'electronicInvoiceHash' );
				cXMLSHA := UpperCase( MakeSHA3512( cBase64XML ));
				PassNode.Text := cXMLSHA;
				WriteLogFile( 'Elektronikus számla hash kódja:' + cXMLSHA,4 );
				PassNode.Attributes[ 'cryptoType' ] := 'SHA3-512';
			end;
		end;
		try
			try
				cXML := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
				XMLFile := LoadXMLData( cXML );
				XMLFile.Encoding := 'utf-8';
				WriteLogFile( 'XML file elkészítése (' + InInvoice.RequestId + '.xml)',3 );
				XMLFile.SaveToFile( MainForm.AppSettings.cSendPath + '\' + InInvoice.RequestId + '.xml' );
				WriteLogFile( 'XML file elkészítése megtörtént (' + MainForm.AppSettings.cSendPath + '\' + InInvoice.RequestId + '.xml)',3 );
				Result := InInvoice.RequestId + '.xml';
			finally
				XMLFile.Active := FALSE;
			end;
		except
			on E: Exception do begin
				WriteLogFile( 'Hiba az XML file elkészítésekor',3 );
				WriteLogFile( E.ClassName + ': ' + E.Message,3 );
				Result := '';
			end;
		end;
// Ha elektronikus számla, akkor letároljuk az SHA kódot is
		if ( InInvoice.Electronic = ei_Electronic ) then begin
			HASHLines := TStringList.Create;
			try
				HASHLines.Add( 'Kibocsátó cég neve:' + InInvoice.Supplier.Name );
				HASHLines.Add( 'Kibocsátó cég adószáma:' + InInvoice.Supplier.TAXPayerID );
				HASHLines.Add( 'Számla száma:' + InInvoice.InvoiceNumber );
				HASHLines.Add( 'A számla (base64):' );
				HASHLines.Add( cBase64XML );
				HASHLines.Add( 'A számla HASH kódja (SHA3-512):' );
				HASHLines.Add( cXMLSHA );
				HASHLines.SaveToFile( MainForm.NAVASzSettings.cEInvoicePath + '\' + MakeSafetyFileName( InInvoice.Supplier.TAXPayerID + '-' + InInvoice.InvoiceNumber + '.SHA', '-' ), TEncoding.UTF8 );
				WriteLogFile( 'Elektronikus számla hash kódja elmentve :' + MakeSafetyFileName( InInvoice.Supplier.TAXPayerID + '-' + InInvoice.InvoiceNumber + '.SHA', '-' ),4 );
			finally
				HASHLines.Free;
			end;
		end;
	end else begin
		WriteLogFile( 'Nem található a számla XML (' + InInvoice.XMLFile + ')',2 );
		InInvoice.InvStatusNum := '0';
		InInvoice.InvStatusText := 'Hiba a küldéskor';
		InInvoice.NAVError := '1';
		InInvoice.ErrorText := 'Nem található a számla XML (' + InInvoice.XMLFile + ')';
		SendErrorMail( InInvoice, '' );
		InInvoice.SetNavStatus;
	end;
end;

end.
