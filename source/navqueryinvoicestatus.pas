unit NAVQueryInvoiceStatus;

interface

uses NAV, Windows, SysUtils, XMLDoc, XMLIntf, XMLHandler, NAVTokenExchange, Main, MailSending, invoice;

function MakeInvoiceStatus( InInvoice : TInvoice ) : string;

implementation

function MakeInvoiceStatus( InInvoice : TInvoice ) : string;
var
	UTCDateTime								: TSystemTime;
	cPassHash,cKey,cKeyHash,cXML		: string;
	cDecodedToken,cCRC32,cBase64XML	: string;
	cExchangeToken,cXMLFile				: string;
	XMLFile									: IXMLDocument;
	MainNode,ChildNode,ResultNode		: IXMLNode;
	AbortNode								: IXMLNode;
	lDeleteXML								: boolean;
begin
	lDeleteXML := FALSE;
	WriteLogFile( 'Számla állapot lekérdezése : ' + Trim( InInvoice.RequestId ) + ' (' + IntToStr( InInvoice.RecordNumber ) + '. rekord)',1 );
	if InInvoice.TransactionID <> '' then begin
		XMLFile := NewXMLDocument;
		XMLFile.Options := [ doNodeAutoIndent ];
		XMLFile.Active;
		GetSystemTime( UTCDateTime );
		cPassHash := MakeSHA512( InInvoice.Supplier.Password );
		cKey := InInvoice.RequestId + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + String( InInvoice.Supplier.SignKey );
//		ChildNode := XMLFile.CreateNode( 'InvoiceNumber', ntComment );
//		XMLFile.ChildNodes.Add( ChildNode );
//		ChildNode.Text := 'Szamla szama: ' + InInvoice.InvoiceNumber;
//		ChildNode := XMLFile.CreateNode( 'CustomerName', ntComment );
//		XMLFile.ChildNodes.Add( ChildNode );
//		ChildNode.Text := 'Ceg neve: ' + InInvoice.FinPart2Name;
		MainNode := XMLFile.AddChild( 'QueryTransactionStatusRequest' );
		XMLInsertSchemas( MainNode );
		ChildNode := MainNode.AddChild( cNAVCommonSchema + 'header' );
		ChildNode.AddChild( cNAVCommonSchema + 'requestId' ).Text := InInvoice.RequestId;
		ChildNode.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
		ChildNode.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := GetNAVVersion( MainForm.AppSettings.NAVVersion );
		ChildNode.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
		ChildNode := MainNode.AddChild( cNAVCommonSchema + 'user' );
		ChildNode.AddChild( cNAVCommonSchema + 'login' ).Text := InInvoice.Supplier.Login;
		ResultNode := ChildNode.AddChild( cNAVCommonSchema + 'passwordHash' );
		ResultNode.Text := UpperCase( cPassHash );
		ResultNode.Attributes[ 'cryptoType' ] := 'SHA-512';
		ChildNode.AddChild( 'taxNumber' ).Text := Copy( InInvoice.Supplier.TAXPayerID,1,8 );
		ResultNode := ChildNode.AddChild( cNAVCommonSchema + 'requestSignature' );
		ResultNode.Text := UpperCase( MakeSHA3512( cKey ));
		ResultNode.Attributes[ 'cryptoType' ] := 'SHA3-512';
		ChildNode := MainNode.AddChild( 'software' );
		ChildNode.AddChild( 'softwareId' ).Text := SoftwareData.ID;
		ChildNode.AddChild( 'softwareName' ).Text := SoftwareData.Name;
		ChildNode.AddChild( 'softwareOperation' ).Text := SoftwareData.Operation;
		ChildNode.AddChild( 'softwareMainVersion' ).Text := SoftwareData.MainVersion;
		ChildNode.AddChild( 'softwareDevName' ).Text := SoftwareData.DevName;
		ChildNode.AddChild( 'softwareDevContact' ).Text := SoftwareData.DevContact;
		ChildNode.AddChild( 'softwareDevCountryCode' ).Text := SoftwareData.DevCountryCode;
		ChildNode.AddChild( 'softwareDevTaxNumber' ).Text := SoftwareData.DevTaxNumber;
		MainNode.AddChild( 'transactionId' ).Text := InInvoice.TransactionID;
		MainNode.AddChild( 'returnOriginalRequest' ).Text := 'true';
		cXMLFile := InInvoice.RequestId + '.xml';
		try
			try
				cXML := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
				XMLFile := LoadXMLData( cXML );
				XMLFile.Encoding := 'utf-8';
				WriteLogFile( 'XML file elkészítése (' + cXMLFile + ')',3 );
				XMLFile.SaveToFile( MainForm.AppSettings.cSendPath + '\' + cXMLFile );
				WriteLogFile( 'XML file elkészítése megtörtént (' + MainForm.AppSettings.cSendPath + '\' + cXMLFile + ')',3 );
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
		WriteLogFile( 'XML file küldése indul (' + InInvoice.RequestID + '.xml)',3 );
		cXMLFile := SendXML( cXMLFile, InInvoice.TestMode, nQTransactionStatus );
		if cXMLFile <> '' then begin
			WriteLogFile( 'A számla állapota lekérdezve.',1 );
			XMLFile := LoadXMLDocument( MainForm.AppSettings.cReceivePath + '\' + cXMLFile );
			MainNode := XMLFile.ChildNodes.FindNode( 'QueryTransactionStatusResponse' );
			ChildNode := MainNode.ChildNodes.FindNode( 'header','' );
			ChildNode := ChildNode.ChildNodes.FindNode( 'requestId','' );
			if InInvoice.RequestId = ChildNode.Text then begin
				ChildNode := MainNode.ChildNodes.FindNode( 'result','' );
				ChildNode := ChildNode.ChildNodes.FindNode( 'funcCode','' );
				if ChildNode.Text = 'OK' then begin
					ChildNode := MainNode.ChildNodes.FindNode( 'processingResults' );
					if ChildNode <> NIL then begin
						ResultNode := ChildNode.ChildNodes.FindNode( 'processingResult' );
						ChildNode := ResultNode.ChildNodes.FindNode( 'invoiceStatus' );
						InInvoice.InvStatusNum := '5';
						InInvoice.StatusDateTime := Now;
						if ChildNode.Text = 'DONE' then begin
							InInvoice.InvStatusNum := '6';
							InInvoice.InvStatusText := 'Számla lekérdezve';
						end;
						if ChildNode.Text = 'ABORTED' then begin
							InInvoice.InvStatusNum := '6';
// Van-e "businessValidationMessages" elem
							AbortNode := ResultNode.ChildNodes.FindNode( 'businessValidationMessages','' );
							if AbortNode <> NIL then begin
								InInvoice.ErrorText := Copy( AbortNode.ChildNodes.FindNode( 'message','' ).Text,1,100 );
							end;
// Van-e "technicalValidationMessages" elem
							AbortNode := ResultNode.ChildNodes.FindNode( 'technicalValidationMessages','' );
							if AbortNode <> NIL then begin
								InInvoice.ErrorText := Copy( AbortNode.ChildNodes.FindNode( 'message','' ).Text,1,100 );
							end;
							SendErrorMail( InInvoice, '' );
						end;
						if ( ChildNode.Text = 'RECEIVED' ) or ( ChildNode.Text = 'PROCESSING' ) then begin
							lDeleteXML := TRUE;
						end;
						InInvoice.InvStatus := ChildNode.Text;
						InInvoice.SetNavStatus;
						WriteLogFile( 'A számla feldolgozottsági állapota : ' + ChildNode.Text,3 );
						Result := ChildNode.Text;
					end else begin
// Ha nincs "processingResults" elem, akkor is elfogadjuk a lekérdezést
						WriteLogFile( 'A számla állapotának lekérdezésekor nincs DONE !!!',1 );
						InInvoice.StatusDateTime := Now;
						InInvoice.InvStatusNum := '6';
						InInvoice.InvStatus := 'OK';
						InInvoice.InvStatusText := 'Számla lekérdezve';
						InInvoice.SetNavStatus;
						SendErrorMail( InInvoice, '' );
						Result := 'OK';
					end;
				end else begin
					WriteLogFile( 'Hiba a számla állapotának lekérdezésekor!!!',1 );
					WriteLogFile( 'A lekérdezés eredménye nem OK (' + ChildNode.Text + ')',3 );
					SendErrorMail( InInvoice, '' );
				end;
			end else begin
				WriteLogFile( 'Hiba a számla állapotának lekérdezésekor!!!',1 );
				WriteLogFile( 'A válasz XML-ben nem egyezõ REQUESTID (' + cXMLFile + ')',3 );
				SendErrorMail( InInvoice, '' );
			end;
			XMLFile.Active := FALSE;
			if lDeleteXML then begin
				if MainForm.NAVASzSettings.lDeleteProcessing then begin
					WriteLogFile( 'PROCESSING xml fileok törlése : ' + cXMLFile, 3 );
					DeleteFile( MainForm.AppSettings.cReceivePath + '\' + cXMLFile );
					DeleteFile( MainForm.AppSettings.cSendPath + '\' + cXMLFile );
				end;
			end;
		end else begin
			WriteLogFile( 'Hiba a számla állapotának lekérdezésekor', 1 );
			SendErrorMail( InInvoice, '' );
		end;
	end else begin
		WriteLogFile( 'Hibás token (' + cExchangeToken + ')',2 );
		SendErrorMail( InInvoice, '' );
	end;
end;

end.
