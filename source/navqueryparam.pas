unit NAVQueryParam;

interface

uses NAV, Windows, SysUtils, XMLDoc, XMLIntf, XMLHandler, NAVTokenExchange, Main, DCPBase64,
	Vcl.Dialogs, Winapi.Messages, Vcl.ExtCtrls, frxClass, frxDBSet, frxExportPDF;

procedure GetInvoiceData( InNAVInvoice : TNAVInvoice );
function MakeInvoiceData( InNAVInvoice : TNAVInvoice ) : string;

implementation

procedure GetInvoiceData( InNAVInvoice : TNAVInvoice );
begin
end;

function MakeInvoiceData( InNAVInvoice : TNAVInvoice ) : string;
var
	UTCDateTime								: TSystemTime;
	MySettings								: TFormatSettings;
	cPassHash,cKey,cDate,cXML			: string;
	cBase64XML								: string;
	cExchangeToken,cXMLFile				: string;
	XMLFile									: IXMLDocument;
	MainNode,ChildNode					: IXMLNode;
begin
	GetLocaleFormatSettings( GetUserDefaultLCID, MySettings );
	MySettings.DateSeparator := '-';
	MySettings.TimeSeparator := ':';
	MySettings.ShortDateFormat := 'yyyy-mm-dd';
	MySettings.ShortTimeFormat := 'hh:nn:ss';
	MySettings.DecimalSeparator := '.';
	WriteLogFile( 'Számla adatok lekérdezése : ' + Trim( InNAVInvoice.RequestId ) + ' (' + IntToStr( InNAVInvoice.RecordNumber ) + '. rekord)',1 );
	if InNAVInvoice.TransactionID <> '' then begin
		XMLFile := NewXMLDocument;
		XMLFile.Options := [ doNodeAutoIndent ];
		XMLFile.Active;
		GetSystemTime( UTCDateTime );
		cPassHash := MakeSHA512( InNAVInvoice.FinPart1.Password );
		cKey := InNAVInvoice.RequestId + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + InNAVInvoice.FinPart1.SignKey;
//		ChildNode := XMLFile.CreateNode( 'InvoiceNumber', ntComment );
//		XMLFile.ChildNodes.Add( ChildNode );
//		ChildNode.Text := 'Szamla szama: ' + InNAVInvoice.InvoiceNumber;
//		ChildNode := XMLFile.CreateNode( 'CustomerName', ntComment );
//		XMLFile.ChildNodes.Add( ChildNode );
//		ChildNode.Text := 'Ceg neve: ' + InNAVInvoice.FinPart2Name;
		MainNode := XMLFile.AddChild( 'QueryInvoiceDataRequest' );
//		MainNode.Attributes[ 'xmlns' ] := cNAVSchema;
		ChildNode := MainNode.AddChild( 'header' );
		ChildNode.AddChild( 'requestId' ).Text := InNAVInvoice.RequestId;
		ChildNode.AddChild( 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
		ChildNode.AddChild( 'requestVersion' ).Text := GetNAVVersion( MainForm.AppSettings.NAVVersion );
		ChildNode.AddChild( 'headerVersion' ).Text := '1.0';
		ChildNode := MainNode.AddChild( 'user' );
		ChildNode.AddChild( 'login' ).Text := InNAVInvoice.FinPart1.Login;
		ChildNode.AddChild( 'passwordHash' ).Text := UpperCase( cPassHash );
		ChildNode.AddChild( 'taxNumber' ).Text := Copy( InNAVInvoice.FinPart1.TaxNumber,1,8 );
		ChildNode.AddChild( 'requestSignature' ).Text := UpperCase( MakeSHA512( cKey ));
		ChildNode := MainNode.AddChild( 'software' );
		ChildNode.AddChild( 'softwareId' ).Text := SoftwareData.ID;
		ChildNode.AddChild( 'softwareName' ).Text := SoftwareData.Name;
		ChildNode.AddChild( 'softwareOperation' ).Text := SoftwareData.Operation;
		ChildNode.AddChild( 'softwareMainVersion' ).Text := SoftwareData.MainVersion;
		ChildNode.AddChild( 'softwareDevName' ).Text := SoftwareData.DevName;
		ChildNode.AddChild( 'softwareDevContact' ).Text := SoftwareData.DevContact;
		ChildNode.AddChild( 'softwareDevCountryCode' ).Text := SoftwareData.DevCountryCode;
		ChildNode.AddChild( 'softwareDevTaxNumber' ).Text := SoftwareData.DevTaxNumber;
		MainNode.AddChild( 'page' ).Text := '1';
		ChildNode := MainNode.AddChild( 'queryParams' );
		ChildNode.AddChild( 'invoiceIssueDateFrom' ).Text := '2018-07-01';
		ChildNode.AddChild( 'invoiceIssueDateTo' ).Text := '2018-07-18';
		cXMLFile := InNAVInvoice.RequestId + '.xml';
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
		WriteLogFile( 'XML file küldése indul (' + InNAVInvoice.RequestID + '.xml)',3 );
		cXMLFile := SendXML( cXMLFile, InNAVInvoice.TestMode, nQInvoiceData );
		if cXMLFile <> '' then begin

		end else begin
			WriteLogFile( 'Hiba a számla állapotának lekérdezésekor', 1 );
		end;
	end else begin
		WriteLogFile( 'Hibás token (' + cExchangeToken + ')',2 );
	end;
end;

end.
