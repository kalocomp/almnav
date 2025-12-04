unit kontir;

interface

uses System.Classes, System.SysUtils, StrUtils, ApoDSet, apoEnv;

type

	TBizKontir = class;

	TKontirItem = class( TCollectionItem )
	private
		FFKSz1 : string;
		FKTNem1 : string;
		FRJ1 : integer;
		FFKSz2 : string;
		FKTNem2 : string;
		FRJ2 : integer;
		FForgalom : single;
		FMenny1 : single;
		FMenny2 : single;
		FText1 : string;
		FText2 : string;
		FKontirKey : string;
	public
		constructor Create( Collection: TCollection ); override;
		destructor Destroy; override;
		procedure Assign(Source: TPersistent); override;
		function GetKontirKey : string;
	published
		property FKSz1 : string read FFKSz1 write FFKSz1;
		property KTNem1 : string read FKTNem1 write FKTNem1;
		property RJ1 : integer read FRJ1 write FRJ1;
		property FKSz2 : string read FFKSz2 write FFKSz2;
		property KTNem2 : string read FKTNem2 write FKTNem2;
		property RJ2 : integer read FRJ2 write FRJ2;
		property Forgalom : single read FForgalom write FForgalom;
		property Menny1 : single read FMenny1 write FMenny1;
		property Menny2 : single read FMenny2 write FMenny2;
		property Text1 : string read FText1 write FText1;
		property Text2 : string read FText2 write FText2;
		property KontirKey : string read GetKontirKey;
	end;

	TKontir = class( TCollection )
	private
		FOwner : TBizKontir;
		function GetItem( Index : integer ) : TKontirItem;
		procedure SetItem( Index : integer; const Value : TKontirItem );
	protected
	public
		constructor Create( AOwner : TBizKontir );
		destructor Destroy; override;
		procedure Clear;
		function GetOwner : TPersistent; override;
		function Add : TKontirItem;
		function Insert( Index : integer ) : TKontirItem;
		property Items[ Index : integer ] : TKontirItem read GetItem write SetItem; default;
		property Bizonylat : TBizKontir read FOwner;
	end;

	TSumItem = class( TCollectionItem )
	private
		FFJ : string;
		FMonth : integer;
		FFKSz : string;
		FKTNem : string;
		FRJ : integer;
		FForgalom : single;
		FMenny : single;
		FDarab : integer;
		FKontirKey : string;
	public
		constructor Create( Collection: TCollection ); override;
		destructor Destroy; override;
		procedure Assign(Source: TPersistent); override;
		function GetKontirKey : string;
	published
		property FJ : string read FFJ write FFJ;
		property Month : integer read FMonth write FMonth;
		property FKSz : string read FFKSz write FFKSz;
		property KTNem : string read FKTNem write FKTNem;
		property RJ : integer read FRJ write FRJ;
		property Forgalom : single read FForgalom write FForgalom;
		property Menny : single read FMenny write FMenny;
		property Darab : integer read FDarab write FDarab;
		property KontirKey : string read GetKontirKey;
	end;

	TSumKontir = class( TCollection )
	private
		function GetItem( Index : integer ) : TSumItem;
		procedure SetItem( Index : integer; const Value : TSumItem );
	protected
	public
		constructor Create( AOwner : TBizKontir );
		destructor Destroy; override;
		procedure Clear;
		function Add : TSumItem;
		function Insert( Index : integer ) : TSumItem;
		property Items[ Index : integer ] : TSumItem read GetItem write SetItem; default;
	end;

	TBizKontir = class( TPersistent )
	private
		FBizSzam : string;
		FBizTipus : string;
		FBizDate : TDateTime;
		FKontir : TKontir;
		FSumKontir : TSumKontir;
		FBizMonth : integer;
		FBizSumText : string;
	public
		constructor Create;
		destructor Destroy; override;
		procedure KeyInsert( cInKey : string; nInForgalom, nInMenny1, nInMenny2 : single; cInText1, cInText2 : string );
		procedure SumInsert( cInFJ, cInFKsz, cInKTNem : string; nInRJ, nInMonth, nInDarab : integer; nInForgalom, nInMenny : single );
		procedure WriteDBF( F15Table : TApolloTable );
		procedure Clear;
		function GetBizMonth : integer;
		function GetBizSumText : string;
	published
		property BizSzam : string read FBizSzam write FBizSzam;
		property BizTipus : string read FBizTipus write FBizTipus;
		property Kontir : TKontir read FKontir write FKontir;
		property SumKontir : TSumKontir read FSumKontir write FSumKontir;
		property BizDate : TDateTime read FBizDate write FBizDate;
		property BizMonth : integer read GetBizMonth;
		property BizSumText : string read GetBizSumText;
	end;

implementation

uses crypt, Main, System.DateUtils;

// TKontirItem
constructor TKontirItem.Create( Collection: TCollection );
begin
	inherited;
	FFKsz1 := '';
	FKTNem1 := '';
	FRJ1 := 0;
	FFKsz2 := '';
	FKTNem2 := '';
	FRJ2 := 0;
	FForgalom := 0;
	FMenny1 := 0;
	FMenny2 := 0;
	FText1 := '';
	FText2 := '';
end;

destructor TKontirItem.Destroy;
begin
	inherited;
end;

procedure TKontirItem.Assign( Source: TPersistent );
begin
	if ( Source is TKontirItem ) then begin
		FFKsz1 := TKontirItem( Source ).FFKSz1;
		FKTNem1 := TKontirItem( Source ).FKTNem1;
		FRJ1 := TKontirItem( Source ).FRJ1;
		FFKsz2 := TKontirItem( Source ).FFKSz2;
		FKTNem2 := TKontirItem( Source ).FKTNem2;
		FRJ2 := TKontirItem( Source ).FRJ2;
		FMenny1 := TKontirItem( Source ).FMenny1;
		FMenny2 := TKontirItem( Source ).FMenny2;
		FForgalom := TKontirItem( Source ).FForgalom;
		FText1 := TKontirItem( Source ).FText1;
		FText2 := TKontirItem( Source ).FText2;
	end else begin
		inherited Assign( Source );
	end;
end;

function TKontirItem.GetKontirKey: string;
var
	ItemOwner										: TCollection;
	dBizDate										: TDateTime;
begin
	dBizDate := TKontir( Collection ).Bizonylat.FBizDate;
	Result := FormatDateTime( 'YYYYMMDD', dBizDate ) + PadR( Self.FFKSz1,11,' ' ) + PadR( Self.FKTNem1,6,' ' ) + PadR( IntToStr( Self.FRJ1 ),5,' ' ) +
		PadR( Self.FFKSz2,11,' ' ) + PadR( Self.FKTNem2,6,' ' ) + PadR( IntToStr( Self.FRJ2 ),5,' ' );
end;

// TKontir
constructor TKontir.Create;
begin
	inherited Create( TKontirItem );
	FOwner := AOwner;
end;

destructor TKontir.Destroy;
begin
	while ( Self.Count > 0 ) do begin
//		Self.Items[ Self.Count - 1 ].Free;
		Self.Items[ Self.Count - 1 ].Destroy;
	end;
	inherited;
end;

function TKontir.Add : TKontirItem;
begin
	Result := TKontirItem( inherited Add );
	Result.FFKSz1 := '';
	Result.FKTNem1 := '';
	Result.FRJ1 := 0;
	Result.FMenny1 := 0;
	Result.FText1 := '';
	Result.FFKSz2 := '';
	Result.FKTNem2 := '';
	Result.FRJ2 := 0;
	Result.FMenny2 := 0;
	Result.FText2 := '';
	Result.FForgalom := 0;
end;

function TKontir.GetOwner: TPersistent;
begin
	Result := FOwner;
end;

function TKontir.GetItem( Index: integer) : TKontirItem;
begin
  Result := TKontirItem( inherited Items[ Index ]);
end;

function TKontir.Insert(Index: integer) : TKontirItem;
begin
  Result := TKontirItem( inherited Insert( Index ));
end;

procedure TKontir.SetItem( Index : integer; const Value : TKontirItem);
begin
	inherited Items[ Index ] := Value;
end;

procedure TKontir.Clear;
begin
	while ( Self.Count > 0 ) do begin
		Self.Items[ Self.Count - 1 ].Destroy;
	end;
	inherited;
end;

// TSumItem
constructor TSumItem.Create( Collection: TCollection );
begin
	inherited;
	FMonth := 0;
	FFKsz := '';
	FKTNem := '';
	FRJ := 0;
	FForgalom := 0;
	FMenny := 0;
	FDarab := 0;
end;

destructor TSumItem.Destroy;
begin
	inherited;
end;

procedure TSumItem.Assign( Source: TPersistent );
begin
	if ( Source is TSumItem ) then begin
		FMonth := TSumItem( Source ).FMonth;
		FFKsz := TSumItem( Source ).FFKSz;
		FKTNem := TSumItem( Source ).FKTNem;
		FRJ := TSumItem( Source ).FRJ;
		FMenny := TSumItem( Source ).FMenny;
		FForgalom := TSumItem( Source ).FForgalom;
		FDarab := TSumItem( Source ).FDarab;
	end else begin
		inherited Assign( Source );
	end;
end;

function TSumItem.GetKontirKey: string;
begin
	Result := Self.FFJ +  PadR( Self.FFKSz,11,' ' ) + PadR( Self.FKTNem,6,' ' ) + PadR( IntToStr( Self.FRJ ),5,' ' ) + PadR( IntToStr( Self.FMonth ),2,' ' );
end;

// TSumKontir
constructor TSumKontir.Create;
begin
	inherited Create( TSumItem );
end;

destructor TSumKontir.Destroy;
begin
	while ( Self.Count > 0 ) do begin
//		Self.Items[ Self.Count - 1 ].Free;
		Self.Items[ Self.Count - 1 ].Destroy;
	end;
	inherited;
end;

function TSumKontir.Add : TSumItem;
begin
	Result := TSumItem( inherited Add );
	Result.FMonth := 0;
	Result.FFKSz := '';
	Result.FKTNem := '';
	Result.FRJ := 0;
	Result.FMenny := 0;
	Result.FForgalom := 0;
end;

function TSumKontir.GetItem( Index: integer) : TSumItem;
begin
	Result := TSumItem( inherited Items[ Index ]);
end;

function TSumKontir.Insert(Index: integer) : TSumItem;
begin
	Result := TSumItem( inherited Insert( Index ));
end;

procedure TSumKontir.SetItem( Index : integer; const Value : TSumItem);
begin
	inherited Items[ Index ] := Value;
end;

procedure TSumKontir.Clear;
begin
	while ( Self.Count > 0 ) do begin
		Self.Items[ Self.Count - 1 ].Destroy;
	end;
	inherited;
end;

constructor TBizKontir.Create;
begin
	inherited;
	FBizTipus := '';
	FBizSzam := '';
	FBizTipus := 'P';
	FBizMonth := 1;
	FBizSumText := '';
	FKontir := TKontir.Create( Self );
	FSumKontir := TSumKontir.Create( Self );
end;

destructor TBizKontir.Destroy;
begin
	FKontir.Destroy;
	inherited;
end;

function TBizKontir.GetBizMonth : integer;
begin
	Result := MonthOfTheYear( FBizDate );
end;

function TBizKontir.GetBizSumText : string;
begin
	if ( FBizTipus = 'P' ) then Result := 'kimenõ számla';
	if ( FBizTipus = 'R' ) then Result := 'banki bizonylat';
	if ( FBizTipus = 'S' ) then Result := 'pénztári bizonylat';
end;


procedure TBizKontir.KeyInsert( cInKey : string; nInForgalom, nInMenny1, nInMenny2 : single; cInText1, cInText2 : string );
var
	I,nActItem												: integer;
	NewKontirItem											: TKontirItem;
	cSeged													: string;
begin
	nActItem := -1;
	if ( Trim( Copy( cInKey,9,11 )) <> '' ) and ( Trim( Copy( cInKey,31,11 )) <> '' ) then begin
		for I := 0 to Self.FKontir.Count - 1 do begin
			if ( Self.FKontir.Items[ I ].KontirKey = cInKey ) then begin
				nActItem := I;
			end;
		end;
		if ( nActItem = -1 ) then begin
			NewKontirItem := Self.FKontir.Add;
			NewKontirItem.FFKSz1 := Copy( cInKey,9,11 );
			NewKontirItem.FKTNem1 := Copy( cInKey,20,6 );
			NewKontirItem.FRJ1 := StrToInt( Trim( Copy( cInKey,26,5 )));
			NewKontirItem.FFKSz2 := Copy( cInKey,31,11 );
			NewKontirItem.FKTNem2 := Copy( cInKey,42,6 );
			NewKontirItem.FRJ2 := StrToInt( Trim( Copy( cInKey,48,5 )));
			NewKontirItem.FText1 := cInText1;
			NewKontirItem.FText2 := cInText2;
		end else begin
			NewKontirItem := Self.FKontir.Items[ nActItem ];
		end;
		NewKontirItem.FForgalom := NewKontirItem.FForgalom + nInForgalom;
		NewKontirItem.FMenny1 := NewKontirItem.FMenny1 + nInMenny1;
		NewKontirItem.FMenny2 := NewKontirItem.FMenny2 + nInMenny2;
	end;
end;

procedure TBizKontir.SumInsert( cInFJ, cInFKSz, cInKTNem : string; nInRJ, nInMonth, nInDarab : integer; nInForgalom, nInMenny : single );
var
	I,nActItem												: integer;
	NewSumItem												: TSumItem;
	cSeged														: string;
begin
	nActItem := -1;
	cSeged := cInFJ + cInFKsz + cInKTNem + PadR( IntToStr( nInRJ ),5,' ' ) + PadR( IntToStr( nInMonth ),2,' ' );
	for I := 0 to Self.FSumKontir.Count - 1 do begin
		if ( Self.FSumKontir.Items[ I ].KontirKey = cSeged ) then begin
			nActItem := I;
		end;
	end;
	if ( nActItem = -1 ) then begin
		NewSumItem := Self.FSumKontir.Add;
		NewSumItem.FFJ := cInFJ;
		NewSumItem.FMonth := nInMonth;
		NewSumItem.FFKSz := cInFKSz;
		NewSumItem.FKTNem := cInKTNem;
		NewSumItem.FRJ := nInRJ;
	end else begin
		NewSumItem := Self.FSumKontir.Items[ nActItem ];
	end;
	NewSumItem.FForgalom := NewSumItem.FForgalom + nInForgalom;
	NewSumItem.FMenny := NewSumItem.FMenny + nInMenny;
	NewSumItem.FDarab := NewSumItem.FDarab + nInDarab;
end;

procedure TBizKontir.WriteDBF( F15Table : TApolloTable );
var
	I												: integer;
	cSumText								: string;
begin
// A gyûjtõ listát kitöröljük
	SumKontir.Clear;
// Kinullázzuk a bizonylathoz tartozó sorokat
	MainForm.AlmiraEnv.SetSoftSeek( TRUE );
	F15Table.SetOrder( 1 );
	F15Table.Seek( PadR( FBizTipus + FBizSzam,16,' ' ));
	while ( not F15Table.Eof ) and ( LeftStr( F15Table.FieldByName( 'KULCS' ).AsString,16 ) = PadR( FBizTipus + FBizSzam,16,' ' )) do begin
		if ( F15Table.FieldByName( 'ERVENYES' ).AsString <> 'N' ) then begin
			SumInsert( 'T', F15Table.FieldByName( 'FKSZ_TART' ).AsString, F15Table.FieldByName( 'KLTN_TART' ).AsString, F15Table.FieldByName( 'RJ_TART' ).AsInteger,
				MonthOfTheYear( F15Table.FieldByName( 'BDAT' ).AsDateTime ), -1, - F15Table.FieldByName( 'ERTEK' ).AsFloat, - F15Table.FieldByName( 'MENNYISEGT' ).AsFloat );
			SumInsert( 'K', F15Table.FieldByName( 'FKSZ_KOV' ).AsString, F15Table.FieldByName( 'KLTN_KOV' ).AsString, F15Table.FieldByName( 'RJ_KOV' ).AsInteger,
				MonthOfTheYear( F15Table.FieldByName( 'BDAT' ).AsDateTime ), -1, - F15Table.FieldByName( 'ERTEK' ).AsFloat, - F15Table.FieldByName( 'MENNYISEGK' ).AsFloat );
		end;
		F15Table.Edit;
		F15Table.FieldByName( 'ERVENYES' ).AsString := 'N';
		F15Table.FieldByName( 'FKSZ_TART' ).AsString := 'XXXXXXXXXXX';
		F15Table.FieldByName( 'FKSZ_KOV' ).AsString := 'XXXXXXXXXXX';
		F15Table.FieldByName( 'KLTN_TART' ).AsString := 'XXXXXX';
		F15Table.FieldByName( 'KLTN_KOV' ).AsString := 'XXXXXX';
		F15Table.FieldByName( 'ERTEK' ).AsSingle := 0;
		F15Table.FieldByName( 'MENNYISEGT' ).AsSingle := 0;
		F15Table.FieldByName( 'MENNYISEGK' ).AsSingle := 0;
		F15Table.Post;
		F15Table.Next;
	end;

// Felírjuk a bizonylathoz tartozó kontírozó sorokat
	for I := 0 to Self.FKontir.Count - 1 do begin
// Ha már van ilyen bizonylat sor
		MainForm.AlmiraEnv.SetSoftSeek( FALSE );
		F15Table.SetOrder( 1 );
		F15Table.Seek( PadR( FBizTipus + FBizSzam,16,' ' ) + PadL( IntToStr( I + 1 ),4,' ' ));
		if ( F15Table.FieldByName( 'KULCS' ).AsString = PadR( FBizTipus + FBizSzam,16,' ' ) + PadL( IntToStr( I + 1 ),4,' ' )) then begin
			F15Table.Edit;
		end else begin
			F15Table.SetOrder( 2 );
			MainForm.AlmiraEnv.SetSoftSeek( TRUE );
// Rákeresünk, hogy van-e üres sor az adatbázisban
			F15Table.Seek( 'X' );
			if (( not F15Table.Eof ) and ( F15Table.FieldByName( 'FKSZ_TART' ).AsString = 'XXXXXXXXXXX' )) then begin
				F15Table.Edit;
			end else begin
				F15Table.Append;
			end;
			F15Table.FieldByName( 'KULCS' ).AsString := PadR( FBizTipus + FBizSzam, 16, ' ' ) + PadL( IntToStr( I + 1 ),4,' ' );
			F15Table.FieldByName( 'ERVENYES' ).AsString := 'I';
			F15Table.FieldByName( 'FKSZ_TART' ).AsString := Self.FKontir.Items[ I ].FFKSz1;
			F15Table.FieldByName( 'FKSZ_KOV' ).AsString := Self.FKontir.Items[ I ].FFKSz2;
			F15Table.FieldByName( 'KLTN_TART' ).AsString := Self.FKontir.Items[ I ].FKTNem1;
			F15Table.FieldByName( 'KLTN_KOV' ).AsString := Self.FKontir.Items[ I ].FKTNem2;
			F15Table.FieldByName( 'RJ_TART' ).AsInteger := Self.FKontir.Items[ I ].FRJ1;
			F15Table.FieldByName( 'RJ_KOV' ).AsInteger := Self.FKontir.Items[ I ].FRJ2;
			F15Table.FieldByName( 'ERTEK' ).AsSingle := Self.FKontir.Items[ I ].FForgalom;
			F15Table.FieldByName( 'MENNYISEGT' ).AsSingle := Self.FKontir.Items[ I ].FMenny1;
			F15Table.FieldByName( 'MENNYISEGK' ).AsSingle := Self.FKontir.Items[ I ].FMenny2;
			F15Table.FieldByName( 'HONNAN' ).AsString := Self.BizTipus + PadL( IntToStr( Self.BizMonth ),2,' ' );
			F15Table.FieldByName( 'BDAT' ).AsDateTime := Self.FBizDate;
			F15Table.FieldByName( 'SZOVEGT' ).AsString := Self.FKontir.Items[ I ].FText1;
			F15Table.FieldByName( 'SZOVEGK' ).AsString := Self.FKontir.Items[ I ].FText2;
			F15Table.FieldByName( 'ROGZITO' ).AsInteger := 99;
			F15Table.FieldByName( 'UTDAT' ).AsDateTime := Now;
			F15Table.Post;
			SumInsert( 'T', Self.FKontir.Items[ I ].FFKSz1, Self.FKontir.Items[ I ].FKTNem1, Self.FKontir.Items[ I ].FRJ1,
				MonthOfTheYear( Self.FBizDate ), 1, Self.FKontir.Items[ I ].FForgalom, Self.FKontir.Items[ I ].FMenny1 );
			SumInsert( 'K', Self.FKontir.Items[ I ].FFKSz2, Self.FKontir.Items[ I ].FKTNem2, Self.FKontir.Items[ I ].FRJ2,
				MonthOfTheYear( Self.FBizDate ), 1, Self.FKontir.Items[ I ].FForgalom, Self.FKontir.Items[ I ].FMenny2 );
		end;
	end;
// Felírjuk a havi gyûjtött tételeket is
	for I := 0 to Self.SumKontir.Count - 1 do begin
// Ha tartozik tételrõl van szó
		if Self.FSumKontir.Items[ I ].FFJ = 'T' then begin
			F15Table.SetOrder( 2 );
			MainForm.AlmiraEnv.SetSoftSeek( TRUE );
// Rákeresünk, hogy ven-e már ilyen havi tétel
			F15Table.Seek( FSumKontir.Items[ I ].FFKSz + ' ' + PadL( IntToStr( FSumKontir.Items[ I ].FMonth ),2,' ' ));
			if ( PadR( F15Table.FieldByName( 'FKSZ_TART' ).AsString, 11, ' ' ) = Self.FSumKontir.Items[ I ].FFKSz ) and
				( F15Table.FieldByName( 'HONNAN' ).AsString = ' ' + PadL( IntToStr( FSumKontir.Items[ I ].FMonth ),2,' ' )) then begin
// Ha van akkor hozzáírunk
				F15Table.Edit;
			end else begin
// Ha nincs, akkor megnézzük, hogy üres rekord van-e
				F15Table.Seek( 'X' );
				if ( F15Table.FieldByName( 'FKSZ_TART' ).AsString = 'XXXXXXXXXXX' ) then begin
					F15Table.Edit;
				end else begin
// Ha nincs akkor csinálunk
					F15Table.Append;
				end;
				F15Table.FieldByName( 'KULCS' ).AsString := PadR( FBizTipus,20,' ' );
				F15Table.FieldByName( 'HONNAN' ).AsString := ' ' + PadL( IntToStr( FSumKontir.Items[ I ].FMonth ),2,' ' );
				F15Table.FieldByName( 'FKSZ_TART' ).AsString := Self.FSumKontir.Items[ I ].FFKSz;
				F15Table.FieldByName( 'FKSZ_KOV' ).AsString := 'YYYYYYYYYYY';
				F15Table.FieldByName( 'KLTN_TART' ).AsString := Self.FSumKontir.Items[ I ].FKTNem;
				F15Table.FieldByName( 'KLTN_KOV' ).AsString := 'YYYYYY';
				F15Table.FieldByName( 'RJ_TART' ).AsInteger := Self.FSumKontir.Items[ I ].FRJ;
				F15Table.FieldByName( 'RJ_KOV' ).AsInteger := 0;
				F15Table.FieldByName( 'SZOVEGT' ).AsString := IntToStr( FSumKontir.Items[ I ].FMonth ) + '. havi ' + Self.GetBizSumText;
			end;
			F15Table.FieldByName( 'MENNYISEGT' ).AsSingle := F15Table.FieldByName( 'MENNYISEGT' ).AsSingle + Self.FSumKontir.Items[ I ].FMenny;
		end else begin
// Ha követel tételrõl van szó
			F15Table.SetOrder( 4 );
			MainForm.AlmiraEnv.SetSoftSeek( TRUE );
// Rákeresünk, hogy ven-e már ilyen havi tétel
			F15Table.Seek( FSumKontir.Items[ I ].FFKSz + ' ' + PadL( IntToStr( FSumKontir.Items[ I ].FMonth ),2,' ' ));
			if ( PadR( F15Table.FieldByName( 'FKSZ_KOV' ).AsString, 11, ' ' ) = Self.FSumKontir.Items[ I ].FFKSz ) and
				( F15Table.FieldByName( 'HONNAN' ).AsString = ' ' + PadL( IntToStr( FSumKontir.Items[ I ].FMonth ),2,' ' )) then begin
// Ha van akkor hozzáírunk
				F15Table.Edit;
			end else begin
// Ha nincs, akkor megnézzük, hogy üres rekord van-e
				F15Table.Seek( 'X' );
				if ( F15Table.FieldByName( 'FKSZ_KOV' ).AsString = 'XXXXXXXXXXX' ) then begin
					F15Table.Edit;
				end else begin
// Ha nincs akkor csinálunk
					F15Table.Append;
				end;
// Ha nincs akkor csinálunk
				F15Table.Append;
				F15Table.FieldByName( 'KULCS' ).AsString := PadR( FBizTipus,20,' ' );
				F15Table.FieldByName( 'HONNAN' ).AsString := ' ' + PadL( IntToStr( FSumKontir.Items[ I ].FMonth ),2,' ' );
				F15Table.FieldByName( 'FKSZ_KOV' ).AsString := Self.FSumKontir.Items[ I ].FFKSz;
				F15Table.FieldByName( 'FKSZ_TART' ).AsString := 'YYYYYYYYYYY';
				F15Table.FieldByName( 'KLTN_KOV' ).AsString := Self.FSumKontir.Items[ I ].FKTNem;
				F15Table.FieldByName( 'KLTN_TART' ).AsString := 'YYYYYY';
				F15Table.FieldByName( 'RJ_KOV' ).AsInteger := Self.FSumKontir.Items[ I ].FRJ;
				F15Table.FieldByName( 'RJ_TART' ).AsInteger := 0;
				F15Table.FieldByName( 'SZOVEGK' ).AsString := IntToStr( FSumKontir.Items[ I ].FMonth ) + '. havi ' + Self.GetBizSumText;
			end;
			F15Table.FieldByName( 'MENNYISEGK' ).AsSingle := F15Table.FieldByName( 'MENNYISEGK' ).AsSingle + Self.FSumKontir.Items[ I ].FMenny;
		end;
		F15Table.FieldByName( 'ERVENYES' ).AsString := 'I';
		F15Table.FieldByName( 'ERTEK' ).AsSingle := F15Table.FieldByName( 'ERTEK' ).AsSingle + Self.FSumKontir.Items[ I ].FForgalom;
		F15Table.FieldByName( 'DARABSZAM' ).AsInteger := F15Table.FieldByName( 'DARABSZAM' ).AsInteger + Self.FSumKontir.Items[ I ].FDarab;
		F15Table.FieldByName( 'BDAT' ).AsDateTime := StartOfTheMonth( Self.FBizDate );
		F15Table.FieldByName( 'WINKULD' ).AsString := ' ';
		F15Table.FieldByName( 'ROGZITO' ).AsInteger := 99;
		F15Table.FieldByName( 'UTDAT' ).AsDateTime := Now;

		if ( F15Table.FieldByName( 'DARABSZAM' ).AsInteger = 0 ) and
			( F15Table.FieldByName( 'ERTEK' ).AsInteger = 0 ) and
			( F15Table.FieldByName( 'MENNYISEGT' ).AsInteger = 0 ) and
			( F15Table.FieldByName( 'MENNYISEGK' ).AsInteger = 0 ) then begin
			F15Table.FieldByName( 'FKSZ_KOV' ).AsString := 'XXXXXXXXXXX';
			F15Table.FieldByName( 'FKSZ_TART' ).AsString := 'XXXXXXXXXXX';
			F15Table.FieldByName( 'KLTN_KOV' ).AsString := 'XXXXXX';
			F15Table.FieldByName( 'KLTN_TART' ).AsString := 'XXXXXX';
			F15Table.FieldByName( 'ERVENYES' ).AsString := 'N';
		end;
		F15Table.Post;
	end;
end;

procedure TBizKontir.Clear;
begin
	Self.FKontir.Clear;
end;

end.

