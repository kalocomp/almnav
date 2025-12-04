unit navreadsetting;

interface

uses System.Classes, NAV, invoice;

type
// NAVReadSettings definiálása
	TNAVReadSettings = class;

	TNAVReadItem = class( TCollectionItem )
	private
		FSor : integer;
		FAlmiraPath : AnsiString;
		FAlmiraSharePath : AnsiString;
		FStartDate : TDateTime;
	public
		constructor Create( Collection: TCollection ); override;
		procedure Assign(Source: TPersistent); override;
	published
		property Sor : integer read FSor write FSor default 0;
		property AlmiraPath : AnsiString read FAlmiraPath write FAlmiraPath;
		property AlmiraSharePath : AnsiString read FAlmiraSharePath write FAlmiraSharePath;
		property StartDate: TDateTime read FStartDate write FStartDate;
	end;

	TNAVReadItems = class( TCollection )
	private
		FNAVReadSettings : TNAVReadSettings;
		function GetItem( Index : integer ) : TNAVReadItem;
		procedure SetItem( Index : integer; const Value : TNAVReadItem );
	protected
	public
		constructor Create( AOwner : TNAVReadSettings );
		function Add : TNAVReadItem;
		function Insert( Index : integer ) : TNAVReadItem;
		property Items[ Index : integer ] : TNAVReadItem read GetItem write SetItem; default;
	end;

	TNAVReadSettings = class( TPersistent )
	private
		FActive : boolean;
		FInvoicePath : AnsiString;
		FXMLInvoicePath : AnsiString;
		FReadInterval : integer;
		FBackDays : integer;
		FReadMode : TTestMode;
		FLastRead : TDateTime;
		FNAVReadItems : TNAVReadItems;
	public
		constructor Create;
		destructor Destroy; override;
	published
		property Active : boolean read FActive write FActive;
		property InvoicePath : AnsiString read FInvoicePath write FInvoicePath;
		property XMLInvoicePath : AnsiString read FXMLInvoicePath write FXMLInvoicePath;
		property ReadInterval : integer read FReadInterval write FReadInterval;
		property BackDays : integer read FBackDays write FBackDays;
		property ReadMode : TTestMode read FReadMode write FReadMode;
		property LastRead : TDateTime read FLastRead write FLastRead;
		property NAVReadItems : TNAVReadItems read FNAVReadItems write FNAVReadItems;
	end;

implementation

uses System.DateUtils, System.SysUtils;

// TNAVReadItem
constructor TNAVReadItem.Create(Collection: TCollection);
begin
	inherited;
	FSor := 0;
	FAlmiraPath := '';
	FAlmiraSharePath := '';
	FStartDate := IncDay( Now(),- DayOfTheYear( Now()) + 1 );
end;

procedure TNAVReadItem.Assign( Source: TPersistent );
begin
	if ( Source is TNAVReadItem ) then begin
		FSor := TNAVReadItem( Source ).FSor;
		FAlmiraPath := TNAVReadItem( Source ).FAlmiraPath;
		FAlmiraSharePath := TNAVReadItem( Source ).FAlmiraSharePath;
		FStartDate := TNAVReadItem( Source ).FStartDate;
	end else begin
		inherited Assign( Source );
	end;
end;

// TNAVReadItems
constructor TNAVReadItems.Create(AOwner: TNAVReadSettings);
begin
	inherited Create( TNAVReadItem );
	FNAVReadSettings := AOwner;
end;

function TNAVReadItems.Add : TNAVReadItem;
begin
	Result := TNAVReadItem( inherited Add );
	Result.FSor := 0;
	Result.FAlmiraPath := '';
	Result.FAlmiraSharePath := '';
	Result.FStartDate := IncDay( Now(),- DayOfTheYear( Now()) + 1 );
end;

function TNAVReadItems.GetItem( Index: integer) : TNAVReadItem;
begin
  Result := TNAVReadItem( inherited Items[ Index ]);
end;

function TNAVReadItems.Insert(Index: integer) : TNAVReadItem;
begin
  Result := TNAVReadItem( inherited Insert( Index ));
end;

procedure TNAVReadItems.SetItem( Index : integer; const Value : TNAVReadItem);
begin
  inherited Items[ Index ] := Value;
end;

// TNAVReadSettings
constructor TNAVReadSettings.Create;
begin
	inherited;
	FActive := FALSE;
	FInvoicePath := '';
	FXMLInvoicePath := '';
	FReadInterval := 0;
	FBackDays := 0;
	FReadMode := tm_Real;
	FLastRead := IncDay( Now(),- DayOfTheYear( Now()) + 1 );
	FNAVReadItems := TNAVReadItems.Create( Self );
end;

destructor TNAVReadSettings.Destroy;
begin
  FNAVReadItems.Destroy;
  inherited;
end;

end.
