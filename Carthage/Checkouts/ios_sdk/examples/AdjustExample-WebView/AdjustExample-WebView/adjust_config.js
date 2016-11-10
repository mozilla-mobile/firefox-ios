function AdjustConfig(bridge, appToken, environment) {
    this.bridge = bridge;
    this.appToken = appToken;
    this.environment = environment;

    this.sdkPrefix = 'web';

    this.logLevel = null;
    this.defaultTracker = null;

    this.sendInBackground = null;
    this.eventBufferingEnabled = null;

    this.attributionCallback = null;
    this.eventSuccessCallback = null;
    this.eventFailureCallback = null;
    this.sessionSuccessCallback = null;
    this.sessionFailureCallback = null;
}

AdjustConfig.EnvironmentSandbox     = 'sandbox';
AdjustConfig.EnvironmentProduction  = 'production';

AdjustConfig.LogLevelVerbose        = 'VERBOSE',
AdjustConfig.LogLevelDebug          = 'DEBUG',
AdjustConfig.LogLevelInfo           = 'INFO',
AdjustConfig.LogLevelWarn           = 'WARN',
AdjustConfig.LogLevelError          = 'ERROR',
AdjustConfig.LogLevelAssert         = 'ASSERT',

AdjustConfig.prototype.getBridge = function() {
    return this.bridge;
};

AdjustConfig.prototype.getAttributionCallback = function() {
    return this.attributionCallback;
};

AdjustConfig.prototype.getEventSuccessCallback = function() {
    return this.eventSuccessCallback;
};

AdjustConfig.prototype.getEventFailureCallback = function() {
    return this.eventFailureCallback;
};

AdjustConfig.prototype.getSessionSuccessCallback = function() {
    return this.sessionSuccessCallback;
};

AdjustConfig.prototype.getSessionFailureCallback = function() {
    return this.sessionFailureCallback;
};

AdjustConfig.prototype.setEventBufferingEnabled = function(isEnabled) {
    this.eventBufferingEnabled = isEnabled;
};

AdjustConfig.prototype.setSendInBackground = function(isEnabled) {
    this.sendInBackground = isEnabled;
};

AdjustConfig.prototype.setLogLevel = function(logLevel) {
    this.logLevel = logLevel;
};

AdjustConfig.prototype.setProcessName = function(processName) {
    this.processName = processName;
};

AdjustConfig.prototype.setDefaultTracker = function(defaultTracker) {
    this.defaultTracker = defaultTracker;
};

AdjustConfig.prototype.setAttributionCallback = function(callbackFluf) {
    this.attributionCallback = callbackFluf;
};

AdjustConfig.prototype.setEventSuccessCallback = function(callback) {
    this.eventSuccessCallback = callback;
};

AdjustConfig.prototype.setEventFailureCallback = function(callback) {
    this.eventFailureCallback = callback;
};

AdjustConfig.prototype.setSessionSuccessCallback = function(callback) {
    this.sessionSuccessCallback = callback;
};

AdjustConfig.prototype.setSessionFailureCallback = function(callback) {
    this.sessionFailureCallback = callback;
};

module.exports = AdjustConfig;
