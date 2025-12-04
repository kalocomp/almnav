unit NAVTokenExchange;

interface

uses NAV, invoice;

function GetToken( InInvoice : TInvoice ) : string;

implementation

uses Vcl.ExtCtrls, Windows, System.DateUtils, SysUtils, XMLDoc, XMLIntf, Main, Dialogs, Classes, XMLHandler, MailSending;

function GetToken( InInvoice : TInvoice ) : string;
var
	cXMLFile									: string;
	XMLFile									: IXMLDocument;
	MainNode,ChildNode,ErrorNode		: IXMLNode;
	UTCDateTime								: TSystemTime;
	InternetTime							: TDateTime;
	cPassHash,cKey,cXML        		: string;
	I											: integer;
begin
// Mielõtt bármit is tennénk le kell kérdezniünk az idõt
//	MainForm.NAVTime.Host := 'time.nist.gov';
//	InternetTime := MainForm.NAVTime.DateTime;
	InternetTime := Now;
	if MinutesBetween( Now, InternetTime ) < 5 then begin
// Jöhet a token kérés
		InInvoice.InvStatusNum := '2';
		InInvoice.InvStatusText := 'Token kérés';
		InInvoice.RequestDateTime := Now;
		InInvoice.NAVError := '0';
// A token requestID-jének elsõ betûjét le kell cserélni 'T'-re
		InInvoice.RequestId := 'T' + Copy( InInvoice.RequestId,2,Length( InInvoice.RequestId ) - 1 );
		InInvoice.SetNavStatus;
		cXMLFile := '';
		WriteLogFile( String( InInvoice.RequestId ) + ' - token kérése',2 );
		GetSystemTime( UTCDateTime );
		WriteLogFile( 'Login : ' + String( InInvoice.Supplier.Login ),4 );
		cPassHash := MakeSHA512( String( InInvoice.Supplier.Password ));
		WriteLogFile( 'Jelszó : ' + String( InInvoice.Supplier.Password ),4 );
		WriteLogFile( 'Titkosított jelszó : ' + cPassHash,4 );
		cKey := String( InInvoice.RequestId ) + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + String( InInvoice.Supplier.SignKey );
		WriteLogFile( 'RequestSiganture : ' + cKey,4 );
		WriteLogFile( 'RequestSiganture (SHA3-512) : ' + UpperCase( MakeSHA3512( cKey )),4 );
		XMLFile := NewXMLDocument;
		XMLFile.Options := [ doNodeAutoIndent ];
		XMLFile.Active;
//		ChildNode := XMLFile.CreateNode( 'InvoiceNumber', ntComment );
//		XMLFile.ChildNodes.Add( ChildNode );
//		ChildNode.Text := 'Szamla szama: ' + String( InInvoice.InvoiceNumber );
//		ChildNode := XMLFile.CreateNode( 'CustomerName', ntComment );
//		XMLFile.ChildNodes.Add( ChildNode );
//		ChildNode.Text := 'Ceg neve: ' + String( InInvoice.FinPart2Name );
		MainNode := XMLFile.AddChild( 'TokenExchangeRequest' );
		XMLInsertSchemas( MainNode );
		ChildNode := MainNode.AddChild( cNAVCommonSchema + 'header' );
		ChildNode.AddChild( cNAVCommonSchema + 'requestId' ).Text := String( InInvoice.RequestId );
		ChildNode.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
		ChildNode.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := String( GetNAVVersion( MainForm.AppSettings.NAVVersion ));
		ChildNode.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
		ChildNode := MainNode.AddChild( cNAVCommonSchema + 'user' );
		ChildNode.AddChild( cNAVCommonSchema + 'login' ).Text := String( InInvoice.Supplier.Login );
		ErrorNode := ChildNode.AddChild( cNAVCommonSchema + 'passwordHash' );
		ErrorNode.Text := UpperCase( cPassHash );
		ErrorNode.Attributes[ 'cryptoType' ] := 'SHA-512';
		ChildNode.AddChild( cNAVCommonSchema + 'taxNumber' ).Text := Copy( String( InInvoice.Supplier.TAXPayerID ),1,8 );
		ErrorNode := ChildNode.AddChild( cNAVCommonSchema + 'requestSignature' );
		ErrorNode.Text := String( UpperCase( MakeSHA3512( cKey )));
		ErrorNode.Attributes[ 'cryptoType' ] := 'SHA3-512';
		ChildNode := MainNode.AddChild( 'software' );
		ChildNode.AddChild( 'softwareId' ).Text := String( SoftwareData.ID );
		ChildNode.AddChild( 'softwareName' ).Text := String( SoftwareData.Name );
		ChildNode.AddChild( 'softwareOperation' ).Text := String( SoftwareData.Operation );
		ChildNode.AddChild( 'softwareMainVersion' ).Text := String( SoftwareData.MainVersion );
		ChildNode.AddChild( 'softwareDevName' ).Text := String( SoftwareData.DevName );
		ChildNode.AddChild( 'softwareDevContact' ).Text := String( SoftwareData.DevContact );
		ChildNode.AddChild( 'softwareDevCountryCode' ).Text := String( SoftwareData.DevCountryCode );
		ChildNode.AddChild( 'softwareDevTaxNumber' ).Text := String( SoftwareData.DevTaxNumber );
		try
			try
				cXML := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
				XMLFile := LoadXMLData( cXML );
				XMLFile.Encoding := 'utf-8';
				WriteLogFile( 'XML file elkészítése (token.xml)',3 );
				XMLFile.SaveToFile( String( MainForm.AppSettings.cSendPath ) + '\token.xml' );
				WriteLogFile( 'XML file elkészítése megtörtént ( ' + String( MainForm.AppSettings.cSendPath ) + '\token.xml)',3 );
				cXMLFile := 'token.xml';
			finally
				XMLFile.Active := FALSE;
			end;
		except
			on E: Exception do begin
				WriteLogFile( 'Hiba az XML file elkészítésekor (' + String( MainForm.AppSettings.cSendPath ) + '\token.xml)',3 );
				WriteLogFile( E.ClassName + ': ' + E.Message,4 );
				cXMLFile := '';
			end;
		end;
		Result := '';
		MainNode := NIL;
		ChildNode := NIL;
		if cXMLFile <> '' then begin
			cXMLFile := SendXML( cXMLFile, InInvoice.TestMode, nTokenExchange );
			if cXMLFile <> '' then begin
				XMLFile := LoadXMLDocument( String( MainForm.AppSettings.cReceivePath ) + '\' + cXMLFile );
				MainNode := XMLFile.ChildNodes.FindNode( 'TokenExchangeResponse' );
				if MainNode <> NIL then begin
					ChildNode := MainNode.ChildNodes.FindNode( 'header','' );
					ChildNode := ChildNode.ChildNodes.FindNode( 'requestId','' );
					if String( InInvoice.RequestId ) = ChildNode.Text then begin
						ChildNode := MainNode.ChildNodes.FindNode( 'result','' );
						ChildNode := ChildNode.ChildNodes.FindNode( 'funcCode','' );
						if ChildNode.Text = 'OK' then begin
							ChildNode := MainNode.ChildNodes.FindNode( 'encodedExchangeToken' );
							Result := ChildNode.Text;
							WriteLogFile( 'A válasz token : ' + Result,3 );
						end else begin
							WriteLogFile( 'A válasz XML-ben nincs OK (' + cXMLFile + ')',3 );
							InInvoice.InvStatusNum := '1';
							InInvoice.InvStatusText := 'Token kérés hiba';
							InInvoice.RequestDateTime := Now;
							InInvoice.NAVError := '1';
							InInvoice.SetNAVStatus;
							SendErrorMail( InInvoice, cXMLFile );
						end;
					end else begin
						InInvoice.InvStatusNum := '1';
						InInvoice.InvStatusText := 'Token hiba';
						InInvoice.RequestDateTime := Now;
						InInvoice.NAVError := '1';
						InInvoice.SetNAVStatus;
						SendErrorMail( InInvoice, cXMLFile );
						WriteLogFile( 'A válasz XML-ben nem egyezõ REQUESTID (' + String( MainForm.AppSettings.cReceivePath ) + '\' + cXMLFile + ')',3 );
					end;
				end else begin
					MainNode := XMLFile.ChildNodes.FindNode( 'GeneralErrorResponse' );
					if MainNode <> NIL then begin
						ChildNode := MainNode.ChildNodes.FindNode( 'header' );
						if ChildNode <> NIL then begin
							ChildNode := ChildNode.ChildNodes.FindNode( 'requestId' );
							if String( InInvoice.RequestId ) = ChildNode.Text then begin
								ErrorNode := MainNode.ChildNodes.FindNode( 'result' );
								ChildNode := ErrorNode.ChildNodes.FindNode( 'funcCode' );
								if ChildNode.Text = 'ERROR' then begin
									ChildNode := ErrorNode.ChildNodes.FindNode( 'errorCode' );
									WriteLogFile( 'Hiba kód : ' + ChildNode.Text,3 );
									ChildNode := ErrorNode.ChildNodes.FindNode( 'message' );
									WriteLogFile( 'Hiba : ' + ChildNode.Text,3 );
									InInvoice.NAVError := '1';
									InInvoice.SetNavStatus;
								end else begin
									InInvoice.InvStatusNum := '1';
									InInvoice.InvStatusText := 'Token hiba';
									InInvoice.RequestDateTime := Now;
									InInvoice.NAVError := '1';
									InInvoice.SetNavStatus;
									WriteLogFile( 'A válasz XML-ben nem egyezõ REQUESTID (' + String( MainForm.AppSettings.cReceivePath ) + '\' + cXMLFile + ')',3 );
								end;
							end;
						end else begin
							InInvoice.InvStatusNum := '1';
							InInvoice.InvStatusText := 'Azonosítási hiba';
							InInvoice.RequestDateTime := Now;
							InInvoice.NAVError := '1';
							InInvoice.SetNavStatus;
							WriteLogFile( 'Azonosítási hiba (' + String( MainForm.AppSettings.cReceivePath ) + '\' + cXMLFile + ')',3 );
						end;
					end;
					SendErrorMail( InInvoice, cXMLFile );
				end;
			end else begin
				InInvoice.InvStatusNum := '1';
				InInvoice.InvStatusText := 'NET hiba';
				InInvoice.RequestDateTime := Now;
				InInvoice.NAVError := '0';
				InInvoice.SetNavStatus;
				SendErrorMail( InInvoice, '' );
			end;
		end;
// A token requestID-jének elsõ betûjét vissza kell cserélni 'S'-re
		InInvoice.RequestId := 'S' + Copy( InInvoice.RequestId,2,Length( InInvoice.RequestId ) - 1 );
	end else begin
		MainForm.MyShowBalloonHint( 'Hiba !!!', 'A számítógép órája nem megfelelõ!!!', bfError );
		WriteLogFile( 'A számítógép órája nem megfelelõ!!! ' + FormatDateTime( 'yyyy.mm.dd hh:nn:ss', InternetTime ), 3 );
		Result := '';
	end;
end;

end.


