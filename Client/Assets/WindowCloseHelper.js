(function () {
  var _close = window.close;
  window.close = function () {
    console.log("Yo I am going to close");
    webkit.messageHandlers.windowCloseHelper.postMessage(null);
    _close();
  };
})();