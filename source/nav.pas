unit NAV;

interface

uses IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdBaseComponent, IdComponent,
	IdTCPConnection, IdTCPClient, IdHTTP, Windows, SysUtils, StrUtils, XMLDoc, XMLIntf, Dialogs,
	Classes, XMLHandler, DCPrijndael, DCPBase64, DCPsha512, invoice, SyncSetting, System.IOUtils;
const
	acNAVSchema : array[ 0..1,0..1 ] of string = ((
		'xmlns:common','http://schemas.nav.gov.hu/NTCA/1.0/common' ),(
		'xmlns','http://schemas.nav.gov.hu/OSA/3.0/api' ));
	cNAVCommonSchema : string = 'common:';
	cNAVReceiveSchema : string = 'ns2:';
	nMAnnulment : integer = 1;
	nMInvoice : integer = 2;
	nQInvoiceChainDigest : integer = 3;
	nQInvoiceCheck : integer = 4;
	nQInvoiceData : integer = 5;
	nQInvoiceDigest : integer = 6;
	nQTransactionList : integer = 7;
	nQTransactionStatus : integer = 8;
	nQTaxpayer : integer = 9;
	nTokenExchange : integer = 10;
	BufferSize = 8192;
	aCRCTable : array [0..255] of dword = (
		$00000000, $77073096, $ee0e612c, $990951ba,
		$076dc419, $706af48f, $e963a535, $9e6495a3,
		$0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988,
		$09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91,
		$1db71064, $6ab020f2, $f3b97148, $84be41de,
		$1adad47d, $6ddde4eb, $f4d4b551, $83d385c7,
		$136c9856, $646ba8c0, $fd62f97a, $8a65c9ec,
		$14015c4f, $63066cd9, $fa0f3d63, $8d080df5,
		$3b6e20c8, $4c69105e, $d56041e4, $a2677172,
		$3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
		$35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940,
		$32d86ce3, $45df5c75, $dcd60dcf, $abd13d59,
		$26d930ac, $51de003a, $c8d75180, $bfd06116,
		$21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
		$2802b89e, $5f058808, $c60cd9b2, $b10be924,
		$2f6f7c87, $58684c11, $c1611dab, $b6662d3d,
		$76dc4190, $01db7106, $98d220bc, $efd5102a,
		$71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433,
		$7807c9a2, $0f00f934, $9609a88e, $e10e9818,
		$7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
		$6b6b51f4, $1c6c6162, $856530d8, $f262004e,
		$6c0695ed, $1b01a57b, $8208f4c1, $f50fc457,
		$65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c,
		$62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65,
		$4db26158, $3ab551ce, $a3bc0074, $d4bb30e2,
		$4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb,
		$4369e96a, $346ed9fc, $ad678846, $da60b8d0,
		$44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
		$5005713c, $270241aa, $be0b1010, $c90c2086,
		$5768b525, $206f85b3, $b966d409, $ce61e49f,
		$5edef90e, $29d9c998, $b0d09822, $c7d7a8b4,
		$59b33d17, $2eb40d81, $b7bd5c3b, $c0ba6cad,
		$edb88320, $9abfb3b6, $03b6e20c, $74b1d29a,
		$ead54739, $9dd277af, $04db2615, $73dc1683,
		$e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
		$e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1,
		$f00f9344, $8708a3d2, $1e01f268, $6906c2fe,
		$f762575d, $806567cb, $196c3671, $6e6b06e7,
		$fed41b76, $89d32be0, $10da7a5a, $67dd4acc,
		$f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
		$d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252,
		$d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
		$d80d2bda, $af0a1b4c, $36034af6, $41047a60,
		$df60efc3, $a867df55, $316e8eef, $4669be79,
		$cb61b38c, $bc66831a, $256fd2a0, $5268e236,
		$cc0c7795, $bb0b4703, $220216b9, $5505262f,
		$c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04,
		$c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d,
		$9b64c2b0, $ec63f226, $756aa39c, $026d930a,
		$9c0906a9, $eb0e363f, $72076785, $05005713,
		$95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38,
		$92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21,
		$86d3d2d4, $f1d4e242, $68ddb3f8, $1fda836e,
		$81be16cd, $f6b9265b, $6fb077e1, $18b74777,
		$88085ae6, $ff0f6a70, $66063bca, $11010b5c,
		$8f659eff, $f862ae69, $616bffd3, $166ccf45,
		$a00ae278, $d70dd2ee, $4e048354, $3903b3c2,
		$a7672661, $d06016f7, $4969474d, $3e6e77db,
		$aed16a4a, $d9d65adc, $40df0b66, $37d83bf0,
		$a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
		$bdbdf21c, $cabac28a, $53b39330, $24b4a3a6,
		$bad03605, $cdd70693, $54de5729, $23d967bf,
		$b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94,
		$b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d);
	nKeySize 							: integer = 16;
	nBlockSize							: integer = 16;


type
	TVarType = ( vt_String,vt_Logical,vt_Numeric );

PNAVFactory = ^TNAVFactory;
	TNAVFactory = record
		Letter : string[1];
		FactoryName : string[50];
		TaxNumber : string[11];
		Login : string[15];
		Password : string[20];
		SignKey : string[32];
		ChangeKey : string[16];
	end;

{	PNAVInvoice = ^TNAVInvoice;
	TNAVInvoice = record
		RecordNumber : integer;
		RequestId : string[50];
		RequestDateTime : TDateTime;
		RequestVersion : TNAVVersion;
		XMLFile : string[200];
		FinPart1 : TNAVFactory;
		InvoiceNumber : string[20];
		GrossValue : real;
		TaxValue : real;
		Currency : string[3];
		FinPart2Name : string[40];
		FinPart2TaxNumber : string[11];
		StatusDateTime : TDateTime;
		ResultText : string[5];
		OperationType : string[1];
		TestMode : TTestMode;
		InvStatusNum : string[1];
		InvStatus : string[20];
		InvStatusText : string[20];
		TransactionID : string[16];
		InsUser : string[30];
		InsDate : TDateTime;
		NAVError : string[1];
		ErrorText : string[100];
		SendDateTime : TDateTime;
		SendMail : integer;
		Compressed : boolean;
	end;}

	TSoftWareType = record
		ID : string[40];
		Name : string[40];
		Operation : string[20];
		MainVersion : string[10];
		DevName : string[40];
		DevContact : string[40];
		DevCountryCode : string[2];
		DevTaxNumber : string[15];
	end;

	TAppSettings = record
		nLogLevel : integer;
		cLogPath : string[200];
		cXMLLogPath : string[200];
		cReceivePath : string[200];
		cXMLReceivePath : string[200];
		cSendPath : string[200];
		cXMLSendPath : string[200];
		nBalloonTimeout : integer;
		NAVVersion : TNAVVersion;
		WindowPos : TPoint;
		WindowWidth : integer;
		WindowHeight : integer;
	end;

	TNAVASzSettings = record
		lActive : boolean;
		cDBFPath : string[200];
		cEInvoicePath : string[200];
		nDBFInterval : integer;
		nGridInterval : integer;
		nDeleteDay : integer;
		lDeleteProcessing : boolean;
		cUserCompany : string[40];
		cUserSites : string[50];
		cUserMachine : string[50];
		cUserName : string[20];
	end;

	TAddress = record
		cCountryCode : string[2];
		cPostalCode : string[10];
		cCity : string[40];
		cStreet : string[100];
	end;

	PEmailAddress = ^TEmailAddress;
	TEmailAddress = record
		cName : string[50];
		cAddress : string[50];
	end;

	TInvoiceHeader = record
		cInvNumber : string[20];
		cInvoiceAppearance : string[20];
		cInvoiceCategory : string[20];
		cTransactionID : string[16];
		dInsDate : TDateTime;
		cInsUser : string[15];
		cCurrency : string[3];
		nNetAmount : longint;
		nVATAmount : longint;
		cSupplierTax : string[15];
		cSupplierName : string[40];
		cSupplierAddress : TAddress;
		cCustTax : string[15];
		cCustName : string[40];
		cCustAddress : TAddress;
		cInvCurrency : string[3];
		dInvIssue : TDateTime;
		dInvDelivery : TDateTime;
		dInvPayment : TDateTime;
		nInvoiceNetAmount : real;
		nInvoiceNetAmountHUF : real;
		nInvoiceVATAmount : real;
		nInvoiceVATAmountHUF : real;
		nInvoiceGrossAmount : real;
		nInvoiceGrossAmountHUF : real;
	end;

var
	SoftwareData : TSoftWareType;
	MySettings : TFormatSettings;
	aNAVLink : array[ 0..1,1..10 ] of string[200];

function LeftPad( InValue, InLength : integer; InPadChar : char ): string;
function MakeSHA512( InText : string ) : string;
function MakeSHA3512( InText : AnsiString ) : AnsiString;
function DecryptExchangeToken( InExchangeToken, InChangeKey : string ) : string;
function StringToHex( cIn : string ) : string;
function SendXML( cFileName : string; InTestMode : TTestMode; InXMLType : integer ) : string;
function PadWithZeros( const InString : string; InSize : integer ) : string;
function CompCRC32( InText : AnsiString ) : dword;
function ParseXML( InXML : AnsiString ) : AnsiString;
function ReadNodeText( InNode : IXMLNode; InItemName : string ) : string;
function NAVStrToDate( InString : AnsiString ) : TDateTime;
function GetNAVVersion( InNAVVersion : TNAVVersion ) : AnsiString;
function SetNAVVersion( InNAVVersion : AnsiString ) : TNAVVersion;
function GetSQLDateS( InD : TDateTime; InSQLType : TSQLType ) : string;
function GetSQLDateTimeS( InD : TDateTime; InSQLType : TSQLType ) : string;
function GetSQLNumN( InN : real ) : string;
function PadR( cIn : string; nLength : integer; cFillChar : char ) : string;
function PadL( cIn : string; nLength : integer; cFillChar : char ) : string;
procedure SetMySettings;
procedure MakeQueryInvoiceXML( InInvoice : TInvoice; InvoiceDirection : TInvoiceDirection );
function MakeSafetyFileName( const cInFileName : string; cChangeChar : char ) : string;

implementation

uses Main, MailSending, mem_util, sha3_512, myhash, Math;

function GetNAVVersion( InNAVVersion : TNAVVersion ) : AnsiString;
begin
	if ( InNAVVersion = rv_10 ) then Result := '1.0';
	if ( InNAVVersion = rv_20 ) then Result := '2.0';
	if ( InNAVVersion = rv_30 ) then Result := '3.0';
end;

function SetNAVVersion( InNAVVersion : AnsiString ) : TNAVVersion;
begin
	Result := rv_30;
	if ( InNAVVersion = '1.0' ) then Result := rv_10;
	if ( InNAVVersion = '2.0' ) then Result := rv_20;
end;

{function CompareRec( InRec1, InRec2 : PNAVInvoice ) : boolean;
begin
	Result := FALSE;
	if ( InRec1.RecordNumber = InRec2.RecordNumber ) and
		( InRec1.RequestId = InRec2.RequestId ) and
		( InRec1.XMLFile = InRec2.XMLFile ) and
		( InRec1.FinPart1.FactoryName = InRec2.FinPart1.FactoryName ) and
		( InRec1.FinPart1.TaxNumber = InRec2.FinPart1.TaxNumber ) and
		( InRec1.FinPart1.Login = InRec2.FinPart1.Login ) and
		( InRec1.FinPart1.Password = InRec2.FinPart1.Password ) and
		( InRec1.FinPart1.SignKey = InRec2.FinPart1.SignKey ) and
		( InRec1.FinPart1.ChangeKey = InRec2.FinPart1.ChangeKey ) and
		( InRec1.InvoiceNumber = InRec2.InvoiceNumber ) and
		( InRec1.GrossValue = InRec2.GrossValue ) and
		( InRec1.TaxValue = InRec2.TaxValue ) and
		( InRec1.Currency = InRec2.Currency ) and
		( InRec1.FinPart2Name = InRec2.FinPart2Name ) and
		( InRec1.RequestDateTime = InRec2.RequestDateTime ) and
		( InRec1.StatusDateTime = InRec2.StatusDateTime ) and
		( InRec1.ResultText = InRec2.ResultText ) and
		( InRec1.OperationType = InRec2.OperationType ) and
		( InRec1.TestMode = InRec2.TestMode ) and
		( InRec1.InvStatusNum = InRec2.InvStatusNum ) and
		( InRec1.InvStatus = InRec2.InvStatus ) and
		( InRec1.InvStatusText = InRec2.InvStatusText ) and
		( InRec1.NAVError = InRec2.NAVError ) and
		( InRec1.ErrorText = InRec2.ErrorText ) and
		( InRec1.SendDateTime = InRec2.SendDateTime ) then begin
		Result := TRUE;
	end;
end;}

function LeftPad( InValue, InLength : integer; InPadChar : char ): string;
begin
	 Result := RightStr( StringOfChar( InPadChar, InLength ) + IntToStr( InValue ), InLength );
end;

function StringToHex( cIn : string ) : string;
var
	I										: integer;
begin
	Result := '';
	for I := 1 to Length( cIn ) do begin
		Result:= Result + IntToHex( Ord( cIn[ I ]), 2 );
	end;
end;

function PadWithZeros( const InString : string; InSize : integer ) : string;
var
	nOrigSize, I 									: integer;
begin
	Result := InString;
	nOrigSize := Length( Result );
	if (( nOrigSize mod InSize ) <> 0 ) or ( nOrigSize = 0 ) then begin
		SetLength( Result, (( nOrigSize div InSize ) + 1 ) * InSize);
	  for I := nOrigSize + 1 to Length( Result ) do
		 Result[ I ] := #0;
	end;
end;

function NAVStrToDate( InString : AnsiString ) : TDateTime;
begin
	Result := StrToDateTime( Copy( InString,1,10 ) + ' ' + Copy( InString,12,8 ), NAV.MySettings );
end;

function DecryptExchangeToken( InExchangeToken, InChangeKey : string ) : string;
var
	AES128									: TDCP_rijndael;
	cDecodedToken,cEncodedToken		: AnsiString;
	cVector,cKey							: AnsiString;
begin
	InExchangeToken := Copy( InExchangeToken,1,64 );
	cVector := '';
	cKey := PadWithZeros( AnsiString( InChangeKey ), nKeySize );
	cVector := PadWithZeros( AnsiString( cVector ), nBlockSize );
	cEncodedToken := PadWithZeros( AnsiString( InExchangeToken ), nBlockSize );
	cEncodedToken := Base64DecodeStr( AnsiString( cEncodedToken ));
	AES128 := TDCP_rijndael.Create( NIL );
	AES128.Init( cKey[1], 128, @cVector[ 1 ]);
	cDecodedToken := '';
	cDecodedToken := PadWithZeros( cDecodedToken, Length( cEncodedToken ));
	SetLength( cDecodedToken, Length( cEncodedToken ));
	AES128.DecryptECB( cEncodedToken[  1 ], cDecodedToken[  1 ]);
	AES128.DecryptECB( cEncodedToken[ 17 ], cDecodedToken[ 17 ]);
	AES128.DecryptECB( cEncodedToken[ 33 ], cDecodedToken[ 33 ]);
	if Length( cEncodedToken ) > 48 then begin
		AES128.DecryptECB( cEncodedToken[ 49 ], cDecodedToken[ 49 ]);
	end;
	AES128.Free;
	cDecodedToken := Copy( cDecodedToken, 0, 48 );
	Result := cDecodedToken;
end;

function MakeSHA3512( InText : AnsiString ) : AnsiString;
	function HexString( const cIn : array of byte ) : AnsiString;
	begin
		Result := HexStr( @cIn, SizeOf( cIn ));
	end;

var
	SHA3_512Digiest : TSHA3_512Digest;
begin
	SHA3_512FullXL( SHA3_512Digiest, PChar( InText ),Length( InText ));
	Result := HexString( SHA3_512Digiest );
end;

function MakeSHA512( InText : string ) : string;
var
	I 											: Longint;
	aDigest 									: array [0..63] of byte;
	Hash512 									: TDCP_sha512;
begin
	Hash512 := TDCP_sha512.Create( NIL );
	Hash512.Init();
	Hash512.UpdateStr( InText );
	Hash512.Final( aDigest );
	Result := '';
	for I := 0 to High( aDigest ) do begin
		Result := Result + IntToHex( aDigest[ I ], 2 );
	end;
	Hash512.Free;
end;

function SendXML( cFileName : string; InTestMode : TTestMode; InXMLType : integer ) : string;
var
	cXMLFile									: string;
	cError,cErrorFileName				: string;
	nTestMode								: integer;
	XMLStream								: TFileStream;
	XMLResult,cUnicodeStr				: AnsiString;
	XMLFile									: IXMLDocument;
begin
	if ( InTestMode = tm_Test ) then begin
		nTestMode := 1;
	end else begin
		nTestMode := 0;
	end;
	WriteLogFile( 'XML file küldésének megkezdése (' + MainForm.AppSettings.cSendPath + '\' + cFileName + ')',2 );
	cXMLFile := MainForm.AppSettings.cSendPath +  '\' + cFileName;
	if FileExists( cXMLFile ) then begin
		XMLStream := TFileStream.Create( cXMLFile, fmOpenRead or fmShareDenyWrite );
		XMLStream.Position := 0;
		try
			try
				WriteLogFile( 'XML file küldése (' + aNavLink[ nTestMode, InXMLType ] + ')',4 );
				XMLResult := '';
				XMLResult := MainForm.MainHTTP.Post( aNavLink[ nTestMode, InXMLType ], XMLStream );
				cUnicodeStr := UTF8Encode( XMLResult );
				WriteLogFile( 'Az XML file küldés befejezve (' + cXMLFile + ')', 4 );
				XMLFile := NewXMLDocument;
				XMLFile.Encoding := 'UTF8';
				XMLFile.Options := [ doNodeAutoIndent ];
				XMLFile.LoadFromXML( cUnicodeStr );
				XMLFile.XML.Text := XMLDoc.FormatXMLData( XMLFile.XML.Text );
				XMLFile.Active := TRUE;
				XMLFile.SaveToFile( MainForm.AppSettings.cReceivePath + '\' + cFileName );
				XMLFile.Active := FALSE;
				WriteLogFile( 'Az XML file küldése hibátlan (' + cXMLFile + ')', 2 );
				Result := cFileName;
			except
				on E: EIdHTTPProtocolException do begin
					cErrorFileName := 'error-' + FormatDateTime( 'mmddhhnnss', Now ) + '.xml';
					WriteLogFile( 'Hiba az XML file küldésekor (' + cXMLFile + ')', 2 );
					WriteLogFile( 'Errorcode : ' + IntToStr( E.ErrorCode ), 4 );
					WriteLogFile( 'Message : ' + E.Message, 4 );
					WriteLogFile( 'ErrorMessage : '+  E.ErrorMessage, 4 );
					cError := E.Message;
					XMLFile := NewXMLDocument;
					XMLFile.Active := TRUE;
					XMLFile.Encoding := 'utf-8';
					try
						cError := FormatXMLData( E.ErrorMessage );
						XMLFile := LoadXMLData( cError );
						XMLFile.SaveToFile( MainForm.AppSettings.cReceivePath + '\' + cErrorFileName );
					except
						on E: Exception do begin
							WriteLogFile( 'Nem XML formátumú a hiba : ' + cError, 2 );
						end;
					end;
					XMLFile.Active := FALSE;
					Result := '';
				end;
				on E: Exception do begin
					WriteLogFile( 'Hiba az XML file küldésekor (' + cXMLFile + ')', 2 );
					WriteLogFile( 'Errorcode : ' + E.Message, 4 );
					Result := '';
				end;
			end;
		finally
			XMLStream.Free;
		end;
	end else begin
		WriteLogFile( 'File nem található (' + cXMLFile + ')', 3 );
	end;
	if Result = '' then begin
		WriteLogFile( 'Hiba az XML file küldésekor (sendxlm\' + cFileName + ')', 2 );
	end;
end;

function CompCRC32( InText : AnsiString ) : dword;
var
	I,nWorkBytes						: integer;
	nOutCRC								: dword;
	CRCStream							: TStringStream;
	CRCBuffer							: array[ 1..BufferSize ] of byte;
begin
	nOutCRC := $FFFFFFFF;
	CRCStream := TStringStream.Create( InText );
	while ( CRCStream.Position <> CRCStream.Size ) do begin
		nWorkBytes := CRCStream.Read( CRCBuffer, SizeOf( CRCBuffer ));
		for I := 1 to nWorkBytes do begin
			nOutCRC := (( nOutCRC SHR 8) AND $FFFFFF) XOR aCRCTable[( nOutCRC XOR dword( CRCBuffer[ I ])) AND $FF ];
		end;
	end;
	CRCStream.Free;
	nOutCRC := ( not( nOutCRC ));
	Result := nOutCRC;
end;


function ParseXML( InXML : AnsiString ) : AnsiString;
var
	I								: integer;
	cOutXML						: AnsiString;
begin
	cOutXML := '';
	for I := 1 to Length( InXML ) do begin
		if Copy( InXML,I,2 ) = '><' then begin
			cOutXML := cOutXML + '>' + Chr( 13 ) + Chr( 10 );
		end else begin
			cOutXML := cOutXML + Copy( InXML,I,1 );
		end;
	end;
	Result := cOutXML;
end;

function ReadNodeText( InNode : IXMLNode; InItemName : string ) : string;
var
	MainNode,ChildNode				: IXMLNode;
	cItemName							: string;
begin
	cItemName := InItemName;
	MainNode := InNode;
	Result := '0';
	if ( Pos( ':', InItemName ) > 0 ) then begin
		ChildNode := MainNode.ChildNodes.FindNode( InItemName,'' );
	end else begin
		ChildNode := MainNode.ChildNodes.FindNode( InItemName,'' );
	end;
	if ChildNOde <> NIL then begin
		Result := Trim( ChildNode.Text );
	end;
end;

procedure MakeQueryInvoiceXML( InInvoice : TInvoice; InvoiceDirection : TInvoiceDirection );
var
	UTCDateTime										: TSystemTime;
	MySettings										: TFormatSettings;
	cPassHash,cKey,cXML,cXMLFile				: string;
	XMLFile											: IXMLDocument;
	MainNode,Level1Node,Level2Node			: IXMLNode;
begin
	GetLocaleFormatSettings( GetUserDefaultLCID, MySettings );
	MySettings.DateSeparator := '-';
	MySettings.TimeSeparator := ':';
	MySettings.ShortDateFormat := 'yyyy-mm-dd';
	MySettings.ShortTimeFormat := 'hh:nn:ss';
	MySettings.DecimalSeparator := '.';
	WriteLogFile( 'Számla adatok lekérdezése : ' + Trim( InInvoice.RequestId ) + ' (' + IntToStr( InInvoice.RecordNumber ) + '. rekord)',1 );
	if InInvoice.TransactionID <> '' then begin
		XMLFile := NewXMLDocument;
		XMLFile.Options := [ doNodeAutoIndent ];
		XMLFile.Active;
		GetSystemTime( UTCDateTime );
		cPassHash := MakeSHA512( InInvoice.Supplier.Password );
		cKey := InInvoice.RequestId + FormatDateTime( 'yyyymmddhhnnss', SystemTimeToDateTime( UTCDateTime )) + InInvoice.Supplier.SignKey;
//		MainNode := XMLFile.CreateNode( 'InvoiceNumber', ntComment );
//		XMLFile.ChildNodes.Add( MainNode );
//		MainNode.Text := 'Szamla szama: ' + InInvoice.InvoiceNumber;
//		MainNode := XMLFile.CreateNode( 'CustomerName', ntComment );
//		XMLFile.ChildNodes.Add( MainNode );
//		MainNode.Text := 'Ceg neve: ' + InInvoice.FinPart2Name;
		MainNode := XMLFile.AddChild( 'QueryInvoiceDataRequest' );
		XMLInsertSchemas( MainNode );
		Level1Node := MainNode.AddChild( cNAVCommonSchema + 'header' );
		Level1Node.AddChild( cNAVCommonSchema + 'requestId' ).Text := InInvoice.RequestId;
		Level1Node.AddChild( cNAVCommonSchema + 'timestamp' ).Text := FormatDateTime( 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', SystemTimeToDateTime( UTCDateTime ));
		Level1Node.AddChild( cNAVCommonSchema + 'requestVersion' ).Text := GetNAVVersion( MainForm.AppSettings.NAVVersion );
		Level1Node.AddChild( cNAVCommonSchema + 'headerVersion' ).Text := '1.0';
		Level1Node := MainNode.AddChild( cNAVCommonSchema + 'user' );
		Level1Node.AddChild( cNAVCommonSchema + 'login' ).Text := InInvoice.Supplier.Login;
		Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'passwordHash' );
		Level2Node.Text := UpperCase( cPassHash );
		Level2Node.Attributes[ 'cryptoType' ] := 'SHA-512';
		Level1Node.AddChild( cNAVCommonSchema + 'taxNumber' ).Text := Copy( String( InInvoice.Supplier.TAXPayerID ),1,8 );
		Level2Node := Level1Node.AddChild( cNAVCommonSchema + 'requestSignature' );
		Level2Node.Text := UpperCase( MakeSHA3512( cKey ));
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
		Level1Node := MainNode.AddChild( 'invoiceNumberQuery' );
		Level1Node.AddChild( 'invoiceNumber' ).Text := InInvoice.InvoiceNumber;
		if ( InvoiceDirection = id_Outbound ) then begin
			Level1Node.AddChild( 'invoiceDirection' ).Text := 'OUTBOUND';
		end else begin
			Level1Node.AddChild( 'invoiceDirection' ).Text := 'INBOUND';
		end;
		if ( InInvoice.Customer.TAXPayerID <> '' ) then begin
			Level1Node.AddChild( 'supplierTaxNumber' ).Text := Trim( InInvoice.Customer.TAXPayerID );
		end;
		cXMLFile := InInvoice.RequestId + '.xml';
		try
			try
				cXML := StringReplace( XMLFile.XML.Text, ' xmlns=""', '', [ rfReplaceAll ]);
				XMLFile := LoadXMLData( cXML );
				XMLFile.Encoding := 'utf-8';
				WriteLogFile( 'XML file elkészítése (' + cXMLFile + ')',3 );
				XMLFile.SaveToFile( MainForm.AppSettings.cSendPath + '\' + cXMLFile );
				WriteLogFile( 'XML file elkészítése megtörtént (' + MainForm.AppSettings.cSendPath + '\' + cXMLFile + ')',3 );
			finally
				XMLFile.Active := FALSE;
			end;
		except
			on E: Exception do begin
				WriteLogFile( 'Hiba az XML file elkészítésekor',3 );
				WriteLogFile( E.ClassName + ': ' + E.Message,3 );
			end;
		end;
	end;
end;

procedure SetMySettings;
begin
	GetLocaleFormatSettings( GetUserDefaultLCID, NAV.MySettings );
	NAV.MySettings.DateSeparator := '-';
	NAV.MySettings.TimeSeparator := ':';
	NAV.MySettings.ShortDateFormat := 'YYYY-MM-DD';
	NAV.MySettings.ShortTimeFormat := 'HH:NN:SS.ZZZ';
	NAV.MySettings.DecimalSeparator := '.';
end;

function GetSQLDateS( InD : TDateTime; InSQLType : TSQLType ) : string;
begin
	if ( InSQLType = sqt_Firebird ) then begin
		Result := FormatDateTime( 'yyyy mm dd', InD );
	end else begin
		Result := FormatDateTime( 'yyyy.mm.dd', InD );
	end;
end;

function GetSQLDateTimeS( InD : TDateTime; InSQLType : TSQLType ) : string;
begin
	if ( InSQLType = sqt_Firebird ) then begin
		Result := FormatDateTime( 'yyyy mm dd hh:mm:ss', InD );
	end else begin
		Result := FormatDateTime( 'yyyy.mm.dd hh:mm:ss', InD );
	end;
end;

function GetSQLNumN( InN : real ) : string;
var
	nPos						: integer;
	cOut,cSeged				: string;
begin
	cSeged := FloatToStr( RoundTo( InN,-5 ));
	nPos := Pos( ',', cSeged );
	cOut := cSeged;
	if nPos <> 0 then begin
		cOut := StuffString( cOut, nPos, 1, '.' );
	end;
	Result := cOut;
end;

function PadR( cIn : string; nLength : integer; cFillChar : char ) : string;
var
	I             : integer;
	cSeged        : string;
begin
	cIn := Trim( cIn );
	cSeged := cIn;
	for I := Length( cIn ) + 1 to nLength do begin
	  cSeged := cSeged + cFillChar;
	end;
	Result := Copy( cSeged,1,nLength );
end;

function PadL( cIn : string; nLength : integer; cFillChar : char ) : string;
var
	I             : integer;
	cSeged        : string;
begin
	cIn := Trim( cIn );
	cSeged := cIn;
	for I := Length( cIn ) + 1 to nLength do begin
	  cSeged := cFillChar + cSeged;
	end;
	Result := Copy( cSeged,1,nLength );
end;

function MakeSafetyFileName( const cInFileName : string; cChangeChar : char ) : string;
var
	aInvChars							: array of char;
	cActChar								: char;
	I										: integer;
	cOut									: string;
begin
	cOut := '';
// Lekérjük a fájlrendszer által tiltott karakterek listáját
	for I := 1 to Length( cInFileName ) do begin
		cActChar := cInFileName[ I ];
		if ( TPath.IsValidFileNameChar( cActChar )) then begin
			cOut := cOut + cActChar;
		end else begin
			cOut := cOut + cChangeChar;
		end;
	end;
// Eltávolítjuk a túl hosszú neveket, ha szükséges (bár a teljes útvonal a kritikus)
	if Length( cOut ) > 255 then begin
		cOut := Copy( cOut, 1, 255 );
  end;
  Result := cOut;
end;

end.
