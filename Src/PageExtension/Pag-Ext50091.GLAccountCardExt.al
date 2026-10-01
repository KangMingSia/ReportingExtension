pageextension 50091 GLAccountCardExt extends "G/L Account Card"
{
    layout
    {
        addlast(General)
        {
            field("LucaNet ID"; Rec."LucaNet ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the LucaNet ID for the G/L account.';
            }
        }
    }
}
