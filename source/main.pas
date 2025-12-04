unit main;

interface

uses
	NAV, currencyread, MailSending, AdvUtil, IdComponent, FireDAC.Stan.Intf,
	ApoDSet, apoEnv,
	Vcl.ExtCtrls, Data.DB, AdvPanel, Vcl.Menus, AdvMenus,
	frxClass, frxExportBaseDialog,
	frxExportPDF, frxDBSet, AdvMenuStylers, IdHTTP, IdIOHandler,
	IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdTime,
	IdMessage, IdSASL, IdSASLUserPass, IdSASLLogin, IdUserPassProvider,
	IdBaseComponent, IdTCPConnection, IdTCPClient,
	IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP,
	Vcl.Grids, AdvObj, BaseGrid, AdvGrid, Vcl.StdCtrls, Vcl.Mask, AdvEdit,
	AdvGlowButton, Vcl.Imaging.pngimage, Vcl.Controls, AdvProgressBar,
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Forms, Vcl.Dialogs, DBAdvGrid, Data.Win.ADODB, DateUtils, Datasnap.DBClient, XMLDoc, XMLIntf,
	AdvAppStyler, AdvStyleIf, navreadsetting, invoice, syncsetting,
	IBX.IBCustomDataSet, IBX.IBQuery, IBX.IBDatabase, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.UI.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.VCLUI.Wait, FireDAC.DApt;

type
	TMainForm = class(TForm)
		MainPanel: TAdvPanel;
		ExitButton: TAdvGlowButton;
		SettingsButton: TAdvGlowButton;
		SendButton: TAdvGlowButton;
		AdoszamPanel: TAdvPanel;
		CheckButton: TAdvGlowButton;
		AdoszamEdit: TAdvMaskEdit;
		LogFileButton: TAdvGlowButton;
		BadImage: TImage;
		GoodImage: TImage;
		QueryButton: TAdvGlowButton;
		ReadProgressBar: TAdvProgressBar;
		NAVSMTP: TIdSMTP;
		NAVUserPassProvider: TIdUserPassProvider;
		NAVSASLLogin: TIdSASLLogin;
		NAVMessage: TIdMessage;
		NAVTime: TIdTime;
		SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
		MainHTTP: TIdHTTP;
		MainMenuStyler: TAdvMenuOfficeStyler;
//    InvLineDataSet: TfrxDBDataset;
		InvVATDataSet: TfrxDBDataset;
		InvoiceReport: TfrxReport;
		PDFInvoice: TfrxPDFExport;
		InvVATTable: TFDMemTable;
		InvVATTableVATPERCENTAGE: TFloatField;
		InvVATTableVATNAME: TStringField;
		InvVATTableVATNETAMOUNT: TFloatField;
		InvVATTableVATNETAMOUNTHUF: TFloatField;
		InvVATTableVATVATAMOUNT: TFloatField;
		InvVATTableVATVATAMOUNTHUF: TFloatField;
		InvVATTableVATGROSSAMOUNT: TFloatField;
		InvVATTableVATGROSSAMOUNTHUF: TFloatField;
		InvLineTable: TFDMemTable;
		InvLineTableLINENUMBER: TIntegerField;
		InvLineTablePRODUCTNAME: TStringField;
		InvLineTablePRODUCTCODECATEGORY: TStringField;
		InvLineTablePRODUCTCODEVALUE: TStringField;
		InvLineTableQUANTITY: TFloatField;
		InvLineTableUNIT: TStringField;
		InvLineTableUNITPRICE: TFloatField;
		InvLineTableNETAMOUNT: TFloatField;
		InvLineTableNETAMOUNTH: TFloatField;
		InvLineTableVATAMOUNT: TFloatField;
		InvLineTableVATAMOUNTHUF: TFloatField;
		InvLineTableGROSSAMOUNT: TFloatField;
		InvLineTableGROSSAMOUNTH: TFloatField;
		InvLineTableVATPERCENT: TFloatField;
		MainMenu: TAdvPopupMenu;
		Menu01: TMenuItem;
		Menu02: TMenuItem;
		N2: TMenuItem;
		Menu03: TMenuItem;
		Menu04: TMenuItem;
		Menu09: TMenuItem;
		N1: TMenuItem;
		Menu10: TMenuItem;
		MainPanelStyler: TAdvPanelStyler;
		InvLineSource: TDataSource;
		SzamlaQ: TDataSource;
		TrayIcon: TTrayIcon;
		MainTimer: TTimer;
		CegekTable: TFDMemTable;
		CegekTablekod: TStringField;
		CegekTablenev: TStringField;
		CegekTableadoszam: TStringField;
		CegekTablelogin: TStringField;
		CegekTablepassword: TStringField;
		CegekTablesignkey: TStringField;
		CegekTablechangekey: TStringField;
		CegekTablelogintest: TStringField;
		CegekTablepasswordtest: TStringField;
		CegekTablesignkeytest: TStringField;
		CegekTablechangekeytest: TStringField;
		CegekTablenavread: TStringField;
		CegekTablenavreaditem: TIntegerField;
		N3: TMenuItem;
		InvLineTableVATCODE: TIntegerField;
		InvLineTableNAVVATCODE: TStringField;
		InvLineTablePRODUCTCODE: TStringField;
		InvLineTableTAXID: TStringField;
		InvLineTableINVOICENUMBER: TStringField;
		Menu05: TMenuItem;
		Menu06: TMenuItem;
		N4: TMenuItem;
		N5: TMenuItem;
		Menu07: TMenuItem;
		Menu08: TMenuItem;
		InvoiceGrid: TAdvStringGrid;
		DBFTable1: TApolloTable;
		AlmiraEnv: TApolloEnv;
		InvLineData: TfrxDBDataset;
		SyncFBDatabase: TIBDatabase;
		SyncFBTransaction: TIBTransaction;
		SyncFBQuery: TIBQuery;
		DBFTable2: TApolloTable;
		DBFTable3: TApolloTable;
		DBFTable4: TApolloTable;
		DBFTable5: TApolloTable;
		SyncMySQLConnection: TFDConnection;
		SyncMySQLQuery: TFDQuery;
		SyncMySQLTransaction: TFDTransaction;
		SyncFBCommand: TIBQuery;
		SyncMySQLCommand: TFDQuery;
		procedure FormCreate(Sender: TObject);
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure CheckButtonClick(Sender: TObject);
		procedure LogFileButtonClick(Sender: TObject);
		procedure ExitButtonClick(Sender: TObject);
		procedure AdoszamEditChange(Sender: TObject);
		procedure SettingsButtonClick(Sender: TObject);
		procedure SendButtonClick(Sender: TObject);
		procedure QueryButtonClick(Sender: TObject);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
		procedure FormShow(Sender: TObject);
		procedure InvoiceGridGetAlignment(Sender: TObject; ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
		procedure InvoiceGridGetCellColor(Sender: TObject; ARow, ACol: Integer; AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
		procedure InvoiceGridCustomCellDraw(Sender: TObject; Canvas: TCanvas; ACol, ARow: Integer; AState: TGridDrawState; ARect: TRect; Printing: Boolean);
		procedure MainTimerTimer(Sender: TObject);
		procedure NAVSMTPStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
		procedure MainHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
		procedure MainHTTPStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
		procedure SSLHandlerStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
		procedure SSLHandlerStatusInfo(const AMsg: string);
		procedure NAVSMTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
		procedure TrayIconMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure TrayIconDblClick(Sender: TObject);
		procedure Menu01Click(Sender: TObject);
		procedure Menu02Click(Sender: TObject);
		procedure Menu03Click(Sender: TObject);
		procedure Menu04Click(Sender: TObject);
		procedure Menu09Click(Sender: TObject);
		procedure Menu10Click(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure Menu05Click(Sender: TObject);
		procedure Menu06Click(Sender: TObject);
		procedure FormResize(Sender: TObject);
		procedure Menu07Click(Sender: TObject);
		procedure Menu08Click(Sender: TObject);
	private
{ Private declarations }
		nShowBalloonTime : TDateTime;
		procedure OnMinimize( Sender:TObject );
		procedure WMGetMinMaxInfo(var MSG: Tmessage); message WM_GetMinMaxInfo;
	public
{ Public declarations }
		AppSettings : TAppSettings;
		NAVReadSettings : TNAVReadSettings;
		NAVASzSettings : TNAVASzSettings;
		CurrencyReadSettings : TCurrencyReadSettings;
		SyncSettings : TSyncSettings;
		EMailSettings : TEMailSettings;
		InvoiceList : TInvoiceList;
		lQuery : boolean;
		lDBFWorking : boolean;
		lReadCurrency : boolean;
		lSyncData : boolean;
		lChangedDBF : boolean;
		lRefreshGrid : boolean;
		dLastDelete : TDateTime;
		nLastGridTime : TDateTime;
		nLastDBCheck : TDateTime;
		cSoftID : string;
		cSoftName : string;
		lShowBalloon : boolean;
		cAppPath : string;
		cLogFile : string;
		cPar01 : string;
		cPar02 : string;
		procedure ApplicationClose;
		procedure MyShowBalloonHint( InTitle, InMessage : string; InBalloonFlag : TBalloonFlags );
		procedure RefreshInvoiceGrid;
		procedure GetInvoiceStatus( InInvoice : TInvoice );
		procedure SendInvoice( InInvoice : TInvoice );
		procedure CheckInvoiceDatabase;
		procedure QueryInvoiceData;
	end;

var
	MainForm: TMainForm;

implementation

{$R *.dfm}

uses XMLHandler, ShellAPI, NAVTokenExchange, NAVQueryTaxpayer,
	NAVManageInvoice, DCPrijndael, DCPBase64, Settings, NAVQueryInvoiceStatus,
	NAVQueryInvoiceData, TaxPayer, Delete, NAVRead, reading, System.UITypes,
	sync, Math;

procedure TMainForm.OnMinimize( Sender:TObject );
begin
	Hide;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
	nRecNo								: integer;
	EmailAddress						: PEmailAddress;

function SetDirPath( InDirPath : AnsiString ) : AnsiString;
begin
	Result := InDirPath;
	if ( ExtractFileDrive( InDirPath ) = '' ) then begin
		Result := cAppPath + '\' + InDirPath;
	end;
end;

begin
	lRefreshGrid := FALSE;
	lDBFWorking := FALSE;
	lSyncData := FALSE;
	lReadCurrency := FALSE;
	lChangedDBF := TRUE;
	lQuery := FALSE;
	CurrencyReadSettings := TCurrencyReadSettings.Create;
	SyncSettings := TSyncSettings.Create;
	EMailSettings := TEMailSettings.Create;
	NAVReadSettings := TNAVReadSettings.Create;
	cAppPath := ExtractFileDir( ParamStr( 0 ));
	cPar01 := ParamStr( 1 );
	cPar02 := ParamStr( 2 );
	AppSettings.cReceivePath := 'receivexml';
	AppSettings.cSendPath := 'sendxml';
	AppSettings.cLogPath := 'log';
	AppSettings.nBalloonTimeOut := 3000;
	AppSettings.NAVVersion := rv_30;
	AppSettings.nLogLevel := 3;
	AppSettings.WindowPos.X := 10;
	AppSettings.WindowPos.Y := 10;
	AppSettings.WindowWidth := 1000;
	AppSettings.WindowHeight := 500;
	MainForm.NAVASzSettings.lActive := TRUE;
	MainForm.NAVASzSettings.nGridInterval := 3000;
	MainForm.NAVASzSettings.nDBFInterval := 3000;
	MainForm.NAVASzSettings.nDeleteDay := 30;
	MainForm.NAVASzSettings.lDeleteProcessing := TRUE;
	NAV.SoftwareData.Name := 'ALMIRA';
	NAV.SoftwareData.Operation := 'LOCAL_SOFTWARE';
	NAV.SoftwareData.MainVersion := '1.1';
	NAV.SoftwareData.DevName := 'KalocompKft.';
	NAV.SoftwareData.DevContact := 'kalocomp@kalocomp.hu';
	NAV.SoftwareData.DevCountryCode := 'HU';
	NAV.SoftwareData.DevTaxNumber := '11036423-2-03';
	NAV.SoftwareData.ID := 'HU11036423ALMIRA10';
	WriteLogFile( 'XML file beolvasása',4 );
	XMLHandler.ReadXMLFile;
	Self.Left := AppSettings.WindowPos.X;
	Self.Top := AppSettings.WindowPos.Y;
	Self.Width := AppSettings.WindowWidth;
	Self.Height := AppSettings.WindowHeight;
	MainForm.cLogFile := System.SysUtils.IncludeTrailingPathDelimiter( MainForm.AppSettings.cLogPath ) + FormatDateTime( 'yymmdd',Now ) + '.log';
	WriteLogFile( 'Program indítása',4 );
	MainForm.AppSettings.cLogPath := SetDirPath( MainForm.AppSettings.cXMLLogPath );
// Könyvtárak ellenőrzése (ha szükséges akkor megnyitása is)
	if ( not DirectoryExists( MainForm.AppSettings.cLogPath )) then begin
		WriteLogFile( 'Nem létező könyvtár (' + MainForm.AppSettings.cLogPath + ')',0 );
		CreateDir( MainForm.AppSettings.cLogPath );
	end else begin
		WriteLogFile( 'Könyvtár ellenőrizve (log) ' + MainForm.AppSettings.cLogPath,0 );
	end;
	MainForm.AppSettings.cReceivePath := SetDirPath( MainForm.AppSettings.cXMLReceivePath );
	if ( not DirectoryExists( MainForm.AppSettings.cReceivePath )) then begin
		WriteLogFile( 'Nem létező könyvtár (receivexml) ' + MainForm.AppSettings.cReceivePath,0 );
		CreateDir( MainForm.AppSettings.cReceivePath );
	end else begin
		WriteLogFile( 'Könyvtár ellenőrizve (receivexml) ' + MainForm.AppSettings.cReceivePath,0 );
	end;
	MainForm.AppSettings.cSendPath := SetDirPath( MainForm.AppSettings.cXMLSendPath );
	if ( not DirectoryExists( MainForm.AppSettings.cSendPath )) then begin
		WriteLogFile( 'Nem létező Könyvtár (sendxml) ' + MainForm.AppSettings.cSendPath,0 );
		CreateDir( MainForm.AppSettings.cSendPath );
	end else begin
		WriteLogFile( 'Könyvtár ellenőrizve (sendxml) ' + MainForm.AppSettings.cSendPath,0 );
	end;
	MainForm.NAVReadSettings.InvoicePath := SetDirPath( MainForm.NAVReadSettings.XMLInvoicePath );
	if ( not DirectoryExists( MainForm.NAVReadSettings.InvoicePath )) then begin
		WriteLogFile( 'Nem létező könyvtár (invoice) ' + MainForm.NAVReadSettings.InvoicePath,0 );
		CreateDir( MainForm.NAVReadSettings.InvoicePath );
	end else begin
		WriteLogFile( 'Könyvtár ellenőrizve (invoice) ' + MainForm.NAVReadSettings.InvoicePath,0 );
	end;
	if ( not DirectoryExists( cAppPath + '\pdf' )) then begin
		CreateDir( cAppPath + '\pdf' );
	end;
	if ( not DirectoryExists( MainForm.NAVASzSettings.cEInvoicePath )) then begin
		WriteLogFile( 'Nem létező könyvtár (' + MainForm.NAVASzSettings.cEInvoicePath + ')',0 );
		CreateDir( MainForm.NAVASzSettings.cEInvoicePath );
	end else begin
		WriteLogFile( 'Könyvtár ellenőrizve (einvoice) ' + MainForm.NAVASzSettings.cEInvoicePath,0 );
	end;
	if (( not FileExists( cAppPath + '\libeay32.dll' )) or
		( not FileExists( cAppPath + '\ssleay32.dll' ))) then begin
		MessageDlg( 'libeay32.dll vagy ssleay32.dll nem található !!!', mtWarning, [ mbOK ], 0);
		MainForm.Close;
		AppLication.Terminate;
	end;
	lShowBalloon := FALSE;
	MyShowBalloonHint( 'Figyelem !!!', 'Automatikus NAV számla adatszolgáltatás aktív...', bfInfo );
	WriteLogFile( '-------------------',0 );
	WriteLogFile( 'A program elindítva (Loggolási szint : ' + IntToStr( MainForm.AppSettings.nLogLevel ) + ')',0 );
	MainForm.Enabled := TRUE;
	MainForm.InvoiceGrid.RowCount := 0;
// DBF file megnyitása
	if ( not FileExists( MainForm.NAVASzSettings.cDBFPath )) then begin
		MessageDlg( 'Mem található a számlák állománya : ' + MainForm.NAVASzSettings.cDBFPath, mtWarning, [ mbOK ], 0);
		WriteLogFile( 'Nem található a NAV.DBF állomány : ' + MainForm.NAVASzSettings.cDBFPath,1 );
		MainForm.AppLicationClose;
		Exit;
	end else begin
		WriteLogFile( 'A NAV.DBF állomány ellenőrizve.',2 );
	end;
	WriteLogFile( 'A NAV.DBF állomány sikeresen megnyitva.',2 );
	if ( UpperCase( MainForm.cPar01 ) = '-Q' ) and ( Trim( MainForm.cPar02 ) <> '' ) then begin
		lQuery := TRUE;
		WriteLogFile( 'Csak számla adat lekérdezése. (' + MainForm.cPar02 + ')',0 );
	end;
	MainForm.TrayIcon.Visible := ( not lQuery);
	nLastDBCheck := Now;
	nLastGridTime := Now;
	GoodImage.Visible := FALSE;
	BadImage.Visible := FALSE;
	AdoszamEdit.Text := '11371638-2-03';
	MainForm.MainTimer.Interval := 100;
	InvoiceList := TInvoiceList.Create;
// Ha paraméterrel hívjuk meg a programot, akkor csak lekérdezés van
	if lQuery then begin
		nRecNo := StrToInt( MainForm.cPar02 );
		WriteLogFile( 'Csak számla adat lekérdezése. (' + IntToStr( nRecNo ) + ')',0 );
		WriteLogFile( 'Elküldött számlák beolvasása.',4 );
		MainForm.RefreshInvoiceGrid;
		if ( nRecNo < InvoiceGrid.RowCount ) then begin
			InvoiceGrid.SelectRows( nRecNo,1 );
			InvoiceGrid.Row := nRecNo;
			WriteLogFile( 'Számla lekérdezése.',4 );
			MainForm.QueryInvoiceData;
		end;
		MainForm.DBFTable1.Close;
		MainForm.AppLicationClose;
		Exit;
	end;
	Menu02.Checked := MainForm.NAVASzSettings.lActive;
	Menu04.Checked := MainForm.NAVReadSettings.Active;
	Menu06.Checked := MainForm.CurrencyReadSettings.Active;
	Menu08.Checked := MainForm.SyncSettings.Active;
	dLastDelete := 0;
	MainForm.RefreshInvoiceGrid;
	MainForm.MainTimer.Enabled := TRUE;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
	I														: integer;
begin
	CurrencyReadSettings.Destroy;
	EMailSettings.Destroy;
	NAVReadSettings.Destroy;
	SyncSettings.Destroy;
	InvoiceList.Destroy;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
	Self.Width := Min( Screen.Width, Self.Width );
  Self.Height := Min( Screen.Height, Self.Height );
	SendButton.Left := Self.Width - ExitButton.Width - QueryButton.Width - SendButton.Width - 30;
	QueryButton.Left := Self.Width - ExitButton.Width - QueryButton.Width - 25;
	ExitButton.Left := Self.Width - ExitButton.Width - 20;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Action := caNone;
	Visible := FALSE;
	MainForm.Menu01.Enabled := TRUE;
	MainForm.Menu02.Enabled := TRUE;
	MainForm.Menu03.Enabled := TRUE;
	MainForm.Menu04.Enabled := TRUE;
	MainForm.Menu05.Enabled := TRUE;
	MainForm.Menu06.Enabled := TRUE;
	MainForm.Menu07.Enabled := TRUE;
	MainForm.Menu08.Enabled := TRUE;
	MainForm.Menu09.Enabled := TRUE;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	CanClose := FALSE;
	Application.Minimize;
	MainForm.Hide;
	Self.Hide;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
	Self.Caption := 'NAV - számla adatszolgáltatás (v' + GetNAVVersion( MainForm.AppSettings.NAVVersion ) + ')';
	MainForm.TrayIcon.Hint := 'NAV - számla adatszolgáltatás (v' + GetNAVVersion( MainForm.AppSettings.NAVVersion ) + ')';
	MainForm.ActiveControl := MainForm.InvoiceGrid;
	InvoiceGrid.Visible := TRUE;
	InvoiceGrid.SetFocus;
	if ( InvoiceList.Count > 0 ) then begin
		InvoiceGrid.SelectRows( InvoiceGrid.RowCount,1 );
		InvoiceGrid.Visible := TRUE;
		InvoiceGrid.TopRow := InvoiceGrid.RowCount - InvoiceGrid.VisibleRowCount;
		InvoiceGrid.Repaint;
	end;
	MainForm.Menu01.Enabled := FALSE;
	MainForm.Menu02.Enabled := FALSE;
	MainForm.Menu03.Enabled := FALSE;
	MainForm.Menu04.Enabled := FALSE;
	MainForm.Menu05.Enabled := FALSE;
	MainForm.Menu06.Enabled := FALSE;
	MainForm.Menu07.Enabled := FALSE;
	MainForm.Menu08.Enabled := FALSE;
	MainForm.Menu09.Enabled := FALSE;
end;

procedure TMainForm.WMGetMinMaxInfo(var MSG: Tmessage);
begin
  inherited;
  PMinMaxInfo( MSG.LParam )^.ptMinTrackSize.X := 600;
  PMinMaxInfo( MSG.LParam )^.ptMinTrackSize.Y := 500;
//  PMinMaxInfo( MSG.LParam )^.ptMaxTrackSize.X := 300;
//  PMinMaxInfo( MSG.LParam )^.ptMaxTrackSize.Y := 300;
end;

procedure TMainForm.MyShowBalloonHint( InTitle, InMessage : string; InBalloonFlag : TBalloonFlags );
begin
	if ( AppSettings.nBalloonTimeout > 0 ) and ( not lShowBalloon ) then begin
		TrayIcon.BalloonTitle := InTitle;
		TrayIcon.BalloonHint := InMessage;
		TrayIcon.BalloonFlags := InBalloonFlag;
//		MainTimer.Interval := AppSettings.nBalloonTimeOut;
		lShowBalloon := TRUE;
		nShowBalloonTime := Now;
		TrayIcon.ShowBalloonHint;
		WriteLogFile( 'Balloon bekapcsolva...',4 );
	end;
	TrayIcon.Hint := 'NAV - számla adatszolgáltatás (v' + GetNAVVersion( MainForm.AppSettings.NAVVersion ) + ')';
end;

procedure TMainForm.LogFileButtonClick(Sender: TObject);
begin
	ShellExecute( Handle, 'open', PChar( MainForm.cLogFile ), NIL, NIL, SW_SHOWNORMAL );
end;

procedure TMainForm.Menu01Click(Sender: TObject);
begin
	Application.Restore;
	Application.BringToFront;
	MainForm.Show;
end;

procedure TMainForm.Menu02Click(Sender: TObject);
begin
	MainForm.NAVASzSettings.lActive := ( not MainForm.NAVASzSettings.lActive );
	Menu02.Checked := MainForm.NAVASzSettings.lActive;
	if MainForm.NAVASzSettings.lActive then begin
		MyShowBalloonHint( 'Figyelem !!!', 'Automatikus adatszolgáltatás bekapcsolva...', bfInfo );
	end else begin
		MyShowBalloonHint( 'Figyelem !!!', 'Automatikus adatszolgáltatás kikapcsolva...', bfInfo );
	end;
end;

procedure TMainForm.Menu03Click(Sender: TObject);
begin
	Application.Restore;
	Application.BringToFront;
	NAVReadForm.Show;
end;

procedure TMainForm.Menu04Click(Sender: TObject);
begin
	MainForm.NAVReadSettings.Active := ( not MainForm.NAVReadSettings.Active );
	Menu04.Checked := MainForm.NAVReadSettings.Active;
	if MainForm.NAVReadSettings.Active then begin
		MyShowBalloonHint( 'Figyelem !!!', 'NAV adatbázis szinkronizálás bekapcsolva...', bfInfo );
	end else begin
		MyShowBalloonHint( 'Figyelem !!!', 'NAV adatbázis szinkronizálás kikapcsolva...', bfInfo );
	end;
end;

procedure TMainForm.Menu05Click(Sender: TObject);
begin
	CurrencyReadForm.ShowModal;
end;

procedure TMainForm.Menu06Click(Sender: TObject);
begin
	MainForm.CurrencyReadSettings.Active := ( not MainForm.CurrencyReadSettings.Active );
	Menu06.Checked := MainForm.CurrencyReadSettings.Active;
	if MainForm.CurrencyReadSettings.Active then begin
		MyShowBalloonHint( 'Figyelem !!!', 'Árfolyamok letöltése bekapcsolva...', bfInfo );
	end else begin
		MyShowBalloonHint( 'Figyelem !!!', 'Árfolyamok letöltése kikapcsolva...', bfInfo );
	end;
end;

procedure TMainForm.Menu07Click(Sender: TObject);
begin
	SyncForm.ShowModal;
end;

procedure TMainForm.Menu08Click(Sender: TObject);
begin
	MainForm.SyncSettings.Active := ( not MainForm.SyncSettings.Active );
	Menu08.Checked := MainForm.SyncSettings.Active;
	if MainForm.SyncSettings.Active then begin
		MyShowBalloonHint( 'Figyelem !!!', 'Adatszinkronizálás bekapcsolva...', bfInfo );
	end else begin
		MyShowBalloonHint( 'Figyelem !!!', 'Adatszinkronizálás kikapcsolva...', bfInfo );
	end;
end;

procedure TMainForm.Menu09Click(Sender: TObject);
begin
	SettingsForm.ShowModal;
end;

procedure TMainForm.Menu10Click(Sender: TObject);
begin
	MainForm.ApplicationClose;
end;

procedure TMainForm.NAVSMTPStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
	WriteLogFile( 'HTTP - ' + AStatusText,4 );
	Application.ProcessMessages;
end;

procedure TMainForm.NAVSMTPWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
	WriteLogFile( 'SMTP working - ' + IntToStr( AWorkCount ),4 );
	Application.ProcessMessages;
end;

procedure TMainForm.SSLHandlerStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
	WriteLogFile( 'HTTP - ' + AStatusText,4 );
	Application.ProcessMessages;
end;

procedure TMainForm.SSLHandlerStatusInfo(const AMsg: string);
begin
	WriteLogFile( 'SSL - ' + AMsg,4 );
	Application.ProcessMessages;
end;

procedure TMainForm.TrayIconDblClick(Sender: TObject);
begin
	if ( not MainForm.lDBFWorking ) and ( not MainForm.lRefreshGrid ) and ( not NAVReadForm.lReading ) and
		( not MainForm.lReadCurrency ) and ( not MainForm.lSyncData ) then begin
		Menu01Click( Self );
	end;
end;

procedure TMainForm.TrayIconMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
	if ( not MainForm.lDBFWorking ) and ( not MainForm.lRefreshGrid ) and ( not NAVReadForm.lReading ) and
		( not MainForm.lReadCurrency ) and ( not MainForm.lSyncData ) then begin
		if Button = TMouseButton.mbRight then begin
			MainForm.MainMenu.Popup( Mouse.CursorPos.X, Mouse.CursorPos.Y );
		end;
	end;
end;

procedure TMainForm.SendInvoice( InInvoice : TInvoice );
var
	cToken							: string;
begin
	lDBFWorking := TRUE;
	InInvoice.RequestId := 'S' + Trim( InInvoice.Supplier.TAXPayerID ) + LeftPad( InInvoice.RecordNumber,4,'0' ) + FormatDateTime( 'yyyymmddhhMMss', Now );
	if InInvoice.OperationType = '0' then begin
		InInvoice.OperationType := '1';
	end;
	cToken := NAVManageInvoice.GetManageInvoice( InInvoice );
	if cToken = '' then begin
		MainForm.MyShowBalloonHint( 'Hiba !!!', 'Hiba történt a számla elküldésekor...', bfError );
	end else begin
		MainForm.MyShowBalloonHint( 'Rendben', 'A számla elküldve...', bfInfo );
		GetInvoiceStatus( InInvoice );
	end;
	lDBFWorking := FALSE;
end;

procedure TMainForm.GetInvoiceStatus( InInvoice : TInvoice );
var
	cStatus							: string;
begin
	lDBFWorking := TRUE;
	if InInvoice.TransactionID <> '' then begin
		InInvoice.RequestId := 'Q' + Trim( InInvoice.Supplier.TAXPayerID ) + LeftPad( InInvoice.RecordNumber,4,'0' ) + FormatDateTime( 'yyyymmddhhMMss', Now );
		if InInvoice.OperationType = '0' then begin
			InInvoice.OperationType := '1';
		end;
		cStatus := NAVQueryInvoiceStatus.MakeInvoiceStatus( InInvoice );
		if cStatus = '' then begin
			if InInvoice.TestMode = tm_Test then begin
				MainForm.MyShowBalloonHint( 'Hiba !!! (teszt üzem)', 'Hiba történt a számla állapotának lekérdezéskor...', bfError );
			end else begin
				MainForm.MyShowBalloonHint( 'Hiba !!!', 'Hiba történt a számla állapotának lekérdezéskor...', bfError );
			end;
		end else begin
			if InInvoice.TestMode = tm_Test then begin
				MainForm.MyShowBalloonHint( 'Rendban !!! (teszt üzem)', 'A számla állapota : ' + cStatus, bfInfo );
			end else begin
				MainForm.MyShowBalloonHint( 'Rendban !!!', 'A számla állapota : ' + cStatus, bfInfo );
			end;
		end;
	end;
	lDBFWorking := FALSE;
end;


procedure TMainForm.InvoiceGridCustomCellDraw(Sender: TObject; Canvas: TCanvas;
	ACol, ARow: Integer; AState: TGridDrawState; ARect: TRect; Printing: Boolean);
var
	cCellText : string;
begin
	if ACol = 6 then begin
		cCellText := MainForm.InvoiceGrid.Cells[ ACol, ARow ];
		if cCellText = '1998' then begin


		end;
	end;
end;

procedure TMainForm.InvoiceGridGetAlignment(Sender: TObject; ARow,
	ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
	if ( ACol > 1 ) then begin
		HAlign := taRightJustify;
  end;

end;

procedure TMainForm.InvoiceGridGetCellColor(Sender: TObject; ARow,
	ACol: Integer; AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
var
	nItem,nColor								: integer;
	NAVInvoice									: TInvoice;
begin
	nItem := ARow - 1;
	if AState = [] then begin
		nItem := ARow - 1;
//		MainForm.DBFTable.First;
//		MainForm.DBFTable.MoveBy( nItem );
		NAVInvoice := TInvoice( MainForm.InvoiceList.Items[ nItem ]);
		nColor := 0;
		if NAVInvoice.NAVError = '1' then begin
			nColor := 1;
		end else begin
			if ( NAVInvoice.InvStatusNum < '5' ) then begin
				nColor := 2;
			end else begin
				if ( NAVInvoice.InvStatus <> 'OK' ) and ( NAVInvoice.InvStatus <> 'DONE' ) then begin
					nColor := 1;
				end;
			end;
		end;
		case nColor of
			1 : begin
				ABrush.Color := $00DDDEF9;
			end;
			2 : begin
				ABrush.Color := $00ACCAB3;
			end;
			else begin
				if ARow mod 2 = 1 then begin
					ABrush.Color := $00EAEAEA;
				end else begin
					ABrush.Color := clWhite;
				end;
			end;
		end;
	end;
end;

procedure TMainForm.QueryButtonClick(Sender: TObject);
begin
	QueryInvoiceData;
end;

procedure TMainForm.QueryInvoiceData;
var
	NAVInvoice											: TInvoice;
begin
	lDBFWorking := TRUE;
	NAVInvoice := TInvoice( MainForm.InvoiceList.Items[ InvoiceGrid.Selection.Top - 1 ]);
	if NAVInvoice.TransactionID <> '' then begin
		NAVInvoice.RequestId := 'D' + Trim( NAVInvoice.Supplier.TAXPayerID ) + LeftPad( NAVInvoice.RecordNumber,4,'0' ) + FormatDateTime( 'yyyymmddhhMMss', Now );
		if NAVInvoice.InvStatusNum > '4' then begin
			NAVQueryInvoiceData.GetInvoiceData( NAVInvoice );
		end;
	end;
	lDBFWorking := FALSE;
end;

procedure TMainForm.CheckInvoiceDatabase;
var
	NAVInvoice											: TInvoice;
	I														: integer;
begin
	WriteLogFile( 'Számla adatok ellenőrzése ' + Trim( IntToStr( MainForm.InvoiceList.Count )) + ' db record',3 );
	for I := 0 to MainForm.InvoiceList.Count - 1 do begin
		NAVInvoice := MainForm.InvoiceList.Items[ I ];
		if NAVInvoice.XMLFile <> '' then begin
			if ( NAVInvoice.NAVError = '0' ) or ( NAVInvoice.NAVError = '' ) then begin
				if NAVInvoice.InvStatusNum < '4' then begin
					SendInvoice( NAVInvoice );
				end else begin
					if ( NAVInvoice.InvStatusNum = '4' ) or ( NAVInvoice.InvStatusNum = '5' ) then begin
						GetInvoiceStatus( NAVInvoice );
					end;
				end;
			end;
		end;
	end;
	WriteLogFile( 'Számla adatok ellenőrzése befejezve.',3 );
end;

procedure TMainForm.RefreshInvoiceGrid;
var
	I,nRec,nSelected,nTop			: integer;
begin
	lChangedDBF := FALSE;
	MainForm.DBFTable1.DatabaseName := ExtractFilePath( MainForm.NAVASzSettings.cDBFPath );
	MainForm.DBFTable1.TableName := ExtractFileName( MainForm.NAVASzSettings.cDBFPath );
	try
		MainForm.DBFTable1.OEMTranslate := TRUE;
		MainForm.DBFTable1.Open;
// Ha sikerült a DBF file megnyitása, akkor újraolvassuk
		if ( MainForm.DBFTable1.Active ) then begin
			if InvoiceGrid.RowCount = 1 then begin
				nTop := 0;
				nSelected := 0;
			end else begin
				nSelected := InvoiceGrid.Selection.Top;
				nTop := InvoiceGrid.TopRow;
			end;
			nRec := 0;
			WriteLogFile( 'Számlalista mérete: ' + IntToStr( SizeOf( InvoiceList )) + ' byte',4 );
			MainForm.DBFTable1.First;
			MainForm.ReadProgressBar.Visible := TRUE;
			MainForm.ReadProgressBar.Max := MainForm.DBFTable1.RecordCount;
			MainForm.ReadProgressBar.Position := 0;
			while ( not MainForm.DBFTable1.Eof ) do begin
				nRec := -1;
				for I := 0 to InvoiceList.Count - 1 do begin
					if ( TInvoice( InvoiceList.Items[ I ]).RecordNumber = MainForm.DBFTable1.RecNo ) then begin
						nRec := I;
						Break;
					end;
				end;
				if ( nRec = -1 ) then begin
					InvoiceList.Add;
					nRec := InvoiceList.Count - 1;
				end;
				TInvoice( InvoiceList.Items[ nRec ]).RecordNumber := MainForm.DBFTable1.RecNo;
				if Trim( MainForm.DBFTable1.FieldByName( 'OPERATION' ).AsString ) = '' then begin
					TInvoice( InvoiceList.Items[ nRec ]).OperationType := '1';
				end else begin
					TInvoice( InvoiceList.Items[ nRec ]).OperationType := MainForm.DBFTable1.FieldByName( 'OPERATION' ).AsString;
				end;
				if MainForm.DBFTable1.FieldByName( 'TESZT' ).AsString = '1' then begin
					TInvoice( InvoiceList.Items[ nRec ]).TestMode := tm_Test;
				end else begin
					TInvoice( InvoiceList.Items[ nRec ]).TestMode := tm_Real;
				end;
				if ( MainForm.DBFTable1.FindField( 'ELSZLA' ) = NIL ) then begin
					TInvoice( InvoiceList.Items[ nRec ]).Electronic := ei_normal;
				end else begin
					if Trim( MainForm.DBFTable1.FieldByName( 'ELSZLA' ).AsString ) = 'I' then begin
						TInvoice( InvoiceList.Items[ nRec ]).Electronic := ei_Electronic;
					end else begin
						TInvoice( InvoiceList.Items[ nRec ]).Electronic := ei_normal;
					end;
				end;
				TInvoice( InvoiceList.Items[ nRec ]).Supplier.Login := MainForm.DBFTable1.FieldByName( 'LOGIN' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Supplier.Password := MainForm.DBFTable1.FieldByName( 'PASSWORD' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Supplier.SignKey := MainForm.DBFTable1.FieldByName( 'SIGNKEY' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Supplier.ChangeKey := MainForm.DBFTable1.FieldByName( 'CHANGEKEY' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Supplier.TAXPayerID := MainForm.DBFTable1.FieldByName( 'ADOSZAM' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Supplier.Name := MainForm.DBFTable1.FieldByName( 'CEG1' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).XMLFile := MainForm.DBFTable1.FieldByName( 'XMLFILE' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).TransactionID := MainForm.DBFTable1.FieldByName( 'ACTIONID' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).InvoiceNumber := MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Customer.Name := MainForm.DBFTable1.FieldByName( 'CEG2' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).Customer.TAXPayerID := '';
				TInvoice( InvoiceList.Items[ nRec ]).GrossAmount := MainForm.DBFTable1.FieldByName( 'BRUTTO' ).AsFloat;
				TInvoice( InvoiceList.Items[ nRec ]).VatAmount := MainForm.DBFTable1.FieldByName( 'AFA' ).AsFloat;
				if Trim( MainForm.DBFTable1.FieldByName( 'PENZNEM' ).AsString ) = '' then begin
					TInvoice( InvoiceList.Items[ nRec ]).Currency := 'HUF';
				end else begin
					TInvoice( InvoiceList.Items[ nRec ]).Currency := MainForm.DBFTable1.FieldByName( 'PENZNEM' ).AsString;
				end;
				TInvoice( InvoiceList.Items[ nRec ]).InvStatusText := MainForm.DBFTable1.FieldByName( 'STATUSTEXT' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).InvStatus := MainForm.DBFTable1.FieldByName( 'INVSTATUS' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).InvStatusNum := MainForm.DBFTable1.FieldByName( 'STATUS' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).NAVError := MainForm.DBFTable1.FieldByName( 'NAVERROR' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).RequestDateTime := MainForm.DBFTable1.FieldByName( 'REQDATE' ).AsDateTime;
				TInvoice( InvoiceList.Items[ nRec ]).RequestVersion := SetNAVVersion( Trim( MainForm.DBFTable1.FieldByName( 'REQVER' ).AsString ));
				TInvoice( InvoiceList.Items[ nRec ]).StatusDateTime := MainForm.DBFTable1.FieldByName( 'RESDATE' ).AsDateTime;
				TInvoice( InvoiceList.Items[ nRec ]).SendDateTime := MainForm.DBFTable1.FieldByName( 'RESDATE' ).AsDateTime;
				TInvoice( InvoiceList.Items[ nRec ]).ResultText := MainForm.DBFTable1.FieldByName( 'RESULT' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).ErrorText := MainForm.DBFTable1.FieldByName( 'ERRORTEXT' ).AsString;
				TInvoice( InvoiceList.Items[ nRec ]).SendMail := MainForm.DBFTable1.FieldByName( 'SENDMAIL' ).AsInteger;
				TInvoice( InvoiceList.Items[ nRec ]).RequestId := 'X' + TInvoice( InvoiceList.Items[ nRec ]).Supplier.TAXPayerID +
					LeftPad( TInvoice( InvoiceList.Items[ nRec ]).RecordNumber,4,'0' ) +
					FormatDateTime( 'yyyymmddhhMMss', Now );
//				WriteLogFile( MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString + ' számla beolvasva (' +
//					MainForm.DBFTable1.FieldByName( 'CEG1' ).AsString + ' - ' + MainForm.DBFTable1.FieldByName( 'CEG2' ).AsString + ')',4 );
				MainForm.DBFTable1.Next;
				MainForm.ReadProgressBar.Position := MainForm.DBFTable1.RecNo;
			end;
//	end;
			MainForm.DBFTable1.Close;
		end;
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a NAV.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;
	MainForm.ReadProgressBar.Visible := FALSE;
// Innen jön a Grid feltöltése
	InvoiceGrid.ColCount := 9;
	if ( MainForm.Width > 1000 ) then begin
		InvoiceGrid.ColWidths[ 0 ] := InvoiceGrid.Width div 5;
		InvoiceGrid.ColWidths[ 1 ] := InvoiceGrid.Width div 5;
		InvoiceGrid.ColWidths[ 2 ] := InvoiceGrid.Width div 11;
		InvoiceGrid.ColWidths[ 3 ] := InvoiceGrid.Width div 11;
		InvoiceGrid.ColWidths[ 4 ] := InvoiceGrid.Width div 11;
		InvoiceGrid.ColWidths[ 5 ] := InvoiceGrid.Width div 9;
		InvoiceGrid.ColWidths[ 6 ] := InvoiceGrid.Width div 15;
		InvoiceGrid.ColWidths[ 7 ] := InvoiceGrid.Width div 20;
		InvoiceGrid.ColWidths[ 8 ] := InvoiceGrid.Width div 15;
	end else begin
		InvoiceGrid.ColWidths[ 0 ] := 50;
		InvoiceGrid.ColWidths[ 1 ] := 50;
		InvoiceGrid.ColWidths[ 2 ] := 100;
		InvoiceGrid.ColWidths[ 3 ] := 100;
		InvoiceGrid.ColWidths[ 4 ] := 100;
		InvoiceGrid.ColWidths[ 5 ] := 90;
		InvoiceGrid.ColWidths[ 6 ] := 140;
		InvoiceGrid.ColWidths[ 7 ] := 200;
		InvoiceGrid.ColWidths[ 8 ] := 150;
	end;
	if ( InvoiceList.Count = 0 ) then InvoiceGrid.RowCount := 2 else InvoiceGrid.RowCount := InvoiceList.Count + 1;
	InvoiceGrid.FixedRows := 1;
	InvoiceGrid.Cells[ 0,0 ] := 'Számla kiállítója';
	InvoiceGrid.Cells[ 1,0 ] := 'Számla befogadója';
	InvoiceGrid.Cells[ 2,0 ] := 'Számlaszám';
	InvoiceGrid.Cells[ 3,0 ] := 'Bruttó érték';
	InvoiceGrid.Cells[ 4,0 ] := 'ÁFA érték';
	InvoiceGrid.Cells[ 5,0 ] := 'Állapot';
	InvoiceGrid.Cells[ 6,0 ] := 'Dátum';
	InvoiceGrid.Cells[ 7,0 ] := 'Válasz';
	InvoiceGrid.Cells[ 8,0 ] := 'Verzió';
	lChangedDBF := TRUE;
	if lChangedDBF then begin
		for I := 0 to InvoiceList.Count - 1 do begin
			InvoiceGrid.Cells[ 0,I + 1 ] := TInvoice( InvoiceList.Items[ I ]).Supplier.Name;
			InvoiceGrid.Cells[ 1,I + 1 ] := TInvoice( InvoiceList.Items[ I ]).Customer.Name;
			InvoiceGrid.Cells[ 2,I + 1 ] := TInvoice( InvoiceList.Items[ I ]).InvoiceNumber;
			InvoiceGrid.Cells[ 3,I + 1 ] := FormatFloat( '# ### ##0 "' + TInvoice( InvoiceList.Items[ I ]).Currency + '"', TInvoice( InvoiceList.Items[ I ]).GrossAmount );
			InvoiceGrid.Cells[ 4,I + 1 ] := FormatFloat( '# ### ##0 "' + TInvoice( InvoiceList.Items[ I ]).Currency + '"', TInvoice( InvoiceList.Items[ I ]).VatAmount );
			InvoiceGrid.Cells[ 5,I + 1 ] := TInvoice( InvoiceList.Items[ I ]).InvStatusText;
			InvoiceGrid.Cells[ 6,I + 1 ] := FormatDateTime( 'yyyy.mm.dd', TInvoice( InvoiceList.Items[ I ]).SendDateTime );
			InvoiceGrid.Cells[ 7,I + 1 ] := TInvoice( InvoiceList.Items[ I ]).InvStatus;
			if ( TInvoice( InvoiceList.Items[ I ]).Electronic = ei_Electronic ) then begin
				if ( TInvoice( InvoiceList.Items[ I ]).TestMode = tm_Test ) then begin
					InvoiceGrid.Cells[ 8,I + 1 ] := 'Teszt-' + GetNAVVersion( TInvoice( InvoiceList.Items[ I ]).RequestVersion ) + ' (E)';
				end else begin
					InvoiceGrid.Cells[ 8,I + 1 ] := GetNAVVersion( TInvoice( InvoiceList.Items[ I ]).RequestVersion ) + ' (E)';
				end;
			end else begin
				if ( TInvoice( InvoiceList.Items[ I ]).TestMode = tm_Test ) then begin
					InvoiceGrid.Cells[ 8,I + 1 ] := 'Teszt-' + GetNAVVersion( TInvoice( InvoiceList.Items[ I ]).RequestVersion );
				end else begin
					InvoiceGrid.Cells[ 8,I + 1 ] := GetNAVVersion( TInvoice( InvoiceList.Items[ I ]).RequestVersion );
				end;
			end;
		end;
		if nSelected = 0 then begin
			InvoiceGrid.SelectRows( InvoiceGrid.RowCount,1 );
			InvoiceGrid.Row := InvoiceGrid.RowCount - 1;
		end else begin
			InvoiceGrid.SelectRows( nSelected,1 );
			InvoiceGrid.Row := nSelected;
		end;
		if MainForm.Showing then begin
			InvoiceGrid.Visible := TRUE;
			InvoiceGrid.TopRow := nTop;
			InvoiceGrid.Repaint;
		end;
	end;
end;


procedure TMainForm.SendButtonClick(Sender: TObject);
begin
	WriteLogFile( 'Kézi számlaküldés.',1 );
	SendInvoice( InvoiceList.Items[ MainForm.InvoiceGrid.Selection.Top - 1 ] );
end;

procedure TMainForm.SettingsButtonClick(Sender: TObject);
begin
	SettingsForm.ShowModal;
end;

procedure TMainForm.ExitButtonClick(Sender: TObject);
begin
	Self.Close;
end;

procedure TMainForm.AdoszamEditChange(Sender: TObject);
begin
	GoodImage.Visible := FALSE;
	BadImage.Visible := FALSE;
end;

procedure TMainForm.CheckButtonClick(Sender: TObject);
var
	cResult							: string;
	NAVInvoice						: TInvoice;
begin
	if Length( Trim( AdoszamEdit.Text )) < 11 then begin
		MessageDlg( 'Hibás adószám !!!', mtWarning, [ mbOK ], 0);
	end else begin
		NAVInvoice := TInvoice.Create;
		NAVInvoice := InvoiceList.Items[ MainForm.InvoiceGrid.Selection.Top - 1 ];
//		InvoiceList.Items[ MainForm.InvoiceGrid.Selection.Top - 1 ].RequestID :=
//			Trim( InvoiceList.Items[ MainForm.InvoiceGrid.Selection.Top - 1 ].Supplier.Name ) + LeftPad( MainForm.InvoiceGrid.Selection.Top,4,'0' ) + FormatDateTime( 'yyyymmddhhMMss', Now );
		cResult := NAVQueryTaxpayer.CheckTaxpayer( NAVInvoice, Copy( AdoszamEdit.Text,1,8 ));
		if cResult = 'OK' then begin
			GoodImage.Visible := TRUE;
			BadImage.Visible := FALSE;
			TaxPayerForm.Show;
		end else begin
			GoodImage.Visible := FALSE;
			BadImage.Visible := TRUE;
		end;
		NAVInvoice.Destroy;
	end;
end;

procedure TMainForm.ApplicationClose;
begin
	TrayIcon.Visible := FALSE;
	if MainForm.DBFTable1.Active then begin
		MainForm.DBFTable1.Close;
	end;
	MainForm.Close;
	XMLHandler.WriteXMLFile;
	WriteLogFile( 'XML file rögzítve',4 );
	WriteLogFile( 'A program bezárva',1 );
	WriteLogFile( '-------------------',1 );
	AppLication.Terminate;
end;

procedure TMainForm.MainHTTPStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
	WriteLogFile( 'HTTP - ' + AStatusText,4 );
//	Application.ProcessMessages;
end;

procedure TMainForm.MainHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
	WriteLogFile( 'HTTP working - ' + IntToStr( AWorkCount ),4 );
//	Application.ProcessMessages;
end;

procedure TMainForm.MainTimerTimer(Sender: TObject);
var
	nMS : integer;
begin
// Ha a balloon látszik, akkor azt kell figyelni
	if lShowBalloon then begin
		nMS := MilliSecondsBetween( Now, nShowBalloonTime );
		if nMS > MainForm.AppSettings.nBalloonTimeout then begin
			MainForm.TrayIcon.Visible := FALSE;
			MainForm.TrayIcon.Visible := TRUE;
			lShowBalloon := FALSE;
			MainForm.TrayIcon.BalloonHint := '';
			MainForm.TrayIcon.BalloonTitle := '';
		end;
// Ha nincs balloon
	end else begin
// Ha éppen nem csinálunk mást
		if ( not MainForm.lDBFWorking ) and ( not MainForm.lRefreshGrid ) and ( not NAVReadForm.lReading ) and
			( not MainForm.lReadCurrency ) and ( not MainForm.lSyncData ) then begin
// Be van-e kapcsolva a küldés
			if ( MainForm.NAVASzSettings.lActive ) then begin
// A számla listát kell-e frissíteni
				if ( MilliSecondsBetween( Now, MainForm.nLastGridTime ) >= MainForm.NAVASzSettings.nGridInterval ) then begin
					MainForm.MainTimer.Enabled := FALSE;
					MainForm.lRefreshGrid := TRUE;
					MainForm.nLastGridTime := Now;
					MainForm.RefreshInvoiceGrid;
					MainForm.lRefreshGrid := FALSE;
					MainForm.MainTimer.Enabled := TRUE;
				end;
// A számla adatokat kell-e frissíteni
				if ( MilliSecondsBetween( Now, MainForm.nLastDBCheck ) >= MainForm.NAVASzSettings.nDBFInterval ) then begin
					MainForm.MainTimer.Enabled := FALSE;
					MainForm.lDBFWorking := TRUE;
					MainForm.CheckInvoiceDatabase;
					MainForm.nLastDbCheck := Now;
					MainForm.lDBFWorking := FALSE;
					MainForm.MainTimer.Enabled := TRUE;
				end;
			end;
// Kell olvasni a NAV adatbázist
			if ( MainForm.NAVReadSettings.Active ) then begin
// Ha eljött az idő
				if ( MinutesBetween( Now, MainForm.NAVReadSettings.LastRead ) >= MainForm.NAVReadSettings.ReadInterval ) then begin
					if ( Now > MainForm.NAVReadSettings.LastRead ) then begin
						MainForm.MainTimer.Enabled := FALSE;
						NAVReadForm.lReading := TRUE;
						Reading.ReadFactories( TRUE );
						NAVReadForm.lReading := FALSE;
						MainForm.MainTimer.Enabled := TRUE;
					end;
				end;
			end;
// Kell olvasni az árfolyamokat
			if ( MainForm.CurrencyReadSettings.Active ) then begin
// Ha eljött az idő
				if ( MinutesBetween( Now, MainForm.CurrencyReadSettings.LastRead ) >= MainForm.CurrencyReadSettings.ReadInterval ) then begin
					if ( Now > MainForm.CurrencyReadSettings.LastRead ) then begin
						MainForm.MainTimer.Enabled := FALSE;
						MainForm.lReadCurrency := TRUE;
						CurrencyReadForm.ReadCurrencies;
						MainForm.lReadCurrency := FALSE;
						MainForm.MainTimer.Enabled := TRUE;
					end;
				end;
			end;
// Be van-e kapcsolva a szinkronizálás
			if ( MainForm.SyncSettings.Active ) then begin
// A eljött az idő
				if ( MinutesBetween( Now, MainForm.SyncSettings.LastRead ) >= MainForm.SyncSettings.ReadInterval ) then begin
					MainForm.MainTimer.Enabled := FALSE;
					MainForm.lSyncData := TRUE;
					SyncForm.Syncing;
					MainForm.lSyncData := FALSE;
					MainForm.MainTimer.Enabled := TRUE;
				end;
			end else begin
// Üresjárat van, akkor lehet törölgetni a régi fájlokat
				if DaysBetween( MainForm.dLastDelete, Now ) > 1 then begin
					if MainForm.Showing then begin
						MainForm.MainTimer.Enabled := FALSE;
						DeleteForm.DeletingOldFiles;
						MainForm.MainTimer.Enabled := TRUE;
					end;
				end;
			end;
		end;
	end;
end;

end.
