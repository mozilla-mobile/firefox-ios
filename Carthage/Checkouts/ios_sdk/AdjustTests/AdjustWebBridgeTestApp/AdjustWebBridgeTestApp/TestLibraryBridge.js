var localBaseUrl = 'http://127.0.0.1:8080';
var localGdprUrl = 'http://127.0.0.1:8080';

// local reference of the command executor
// originally it was this.adjustCommandExecutor of TestLibraryBridge var
// but for some reason, "this" on "startTestSession" was different in "adjustCommandExecutor"
var localAdjustCommandExecutor;

var TestLibraryBridge = {
    adjustCommandExecutor: function(commandRawJson) {
        console.log('TestLibraryBridge adjustCommandExecutor');
        const command = JSON.parse(commandRawJson);
        console.log('className: ' + command.className);
        console.log('functionName: ' + command.functionName);
        console.log('params: ' + JSON.stringify(command.params));

        // reflection based technique to call functions with the same name as the command function
        localAdjustCommandExecutor[command.functionName](command.params);
    },
    startTestSession: function () {
        console.log('TestLibraryBridge startTestSession');
        if (WebViewJavascriptBridge) {
            console.log('TestLibraryBridge startTestSession callHandler');
            localAdjustCommandExecutor = new AdjustCommandExecutor(localBaseUrl, localGdprUrl);
            // register objc->JS function for commands
            WebViewJavascriptBridge.registerHandler('adjustJS_commandExecutor', TestLibraryBridge.adjustCommandExecutor);
            // start test session in obj-c
            Adjust.getSdkVersion(function(sdkVersion) {
                WebViewJavascriptBridge.callHandler('adjustTLB_startTestSession', sdkVersion, null);
            });
        }
    }
};

var AdjustCommandExecutor = function(baseUrl, gdprUrl) {
    this.baseUrl           = baseUrl;
    this.gdprUrl           = gdprUrl;
    this.basePath          = null;
    this.gdprPath          = null;
    this.savedEvents       = {};
    this.savedConfigs      = {};
    this.savedCommands     = [];
    this.nextToSendCounter = 0;
};

AdjustCommandExecutor.prototype.testOptions = function(params) {
    console.log('TestLibraryBridge testOptions');
    console.log('params: ' + JSON.stringify(params));

    var TestOptions = function() {
        this.baseUrl = null;
        this.gdprUrl = null;
        this.basePath = null;
        this.gdprPath = null;
        this.timerIntervalInMilliseconds = null;
        this.timerStartInMilliseconds = null;
        this.sessionIntervalInMilliseconds = null;
        this.subsessionIntervalInMilliseconds = null;
        this.teardown = null;
        this.deleteState = null;
        this.noBackoffWait = null;
        this.iAdFrameworkEnabled = null;
    };

    var testOptions = new TestOptions();
    testOptions.baseUrl = this.baseUrl;
    testOptions.gdprUrl = this.gdprUrl;

    if ('basePath' in params) {
        var basePath = getFirstValue(params, 'basePath');
        console.log('TestLibraryBridge hasOwnProperty basePath, first: ' + basePath);
        this.basePath = basePath;
        this.gdprPath = basePath;
    }
    if ('timerInterval' in params) {
        testOptions.timerIntervalInMilliseconds = getFirstValue(params, 'timerInterval');
    }
    if ('timerStart' in params) {
        testOptions.timerStartInMilliseconds = getFirstValue(params, 'timerStart');
    }
    if ('sessionInterval' in params) {
        testOptions.sessionIntervalInMilliseconds = getFirstValue(params, 'sessionInterval');
    }
    if ('subsessionInterval' in params) {
        testOptions.subsessionIntervalInMilliseconds = getFirstValue(params, 'subsessionInterval');
    }
    if ('noBackoffWait' in params) {
        testOptions.noBackoffWait = getFirstValue(params, 'noBackoffWait');
    }
    // iAd will not be used in test app by default
    testOptions.iAdFrameworkEnabled = false;
    if ('iAdFrameworkEnabled' in params) {
        testOptions.iAdFrameworkEnabled = getFirstValue(params, 'iAdFrameworkEnabled');
    }
    if ('teardown' in params) {
        console.log('TestLibraryBridge hasOwnProperty teardown: ' + params['teardown']);

        var teardownOptions = params['teardown'];
        var teardownOptionsLength = teardownOptions.length;

        for (var i = 0; i < teardownOptionsLength; i++) {
            let teardownOption = teardownOptions[i];
            console.log('TestLibraryBridge teardown option nr ' + i + ' with value: ' + teardownOption);
            switch(teardownOption) {
                case 'resetSdk':
                    testOptions.teardown = true;
                    testOptions.basePath = this.basePath;
                    testOptions.gdprPath = this.gdprPath;
                    break;
                case 'deleteState':
                    testOptions.deleteState = true;
                    break;
                case 'resetTest':
                    // TODO: reset configs
                    // TODO: reset events
                    testOptions.timerIntervalInMilliseconds = -1;
                    testOptions.timerStartInMilliseconds = -1;
                    testOptions.sessionIntervalInMilliseconds = -1;
                    testOptions.subsessionIntervalInMilliseconds = -1;
                    break;
                case 'sdk':
                    testOptions.teardown = true;
                    testOptions.basePath = null;
                    testOptions.gdprPath = null;
                    break;
                case 'test':
                    // TODO: null configs
                    // TODO: null events
                    // TODO: null delegate
                    this.basePath = null;
                    this.gdprPath = null;
                    testOptions.timerIntervalInMilliseconds = -1;
                    testOptions.timerStartInMilliseconds = -1;
                    testOptions.sessionIntervalInMilliseconds = -1;
                    testOptions.subsessionIntervalInMilliseconds = -1;
                    break;
            }
        }
    }
    Adjust.setTestOptions(testOptions);
};

AdjustCommandExecutor.prototype.config = function(params) {
    var configNumber = 0;
    if ('configName' in params) {
        var configName = getFirstValue(params, 'configName');
        configNumber = parseInt(configName.substr(configName.length - 1));
    }

    var adjustConfig;
    if (configNumber in this.savedConfigs) {
        adjustConfig = this.savedConfigs[configNumber];
    } else {
        var environment = getFirstValue(params, 'environment');
        var appToken = getFirstValue(params, 'appToken');

        adjustConfig = new AdjustConfig(appToken, environment);
        adjustConfig.setLogLevel(AdjustConfig.LogLevelVerbose);

        this.savedConfigs[configNumber] = adjustConfig;
    }

    if ('logLevel' in params) {
        var logLevelS = getFirstValue(params, 'logLevel');
        var logLevel = null;
        switch (logLevelS) {
            case "verbose":
                logLevel = AdjustConfig.LogLevelVerbose;
                break;
            case "debug":
                logLevel = AdjustConfig.LogLevelDebug;
                break;
            case "info":
                logLevel = AdjustConfig.LogLevelInfo;
                break;
            case "warn":
                logLevel = AdjustConfig.LogLevelWarn;
                break;
            case "error":
                logLevel = AdjustConfig.LogLevelError;
                break;
            case "assert":
                logLevel = AdjustConfig.LogLevelAssert;
                break;
            case "suppress":
                logLevel = AdjustConfig.LogLevelSuppress;
                break;
        }

        adjustConfig.setLogLevel(logLevel);
    }

    if ('sdkPrefix' in params) {
        var sdkPrefix = getFirstValue(params, 'sdkPrefix');
        adjustConfig.setSdkPrefix(sdkPrefix);
    }

    if ('defaultTracker' in params) {
        var defaultTracker = getFirstValue(params, 'defaultTracker');
        adjustConfig.setDefaultTracker(defaultTracker);
    }

    if ('appSecret' in params) {
        var appSecretArray = getValues(params, 'appSecret');
        var secretId = appSecretArray[0].toString();
        var info1    = appSecretArray[1].toString();
        var info2    = appSecretArray[2].toString();
        var info3    = appSecretArray[3].toString();
        var info4    = appSecretArray[4].toString();
        adjustConfig.setAppSecret(secretId, info1, info2, info3, info4);
    }

    if ('delayStart' in params) {
        var delayStartS = getFirstValue(params, 'delayStart');
        var delayStart = parseFloat(delayStartS);
        adjustConfig.setDelayStart(delayStart);
    }

    if ('deviceKnown' in params) {
        var deviceKnownS = getFirstValue(params, 'deviceKnown');
        var deviceKnown = deviceKnownS == 'true';
        adjustConfig.setIsDeviceKnown(deviceKnown);
    }

    if ('eventBufferingEnabled' in params) {
        var eventBufferingEnabledS = getFirstValue(params, 'eventBufferingEnabled');
        var eventBufferingEnabled = eventBufferingEnabledS == 'true';
        adjustConfig.setEventBufferingEnabled(eventBufferingEnabled);
    }

    if ('sendInBackground' in params) {
        var sendInBackgroundS = getFirstValue(params, 'sendInBackground');
        var sendInBackground = sendInBackgroundS == 'true';
        adjustConfig.setSendInBackground(sendInBackground);
    }

    if ('userAgent' in params) {
        var userAgent = getFirstValue(params, 'userAgent');
        adjustConfig.setUserAgent(userAgent);
    }

    if ('attributionCallbackSendAll' in params) {
        console.log('AdjustCommandExecutor.prototype.config attributionCallbackSendAll');
        var basePath = this.basePath;
        adjustConfig.setAttributionCallback(
            function(attribution) {
                console.log('attributionCallback: ' + JSON.stringify(attribution));
                addInfoToSend('trackerToken', attribution.trackerToken);
                addInfoToSend('trackerName', attribution.trackerName);
                addInfoToSend('network', attribution.network);
                addInfoToSend('campaign', attribution.campaign);
                addInfoToSend('adgroup', attribution.adgroup);
                addInfoToSend('creative', attribution.creative);
                addInfoToSend('clickLabel', attribution.click_label);
                addInfoToSend('adid', attribution.adid);
                WebViewJavascriptBridge.callHandler('adjustTLB_sendInfoToServer', basePath, null);
            }
        );
    }

    if ('sessionCallbackSendSuccess' in params) {
        console.log('AdjustCommandExecutor.prototype.config sessionCallbackSendSuccess');
        var basePath = this.basePath;
        adjustConfig.setSessionSuccessCallback(
            function(sessionSuccessResponseData) {
                console.log('sessionSuccessCallback: ' + JSON.stringify(sessionSuccessResponseData));
                addInfoToSend('message', sessionSuccessResponseData.message);
                addInfoToSend('timestamp', sessionSuccessResponseData.timestamp);
                addInfoToSend('adid', sessionSuccessResponseData.adid);
                addInfoToSend('jsonResponse', sessionSuccessResponseData.jsonResponse);
                WebViewJavascriptBridge.callHandler('adjustTLB_sendInfoToServer', basePath, null);
            }
        );
    }

    if ('sessionCallbackSendFailure' in params) {
        console.log('AdjustCommandExecutor.prototype.config sessionCallbackSendFailure');
        var basePath = this.basePath;
        adjustConfig.setSessionFailureCallback(
            function(sessionFailureResponseData) {
                console.log('sessionFailureCallback: ' + JSON.stringify(sessionFailureResponseData));
                addInfoToSend('message', sessionFailureResponseData.message);
                addInfoToSend('timestamp', sessionFailureResponseData.timestamp);
                addInfoToSend('adid', sessionFailureResponseData.adid);
                addInfoToSend('willRetry', sessionFailureResponseData.willRetry ? 'true' : 'false');
                addInfoToSend('jsonResponse', sessionFailureResponseData.jsonResponse);
                WebViewJavascriptBridge.callHandler('adjustTLB_sendInfoToServer', basePath, null);
            }
        );
    }

    if ('eventCallbackSendSuccess' in params) {
        console.log('AdjustCommandExecutor.prototype.config eventCallbackSendSuccess');
        var basePath = this.basePath;
        adjustConfig.setEventSuccessCallback(
            function(eventSuccessResponseData) {
                console.log('eventSuccessCallback: ' + JSON.stringify(eventSuccessResponseData));
                addInfoToSend('message', eventSuccessResponseData.message);
                addInfoToSend('timestamp', eventSuccessResponseData.timestamp);
                addInfoToSend('adid', eventSuccessResponseData.adid);
                addInfoToSend('eventToken', eventSuccessResponseData.eventToken);
                addInfoToSend('callbackId', eventSuccessResponseData.callbackId);
                addInfoToSend('jsonResponse', eventSuccessResponseData.jsonResponse);
                WebViewJavascriptBridge.callHandler('adjustTLB_sendInfoToServer', basePath, null);
            }
        );
    }

    if ('eventCallbackSendFailure' in params) {
        console.log('AdjustCommandExecutor.prototype.config eventCallbackSendFailure');
        var basePath = this.basePath;
        adjustConfig.setEventFailureCallback(
            function(eventFailureResponseData) {
                console.log('eventFailureCallback: ' + JSON.stringify(eventFailureResponseData));
                addInfoToSend('message', eventFailureResponseData.message);
                addInfoToSend('timestamp', eventFailureResponseData.timestamp);
                addInfoToSend('adid', eventFailureResponseData.adid);
                addInfoToSend('eventToken', eventFailureResponseData.eventToken);
                addInfoToSend('callbackId', eventFailureResponseData.callbackId);
                addInfoToSend('willRetry', eventFailureResponseData.willRetry ? 'true' : 'false');
                addInfoToSend('jsonResponse', eventFailureResponseData.jsonResponse);
                WebViewJavascriptBridge.callHandler('adjustTLB_sendInfoToServer', basePath, null);
            }
        );
    }

    if ('deferredDeeplinkCallback' in params) {
        console.log('AdjustCommandExecutor.prototype.config deferredDeeplinkCallback');
        var shouldOpenDeeplinkS = getFirstValue(params, 'deferredDeeplinkCallback');
        if (shouldOpenDeeplinkS === 'true') {
            adjustConfig.setOpenDeferredDeeplink(true);
        }
        if (shouldOpenDeeplinkS === 'false') {
            adjustConfig.setOpenDeferredDeeplink(false);
        }
        var basePath = this.basePath;
        adjustConfig.setDeferredDeeplinkCallback(
            function(deeplink) {
                console.log('deferredDeeplinkCallback: ' + JSON.stringify(deeplink));
                addInfoToSend('deeplink', deeplink);
                WebViewJavascriptBridge.callHandler('adjustTLB_sendInfoToServer', basePath, null);
            }
        );
    }
};

var addInfoToSend = function(key, value) {
    WebViewJavascriptBridge.callHandler('adjustTLB_addInfoToSend', {key: key, value: value}, null);
};

AdjustCommandExecutor.prototype.start = function(params) {
    this.config(params);
    var configNumber = 0;
    if ('configName' in params) {
        var configName = getFirstValue(params, 'configName');
        configNumber = parseInt(configName.substr(configName.length - 1));
    }

    var adjustConfig = this.savedConfigs[configNumber];
    Adjust.appDidLaunch(adjustConfig);

    delete this.savedConfigs[0];
};

AdjustCommandExecutor.prototype.event = function(params) {
    var eventNumber = 0;
    if ('eventName' in params) {
        var eventName = getFirstValue(params, 'eventName');
        eventNumber = parseInt(eventName.substr(eventName.length - 1))
    }

    var adjustEvent;
    if (eventNumber in this.savedEvents) {
        adjustEvent = this.savedEvents[eventNumber];
    } else {
        var eventToken = getFirstValue(params, 'eventToken');
        adjustEvent = new AdjustEvent(eventToken);
        this.savedEvents[eventNumber] = adjustEvent;
    }

    if ('revenue' in params) {
        var revenueParams = getValues(params, 'revenue');
        var currency = revenueParams[0];
        var revenue = parseFloat(revenueParams[1]);
        adjustEvent.setRevenue(revenue, currency);
    }

    if ('callbackParams' in params) {
        var callbackParams = getValues(params, 'callbackParams');
        for (var i = 0; i < callbackParams.length; i = i + 2) {
            var key = callbackParams[i];
            var value = callbackParams[i + 1];
            adjustEvent.addCallbackParameter(key, value);
        }
    }

    if ('partnerParams' in params) {
        var partnerParams = getValues(params, 'partnerParams');
        for (var i = 0; i < partnerParams.length; i = i + 2) {
            var key = partnerParams[i];
            var value = partnerParams[i + 1];
            adjustEvent.addPartnerParameter(key, value);
        }
    }

    if ('orderId' in params) {
        var orderId = getFirstValue(params, 'orderId');
        adjustEvent.setTransactionId(orderId);
    }

    if ('callbackId' in params) {
        var callbackId = getFirstValue(params, 'callbackId');
        adjustEvent.setCallbackId(callbackId);
    }
};

AdjustCommandExecutor.prototype.trackEvent = function(params) {
    this.event(params);
    var eventNumber = 0;
    if ('eventName' in params) {
        var eventName = getFirstValue(params, 'eventName');
        eventNumber = parseInt(eventName.substr(eventName.length - 1))
    }

    var adjustEvent = this.savedEvents[eventNumber];
    Adjust.trackEvent(adjustEvent);

    delete this.savedEvents[0];
};

AdjustCommandExecutor.prototype.pause = function(params) {
    Adjust.trackSubsessionEnd();
};

AdjustCommandExecutor.prototype.resume = function(params) {
    Adjust.trackSubsessionStart();
};

AdjustCommandExecutor.prototype.setEnabled = function(params) {
    var enabled = getFirstValue(params, 'enabled') == 'true';
    Adjust.setEnabled(enabled);
};

AdjustCommandExecutor.prototype.setOfflineMode = function(params) {
    var enabled = getFirstValue(params, 'enabled') == 'true';
    Adjust.setOfflineMode(enabled);
};

AdjustCommandExecutor.prototype.sendFirstPackages = function(params) {
    Adjust.sendFirstPackages();
};

AdjustCommandExecutor.prototype.gdprForgetMe = function(params) {
    Adjust.gdprForgetMe();
};

AdjustCommandExecutor.prototype.addSessionCallbackParameter = function(params) {
    var list = getValues(params, 'KeyValue');

    for (var i = 0; i < list.length; i = i+2){
        var key = list[i];
        var value = list[i+1];
        Adjust.addSessionCallbackParameter(key, value);
    }
};

AdjustCommandExecutor.prototype.addSessionPartnerParameter = function(params) {
    var list = getValues(params, 'KeyValue');

    for (var i = 0; i < list.length; i = i+2){
        var key = list[i];
        var value = list[i+1];
        Adjust.addSessionPartnerParameter(key, value);
    }
};

AdjustCommandExecutor.prototype.removeSessionCallbackParameter = function(params) {
    var list = getValues(params, 'key');

    for (var i = 0; i < list.length; i++) {
        var key = list[i];
        Adjust.removeSessionCallbackParameter(key);
    }
};

AdjustCommandExecutor.prototype.removeSessionPartnerParameter = function(params) {
    var list = getValues(params, 'key');

    for (var i = 0; i < list.length; i++) {
        var key = list[i];
        Adjust.removeSessionPartnerParameter(key);
    }
};

AdjustCommandExecutor.prototype.resetSessionCallbackParameters = function(params) {
    Adjust.resetSessionCallbackParameters();
};

AdjustCommandExecutor.prototype.resetSessionPartnerParameters = function(params) {
    Adjust.resetSessionPartnerParameters();
};

AdjustCommandExecutor.prototype.setPushToken = function(params) {
    var token = getFirstValue(params, 'pushToken');
    Adjust.setDeviceToken(token);
};

AdjustCommandExecutor.prototype.openDeeplink = function(params) {
    var deeplink = getFirstValue(params, 'deeplink');
    Adjust.appWillOpenUrl(deeplink);
};

// Util
function getValues(params, key) {
    if (key in params) {
        return params[key];
    }

    return null;
}

function getFirstValue(params, key) {
    if (key in params) {
        var param = params[key];

        if(param != null && param.length >= 1) {
            return param[0];
        }
    }

    return null;
}

module.exports = TestLibraryBridge;
