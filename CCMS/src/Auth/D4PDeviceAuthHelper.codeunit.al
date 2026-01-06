namespace D4P.CCMS.Auth;

using D4P.CCMS.Auth;
using D4P.CCMS.Setup;
using System.Security.Authentication;

codeunit 62040 "D4P Device Auth Helper"
{
    var
        DeviceCodeUrlLbl: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/devicecode', Locked = true;
        TokenUrlLbl: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        ScopeLbl: Label 'https://api.businesscentral.dynamics.com/.default offline_access', Locked = true;

    procedure RequestDeviceCode(TenantId: Guid; ClientId: Guid; ClientSecret: SecretText; var DeviceCode: Text; var UserCode: Text; var VerificationUrl: Text; var IntervalSeconds: Integer; var ExpiresInSeconds: Integer): Boolean
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseText: Text;
        Url: Text;
        JsonObj: JsonObject;
        Token: JsonToken;
        TenantIdText: Text;
    begin
        TenantIdText := Format(TenantId);
        TenantIdText := DelChr(TenantIdText, '=', '{}');
        Url := StrSubstNo(DeviceCodeUrlLbl, TenantIdText);

        Content.WriteFrom(StrSubstNo('client_id=%1&scope=%2', Format(ClientId), ScopeLbl));
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        if not HttpClient.Post(Url, Content, HttpResponse) then
            exit(false);

        if not HttpResponse.IsSuccessStatusCode() then
            exit(false);

        HttpResponse.Content().ReadAs(ResponseText);
        if not JsonObj.ReadFrom(ResponseText) then
            exit(false);

        if JsonObj.Get('device_code', Token) then
            DeviceCode := Token.AsValue().AsText();
        if JsonObj.Get('user_code', Token) then
            UserCode := Token.AsValue().AsText();
        if JsonObj.Get('verification_uri', Token) then
            VerificationUrl := Token.AsValue().AsText();
        if JsonObj.Get('interval', Token) then
            IntervalSeconds := Token.AsValue().AsInteger()
        else
            IntervalSeconds := 5; // Default to 5 seconds if not specified
        if JsonObj.Get('expires_in', Token) then
            ExpiresInSeconds := Token.AsValue().AsInteger()
        else
            ExpiresInSeconds := 900; // Default to 15 minutes if not specified

        exit(true);
    end;

    procedure PollForToken(TenantId: Guid; ClientId: Guid; ClientSecret: SecretText; DeviceCode: Text; var AccessToken: SecretText; var RefreshToken: SecretText; var ErrorMessage: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseText: Text;
        Url: Text;
        JsonObj: JsonObject;
        Token: JsonToken;
        TenantIdText: Text;
        Body: Text;
        SecretVal: Text;
    begin
        TenantIdText := Format(TenantId);
        TenantIdText := DelChr(TenantIdText, '=', '{}');
        Url := StrSubstNo(TokenUrlLbl, TenantIdText);

        Body := StrSubstNo('grant_type=urn:ietf:params:oauth:grant-type:device_code&client_id=%1&device_code=%2', Format(ClientId), DeviceCode);

        // Append client secret if available (for confidential clients)
        if not ClientSecret.IsEmpty() then begin
            SecretVal := ClientSecret.Unwrap();
            Body += '&client_secret=' + SecretVal;
        end;

        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        if not HttpClient.Post(Url, Content, HttpResponse) then
            exit(false);

        HttpResponse.Content().ReadAs(ResponseText);
        if not JsonObj.ReadFrom(ResponseText) then
            exit(false);

        if JsonObj.Contains('error') then begin
            JsonObj.Get('error', Token);
            if Token.AsValue().AsText() = 'authorization_pending' then
                exit(false); // Still waiting

            // Other errors are fatal
            ErrorMessage := Token.AsValue().AsText();
            if JsonObj.Get('error_description', Token) then
                ErrorMessage += ': ' + Token.AsValue().AsText();

            exit(false);
        end;

        if JsonObj.Get('access_token', Token) then
            AccessToken := Token.AsValue().AsText();

        if JsonObj.Get('refresh_token', Token) then
            RefreshToken := Token.AsValue().AsText();

        exit((not AccessToken.IsEmpty()) and (not RefreshToken.IsEmpty()));
    end;

    procedure RefreshAccessToken(TenantId: Guid; ClientId: Guid; ClientSecret: SecretText; RefreshToken: SecretText; var NewAccessToken: SecretText; var NewRefreshToken: SecretText): Boolean
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseText: Text;
        Url: Text;
        JsonObj: JsonObject;
        Token: JsonToken;
        TenantIdText: Text;
        Body: Text;
        SecretVal: Text;
        RefreshTokenVal: Text;
    begin
        TenantIdText := Format(TenantId);
        TenantIdText := DelChr(TenantIdText, '=', '{}');
        Url := StrSubstNo(TokenUrlLbl, TenantIdText);

        RefreshTokenVal := RefreshToken.Unwrap();
        Body := StrSubstNo('grant_type=refresh_token&client_id=%1&refresh_token=%2&scope=%3', Format(ClientId), RefreshTokenVal, ScopeLbl);

        if not ClientSecret.IsEmpty() then begin
            SecretVal := ClientSecret.Unwrap();
            Body += '&client_secret=' + SecretVal;
        end;

        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        if not HttpClient.Post(Url, Content, HttpResponse) then
            exit(false);

        HttpResponse.Content().ReadAs(ResponseText);
        if not JsonObj.ReadFrom(ResponseText) then
            exit(false);

        if JsonObj.Get('access_token', Token) then
            NewAccessToken := Token.AsValue().AsText();

        // Refresh token might rotate
        if JsonObj.Get('refresh_token', Token) then
            NewRefreshToken := Token.AsValue().AsText()
        else
            NewRefreshToken := RefreshToken; // Keep old if not rotated

        exit(not NewAccessToken.IsEmpty());
    end;
}
