namespace D4P.CCMS.Auth;

using D4P.CCMS.Tenant;
using D4P.CCMS.Setup;

page 62041 "D4P Bulk Device Login"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "D4P BC Tenant";
    Caption = 'Bulk Device Login';
    SourceTableView = sorting("Customer No.", "Tenant ID");

    layout
    {
        area(Content)
        {
            usercontrol(BulkLoginControl; "D4P Bulk Login Control")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ControlReady := true;
                end;

                trigger PollToken(TenantId: Guid; DeviceCode: Text; ClientId: Guid)
                var
                    Tenant: Record "D4P BC Tenant";
                    AppReg: Record "D4P BC App Registration";
                    AuthHelper: Codeunit "D4P Device Auth Helper";
                    AccessToken: SecretText;
                    RefreshToken: SecretText;
                begin
                    Tenant.SetRange("Tenant ID", TenantId);
                    if not Tenant.FindFirst() then
                        exit;

                    // Get Client Secret if available
                    if IsNullGuid(ClientId) then
                        ClientId := Tenant."Client ID";

                    // Try to poll
                    if AuthHelper.PollForToken(TenantId, ClientId, Tenant.GetClientSecret(), DeviceCode, AccessToken, RefreshToken) then begin
                        // Success! Save tokens
                        SaveRefreshToken(TenantId, RefreshToken);

                        // Stop polling in JS
                        CurrPage.BulkLoginControl.StopPolling(TenantId);

                        // Show success (maybe update a variable on the line? we can't modify Rec here easily if iterate)
                        // But we can show a message or update a tracking table.
                        // Since this is a list page, visual feedback is tricky without refreshing.
                        Message('Login successful for tenant %1', Tenant."Tenant Name");
                    end;
                end;
            }

            repeater(Group)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Tenant ID"; Rec."Tenant ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Tenant Name"; Rec."Tenant Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(HasToken; HasStoredToken(Rec."Tenant ID"))
                {
                    ApplicationArea = All;
                    Caption = 'Has Token';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Login)
            {
                ApplicationArea = All;
                Caption = 'Login';
                Image = Log;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;

                trigger OnAction()
                var
                    AuthHelper: Codeunit "D4P Device Auth Helper";
                    DeviceCode: Text;
                    UserCode: Text;
                    VerificationUrl: Text;
                begin
                    if not ControlReady then
                        Error('Control not ready.');

                    if AuthHelper.RequestDeviceCode(Rec."Tenant ID", Rec."Client ID", Rec.GetClientSecret(), DeviceCode, UserCode, VerificationUrl) then begin
                        CurrPage.BulkLoginControl.StartLoginProcess(Rec."Tenant ID", Rec."Client ID", UserCode, VerificationUrl, DeviceCode);
                    end else begin
                        Error('Failed to request device code for tenant %1', Rec."Tenant Name");
                    end;
                end;
            }

            action(ClearToken)
            {
                ApplicationArea = All;
                Caption = 'Clear Token';
                Image = Delete;

                trigger OnAction()
                begin
                     if IsolatedStorage.Contains(GetTokenKey(Rec."Tenant ID"), DataScope::User) then
                        IsolatedStorage.Delete(GetTokenKey(Rec."Tenant ID"), DataScope::User);
                     CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ControlReady: Boolean;

    local procedure GetTokenKey(TenantId: Guid): Text
    begin
        exit('DeviceRefresh_' + Format(TenantId));
    end;

    local procedure SaveRefreshToken(TenantId: Guid; RefreshToken: SecretText)
    begin
        if not RefreshToken.IsEmpty() then
            IsolatedStorage.Set(GetTokenKey(TenantId), RefreshToken, DataScope::User);
    end;

    local procedure HasStoredToken(TenantId: Guid): Boolean
    begin
        exit(IsolatedStorage.Contains(GetTokenKey(TenantId), DataScope::User));
    end;
}
