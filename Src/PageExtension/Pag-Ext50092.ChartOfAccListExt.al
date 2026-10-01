pageextension 50092 ChartOfAccListExt extends "Chart of Accounts"
{
    layout
    {
        addlast(Control1)
        {
            field("LucaNet ID"; Rec."LucaNet ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the LucaNet ID for the G/L account.';
                editable = false;
            }
        }
    }
}
