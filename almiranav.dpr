program almiranav;

uses
  FastMM4Messages in 'source\FastMM4Messages.pas',
  Dialogs,
  Vcl.Forms,
  SysUtils,
  System.UITypes,
  WinAPI.Windows,
  crypt in 'source\crypt.pas',
  delete in 'source\delete.pas' {DeleteForm},
  mailsending in 'source\mailsending.pas',
  main in 'source\main.pas' {MainForm},
  nav in 'source\nav.pas',
  navmanageinvoice in 'source\navmanageinvoice.pas',
  navqueryinvoicedata in 'source\navqueryinvoicedata.pas',
  navqueryinvoicestatus in 'source\navqueryinvoicestatus.pas',
  navquerytaxpayer in 'source\navquerytaxpayer.pas',
  navread in 'source\navread.pas' {NAVReadForm},
  navtokenexchange in 'source\navtokenexchange.pas',
  reading in 'source\reading.pas',
  settings in 'source\settings.pas' {SettingsForm},
  taxpayer in 'source\taxpayer.pas' {TaxPayerForm},
  test in 'source\test.pas' {TestForm},
  xmlhandler in 'source\xmlhandler.pas',
  btypes in 'source\sha3512\btypes.pas',
  mem_util in 'source\sha3512\mem_util.pas',
  myhash in 'source\sha3512\myhash.pas',
  sha3 in 'source\sha3512\sha3.pas',
  sha3_512 in 'source\sha3512\sha3_512.pas',
  invoice in 'source\invoice.pas',
  currencyread in 'source\currencyread.pas' {CurrencyReadForm},
  navreadsetting in 'source\navreadsetting.pas',
  syncsetting in 'source\syncsetting.pas',
  sync in 'source\sync.pas' {SyncForm},
  Kontir in 'source\Kontir.pas';

{$R *.res}

const
	MyMutexName = 'ALMIRANAV';

var
	MyMutex						: THandle;
	cPar01,cPar02				: string;

begin
	MyMutex := CreateMutex( NIL, FALSE, MyMutexName );
	if GetLastError = ERROR_ALREADY_EXISTS then begin
		cPar01 := ParamStr( 1 );
		cPar02 := ParamStr( 2 );
		if UpperCase( cPar01 ) <> '-Q' then begin
			MessageDlg( 'A program már fut, ne indítsa el kétszer !!!', mtWarning, [ mbOK ], 0 );
			Exit;
		end;
	end;
	try
		Application.Initialize;
		Application.MainFormOnTaskbar := TRUE;
		Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TNAVReadForm, NAVReadForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.CreateForm(TTaxPayerForm, TaxPayerForm);
  Application.CreateForm(TTestForm, TestForm);
  Application.CreateForm(TCurrencyReadForm, CurrencyReadForm);
  Application.CreateForm(TDeleteForm, DeleteForm);
  Application.CreateForm(TSyncForm, SyncForm);
  Application.ShowMainForm := FALSE;
		Application.Run;
	finally
		CloseHandle( MyMutex );
	end;
end.
