pageextension 50191 GLAccountCardExt extends "G/L Account Card"
{
    layout
    {
        addlast(General)
        {
            field("Cost Centre"; Rec."Cost Centre")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Cost Centre field.', Comment = '%';
            }
            field("Lucanet Item"; Rec."Lucanet Item")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Lucanet Item field.', Comment = '%';
            }
            field("Lucanet Group"; Rec."Lucanet Group")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Lucanet Group field.', Comment = '%';
            }
        }
    }
}
