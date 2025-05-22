(function waitForBody() {
  const buttonId = "custom-sso-button"

  if (!document.body) {
    return setTimeout(waitForBody, 100);
  }

  function oAuthInitDeviceId() {
    if (!localStorage.getItem('_deviceId2') && window.NativeShell?.AppHost?.deviceId) {
      localStorage.setItem('_deviceId2', window.NativeShell.AppHost.deviceId());
    }
  }

  // Attach device ID logic to existing SSO button
  function attachSSOHandler() {
    const ssoButton = document.getElementById(buttonId);
    if (ssoButton) {
      ssoButton.onclick = oAuthInitDeviceId;
    }
  }

  // Observe DOM until SSO button appears
  const observer = new MutationObserver(() => {
    const containerReady = document.querySelector('.readOnlyContent') || document.querySelector('form');
    const ssoButtonReady = document.getElementById(buttonId);

    if (containerReady && ssoButtonReady) {
      attachSSOHandler();
      observer.disconnect();
    }
  });

  observer.observe(document.body, { childList: true, subtree: true });
})();
