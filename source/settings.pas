unit Settings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvReflectionImage, Vcl.StdCtrls,
	AdvTrackBar, AdvOfficeButtons, AdvOfficePager, AdvOfficePagerStylers, Vcl.Grids,
  AdvGlassButton;

type
	TSettingsForm = class(TForm)
    OKButton: TButton;
    SettingsPager: TAdvOfficePager;
	  SettingsPage01: TAdvOfficePage;
    SettingsPage02: TAdvOfficePage;
    SettingsPageStyler: TAdvOfficePagerOfficeStyler;
    DeleteXMLCheckBox: TAdvOfficeCheckBox;
    DeleteFilesBar: TAdvTrackBar;
    DeleteFilesLabel: TLabel;
    MessageTimeBar: TAdvTrackBar;
    MessageTimeLabel: TLabel;
    DBFRefreshBar: TAdvTrackBar;
    DBFRefreshLabel: TLabel;
	  GridRefreshBar: TAdvTrackBar;
	  GridRefreshLabel: TLabel;
	  LogLevelBar: TAdvTrackBar;
	  LogLevelLabel: TLabel;
	  ReceiveXMLEdit: TEdit;
	  ReceiveXMLButton: TButton;
	  SendXMLButton: TButton;
	  LogPathButton: TButton;
    DBFFileButton: TButton;
    DBFFileEdit: TEdit;
    LogPathEdit: TEdit;
    SendXMLEdit: TEdit;
    ReceiveXMLLabel: TLabel;
	  SendXMLLabel: TLabel;
    LogPathLabel: TLabel;
	  DBFFileLabel: TLabel;
    SettingsImage: TAdvReflectionImage;
    ActLogLevelLabel: TLabel;
    ActGridRefreshLabel: TLabel;
    ActDBFRefreshLabel: TLabel;
    ActMessageTimeLabel: TLabel;
    ActDeleteFilesLabel: TLabel;
    MailImage: TAdvReflectionImage;
    SMTPLabel: TLabel;
    SMTPEdit: TEdit;
    SMTPPortEdit: TEdit;
    SMTPPortLabel: TLabel;
    SMTPUserNameLabel: TLabel;
    SMTPUserNameEdit: TEdit;
    PasswordEdit: TEdit;
    PasswordEditLabel: TLabel;
    RepasswordEdit: TEdit;
    RePasswordLabel: TLabel;
    EmailSendCheckBox: TAdvOfficeCheckBox;
    AddressGrid: TStringGrid;
    AddressLabel: TLabel;
    NewButton: TAdvGlassButton;
    DeleteButton: TAdvGlassButton;
    SenderMailLabel: TLabel;
    SenderMailEdit: TEdit;
    SettingsPage03: TAdvOfficePage;
    UserCompanyLabel: TLabel;
    UserCompanyEdit: TEdit;
    UserSiteEdit: TEdit;
	  UserSiteLabel: TLabel;
    UserMachineEdit: TEdit;
    UserMachineLabel: TLabel;
    UserUserNameEdit: TEdit;
    UserUserNameLabel: TLabel;
    UserImage: TAdvReflectionImage;
	  procedure DBFFileButtonClick(Sender: TObject);
	  procedure FormShow(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
	  procedure LogPathButtonClick(Sender: TObject);
	  procedure LogLevelBarChange(Sender: TObject);
	  procedure GridRefreshBarChange(Sender: TObject);
	  procedure DBFRefreshBarChange(Sender: TObject);
	  procedure MessageTimeBarChange(Sender: TObject);
	  procedure SendXMLButtonClick(Sender: TObject);
	  procedure ReceiveXMLButtonClick(Sender: TObject);
	  procedure DeleteFilesBarChange(Sender: TObject);
	  procedure DeleteButtonClick(Sender: TObject);
	  procedure NewButtonClick(Sender: TObject);
	private
	  { Private declarations }
	public
	  { Public declarations }
	end;

var
	SettingsForm: TSettingsForm;

implementation

uses Main, VCL.FileCtrl, NAV, Math;

{$R *.dfm}

procedure TSettingsForm.FormShow(Sender: TObject);
var
	MailAddress								: TEmailAddress;
	I											: integer;
begin
// Általános lap
	DBFFileEdit.Text := MainForm.NAVASzSettings.cDBFPath;
	LogPathEdit.Text := MainForm.AppSettings.cLogPath;
	SendXMLEdit.Text := MainForm.AppSettings.cSendPath;
	ReceiveXMLEdit.Text := MainForm.AppSettings.cReceivePath;
	ActLogLevelLabel.Caption := IntToStr( MainForm.AppSettings.nLogLevel );
	LogLevelBar.Position := MainForm.AppSettings.nLogLevel;
	ActGridRefreshLabel.Caption := IntToStr( MainForm.NAVASzSettings.nGridInterval div 1000 );
	GridRefreshBar.Position := 0;
	GridRefreshBar.Position := MainForm.NAVASzSettings.nGridInterval div 1000;
	ActDBFRefreshLabel.Caption := IntToStr( MainForm.NAVASzSettings.nDBFInterval div 1000 );
	DBFRefreshBar.Position := 0;
	DBFRefreshBar.Position := MainForm.NAVASzSettings.nDBFInterval div 1000 - 5;
	ActMessageTimeLabel.Caption := IntToStr( MainForm.AppSettings.nBalloonTimeout div 1000 );
	MessageTimeBar.Position := 0;
	MessageTimeBar.Position := MainForm.AppSettings.nBalloonTimeout div 1000;
	DeleteFilesBar.Position := 0;
	DeleteFilesBar.Position := MainForm.NAVASzSettings.nDeleteDay + 1;
	DeleteXMLCheckBox.Checked := MainForm.NAVASzSettings.lDeleteProcessing;
// Email lap
	EmailSendCheckBox.Checked := MainForm.EMailSettings.MailSending;
	SMTPEdit.Text := MainForm.EMailSettings.MailSMTP;
	SMTPPortEdit.Text := MainForm.EMailSettings.MailPort;
	SMTPUserNameEdit.Text := MainForm.EMailSettings.MailUserName;
	PasswordEdit.Text := MainForm.EMailSettings.MailPassword;
	RePasswordEdit.Text := MainForm.EMailSettings.MailPassword;
	SenderMailEdit.Text := MainForm.EMailSettings.MailSender;
	AddressGrid.ColCount := 3;
	AddressGrid.ColWidths[ 0 ] := 30;
	AddressGrid.ColWidths[ 1 ] := 180;
	AddressGrid.ColWidths[ 2 ] := 180;
	AddressGrid.Cells[ 0, 0 ] := 'Sor';
	AddressGrid.Cells[ 1, 0 ] := 'Név';
	AddressGrid.Cells[ 2, 0 ] := 'Email';
	AddressGrid.RowHeights[ 0 ] := 20;
	AddressGrid.RowCount := Max( MainForm.EMailSettings.EMailItems.Count + 1, 2 );
	AddressGrid.FixedRows := 1;
	for I := 0 to MainForm.EMailSettings.EMailItems.Count - 1 do begin
		AddressGrid.RowHeights[ I + 1 ] := 20;
		AddressGrid.Cells[ 0, I + 1 ] := IntToStr( I + 1 );
		AddressGrid.Cells[ 1, I + 1 ] := MainForm.EMailSettings.EMailItems[ I ].EMailName;
		AddressGrid.Cells[ 2, I + 1 ] := MainForm.EMailSettings.EMailItems[ I ].EMailAddress;
	end;
	DeleteButton.Enabled := ( MainForm.EMailSettings.EMailItems.Count > 1 );
// Felhasználó lap
	UserCompanyEdit.Text := MainForm.NAVASzSettings.cUserCompany;
	UserSiteEdit.Text := MainForm.NAVASzSettings.cUserSites;
	UserMachineEdit.Text := MainForm.NAVASzSettings.cUserMachine;
	UserUserNameEdit.Text := MainForm.NAVASzSettings.cUserName;
	SettingsPager.ActivePageIndex := 0;
end;


procedure TSettingsForm.OKButtonClick(Sender: TObject);
var
	EMailAddress							: PEmailAddress;
	cMailName,cMailAddress				: ShortString;
	I											: integer;
begin
// Általános lap
	MainForm.NAVASzSettings.cDBFPath := DBFFileEdit.Text;
	MainForm.AppSettings.cLogPath := LogPathEdit.Text;
	MainForm.AppSettings.cSendPath := SendXMLEdit.Text;
	MainForm.AppSettings.cReceivePath := ReceiveXMLEdit.Text;
	MainForm.AppSettings.nLogLevel := LogLevelBar.Position;
	MainForm.NAVASzSettings.nGridInterval := GridRefreshBar.Position * 1000;
	MainForm.NAVASzSettings.nDBFInterval := ( DBFRefreshBar.Position + 5 ) * 1000;
	MainForm.AppSettings.nBalloonTimeout := MessageTimeBar.Position * 1000;
	MainForm.NAVASzSettings.nDeleteDay := DeleteFilesBar.Position - 1;
	MainForm.NAVASzSettings.lDeleteProcessing := DeleteXMLCheckBox.Checked;
// Email lap
	MainForm.EMailSettings.MailSending := EmailSendCheckBox.Checked;
	MainForm.EMailSettings.MailSMTP := SMTPEdit.Text;
	MainForm.EMailSettings.MailPort := SMTPPortEdit.Text;
	MainForm.EMailSettings.MailUserName := SMTPUserNameEdit.Text;
	MainForm.EMailSettings.MailPassword := PasswordEdit.Text;
	MainForm.EMailSettings.MailPassword := RePasswordEdit.Text;
	MainForm.EMailSettings.MailSender := SenderMailEdit.Text;
	MainForm.EMailSettings.EMailItems.Clear;
	for I := 1 to AddressGrid.RowCount - 1 do begin
		MainForm.EMailSettings.EMailItems.Add;
		MainForm.EMailSettings.EMailItems[ MainForm.EMailSettings.EMailItems.Count ].EMailName := AddressGrid.Cells[ 1,I ];
		MainForm.EMailSettings.EMailItems[ MainForm.EMailSettings.EMailItems.Count ].EMailAddress := AddressGrid.Cells[ 1,I ];
	end;
// Felhasználó lap
	MainForm.NAVASzSettings.cUserCompany := UserCompanyEdit.Text;
	MainForm.NAVASzSettings.cUserSites := UserSiteEdit.Text;
	MainForm.NAVASzSettings.cUserMachine := UserMachineEdit.Text;
	MainForm.NAVASzSettings.cUserName := UserUserNameEdit.Text;
end;

procedure TSettingsForm.ReceiveXMLButtonClick(Sender: TObject);
var
	OpenFileDialog							: TFileOpenDialog;
	cNewPath									: string;
begin
	if Win32MajorVersion >= 6 then begin
		OpenFileDialog := TFileOpenDialog.Create( nil );
		OpenFileDialog.Title := 'Fogadott XML fájlok helye';
		OpenFileDialog.Options := [ fdoPickFolders, fdoPathMustExist, fdoForceFileSystem ];
		OpenFileDialog.OkButtonLabel := 'Kiválasztás';
		OpenFileDialog.DefaultFolder := ReceiveXMLEdit.Text;
		OpenFileDialog.FileName := ReceiveXMLEdit.Text;
		if OpenFileDialog.Execute then begin
			ReceiveXMLEdit.Text := OpenFileDialog.FileName;
		end;
		OpenFileDialog.Free;
	end else begin
		cNewPath := ReceiveXMLEdit.Text;
		if SelectDirectory( 'Fogadott XML fájlok helye', ExtractFileDrive( cNewPath ), cNewPath, [sdNewUI, sdNewFolder]) then begin
			ReceiveXMLEdit.Text := cNewPath;
		end;
	end;
end;

procedure TSettingsForm.SendXMLButtonClick(Sender: TObject);
var
	OpenFileDialog							: TFileOpenDialog;
	cNewPath									: string;
begin
	if Win32MajorVersion >= 6 then begin
		OpenFileDialog := TFileOpenDialog.Create( nil );
		OpenFileDialog.Title := 'Küldött XML fájlok helye';
		OpenFileDialog.Options := [ fdoPickFolders, fdoPathMustExist, fdoForceFileSystem ];
		OpenFileDialog.OkButtonLabel := 'Kiválasztás';
		OpenFileDialog.DefaultFolder := SendXMLEdit.Text;
		OpenFileDialog.FileName := SendXMLEdit.Text;
		if OpenFileDialog.Execute then begin
			SendXMLEdit.Text := OpenFileDialog.FileName;
		end;
		OpenFileDialog.Free;
	end else begin
		cNewPath := SendXMLEdit.Text;
		if SelectDirectory( 'Küldött XML fájlok helye', ExtractFileDrive( cNewPath ), cNewPath, [sdNewUI, sdNewFolder]) then begin
			SendXMLEdit.Text := cNewPath;
		end;
	end;
end;

procedure TSettingsForm.DBFFileButtonClick(Sender: TObject);
var
	OpenFileDialog							: TFileOpenDialog;
	OpenDialog								: TOpenDialog;
begin
	if Win32MajorVersion >= 6 then begin
		OpenFileDialog := TFileOpenDialog.Create( nil );
		OpenFileDialog.Title := 'DBF fájl ÿútvonala';
		OpenFileDialog.Options := [ fdoStrictFileTypes, fdoPathMustExist, fdoFileMustExist, fdoForceFileSystem ];
		OpenFileDialog.OkButtonLabel := 'Kiválasztás';
		OpenFileDialog.DefaultExtension := 'DBF';
		OpenFileDialog.DefaultFolder := ExtractFilePath( DBFFileEdit.Text );
		OpenFileDialog.FileName := ExtractFileName( DBFFileEdit.Text );
		if OpenFileDialog.Execute then begin
			DBFFileEdit.Text := OpenFileDialog.FileName;
		end;
		OpenFileDialog.Free;
	end else begin
		OpenDialog := TOpenDialog.Create( Self );
		OpenDialog.Title := 'DBF fájl ÿútvonala';
		OpenDialog.Options := [ ofFileMustExist ];
		OpenDialog.Filter := 'dBase file| *.DBF';
		OpenDialog.FilterIndex := 1;
		OpenDialog.FileName := ExtractFileName( DBFFileEdit.Text );
		if OpenDialog.Execute then begin
			DBFFileEdit.Text := OpenDialog.FileName;
		end;
		OpenDialog.Free;
	end;
end;

procedure TSettingsForm.LogPathButtonClick(Sender: TObject);
var
	OpenFileDialog							: TFileOpenDialog;
	cNewPath									: string;
begin
	if Win32MajorVersion >= 6 then begin
		OpenFileDialog := TFileOpenDialog.Create( nil );
		OpenFileDialog.Title := 'Log fájlok helye';
		OpenFileDialog.Options := [ fdoPickFolders, fdoPathMustExist, fdoForceFileSystem ];
		OpenFileDialog.OkButtonLabel := 'Kiválasztás';
		OpenFileDialog.DefaultFolder := LogPathEdit.Text;
		OpenFileDialog.FileName := LogPathEdit.Text;
		if OpenFileDialog.Execute then begin
			LogPathEdit.Text := OpenFileDialog.FileName;
		end;
		OpenFileDialog.Free;
	end else begin
		cNewPath := LogPathEdit.Text;
		if SelectDirectory( 'Log fájlok helye', ExtractFileDrive( cNewPath ), cNewPath, [sdNewUI, sdNewFolder]) then begin
			LogPathEdit.Text := cNewPath;
		end;
	end;
end;

procedure TSettingsForm.LogLevelBarChange(Sender: TObject);
begin
	ActLogLevelLabel.Caption := IntToStr( LogLevelBar.Position );
end;

procedure TSettingsForm.GridRefreshBarChange(Sender: TObject);
begin
	ActGridRefreshLabel.Caption := IntToStr( GridRefreshBar.Position ) + ' másodperc';
end;

procedure TSettingsForm.DBFRefreshBarChange(Sender: TObject);
begin
	ActDBFRefreshLabel.Caption := IntToStr( DBFRefreshBar.Position + 5 ) + ' másodperc';
end;

procedure TSettingsForm.DeleteFilesBarChange(Sender: TObject);
begin
	ActDeleteFilesLabel.Caption := IntToStr( DeleteFilesBar.Position + 1 ) + ' nap';
end;

procedure TSettingsForm.MessageTimeBarChange(Sender: TObject);
begin
	ActMessageTimeLabel.Caption := IntToStr( MessageTimeBar.Position ) + ' másodperc';
end;

procedure TSettingsForm.NewButtonClick(Sender: TObject);
begin
	AddressGrid.RowCount := AddressGrid.RowCount + 1;
	AddressGrid.Cells[ 0,AddressGrid.RowCount - 1 ] := IntToStr( AddressGrid.RowCount - 1 );
	AddressGrid.Cells[ 1,AddressGrid.RowCount - 1 ] := 'teszt' + IntToStr( AddressGrid.RowCount - 1 );
	AddressGrid.Cells[ 2,AddressGrid.RowCount - 1 ] := 'feri' + IntToStr( AddressGrid.RowCount - 1 );
	DeleteButton.Enabled := ( AddressGrid.RowCount > 2 );
end;

procedure TSettingsForm.DeleteButtonClick(Sender: TObject);
var
	I										: integer;
begin
	for I := AddressGrid.Selection.Top to AddressGrid.RowCount - 1 do begin
		AddressGrid.Cells[ 1,I ] := AddressGrid.Cells[ 1,I + 1 ];
		AddressGrid.Cells[ 2,I ] := AddressGrid.Cells[ 2,I + 1 ];
	end;
	AddressGrid.RowCount := AddressGrid.RowCount - 1;
	DeleteButton.Enabled := ( AddressGrid.RowCount > 2 );
end;

end.
