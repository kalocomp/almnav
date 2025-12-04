unit NAVQueryInvoiceData;

interface

uses NAV, Windows, System.StrUtils, SysUtils, XMLDoc, XMLIntf, XMLHandler, NAVTokenExchange, Main, DCPBase64,
	Vcl.Dialogs, Winapi.Messages, Vcl.ExtCtrls, frxClass, frxDBSet, frxExportPDF, invoice;

procedure GetInvoiceData( InInvoice : TInvoice );

implementation

uses DateUtils, MailSending, reading, System.UITypes;

procedure GetInvoiceData( InInvoice : TInvoice );
var
	XMLFile												: IXMLDocument;
	MainNode,Level1Node,Level2Node,Level3Node	: IXMLNode;
	Level4Node											: IXMLNode;
	nLines,I												: integer;
	ReportField											: TfrxComponent;
	cInvoiceData,cInvoice,cPDFName,cSeged		: string;
	cMoneyPicture,cXMLFile							: string;
begin
	SetMySettings;
	MakeQueryInvoiceXML( InInvoice, id_Outbound );
	WriteLogFile( 'XML file küldése indul (' + InInvoice.RequestID + '.xml)',3 );
	cXMLFile := InInvoice.RequestId + '.xml';
	cXMLFile := SendXML( cXMLFile, InInvoice.TestMode, nQInvoiceData );
	if cXMLFile <> '' then begin
		WriteLogFile( 'A számla adatai lekérdezve.',1 );
		XMLFile := LoadXMLDocument( MainForm.AppSettings.cReceivePath + '\' + cXMLFile );
		MainNode := XMLFile.ChildNodes.FindNode( 'QueryInvoiceDataResponse','' );
		if ( MainNode <> NIL ) then begin
			Level1Node := MainNode.ChildNodes.FindNode( 'header','' );
			if InInvoice.RequestId = ReadNodeText( Level1Node,'requestId' ) then begin
				Level1Node := MainNode.ChildNodes.FindNode( 'result','' );
				if ReadNodeText( Level1Node, 'funcCode' ) = 'OK' then begin
					Level1Node := MainNode.ChildNodes.FindNode( 'invoiceDataResult','' );
					if Level1Node <> NIL then begin
						cInvoiceData := ReadNodeText( Level1Node, 'invoiceData' );
						InInvoice.Compressed := ( ReadNodeText( Level1Node, 'compressedContentIndicator' ) = 'true' );
						Level2Node := Level1Node.ChildNodes.FindNode( 'auditData','' );
						if Level2Node <> NIL then begin
							cSeged := ReadNodeText( Level2Node, 'insdate' );
							InInvoice.NAVDate := StrToDateTime( Copy( cSeged,1,10 ) + ' ' + Copy( cSeged,12,8 ), NAV.MySettings );
							InInvoice.Supplier.Login := ReadNodeText( Level2Node, 'insCusUser' );
							cSeged := ReadNodeText( Level2Node, 'transactionId' );
							if ( InInvoice.TransactionID = cSeged ) then begin
								InInvoice.TransactionID := cSeged;
								InInvoice.SetNAVStatus;
								MainForm.GetInvoiceStatus( InInvoice );
							end;
						end;
					end else begin
						WriteLogFile( 'Nincs adat a megadott számláról. (' + InInvoice.InvoiceNumber + ')',1 );
					end;
				end else begin
					WriteLogFile( 'Hiba a számla adatainak lekérdezésekor!!!',1 );
					WriteLogFile( 'A lekérdezés eredménye nem OK (' + Level1Node.Text + ')',3 );
				end;
			end else begin
				WriteLogFile( 'Hiba a számla adatainak lekérdezésekor!!!',1 );
				WriteLogFile( 'A válasz XML-ben nem egyező REQUESTID (' + cXMLFile + ')',3 );
			end;
		end else begin
			WriteLogFile( 'Hiba a számla állapotának lekérdezésekor', 1 );
			SendErrorMail( InInvoice, '' );
		end;
	end else begin
		WriteLogFile( 'Hiba a számla állapotának lekérdezésekor', 1 );
		SendErrorMail( InInvoice, '' );
	end;

	if cInvoiceData = '' then begin
		MainForm.MyShowBalloonHint( 'Hiba !!!', 'Hiba történt a számla adatainak lekérdezéskor...', bfError );
	end else begin
		MainForm.MyShowBalloonHint( 'Figyelem!!!', 'A számla adatai lekérdezve...', bfInfo );
		InInvoice := DecodeInvoiceData( FALSE, cInvoiceData, InInvoice.RequestId + '.xml', InInvoice );

		if ( InInvoice.Currency = 'HUF' ) then begin
			cMoneyPicture := '### ### ##0 HUF';
		end else begin
			cMoneyPicture := '# ### ##0.00 ' + InInvoice.Currency;
		end;
		cPDFName := MainForm.cAppPath + '\pdf\' + InInvoice.TransactionID + '.pdf';
		if FileExists( cPDFName ) then begin
			if ( not DeleteFile( cPDFName )) then begin
				MessageDlg( 'A korábbi lista állomány nem törölhetõ !!!', mtWarning, [ mbOK ], 0 );
			end;
		end;
		if FileExists( cPDFName ) then begin
			MessageDlg( 'A lista nem hozható létre !!!', mtWarning, [ mbOK ], 0 );
			Exit;
		end;
		if ( not MainForm.InvoiceReport.LoadFromFile( MainForm.cAppPath + '\invoice.fr3' )) then begin
			MessageDlg( 'Nem sikerült a lista betöltése ! (' + MainForm.cAppPath + '\invoice.fr3)',mtError,[ mbOK ], 0 );
			Exit;
		end;
		MainForm.PDFInvoice.ShowDialog := FALSE;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'UnitPriceMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 ' + InInvoice.Currency;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'NetAmountMemo' ))).DisplayFormat.FormatStr := cMoneyPicture;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'NetAmountHUFMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 HUF';
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'VATAmountMemo' ))).DisplayFormat.FormatStr := cMoneyPicture;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'VATAmountHUFMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 HUF';
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'GrossAmountMemo' ))).DisplayFormat.FormatStr := cMoneyPicture;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'GrossAmountHUFMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 HUF';
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SupplierNameMemo' ))).Text := InInvoice.Supplier.Name;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SupplierTaxMemo' ))).Text := InInvoice.Supplier.FullTAXID;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SupplierCountryMemo' ))).Text := InInvoice.Supplier.CountryCode;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SupplierPostalCodeMemo' ))).Text := InInvoice.Supplier.PostalCode;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SupplierCityMemo' ))).Text := InInvoice.Supplier.City;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SupplierAddressMemo' ))).Text := InInvoice.Supplier.Address;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CustomerNameMemo' ))).Text := InInvoice.Customer.Name;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CustomerTaxMemo' ))).Text := InInvoice.Customer.FullTAXID;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CustomerCountryMemo' ))).Text := InInvoice.Customer.CountryCode;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CustomerPostalCodeMemo' ))).Text := InInvoice.Customer.PostalCode;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CustomerCityMemo' ))).Text := InInvoice.Customer.City;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CustomerAddressMemo' ))).Text := InInvoice.Customer.Address;

		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'LoginMemo' ))).Text := InInvoice.Supplier.Login;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InsDateMemo' ))).Text := FormatDateTime( 'yyyy.mm.dd hh:MM:ss', InInvoice.NAVDate );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvoiceApperanceMemo' ))).Text := InInvoice.Apperance;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'TransactionIDMemo' ))).Text := InInvoice.TransactionID;

		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'PrevInvoiceMemo' ))).Text := InInvoice.OriginalInvoice;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'CurrencyMemo' ))).Text := InInvoice.Currency;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'ExchangeRateMemo' ))).Text := FormatFloat( '0.0000 HUF/' + InInvoice.Currency, InInvoice.ExchangeRate );
		if ( InInvoice.PaymentMethod = 1 ) then begin
			TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'PaymentMethodMemo' ))).Text := 'KÉSZPÉNZ';
		end;
		if ( InInvoice.PaymentMethod = 2 ) then begin
			TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'PaymentMethodMemo' ))).Text := 'ÁTUTALÁS';
		end;
		if ( InInvoice.PaymentMethod = 3 ) then begin
			TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'PaymentMethodMemo' ))).Text := 'EGYÉB';
		end;

		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvoiceNumberMemo' ))).Text := InInvoice.InvoiceNumber;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvoiceDeliveryDateMemo' ))).Text := FormatDateTime( 'yyyy.mm.dd', InInvoice.DeliveryDate );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvoiceIssueDateMemo' ))).Text := FormatDateTime( 'yyyy.mm.dd', InInvoice.IssueDate );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'PaymentDateMemo' ))).Text := FormatDateTime( 'yyyy.mm.dd', InInvoice.PaymentDate );

		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvNetAmountMemo' ))).Text := FormatFloat( cMoneyPicture, InInvoice.NetAmount );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvNetAmountHUFMemo' ))).Text := FormatFloat( '### ### ##0.00 HUF', InInvoice.NetAmountHUF );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvVATAmountMemo' ))).Text := FormatFloat( cMoneyPicture, InInvoice.VatAmount );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvVATAmountHUFMemo' ))).Text := FormatFloat( '### ### ##0.00 HUF', InInvoice.VatAmountHUF );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvGrossAmountMemo' ))).Text := FormatFloat( cMoneyPicture, InInvoice.GrossAmount );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'InvGrossAmountHUFMemo' ))).Text := FormatFloat( '### ### ##0.00 HUF', InInvoice.GrossAmountHUF );

		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SumVATNETMemo' ))).DisplayFormat.FormatStr := cMoneyPicture;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SumVATNETHUFMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 HUF';
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SumVATVATMemo' ))).DisplayFormat.FormatStr := cMoneyPicture;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SumVATVATHUFMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 HUF';
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SumVATGrossMemo' ))).DisplayFormat.FormatStr := cMoneyPicture;
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'SumVATGrossHUFMemo' ))).DisplayFormat.FormatStr := '### ### ##0.00 HUF';

		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'MSumVATNETMemo' ))).Text := FormatFloat( cMoneyPicture, InInvoice.NetAmount );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'MSumVATNETHUFMemo' ))).Text := FormatFloat( '### ### ##0.00 HUF', InInvoice.NetAmountHUF );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'MSumVATVATMemo' ))).Text := FormatFloat( cMoneyPicture, InInvoice.VatAmount );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'MSumVATVATHUFMemo' ))).Text := FormatFloat( '### ### ##0.00 HUF', InInvoice.VatAmountHUF );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'MSumVATGrossMemo' ))).Text := FormatFloat( cMoneyPicture, InInvoice.GrossAmount );
		TfrxMemoView( TfrxMasterData( MainForm.InvoiceReport.FindObject( 'MSumVATGrossHUFMemo' ))).Text := FormatFloat( '### ### ##0.00 HUF', InInvoice.GrossAmountHUF );

		MainForm.InvLineTable.Active := TRUE;
		MainForm.InvLineTable.EmptyDataSet;
		MainForm.InvVATTable.Active := TRUE;
		MainForm.InvVATTable.EmptyDataSet;
		for I := 0 to InInvoice.InvoiceLines.Count - 1 do begin
			MainForm.InvLineTable.Append;
			MainForm.InvLineTable.FieldByName( 'LINENUMBER' ).AsInteger := InInvoice.InvoiceLines.Items[ I ].Sor;
			MainForm.InvLineTable.FieldByName( 'PRODUCTCODECATEGORY' ).AsString := 'VTSZ';
			MainForm.InvLineTable.FieldByName( 'PRODUCTCODEVALUE' ).AsString := InInvoice.InvoiceLines.Items[ I ].ProductCode;
			MainForm.InvLineTable.FieldByName( 'PRODUCTNAME' ).AsString := InInvoice.InvoiceLines.Items[ I ].ProductName;
			MainForm.InvLineTable.FieldByName( 'UNIT' ).AsString := InInvoice.InvoiceLines.Items[ I ].ProductUnit;
			MainForm.InvLineTable.FieldByName( 'QUANTITY' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].Quantity;
			MainForm.InvLineTable.FieldByName( 'UNITPRICE' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].UnitPrice;
			MainForm.InvLineTable.FieldByName( 'NETAMOUNT' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].NetAmount;
			MainForm.InvLineTable.FieldByName( 'NETAMOUNTHUF' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].NetAmountHUF;
			MainForm.InvLineTable.FieldByName( 'VATPERCENT' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].VatPercent;
			MainForm.InvLineTable.FieldByName( 'VATAMOUNT' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].VatAmount;
			MainForm.InvLineTable.FieldByName( 'VATAMOUNTHUF' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].VatAmountHUF;
			MainForm.InvLineTable.FieldByName( 'GROSSAMOUNT' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].GrossAmount;
			MainForm.InvLineTable.FieldByName( 'GROSSAMOUNTHUF' ).AsFloat := InInvoice.InvoiceLines.Items[ I ].GrossAmountHUF;
		end;
		MainForm.PDFInvoice.DefaultPath := MainForm.cAppPath + '\pdf\';
		MainForm.PDFInvoice.FileName := cPDFName;
		try
			MainForm.InvoiceReport.PrepareReport( TRUE );
			MainForm.InvoiceReport.Export( MainForm.PDFInvoice );
		except
			on E:Exception do begin
			end;
		end;
		MainForm.InvLineTable.Active := FALSE;
//		InInvoice.Destroy;
	end;
end;

end.
