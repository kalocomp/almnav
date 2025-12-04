unit Delete;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, AdvProgressBar;

const
	acDirectoryNames : array[ 1..4 ] of string = ( 'LOG','PDF','Elküldött','Fogadott' );

type
	TDeleteForm = class(TForm)
		DirectoryBar: TAdvProgressBar;
		DirectoryLabel: TLabel;
		DeleteDateLabel: TLabel;
		FileNameLabel: TLabel;
	 procedure FormCreate(Sender: TObject);
	private
{ Private declarations }
	public
{ Public declarations }
		procedure DeletingOldFiles;
	end;

var
	DeleteForm: TDeleteForm;

implementation

{$R *.dfm}

uses Main, NAV, XMLHandler, DateUtils;

procedure TDeleteForm.DeletingOldFiles;
var
	dOldDate								: TDateTime;
	OldFileSearch						: TSearchRec;
	acPath								: array[ 1..4 ] of string;
	I,J,nTest,nDeletedFiles			: integer;
begin
	if MainForm.Showing then begin
		DeleteForm.Visible := TRUE;
		DeleteForm.Show;
		Application.ProcessMessages;
	end;
	MainForm.MainTimer.Enabled := FALSE;
	dOldDate := IncDay( Now, - MainForm.NAVASzSettings.nDeleteDay );
	nDeletedFiles := 0;
	WriteLogFile( 'Régi fájlok törlése indul (' + FormatDateTime( 'YYYY.MM.DD', dOldDate) + ')',1 );
	DeleteDateLabel.Caption := 'A törlendõ fájlok dátuma : ' + FormatDateTime( 'YYYY.MM.DD', dOldDate );
	acPath[ 1 ] := MainForm.AppSettings.cLogPath;
	acPath[ 2 ] := MainForm.cAppPath + '\pdf';
	acPath[ 3 ] := MainForm.AppSettings.cSendPath;
	acPath[ 4 ] := MainForm.AppSettings.cReceivePath;
	for I := 1 to 4 do begin
		DirectoryLabel.Caption := acDirectoryNames[ I ] + ' fájlok könyvtára';
		if FindFirst( acPath[ I ] + '\*.*', faAnyFile, OldFileSearch ) = 0 then begin
			repeat
				FileNameLabel.Caption := OldFileSearch.Name;
				if OldFileSearch.Attr <> faDirectory then begin
					if OldFileSearch.TimeStamp < dOldDate then begin
						if FileExists( acPath[ I ] + '\' + OldFileSearch.Name ) then begin
							DeleteFile( acPath[ I ] + '\' + OldFileSearch.Name );
							WriteLogFile( acPath[ I ] + '\' + OldFileSearch.Name + ' (' + FormatDateTime( 'YYYY.MM.DD', OldFileSearch.TimeStamp ) + ') fájl törölve.',4 );
							Inc( nDeletedFiles );
						end;
					end;
				end;
				Application.ProcessMessages;
			until FindNext( OldFileSearch ) <> 0;
		end;
		DirectoryBar.Position := I;
	end;
	WriteLogFile( IntToStr( nDeletedFiles ) + 'db régi fájl törölve.',1 );
	MainForm.dLastDelete := Now;
	if MainForm.Showing then begin
		DeleteForm.Visible := FALSE;;
		DeleteForm.Hide;
	end;
	MainForm.MainTimer.Enabled := TRUE;
end;

procedure TDeleteForm.FormCreate(Sender: TObject);
begin
	DeleteForm.DeletingOldFiles;
end;

end.
