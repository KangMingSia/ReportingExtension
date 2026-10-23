page 50089 "QR Scan Input Dialog"
{
    PageType = StandardDialog;
    Caption = 'Scan QR Code to Create Purchase Order';
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(ScanGroup)
            {
                ShowCaption = false;

                field(ScannedTextData; ScannedText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    MultiLine = true;
                    ToolTip = 'Scan the QR code to create a purchase order.';

                    trigger OnValidate()
                    begin
                        if ScannedText <> '' then begin
                            CreatePOFromJson(ScannedText);
                            CurrPage.Close();
                        end;
                    end;
                }
            }
        }
    }

    var
        ScannedText: Text;

    local procedure CreatePOFromJson(JsonString: Text)
    var
        JObject: JsonObject;
        JToken: JsonToken;
        LinesToken: JsonToken;
        LineToken: JsonToken;
        JLines: JsonArray;
        LineObject: JsonObject;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NextLineNo: Integer;
        VendorNo: Code[20];
        VendorOrderNo: Code[35];
        YourReference: Text[35];
        ParsedDate: Date;
    begin
        // Parse JSON
        if not JObject.ReadFrom(JsonString) then
            Error('The scanned text is not valid JSON.');

        // Read header values
        if JObject.Get('vendor_no', JToken) then
            VendorNo := UpperCase(CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorNo)));
        if JObject.Get('vendor_order_no', JToken) then
            VendorOrderNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorOrderNo));
        if JObject.Get('your_reference', JToken) then
            YourReference := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(YourReference));

        // Duplicate Check - Vendor Order No.
        if VendorNo <> '' then begin
            if VendorOrderNo <> '' then begin
                PurchHeader.Reset();
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
                PurchHeader.SetRange("Vendor Order No.", VendorOrderNo);
                if PurchHeader.FindFirst() then
                    Error(
                        'Purchase Order %1 already exists for Vendor %2 with Vendor Order No. %3.',
                        PurchHeader."No.",
                        VendorNo,
                        VendorOrderNo);
            end;

            // Duplicate Check - Your Reference
            if YourReference <> '' then begin
                PurchHeader.Reset();
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
                PurchHeader.SetRange("Your Reference", YourReference);
                if PurchHeader.FindFirst() then
                    Error(
                        'Purchase Order %1 already exists for Vendor %2 with Your Reference %3.',
                        PurchHeader."No.",
                        VendorNo,
                        YourReference);
            end;
        end;

        // Create Purchase Header
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader.Insert(true);
        if VendorNo <> '' then
            PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        if VendorOrderNo <> '' then
            PurchHeader.Validate("Vendor Order No.", VendorOrderNo);
        if YourReference <> '' then
            PurchHeader.Validate("Your Reference", YourReference);
        if JObject.Get('currency_code', JToken) then
            if JToken.AsValue().AsText() <> '' then
                PurchHeader.Validate("Currency Code", UpperCase(JToken.AsValue().AsText()));
        if JObject.Get('location_code', JToken) then
            if JToken.AsValue().AsText() <> '' then
                PurchHeader.Validate("Location Code", UpperCase(JToken.AsValue().AsText()));
        if JObject.Get('expected_receipt_date', JToken) then begin
            if ParseJsonDate(JToken.AsValue().AsText(), ParsedDate) then
                PurchHeader.Validate("Expected Receipt Date", ParsedDate);
        end;

        PurchHeader.Modify(true);

        // Create Purchase Lines
        if JObject.Get('lines', LinesToken) then begin
            if LinesToken.IsArray() then begin
                JLines := LinesToken.AsArray();
                NextLineNo := 10000;
                foreach LineToken in JLines do begin
                    LineObject := LineToken.AsObject();

                    PurchLine.Init();
                    PurchLine."Document Type" := PurchHeader."Document Type";
                    PurchLine."Document No." := PurchHeader."No.";
                    PurchLine."Line No." := NextLineNo;
                    PurchLine.Insert(true);

                    PurchLine.Validate(Type, PurchLine.Type::Item);
                    if LineObject.Get('item_no', JToken) then
                        PurchLine.Validate("No.", UpperCase(JToken.AsValue().AsText()));
                    if LineObject.Get('location_code', JToken) then
                        if JToken.AsValue().AsText() <> '' then
                            PurchLine.Validate("Location Code", UpperCase(JToken.AsValue().AsText()));
                    if LineObject.Get('quantity', JToken) then
                        PurchLine.Validate(Quantity, JToken.AsValue().AsDecimal());
                    if LineObject.Get('unit_of_measure_code', JToken) then
                        if JToken.AsValue().AsText() <> '' then
                            PurchLine.Validate("Unit of Measure Code", UpperCase(JToken.AsValue().AsText()));
                    if LineObject.Get('direct_unit_cost', JToken) then
                        PurchLine.Validate("Direct Unit Cost", JToken.AsValue().AsDecimal());
                    if LineObject.Get('expected_receipt_date', JToken) then begin
                        if ParseJsonDate(JToken.AsValue().AsText(), ParsedDate) then
                            PurchLine.Validate("Expected Receipt Date", ParsedDate);
                    end;

                    PurchLine.Modify(true);

                    NextLineNo += 10000;
                end;
            end;
        end;

        Message(
            'Purchase Order %1 has been created successfully.',
            PurchHeader."No.");
    end;

    local procedure ParseJsonDate(DateString: Text; var TargetDate: Date): Boolean
    var
        YearVal: Integer;
        MonthVal: Integer;
        DayVal: Integer;
    begin
        Clear(TargetDate);
        if DateString = '' then
            exit(false);
        if StrLen(DateString) >= 10 then begin
            if Evaluate(YearVal, CopyStr(DateString, 1, 4)) and
               Evaluate(MonthVal, CopyStr(DateString, 6, 2)) and
               Evaluate(DayVal, CopyStr(DateString, 9, 2))
            then begin
                TargetDate := DMY2Date(DayVal, MonthVal, YearVal);
                exit(true);
            end;
        end;

        exit(Evaluate(TargetDate, DateString));
    end;
}