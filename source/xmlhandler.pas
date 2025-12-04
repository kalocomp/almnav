unit XMLHandler;

interface

uses XMLDoc, XMLIntf, System.SysUtils, currencyread, Syncsetting;

type
	TVarType = ( vt_String,vt_Logical,vt_Numeric,vt_DateTime );

	procedure ReadXMLFile;
	procedure WriteXMLFile;
	procedure WriteLogFile( cMessage : string; nLevel : integer );
	procedure XMLInsertSchemas( InNode : IXMLNode );
	function MakeUniqueFileName( InTaxNumber : string; InDate : TDateTime ) : string;
	function ShellExecuteAndWait( FileName: string; Params: string ): boolean;

implementation

uses System.Classes, Main, Crypt, Windows, ShellAPI, VCL.Forms, NAVRead, NAV;

procedure ReadXMLFile;
var
	XMLFile												: IXMLDocument;
	XMLGlobal,XMLItems,XMLItem,XMLSettings		: IXMLNode;
	cXMLFile,cCryptPassword,cSeged				: string;

	// Egy elem beolvasása az XML fileból
function ReadNode( InItem : IXMLNode; InNodeName : string; InType : TVarType ) : string;
var
	XMLNode : IXMLNode;
begin
	XMLNode := InItem.ChildNodes.FindNode( InNodeName );
	if XMLNode <> NIL then begin
		Result := XMLNode.Text;
	end else begin
		case InType of
			vt_String: begin
				Result := '';
			end;
			vt_Numeric: begin
				Result := '0';
			end;
			vt_Logical: begin
				Result := 'FALSE';
			end;
			vt_DateTime: begin
				Result := '2021-01-01 00:00:00';
			end;
		end;
	end;
	XMLNode := NIL;;
end;

begin
	SetMySettings;
	cXMLFile := MainForm.cAppPath + '\almiranav.xml';
	if FileExists( cXMLFile ) then begin
		XMLFile := TXMLDocument.Create( NIL );
		XMLFile.LoadFromFile( 'almiranav.xml' );
		XMLGlobal := XMLFile.ChildNodes.FindNode( 'Main' );
		if XMLGlobal <> NIL then begin
// Általános adatok
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'Settings' );
			if XMLSettings <> NIL then begin
				MainForm.AppSettings.cXMLReceivePath := ReadNode( XMLSettings, 'ReceivePath', vt_String );
				MainForm.AppSettings.cXMLSendPath := ReadNode( XMLSettings, 'SendPath', vt_String );
				MainForm.AppSettings.NAVVersion := SetNAVVersion( ReadNode( XMLSettings, 'NAVVersion', vt_String ));
				MainForm.AppSettings.cXMLLogPath := ReadNode( XMLSettings, 'LogPath', vt_String );
				MainForm.AppSettings.nLogLevel := StrToInt( ReadNode( XMLSettings, 'LogLevel', vt_String ));
				MainForm.AppSettings.nBalloonTimeOut := StrToInt( ReadNode( XMLSettings, 'BalloonTimeOut', vt_String ));
				MainForm.AppSettings.WindowPos.X := StrToInt( ReadNode( XMLSettings, 'WindowLeft', vt_String ));
				MainForm.AppSettings.WindowPos.Y := StrToInt( ReadNode( XMLSettings, 'WindowTop', vt_String ));
				MainForm.AppSettings.WindowWidth := StrToInt( ReadNode( XMLSettings, 'WindowWidth', vt_String ));
				MainForm.AppSettings.WindowHeight := StrToInt( ReadNode( XMLSettings, 'WindowHeight', vt_String ));
			end;
// NAVASz beállítások
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'NAVASzSettings' );
			if XMLSettings <> NIL then begin
				if ReadNode( XMLSettings, 'Active', vt_String ) = '1' then begin
					MainForm.NAVASzSettings.lActive := TRUE;
				end else begin
					MainForm.NAVASzSettings.lActive := FALSE;
				end;
				MainForm.NAVASzSettings.cDBFPath := ReadNode( XMLSettings, 'DBFPath', vt_String );
				MainForm.NAVASzSettings.cEInvoicePath := ReadNode( XMLSettings, 'EInvoicePath', vt_String );
				if ( MainForm.NAVASzSettings.cEInvoicePath = '' ) then begin
					MainForm.NAVASzSettings.cEInvoicePath := 'einvoice';
				end;
				MainForm.NAVASzSettings.nGridInterval := StrToInt( ReadNode( XMLSettings, 'GridInterval', vt_String ));
				MainForm.NAVASzSettings.nDBFInterval := StrToInt( ReadNode( XMLSettings, 'DBFInterval', vt_String ));
				MainForm.NAVASzSettings.nDeleteDay := StrToInt( ReadNode( XMLSettings, 'XMLDelete', vt_String ));
				if ReadNode( XMLSettings, 'DeleteProcessing', vt_String ) = '1' then begin
					MainForm.NAVASzSettings.lDeleteProcessing := TRUE;
				end else begin
					MainForm.NAVASzSettings.lDeleteProcessing := FALSE;
				end;
			end;
// NAVRead beállítások
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'NAVReadSettings' );
			if XMLSettings <> NIL then begin
				if ReadNode( XMLSettings, 'Active', vt_String ) = '1' then begin
					MainForm.NAVReadSettings.Active := TRUE;
				end else begin
					MainForm.NAVReadSettings.Active := FALSE;
				end;
				MainForm.NAVReadSettings.XMLInvoicePath := ReadNode( XMLSettings, 'InvoicePath', vt_String );
				MainForm.NAVReadSettings.BackDays := StrToInt( ReadNode( XMLSettings, 'BackDays', vt_String ));
				MainForm.NAVReadSettings.LastRead := StrToDateTime( ReadNode( XMLSettings, 'LastRead', vt_DateTime ), NAV.MySettings );
				MainForm.NAVReadSettings.ReadInterval := StrToInt( ReadNode( XMLSettings, 'ReadInterval', vt_String ));
				XMLItems := XMLSettings.ChildNodes.FindNode( 'NAVReadItems' );
				if ( XMLItems <> NIL ) then begin
					XMLItem := XMLItems.ChildNodes.FindNode( 'NAVReadItem' );
					while ( XMLItem <> NIL ) do begin
						MainForm.NAVReadSettings.NAVReadItems.Add;
						MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.NAVReadSettings.NAVReadItems.Count - 1 ].AlmiraPath := ReadNode( XMLItem, 'ALMIRAPath', vt_String );
						MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.NAVReadSettings.NAVReadItems.Count - 1 ].AlmiraSharePath := ReadNode( XMLItem, 'ALMIRASharePath', vt_String );
						MainForm.NAVReadSettings.NAVReadItems.Items[ MainForm.NAVReadSettings.NAVReadItems.Count - 1 ].StartDate := StrToDateTime( ReadNode( XMLItem, 'StartDate', vt_DateTime ), NAV.MySettings );
						XMLItem := XMLItem.NextSibling;
					end;
				end;

			end;
// Árfolyam olvasási adatok
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'CurrencyReadSettings' );
			if ( XMLSettings <> NIL ) then begin
				if ReadNode( XMLSettings, 'Active', vt_String ) = '1' then begin
					MainForm.CurrencyReadSettings.Active := TRUE;
				end else begin
					MainForm.CurrencyReadSettings.Active := FALSE;
				end;
				MainForm.CurrencyReadSettings.HTTPLink := ReadNode( XMLSettings, 'HTTPLink', vt_String );
				MainForm.CurrencyReadSettings.DBFPath := ReadNode( XMLSettings, 'DBFPath', vt_String );
				MainForm.CurrencyReadSettings.DBFFile := ReadNode( XMLSettings, 'DBFFile', vt_String );
				MainForm.CurrencyReadSettings.LastRead := StrToDateTime( ReadNode( XMLSettings, 'LastRead', vt_String ), NAV.MySettings );
				MainForm.CurrencyReadSettings.ReadInterval := StrToInt( ReadNode( XMLSettings, 'ReadInterval', vt_String ));
				XMLItems := XMLSettings.ChildNodes.FindNode( 'CurrencyItems' );
				if ( XMLItems <> NIL ) then begin
					XMLItem := XMLItems.ChildNodes.FindNode( 'CurrencyItem' );
					while ( XMLItem <> NIL ) do begin
						MainForm.CurrencyReadSettings.CurrencyReadItems.Add;
						MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 ].BankCode := StrToInt( ReadNode( XMLItem, 'BankCode', vt_String ));
						MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 ].CurrencyCode := ReadNode( XMLItem, 'CurrencyCode', vt_String );
						MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 ].BankName := aBankCode[ MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 ].BankCode - 1,0 ];
						XMLItem := XMLItem.NextSibling;
					end;
				end;
			end;
// Szinkronizálási beállítások
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'SyncSettings' );
			if ( XMLSettings <> NIL ) then begin
				if ReadNode( XMLSettings, 'Active', vt_String ) = '1' then begin
					MainForm.SyncSettings.Active := TRUE;
				end else begin
					MainForm.SyncSettings.Active := FALSE;
				end;
				MainForm.SyncSettings.ReadInterval := StrToInt( ReadNode( XMLSettings, 'ReadInterval', vt_String ));
				MainForm.SyncSettings.LastRead := StrToDateTime( ReadNode( XMLSettings, 'LastRead', vt_String ), NAV.MySettings );
				XMLItems := XMLSettings.ChildNodes.FindNode( 'SyncItems' );
				if ( XMLItems <> NIL ) then begin
					XMLItem := XMLItems.ChildNodes.FindNode( 'SyncItem' );
					while ( XMLItem <> NIL ) do begin
						MainForm.SyncSettings.SyncItems.Add;
						if ReadNode( XMLItem, 'Active', vt_String ) = '1' then begin
							MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].Active := TRUE;
						end else begin
							MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].Active := FALSE;
						end;
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].Name := ReadNode( XMLItem, 'Name', vt_String );
						cSeged := ReadNode( XMLItem, 'SessionType', vt_String );
						if cSeged = 'UploadPekseg' then MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SessionType := st_UploadLinzer;
						if cSeged = 'DownloadPekseg' then MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SessionType := st_DownloadLinzer;
						cSeged := LowerCase( ReadNode( XMLItem, 'SQLType', vt_String ));
						if cSeged = 'firebird' then MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLType := sqt_Firebird;
						if cSeged = 'mysql' then MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLType := sqt_MySQL;
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLServer := ReadNode( XMLItem, 'SQLServer', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLPort := ReadNode( XMLItem, 'SQLPort', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLFileName := ReadNode( XMLItem, 'SQLFile', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLUser := ReadNode( XMLItem, 'SQLUser', vt_String );
						cSeged := ReadNode( XMLItem, 'SQLPassword', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].SQLPassword := DecodePWDEx( cSeged, '1234567890abcdefgh' );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].LocalYearDatabase := ReadNode( XMLItem, 'LocalYearPath', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].LocalYearShareDatabase := ReadNode( XMLItem, 'LocalYearSharePath', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].LocalShareDatabase := ReadNode( XMLItem, 'LocalSharePath', vt_String );
						MainForm.SyncSettings.SyncItems.Items[ MainForm.SyncSettings.SyncItems.Count - 1 ].ActYear := StrToInt( ReadNode( XMLItem, 'ActYear', vt_Numeric ));
						XMLItem := XMLItem.NextSibling;
					end;
				end;
			end;
// Szoftver adatai
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'Software' );
			if XMLSettings <> NIL then begin
				NAV.SoftwareData.ID := ReadNode( XMLSettings, 'SoftwareId', vt_String );
				NAV.SoftwareData.Name := ReadNode( XMLSettings, 'SoftwareName', vt_String );
				NAV.SoftwareData.Operation := ReadNode( XMLSettings, 'SoftwareOperation', vt_String );
				NAV.SoftwareData.MainVersion := ReadNode( XMLSettings, 'SoftwareMainVersion', vt_String );
				NAV.SoftwareData.DevName := ReadNode( XMLSettings, 'SoftwareDevName', vt_String );
				NAV.SoftwareData.DevContact := ReadNode( XMLSettings, 'SoftwareDevContact', vt_String );
				NAV.SoftwareData.DevCountryCode := ReadNode( XMLSettings, 'SoftwareDevCountryCode', vt_String );
				NAV.SoftwareData.DevTaxNumber := ReadNode( XMLSettings, 'SoftwareDevTaxNumber', vt_String );
			end;
// Email adatok
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'Email' );
			if XMLSettings <> NIL then begin
				if ReadNode( XMLSettings, 'EmailErrorSending', vt_String ) = '1' then begin
					MainForm.EMailSettings.MailSending := TRUE;
				end else begin
					MainForm.EMailSettings.MailSending := FALSE;
				end;
				MainForm.EMailSettings.MailSMTP := ReadNode( XMLSettings, 'SMTPServer', vt_String );
				MainForm.EMailSettings.MailPort := ReadNode( XMLSettings, 'SMTPPort', vt_String );
				MainForm.EMailSettings.MailUserName := ReadNode( XMLSettings, 'SMTPUser', vt_String );
				cCryptPassword := ReadNode( XMLSettings, 'SMTPPassword', vt_String );
				MainForm.EMailSettings.MailPassword := DecodePWDEx( cCryptPassword, '1234567890abcdefgh' );
				MainForm.EMailSettings.MailSender := ReadNode( XMLSettings, 'SenderName', vt_String );
				XMLItems := XMLSettings.ChildNodes.FindNode( 'EmailAddresses' );
				if XMLItems <> NIL then begin
					XMLItem := XMLItems.ChildNodes.FindNode( 'EmailAddress' );
					while XMLItem <> NIL do begin
						MainForm.EMailSettings.EMailItems.Add;
						if ( ReadNode( XMLItem, 'Active', vt_String ) = '0' ) then begin
							MainForm.EMailSettings.EMailItems[ MainForm.EMailSettings.EMailItems.Count - 1 ].Active := FALSE;
						end else begin
							MainForm.EMailSettings.EMailItems[ MainForm.EMailSettings.EMailItems.Count - 1 ].Active := TRUE;
						end;
						MainForm.EMailSettings.EMailItems[ MainForm.EMailSettings.EMailItems.Count - 1 ].EMailName := ReadNode( XMLItem, 'Name', vt_String );
						MainForm.EMailSettings.EMailItems[ MainForm.EMailSettings.EMailItems.Count - 1 ].EMailAddress := ReadNode( XMLItem, 'Address', vt_String );
						XMLItem := XMLItem.NextSibling;
					end;
				end;
			end;
// User adatok
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'User' );
			if XMLSettings <> NIL then begin
				MainForm.NAVASzSettings.cUserCompany := ReadNode( XMLSettings, 'Company', vt_String );
				MainForm.NAVASzSettings.cUserSites := ReadNode( XMLSettings, 'Site', vt_String );
				MainForm.NAVASzSettings.cUserMachine := ReadNode( XMLSettings, 'Machine', vt_String );
				MainForm.NAVASzSettings.cUserName := ReadNode( XMLSettings, 'User', vt_String );
			end;
// NAV linkek
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'NAVLinks' );
			if XMLSettings <> NIL then begin
				aNAVLink[ 0,nMAnnulment ] := ReadNode( XMLSettings, 'manageAnnulment', vt_String );
				aNAVLink[ 0,nMInvoice ] := ReadNode( XMLSettings, 'manageInvoice', vt_String );
				aNAVLink[ 0,nQInvoiceChainDigest ] := ReadNode( XMLSettings, 'queryInvoiceChainDigest', vt_String );
				aNAVLink[ 0,nQInvoiceCheck ] := ReadNode( XMLSettings, 'queryInvoiceCheck', vt_String );
				aNAVLink[ 0,nQInvoiceData ] := ReadNode( XMLSettings, 'queryInvoiceData', vt_String );
				aNAVLink[ 0,nQInvoiceDigest ] := ReadNode( XMLSettings, 'queryInvoiceDigest', vt_String );
				aNAVLink[ 0,nQTransactionList ] := ReadNode( XMLSettings, 'queryTransactionList', vt_String );
				aNAVLink[ 0,nQTransactionStatus ] := ReadNode( XMLSettings, 'queryTransactionStatus', vt_String );
				aNAVLink[ 0,nQTaxpayer ] := ReadNode( XMLSettings, 'queryTaxpayer', vt_String );
				aNAVLink[ 0,nTokenExchange ] := ReadNode( XMLSettings, 'tokenExchange', vt_String );
			end;
			XMLSettings := XMLGlobal.ChildNodes.FindNode( 'NAVLinksTest' );
			if XMLSettings <> NIL then begin
				aNAVLink[ 1,nMAnnulment ] := ReadNode( XMLSettings, 'manageAnnulment', vt_String );
				aNAVLink[ 1,nMInvoice ] := ReadNode( XMLSettings, 'manageInvoice', vt_String );
				aNAVLink[ 1,nQInvoiceChainDigest ] := ReadNode( XMLSettings, 'queryInvoiceChainDigest', vt_String );
				aNAVLink[ 1,nQInvoiceCheck ] := ReadNode( XMLSettings, 'queryInvoiceCheck', vt_String );
				aNAVLink[ 1,nQInvoiceData ] := ReadNode( XMLSettings, 'queryInvoiceData', vt_String );
				aNAVLink[ 1,nQInvoiceDigest ] := ReadNode( XMLSettings, 'queryInvoiceDigest', vt_String );
				aNAVLink[ 1,nQTransactionList ] := ReadNode( XMLSettings, 'queryTransactionList', vt_String );
				aNAVLink[ 1,nQTransactionStatus ] := ReadNode( XMLSettings, 'queryTransactionStatus', vt_String );
				aNAVLink[ 1,nQTaxpayer ] := ReadNode( XMLSettings, 'queryTaxpayer', vt_String );
				aNAVLink[ 1,nTokenExchange ] := ReadNode( XMLSettings, 'tokenExchange', vt_String );
			end;
		end;
		XMLGlobal := NIL;
		XMLItems := NIL;
		XMLItem := NIL;
		XMLSettings := NIL;
		XMLFile := NIL;
	end;
end;

procedure WriteXMLFile;
var
	XMLFile												: IXMLDocument;
	XMLGlobal,XMLItems,XMLItem,XMLSettings		: IXMLNode;
	cCryptPassword										: string;
	I														: integer;
begin
	SetMySettings;
	XMLFile := NewXMLDocument;
	XMLFile.Encoding := 'utf-8';
	XMLFile.Options := [doNodeAutoIndent];
	XMLFile.Active;
	XMLGlobal := XMLFile.AddChild( 'Main' );
// Program adatok
	XMLSettings := XMLGlobal.AddChild( 'Settings' );
	XMLSettings.AddChild( 'ReceivePath' ).Text := String( MainForm.AppSettings.cXMLReceivePath );
	XMLSettings.AddChild( 'SendPath' ).Text := String( MainForm.AppSettings.cXMLSendPath );
	XMLSettings.AddChild( 'LogPath' ).Text := String( MainForm.AppSettings.cXMLLogPath );
	XMLSettings.AddChild( 'NAVVersion' ).Text := GetNAVVersion( MainForm.AppSettings.NAVVersion );
	XMLSettings.AddChild( 'LogLevel' ).Text := IntToStr( MainForm.AppSettings.nLogLevel );
	XMLSettings.AddChild( 'BalloonTimeOut' ).Text := IntToStr( MainForm.AppSettings.nBalloonTimeout );
	XMLSettings.AddChild( 'WindowLeft' ).Text := IntToStr( MainForm.Left );
	XMLSettings.AddChild( 'WindowTop' ).Text := IntToStr( MainForm.Top );
	XMLSettings.AddChild( 'WindowWidth' ).Text := IntToStr( MainForm.Width );
	XMLSettings.AddChild( 'WindowHeight' ).Text := IntToStr( MainForm.Height );
//NAVASz adatok
	XMLSettings := XMLGlobal.AddChild( 'NAVASzSettings' );
	if MainForm.NAVASzSettings.lActive then begin
		XMLSettings.AddChild( 'Active' ).Text := '1';
	end else begin
		XMLSettings.AddChild( 'Active' ).Text := '0';
	end;
	XMLSettings.AddChild( 'DBFPath' ).Text := String( MainForm.NAVASzSettings.cDBFPath );
	XMLSettings.AddChild( 'EInvoicePath' ).Text := String( MainForm.NAVASzSettings.cEInvoicePath );
	XMLSettings.AddChild( 'GridInterval' ).Text := IntToStr( MainForm.NAVASzSettings.nGridInterval );
	XMLSettings.AddChild( 'DBFInterval' ).Text := IntToStr( MainForm.NAVASzSettings.nDBFInterval );
	XMLSettings.AddChild( 'XMLDelete' ).Text := IntToStr( MainForm.NAVASzSettings.nDeleteDay );
	if MainForm.NAVASzSettings.lDeleteProcessing then begin
		XMLSettings.AddChild( 'DeleteProcessing' ).Text := '1';
	end else begin
		XMLSettings.AddChild( 'DeleteProcessing' ).Text := '0';
	end;
//NAVRead adatok
	XMLSettings := XMLGlobal.AddChild( 'NAVReadSettings' );
	if MainForm.NAVReadSettings.Active then begin
		XMLSettings.AddChild( 'Active' ).Text := '1';
	end else begin
		XMLSettings.AddChild( 'Active' ).Text := '0';
	end;
	XMLSettings.AddChild( 'InvoicePath' ).Text := String( MainForm.NAVReadSettings.XMLInvoicePath );
	XMLSettings.AddChild( 'BackDays' ).Text := IntToStr( MainForm.NAVReadSettings.BackDays );
	XMLSettings.AddChild( 'LastRead' ).Text := FormatDateTime( 'YYYY-MM-DD hh:mm:ss', MainForm.NAVReadSettings.LastRead );
	XMLSettings.AddChild( 'ReadInterval' ).Text := IntToStr( MainForm.NAVReadSettings.ReadInterval );
	XMLItems := XMLSettings.AddChild( 'NAVReadItems' );
	for I := 0 to MainForm.NAVReadSettings.NAVReadItems.Count - 1 do begin
		XMLItem := XMLItems.AddChild( 'NAVReadItem' );
		XMLItem.AddChild( 'ALMIRAPath' ).Text := String( MainForm.NAVReadSettings.NAVReadItems.Items[ I ].AlmiraPath );
		XMLItem.AddChild( 'ALMIRASharePath' ).Text := String( MainForm.NAVReadSettings.NAVReadItems.Items[ I ].AlmiraSharePath );
		XMLItem.AddChild( 'StartDate' ).Text := FormatDateTime( 'YYYY-MM-DD', MainForm.NAVReadSettings.NAVReadItems.Items[ I ].StartDate );
	end;
// Árfolyam beolvasási adatok
	XMLSettings := XMLGlobal.AddChild( 'CurrencyReadSettings' );
	if MainForm.CurrencyReadSettings.Active then begin
		XMLSettings.AddChild( 'Active' ).Text := '1';
	end else begin
		XMLSettings.AddChild( 'Active' ).Text := '0';
	end;
	XMLSettings.AddChild( 'HTTPLink' ).Text := String( MainForm.CurrencyReadSettings.HTTPLink );
	XMLSettings.AddChild( 'DBFPath' ).Text := String( MainForm.CurrencyReadSettings.DBFPath );
	XMLSettings.AddChild( 'DBFFile' ).Text := String( MainForm.CurrencyReadSettings.DBFFile );
	XMLSettings.AddChild( 'LastRead' ).Text := FormatDateTime( 'YYYY-MM-DD hh:mm:ss', MainForm.CurrencyReadSettings.LastRead );
	XMLSettings.AddChild( 'ReadInterval' ).Text := IntToStr( MainForm.CurrencyReadSettings.ReadInterval );
	XMLItems := XMLSettings.AddChild( 'CurrencyItems' );
	for I := 0 to MainForm.CurrencyReadSettings.CurrencyReadItems.Count - 1 do begin
		XMLItem := XMLItems.AddChild( 'CurrencyItem' );
		XMLItem.AddChild( 'BankCode' ).Text := IntToStr( MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].BankCode );
		XMLItem.AddChild( 'BankName' ).Text := String( MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].BankName );
		XMLItem.AddChild( 'CurrencyCode' ).Text := String( MainForm.CurrencyReadSettings.CurrencyReadItems.Items[ I ].CurrencyCode );
	end;

// Szinkronizálási beállítások
	XMLSettings := XMLGlobal.AddChild( 'SyncSettings' );
	if MainForm.SyncSettings.Active then begin
		XMLSettings.AddChild( 'Active' ).Text := '1';
	end else begin
		XMLSettings.AddChild( 'Active' ).Text := '0';
	end;
	XMLSettings.AddChild( 'ReadInterval' ).Text := IntToStr( MainForm.SyncSettings.ReadInterval );
	XMLSettings.AddChild( 'LastRead' ).Text := FormatDateTime( 'YYYY-MM-DD hh:mm:ss', MainForm.SyncSettings.LastRead );
	XMLItems := XMLSettings.AddChild( 'SyncItems' );
	for I := 0 to MainForm.SyncSettings.SyncItems.Count - 1 do begin
		XMLItem := XMLItems.AddChild( 'SyncItem' );
		if MainForm.SyncSettings.SyncItems.Items[ I ].Active then begin
			XMLItem.AddChild( 'Active' ).Text := '1';
		end else begin
			XMLItem.AddChild( 'Active' ).Text := '0';
		end;
		XMLItem.AddChild( 'Name' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].Name );
		case MainForm.SyncSettings.SyncItems.Items[ I ].SessionType of
			st_UploadLinzer : XMLItem.AddChild( 'SessionType' ).Text := 'UploadPekseg';
			st_DownloadLinzer : XMLItem.AddChild( 'SessionType' ).Text := 'DownloadPekseg';
		end;
		case MainForm.SyncSettings.SyncItems.Items[ I ].SQLType of
			sqt_Firebird : XMLItem.AddChild( 'SQLType' ).Text := 'firebird';
			sqt_Mysql : XMLItem.AddChild( 'SQLType' ).Text := 'mysql';
		end;
		XMLItem.AddChild( 'SQLServer' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].SQLServer );
		XMLItem.AddChild( 'SQLPort' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].SQLPort );
		XMLItem.AddChild( 'SQLFile' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].SQLFileName );
		XMLItem.AddChild( 'SQLUser' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].SQLUser );
		cCryptPassword := EncodePWDEx( Trim( String( MainForm.SyncSettings.SyncItems.Items[ I ].SQLPassword )), '1234567890abcdefgh' );
		XMLItem.AddChild( 'SQLPassword' ).Text := cCryptPassword;
		XMLItem.AddChild( 'LocalYearPath' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].LocalYearDatabase );
		XMLItem.AddChild( 'LocalYearSharePath' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].LocalYearShareDatabase );
		XMLItem.AddChild( 'LocalSharePath' ).Text := String( MainForm.SyncSettings.SyncItems.Items[ I ].LocalShareDatabase );
		XMLItem.AddChild( 'ActYear' ).Text := IntToStr( MainForm.SyncSettings.SyncItems.Items[ I ].ActYear );
	end;
// Szoftver adatok
	XMLSettings := XMLGlobal.AddChild( 'Software' );
	XMLSettings.AddChild( 'SoftwareId' ).Text := String( NAV.SoftwareData.ID );
	XMLSettings.AddChild( 'SoftwareName' ).Text := String( NAV.SoftwareData.Name );
	XMLSettings.AddChild( 'SoftwareOperation' ).Text := String( NAV.SoftwareData.Operation );
	XMLSettings.AddChild( 'SoftwareMainVersion' ).Text := String( NAV.SoftwareData.MainVersion );
	XMLSettings.AddChild( 'SoftwareDevName' ).Text := String( NAV.SoftwareData.DevName );
	XMLSettings.AddChild( 'SoftwareDevContact' ).Text := String( NAV.SoftwareData.DevContact );
	XMLSettings.AddChild( 'SoftwareDevCountryCode' ).Text := String( NAV.SoftwareData.DevCountryCode );
	XMLSettings.AddChild( 'SoftwareDevTaxNumber' ).Text := String( NAV.SoftwareData.DevTaxNumber );
// Email adatok
	cCryptPassword := EncodePWDEx( Trim( String( MainForm.EMailSettings.MailPassword )), '1234567890abcdefgh' );
	XMLSettings := XMLGlobal.AddChild( 'Email' );
	if MainForm.EMailSettings.MailSending then begin
		XMLSettings.AddChild( 'EmailErrorSending' ).Text := '1';
	end else begin
		XMLSettings.AddChild( 'EmailErrorSending' ).Text := '0';
	end;
	XMLSettings.AddChild( 'SMTPServer' ).Text := String( MainForm.EMailSettings.MailSMTP );
	XMLSettings.AddChild( 'SMTPPort' ).Text := String( MainForm.EMailSettings.MailPort );
	XMLSettings.AddChild( 'SMTPUser' ).Text := String( MainForm.EMailSettings.MailUserName );
	XMLSettings.AddChild( 'SMTPPassword' ).Text := cCryptPassword;
	XMLSettings.AddChild( 'SenderName' ).Text := String( MainForm.EMailSettings.MailSender );
	XMLItems := XMLSettings.AddChild( 'EmailAddresses' );
	for I := 0 to MainForm.EMailSettings.EMailItems.Count - 1 do begin
		XMLItem := XMLItems.AddChild( 'EmailAddress' );
		if ( MainForm.EMailSettings.EMailItems.Items[ I ].Active ) then begin
			XMLItem.AddChild( 'Active' ).Text := '1';
		end else begin
			XMLItem.AddChild( 'Active' ).Text := '0';
		end;
		XMLItem.AddChild( 'Name' ).Text := String( MainForm.EMailSettings.EMailItems.Items[ I ].EMailName );
		XMLItem.AddChild( 'Address' ).Text := String( MainForm.EMailSettings.EMailItems.Items[ I ].EMailAddress );
	end;
// User adatok
	XMLSettings := XMLGlobal.AddChild( 'User' );
	XMLSettings.AddChild( 'Company' ).Text := String( MainForm.NAVASzSettings.cUserCompany );
	XMLSettings.AddChild( 'Site' ).Text := String( MainForm.NAVASzSettings.cUserSites );
	XMLSettings.AddChild( 'Machine' ).Text := String( MainForm.NAVASzSettings.cUserCompany );
	XMLSettings.AddChild( 'User' ).Text := String( MainForm.NAVASzSettings.cUserName );
// NAV linkek
	XMLSettings := XMLGlobal.AddChild( 'NAVLinks' );
	XMLSettings.AddChild( 'manageAnnulment' ).Text := String( aNAVLink[ 0,nMAnnulment ]);
	XMLSettings.AddChild( 'manageInvoice' ).Text := String( aNAVLink[ 0,nMInvoice ]);
	XMLSettings.AddChild( 'queryInvoiceChainDigest' ).Text := String( aNAVLink[ 0,nQInvoiceChainDigest ]);
	XMLSettings.AddChild( 'queryInvoiceCheck' ).Text := String( aNAVLink[ 0,nQInvoiceCheck ]);
	XMLSettings.AddChild( 'queryInvoiceData' ).Text := String( aNAVLink[ 0,nQInvoiceData ]);
	XMLSettings.AddChild( 'queryInvoiceDigest' ).Text := String( aNAVLink[ 0,nQInvoiceDigest ]);
	XMLSettings.AddChild( 'queryTransactionList' ).Text := String( aNAVLink[ 0,nQTransactionList ]);
	XMLSettings.AddChild( 'queryTransactionStatus' ).Text := String( aNAVLink[ 0,nQTransactionStatus ]);
	XMLSettings.AddChild( 'queryTaxpayer' ).Text := String( aNAVLink[ 0,nQTaxpayer ]);
	XMLSettings.AddChild( 'tokenExchange' ).Text := String( aNAVLink[ 0,nTokenExchange ]);
	XMLSettings := XMLGlobal.AddChild( 'NAVLinksTest' );
	XMLSettings.AddChild( 'manageAnnulment' ).Text := String( aNAVLink[ 1,nMAnnulment ]);
	XMLSettings.AddChild( 'manageInvoice' ).Text := String( aNAVLink[ 1,nMInvoice ]);
	XMLSettings.AddChild( 'queryInvoiceChainDigest' ).Text := String( aNAVLink[ 1,nQInvoiceChainDigest ]);
	XMLSettings.AddChild( 'queryInvoiceCheck' ).Text := String( aNAVLink[ 1,nQInvoiceCheck ]);
	XMLSettings.AddChild( 'queryInvoiceData' ).Text := String( aNAVLink[ 1,nQInvoiceData ]);
	XMLSettings.AddChild( 'queryInvoiceDigest' ).Text := String( aNAVLink[ 1,nQInvoiceDigest ]);
	XMLSettings.AddChild( 'queryTransactionList' ).Text := String( aNAVLink[ 1,nQTransactionList ]);
	XMLSettings.AddChild( 'queryTransactionStatus' ).Text := String( aNAVLink[ 1,nQTransactionStatus ]);
	XMLSettings.AddChild( 'queryTaxpayer' ).Text := String( aNAVLink[ 1,nQTaxpayer ]);
	XMLSettings.AddChild( 'tokenExchange' ).Text := String( aNAVLink[ 1,nTokenExchange ]);
	if Trim( String( MainForm.NAVASzSettings.cDBFPath )) <> '' then begin
		XMLFile.SaveToFile( MainForm.cAppPath + '\almiranav.xml' );
	end;
	XMLGlobal := NIL;
	XMLItems := NIL;
	XMLItem := NIL;
	XMLSettings := NIL;
	XMLFile := NIL;
end;


procedure WriteLogFile( cMessage : string; nLevel : integer );
var
	nLogFile 								: TextFile;
	cLogFileName							: string;
begin
	if nLevel <= MainForm.AppSettings.nLogLevel then begin
		if ( not DirectoryExists( 'Log' )) then begin
			CreateDir( 'Log' );
		end;
		cLogFileName := 'Log\' + FormatDateTime( 'yymmdd',Now()) + '.log';
		AssignFile( nLogFile, cLogFileName );
		if FileExists( cLogFileName ) then begin
			Append( nLogFile );
		end else begin
			Rewrite( nLogFile );
		end;
		WriteLn( nLogFile, FormatDateTime( 'YYYY.MM.DD hh:nn:ss', Now()) +
			' - ' + cMessage );
		CloseFile( nLogFile );
	end;
end;

function MakeUniqueFileName( InTaxNumber : string; InDate : TDateTime ) : string;
var
	nSeged1,nSeged2									: integer;
	cResult												: string[ 8 ];
begin
	SetMySettings;
	cResult := '';
	nSeged1 := StrToInt( InTaxNumber );
	nSeged2 := StrToInt( FormatDateTime( 'MMDDhhnnss', InDate, NAV.MySettings ));
	cResult := IntToHex( nSeged1 + nSeged2,8 );
	Result := cResult;
end;

procedure XMLInsertSchemas( InNode : IXMLNode );
var
	I											: integer;
begin
	for I := 0 to 1 do begin
		InNode.Attributes[ acNAVSchema[ I,0 ]] := acNAVSchema[ I,1 ];
	end;
end;

function ShellExecuteAndWait( FileName: string; Params: string ) : boolean;
var
	exInfo										: TShellExecuteInfo;
	Ph												: DWORD;
begin
	WriteLogFile( 'DOS parancs futtatása : ' + FileName + ' (' + Params + ')',2 );
	FillChar( exInfo, SizeOf( exInfo ), 0 );
	exInfo.cbSize := SizeOf( exInfo );
	exInfo.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_DDEWAIT;
	exInfo.Wnd := GetActiveWindow();
	exInfo.lpVerb := 'open';
	exInfo.lpParameters := PChar( Params );
	exInfo.lpFile := PChar( FileName );
	exInfo.nShow := SW_SHOWNORMAL;
	if ShellExecuteEx (@exInfo ) then begin
		Ph := exInfo.hProcess
	end else begin
		WriteLogFile( 'DOS parancs futtatása hibás : ' + IntToStr( GetLastError ),2 );
		Result := TRUE;
		Exit;
	end;
		while WaitForSingleObject( exInfo.hProcess, 50 ) <> WAIT_OBJECT_0 do begin
		Application.ProcessMessages;
	end;
	CloseHandle( Ph );
	Result := TRUE;
end;

end.


