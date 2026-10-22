page 50089 "QR Scan Input Dialog"
{
    PageType = StandardDialog;
    Caption = 'Scan QR Code';
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(ScanGroup)
            {
                Caption = 'Scan barcode into field below';
                field(ScannedTextData; ScannedText)
                {
                    ApplicationArea = All;
                    Caption = 'QR Code Input';
                    MultiLine = true;
                    ToolTip = 'Scan the QR code directly into this field.';

                    trigger OnValidate()
                    begin
                        // Allows immediate completion when scanner submits an Enter keystroke
                    end;
                }
            }
        }
    }

    var
        ScannedText: Text;

    procedure GetScannedText(): Text
    begin
        exit(ScannedText);
    end;
}
