// Override AriaNg RPC settings on page load
window.addEventListener('load', function() {
  setTimeout(function() {
      // Get the angular scope
      var appElement = document.querySelector('[ng-app="ariaNg"]');
      if (!appElement) return;

      var angularScope = angular.element(appElement).scope();
      if (!angularScope) return;

      // Force RPC settings
      var ariaNgSettingService = angular.element(appElement).injector().get('ariaNgSettingService');
      if (!ariaNgSettingService) return;

      // Update all RPC settings to use relative paths
      var allRpcSettings = ariaNgSettingService.getAllRpcSettings();
      if (allRpcSettings && allRpcSettings.length > 0) {
          for (var i = 0; i < allRpcSettings.length; i++) {
              allRpcSettings[i].rpcHost = "";
              allRpcSettings[i].rpcPort = "";
          }

          console.log('AriaNg RPC settings overridden to use relative paths');
          location.reload();
      }
  }, 1000);
});
