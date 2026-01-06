var pollIntervals = {};
var pollTimeouts = {};
var currentLoginData = null;

function InitializeControl() {
    var container = document.getElementById('controlAddIn');
    container.innerHTML = `
        <div id="login-container" style="display:none; padding: 20px; text-align: center;">
            <p id="instruction-text">Click the button below to copy the code <strong><span id="user-code-display"></span></strong> and open the login page.</p>
            <button id="login-btn" class="ms-Button ms-Button--primary">
                <span class="ms-Button-label">Copy Code & Open Login</span>
            </button>
            <div id="status-message" style="margin-top: 10px; color: #666;"></div>
        </div>
    `;

    document.getElementById('login-btn').addEventListener('click', function() {
        if (!currentLoginData) return;

        // User Activation Context here

        // Copy to clipboard
        navigator.clipboard.writeText(currentLoginData.userCode).then(function() {
            console.log('Copied to clipboard');
        }, function(err) {
            console.error('Copy failed', err);
            alert('Failed to copy code. Please manually copy: ' + currentLoginData.userCode);
        });

        // Open window
        window.open(currentLoginData.verificationUrl, '_blank');

        // Update UI
        document.getElementById('status-message').innerText = 'Waiting for login...';
        document.getElementById('login-btn').disabled = true;

        // Start polling
        StartPollingInternal(currentLoginData.tenantId, currentLoginData.deviceCode, currentLoginData.clientId, currentLoginData.intervalSeconds, currentLoginData.expiresInSeconds);
    });

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
}

function StartLoginProcess(tenantId, clientId, userCode, verificationUrl, deviceCode, intervalSeconds, expiresInSeconds) {
    // Store data
    currentLoginData = {
        tenantId: tenantId,
        clientId: clientId,
        userCode: userCode,
        verificationUrl: verificationUrl,
        deviceCode: deviceCode,
        intervalSeconds: intervalSeconds || 5,
        expiresInSeconds: expiresInSeconds || 900
    };

    // Show UI
    document.getElementById('user-code-display').innerText = userCode;
    document.getElementById('login-container').style.display = 'block';
    document.getElementById('login-btn').disabled = false;
    document.getElementById('status-message').innerText = '';
}

function StartPollingInternal(tenantId, deviceCode, clientId, intervalSeconds, expiresInSeconds) {
    if (pollIntervals[tenantId]) {
        clearInterval(pollIntervals[tenantId]);
    }
    if (pollTimeouts[tenantId]) {
        clearTimeout(pollTimeouts[tenantId]);
    }

    // Use the interval from the server response (converted to milliseconds)
    var intervalMs = (intervalSeconds || 5) * 1000;

    pollIntervals[tenantId] = setInterval(function() {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('PollToken', [tenantId, deviceCode, clientId]);
    }, intervalMs);

    // Set timeout based on expires_in
    var expiresInMs = (expiresInSeconds || 900) * 1000;
    pollTimeouts[tenantId] = setTimeout(function() {
        StopPolling(tenantId);
        document.getElementById('status-message').innerText = 'Login timeout - device code expired';
        document.getElementById('login-btn').disabled = false;
    }, expiresInMs);
}

function StopPolling(tenantId) {
    if (pollIntervals[tenantId]) {
        clearInterval(pollIntervals[tenantId]);
        delete pollIntervals[tenantId];
    }
    if (pollTimeouts[tenantId]) {
        clearTimeout(pollTimeouts[tenantId]);
        delete pollTimeouts[tenantId];
    }
    document.getElementById('status-message').innerText = 'Login successful!';
    setTimeout(function() {
        document.getElementById('login-container').style.display = 'none';
    }, 2000);
}

InitializeControl();
