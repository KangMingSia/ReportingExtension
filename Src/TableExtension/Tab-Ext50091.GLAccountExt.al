tableextension 50091 GLAccountExt extends "G/L Account"
{
    fields
    {
        field(50091; "Cost Centre"; Text[50])
        {
            Caption = 'Cost Centre';
            DataClassification = CustomerContent;
        }
        field(50092; "Lucanet Item"; Text[50])
        {
            Caption = 'Lucanet Item';
            DataClassification = CustomerContent;
        }
        field(50093; "Lucanet Group"; Text[50])
        {
            Caption = 'Lucanet Group';
            DataClassification = CustomerContent;
        }
    }
}
