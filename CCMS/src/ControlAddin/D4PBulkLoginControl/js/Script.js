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
        StartPollingInternal(currentLoginData.tenantId, currentLoginData.deviceCode, currentLoginData.clientId, currentLoginData.expiresIn);
    });

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
}

function StartLoginProcess(tenantId, clientId, userCode, verificationUrl, deviceCode, expiresIn) {
    // Store data
    currentLoginData = {
        tenantId: tenantId,
        clientId: clientId,
        userCode: userCode,
        verificationUrl: verificationUrl,
        deviceCode: deviceCode,
        expiresIn: expiresIn || 900 // Default to 15 minutes
    };

    // Show UI
    document.getElementById('user-code-display').innerText = userCode;
    document.getElementById('login-container').style.display = 'block';
    document.getElementById('login-btn').disabled = false;
    document.getElementById('status-message').innerText = '';
}

function StartPollingInternal(tenantId, deviceCode, clientId, expiresIn) {
    // Clear any existing polling for this tenant
    if (pollIntervals[tenantId]) {
        clearInterval(pollIntervals[tenantId]);
    }
    if (pollTimeouts[tenantId]) {
        clearTimeout(pollTimeouts[tenantId]);
    }

    // Start polling
    pollIntervals[tenantId] = setInterval(function() {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('PollToken', [tenantId, deviceCode, clientId]);
    }, 5000);

    // Set timeout to stop polling after expiration
    var expiresInMs = (expiresIn || 900) * 1000; // Convert seconds to milliseconds
    pollTimeouts[tenantId] = setTimeout(function() {
        // Stop polling
        if (pollIntervals[tenantId]) {
            clearInterval(pollIntervals[tenantId]);
            delete pollIntervals[tenantId];
        }
        delete pollTimeouts[tenantId];

        // Update UI to show timeout message
        document.getElementById('status-message').innerText = 'Login timed out. The code has expired.';
        document.getElementById('login-btn').disabled = false;
        document.getElementById('login-btn').querySelector('.ms-Button-label').innerText = 'Try Again';
    }, expiresInMs);
}

function StopPolling(tenantId) {
    // Clear polling interval
    if (pollIntervals[tenantId]) {
        clearInterval(pollIntervals[tenantId]);
        delete pollIntervals[tenantId];
    }
    // Clear timeout
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
