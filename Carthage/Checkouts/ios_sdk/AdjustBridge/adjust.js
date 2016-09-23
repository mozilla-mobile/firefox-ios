var Adjust = {
    appDidLaunch: function (adjustConfig) {
        this.bridge = adjustConfig.getBridge();

        if (this.bridge != null) {
            if (adjustConfig != null) {
                if (adjustConfig.getAttributionCallback() != null) {
                    this.bridge.callHandler('adjust_setAttributionCallback', null, adjustConfig.getAttributionCallback())
                }

                if (adjustConfig.getEventSuccessCallback() != null) {
                    this.bridge.callHandler('adjust_setEventSuccessCallback', null, adjustConfig.getEventSuccessCallback())
                }

                if (adjustConfig.getEventFailureCallback() != null) {
                    this.bridge.callHandler('adjust_setEventFailureCallback', null, adjustConfig.getEventFailureCallback())
                }

                if (adjustConfig.getSessionSuccessCallback() != null) {
                    this.bridge.callHandler('adjust_setSessionSuccessCallback', null, adjustConfig.getSessionSuccessCallback())
                }

                if (adjustConfig.getSessionFailureCallback() != null) {
                    this.bridge.callHandler('adjust_setSessionFailureCallback', null, adjustConfig.getSessionFailureCallback())
                }

                if (adjustConfig.getDeferredDeeplinkCallback() != null) {
                    this.bridge.callHandler('adjust_setDeferredDeeplinkCallback', null, adjustConfig.getDeferredDeeplinkCallback())
                }

                this.bridge.callHandler('adjust_appDidLaunch', adjustConfig, null)
            }
        }
    },

    trackEvent: function (adjustEvent) {
        if (this.bridge != null) {
            this.bridge.callHandler('adjust_trackEvent', adjustEvent, null)
        }
    },

    setOfflineMode: function(isOffline) {
        if (this.bridge != null) {
            this.bridge.callHandler('adjust_setOfflineMode', isOffline, null)
        }
    },

    setEnabled: function (enabled) {
        if (this.bridge != null) {
            this.bridge.callHandler('adjust_setEnabled', enabled, null)
        }
    },

    isEnabled: function (callback) {
        if (this.bridge != null) {
            this.bridge.callHandler('adjust_isEnabled', null, function(response) {
                callback(new Boolean(response))
            })
        }
    },

    getIdfa: function (callback) {
        if (this.bridge != null) {
            this.bridge.callHandler('adjust_idfa', null, function(response) {
                callback(response)
            })
        }
    },

    appWillOpenUrl: function (url) {
        if (this.bridge != null) {
            this.bridge.callHandler('adjust_appWillOpenUrl', url, null)
        }
    }
};

module.exports = Adjust;
