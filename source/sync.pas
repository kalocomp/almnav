unit sync;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.StdCtrls, IBX.IB, FireDAC.Phys.MySQLWrapper,
  GradientLabel, Vcl.Grids, AdvObj, BaseGrid, AdvGrid, syncsetting, Data.DB,
  Vcl.DBGrids;

type
  TSyncForm = class(TForm)
		SyncGrid: TAdvStringGrid;
		GradientLabel1: TGradientLabel;
		StartButton: TButton;
		NAVButton: TButton;
		DBGrid1: TDBGrid;
    SQLButton: TButton;
		NAVSource: TDataSource;
		procedure FormShow(Sender: TObject);
		procedure StartButtonClick(Sender: TObject);
		procedure SyncGridCheckBoxClick(Sender: TObject; ACol, ARow: Integer; State: Boolean);
		procedure SyncGridGetAlignment(Sender: TObject; ARow, ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
		procedure NAVButtonClick(Sender: TObject);
		procedure SQLButtonClick(Sender: TObject);
	private
{ Private declarations }
		cSQL : string;
		function MyFBSQLSelect( cInSQL : string ) : boolean;
		function MyFBSQLCommand( cInSQL : string ) : boolean;
		function MyMySQLSelect( cInSQL : string ) : boolean;
		function MyMySQLCommand( cInSQL : string ) : boolean;
		function MyMySQLCommandCommit( cInSQL : string ) : boolean;
	public
{ Public declarations }
		procedure Syncing;
		procedure SyncingItem( InSyncItem : TSyncItem );
		procedure UploadLinzer( InSyncItem : TSyncItem );
		procedure DownloadLinzer( InSyncItem : TSyncItem );
	end;

var
	SyncForm: TSyncForm;

implementation

uses nav, main, xmlhandler, kontir, System.StrUtils, System.DateUtils;

{$R *.dfm}

procedure TSyncForm.FormShow(Sender: TObject);
var
	I												: integer;
begin
	SetMySettings;
	if ( MainForm.SyncSettings.SyncItems.Count = 0 ) then begin
		MessageDlg( 'Nincs sznkronizálandó adat beállítva !!!', mtWarning, [ mbOK ], 0);
	end else begin
		SyncGrid.FixedCols := 0;
		SyncGrid.ColCount := 4;
		SyncGrid.ColWidths[ 0 ] := SyncGrid.Width div 8;
		SyncGrid.ColWidths[ 1 ] := SyncGrid.Width div 3;
		SyncGrid.ColWidths[ 2 ] := SyncGrid.Width div 5;
		SyncGrid.ColWidths[ 3 ] := SyncGrid.Width div 6;
		SyncGrid.RowCount := MainForm.SyncSettings.SyncItems.Count + 1;
		SyncGrid.FixedRows := 1;
//		SyncGrid.ShowSelection := FALSE;
		SyncGrid.Cells[ 0,0 ] := 'Actív';
		SyncGrid.Cells[ 1,0 ] := 'Megnevezés';
		SyncGrid.Cells[ 2,0 ] := 'Utolsó aktivitás';
		SyncGrid.Cells[ 3,0 ] := 'Könyvelési év';
		for I := 0 to MainForm.SyncSettings.SyncItems.Count - 1 do begin
			SyncGrid.AddCheckBox( 0, I + 1, ( MainForm.SyncSettings.SyncItems[ I ].Active ), FALSE );
			SyncGrid.Cells[ 1,I + 1 ] := MainForm.SyncSettings.SyncItems.Items[ I ].Name;
			SyncGrid.Cells[ 2,I + 1 ] := FormatDateTime( 'YYYY.MM.DD hh:mm', MainForm.SyncSettings.LastRead );
			SyncGrid.Cells[ 3,I + 1 ] := IntToStr( MainForm.SyncSettings.SyncItems.Items[ I ].ActYear );
		end;
		MainForm.DBFTable1.Close;
	end;
end;

procedure TSyncForm.StartButtonClick(Sender: TObject);
begin
	if ( MainForm.SyncSettings.SyncItems.Count > 0 ) then begin
		SyncingItem( MainForm.SyncSettings.SyncItems.Items[ SyncForm.SyncGrid.Selection.Top - 1 ]);
	end;
end;

function TSyncForm.MyFBSQLSelect( cInSQL : string ) : boolean;
begin
	Result := TRUE;
	if Length( cInSQL ) > 0 then begin
		WriteLogFile( 'SQL Select : ' + cInSQL, 4 );
		try
			if MainForm.SyncFBTransaction.InTransaction then begin
				MainForm.SyncFBTransaction.CommitRetaining;
			end;
			Result := TRUE;
			MainForm.SyncFBQuery.Transaction := MainForm.SyncFBTransaction;
			MainForm.SyncFBQuery.Close;
			MainForm.SyncFBQuery.SQL.Clear;
			MainForm.SyncFBQuery.SQL.Add( cInSQL );
			MainForm.SyncFBQuery.Open;
			MainForm.SyncFBTransaction.CommitRetaining;
		except
			on E: Exception do begin
				if ( E is EIBInterbaseError ) then begin
					WriteLogFile( 'A kovetkező parancs nem hajtható végre :' + cInSQL, 4 );
					WriteLogFile( 'SQL hiba : ' + EIBInterbaseError( E ).Message, 2 );
				end;
				Result := FALSE;
			end;
		end;
	end;
end;

function TSyncForm.MyFBSQLCommand( cInSQL : string ) : boolean;
var
	nPos					: integer;
begin
	WriteLogFile( 'SQL Command : ' + cInSQL, 4 );
	Result := TRUE;
	try
		try
			MainForm.SyncFBCommand.Transaction := MainForm.SyncFBTransaction;
			MainForm.SyncFBCommand.Transaction.Active := TRUE;
			MainForm.SyncFBCommand.SQL.Clear;
			MainForm.SyncFBCommand.SQL.Add( cInSQL );
			MainForm.SyncFBCommand.ExecSQL;
			MainForm.SyncFBTransaction.CommitRetaining;
			MainForm.SyncFBCommand.Transaction := NIL;
		except
			on E: Exception do begin
				if ( E is EIBInterbaseError ) then begin
					WriteLogFile( 'A kovetkező parancs nem hajtható végre :' + cInSQL, 4 );
					WriteLogFile( 'SQL hiba : ' + EIBInterbaseError( E ).Message, 2 );
				end;
				if ( E is EIBClientError ) then begin
					WriteLogFile( 'A kovetkező parancs nem hajtható végre :' + cInSQL, 4 );
					WriteLogFile( 'SQL hiba : ' + EIBClientError( E ).Message, 2 );
				end;
				Result := FALSE;
			end;
		end;
	finally
		MainForm.SyncFBCommand.Close;
	end;
end;

function TSyncForm.MyMySQLSelect( cInSQL : string ) : boolean;
begin
	Result := TRUE;
	if Length( cInSQL ) > 0 then begin
		WriteLogFile( 'SQL Select : ' + cInSQL, 4 );
		try
			if MainForm.SyncMySQLTransaction.Active then begin
				MainForm.SyncMySQLTransaction.CommitRetaining;
			end;
			Result := TRUE;
			MainForm.SyncMySQLQuery.Transaction := MainForm.SyncMySQLTransaction;
			MainForm.SyncMySQLQuery.Transaction.StartTransaction;
			MainForm.SyncMySQLQuery.Close;
			MainForm.SyncMySQLQuery.SQL.Clear;
			MainForm.SyncMySQLQuery.SQL.Add( cInSQL );
			MainForm.SyncMySQLQuery.Open;
			MainForm.SyncMySQLTransaction.CommitRetaining;
		except
			on E: Exception do begin
				if ( E is EMySQLNativeException ) then begin
					WriteLogFile( 'A kovetkező parancs nem hajtható végre :' + cInSQL, 4 );
					WriteLogFile( 'SQL hiba : ' + EMySQLNativeException( E ).Message, 2 );
				end;
				Result := FALSE;
			end;
		end;
	end;
end;

function TSyncForm.MyMySQLCommand( cInSQL : string ) : boolean;
var
	nPos					: integer;
begin
	WriteLogFile( 'SQL Command : ' + cInSQL, 4 );
	Result := TRUE;
	try
		try
			MainForm.SyncMySQLCommand.SQL.Clear;
			MainForm.SyncMySQLCommand.SQL.Add( cInSQL );
			MainForm.SyncMySQLCommand.ExecSQL;
		except
			on E: Exception do begin
				if ( E is EMySQLNativeException ) then begin
					WriteLogFile( 'A kovetkező parancs nem hajtható végre :' + cInSQL, 4 );
					WriteLogFile( 'SQL hiba : ' + EMySQLNativeException( E ).Message, 2 );
				end;
				Result := FALSE;
			end;
		end;
	finally
		MainForm.SyncMySQLCommand.Close;
	end;
end;

function TSyncForm.MyMySQLCommandCommit( cInSQL : string ) : boolean;
var
	nPos					: integer;
begin
	WriteLogFile( 'SQL Command : ' + cInSQL, 4 );
	Result := TRUE;
	if MainForm.SyncMySQLCommand.Active then begin
		MainForm.SyncMySQLCommand.Close;
	end;
	try
		try
			if MainForm.SyncMySQLTransaction.Active then begin
				MainForm.SyncMySQLTransaction.Commit;
			end;
			MainForm.SyncMySQLTransaction.StartTransaction;
			MainForm.SyncMySQLCommand.Transaction := MainForm.SyncMySQLTransaction;
			MainForm.SyncMySQLCommand.SQL.Clear;
			MainForm.SyncMySQLCommand.SQL.Add( cInSQL );
			MainForm.SyncMySQLCommand.ExecSQL;
			MainForm.SyncMySQLTransaction.Commit;
		except
			on E: Exception do begin
				if ( E is EMySQLNativeException ) then begin
					WriteLogFile( 'A kovetkező parancs nem hajtható végre :' + cInSQL, 4 );
					WriteLogFile( 'SQL hiba : ' + EMySQLNativeException( E ).Message, 2 );
				end;
				Result := FALSE;
			end;
		end;
	finally
		MainForm.SyncMySQLCommand.Close;
	end;
end;

procedure TSyncForm.SyncGridCheckBoxClick(Sender: TObject; ACol, ARow: Integer;
	State: Boolean);
begin
	if ( ACol = 0 ) then begin
		MainForm.SyncSettings.SyncItems[ ARow - 1 ].Active := State;
	end;
end;

procedure TSyncForm.SyncGridGetAlignment(Sender: TObject; ARow, ACol: Integer;
	var HAlign: TAlignment; var VAlign: TVAlignment);
begin
	if ( ACol = 0 ) then begin
		HAlign := taCenter;
	end;
end;

procedure TSyncForm.Syncing;
var
	I											: integer;
begin
	WriteLogFile( 'Szinkronizálás megezdve.',4 );
	for I := 0 to MainForm.SyncSettings.SyncItems.Count - 1 do begin
		if ( MainForm.SyncSettings.SyncItems.Items[ I ].Active ) then begin
			Self.SyncingItem( MainForm.SyncSettings.SyncItems.Items[ I ] );
		end;
		MainForm.SyncSettings.LastRead := Now;
	end;
	WriteLogFile( 'Szinkronizálás befejezve.',4 );
end;

procedure TSyncForm.SyncingItem( InSyncItem: TSyncItem );
var
	lConnected							: boolean;
begin
	lConnected := FALSE;
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird adatbázist használunk
		if Length( InSyncItem.SQLServer ) = 0 then begin
			MainForm.SyncFBDatabase.DatabaseName := InSyncItem.SQLFileName;
		end else begin
			if InSyncItem.SQLPort <> '' then begin
				MainForm.SyncFBDatabase.DatabaseName := InSyncItem.SQLServer + '/' + InSyncItem.SQLPort + ':' + InSyncItem.SQLFileName;
			end else begin
				MainForm.SyncFBDatabase.DatabaseName := InSyncItem.SQLServer + ':' + InSyncItem.SQLFileName;
			end;
		end;
		MainForm.SyncFBDatabase.Params.Clear;
		MainForm.SyncFBDatabase.Params.Add( 'user_name=' + InSyncItem.SQLUser );
		MainForm.SyncFBDatabase.Params.Add( 'password=' + InSyncItem.SQLPassword );
		MainForm.SyncFBDatabase.Params.Add( 'lc_ctype=win1250' );
		try
			MainForm.SyncFBDatabase.Close;
			MainForm.SyncFBDatabase.Open;
			if ( MainForm.SyncFBDatabase.Connected ) then begin
				lConnected := TRUE;
			end;
		except
			on E : EDatabaseError do begin
				WriteLogFile( 'Adatbázis hibás megynyiása.' + MainForm.SyncFBDatabase.DatabaseName,2 );
				MainForm.SyncFBTransaction.Active := FALSE;
				MainForm.SyncFBDatabase.Close;
			end;
		end;
	end else begin
// Ha MySQL adatbázist használunk
		MainForm.SyncMySQLConnection.Params.Clear;
		MainForm.SyncMySQLConnection.Params.Add( 'DriverID=MySQL' );
		MainForm.SyncMySQLConnection.Params.Add( 'Server=' + InSyncItem.SQLServer );
		MainForm.SyncMySQLConnection.Params.Add( 'User_Name=' + InSyncItem.SQLUser );
		MainForm.SyncMySQLConnection.Params.Add( 'Password=' + InSyncItem.SQLPassword );
		MainForm.SyncMySQLConnection.Params.Add( 'Database=' + InSyncItem.SQLFileName );
		MainForm.SyncMySQLConnection.Params.Add( 'Port=' + InSyncItem.SQLPort );
		MainForm.SyncMySQLConnection.Params.Add( 'CharacterSet=utf8mb4' );
		try
			MainForm.SyncMySQLConnection.Close;
			MainForm.SyncMySQLConnection.Open;
			if ( MainForm.SyncMySQLConnection.Connected ) then begin
				lConnected := TRUE;
			end;
		except
			on E : EDatabaseError do begin
				WriteLogFile( 'Adatbázis hibás megynyiása.' + MainForm.SyncMySQLConnection.Params.Database,2 );
				MainForm.SyncMySQLConnection.Connected := FALSE;
				MainForm.SyncMySQLConnection.Close;
			end;
		end;
	end;
	if ( lConnected ) then begin
		case ( InSyncItem.SessionType ) of
			st_UploadLinzer : begin
				WriteLogFile( 'Adatbázis megynyitva: ' + MainForm.SyncFBDatabase.DatabaseName, 4 );
				UploadLinzer( InSyncItem );
			end;
			st_DownloadLinzer : begin
				WriteLogFile( 'Adatbázis megynyitva: ' + InSyncItem.SQLServer, 4 );
				DownloadLinzer( InSyncItem );
			end;
		end;
	end;
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird adatbázist használunk
		MainForm.SyncFBTransaction.Active := FALSE;
		MainForm.SyncFBDatabase.Close;
	end else begin
		MainForm.SyncMySQLConnection.Close;
	end;
end;

procedure TSyncForm.UploadLinzer( InSyncItem: TSyncItem );
var
	cMaxSzla,cMaxBiz									: string;
	nMaxEv												: TDateTime;
	nAlap, nAFA											: double;
	nSor,nEv,nPenztar,nBiz							: integer;
begin
	StartButton.Enabled := FALSE;
// Árutörzs frissítése
	WriteLogFile( 'Linzer áruk feltöltése megkezdve.',2 );
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalYearDatabase + 'T10.DBF';
	try
		if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
			cSQL := 'SELECT * FROM "aru"';
			MyFBSQLSelect( cSQL );
		end else begin
			cSQL := 'SELECT * FROM aru';
			MyMySQLSelect( cSQL );
		end;
		MainForm.DBFTable1.Open;
		MainForm.DBFTable1.First;
		while ( not MainForm.DBFTable1.Eof ) do begin
			Application.ProcessMessages;
			WriteLogFile( 'Áru adat ellenőrzése: ' + MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString + ' (' + MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString + ')',4 );
			if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
//				cSQL := 'SELECT "aru"."kod", "aru"."nev", "aru"."szlanev", "aru"."me", "aru"."vtsz", "aru"."afakod" ' +
//					'FROM "aru" WHERE "aru"."kod" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString );
//				MyFBSQLSelect( cSQL );
//				if ( MainForm.SyncFBQuery.RecordCount <> 0 ) then begin
				if ( MainForm.SyncFBQuery.Locate( 'KOD', MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString, [])) then begin
					if (( MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10NEV2' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'SZLANEV' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10ME1' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'ME' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10VTSZAM' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'VTSZ' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10AFAKOD' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'AFAKOD' ).AsString )) then begin
						cSQL := 'UPDATE "aru" SET ' +
							'"nev" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString ) + ', ' +
							'"szlanev" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV2' ).AsString ) + ', ' +
							'"me" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10ME1' ).AsString ) + ', ' +
							'"vtsz" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10VTSZAM' ).AsString ) + ', ' +
							'"afakod" = ' + MainForm.DBFTable1.FieldByName( 'T10AFAKOD' ).AsString + ', ' +
							'"syncdat" = CURRENT_TIMESTAMP WHERE "aru"."kod" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString );
						MyFBSQLCommand( cSQL );
						WriteLogFile( 'Áru adatainak frissítése : ' + MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString + ' (' + MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString + ')',4 );
					end;
				end else begin
					cSQL := 'INSERT INTO "aru" ( "kod", "nev", "szlanev", "me", "vtsz", "afakod", "syncdat" ) VALUES ( ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV2' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10ME1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10VTSZAM' ).AsString ) + ', ' +
						MainForm.DBFTable1.FieldByName( 'T10AFAKOD' ).AsString + ', ' +
						'CURRENT_TIMESTAMP )';
					MyFBSQLCommand( cSQL );
					WriteLogFile( 'Áru adatainak beszúrása : ' + MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString + ' (' + MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString + ')',4 );
				end;
			end else begin
// Ha MYSQL szerver van
//				cSQL := 'SELECT aru.kod, aru.nev1, aru.szlanev, aru.me1, aru.vtsz, aru.afakod FROM aru ' +
//					'WHERE aru.kod = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString );
//				MyMySQLSelect( cSQL );
//				if ( MainForm.SyncMySQLQuery.RecordCount <> 0 ) then begin
				if ( MainForm.SyncMySQLQuery.Locate( 'KOD', MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString, [])) then begin
					if (( MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10NEV2' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'SZLANEV' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10ME1' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'ME1' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10VTSZAM' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'VTSZ' ).AsString ) or
						( MainForm.DBFTable1.FieldByName( 'T10AFAKOD' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'AFAKOD' ).AsString )) then begin
						cSQL := 'UPDATE aru SET ' +
							'nev1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString ) + ', ' +
							'szlanev = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV2' ).AsString ) + ', ' +
							'me1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10ME1' ).AsString ) + ', ' +
							'vtsz = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10VTSZAM' ).AsString ) + ', ' +
							'afakod = ' + MainForm.DBFTable1.FieldByName( 'T10AFAKOD' ).AsString + ', ' +
							'syncdat = CURRENT_TIMESTAMP WHERE aru.kod = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString );
						MyMySQLCommandCommit( cSQL );
						WriteLogFile( 'Áru adatainak frissítése : ' + MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString + ' (' + MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString + ')',4 );
					end;
				end else begin
					cSQL := 'INSERT INTO aru ( kod, nev1, szlanev, me1, vtsz, afakod, syncdat ) VALUES ( ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10NEV2' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10ME1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T10VTSZAM' ).AsString ) + ', ' +
						MainForm.DBFTable1.FieldByName( 'T10AFAKOD' ).AsString + ', ' +
						'CURRENT_TIMESTAMP )';
					MyMySQLCommandCommit( cSQL );
					WriteLogFile( 'Áru adatainak beszúrása : ' + MainForm.DBFTable1.FieldByName( 'T10NEV' ).AsString + ' (' + MainForm.DBFTable1.FieldByName( 'T10KOD' ).AsString + ')',4 );
				end;
			end;
			MainForm.DBFTable1.Next;
		end;
		WriteLogFile( 'Áruk adatainak frissítése kész. ',2 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'T10.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;
	MainForm.DBFTable1.Close;
// Partner törzs frissítése
	WriteLogFile( 'Linzer partnerek feltöltése megkezdve.',2 );
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalYearDatabase + 'T20.DBF';
	try
		if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
			cSQL := 'UPDATE "syncdate" SET "syncdate"."lastupload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'aru' );
			MyFBSQLCommand( cSQL );
			cSQL := 'SELECT * FROM "partner"';
			MyFBSQLSelect( cSQL );
		end else begin
			cSQL := 'UPDATE syncdate SET syncdate.lastupload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'aru' );
			MyMySQLCommandCommit( cSQL );
			cSQL := 'SELECT * FROM partner';
			MyMySQLSelect( cSQL );
		end;
		MainForm.DBFTable1.Open;
		MainForm.DBFTable1.First;
		while ( not MainForm.DBFTable1.Eof ) do begin
			Application.ProcessMessages;
			if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
//				cSQL := 'SELECT * FROM "partner" WHERE "partner"."kod" = ' + MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString;
//				MyFBSQLSelect( cSQL );
//				if ( MainForm.SyncFBQuery.RecordCount <> 0 ) then begin
				if ( MainForm.SyncFBQuery.Locate( 'KOD', MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString, [])) then begin
					if ( MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString = MainForm.SyncFBQuery.FieldByName( 'ADOSZAM' ).AsString ) then begin
						if (( MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20SZLANEV' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'SZLANEV' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20ORSZAG1' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'ORSZAG' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20IRSZAM1' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'IRSZAM' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20UTCA1' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'UTCA' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20UTTIP1' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'UTTIP' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20HAZ1' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'HAZ' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20FIZMOD' ).AsInteger <> MainForm.SyncFBQuery.FieldByName( 'FIZMOD' ).AsInteger ) or
							( MainForm.DBFTable1.FieldByName( 'T20NAPOK' ).AsInteger <> MainForm.SyncFBQuery.FieldByName( 'NAPOK' ).AsInteger ) or
							( MainForm.DBFTable1.FieldByName( 'T20NAVTIP' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'NAVTIP' ).AsString )) then begin
							cSQL := 'UPDATE "partner" SET ' +
								'"nev" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString ) + ', ' +
								'"szlanev" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20SZLANEV' ).AsString ) + ', ' +
								'"orszag" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ORSZAG1' ).AsString ) + ', ' +
								'"irszam" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20IRSZAM1' ).AsString ) + ', ' +
								'"utca" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTCA1' ).AsString ) + ', ' +
								'"uttip" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTTIP1' ).AsString ) + ', ' +
								'"haz" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20HAZ1' ).AsString ) + ', ' +
								'"fizmod" = ' + MainForm.DBFTable1.FieldByName( 'T20FIZMOD' ).AsString + ', ' +
								'"napok" = ' + MainForm.DBFTable1.FieldByName( 'T20NAPOK' ).AsString + ', ' +
								'"adoszam" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString ) + ', ' +
								'"navtip" = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NAVTIP' ).AsString ) + ', ' +
								'"syncdat" = CURRENT_TIMESTAMP WHERE "partner"."kod" = ' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger );
							MyFBSQLCommand( cSQL );
							WriteLogFile( 'Partner adatainak frissítése : ' + MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString + ' (' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger ) + ')',4 );
						end;
					end else begin
						WriteLogFile( 'Nem eggyező adószám (' + MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString + ' - ' + MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString + ' - ' +
							MainForm.SyncFBQuery.FieldByName( 'ADOSZAM' ).AsString + ' - ' + MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString + ')',2 );
					end;
				end else begin
					cSQL := 'INSERT INTO "partner" ( "kod", "nev", "szlanev", "orszag", "irszam", "utca", "uttip", "haz", "fizmod", "napok", "adoszam", "navtip", "syncdat" ) VALUES ( ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20SZLANEV' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ORSZAG1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20IRSZAM1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTCA1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTTIP1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20HAZ1' ).AsString ) + ', ' +
						MainForm.DBFTable1.FieldByName( 'T20FIZMOD' ).AsString + ', ' +
						MainForm.DBFTable1.FieldByName( 'T20NAPOK' ).AsString + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NAVTIP' ).AsString ) + ', ' +
						'CURRENT_TIMESTAMP )';
					MyFBSQLCommand( cSQL );
					WriteLogFile( 'Partner adatainak beszúrása : ' + MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString + ' (' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger ) + ')',4 );
				end;
			end else begin
// Ha MySQL szerver van
//				cSQL := 'SELECT * FROM partner WHERE partner.kod = ' + MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString;
//				MyMySQLSelect( cSQL );
//				if ( MainForm.SyncMySQLQuery.RecordCount <> 0 ) then begin
				if ( MainForm.SyncMySQLQuery.Locate( 'KOD', MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString, [])) then begin
					if ( MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString = MainForm.SyncMySQLQuery.FieldByName( 'ADOSZAM' ).AsString ) then begin
						if (( MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20SZLANEV' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'SZLANEV' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20ORSZAG1' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'ORSZAG1' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20IRSZAM1' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'IRSZAM1' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20UTCA1' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'UTCA1' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20UTTIP1' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'UTTIP1' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20HAZ1' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'HAZ1' ).AsString ) or
							( MainForm.DBFTable1.FieldByName( 'T20FIZMOD' ).AsInteger <> MainForm.SyncMySQLQuery.FieldByName( 'FIZMOD1' ).AsInteger ) or
							( MainForm.DBFTable1.FieldByName( 'T20NAPOK' ).AsInteger <> MainForm.SyncMySQLQuery.FieldByName( 'NAPOK1' ).AsInteger ) or
							( MainForm.DBFTable1.FieldByName( 'T20NAVTIP' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'NAVTIP' ).AsString )) then begin
							if ( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString = '2328' ) then begin
							cSQL := 'UPDATE partner SET ' +
								'nev1 = ' + QuotedStr( 'RONI ABC KFT. WESSELENYI u. 7.' ) + ', ' +
								'szlanev = ' + QuotedStr( 'RONI ABC' ) + ', ' +
								'orszag1 = ' + QuotedStr( 'HU' ) + ', ' +
								'irszam1 = ' + QuotedStr( 'HU6300' ) + ', ' +
								'utca1 = ' + QuotedStr( 'Harap' ) + ', ' +
								'uttip1 = ' + QuotedStr( 'utca' ) + ', ' +
								'haz1 = ' + QuotedStr( '3.' ) + ', ' +
								'fizmod1 = 1, ' +
								'napok1 = 10, ' +
								'adoszam = ' + QuotedStr( '14116775444' ) + ', ' +
								'navtip = ' + QuotedStr( '1' ) + ', ' +
								'syncdat = CURRENT_TIMESTAMP WHERE partner.kod = ' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger );
							end else begin
							cSQL := 'UPDATE partner SET ' +
								'nev1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString ) + ', ' +
								'szlanev = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20SZLANEV' ).AsString ) + ', ' +
								'orszag1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ORSZAG1' ).AsString ) + ', ' +
								'irszam1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20IRSZAM1' ).AsString ) + ', ' +
								'utca1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTCA1' ).AsString ) + ', ' +
								'uttip1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTTIP1' ).AsString ) + ', ' +
								'haz1 = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20HAZ1' ).AsString ) + ', ' +
								'fizmod1 = ' + MainForm.DBFTable1.FieldByName( 'T20FIZMOD' ).AsString + ', ' +
								'napok1 = ' + MainForm.DBFTable1.FieldByName( 'T20NAPOK' ).AsString + ', ' +
								'adoszam = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString ) + ', ' +
								'navtip = ' + QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NAVTIP' ).AsString ) + ', ' +
								'syncdat = CURRENT_TIMESTAMP WHERE partner.kod = ' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger );
							end;
							MyMySQLCommandCommit( cSQL );
							WriteLogFile( 'Partner adatainak frissítése : ' + MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString + ' (' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger ) + ')',4 );
						end;
					end else begin
						WriteLogFile( 'Nem eggyező adószám (' + MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString + ' - ' + MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString + ' - ' +
							MainForm.SyncMySQLQuery.FieldByName( 'ADOSZAM' ).AsString + ' - ' + MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString + ')',2 );
					end;
				end else begin
					cSQL := 'INSERT INTO partner ( kod, nev1, szlanev, orszag1, irszam1, utca1, uttip1, haz1, fizmod1, napok1, adoszam, navtip, syncdat ) VALUES ( ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsString ) + ', ' +
						QuotedStr( PadR( MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString, 50, ' ' )) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20SZLANEV' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ORSZAG1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20IRSZAM1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTCA1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20UTTIP1' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20HAZ1' ).AsString ) + ', ' +
						MainForm.DBFTable1.FieldByName( 'T20FIZMOD' ).AsString + ', ' +
						MainForm.DBFTable1.FieldByName( 'T20NAPOK' ).AsString + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20ADO' ).AsString ) + ', ' +
						QuotedStr( MainForm.DBFTable1.FieldByName( 'T20NAVTIP' ).AsString ) + ', ' +
						'CURRENT_TIMESTAMP )';
					MyMySQLCommandCommit( cSQL );
					WriteLogFile( 'Partner adatainak beszúrása : ' + MainForm.DBFTable1.FieldByName( 'T20NEV' ).AsString + ' (' + IntToStr( MainForm.DBFTable1.FieldByName( 'T20KOD' ).AsInteger ) + ')',4 );
				end;
			end;
			MainForm.DBFTable1.Next;
		end;
		WriteLogFile( 'Partnerek adatainak frissítése kész. ',2 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'T20.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;
	MainForm.DBFTable1.Close;
// Meghatározzuk a legutolsó feltöltött számla számát
	WriteLogFile( 'Linzer számlák feltöltése megkezdve.',2 );
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'UPDATE "syncdate" SET "syncdate"."lastupload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'partner' );
		MyFBSQLCommand( cSQL );
		cSQL := 'SELECT MAX( "szlafej"."szlaszam" ) AS MAXSZLA FROM "szlafej" WHERE "szlafej"."ev" = ' + IntToStr( InSyncItem.ActYear );
		MyFBSQLSelect( cSQL );
		cMaxSzla := MainForm.SyncFBQuery.FieldByName( 'MAXSZLA' ).AsString;
	end else begin
// Ha MySQL szerver van
		cSQL := 'UPDATE syncdate SET syncdate.lastupload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'partner' );
		MyMySQLCommandCommit( cSQL );
		cSQL := 'SELECT MAX( szlafej.szlaszam ) AS MAXSZLA FROM szlafej WHERE szlafej.ev = ' + IntToStr( InSyncItem.ActYear );
		MyMySQLSelect( cSQL );
		cMaxSzla := MainForm.SyncMySQLQuery.FieldByName( 'MAXSZLA' ).AsString;
	end;
	MainForm.SyncMySQLCommand.Transaction := MainForm.SyncMySQLTransaction;
	WriteLogFile( 'Legutolsó számlaszám (fej): ' + cMaxSzla,4 );
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalYearDatabase + 'F13.DBF';
	MainForm.DBFTable1.Exclusive := FALSE;
	MainForm.DBFTable2.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable2.TableName := InSyncItem.LocalYearDatabase + 'F30.DBF';
	MainForm.DBFTable2.Exclusive := FALSE;
	try
		MainForm.DBFTable1.Active := TRUE;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalYearDatabase + 'F131.NTX' );
		MainForm.DBFTable2.Active := TRUE;
		MainForm.DBFTable2.CloseIndexes;
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalYearDatabase + 'F301.NTX' );
		WriteLogFile( 'Linzer számla fejrészek feltöltése megkezdve.',4 );
		MainForm.DBFTable1.OEMTranslate := FALSE;
		MainForm.AlmiraEnv.SetSoftSeek( TRUE );
		MainForm.DBFTable1.Seek( cMaxSzla );
		MainForm.DBFTable1.OEMTranslate := TRUE;
		while ( not MainForm.DBFTable1.Eof ) do begin
			Application.ProcessMessages;
			if ( cMaxSzla < MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString ) then begin
				try
					if ( InSyncItem.SQLType = sqt_Firebird ) then begin
	// Ha Firebird szerver van
					end else begin
	// Ha MySQL szerver van
						if MainForm.SyncMySQLCommand.Active then begin
							MainForm.SyncMySQLCommand.Close;
						end;
						MainForm.SyncMySQLConnection.StartTransaction;
					end;
					nAlap := 0;
					nAFA := 0;
					nSor := 0;
					MainForm.DBFTable2.OEMTranslate := FALSE;
					MainForm.AlmiraEnv.SetSoftSeek( TRUE );
					MainForm.DBFTable2.Seek( MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString );
					MainForm.DBFTable2.OEMTranslate := TRUE;
					while (( not MainForm.DBFTable2.Eof ) and ( MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString = MainForm.DBFTable2.FieldByName( 'F30SZLA' ).AsString )) do begin
						Application.ProcessMessages;
						if ( InSyncItem.SQLType = sqt_Firebird ) then begin
	// Ha Firebird szerver van
							cSQL := 'INSERT INTO "szlasor" ( "ev", "szlaszam", "sor", "asz", "afakod", "menny", "egysar", "netto", "eng", "afa", "brutto", "megj" ) VALUES ( ' +
								IntToStr( InSyncItem.ActYear ) + ', ' +
								QuotedStr( MainForm.DBFTable2.FieldByName( 'F30SZLA' ).AsString ) + ', ' +
								MainForm.DBFTable2.FieldByName( 'F30SOR' ).AsString + ', ' +
								QuotedStr( MainForm.DBFTable2.FieldByName( 'F30ARUKOD' ).AsString ) + ', ' +
								MainForm.DBFTable2.FieldByName( 'F30AFAKOD' ).AsString + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30MENNY1' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVAR' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVNET' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVENG' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVAFA' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVBRUT' ).AsFloat ) + ', ' +
								QuotedStr( MainForm.DBFTable2.FieldByName( 'F30MEGJ' ).AsString ) + ' )';
							MyFBSQLCommand( cSQL );
						end else begin
	// Ha MySQL szerver van
							cSQL := 'INSERT INTO szlasor ( ev, szlaszam, sor, asz, afakod, menny1, egysar, netto, eng1, afa, brutto, megj1 ) VALUES ( ' +
								IntToStr( InSyncItem.ActYear ) + ', ' +
								QuotedStr( MainForm.DBFTable2.FieldByName( 'F30SZLA' ).AsString ) + ', ' +
								MainForm.DBFTable2.FieldByName( 'F30SOR' ).AsString + ', ' +
								QuotedStr( MainForm.DBFTable2.FieldByName( 'F30ARUKOD' ).AsString ) + ', ' +
								MainForm.DBFTable2.FieldByName( 'F30AFAKOD' ).AsString + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30MENNY1' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVAR' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVNET' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVENG' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVAFA' ).AsFloat ) + ', ' +
								GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F30DEVBRUT' ).AsFloat ) + ', ' +
								QuotedStr( MainForm.DBFTable2.FieldByName( 'F30MEGJ' ).AsString ) + ' )';
							MyMySQLCommandCommit( cSQL );
						end;
						nAlap := nAlap + MainForm.DBFTable2.FieldByName( 'F30DEVNET' ).AsFloat;
						nAFA := nAFA + MainForm.DBFTable2.FieldByName( 'F30DEVAFA' ).AsFloat;
						if ( nSor < MainForm.DBFTable2.FieldByName( 'F30SOR' ).AsInteger ) then nSor := MainForm.DBFTable2.FieldByName( 'F30SOR' ).AsInteger;
						WriteLogFile( 'Számla sor beszúrása : ' + MainForm.DBFTable2.FieldByName( 'F30SZLA' ).AsString,2 );
						MainForm.DBFTable2.Next;
					end;
					if ( InSyncItem.SQLType = sqt_Firebird ) then begin
	// Ha Firebird szerver van
						cSQL := 'INSERT INTO "szlafej" ( "ev", "szlaszam", "pkod", "telj", "kelt", "hatarido", "fizmod", "megj1", "megj2", "sor", "devnetto", "devafa", "netto", "afa", "eredszla", "upsyncdat" ) VALUES ( ' +
							IntToStr( InSyncItem.ActYear ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13PKOD' ).AsString ) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F13DATUM1' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F13DATUM2' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F13DATUM3' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							MainForm.DBFTable1.FieldByName( 'F13FIZMOD' ).AsString + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13MEGJ1' ).AsString ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13MEGJ2' ).AsString ) + ', ' +
							IntToStr( nSor ) + ', ' +
							GetSQLNumN( nAlap ) + ', ' +
							GetSQLNumN( nAFA ) + ', ' +
							GetSQLNumN( nAlap ) + ', ' +
							GetSQLNumN( nAFA ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13EREDSZ' ).AsString ) + ', ' +
							'CURRENT_TIMESTAMP )';
						MyFBSQLCommand( cSQL );
					end else begin
	// Ha MySQL szerver van
						cSQL := 'INSERT INTO szlafej ( ev, szlaszam, pkod, telj, kelt, hatarido, fizmod, megj1, megj2, sor, devnetto, devafa, netto, afa, eredszla, upsyncdat ) VALUES ( ' +
							IntToStr( InSyncItem.ActYear ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13PKOD' ).AsString ) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F13DATUM1' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F13DATUM2' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F13DATUM3' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							MainForm.DBFTable1.FieldByName( 'F13FIZMOD' ).AsString + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13MEGJ1' ).AsString ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13MEGJ2' ).AsString ) + ', ' +
							IntToStr( nSor ) + ', ' +
							GetSQLNumN( nAlap ) + ', ' +
							GetSQLNumN( nAFA ) + ', ' +
							GetSQLNumN( nAlap ) + ', ' +
							GetSQLNumN( nAFA ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F13EREDSZ' ).AsString ) + ', ' +
							'CURRENT_TIMESTAMP )';
						MyMySQLCommandCommit( cSQL );
					end;
					WriteLogFile( 'Számla fej beszúrása : ' + MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString,2 );
					if ( MainForm.DBFTable1.FieldByName( 'F13DEVBRUT' ).AsFloat <> nAlap + nAFA ) then begin
						WriteLogFile( 'Hibás számlaösszeg : ' + MainForm.DBFTable1.FieldByName( 'F13SZLA' ).AsString + ' (' +
							FormatFloat( '0.00', MainForm.DBFTable1.FieldByName( 'F13DEVBRUT' ).AsFloat ) + ' - ' + FormatFloat( '0.00', nAlap + nAFA ) + ')', 4 );
					end;
					if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
					end else begin
// Ha MySQL szerver van
						MainForm.SyncMySQLConnection.Commit;
						MainForm.SyncMySQLCommand.Close;
					end;
				except
					if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
					end else begin
// Ha MySQL szerver van
						MainForm.SyncMySQLConnection.Rollback;
					end;
				end;
			end;
			MainForm.DBFTable1.Next;
		end;
		WriteLogFile( 'Számlák feltöltése kész. ',2 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'F13.DBF vagy F30.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'UPDATE "syncdate" SET "syncdate"."lastupload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'szamla' );
		MyFBSQLCommand( cSQL );
	end else begin
// Ha MySQL szerver van
		cSQL := 'UPDATE syncdate SET syncdate.lastupload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'szamla' );
		MyMySQLCommandCommit( cSQL );
	end;
	MainForm.DBFTable1.Close;
	MainForm.DBFTable2.Close;
// Pénztárbizonylat feltöltés
	WriteLogFile( 'Linzer pénztárbizonylatok feltöltése megkezdve.',4 );
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'SELECT MAX( "penztarbizonylat"."kulcs" ) AS MAXBIZ FROM "penztarbizonylat"';
		MyFBSQLSelect( cSQL );
		cMaxBiz := MainForm.SyncFBQuery.FieldByName( 'MAXBIZ' ).AsString;
	end else begin
		cSQL := 'SELECT MAX( penztarbizonylat.kulcs ) AS MAXBIZ FROM penztarbizonylat';
		MyMySQLSelect( cSQL );
		cMaxBiz := MainForm.SyncMySQLQuery.FieldByName( 'MAXBIZ' ).AsString;
	end;
	nEv := InSyncItem.ActYear;
	nPenztar := 1;
	nBiz := 0;
	if ( cMaxBiz <> '' ) then begin
		nEv := StrToInt( Copy( cMaxBiz,1,4 ));
		nPenztar := StrToInt( Copy( cMaxBiz,5,2 ));
		nBiz := StrToInt( Copy( cMaxBiz,7,7 ));
	end;
	WriteLogFile( 'Legutolsó bizonylatszám (fej): ' + cMaxBiz,4 );
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalYearDatabase + 'F31.DBF';
	MainForm.DBFTable1.Exclusive := FALSE;
	MainForm.DBFTable2.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable2.TableName := InSyncItem.LocalYearDatabase + 'F32.DBF';
	MainForm.DBFTable2.Exclusive := FALSE;
	try
		WriteLogFile( 'Linzer pénztárbizonylatok feltöltése megkezdve.',4 );
		MainForm.DBFTable1.Active := TRUE;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalYearDatabase + 'F311.NTX' );
		MainForm.DBFTable2.Active := TRUE;
		MainForm.DBFTable2.CloseIndexes;
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalYearDatabase + 'F321.NTX' );
		MainForm.DBFTable1.OEMTranslate := FALSE;
		MainForm.AlmiraEnv.SetSoftSeek( TRUE );
		MainForm.DBFTable1.Seek( IntToStr( nEv ) + PadL( IntToStr( nPenztar ),2,' ' ) + PadL( IntToStr( nBiz ),7,' ' ));
		MainForm.DBFTable1.OEMTranslate := TRUE;
		while ( not MainForm.DBFTable1.Eof ) do begin
			Application.ProcessMessages;
			if ( nBiz < MainForm.DBFTable1.FieldByName( 'F31BIZSZAM' ).AsInteger ) then begin
				MainForm.Refresh;
				Application.ProcessMessages;
				nAlap := 0;
				nSor := 0;
				MainForm.DBFTable2.OEMTranslate := FALSE;
				MainForm.AlmiraEnv.SetSoftSeek( TRUE );
				MainForm.DBFTable2.Seek( MainForm.DBFTable1.FieldByName( 'F31EV' ).AsString + PadL( MainForm.DBFTable1.FieldByName( 'F31PENZTAR' ).AsString,2,' ' ) +
					PadL( MainForm.DBFTable1.FieldByName( 'F31BIZSZAM' ).AsString,7,' ' ));
				MainForm.DBFTable2.OEMTranslate := TRUE;
				while (( not MainForm.DBFTable2.Eof ) and
					( MainForm.DBFTable1.FieldByName( 'F31EV' ).AsInteger = MainForm.DBFTable2.FieldByName( 'F32EV' ).AsInteger ) and
					( MainForm.DBFTable1.FieldByName( 'F31PENZTAR' ).AsInteger = MainForm.DBFTable2.FieldByName( 'F32PENZTAR' ).AsInteger ) and
					( MainForm.DBFTable1.FieldByName( 'F31BIZSZAM' ).AsInteger = MainForm.DBFTable2.FieldByName( 'F32BIZSZAM' ).AsInteger )) do begin
					Application.ProcessMessages;
					if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
						cSQL := 'INSERT INTO "penztarbizonylat" ( "kulcs", "szlaszam", "kelt", "arfolyam", "fj", "pkod", "devforg", "forgalom", "megj", "arfkul", "syncdat" ) VALUES ( ' +
							QuotedStr( MainForm.DBFTable2.FieldByName( 'F32EV' ).AsString +
							PadL( MainForm.DBFTable2.FieldByName( 'F32PENZTAR' ).AsString,2,' ' ) +
							PadL( MainForm.DBFTable2.FieldByName( 'F32BIZSZAM' ).AsString,7,'0' ) +
							PadL( MainForm.DBFTable2.FieldByName( 'F32SOR' ).AsString,3,' ' )) + ', ' +
							QuotedStr( MainForm.DBFTable2.FieldByName( 'F32SZLA' ).AsString ) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F31KELT' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							GetSQLNumN( MainForm.DBFTable1.FieldByName( 'F31ARF' ).AsFloat ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F31FJ' ).AsString ) + ', ' +
							QuotedStr( MainForm.DBFTable2.FieldByName( 'F32PKOD' ).AsString ) + ', ' +
							GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F32DEVFORG' ).AsFloat ) + ', ' +
							GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F32FORG' ).AsFloat ) + ', ' +
							QuotedStr( LeftStr( Trim( MainForm.DBFTable2.FieldByName( 'F32KSOR' ).AsString ) + Trim( MainForm.DBFTable2.FieldByName( 'F32MEGJ' ).AsString ),30 )) + ', 0, ' +
							'CURRENT_TIMESTAMP )';
						MyFBSQLCommand( cSQL );
					end else begin
// Ha MySQL szerver van
						cSQL := 'INSERT INTO penztarbizonylat ( kulcs, szlaszam, kelt, arfolyam, fj, pkod, devforg, forgalom, megj1, arfkul, syncdat ) VALUES ( ' +
							QuotedStr( MainForm.DBFTable2.FieldByName( 'F32EV' ).AsString +
							PadL( MainForm.DBFTable2.FieldByName( 'F32PENZTAR' ).AsString,2,' ' ) +
							PadL( MainForm.DBFTable2.FieldByName( 'F32BIZSZAM' ).AsString,7,'0' ) +
							PadL( MainForm.DBFTable2.FieldByName( 'F32SOR' ).AsString,3,' ' )) + ', ' +
							QuotedStr( MainForm.DBFTable2.FieldByName( 'F32SZLA' ).AsString ) + ', ' +
							QuotedStr( GetSQLDateS( MainForm.DBFTable1.FieldByName( 'F31KELT' ).AsDateTime, InSyncItem.SQLType )) + ', ' +
							GetSQLNumN( MainForm.DBFTable1.FieldByName( 'F31ARF' ).AsFloat ) + ', ' +
							QuotedStr( MainForm.DBFTable1.FieldByName( 'F31FJ' ).AsString ) + ', ' +
							QuotedStr( MainForm.DBFTable2.FieldByName( 'F32PKOD' ).AsString ) + ', ' +
							GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F32DEVFORG' ).AsFloat ) + ', ' +
							GetSQLNumN( MainForm.DBFTable2.FieldByName( 'F32FORG' ).AsFloat ) + ', ' +
							QuotedStr( LeftStr( Trim( MainForm.DBFTable2.FieldByName( 'F32KSOR' ).AsString ) + Trim( MainForm.DBFTable2.FieldByName( 'F32MEGJ' ).AsString ),30 )) + ', 0, ' +
							'CURRENT_TIMESTAMP )';
						MyMySQLCommandCommit( cSQL );
					end;
					nAlap := nAlap + MainForm.DBFTable2.FieldByName( 'F32DEVFORG' ).AsFloat;
					if ( nSor < MainForm.DBFTable2.FieldByName( 'F32SOR' ).AsInteger ) then nSor := MainForm.DBFTable2.FieldByName( 'F32SOR' ).AsInteger;
					WriteLogFile( 'Pénztárbizonylat sor beszúrása : ' + MainForm.DBFTable2.FieldByName( 'F32BIZSZAM' ).AsString,2 );
					MainForm.DBFTable2.Next;
				end;
				if ( MainForm.DBFTable1.FieldByName( 'F31DEVFORG' ).AsFloat <> nAlap ) then begin
					WriteLogFile( 'Hibás bizonylatösszeg : ' + MainForm.DBFTable1.FieldByName( 'F31BIZSZAM' ).AsString + ' (' +
						FormatFloat( '0.00', MainForm.DBFTable1.FieldByName( 'F31DEVFORG' ).AsFloat ) + ' - ' + FormatFloat( '0.00', nAlap ) + ')', 4 );
				end;
			end;
			MainForm.DBFTable1.Next;
		end;
		if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
			cSQL := 'UPDATE "syncdate" SET "syncdate"."lastupload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'penztarbizonylat' );
			MyFBSQLCommand( cSQL );
		end else begin
// Ha MySQL szerver van
			cSQL := 'UPDATE syncdate SET syncdate.lastupload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'penztarbizonylat' );
			MyMySQLCommandCommit( cSQL );
		end;
		WriteLogFile( 'Pénztárbizonylatok frissítése kész. ',2 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'F31.DBF vagy F32.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;
	MainForm.DBFTable1.Close;
	MainForm.DBFTable2.Close;
	StartButton.Enabled := TRUE;
end;

procedure TSyncForm.NAVButtonClick(Sender: TObject);
begin
	MainForm.DBFTable1.DatabaseName := MainForm.cAppPath;
	MainForm.DBFTable1.TableName := ExtractFileName( MainForm.NAVASzSettings.cDBFPath );
	try
		MainForm.DBFTable1.OEMTranslate := TRUE;
		MainForm.DBFTable1.Open;
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a NAV.DBF állomány megnyitásakor :' + E.Message,2 );
		end;
	end;

end;

procedure TSyncForm.SQLButtonClick(Sender: TObject);
var
	InSyncItem : TSyncItem;
begin
	InSyncItem := MainForm.SyncSettings.SyncItems.Items[ 1 ];
	if Length( InSyncItem.SQLServer ) = 0 then begin
		MainForm.SyncFBDatabase.DatabaseName := InSyncItem.SQLFileName;
	end else begin
		if InSyncItem.SQLPort <> '' then begin
			MainForm.SyncFBDatabase.DatabaseName := InSyncItem.SQLServer + '/' + InSyncItem.SQLPort + ':' + InSyncItem.SQLFileName;
		end else begin
			MainForm.SyncFBDatabase.DatabaseName := InSyncItem.SQLServer + ':' + InSyncItem.SQLFileName;
		end;
	end;
	MainForm.SyncFBDatabase.Params.Clear;
	MainForm.SyncFBDatabase.Params.Add( 'user_name=' + InSyncItem.SQLUser );
	MainForm.SyncFBDatabase.Params.Add( 'password=' + InSyncItem.SQLPassword );
	MainForm.SyncFBDatabase.Params.Add( 'lc_ctype=win1250' );
	try
		MainForm.SyncFBDatabase.Close;
		MainForm.SyncFBDatabase.Open;
		if ( MainForm.SyncFBDatabase.Connected ) then begin
			WriteLogFile( 'Adatbázis megynyitva.' + MainForm.SyncFBDatabase.DatabaseName,4 );
		end;
		MainForm.SyncFBTransaction.Active := FALSE;
		MainForm.SyncFBDatabase.Close;
	except
		on E : EDatabaseError do begin
			WriteLogFile( 'Adatbázis hibás megynyiása.' + MainForm.SyncFBDatabase.DatabaseName,2 );
			MainForm.SyncFBTransaction.Active := FALSE;
			MainForm.SyncFBDatabase.Close;
		end;
	end;
end;

procedure TSyncForm.DownloadLinzer( InSyncItem: TSyncItem );
var
	nItem,nCsoport,nMaxSzla										: integer;
	cLastBiz,cNewKey												: string;
	cFKSz1,cFKSz2,cKTNem1,cKTNem2								: string;
	nRJ1,nRJ2														: integer;
	nSumAlap,nSumAFA,nLastAlap,nLastAFA						: single;
	lResult,lWriteBiz		  										: boolean;
	dUploadDate,dKonyvDat										: TDateTime;
	BizKontir				  										: TBizKontir;
begin
	BizKontir := TBizKontir.Create;
	StartButton.Enabled := FALSE;
// Árutörzs frissítése
	WriteLogFile( 'Linzer áruk letöltése megkezdve.',2 );
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalYearDatabase + 'A10.DBF';
	try
		MainForm.DBFTable1.Active := TRUE;
		MainForm.DBFTable1.Exclusive := FALSE;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalYearDatabase + 'A101.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalYearDatabase + 'A102.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalYearDatabase + 'A103.NTX' );
		MainForm.DBFTable1.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'A10.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'SELECT * FROM "aru" WHERE "aru"."syncdat" > ' +
			'( SELECT "syncdate"."lastdownload" FROM "syncdate" WHERE "syncdate"."tablename" = ' + QuotedStr( 'aru' ) + ')';
		lResult := MyFBSQLSelect( cSQL );
		if ( lResult ) and ( MainForm.SyncFBQuery.RecordCount <> 0 ) then begin
			MainForm.SyncFBQuery.First;
			nItem := 0;
			while ( not MainForm.SyncFBQuery.Eof ) do begin
// Megnézzük, hogy van-e már ilyen termék
				Application.ProcessMessages;
				cNewKey := MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString;
				MainForm.AlmiraEnv.SetSoftSeek( FALSE );
				MainForm.DBFTable1.OEMTranslate := FALSE;
				if ( MainForm.DBFTable1.Seek( cNewKey )) then begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Edit;
					WriteLogFile( 'Termék adatok módosítása: ' + cNewKey,4 );
				end else begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Append;
					MainForm.DBFTable1.FieldByName( 'ASZ' ).AsString := cNewKey;
					WriteLogFile( 'Új termék adatai : ' + cNewKey,4 );
				end;
				MainForm.DBFTable1.FieldByName( 'NEV' ).AsString := MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString;
				MainForm.DBFTable1.FieldByName( 'SZLANEV' ).AsString := MainForm.SyncFBQuery.FieldByName( 'SZLANEV' ).AsString;
				MainForm.DBFTable1.FieldByName( 'ME1' ).AsString := MainForm.SyncFBQuery.FieldByName( 'ME' ).AsString;
				MainForm.DBFTable1.FieldByName( 'VTSZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'VTSZ' ).AsString;
				MainForm.DBFTable1.FieldByName( 'AFAKOD' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'AFAKOD' ).AsInteger;
				MainForm.DBFTable1.Commit;
				MainForm.SyncFBQuery.Next;
				nItem := nItem + 1;
			end;
			WriteLogFile( IntToStr( nItem ) + ' db termék adatai frissítve.',4 );
			MainForm.SyncFBQuery.Close;
		end;
		cSQL := 'UPDATE "syncdate" SET "syncdate"."lastdownload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'aru' );
		MyFBSQLCommand( cSQL );
	end else begin
// Ha MySQL szerver van
		cSQL := 'SELECT * FROM aru WHERE aru.syncdat > ' +
			'( SELECT syncdate.lastdownload FROM syncdate WHERE syncdate.tablename = ' + QuotedStr( 'aru' ) + ')';
		lResult := MyMySQLSelect( cSQL );
		if ( lResult ) and ( MainForm.SyncMySQLQuery.RecordCount <> 0 ) then begin
			MainForm.SyncMySQLQuery.First;
			nItem := 0;
			while ( not MainForm.SyncMySQLQuery.Eof ) do begin
// Megnézzük, hogy van-e már ilyen termék
				Application.ProcessMessages;
				cNewKey := MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString;
				MainForm.AlmiraEnv.SetSoftSeek( FALSE );
				MainForm.DBFTable1.OEMTranslate := FALSE;
				if ( MainForm.DBFTable1.Seek( cNewKey )) then begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Edit;
					WriteLogFile( 'Termék adatok módosítása: ' + cNewKey,4 );
				end else begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Append;
					MainForm.DBFTable1.FieldByName( 'ASZ' ).AsString := cNewKey;
					WriteLogFile( 'Új termék adatai : ' + cNewKey,4 );
				end;
				MainForm.DBFTable1.FieldByName( 'NEV' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString;
				MainForm.DBFTable1.FieldByName( 'SZLANEV' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'SZLANEV' ).AsString;
				MainForm.DBFTable1.FieldByName( 'ME1' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'ME1' ).AsString;
				MainForm.DBFTable1.FieldByName( 'VTSZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'VTSZ' ).AsString;
				MainForm.DBFTable1.FieldByName( 'AFAKOD' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'AFAKOD' ).AsInteger;
				MainForm.DBFTable1.Commit;
				MainForm.SyncMySQLQuery.Next;
				nItem := nItem + 1;
			end;
			WriteLogFile( IntToStr( nItem ) + ' db termék adatai frissítve.',4 );
			MainForm.SyncMySQLQuery.Close;
		end;
		cSQL := 'UPDATE syncdate SET syncdate.lastdownload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'aru' );
		MyMySQLCommand( cSQL );
	end;
	MainForm.DBFTable1.Close;
// Partner törzs frissítése
	WriteLogFile( 'Linzer partnerek letöltése megkezdve.',2 );
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalShareDatabase, 1, Length( InSyncItem.LocalShareDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalShareDatabase + 'P10.DBF';
	MainForm.DBFTable2.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable2.TableName := InSyncItem.LocalYearDatabase + 'F10.DBF';
	try
		MainForm.DBFTable1.Active := TRUE;
		MainForm.DBFTable1.Exclusive := FALSE;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P101.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P102.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P103.NTX' );
		WriteLogFile( 'Partner törzs állomány megnyitva! (' + InSyncItem.LocalShareDatabase + 'P10.DBF)',4 );
		MainForm.DBFTable1.SetOrder( 1 );
		MainForm.DBFTable2.Active := TRUE;
		MainForm.DBFTable2.Exclusive := FALSE;
		MainForm.DBFTable2.CloseIndexes;
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalYearDatabase + 'F101.NTX' );
		MainForm.DBFTable2.SetOrder( 1 );
		WriteLogFile( 'Főkönyvi törzs állomány megnyitva! (' + InSyncItem.LocalYearDatabase + 'F10.DBF)',4 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalShareDatabase + 'P10.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'SELECT * FROM "partner" WHERE "partner"."syncdat" > ' +
			'( SELECT "syncdate"."lastdownload" FROM "syncdate" WHERE "syncdate"."tablename" = ' + QuotedStr( 'partner' ) + ')';
		lResult := MyFBSQLSelect( cSQL );
		if ( lResult ) and ( MainForm.SyncFBQuery.RecordCount <> 0 ) then begin
			MainForm.SyncFBQuery.First;
			nItem := 0;
			while ( not MainForm.SyncFBQuery.Eof ) do begin
	// Megnézzük, hogy van-e már ilyen partner
				Application.ProcessMessages;
				MainForm.DBFTable1.OEMTranslate := FALSE;
				MainForm.AlmiraEnv.SetSoftSeek( FALSE );
				cNewKey := MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString;
				if ( MainForm.DBFTable1.Seek( cNewKey )) then begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Edit;
					WriteLogFile( 'Parter adatok módosítása: ' + MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString,4 );
				end else begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Append;
					MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString;
					WriteLogFile( 'Új partner adatai : ' + MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString,4 );
				end;
				MainForm.DBFTable1.FieldByName( 'NEV' ).AsString := MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString;
				MainForm.DBFTable1.FieldByName( 'SZLANEV' ).AsString := MainForm.SyncFBQuery.FieldByName( 'SZLANEV' ).AsString;
				MainForm.DBFTable1.FieldByName( 'ORSZAG' ).AsString := MainForm.SyncFBQuery.FieldByName( 'ORSZAG' ).AsString;
				MainForm.DBFTable1.FieldByName( 'IRSZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'IRSZAM' ).AsString;
				MainForm.DBFTable1.FieldByName( 'CIM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'UTCA' ).AsString + ' ' +
					MainForm.SyncFBQuery.FieldByName( 'UTTIP' ).AsString + ' ' +
					MainForm.SyncFBQuery.FieldByName( 'HAZ' ).AsString + '.';
				MainForm.DBFTable1.FieldByName( 'FIZMOD' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'FIZMOD' ).AsInteger;
				MainForm.DBFTable1.FieldByName( 'NAPOK' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'NAPOK' ).AsInteger;
				MainForm.DBFTable1.FieldByName( 'NAVTIPUS' ).AsString := MainForm.SyncFBQuery.FieldByName( 'NAVTIP' ).AsString;
				MainForm.DBFTable1.FieldByName( 'ADOSZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'ADOSZAM' ).AsString;
				MainForm.DBFTable1.Commit;
				cNewKey := '311   ' + MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString;
				if ( not MainForm.DBFTable2.Seek( cNewKey )) then begin
					MainForm.DBFTable2.OEMTranslate := TRUE;
					MainForm.DBFTable2.Append;
					MainForm.DBFTable2.FieldByName( 'FKSZ' ).AsString := '311   ' + MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString;
					MainForm.DBFTable2.FieldByName( 'RESZ_JEL' ).AsInteger := 0;
					MainForm.DBFTable2.FieldByName( 'FTORZS_KAR' ).AsInteger := 90;
					MainForm.DBFTable2.FieldByName( 'FORG_JELL' ).AsString := '0';
					MainForm.DBFTable2.FieldByName( 'MEGN1' ).AsString := 'Belföldi követelések';
					MainForm.DBFTable2.FieldByName( 'MEGN2' ).AsString := MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString;
					MainForm.DBFTable2.Commit;
					WriteLogFile( 'Új főkönyvi szám beszúrása: 311   -' + MainForm.SyncFBQuery.FieldByName( 'KOD' ).AsString,4 );
				end;
				MainForm.SyncFBQuery.Next;
				nItem := nItem + 1;
			end;
			WriteLogFile( IntToStr( nItem ) + ' db partner adatai frissítve.',4 );
			MainForm.SyncFBQuery.Close;
		end;
		cSQL := 'UPDATE "syncdate" SET "syncdate"."lastdownload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'partner' );;
		MyFBSQLCommand( cSQL );
		MainForm.DBFTable1.Close;
		MainForm.DBFTable2.Close;
	end else begin
// Ha MySQL szerver van
		cSQL := 'SELECT * FROM partner WHERE partner.syncdat > ' +
			'( SELECT syncdate.lastdownload FROM syncdate WHERE syncdate.tablename = ' + QuotedStr( 'partner' ) + ')';
		lResult := MyMySQLSelect( cSQL );
		if ( lResult ) and ( MainForm.SyncMySQLQuery.RecordCount <> 0 ) then begin
			MainForm.SyncMySQLQuery.First;
			nItem := 0;
			while ( not MainForm.SyncMySQLQuery.Eof ) do begin
	// Megnézzük, hogy van-e már ilyen partner
				Application.ProcessMessages;
				MainForm.DBFTable1.OEMTranslate := FALSE;
				MainForm.AlmiraEnv.SetSoftSeek( FALSE );
				cNewKey := MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString;
				if ( MainForm.DBFTable1.Seek( cNewKey )) then begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Edit;
					WriteLogFile( 'Parter adatok módosítása: ' + MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString,4 );
				end else begin
					MainForm.DBFTable1.OEMTranslate := TRUE;
					MainForm.DBFTable1.Append;
					MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString;
					WriteLogFile( 'Új partner adatai : ' + MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString,4 );
				end;
				MainForm.DBFTable1.FieldByName( 'NEV' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString;
				MainForm.DBFTable1.FieldByName( 'SZLANEV' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'SZLANEV' ).AsString;
				MainForm.DBFTable1.FieldByName( 'ORSZAG' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'ORSZAG1' ).AsString;
				MainForm.DBFTable1.FieldByName( 'IRSZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'IRSZAM1' ).AsString;
				MainForm.DBFTable1.FieldByName( 'CIM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'UTCA1' ).AsString + ' ' +
					MainForm.SyncMySQLQuery.FieldByName( 'UTTIP1' ).AsString + ' ' +
					MainForm.SyncMySQLQuery.FieldByName( 'HAZ1' ).AsString + '.';
				MainForm.DBFTable1.FieldByName( 'FIZMOD' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'FIZMOD1' ).AsInteger;
				MainForm.DBFTable1.FieldByName( 'NAPOK' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'NAPOK1' ).AsInteger;
				MainForm.DBFTable1.FieldByName( 'NAVTIPUS' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'NAVTIP' ).AsString;
				MainForm.DBFTable1.FieldByName( 'ADOSZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'ADOSZAM' ).AsString;
				MainForm.DBFTable1.Commit;
				cNewKey := '311   ' + MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString;
				if ( not MainForm.DBFTable2.Seek( cNewKey )) then begin
					MainForm.DBFTable2.OEMTranslate := TRUE;
					MainForm.DBFTable2.Append;
					MainForm.DBFTable2.FieldByName( 'FKSZ' ).AsString := '311   ' + MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString;
					MainForm.DBFTable2.FieldByName( 'RESZ_JEL' ).AsInteger := 0;
					MainForm.DBFTable2.FieldByName( 'FTORZS_KAR' ).AsInteger := 90;
					MainForm.DBFTable2.FieldByName( 'FORG_JELL' ).AsString := '0';
					MainForm.DBFTable2.FieldByName( 'MEGN1' ).AsString := 'Belföldi követelések';
					MainForm.DBFTable2.FieldByName( 'MEGN2' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString;
					MainForm.DBFTable2.Commit;
					WriteLogFile( 'Új főkönyvi szám beszúrása: 311   -' + MainForm.SyncMySQLQuery.FieldByName( 'KOD' ).AsString,4 );
				end;
				MainForm.SyncMySQLQuery.Next;
				nItem := nItem + 1;
			end;
			WriteLogFile( IntToStr( nItem ) + ' db partner adatai frissítve.',4 );
			MainForm.SyncMySQLQuery.Close;
		end;
		cSQL := 'UPDATE syncdate SET syncdate.lastdownload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'partner' );;
		MyMySQLCommand( cSQL );
		MainForm.DBFTable1.Close;
		MainForm.DBFTable2.Close;
	end;
	nCsoport := 0;
	nMaxSzla := 0;
// Kontírozás állomány
	MainForm.DBFTable5.Close;
	MainForm.DBFTable5.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable5.TableName := InSyncItem.LocalYearDatabase + 'F15.DBF';
	try
		MainForm.DBFTable5.Active := TRUE;
		MainForm.DBFTable5.Exclusive := FALSE;
		MainForm.DBFTable5.CloseIndexes;
		MainForm.DBFTable5.IndexOpen( InSyncItem.LocalYearDatabase + 'F151.NTX' );
		MainForm.DBFTable5.IndexOpen( InSyncItem.LocalYearDatabase + 'F152.NTX' );
		MainForm.DBFTable5.IndexOpen( InSyncItem.LocalYearDatabase + 'F153.NTX' );
		MainForm.DBFTable5.IndexOpen( InSyncItem.LocalYearDatabase + 'F154.NTX' );
		MainForm.DBFTable5.IndexOpen( InSyncItem.LocalYearDatabase + 'F155.NTX' );
		MainForm.DBFTable5.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'F15.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
// ÁFA kód törzs
	WriteLogFile( 'Linzer számlák letöltése megkezdve.',2 );
	MainForm.DBFTable3.Close;
	MainForm.DBFTable3.DatabaseName := Copy( InSyncItem.LocalYearShareDatabase, 1, Length( InSyncItem.LocalYearShareDatabase ) - 1 );
	MainForm.DBFTable3.TableName := InSyncItem.LocalYearShareDatabase + '\P13.DBF';
	try
		MainForm.DBFTable3.Active := TRUE;
		MainForm.DBFTable3.Exclusive := FALSE;
		MainForm.DBFTable3.IndexDefs.Clear;
		MainForm.DBFTable3.CloseIndexes;
		MainForm.DBFTable3.IndexOpen( InSyncItem.LocalYearShareDatabase + '\P131.NTX' );
		MainForm.DBFTable3.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearShareDatabase + '\P13.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
// Anyag törzs
	MainForm.DBFTable4.Close;
	MainForm.DBFTable4.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable4.TableName := InSyncItem.LocalYearDatabase + 'A10.DBF';
	try
		MainForm.DBFTable4.Active := TRUE;
		MainForm.DBFTable4.Exclusive := FALSE;
		MainForm.DBFTable4.IndexDefs.Clear;
		MainForm.DBFTable4.CloseIndexes;
		MainForm.DBFTable4.IndexOpen( InSyncItem.LocalYearDatabase + 'A101.NTX' );
		MainForm.DBFTable4.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'A10.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
// Számla fejléc
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalShareDatabase, 1, Length( InSyncItem.LocalShareDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalShareDatabase + 'P14.DBF';
	try
		MainForm.DBFTable1.Active := TRUE;
		MainForm.DBFTable1.Exclusive := FALSE;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P141.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P142.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P143.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P144.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P145.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P146.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P147.NTX' );
		MainForm.DBFTable1.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalShareDatabase + 'P14.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
	MainForm.DBFTable2.DatabaseName := Copy( InSyncItem.LocalShareDatabase, 1, Length( InSyncItem.LocalShareDatabase ) - 1 );
	MainForm.DBFTable2.TableName := InSyncItem.LocalShareDatabase + 'P15.DBF';
	try
		MainForm.DBFTable2.Active := TRUE;
		MainForm.DBFTable2.Exclusive := FALSE;
		MainForm.DBFTable2.CloseIndexes;
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalShareDatabase + 'P151.NTX' );
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalShareDatabase + 'P152.NTX' );
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalShareDatabase + 'P153.NTX' );
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalShareDatabase + 'P154.NTX' );
		MainForm.DBFTable2.IndexOpen( InSyncItem.LocalShareDatabase + 'P155.NTX' );
		MainForm.DBFTable2.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalShareDatabase + 'P15.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
// A legutolsó számla megkeresése
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'SELECT FIRST 1 "szlafej"."szlaszam" FROM "szlafej"';
		lResult := MyFBSQLSelect( cSQL );
		nCsoport := StrToInt( Copy( MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString,1,1 ));
	end else begin
// Ha MySQL szerver van
		cSQL := 'SELECT szlafej.szlaszam FROM szlafej LIMIT 1';
		lResult := MyMySQLSelect( cSQL );
		nCsoport := StrToInt( Copy( MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString,1,1 ));
	end;
	if ( lResult ) then begin
		MainForm.DBFTable1.OEMTranslate := FALSE;
		MainForm.AlmiraEnv.SetSoftSeek( TRUE );
		cNewKey := Trim( IntToStr( InSyncItem.ActYear )) + Trim( IntToStr( nCsoport + 1 ));
		WriteLogFile( 'Legutolsó számla megkeresése :' + cNewKey, 4 );
		MainForm.DBFTable1.Seek( cNewKey );
		WriteLogFile( 'Rekordszám :' + IntToStr( MainForm.DBFTable1.RecordCount ), 4 );
		WriteLogFile( 'Rekord :' + IntToStr( MainForm.DBFTable1.RecNo ), 4 );
		WriteLogFile( 'Kikeresve :' + MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString, 4 );
		if ( MainForm.DBFTable1.Eof ) or ( MainForm.DBFTable1.RecNo > MainForm.DBFTable1.RecordCount ) then begin
			MainForm.DBFTable1.GoTop;
			MainForm.DBFTable1.Skip( MainForm.DBFTable1.RecordCount - 1 );
			cNewKey := Trim( IntToStr( nCsoport )) + '0000000';
		end else begin
			if ( MainForm.DBFTable1.FieldByName( 'EV' ).AsInteger > InSyncItem.ActYear ) or
				 ( Copy( MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString,1,1 ) > Trim( IntToStr( nCsoport ))) then begin
				MainForm.DBFTable1.Skip( -1 );
			end;
			cNewKey := MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString;
			if ( MainForm.DBFTable1.FieldByName( 'EV' ).AsInteger < InSyncItem.ActYear ) then begin
				cNewKey := Trim( IntToStr( nCsoport )) + '0000000';
			end;
		end;
		WriteLogFile( 'Legutolsó számla :' + cNewKey, 4 );
		nMaxSzla := StrToInt( Copy( cNewKey,2,7 ));
		WriteLogFile( 'Legutolsó számla :' + IntToStr( nMaxSzla ), 4 );
		if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
			cSQL := 'SELECT "szlafej"."ev", "szlafej"."szlaszam", "szlafej"."pkod", "szlafej"."telj", "szlafej"."kelt", ' +
				'"szlafej"."hatarido", "szlafej"."fizmod", "szlafej"."megj1", "szlafej"."megj2", "szlafej"."devnetto", "szlafej"."devafa", ' +
				'"szlafej"."eredszla", "szlasor"."sor", "szlasor"."asz", ' +
				'"szlasor"."afakod", "szlasor"."menny", "szlasor"."egysar", "szlasor"."netto", "szlasor"."eng", "szlasor"."afa", ' +
				'"szlasor"."brutto", "szlasor"."megj" FROM "szlasor" ' +
				'LEFT JOIN "szlafej" ON ( "szlafej"."ev" = "szlasor"."ev" AND "szlafej"."szlaszam" = "szlasor"."szlaszam" ) ' +
				'WHERE "szlafej"."ev" = ' + IntToStr( InSyncItem.ActYear ) + ' AND ' +
				'"szlafej"."szlaszam" > ' + QuotedStr( Trim( IntToStr( nCsoport )) + PadL( IntToStr( nMaxSzla ),7,'0' )) + ' ' +
				' AND "szlafej"."szlaszam" < ' + QuotedStr( Trim( IntToStr( nCsoport )) + PadL( IntToStr( nMaxSzla + 51 ),7,'0' )) + ' ' +
				'ORDER BY "ev","szlaszam","sor"';
			lResult := MyFBSQLSelect( cSQL );
			if ( lResult ) and ( MainForm.SyncFBQuery.RecordCount <> 0 ) then begin
				cLastBiz := '';
				nLastAlap := 0;
				nLastAFA := 0;
				nSumAlap := 0;
				nSumAFA := 0;
				MainForm.SyncFBQuery.First;
				while ( not MainForm.SyncFBQuery.Eof ) do begin
					Application.ProcessMessages;
					MainForm.Refresh;
//			Application.ProcessMessages;
					if ( cLastBiz <> MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString ) then begin
						MainForm.DBFTable1.OEMTranslate := FALSE;
						MainForm.AlmiraEnv.SetSoftSeek( FALSE );
// Ha nincs még ilyen számla
						cNewKey := MainForm.SyncFBQuery.FieldByName( 'EV' ).AsString + MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
						if ( not ( MainForm.DBFTable1.Seek( cNewKey ))) then begin
							WriteLogFile( 'Új számla beszúrása :' + cNewKey, 4 );
//						if (( MainForm.DBFTable1.FieldByName( 'EV' ).AsInteger <> MainForm.SyncFBQuery.FieldByName( 'EV' ).AsInteger ) or
//							( MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString <> MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString )) then begin
							 dKonyvDat := MainForm.SyncFBQuery.FieldByName( 'TELJ' ).AsDateTime;
							 if ( YearOf( dKonyvDat ) > InSyncItem.ActYear ) then begin
								dKonyvDat := EncodeDate( InSyncItem.ActYear, 12, 31 );
							 end;
							WriteLogFile( 'Könyvelési dátum :' + FormatDateTime( 'YYYY.MM.DD hh:mm', dKonyvDat ), 4 );
							MainForm.DBFTable1.OEMTranslate := TRUE;
							MainForm.DBFTable1.Append;
							MainForm.DBFTable1.FieldByName( 'EV' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'EV' ).AsInteger;
							MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
							MainForm.DBFTable1.FieldByName( 'KSORSZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
							MainForm.DBFTable1.FieldByName( 'TELJ' ).AsDateTime := MainForm.SyncFBQuery.FieldByName( 'TELJ' ).AsDateTime;
							MainForm.DBFTable1.FieldByName( 'KELT' ).AsDateTime := MainForm.SyncFBQuery.FieldByName( 'KELT' ).AsDateTime;
							MainForm.DBFTable1.FieldByName( 'KONYVDAT' ).AsDateTime := dKonyvDat;
							MainForm.DBFTable1.FieldByName( 'HATARIDO' ).AsDateTime := MainForm.SyncFBQuery.FieldByName( 'HATARIDO' ).AsDateTime;
							MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
							MainForm.DBFTable1.FieldByName( 'FIZMOD' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'FIZMOD' ).AsInteger;
							MainForm.DBFTable1.FieldByName( 'MEGJ1' ).AsString := MainForm.SyncFBQuery.FieldByName( 'MEGJ1' ).AsString;
							MainForm.DBFTable1.FieldByName( 'MEGJ2' ).AsString := MainForm.SyncFBQuery.FieldByName( 'MEGJ2' ).AsString;
							MainForm.DBFTable1.FieldByName( 'EREDSZLA' ).AsString := MainForm.SyncFBQuery.FieldByName( 'EREDSZLA' ).AsString;
							MainForm.DBFTable1.FieldByName( 'FKMEGJ' ).AsString := 'Késztermék értékesítés';
							MainForm.DBFTable1.FieldByName( 'DEVIZA' ).AsString := 'HUF';
							MainForm.DBFTable1.FieldByName( 'ARFOLYAM1' ).AsFloat := 1;
							MainForm.DBFTable1.FieldByName( 'ARFOLYAM2' ).AsFloat := 1;
							MainForm.DBFTable1.FieldByName( 'FORDAFAS' ).AsString := 'N';
							MainForm.DBFTable1.FieldByName( 'BANK' ).AsInteger := 1;
							MainForm.DBFTable1.FieldByName( 'ALAP' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'DEVNETTO' ).AsFloat;
							MainForm.DBFTable1.FieldByName( 'AFA' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'DEVAFA' ).AsFloat;
							MainForm.DBFTable1.FieldByName( 'OSSZEG' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'DEVNETTO' ).AsFloat + MainForm.SyncFBQuery.FieldByName( 'DEVAFA' ).AsFloat;
							MainForm.DBFTable1.FieldByName( 'DEVOSSZEG' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'DEVNETTO' ).AsFloat + MainForm.SyncFBQuery.FieldByName( 'DEVAFA' ).AsFloat;
							MainForm.DBFTable1.Commit;
							WriteLogFile( MainForm.SyncFBQuery.FieldByName( 'EV' ).AsString + '/' + MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString + ' számla adatainak felírása. ', 4 );
							BizKontir.Clear;
							BizKontir.BizSzam := IntToStr( MainForm.SyncFBQuery.FieldByName( 'EV' ).AsInteger ) + MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
							BizKontir.BizTipus := 'P';
							BizKontir.BizDate := MainForm.SyncFBQuery.FieldByName( 'TELJ' ).AsDateTime;
							while ( not MainForm.SyncFBQuery.Eof ) and ( BizKontir.BizSzam = IntToStr( MainForm.SyncFBQuery.FieldByName( 'EV' ).AsInteger ) + MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString ) do begin
								Application.ProcessMessages;
// Számlasorok beszúrása (P15)
								MainForm.DBFTable2.OEMTranslate := FALSE;
								MainForm.AlmiraEnv.SetSoftSeek( FALSE );
// Ha nincs még ilyen számla sor
								cNewKey := MainForm.SyncFBQuery.FieldByName( 'EV' ).AsString + MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString +
									PadL( MainForm.SyncFBQuery.FieldByName( 'SOR' ).AsString,2,' ' );
								if ( not ( MainForm.DBFTable2.Seek( cNewKey ))) then begin
									WriteLogFile( 'Új számla sor beszúrása :' + cNewKey, 2 );
									MainForm.DBFTable2.OEMTranslate := TRUE;
									MainForm.DBFTable2.Append;
									MainForm.DBFTable2.FieldByName( 'EV' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'EV' ).AsInteger;
									MainForm.DBFTable2.FieldByName( 'SZLASZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
									MainForm.DBFTable2.FieldByName( 'SORSZAM' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'SOR' ).AsInteger;
									MainForm.DBFTable2.FieldByName( 'ASZ' ).AsString := MainForm.SyncFBQuery.FieldByName( 'ASZ' ).AsString;
									MainForm.DBFTable2.FieldByName( 'AFAKOD' ).AsInteger := MainForm.SyncFBQuery.FieldByName( 'AFAKOD' ).AsInteger;
									MainForm.DBFTable2.FieldByName( 'MENNY' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'MENNY' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'AR' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'NETTO' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'AFA' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'AFA' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'DEVAR' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'NETTO' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'DEVAFA' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'AFA' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'MEGJ' ).AsString := MainForm.SyncFBQuery.FieldByName( 'MEGJ' ).AsString;
									MainForm.DBFTable2.FieldByName( 'PKOD' ).AsString := MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
									MainForm.DBFTable2.FieldByName( 'EGYSAR' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'EGYSAR' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'PTIPUS' ).AsString := '311';
									MainForm.DBFTable2.FieldByName( 'FKSZ' ).AsString := '911';
									MainForm.DBFTable2.Commit;
// Innen kezdődik a kontírozás
									cFKSz1 := '311   ' + MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
									cKTNem1 := '';
									nRJ1 := 0;
									cFKSz2 := '';
									cKTNem2 := '';
									nRJ2 := 0;
// Rákeresünk az anyagszámra
									MainForm.AlmiraEnv.SetSoftSeek( FALSE );
									cNewKey := MainForm.SyncFBQuery.FieldByName( 'ASZ' ).AsString;
									if ( MainForm.DBFTable4.Seek( cNewKey )) then begin
										cFKSz2 := MainForm.DBFTable4.FieldByName( 'FKSZ3' ).AsString;
										nRJ2 := MainForm.DBFTable4.FieldByName( 'RJ3' ).AsInteger;
									end;
									if ( cFKSz2 = '' ) then begin
										cFKSz2 := '911';
									end;
// Rákeresünk az ÁFA kódra
									cNewKey := MainForm.SyncFBQuery.FieldByName( 'AFAKOD' ).AsString;
									MainForm.DBFTable3.Seek( cNewKey );
									nRJ1 := MainForm.DBFTable3.FieldByName( 'VALAP' ).AsInteger;
// Kikontírozzuk a számlasort
									cNewKey := FormatDateTime( 'YYYYMMDD', MainForm.DBFTable1.FieldByName( 'TELJ' ).AsDateTime ) +
										PadR( cFKSz1,11,' ' ) + PadR( cKTNem1,6,' ' ) + PadR( IntToStr( nRJ1 ),5, ' ' ) +
										PadR( cFKSz2,11,' ' ) + PadR( cKTNem2,6,' ' ) + PadR( IntToStr( nRJ2 ),5, ' ' );
									BizKontir.KeyInsert( cNewKey,
										MainForm.DBFTable2.FieldByName( 'AR' ).AsFloat,
										0,
										MainForm.DBFTable2.FieldByName( 'MENNY' ).AsFloat,
										'Késztermék értékesítés',
										'Késztermék értékesítés' );
									cFKSz1 := '311   ' + MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
									cKTNem1 := '';
									nRJ1 := MainForm.DBFTable3.FieldByName( 'RJ1' ).AsInteger;
									cFKSz2 := MainForm.DBFTable3.FieldByName( 'FKSZ' ).AsString;
									cKTNem2 := '';
									nRJ2 := MainForm.DBFTable3.FieldByName( 'RJ1' ).AsInteger;
									cNewKey := FormatDateTime( 'YYYYMMDD', MainForm.DBFTable1.FieldByName( 'TELJ' ).AsDateTime ) +
										PadR( cFKSz1,11,' ' ) + PadR( cKTNem1,6,' ' ) + PadR( IntToStr( nRJ1 ),5, ' ' ) +
										PadR( cFKSz2,11,' ' ) + PadR( cKTNem2,6,' ' ) + PadR( IntToStr( nRJ2 ),5, ' ' );
// Kikontírozzuk az ÁFÁ-t
									BizKontir.KeyInsert( cNewKey,
										MainForm.DBFTable2.FieldByName( 'AFA' ).AsFloat,
										0,
										0,
										'Késztermék értékesítés ÁFA',
										'Késztermék értékesítés ÁFA' );
									nSumAlap := nSumAlap + MainForm.SyncFBQuery.FieldByName( 'NETTO' ).AsFloat;
									nSumAFA := nSumAFA + MainForm.SyncFBQuery.FieldByName( 'AFA' ).AsFloat;
									cLastBiz := MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
									nCsoport := StrToInt( Copy( MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString,1,1 ));
									nMaxSzla := StrToInt( Copy( MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString,2,7 ));
									lWriteBiz := TRUE;
								end else begin
									WriteLogFile( 'Már létező számla sor :' + cNewKey, 2 );
								end;
								nLastAlap := MainForm.SyncFBQuery.FieldByName( 'DEVNETTO' ).AsFloat;
								nLastAFA := MainForm.SyncFBQuery.FieldByName( 'DEVAFA' ).AsFloat;
								MainForm.SyncFBQuery.Next;
							end;
// Felírjuk a számla kontírozását
							BizKontir.WriteDBF( MainForm.DBFTable5 );
							if ( nLastAlap <> nSumAlap ) or ( nLastAFA <> nSumAFA ) then begin
								WriteLogFile( 'Hibás számla összeg : ' + MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString + ' (' +
									FormatFloat( '0.00', nLastAlap ) + ' - ' + FormatFloat( '0.00', nSumAlap ) + ')', 4 );
							end;
						end else begin
							WriteLogFile( 'Már létező számla :' + cNewKey, 2 );
							MainForm.SyncFBQuery.Next;
						end;
						lWriteBiz := FALSE;
						nSumAlap := 0;
						nSumAFA := 0;
					end;
				end;
				MainForm.SyncFBQuery.Close;
			end;
			cSQL := 'UPDATE "syncdate" SET "syncdate"."lastdownload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'szamla' );;
			MyFBSQLCommand( cSQL );
			MainForm.SyncFBQuery.Close;
		end else begin
// Ha MySQL szerver van
			cSQL := 'SELECT szlafej.ev, szlafej.szlaszam, szlafej.pkod, szlafej.telj, szlafej.kelt, ' +
				'szlafej.hatarido, szlafej.fizmod, szlafej.megj1, szlafej.megj2, szlafej.devnetto, szlafej.devafa, ' +
				'szlafej.eredszla, szlasor.sor, szlasor.asz, ' +
				'szlasor.afakod, szlasor.menny1, szlasor.egysar, szlasor.netto, szlasor.eng1, szlasor.afa, ' +
				'szlasor.brutto, szlasor.megj1 FROM szlasor ' +
				'LEFT JOIN szlafej ON ( szlafej.ev = szlasor.ev AND szlafej.szlaszam = szlasor.szlaszam ) ' +
				'WHERE szlafej.ev = ' + IntToStr( InSyncItem.ActYear ) + ' AND ' +
				'szlafej.szlaszam > ' + QuotedStr( Trim( IntToStr( nCsoport )) + PadL( IntToStr( nMaxSzla ),7,'0' )) + ' ' +
				' AND szlafej.szlaszam < ' + QuotedStr( Trim( IntToStr( nCsoport )) + PadL( IntToStr( nMaxSzla + 51 ),7,'0' )) + ' ' +
				'ORDER BY ev,szlaszam,sor';
			lResult := MyMySQLSelect( cSQL );
			if ( lResult ) and ( MainForm.SyncMySQLQuery.RecordCount <> 0 ) then begin
				cLastBiz := '';
				nLastAlap := 0;
				nLastAFA := 0;
				nSumAlap := 0;
				nSumAFA := 0;
				MainForm.SyncMySQLQuery.First;
				while ( not MainForm.SyncMySQLQuery.Eof ) do begin
					Application.ProcessMessages;
					MainForm.Refresh;
	//			Application.ProcessMessages;
					if ( cLastBiz <> MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString ) then begin
						MainForm.DBFTable1.OEMTranslate := FALSE;
						MainForm.AlmiraEnv.SetSoftSeek( FALSE );
	// Ha nincs még ilyen számla
						cNewKey := MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsString + MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
						if ( not ( MainForm.DBFTable1.Seek( cNewKey ))) then begin
							WriteLogFile( 'Új számla beszúrása :' + cNewKey, 4 );
	//						if (( MainForm.DBFTable1.FieldByName( 'EV' ).AsInteger <> MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsInteger ) or
	//							( MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString <> MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString )) then begin
							 dKonyvDat := MainForm.SyncMySQLQuery.FieldByName( 'TELJ' ).AsDateTime;
							 if ( YearOf( dKonyvDat ) > InSyncItem.ActYear ) then begin
								dKonyvDat := EncodeDate( InSyncItem.ActYear, 12, 31 );
							 end;
							WriteLogFile( 'Könyvelési dátum :' + FormatDateTime( 'YYYY.MM.DD hh:mm', dKonyvDat ), 4 );
							MainForm.DBFTable1.OEMTranslate := TRUE;
							MainForm.DBFTable1.Append;
							MainForm.DBFTable1.FieldByName( 'EV' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsInteger;
							MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
							MainForm.DBFTable1.FieldByName( 'KSORSZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
							MainForm.DBFTable1.FieldByName( 'TELJ' ).AsDateTime := MainForm.SyncMySQLQuery.FieldByName( 'TELJ' ).AsDateTime;
							MainForm.DBFTable1.FieldByName( 'KELT' ).AsDateTime := MainForm.SyncMySQLQuery.FieldByName( 'KELT' ).AsDateTime;
							MainForm.DBFTable1.FieldByName( 'KONYVDAT' ).AsDateTime := dKonyvDat;
							MainForm.DBFTable1.FieldByName( 'HATARIDO' ).AsDateTime := MainForm.SyncMySQLQuery.FieldByName( 'HATARIDO' ).AsDateTime;
							MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
							MainForm.DBFTable1.FieldByName( 'FIZMOD' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'FIZMOD' ).AsInteger;
							MainForm.DBFTable1.FieldByName( 'MEGJ1' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'MEGJ1' ).AsString;
							MainForm.DBFTable1.FieldByName( 'MEGJ2' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'MEGJ2' ).AsString;
							MainForm.DBFTable1.FieldByName( 'EREDSZLA' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'EREDSZLA' ).AsString;
							MainForm.DBFTable1.FieldByName( 'FKMEGJ' ).AsString := 'Késztermék értékesítés';
							MainForm.DBFTable1.FieldByName( 'DEVIZA' ).AsString := 'HUF';
							MainForm.DBFTable1.FieldByName( 'ARFOLYAM1' ).AsFloat := 1;
							MainForm.DBFTable1.FieldByName( 'ARFOLYAM2' ).AsFloat := 1;
							MainForm.DBFTable1.FieldByName( 'FORDAFAS' ).AsString := 'N';
							MainForm.DBFTable1.FieldByName( 'BANK' ).AsInteger := 1;
							MainForm.DBFTable1.FieldByName( 'ALAP' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'DEVNETTO' ).AsFloat;
							MainForm.DBFTable1.FieldByName( 'AFA' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'DEVAFA' ).AsFloat;
							MainForm.DBFTable1.FieldByName( 'OSSZEG' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'DEVNETTO' ).AsFloat + MainForm.SyncMySQLQuery.FieldByName( 'DEVAFA' ).AsFloat;
							MainForm.DBFTable1.FieldByName( 'DEVOSSZEG' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'DEVNETTO' ).AsFloat + MainForm.SyncMySQLQuery.FieldByName( 'DEVAFA' ).AsFloat;
							MainForm.DBFTable1.Commit;
							WriteLogFile( MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsString + '/' + MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString + ' számla adatainak felírása. ', 4 );
							BizKontir.Clear;
							BizKontir.BizSzam := IntToStr( MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsInteger ) + MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
							BizKontir.BizTipus := 'P';
							BizKontir.BizDate := MainForm.SyncMySQLQuery.FieldByName( 'TELJ' ).AsDateTime;
							while ( not MainForm.SyncMySQLQuery.Eof ) and ( BizKontir.BizSzam = IntToStr( MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsInteger ) + MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString ) do begin
								Application.ProcessMessages;
	// Számlasorok beszúrása (P15)
								MainForm.DBFTable2.OEMTranslate := FALSE;
								MainForm.AlmiraEnv.SetSoftSeek( FALSE );
	// Ha nincs még ilyen számla sor
								cNewKey := MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsString + MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString +
									PadL( MainForm.SyncMySQLQuery.FieldByName( 'SOR' ).AsString,2,' ' );
								if ( not ( MainForm.DBFTable2.Seek( cNewKey ))) then begin
									WriteLogFile( 'Új számla sor beszúrása :' + cNewKey, 2 );
									MainForm.DBFTable2.OEMTranslate := TRUE;
									MainForm.DBFTable2.Append;
									MainForm.DBFTable2.FieldByName( 'EV' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'EV' ).AsInteger;
									MainForm.DBFTable2.FieldByName( 'SZLASZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
									MainForm.DBFTable2.FieldByName( 'SORSZAM' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'SOR' ).AsInteger;
									MainForm.DBFTable2.FieldByName( 'ASZ' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'ASZ' ).AsString;
									MainForm.DBFTable2.FieldByName( 'AFAKOD' ).AsInteger := MainForm.SyncMySQLQuery.FieldByName( 'AFAKOD' ).AsInteger;
									MainForm.DBFTable2.FieldByName( 'MENNY' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'MENNY1' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'AR' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'NETTO' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'AFA' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'AFA' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'DEVAR' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'NETTO' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'DEVAFA' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'AFA' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'MEGJ' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'MEGJ1' ).AsString;
									MainForm.DBFTable2.FieldByName( 'PKOD' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
									MainForm.DBFTable2.FieldByName( 'EGYSAR' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'EGYSAR' ).AsFloat;
									MainForm.DBFTable2.FieldByName( 'PTIPUS' ).AsString := '311';
									MainForm.DBFTable2.FieldByName( 'FKSZ' ).AsString := '911';
									MainForm.DBFTable2.Commit;
	// Innen kezdődik a kontírozás
									cFKSz1 := '311   ' + MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
									cKTNem1 := '';
									nRJ1 := 0;
									cFKSz2 := '';
									cKTNem2 := '';
									nRJ2 := 0;
	// Rákeresünk az anyagszámra
									MainForm.AlmiraEnv.SetSoftSeek( FALSE );
									cNewKey := MainForm.SyncMySQLQuery.FieldByName( 'ASZ' ).AsString;
									if ( MainForm.DBFTable4.Seek( cNewKey )) then begin
										cFKSz2 := MainForm.DBFTable4.FieldByName( 'FKSZ3' ).AsString;
										nRJ2 := MainForm.DBFTable4.FieldByName( 'RJ3' ).AsInteger;
									end;
									if ( cFKSz2 = '' ) then begin
										cFKSz2 := '911';
									end;
	// Rákeresünk az ÁFA kódra
									cNewKey := MainForm.SyncMySQLQuery.FieldByName( 'AFAKOD' ).AsString;
									MainForm.DBFTable3.Seek( cNewKey );
									nRJ1 := MainForm.DBFTable3.FieldByName( 'VALAP' ).AsInteger;
	// Kikontírozzuk a számlasort
									cNewKey := FormatDateTime( 'YYYYMMDD', MainForm.DBFTable1.FieldByName( 'TELJ' ).AsDateTime ) +
										PadR( cFKSz1,11,' ' ) + PadR( cKTNem1,6,' ' ) + PadR( IntToStr( nRJ1 ),5, ' ' ) +
										PadR( cFKSz2,11,' ' ) + PadR( cKTNem2,6,' ' ) + PadR( IntToStr( nRJ2 ),5, ' ' );
									BizKontir.KeyInsert( cNewKey,
										MainForm.DBFTable2.FieldByName( 'AR' ).AsFloat,
										0,
										MainForm.DBFTable2.FieldByName( 'MENNY' ).AsFloat,
										'Késztermék értékesítés',
										'Késztermék értékesítés' );
									cFKSz1 := '311   ' + MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
									cKTNem1 := '';
									nRJ1 := MainForm.DBFTable3.FieldByName( 'RJ1' ).AsInteger;
									cFKSz2 := MainForm.DBFTable3.FieldByName( 'FKSZ' ).AsString;
									cKTNem2 := '';
									nRJ2 := MainForm.DBFTable3.FieldByName( 'RJ1' ).AsInteger;
									cNewKey := FormatDateTime( 'YYYYMMDD', MainForm.DBFTable1.FieldByName( 'TELJ' ).AsDateTime ) +
										PadR( cFKSz1,11,' ' ) + PadR( cKTNem1,6,' ' ) + PadR( IntToStr( nRJ1 ),5, ' ' ) +
										PadR( cFKSz2,11,' ' ) + PadR( cKTNem2,6,' ' ) + PadR( IntToStr( nRJ2 ),5, ' ' );
	// Kikontírozzuk az ÁFÁ-t
									BizKontir.KeyInsert( cNewKey,
										MainForm.DBFTable2.FieldByName( 'AFA' ).AsFloat,
										0,
										0,
										'Késztermék értékesítés ÁFA',
										'Késztermék értékesítés ÁFA' );
									nSumAlap := nSumAlap + MainForm.SyncMySQLQuery.FieldByName( 'NETTO' ).AsFloat;
									nSumAFA := nSumAFA + MainForm.SyncMySQLQuery.FieldByName( 'AFA' ).AsFloat;
									cLastBiz := MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
									nCsoport := StrToInt( Copy( MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString,1,1 ));
									nMaxSzla := StrToInt( Copy( MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString,2,7 ));
									lWriteBiz := TRUE;
								end else begin
									WriteLogFile( 'Már létező számla sor :' + cNewKey, 2 );
								end;
								nLastAlap := MainForm.SyncMySQLQuery.FieldByName( 'DEVNETTO' ).AsFloat;
								nLastAFA := MainForm.SyncMySQLQuery.FieldByName( 'DEVAFA' ).AsFloat;
								MainForm.SyncMySQLQuery.Next;
							end;
	// Felírjuk a számla kontírozását
							BizKontir.WriteDBF( MainForm.DBFTable5 );
							if ( nLastAlap <> nSumAlap ) or ( nLastAFA <> nSumAFA ) then begin
								WriteLogFile( 'Hibás számla összeg : ' + MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString + ' (' +
									FormatFloat( '0.00', nLastAlap ) + ' - ' + FormatFloat( '0.00', nSumAlap ) + ')', 4 );
							end;
						end else begin
							WriteLogFile( 'Már létező számla :' + cNewKey, 2 );
							MainForm.SyncMySQLQuery.Next;
						end;
						lWriteBiz := FALSE;
						nSumAlap := 0;
						nSumAFA := 0;
					end;
				end;
				MainForm.SyncMySQLQuery.Close;
			end;
			cSQL := 'UPDATE syncdate SET syncdate.lastdownload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'szamla' );;
			MyMySQLCommand( cSQL );
		end;
		WriteLogFile( 'Számlák adatainak letöltése kész. ',2 );
		MainForm.DBFTable1.Close;
		MainForm.DBFTable2.Close;
	end;
	if ( nCsoport <> 0 ) and ( nMaxSzla <> 0 ) then begin
// Számlaszámok felírása
		MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
		MainForm.DBFTable1.TableName := InSyncItem.LocalYearDatabase + 'P16.DBF';
		try
			MainForm.DBFTable1.Active := TRUE;
			MainForm.DBFTable1.Exclusive := FALSE;
			MainForm.DBFTable1.CloseIndexes;
			MainForm.DBFTable1.IndexOpen( InSyncItem.LocalYearDatabase + 'P161.NTX' );
			MainForm.DBFTable1.SetOrder( 1 );
		except
			on E : Exception do begin
				WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'P16.DBF állomány megnyitásakor :' + E.Message,2 );
				Exit;
			end;
		end;
		MainForm.AlmiraEnv.SetSoftSeek( FALSE );
		MainForm.DBFTable1.OEMTranslate := FALSE;
		if ( MainForm.DBFTable1.Seek( IntToStr( nCsoport ))) then begin
			MainForm.DBFTable1.Edit;
			WriteLogFile( 'Számlaszámok felírása: ' + IntToStr( nCsoport ) + ' (' + IntToStr( nMaxSzla ) + ')',4 );
			MainForm.DBFTable1.OEMTranslate := TRUE;
			MainForm.DBFTable1.FieldByName( 'SORSZAM' ).AsInteger := nMaxSzla;
			MainForm.DBFTable1.Commit;
		end;
		MainForm.DBFTable1.Close;
	end;
// Pénztár törzs
	MainForm.DBFTable3.Close;
	MainForm.DBFTable3.DatabaseName := Copy( InSyncItem.LocalYearDatabase, 1, Length( InSyncItem.LocalYearDatabase ) - 1 );
	MainForm.DBFTable3.TableName := InSyncItem.LocalYearDatabase + 'P33.DBF';
	try
		MainForm.DBFTable3.Active := TRUE;
		MainForm.DBFTable3.Exclusive := FALSE;
		MainForm.DBFTable3.IndexDefs.Clear;
		MainForm.DBFTable3.CloseIndexes;
		MainForm.DBFTable3.IndexOpen( InSyncItem.LocalYearDatabase + 'P331.NTX' );
		MainForm.DBFTable3.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalYearDatabase + 'P33.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;
// Pénztárbizonylat letöltés
	WriteLogFile( 'Linzer pénztárbizonylatok letöltése megkezdve.',2 );
	MainForm.DBFTable1.Close;
	MainForm.DBFTable1.DatabaseName := Copy( InSyncItem.LocalShareDatabase, 1, Length( InSyncItem.LocalShareDatabase ) - 1 );
	MainForm.DBFTable1.TableName := InSyncItem.LocalShareDatabase + 'P31.DBF';
	try
		MainForm.DBFTable1.Active := TRUE;
		MainForm.DBFTable1.Exclusive := FALSE;
		MainForm.DBFTable1.CloseIndexes;
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P311.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P312.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P313.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P314.NTX' );
		MainForm.DBFTable1.IndexOpen( InSyncItem.LocalShareDatabase + 'P315.NTX' );
		MainForm.DBFTable1.SetOrder( 1 );
	except
		on E : Exception do begin
			WriteLogFile( 'Hiba a ' + InSyncItem.LocalShareDatabase + 'P31.DBF állomány megnyitásakor :' + E.Message,2 );
			Exit;
		end;
	end;

// A legutolsó pénztárbizonylat megkeresése
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'SELECT FIRST 1 "penztarbizonylat"."kulcs" FROM "penztarbizonylat"';
		lResult := MyFBSQLSelect( cSQL );
		nCsoport := StrToInt( Copy( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,5,2 ));
	end else begin
// Ha MySQL szerver van
		cSQL := 'SELECT penztarbizonylat.kulcs FROM penztarbizonylat LIMIT 1';
		lResult := MyMySQLSelect( cSQL );
		nCsoport := StrToInt( Copy( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,5,2 ));
	end;
	if ( lResult ) then begin
		MainForm.DBFTable1.OEMTranslate := FALSE;
		MainForm.AlmiraEnv.SetSoftSeek( TRUE );
		cNewKey := Trim( IntToStr( InSyncItem.ActYear )) + PadL( IntToStr( nCsoport + 1 ),2,' ' );
		WriteLogFile( 'Legutolsó pénztárbizonylat megkeresése :' + cNewKey, 4 );
		MainForm.DBFTable1.Seek( cNewKey );
		WriteLogFile( 'Rekordszám :' + IntToStr( MainForm.DBFTable1.RecordCount ), 4 );
		WriteLogFile( 'Rekord :' + IntToStr( MainForm.DBFTable1.RecNo ), 4 );
		WriteLogFile( 'Kikeresve :' + MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString, 4 );
		if ( MainForm.DBFTable1.Eof ) or ( MainForm.DBFTable1.RecNo > MainForm.DBFTable1.RecordCount ) then begin
			MainForm.DBFTable1.GoTop;
			MainForm.DBFTable1.Skip( MainForm.DBFTable1.RecordCount - 1 );
				cNewKey := IntTosTr( InSyncItem.ActYear ) + PadL( IntToStr( nCsoport ),2,' ' ) + '0000001';
		end else begin
			if ( Copy( MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString,1,4 ) < IntTosTr( InSyncItem.ActYear )) then begin
				cNewKey := IntTosTr( InSyncItem.ActYear ) + PadL( IntToStr( nCsoport ),2,' ' ) + '0000001';
			end else begin
				if ( Copy( MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString,1,4 ) > IntTosTr( InSyncItem.ActYear )) or
				 ( Copy( MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString,5,2 ) > PadL( IntToStr( nCsoport ),2,' ' )) then begin
					MainForm.DBFTable1.Skip( -1 );
					cNewKey := MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString;
				end;
				if ( Copy( MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString,1,4 ) = IntTosTr( InSyncItem.ActYear )) or
				 ( Copy( MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString,5,2 ) = PadL( IntToStr( nCsoport ),2,' ' )) then begin
					cNewKey := MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString;
				 end;
			end;
		end;
		nMaxSzla := StrToInt( Copy( cNewKey,7,7 ));
		WriteLogFile( 'Legutolsó pénztárbizonylat :' + cNewKey, 4 );
		WriteLogFile( 'Legutolsó pénztárbizonylat :' + IntToStr( nMaxSzla ), 4 );
		if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
			cSQL := 'SELECT "penztarbizonylat"."kulcs", "penztarbizonylat"."szlaszam", "penztarbizonylat"."pkod", "penztarbizonylat"."kelt", ' +
				'"penztarbizonylat"."fj", "penztarbizonylat"."forgalom", "penztarbizonylat"."megj", "penztarbizonylat"."arfolyam", "penztarbizonylat"."arfkul", ' +
				'"penztarbizonylat"."devforg", "partner"."nev" FROM "penztarbizonylat" ' +
				'LEFT JOIN "partner" ON ( "partner"."kod" = "penztarbizonylat"."pkod" ) ' +
				'WHERE "penztarbizonylat"."kulcs" > ' + QuotedStr( cNewKey ) + ' ' +
				'ORDER BY "kulcs"';
			lResult := MyFBSQLSelect( cSQL );
			if ( lResult ) and ( MainForm.SyncFBQuery.RecordCount <> 0 ) then begin
				cLastBiz := 'X';
				lWriteBiz := FALSE;
				MainForm.SyncFBQuery.First;
				while ( not MainForm.SyncFBQuery.Eof ) do begin
					Application.ProcessMessages;
					MainForm.Refresh;
	// Beszúrjuk a bizonylatsort (P31)
					MainForm.DBFTable1.OEMTranslate := FALSE;
					MainForm.AlmiraEnv.SetSoftSeek( FALSE );
	// Ha nincs még ilyen pénztárbizonylat sor
					MainForm.DBFTable1.Seek( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString );
					if ( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString <> MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString ) then begin
						if ( cLastBiz = 'X' ) then begin
							BizKontir.Clear;
							BizKontir.BizSzam := LeftStr( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,13 );
							BizKontir.BizTipus := 'S';
							BizKontir.BizDate := MainForm.SyncFBQuery.FieldByName( 'KELT' ).AsDateTime;
						end;
						WriteLogFile( 'Új pénztárbizonylat sor beszúrása :' + MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString, 4 );
						MainForm.DBFTable1.OEMTranslate := TRUE;
						MainForm.DBFTable1.Append;
						MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString := MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString;
						MainForm.DBFTable1.FieldByName( 'KELT' ).AsDateTime := MainForm.SyncFBQuery.FieldByName( 'KELT' ).AsDateTime;
						MainForm.DBFTable1.FieldByName( 'FJ' ).AsString := MainForm.SyncFBQuery.FieldByName( 'FJ' ).AsString;
						MainForm.DBFTable1.FieldByName( 'MEGJ' ).AsString := MainForm.SyncFBQuery.FieldByName( 'MEGJ' ).AsString;
						MainForm.DBFTable1.FieldByName( 'DEVFORG' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'DEVFORG' ).AsFloat;
						MainForm.DBFTable1.FieldByName( 'FORGALOM' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'FORGALOM' ).AsFloat;
						MainForm.DBFTable1.FieldByName( 'ARFOLYAM' ).AsFloat := MainForm.SyncFBQuery.FieldByName( 'ARFOLYAM' ).AsFloat;
						if ( MainForm.SyncFBQuery.FieldByName( 'FJ' ).AsString = 'B' ) then begin
							MainForm.DBFTable1.FieldByName( 'SZFJ' ).AsString := 'K';
							if (MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsInteger = 0 ) then begin
								MainForm.DBFTable1.FieldByName( 'FKSZ' ).AsString := '';
								MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := LeftStr( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,4 ) + 'V1';
								MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := '';
							end else begin
								MainForm.DBFTable1.FieldByName( 'FKSZ' ).AsString := '311   ' + MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
								MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := MainForm.SyncFBQuery.FieldByName( 'SZLASZAM' ).AsString;
							MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
							end;
						end else begin
							MainForm.DBFTable1.FieldByName( 'SZFJ' ).AsString := 'B';
							MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := LeftStr( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,4 ) + 'V1';
							MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := '';
						end;
						MainForm.DBFTable1.FieldByName( 'UTDAT' ).AsFloat := Now;
						MainForm.DBFTable1.FieldByName( 'ROGKOD' ).AsFloat := 99;
						MainForm.DBFTable1.Commit;
						nMaxSzla := StrToInt( Copy( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,7,7 ));
						nCsoport := StrToInt( Copy( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,5,2 ));
	// Innen jön a kontírozós rész
						if ( MainForm.SyncFBQuery.FieldByName( 'FJ' ).AsString = 'B' ) then begin
							lWriteBiz := TRUE;
							MainForm.AlmiraEnv.SetSoftSeek( FALSE );
							MainForm.DBFTable3.OEMTranslate := FALSE;
							MainForm.DBFTable3.Seek( IntToStr( nCsoport ));
							cFKSz1 := '311   ' + MainForm.SyncFBQuery.FieldByName( 'PKOD' ).AsString;
							cKTNem1 := '';
							nRJ1 := 0;
							cFKSz2 := MainForm.DBFTable3.FieldByName( 'FKSZ' ).AsString;
							cKTNem2 := '';
							nRJ2 := 0;
	// Kikontírozzuk a pénztárbizonylatot
							cNewKey := FormatDateTime( 'YYYYMMDD', MainForm.DBFTable1.FieldByName( 'KELT' ).AsDateTime ) +
								PadR( cFKSz1,11,' ' ) + PadR( cKTNem1,6,' ' ) + PadR( IntToStr( nRJ1 ),5, ' ' ) +
								PadR( cFKSz2,11,' ' ) + PadR( cKTNem2,6,' ' ) + PadR( IntToStr( nRJ2 ),5, ' ' );
							BizKontir.KeyInsert( cNewKey,
								MainForm.DBFTable1.FieldByName( 'FORGALOM' ).AsFloat,
								0,
								0,
								MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString,
								MainForm.SyncFBQuery.FieldByName( 'NEV' ).AsString );
						end;
					end;
					cLastBiz := LeftStr( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString,13 );
					MainForm.SyncFBQuery.Next;
					if ( cLastBiz <> LeftStr( MainForm.SyncFBQuery.FieldByName( 'KULCS' ).AsString, 13 )) then begin
						if ( lWriteBiz ) then begin
	// Felírjuk a bizonylat kontírozását
							BizKontir.WriteDBF( MainForm.DBFTable5 );
						end;
						cLastBiz := 'X';
					end;
				end;
				MainForm.SyncFBQuery.Close;
			end;
		end else begin
// Ha MySQL szerver van
			cSQL := 'SELECT penztarbizonylat.kulcs, penztarbizonylat.szlaszam, penztarbizonylat.pkod, penztarbizonylat.kelt, ' +
				'penztarbizonylat.fj, penztarbizonylat.forgalom, penztarbizonylat.megj1, penztarbizonylat.arfolyam, penztarbizonylat.arfkul, ' +
				'penztarbizonylat.devforg, partner.nev1 FROM penztarbizonylat ' +
				'LEFT JOIN partner ON ( partner.kod = penztarbizonylat.pkod ) ' +
				'WHERE penztarbizonylat.kulcs > ' + QuotedStr( cNewKey ) + ' ' +
				'ORDER BY kulcs';
			lResult := MyMySQLSelect( cSQL );
			if ( lResult ) and ( MainForm.SyncMySQLQuery.RecordCount <> 0 ) then begin
				cLastBiz := 'X';
				lWriteBiz := FALSE;
				MainForm.SyncMySQLQuery.First;
				while ( not MainForm.SyncMySQLQuery.Eof ) do begin
					Application.ProcessMessages;
					MainForm.Refresh;
	// Beszúrjuk a bizonylatsort (P31)
					MainForm.DBFTable1.OEMTranslate := FALSE;
					MainForm.AlmiraEnv.SetSoftSeek( FALSE );
	// Ha nincs még ilyen pénztárbizonylat sor
					MainForm.DBFTable1.Seek( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString );
					if ( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString <> MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString ) then begin
						if ( cLastBiz = 'X' ) then begin
							BizKontir.Clear;
							BizKontir.BizSzam := LeftStr( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,13 );
							BizKontir.BizTipus := 'S';
							BizKontir.BizDate := MainForm.SyncMySQLQuery.FieldByName( 'KELT' ).AsDateTime;
						end;
						WriteLogFile( 'Új pénztárbizonylat sor beszúrása :' + MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString, 4 );
						MainForm.DBFTable1.OEMTranslate := TRUE;
						MainForm.DBFTable1.Append;
						MainForm.DBFTable1.FieldByName( 'KULCS' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString;
						MainForm.DBFTable1.FieldByName( 'KELT' ).AsDateTime := MainForm.SyncMySQLQuery.FieldByName( 'KELT' ).AsDateTime;
						MainForm.DBFTable1.FieldByName( 'FJ' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'FJ' ).AsString;
						MainForm.DBFTable1.FieldByName( 'MEGJ' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'MEGJ1' ).AsString;
						MainForm.DBFTable1.FieldByName( 'DEVFORG' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'DEVFORG' ).AsFloat;
						MainForm.DBFTable1.FieldByName( 'FORGALOM' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'FORGALOM' ).AsFloat;
						MainForm.DBFTable1.FieldByName( 'ARFOLYAM' ).AsFloat := MainForm.SyncMySQLQuery.FieldByName( 'ARFOLYAM' ).AsFloat;
						if ( MainForm.SyncMySQLQuery.FieldByName( 'FJ' ).AsString = 'B' ) then begin
							MainForm.DBFTable1.FieldByName( 'SZFJ' ).AsString := 'K';
							if (MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsInteger = 0 ) then begin
								MainForm.DBFTable1.FieldByName( 'FKSZ' ).AsString := '';
								MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := LeftStr( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,4 ) + 'V1';
								MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := '';
							end else begin
								MainForm.DBFTable1.FieldByName( 'FKSZ' ).AsString := '311   ' + MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
								MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'SZLASZAM' ).AsString;
							MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
							end;
						end else begin
							MainForm.DBFTable1.FieldByName( 'SZFJ' ).AsString := 'B';
							MainForm.DBFTable1.FieldByName( 'SZLASZAM' ).AsString := LeftStr( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,4 ) + 'V1';
							MainForm.DBFTable1.FieldByName( 'PKOD' ).AsString := '';
						end;
						MainForm.DBFTable1.FieldByName( 'UTDAT' ).AsFloat := Now;
						MainForm.DBFTable1.FieldByName( 'ROGKOD' ).AsFloat := 99;
						MainForm.DBFTable1.Commit;
						nMaxSzla := StrToInt( Copy( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,7,7 ));
						nCsoport := StrToInt( Copy( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,5,2 ));
	// Innen jön a kontírozós rész
						if ( MainForm.SyncMySQLQuery.FieldByName( 'FJ' ).AsString = 'B' ) then begin
							lWriteBiz := TRUE;
							MainForm.AlmiraEnv.SetSoftSeek( FALSE );
							MainForm.DBFTable3.OEMTranslate := FALSE;
							MainForm.DBFTable3.Seek( IntToStr( nCsoport ));
							cFKSz1 := '311   ' + MainForm.SyncMySQLQuery.FieldByName( 'PKOD' ).AsString;
							cKTNem1 := '';
							nRJ1 := 0;
							cFKSz2 := MainForm.DBFTable3.FieldByName( 'FKSZ' ).AsString;
							cKTNem2 := '';
							nRJ2 := 0;
	// Kikontírozzuk a pénztárbizonylatot
							cNewKey := FormatDateTime( 'YYYYMMDD', MainForm.DBFTable1.FieldByName( 'KELT' ).AsDateTime ) +
								PadR( cFKSz1,11,' ' ) + PadR( cKTNem1,6,' ' ) + PadR( IntToStr( nRJ1 ),5, ' ' ) +
								PadR( cFKSz2,11,' ' ) + PadR( cKTNem2,6,' ' ) + PadR( IntToStr( nRJ2 ),5, ' ' );
							BizKontir.KeyInsert( cNewKey,
								MainForm.DBFTable1.FieldByName( 'FORGALOM' ).AsFloat,
								0,
								0,
								MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString,
								MainForm.SyncMySQLQuery.FieldByName( 'NEV1' ).AsString );
						end;
					end;
					cLastBiz := LeftStr( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString,13 );
					MainForm.SyncMySQLQuery.Next;
					if ( cLastBiz <> LeftStr( MainForm.SyncMySQLQuery.FieldByName( 'KULCS' ).AsString, 13 )) then begin
						if ( lWriteBiz ) then begin
	// Felírjuk a bizonylat kontírozását
							BizKontir.WriteDBF( MainForm.DBFTable5 );
						end;
						cLastBiz := 'X';
					end;
				end;
				MainForm.SyncMySQLQuery.Close;
			end;

		end;
	end;
// pénztárbizonylat számának felírása
	if ( nCsoport <> 0 ) and ( nMaxSzla <> 0 ) then begin
		MainForm.AlmiraEnv.SetSoftSeek( FALSE );
		MainForm.DBFTable3.OEMTranslate := FALSE;
		if ( MainForm.DBFTable3.Seek( IntToStr( nCsoport ))) then begin
			MainForm.DBFTable3.Edit;
			WriteLogFile( 'Bizonylatszámok felírása: ' + IntToStr( nCsoport ) + ' (' + IntToStr( nMaxSzla ) + ')',4 );
			MainForm.DBFTable3.OEMTranslate := TRUE;
			MainForm.DBFTable3.FieldByName( 'BIZSZAM' ).AsInteger := nMaxSzla;
			MainForm.DBFTable3.Commit;
		end;
	end;
	MainForm.DBFTable1.CloseIndexes;
	MainForm.DBFTable1.Close;
	MainForm.DBFTable2.Close;
	MainForm.DBFTable3.Close;
	MainForm.DBFTable4.Close;
	MainForm.DBFTable5.Close;
	if ( InSyncItem.SQLType = sqt_Firebird ) then begin
// Ha Firebird szerver van
		cSQL := 'UPDATE "syncdate" SET "syncdate"."lastdownload" = CURRENT_TIMESTAMP WHERE "syncdate"."tablename" = ' + QuotedStr( 'penztarbizonylat' );;
		MyFBSQLCommand( cSQL );
	end else begin
// Ha MySQL szerver van
		cSQL := 'UPDATE syncdate SET syncdate.lastdownload = CURRENT_TIMESTAMP WHERE syncdate.tablename = ' + QuotedStr( 'penztarbizonylat' );
		MyMySQLCommand( cSQL );
	end;
	WriteLogFile( 'Pénztárbizonylat adatok letöltése kész. ',2 );
	StartButton.Enabled := TRUE;
	BizKontir.Destroy;
end;

end.
