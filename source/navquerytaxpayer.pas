unit NAVQueryTaxpayer;

interface

uses invoice;

function MakeTaxPayer( InInvoice : TInvoice; CheckTaxNumber : string ) : string;
function CheckTaxPayer( InInvoice : TInvoice; CheckTaxNumber : string ) : string;

implementation

uses Windows, SysUtils, XMLDoc, XMLIntf, Main, Dialogs, Classes, XMLHandler, TaxPayer, NAV, System.UITypes;

function CheckTaxPayer( InInvoice : TInvoice; CheckTaxNumber : string ) : string;
var
	cXMLFile									: string;
	XMLFile									: IXMLDocument;
	MainNode,Level1Node					: IXMLNode;
	Level2Node,Level3Node,Level4Node : IXMLNode;
begin
	cXMLFile := MakeTaxPayer( InInvoice, CheckTaxNumber );
	Result := '';
	if cXMLFile <> '' then begin
		cXMLFile := SendXML( cXMLFile, InInvoice.TestMode, nQTaxpayer );
		if cXMLFile <> '' then begin
			WriteLogFile( 'Válasz XML feldolgozása (' + cXMLFile + ')',3 );
			XMLFile := LoadXMLDocument( MainForm.AppSettings.cReceivePath + '\' + cXMLFile );
			MainNode := XMLFile.ChildNodes.FindNode( 'QueryTaxpayerResponse','' );
			Level1Node := MainNode.ChildNodes.FindNode( 'header','' );
			Level2Node := Level1Node.ChildNodes.FindNode( 'requestId','' );
			if InInvoice.RequestId = Level2Node.Text then begin
				Level1Node := MainNode.ChildNodes.FindNode( 'result','' );
				Level2Node := Level1Node.ChildNodes.FindNode( 'funcCode','' );
				if Level2Node.Text = 'OK' then begin
					Level1Node := MainNode.ChildNodes.FindNode( 'taxpayerValidity' );
					if Level1Node.Text = 'true' then begin
						WriteLogFile( 'Az adószám létezik (' + CheckTaxNumber + ')',2 );
						Level1Node := MainNode.ChildNodes.FindNode( 'infoDate' );
						TaxPayerForm.RegDateEdit.Text := Level1Node.Text;
						Level1Node := MainNode.ChildNodes.FindNode( 'taxpayerData' );
						Level2Node := Level1Node.ChildNodes.FindNode( 'taxpayerName' );
						TaxPayerForm.cTaxNumber := MainForm.AdoszamEdit.Text;
						TaxPayerForm.cTaxPayerName := Level2Node.Text;
						Level2Node := Level1Node.ChildNodes.FindNode( 'taxpayerAddressList' );
						if ( Level2Node <> NIL ) then begin
							Level3Node := Level2Node.ChildNodes.FindNode( 'taxpayerAddressItem' );
							if ( Level3Node <> NIL ) then begin
								Level4Node := Level3Node.ChildNodes.FindNode( 'taxpayerAddressType' );
								if ( Level4Node <> NIL ) then begin
									if ( Level4Node.Text = 'HQ' ) then begin
										Level4Node := Level3Node.ChildNodes.FindNode( 'taxpayerAddress' );
										TaxPayerForm.cTaxPayerCountry := ReadNodeText( Level4Node, 'countryCode' );
										TaxPayerForm.cTaxPayerPostalCode := ReadNodeText( Level4Node, 'postalCode' );
										TaxPayerForm.cTaxPayerCity := ReadNodeText( Level4Node, 'city' );;
										TaxPayerForm.cTaxPayerStreet := ReadNodeText( Level4Node, 'streetName' );;
										TaxPayerForm.cTaxPayerPlace := ReadNodeText( Level4Node, 'publicPlaceCategory' );;
										TaxPayerForm.cTaxPayerNumber := ReadNodeText( Level4Node, 'number' );;
									end;
								end;
							end;
						end;
						Result := 'OK';
					end else begin
						WriteLogFile( 'Az adószám nem léteik (' + CheckTaxNumber + ')',2 );
					end;
				end else begin
					WriteLogFile( 'A válasz XML-ben nincs OK (' + cXMLFile + ')',3 );
				end;
			end else begin
				WriteLogFile( 'A válasz XML-ben nem egyezõ REQUESTID (' + cXMLFile + ')',3 );
			end;
		end;
	end;
end;

function MakeTaxPayer( InInvoice : TInvoice; CheckTaxNumber : string ) : string;
var
	UTCDateTime								: TSystemTime;
	cPassHash,cKey,cXML					: string;
	XMLFile									: IXMLDocument;
	MainNode,Level1Node,Level2Node	: IXMLNode;
begin
	WriteLogFile( ' Adószám ellenõrzés : ' + CheckTaxNumber,1 );
	GetSystemTime( UTCDateTime );
	cPassHash := MakeSHA512( InInvoice.Supplier.Password );
	WriteLogFile( 'Titkosított jelszó : ' + cPassHash,4 );
	cKey := InInvoice.RequestId + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + InInvoice.Supplier.SignKey;
	WriteLogFile( 'RequestSiganture : ' + UpperCase( MakeSHA512( cKey )),4 );
	XMLFile := NewXMLDocument;
	XMLFile.Options := [ doNodeAutoIndent ];
	XMLFile.Active;
	MainNode := XMLFile.AddChild( 'QueryTaxpayerRequest' );
	XMLInsertSchemas( MainNode );
	Level1Node := MainNode.AddChild( cNAVCommonSchema + 'header' );
	Level1Node.AddChild( cNAVCommonSchema + 'requestId' ).Text := InInvoice.RequestId;
	Level1Node.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
	Level1Node.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := String( GetNAVVersion( MainForm.AppSettings.NAVVersion ));
	Level1Node.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
	Level1Node := MainNode.AddChild( cNAVCommonSchema + 'user' );
	Level1Node.AddChild( cNAVCommonSchema + 'login' ).Text := InInvoice.Supplier.Login;
	Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'passwordHash' );
	Level2Node.Text := UpperCase( cPassHash );
	Level2Node.Attributes[ 'cryptoType' ] := 'SHA-512';
	Level1Node.AddChild( cNAVCommonSchema + 'taxNumber' ).Text := Copy( InInvoice.Supplier.TAXPayerID,1,8 );
	Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'requestSignature' );
	Level2Node.Text := String( UpperCase( MakeSHA3512( cKey )));
	Level2Node.Attributes[ 'cryptoType' ] := 'SHA3-512';
	Level1Node := MainNode.AddChild( 'software' );
	Level1Node.AddChild( 'softwareId' ).Text := SoftwareData.ID;
	Level1Node.AddChild( 'softwareName' ).Text := SoftwareData.Name;
	Level1Node.AddChild( 'softwareOperation' ).Text := SoftwareData.Operation;
	Level1Node.AddChild( 'softwareMainVersion' ).Text := SoftwareData.MainVersion;
	Level1Node.AddChild( 'softwareDevName' ).Text := SoftwareData.DevName;
	Level1Node.AddChild( 'softwareDevContact' ).Text := SoftwareData.DevContact;
	Level1Node.AddChild( 'softwareDevCountryCode' ).Text := SoftwareData.DevCountryCode;
	Level1Node.AddChild( 'softwareDevTaxNumber' ).Text := SoftwareData.DevTaxNumber;
	MainNode.AddChild( 'taxNumber' ).Text := CheckTaxNumber;
	try
		try
			cXML := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
			XMLFile := LoadXMLData( cXML );
			XMLFile.Encoding := 'utf-8';
			WriteLogFile( 'XML file elkészítése (tax.xml)',3 );
			XMLFile.SaveToFile( MainForm.AppSettings.cSendPath + '\tax.xml' );
			WriteLogFile( 'XML file elkészítése megtörtént (tax.xml)',3 );
			Result := 'tax.xml';
		finally
			XMLFile.Active := FALSE;
		end;
	except
		on E: Exception do begin
			MessageDlg( 'Hiba az XML file elkészítésekor ' + E.ClassName + ': ' + E.Message, mtWarning, [ mbOK ], 0);
			Result := '';
		end;
	end;
end;

end.
