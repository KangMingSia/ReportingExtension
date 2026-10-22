pageextension 50193 "Purchase Order List Ext" extends "Purchase Order List"
{
    actions
    {
        addfirst(processing)
        {
            action(ScanQRPO)
            {
                ApplicationArea = All;
                Caption = 'Scan QR to Create PO';
                Image = BarCode;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Scan or paste a QR code containing PO JSON data to create a new Draft PO.';

                trigger OnAction()
                var
                    InS: InStream;
                    FileName: Text;
                    QRText: Text;
                begin
                    if UploadIntoStream('Scan or Select QR Code JSON Data', '', 'JSON files (*.json)|*.json|All files (*.*)|*.*', FileName, InS) then begin
                        InS.ReadText(QRText);
                        if QRText <> '' then
                            CreatePOFromJson(QRText);
                    end;
                end;
            }
        }
    }

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
    begin
        // 1. Parse JSON content
        if not JObject.ReadFrom(JsonString) then
            Error('The scanned text is not valid JSON.');

        // Validate payload type
        // if JObject.Get('payload_type', JToken) then
        //     if JToken.AsValue().AsText() <> 'AN_BC_PO_DRAFT_V1' then
        //         Error('Invalid payload type.');

        // 2. Extract key fields for duplicate validation
        if JObject.Get('vendor_no', JToken) then
            VendorNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorNo));
        if JObject.Get('vendor_order_no', JToken) then
            VendorOrderNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(VendorOrderNo));
        if JObject.Get('your_reference', JToken) then
            YourReference := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(YourReference));

        // 3. DUPLICATE CHECK
        if VendorNo <> '' then begin
            // Check 3A: Vendor No. + Vendor Order No.
            if VendorOrderNo <> '' then begin
                PurchHeader.Reset();
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
                PurchHeader.SetRange("Vendor Order No.", VendorOrderNo);
                if PurchHeader.FindFirst() then begin
                    if Confirm('A Purchase Order (%1) already exists for Vendor %2 with Order No. "%3".\\Do you want to open it?', true, PurchHeader."No.", VendorNo, VendorOrderNo) then
                        Page.Run(Page::"Purchase Order", PurchHeader);
                    exit;
                end;
            end;

            // Check 3B: Vendor No. + Your Reference
            if YourReference <> '' then begin
                PurchHeader.Reset();
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
                PurchHeader.SetRange("Your Reference", YourReference);
                if PurchHeader.FindFirst() then begin
                    if Confirm('A Purchase Order (%1) already exists for Vendor %2 with Your Reference "%3".\\Do you want to open it?', true, PurchHeader."No.", VendorNo, YourReference) then
                        Page.Run(Page::"Purchase Order", PurchHeader);
                    exit;
                end;
            end;
        end;

        // 4. Create Header (Only runs if no duplicate was found)
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader.Insert(true); // Triggers No. Series

        if VendorNo <> '' then
            PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        if VendorOrderNo <> '' then
            PurchHeader.Validate("Vendor Order No.", VendorOrderNo);
        if YourReference <> '' then
            PurchHeader.Validate("Your Reference", YourReference);
        if JObject.Get('currency_code', JToken) then
            PurchHeader.Validate("Currency Code", JToken.AsValue().AsText());
        if JObject.Get('location_code', JToken) then
            PurchHeader.Validate("Location Code", JToken.AsValue().AsText());

        PurchHeader.Modify(true);

        // 5. Loop through Purchase Lines
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
                        PurchLine.Validate("No.", JToken.AsValue().AsText());
                    if LineObject.Get('location_code', JToken) then
                        PurchLine.Validate("Location Code", JToken.AsValue().AsText());
                    if LineObject.Get('quantity', JToken) then
                        PurchLine.Validate(Quantity, JToken.AsValue().AsDecimal());
                    if LineObject.Get('unit_of_measure_code', JToken) then
                        PurchLine.Validate("Unit of Measure Code", JToken.AsValue().AsText());
                    if LineObject.Get('direct_unit_cost', JToken) then
                        PurchLine.Validate("Direct Unit Cost", JToken.AsValue().AsDecimal());

                    PurchLine.Modify(true);
                    NextLineNo += 10000;
                end;
            end;
        end;

        Message('Purchase Order %1 created successfully.', PurchHeader."No.");
        Page.Run(Page::"Purchase Order", PurchHeader);
    end;
}