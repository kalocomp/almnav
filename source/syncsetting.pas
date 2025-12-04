unit syncsetting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Dialogs;

type
	TSessionType = ( st_UploadLinzer, st_DownloadLinzer );
	TSQLType = ( sqt_MySQL, sqt_Firebird );

	TSyncSettings = class;

	TSyncItem = class( TCollectionItem )
	private
		FName : string;
		FSessionType : TSessionType;
		FSQLType : TSQLType;
		FSQLServer : string;
		FSQLPort : string;
		FSQLUser : string;
		FSQLFileName : string;
		FSQLPassword : string;
		FLocalYearDatabase : string;
		FLocalYearShareDatabase : string;
		FLocalShareDatabase : string;
		FActYear : integer;
		FActive : boolean;
	public
		constructor Create( Collection: TCollection ); override;
		procedure Assign(Source: TPersistent); override;
	published
		property Name : string read FName write FName;
		property SessionType : TSessionType read FSessionType write FSessionType;
		property SQLType : TSQLType read FSQLType write FSQLType;
		property SQLServer : string read FSQLServer write FSQLServer;
		property SQLPort : string read FSQLPort write FSQLPort;
		property SQLUser : string read FSQLUser write FSQLUser;
		property SQLFileName : string read FSQLFileName write FSQLFileName;
		property SQLPassword : string read FSQLPassword write FSQLPassword;
		property LocalYearDatabase : string read FLocalYearDatabase write FLocalYearDatabase;
		property LocalYearShareDatabase : string read FLocalYearShareDatabase write FLocalYearShareDatabase;
		property LocalShareDatabase : string read FLocalShareDatabase write FLocalShareDatabase;
		property ActYear : integer read FActYear write FActYear;
		property Active : boolean read FActive write FActive;
	end;

	TSyncItems = class( TCollection )
	private
		FSyncSettings : TSyncSettings;
		function GetItem( Index : integer ) : TSyncItem;
		procedure SetItem( Index : integer; const Value : TSyncItem );
	protected
	public
		constructor Create( AOwner : TSyncSettings );
		function Add : TSyncItem;
		function Insert( Index : integer ) : TSyncItem;
		property Items[ Index : integer ] : TSyncItem read GetItem write SetItem; default;
	end;

	TSyncSettings = class( TPersistent )
	private
		FActive : boolean;
		FReadInterval : integer;
		FLastRead : TDateTime;
		FSyncItems : TSyncItems;
	public
		constructor Create;
		destructor Destroy; override;
	published
		property Active : boolean read FActive write FActive;
		property ReadInterval : integer read FReadInterval write FReadInterval;
		property LastRead : TDateTime read FLastRead write FLastRead;
		property SyncItems : TSyncItems read FSyncItems write FSyncItems;
	end;

implementation

uses System.DateUtils;

// TSyncItem
constructor TSyncItem.Create(Collection: TCollection);
begin
	inherited;
	FName := '';
	FSQLServer := '';
	FSQLType := sqt_Firebird;
	FSQLPort := '';
	FSQLUser := '';
	FSQLFileName := '';
	FSQLPassword := '';
	FLocalYearDatabase := '';
	FLocalYearShareDatabase := '';
	FLocalShareDatabase := '';
	FActYear := 0;
	FActive := FALSE;
end;

procedure TSyncItem.Assign( Source: TPersistent );
begin
	if ( Source is TSyncItem ) then begin
		FName := TSyncItem( Source ).FName;
		FSQLType := TSyncItem( Source ).SQLType;
		FSQLServer := TSyncItem( Source ).FSQLServer;
		FSQLPort := TSyncItem( Source ).FSQLPort;
		FSQLUser := TSyncItem( Source ).FSQLUser;
		FSQLFileName := TSyncItem( Source ).FSQLFileNAme;
		FSQLPassword := TSyncItem( Source ).FSQLPassword;
		FLocalYearDatabase := TSyncItem( Source ).FLocalYearDatabase;
		FLocalYearShareDatabase := TSyncItem( Source ).FLocalYearShareDatabase;
		FLocalShareDatabase := TSyncItem( Source ).FLocalShareDatabase;
		FActYear := TSyncItem( Source ).FActYear;
		FActive := TSyncItem( Source ).FActive;
	end else begin
		inherited Assign( Source );
	end;
end;

// TNAVReadItems
constructor TSyncItems.Create(AOwner: TSyncSettings);
begin
	inherited Create( TSyncItem );
	FSyncSettings := AOwner;
end;

function TSyncItems.Add : TSyncItem;
begin
	Result := TSyncItem( inherited Add );
	Result.FName := '';
	Result.FSQLType := sqt_Firebird;
	Result.FSQLServer := '';
	Result.FSQLPort := '';
	Result.FSQLUser := '';
	Result.FSQLFileName := '';
	Result.FSQLPassword := '';
	Result.FLocalYearDatabase := '';
	Result.FLocalYearShareDatabase := '';
	Result.FLocalShareDatabase := '';
	Result.FActYear := 0;
	Result.FActive := FALSE;
end;

function TSyncItems.GetItem( Index: integer) : TSyncItem;
begin
  Result := TSyncItem( inherited Items[ Index ]);
end;

function TSyncItems.Insert(Index: integer) : TSyncItem;
begin
  Result := TSyncItem( inherited Insert( Index ));
end;

procedure TSyncItems.SetItem( Index : integer; const Value : TSyncItem);
begin
  inherited Items[ Index ] := Value;
end;

// TSyncSettings
constructor TSyncSettings.Create;
begin
	inherited;
	FActive := FALSE;
	FReadInterval := 0;
	FLastRead := IncDay( Now(),- DayOfTheYear( Now()) + 1 );
	FSyncItems := TSyncItems.Create( Self );
end;

destructor TSyncSettings.Destroy;
begin
  FSyncItems.Destroy;
  inherited;
end;

end.
