var Adjust = {
    appDidLaunch: function (adjustConfig) {
        this.bridge = adjustConfig.getBridge();

        if (this.bridge != null) {
            if (adjustConfig != null) {
                if (adjustConfig.getAttributionCallback() != null) {
                    this.bridge.callHandler('setAttributionCallback', null, adjustConfig.getAttributionCallback())
                }

                if (adjustConfig.getEventSuccessCallback() != null) {
                    this.bridge.callHandler('setEventSuccessCallback', null, adjustConfig.getEventSuccessCallback())
                }

                if (adjustConfig.getEventFailureCallback() != null) {
                    this.bridge.callHandler('setEventFailureCallback', null, adjustConfig.getEventFailureCallback())
                }

                if (adjustConfig.getSessionSuccessCallback() != null) {
                    this.bridge.callHandler('setSessionSuccessCallback', null, adjustConfig.getSessionSuccessCallback())
                }

                if (adjustConfig.getSessionFailureCallback() != null) {
                    this.bridge.callHandler('setSessionFailureCallback', null, adjustConfig.getSessionFailureCallback())
                }

                this.bridge.callHandler('appDidLaunch', adjustConfig, null)
            }
        }
    },

    trackEvent: function (adjustEvent) {
        if (this.bridge != null) {
            this.bridge.callHandler('trackEvent', adjustEvent, null)
        }
    },

    setOfflineMode: function(isOffline) {
        if (this.bridge != null) {
            this.bridge.callHandler('setOfflineMode', isOffline, null)
        }
    },

    appWillOpenUrl: function(url) {

    },

    setEnabled: function (enabled) {
        if (this.bridge != null) {
            this.bridge.callHandler('setEnabled', enabled, null)
        }
    },

    isEnabled: function (callback) {
        this.bridge.callHandler('isEnabled', null, function(response) {
            callback(response)
        })
    },

    getIdfa: function (callback) {
        this.bridge.callHandler('idfa', null, function(response) {
            callback(response)
        })
    }
};

module.exports = Adjust;