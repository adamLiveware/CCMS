controladdin "D4P Bulk Login Control"
{
    Scripts = 'CCMS/src/ControlAddin/D4PBulkLoginControl/js/Script.js';
    StyleSheets = 'CCMS/src/ControlAddin/D4PBulkLoginControl/css/Style.css';

    RequestedHeight = 100;
    RequestedWidth = 300;
    VerticalStretch = false;
    HorizontalStretch = false;

    event ControlReady();
    event PollToken(TenantId: Guid; DeviceCode: Text; ClientId: Guid);

    procedure StartLoginProcess(TenantId: Guid; ClientId: Guid; UserCode: Text; VerificationUrl: Text; DeviceCode: Text; IntervalSeconds: Integer; ExpiresInSeconds: Integer);
    procedure StopPolling(TenantId: Guid);
}
