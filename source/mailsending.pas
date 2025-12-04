unit MailSending;

interface

uses Forms, SysUtils, Windows, invoice, IdAttachmentFile, System.Classes;

type
	TEMailSettings = class;

	TEmailItem = class( TCollectionItem )
	private
		FActive : boolean;
		FEMailName : AnsiString;
		FEMailAddress : AnsiString;
	public
		constructor Create( Collection: TCollection ); override;
		procedure Assign(Source: TPersistent); override;
	published
		property Active : boolean read FActive write FActive;
		property EMailName : AnsiString read FEMailName write FEMailName;
		property EMailAddress : AnsiString read FEMailAddress write FEMailAddress;
	end;

	TEMailItems = class( TCollection )
	private
		FEMailSettings : TEMailSettings;
		function GetItem( Index : integer ) : TEMailItem;
		procedure SetItem( Index : integer; const Value : TEMailItem );
	protected
	public
		constructor Create( AOwner : TEMailSettings );
		function Add : TEMailItem;
		function Insert( Index : integer ) : TEMailItem;
		property Items[ Index : integer ] : TEMailItem read GetItem write SetItem; default;
	end;

	TEMailSettings = class( TPersistent )
	private
		FMailSending : boolean;
		FMailSMTP : string;
		FMailPort : string;
		FMailUserName : string;
		FMailPassword : string;
		FMailSender : string;
		FEMailItems : TEMailItems;
	public
		constructor Create;
		destructor Destroy; override;
	published
		property EMailItems : TEMailItems read FEMailItems write FEmailItems;
		property MailSending : boolean read FMailSending write FMailSending;
		property MailSMTP : string read FMailSMTP write FMailSMTP;
		property MailPort : string read FMailPort write FMailPort;
		property MailUserName : string read FMailUserName write FMailUserName;
		property MailPassword : string read FMailPassword write FMailPassword;
		property MailSender : string read FMailSender write FMailSender;
	end;

procedure SendErrorMail( InInvoice : TInvoice; InXMLFile : string );

implementation

uses Main, XMLHandler, Dialogs, crypt;

// EMailItem
constructor TEMailItem.Create(Collection: TCollection);
begin
	inherited;
	FActive := FALSE;
	FEMailName := '';
	FEMailAddress := '';
end;

procedure TEMailItem.Assign(Source: TPersistent);
begin
	if ( Source is TEMailItem ) then begin
		FActive := TEMailItem( Source ).FActive;
		FEMailName := TEMailItem( Source ).FEMailName;
		FEMailAddress := TEMailItem( Source ).EMailAddress;
	end else begin
		inherited Assign( Source );
	end;
end;

// TEMailItems
constructor TEMailItems.Create(AOwner: TEMailSettings);
begin
	inherited Create( TEMailItem );
	FEMailSettings := AOwner;
end;

function TEMailItems.GetItem( Index: integer) : TEMailItem;
begin
  Result := TEMailItem( inherited Items[ Index ]);
end;

function TEMailItems.Insert(Index: integer) : TEMailItem;
begin
  Result := TEMailItem( inherited Insert( Index ));
end;

procedure TEMailItems.SetItem( Index : integer; const Value : TEMailItem);
begin
  inherited Items[ Index ] := Value;
end;

function TEMailItems.Add : TEMailItem;
begin
	Result := TEMailItem( inherited Add );
	Result.Active := FALSE;
	Result.EMailName := '';
	Result.EMailAddress := '';
end;

// TEMailSettings
constructor TEMailSettings.Create;
begin
	inherited;
	FMailSending := TRUE;
	FMailSMTP := 'smtp.gmail.com';
	FMailPort := '587';
	FMailUserName := 'kalocomp';
	FMailPassword := 'almira2008';
	FMailSender := 'kalocomp@gmail.com';
	FEMailItems := TEMailItems.Create(  Self );
end;

destructor TEMailSettings.Destroy;
begin
	FEMailItems.Destroy;
	inherited;
end;

procedure SendErrorMail( InInvoice : TInvoice; InXMLFile : string );
var
	I													: integer;
	cAttachFile,cRequestID						: string;
	MailAttachment 								: TIdAttachmentFile;
	FileSearch										: TSearchRec;
begin
	if (( MainForm.EMailSettings.MailSending ) and ( InInvoice.SendMail = 0 )) then begin
		WriteLogFile( 'Email küldése a hibáról indul...',3 );
		MainForm.NAVSMTP.Host := String( MainForm.EMailSettings.MailSMTP );
		WriteLogFile( 'SMTP szerver - ' + String( MainForm.EMailSettings.MailSMTP ),3 );
		MainForm.NAVSMTP.Username := String( MainForm.EMailSettings.MailUserName );
		WriteLogFile( 'Felhasználónév - ' + String( MainForm.EMailSettings.MailUserName ),3 );
		MainForm.NAVSMTP.Password := String( MainForm.EMailSettings.MailPassword );
		MainForm.NAVSMTP.Port := StrToInt( String( MainForm.EMailSettings.MailPort ));
		WriteLogFile( 'SMTP szerver port - ' + String( MainForm.EMailSettings.MailPort ),3 );

		MainForm.SSLHandler.Destination := Trim( String( MainForm.EMailSettings.MailSMTP )) + ':' + Trim( String( MainForm.EMailSettings.MailPort ));
		MainForm.SSLHandler.Host := String( MainForm.EMailSettings.MailSMTP );
		MainForm.SSLHandler.Port := StrToInt( String( MainForm.EMailSettings.MailPort ));

		MainForm.NAVUserPassProvider.Username := String( MainForm.EMailSettings.MailUserName );
		MainForm.NAVUserPassProvider.Password := String( MainForm.EMailSettings.MailPassword );
		if MainForm.NAVSMTP.Connected then begin
			MainForm.NAVSMTP.Disconnect;
		end;
		try
			MainForm.NAVSMTP.Connect;
			WriteLogFile( 'SMTP szerverhez csatlakozva',4 );
			MainForm.NAVSMTP.Authenticate;
			WriteLogFile( 'A felhasználó az SMTP szerveren azonosítva',4 );
		except
			on E:Exception do begin
				Exit;
			end;
		end;
// Üzenet összeállítása
		MainForm.NAVMessage.ContentType := 'multipart/mixed';
		MainForm.NAVMessage.ContentTransferEncoding := '8bit';
		MainForm.NAVMessage.CharSet := 'UTF-8';
		MainForm.NAVMessage.Subject := 'NAVAsz - program hiba jelentés';
		MainForm.NAVMessage.ClearBody;
// Címzettek beállításai
		MainForm.NAVMessage.MessageParts.Clear;
		MainForm.NAVMessage.ReceiptRecipient.Address := String( MainForm.EMailSettings.EMailItems.Items[ 0 ].EMailAddress );
		MainForm.NAVMessage.ReceiptRecipient.Name := String( MainForm.EMailSettings.EMailItems.Items[ 0 ].EMailName );

		MainForm.NAVMessage.Recipients.Clear;
		for I := 0 to MainForm.EMailSettings.EMailItems.Count - 1  do begin
			if ( MainForm.EMailSettings.EMailItems[ I ].Active ) then begin
				WriteLogFile( 'Címzett mail címe - ' + String( MainForm.EMailSettings.EMailItems.Items[ I ].EMailAddress ),3 );
				WriteLogFile( 'Címzett neve - ' + String( MainForm.EMailSettings.EMailItems.Items[ 0 ].EMailName ),3 );
				MainForm.NAVMessage.Recipients.Add;
				MainForm.NAVMessage.Recipients.Items[ MainForm.NAVMessage.Recipients.Count - 1 ].Address := String( MainForm.EMailSettings.EMailItems.Items[ I ].EMailAddress );
				MainForm.NAVMessage.Recipients.Items[ MainForm.NAVMessage.Recipients.Count - 1 ].Name := String( MainForm.EMailSettings.EMailItems.Items[ I ].EMailName );
			end;
		end;

// Feladó beállítása
		MainForm.NAVMessage.Sender.Address := String( MainForm.EMailSettings.MailSender );
		MainForm.NAVMessage.From.Address := String( MainForm.EMailSettings.MailSender );
		WriteLogFile( 'Feladó mail címe - ' + String( MainForm.EMailSettings.MailSender ),3 );
		MainForm.NAVMessage.Sender.Name := 'NAVASz - program';
		MainForm.NAVMessage.From.Name := 'NAVASz - program';
		MainForm.NAVMessage.FromList.Clear;
		MainForm.NAVMessage.FromList.Add;
		MainForm.NAVMessage.FromList.Items[ 0 ].Address := String( MainForm.EMailSettings.MailSender );
		MainForm.NAVMessage.FromList.Items[ 0 ].Name := 'NAVASz - program';
// Az üzenet szövege
		MainForm.NAVMessage.ClearBody;
		MainForm.NAVMessage.Body.Add( 'A NAVASz.exe mûködésekor hiba lépett fel.' );
		MainForm.NAVMessage.Body.Add( 'A hiba helye :' );
		MainForm.NAVMessage.Body.Add( '    Cég neve : ' + String( MainForm.NAVASzSettings.cUserCompany ));
		MainForm.NAVMessage.Body.Add( '    Cég telephelye : ' + String( MainForm.NAVASzSettings.cUserSites ));
		MainForm.NAVMessage.Body.Add( '    A programot futtató számítógép : ' + String( MainForm.NAVASzSettings.cUserMachine ));
		MainForm.NAVMessage.Body.Add( '    A felhasználó neve : ' + String( MainForm.NAVASzSettings.cUserName ));
		MainForm.NAVMessage.Body.Add( '' );
		if InInvoice.TestMode = tm_Test then begin
			MainForm.NAVMessage.Body.Add( 'A hibás számla (TESZT üzemmód):' );
		end else begin
			MainForm.NAVMessage.Body.Add( 'A hibás számla:' );
		end;
		MainForm.NAVMessage.Body.Add( '    A számla kibocsátója : ' + String( InInvoice.Supplier.Name ));
		MainForm.NAVMessage.Body.Add( '    A számla száma : ' + String( InInvoice.InvoiceNumber ));
		MainForm.NAVMessage.Body.Add( '    A számla rekodja (NAV.DBF) : ' + IntToStr( InInvoice.RecordNumber ));
		MainForm.NAVMessage.Body.Add( '    A számla státusza : ' + String( InInvoice.InvStatusNum ));
		MainForm.NAVMessage.Body.Add( '                        ' + String( InInvoice.InvStatusText ));
		MainForm.NAVMessage.Body.Add( '    A hibaüzenet : ' + String( InInvoice.ErrorText ));
// Mellékletek
		cRequestID := Trim( String( InInvoice.Supplier.TaxPayerID )) + LeftPad( InInvoice.RecordNumber,4,'0' );
		if ( Length( Trim( InXMLFile )) <> 0 ) and ( FileExists( String( MainForm.AppSettings.cReceivePath ) + '\' + InXMLFile )) then begin
			cAttachFile := String( MainForm.AppSettings.cReceivePath ) + '\' + InXMLFile;
			MailAttachment := TIdAttachmentFile.Create( MainForm.NAVMessage.MessageParts, cAttachFile );
		end;
// NAV.DBF-et is küldjük
		cAttachFile := ExtractFileName( String( MainForm.NAVASzSettings.cDBFPath )) + 'mail.dbf';
		if FileExists( cAttachFile ) then begin
			DeleteFile( PWideChar( cAttachFile ));
		end;
		CopyFile( PChar( String( MainForm.NAVASzSettings.cDBFPath )), PChar( String( cAttachFile )), FALSE );
		MailAttachment := TIdAttachmentFile.Create( MainForm.NAVMessage.MessageParts, cAttachFile );
// Aktuális LOG-filet is küldjük
		cAttachFile := ExtractFileName( MainForm.cLogFile ) + 'mail.log';
		if FileExists( cAttachFile ) then begin
			DeleteFile( PWideChar( cAttachFile ));
		end;
		CopyFile( PWideChar( MainForm.cLogFile ), PWideChar( cAttachFile ), FALSE );
		MailAttachment := TIdAttachmentFile.Create( MainForm.NAVMessage.MessageParts, cAttachFile );
// Megkeressük az összes ilyen számlához kapcsolódó XML-t
		if FindFirst( String( MainForm.AppSettings.cSendPath ) + '\?' + cRequestID + '*.xml', faAnyFile, FileSearch ) = 0 then begin
			repeat
				cAttachFile := String( MainForm.AppSettings.cSendPath ) + '\' + FileSearch.Name;
				MailAttachment := TIdAttachmentFile.Create( MainForm.NAVMessage.MessageParts, cAttachFile );
			until FindNext( FileSearch ) <> 0;
		end;
		if FindFirst( String( MainForm.AppSettings.cReceivePath ) + '\?' + cRequestID + '*.xml', faAnyFile, FileSearch ) = 0 then begin
			repeat
				cAttachFile := String( MainForm.AppSettings.cReceivePath ) + '\' + FileSearch.Name;
				MailAttachment := TIdAttachmentFile.Create( MainForm.NAVMessage.MessageParts, cAttachFile );
			until FindNext( FileSearch ) <> 0;
		end;
		try
			WriteLogFile( 'Az E-Mail üzenet küldése',4 );
			MainForm.NAVSMTP.Send( MainForm.NAVMessage );
			WriteLogFile( 'Az E-Mail üzenet sikeresen elküldve',1 );
			InInvoice.SendMail := InInvoice.SendMail + 1;
			except on
				E:Exception do begin
//					MessageDlg( 'Error : ' + E.Message, mtWarning, [ mbOK ], 0);
					WriteLogFile( 'Hiba a küldés során - ' + E.Message,1 );
			end;
		end;
		Application.ProcessMessages;
	end;
end;

end.
