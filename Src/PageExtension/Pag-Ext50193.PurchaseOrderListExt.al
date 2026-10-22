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
                ToolTip = 'Scan a QR code containing PO JSON data to auto-create a Draft PO.';

                trigger OnAction()
                var
                    ScanPage: Page "QR Scan Input Dialog";
                begin
                    // Opens input window where focus is set to the scanning field.
                    // No OK/Cancel buttons are shown.
                    ScanPage.RunModal();
                end;
            }
        }
    }
}