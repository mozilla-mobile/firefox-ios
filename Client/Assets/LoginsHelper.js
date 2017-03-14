/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

var gEnabled = true;
var gStoreWhenAutocompleteOff = true;
var gAutofillForms = true;
var gDebug = false;

function log(pieces) {
  if (!gDebug)
    return;
  alert(pieces);
}

var LoginManagerContent = {
  _getRandomId: function() {
    return Math.round(Math.random() * (Number.MAX_VALUE - Number.MIN_VALUE) + Number.MIN_VALUE).toString()
  },

  _messages: [ "RemoteLogins:loginsFound" ],

  // Map from form login requests to information about that request.
  _requests: { },

  _takeRequest: function(msg) {
    var data = msg;
    var request = this._requests[data.requestId];
    this._requests[data.requestId] = undefined;
    return request;
  },

  _sendRequest: function(requestData, messageData) {
    var requestId = this._getRandomId();
    messageData.requestId = requestId;
    webkit.messageHandlers.loginsManagerMessageHandler.postMessage(messageData);

    var self = this;
    return new Promise(function(resolve, reject) {
      requestData.promise = { resolve: resolve, reject: reject };
      self._requests[requestId] = requestData;
    });
  },

  receiveMessage: function (msg) {
    var request = this._takeRequest(msg);
    switch (msg.name) {
      case "RemoteLogins:loginsFound": {
        request.promise.resolve({ form: request.form,
                                  loginsFound: msg.logins });
        break;
      }

      case "RemoteLogins:loginsAutoCompleted": {
        request.promise.resolve(msg.logins);
        break;
      }
    }
  },

  _asyncFindLogins : function (form, options) {
    // XXX - Unlike desktop, I want to avoid doing a lookup if there is no username/password in this form
    var fields = this._getFormFields(form, false);
    if (!fields[0] || !fields[1]) {
      return Promise.reject("No logins found");
    }

    fields[0].addEventListener("blur", onBlur)

    var formOrigin = LoginUtils._getPasswordOrigin();
    var actionOrigin = LoginUtils._getActionOrigin(form);
    if (actionOrigin == null) {
      return Promise.reject("Action origin is null")
    }

    // XXX - Allowing the page to set origin information in this message is a security problem. Right now its just ignored...
    // TODO: We need to designate what type of message we're sending here...
    var requestData = { form: form };
    var messageData = { type: "request", formOrigin: formOrigin, actionOrigin: actionOrigin };
    return this._sendRequest(requestData, messageData);
  },

  loginsFound : function (form, loginsFound) {
    var autofillForm = gAutofillForms; // && !PrivateBrowsingUtils.isContentWindowPrivate(doc.defaultView);
    this._fillForm(form, autofillForm, false, false, false, loginsFound);
  },

  /*
   * onUsernameInput
   *
   * Listens for DOMAutoComplete and blur events on an input field.
   */
  onUsernameInput : function(event) {
    if (!gEnabled)
      return;

    var acInputField = event.target;

    // This is probably a bit over-conservatative.
    if (!(acInputField.ownerDocument instanceof HTMLDocument))
      return;

    if (!this._isUsernameFieldType(acInputField))
      return;

    var acForm = acInputField.form;
    if (!acForm)
      return;

    // If the username is blank, bail out now -- we don't want
    // fillForm() to try filling in a login without a username
    // to filter on (bug 471906).
    if (!acInputField.value)
      return;      

    log("onUsernameInput from", event.type);

    // Make sure the username field fillForm will use is the
    // same field as the autocomplete was activated on.
    var [usernameField, passwordField, ignored] =
        this._getFormFields(acForm, false);
    if (usernameField == acInputField && passwordField) {
      var self = this;
      this._asyncFindLogins(acForm, { showMasterPassword: false })
          .then(function(res) {
              self._fillForm(res.form, true, true, true, true, res.loginsFound);
          }).then(null, log);
    } else {
      // Ignore the event, it's for some input we don't care about.
    }
  },

  /*
   * _getPasswordFields
   *
   * Returns an array of password field elements for the specified form.
   * If no pw fields are found, or if more than 3 are found, then null
   * is returned.
   *
   * skipEmptyFields can be set to ignore password fields with no value.
   */
  _getPasswordFields : function (form, skipEmptyFields) {
    // Locate the password fields in the form.
    var pwFields = [];
    for (var i = 0; i < form.elements.length; i++) {
      var element = form.elements[i];
      if (!(element instanceof HTMLInputElement) ||
          element.type != "password")
        continue;

      if (skipEmptyFields && !element.value)
        continue;

      pwFields[pwFields.length] = { index   : i,
                                    element : element };
    }

    // If too few or too many fields, bail out.
    if (pwFields.length == 0) {
      log("(form ignored -- no password fields.)");
      return null;
    } else if (pwFields.length > 3) {
      log("(form ignored -- too many password fields. [ got ",
                  pwFields.length, "])");
      return null;
    }
    return pwFields;
  },

  _isUsernameFieldType: function(element) {
    if (!(element instanceof HTMLInputElement))
      return false;

    var fieldType = (element.hasAttribute("type") ?
                     element.getAttribute("type").toLowerCase() :
                     element.type);
    if (fieldType == "text"  ||
        fieldType == "email" ||
        fieldType == "url"   ||
        fieldType == "tel"   ||
        fieldType == "number") {
      return true;
    }
    return false;
  },

  /*
   * _getFormFields
   *
   * Returns the username and password fields found in the form.
   * Can handle complex forms by trying to figure out what the
   * relevant fields are.
   *
   * Returns: [usernameField, newPasswordField, oldPasswordField]
   *
   * usernameField may be null.
   * newPasswordField will always be non-null.
   * oldPasswordField may be null. If null, newPasswordField is just
   * "theLoginField". If not null, the form is apparently a
   * change-password field, with oldPasswordField containing the password
   * that is being changed.
   */
  _getFormFields : function (form, isSubmission) {
    var usernameField = null;

    // Locate the password field(s) in the form. Up to 3 supported.
    // If there's no password field, there's nothing for us to do.
    var pwFields = this._getPasswordFields(form, isSubmission);
    if (!pwFields)
      return [null, null, null];

    // Locate the username field in the form by searching backwards
    // from the first passwordfield, assume the first text field is the
    // username. We might not find a username field if the user is
    // already logged in to the site.
    for (var i = pwFields[0].index - 1; i >= 0; i--) {
      var element = form.elements[i];
      if (this._isUsernameFieldType(element)) {
        usernameField = element;
        break;
      }
    }

    if (!usernameField)
      log("(form -- no username field found)");


    // If we're not submitting a form (it's a page load), there are no
    // password field values for us to use for identifying fields. So,
    // just assume the first password field is the one to be filled in.
    if (!isSubmission || pwFields.length == 1)
      return [usernameField, pwFields[0].element, null];


    // Try to figure out WTF is in the form based on the password values.
    var oldPasswordField, newPasswordField;
    var pw1 = pwFields[0].element.value;
    var pw2 = pwFields[1].element.value;
    var pw3 = (pwFields[2] ? pwFields[2].element.value : null);

    if (pwFields.length == 3) {
      // Look for two identical passwords, that's the new password

      if (pw1 == pw2 && pw2 == pw3) {
        // All 3 passwords the same? Weird! Treat as if 1 pw field.
        newPasswordField = pwFields[0].element;
        oldPasswordField = null;
      } else if (pw1 == pw2) {
        newPasswordField = pwFields[0].element;
        oldPasswordField = pwFields[2].element;
      } else if (pw2 == pw3) {
        oldPasswordField = pwFields[0].element;
        newPasswordField = pwFields[2].element;
      } else  if (pw1 == pw3) {
        // A bit odd, but could make sense with the right page layout.
        newPasswordField = pwFields[0].element;
        oldPasswordField = pwFields[1].element;
      } else {
        // We can't tell which of the 3 passwords should be saved.
        log("(form ignored -- all 3 pw fields differ)");
        return [null, null, null];
      }
    } else { // pwFields.length == 2
      if (pw1 == pw2) {
        // Treat as if 1 pw field
        newPasswordField = pwFields[0].element;
        oldPasswordField = null;
      } else {
        // Just assume that the 2nd password is the new password
        oldPasswordField = pwFields[0].element;
        newPasswordField = pwFields[1].element;
      }
    }

    return [usernameField, newPasswordField, oldPasswordField];
  },

  /*
   * _isAutoCompleteDisabled
   *
   * Returns true if the page requests autocomplete be disabled for the
   * specified form input.
   */
  _isAutocompleteDisabled :  function (element) {
    if (element && element.hasAttribute("autocomplete") &&
        element.getAttribute("autocomplete").toLowerCase() == "off")
      return true;

    return false;
  },

  /*
   * _onFormSubmit
   *
   * Called by the our observer when notified of a form submission.
   * [Note that this happens before any DOM onsubmit handlers are invoked.]
   * Looks for a password change in the submitted form, so we can update
   * our stored password.
   */
  _onFormSubmit : function (form) {
    var doc = form.ownerDocument;
    var win = doc.defaultView;

    // XXX - We'll handle private mode in Swift
    // if (PrivateBrowsingUtils.isContentWindowPrivate(win)) {
      // We won't do anything in private browsing mode anyway,
      // so there's no need to perform further checks.
      // log("(form submission ignored in private browsing mode)");
      // return;
    // }

    // If password saving is disabled (globally or for host), bail out now.
    if (!gEnabled)
      return;

    var hostname = LoginUtils._getPasswordOrigin(doc.documentURI);
    if (!hostname) {
      log("(form submission ignored -- invalid hostname)");
      return;
    }

    var formSubmitURL = LoginUtils._getActionOrigin(form);

    // Get the appropriate fields from the form.
    // [usernameField, newPasswordField, oldPasswordField]
    var fields = this._getFormFields(form, true);
    var usernameField = fields[0];
    var newPasswordField = fields[1];
    var oldPasswordField = fields[2];

    // Need at least 1 valid password field to do anything.
    if (newPasswordField == null)
      return;

    // Check for autocomplete=off attribute. We don't use it to prevent
    // autofilling (for existing logins), but won't save logins when it's
    // present and the storeWhenAutocompleteOff pref is false.
    // XXX spin out a bug that we don't update timeLastUsed in this case?
    if ((this._isAutocompleteDisabled(form) ||
         this._isAutocompleteDisabled(usernameField) ||
         this._isAutocompleteDisabled(newPasswordField) ||
         this._isAutocompleteDisabled(oldPasswordField)) && !gStoreWhenAutocompleteOff) {
      log("(form submission ignored -- autocomplete=off found)");
      return;
    }

    // Don't try to send DOM nodes over IPC.
    var mockUsername = usernameField ? { name: usernameField.name,
                                         value: usernameField.value } :
                                         null;
    var mockPassword = { name: newPasswordField.name,
                         value: newPasswordField.value };
    var mockOldPassword = oldPasswordField ?
                        { name: oldPasswordField.name,
                          value: oldPasswordField.value } :
                          null;

    // Make sure to pass the opener's top in case it was in a frame.
    var opener = win.opener ? win.opener.top : null;

    webkit.messageHandlers.loginsManagerMessageHandler.postMessage({
      type: "submit",
      hostname: hostname,
      username: mockUsername.value,
      usernameField: mockUsername.name,
      password: mockPassword.value,
      passwordField: mockPassword.name,
      formSubmitURL: formSubmitURL
    });
  },

  /*
   * _fillform
   *
   * Fill the form with login information if we can find it. This will find
   * an array of logins if not given any, otherwise it will use the logins
   * passed in. The logins are returned so they can be reused for
   * optimization. Success of action is also returned in format
   * [success, foundLogins].
   *
   * - autofillForm denotes if we should fill the form in automatically
   * - ignoreAutocomplete denotes if we should ignore autocomplete=off
   *     attributes
   * - userTriggered is an indication of whether this filling was triggered by
   *     the user
   * - foundLogins is an array of nsILoginInfo for optimization
   */
  _fillForm : function (form, autofillForm, ignoreAutocomplete,
                        clobberPassword, userTriggered, foundLogins) {
    // Heuristically determine what the user/pass fields are
    // We do this before checking to see if logins are stored,
    // so that the user isn't prompted for a master password
    // without need.
    var fields = this._getFormFields(form, false);
    var usernameField = fields[0];
    var passwordField = fields[1];

    // Need a valid password field to do anything.
    if (passwordField == null)
      return [false, foundLogins];

    // If the password field is disabled or read-only, there's nothing to do.
    if (passwordField.disabled || passwordField.readOnly) {
      log("not filling form, password field disabled or read-only");
      return [false, foundLogins];
    }

    // Discard logins which have username/password values that don't
    // fit into the fields (as specified by the maxlength attribute).
    // The user couldn't enter these values anyway, and it helps
    // with sites that have an extra PIN to be entered (bug 391514)
    var maxUsernameLen = Number.MAX_VALUE;
    var maxPasswordLen = Number.MAX_VALUE;

    // If attribute wasn't set, default is -1.
    if (usernameField && usernameField.maxLength >= 0)
      maxUsernameLen = usernameField.maxLength;
    if (passwordField.maxLength >= 0)
      maxPasswordLen = passwordField.maxLength;

    var createLogin = function(login) {
      return {
        hostname: login.hostname,
        formSubmitURL: login.formSubmitURL,
        httpReal : login.httpRealm,
        username: login.username,
        password: login.password,
        usernameField: login.usernameField,
        passwordField: login.passwordField
      }
    }
    foundLogins = map(foundLogins, createLogin);
    var logins = foundLogins.filter(function (l) {
      var fit = (l.username.length <= maxUsernameLen &&
                 l.password.length <= maxPasswordLen);
      if (!fit)
        log("Ignored", l.username, "login: won't fit");

      return fit;
    }, this);


    // Nothing to do if we have no matching logins available.
    if (logins.length == 0)
      return [false, foundLogins];

    // The reason we didn't end up filling the form, if any.  We include
    // this in the formInfo object we send with the passwordmgr-found-logins
    // notification.  See the _notifyFoundLogins docs for possible values.
    var didntFillReason = null;

    // Attach autocomplete stuff to the username field, if we have
    // one. This is normally used to select from multiple accounts,
    // but even with one account we should refill if the user edits.
    // if (usernameField)
    //    formFillService.markAsLoginManagerField(usernameField);

    // Don't clobber an existing password.
    if (passwordField.value && !clobberPassword) {
      didntFillReason = "existingPassword";
      return [false, foundLogins];
    }

    // If the form has an autocomplete=off attribute in play, don't
    // fill in the login automatically. We check this after attaching
    // the autocomplete stuff to the username field, so the user can
    // still manually select a login to be filled in.
    var isFormDisabled = false;
    if (!ignoreAutocomplete &&
        (this._isAutocompleteDisabled(form) ||
         this._isAutocompleteDisabled(usernameField) ||
         this._isAutocompleteDisabled(passwordField))) {

      isFormDisabled = true;
      log("form not filled, has autocomplete=off");
    }

    // Variable such that we reduce code duplication and can be sure we
    // should be firing notifications if and only if we can fill the form.
    var selectedLogin = null;

    if (usernameField && (usernameField.value || usernameField.disabled || usernameField.readOnly)) {
      // If username was specified in the field, it's disabled or it's readOnly, only fill in the
      // password if we find a matching login.
      var username = usernameField.value.toLowerCase();

      var matchingLogins = logins.filter(function(l) { return l.username.toLowerCase() == username });
      if (matchingLogins.length) {
        // If there are multiple, and one matches case, use it
        for (var i = 0; i < matchingLogins.length; i++) {
          var l = matchingLogins[i];
          if (l.username == usernameField.value) {
            selectedLogin = l;
          }
        }
        // Otherwise just use the first
        if (!selectedLogin) {
          selectedLogin = matchingLogins[0];
        }
      } else {
        didntFillReason = "existingUsername";
        log("Password not filled. None of the stored logins match the username already present.");
      }
    } else if (logins.length == 1) {
      selectedLogin = logins[0];
    } else {
      // We have multiple logins. Handle a special case here, for sites
      // which have a normal user+pass login *and* a password-only login
      // (eg, a PIN). Prefer the login that matches the type of the form
      // (user+pass or pass-only) when there's exactly one that matches.
      var matchingLogins;
      if (usernameField)
        matchingLogins = logins.filter(function(l) { return l.username });
      else
        matchingLogins = logins.filter(function(l) { return !l.username });

      // We really don't want to type on phones, so we always autofill with something...
      //if (matchingLogins.length == 1) {
        selectedLogin = matchingLogins[0];
      //} else {
        //didntFillReason = "multipleLogins";
        //log("Multiple logins for form, so not filling any.");
      //}
    }

    var didFillForm = false;
    if (selectedLogin && autofillForm && !isFormDisabled) {
      // Fill the form
      if (usernameField) {
        // Don't modify the username field if it's disabled or readOnly so we preserve its case.
        var disabledOrReadOnly = usernameField.disabled || usernameField.readOnly;

        var userNameDiffers = selectedLogin.username != usernameField.value;
        // Don't replace the username if it differs only in case, and the user triggered
        // this autocomplete. We assume that if it was user-triggered the entered text
        // is desired.
        var userEnteredDifferentCase = userTriggered && userNameDiffers && usernameField.value.toLowerCase() == selectedLogin.username.toLowerCase();

        if (!disabledOrReadOnly && !userEnteredDifferentCase && userNameDiffers) {
          // usernameField.setUserInput(selectedLogin.username);
          usernameField.value = selectedLogin.username
        }
      }
      if (passwordField.value != selectedLogin.password) {
        // passwordField.setUserInput(selectedLogin.password);
        passwordField.value = selectedLogin.password
      }
      didFillForm = true;
    } else if (selectedLogin && !autofillForm) {
      // For when autofillForm is false, but we still have the information
      // to fill a form, we notify observers.
      didntFillReason = "noAutofillForms";
      // Services.obs.notifyObservers(form, "passwordmgr-found-form", didntFillReason);
      log("autofillForms=false but form can be filled; notified observers");
    } else if (selectedLogin && isFormDisabled) {
      // For when autocomplete is off, but we still have the information
      // to fill a form, we notify observers.
      didntFillReason = "autocompleteOff";
      // Services.obs.notifyObservers(form, "passwordmgr-found-form", didntFillReason);
      log("autocomplete=off but form can be filled; notified observers");
    }

    // this._notifyFoundLogins(didntFillReason, usernameField, passwordField, foundLogins, selectedLogin);
    return [didFillForm, foundLogins];
  },
}

var LoginUtils = {
  /*
   * _getPasswordOrigin
   *
   * Get the parts of the URL we want for identification.
   */
  _getPasswordOrigin : function (uriString, allowJS) {
    // All of this logic is moved to swift (so that we don't need a uri parser here)
    return uriString;
  },

  _getActionOrigin : function(form) {
    var uriString = form.action;

    // A blank or missing action submits to where it came from.
    if (uriString == "")
      uriString = form.baseURI; // ala bug 297761

    return this._getPasswordOrigin(uriString, true);
  },
}

function onBlur(event) {
  LoginManagerContent.onUsernameInput(event)
}

var documentBody = document.body
var observer = new MutationObserver(function(mutations) {
  for(var idx = 0; idx < mutations.length; ++idx){
    findForms(mutations[idx].addedNodes);
  }
});

function findForms(nodes) {
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    if (node.nodeName === "FORM") {
      findLogins(node);
    } else if(node.hasChildNodes()) {
      findForms(node.childNodes);
    }

  }
  return false;
}

 observer.observe(documentBody, { attributes: false, childList: true, characterData: false, subtree: true });

function findLogins(form) {
  try {
      LoginManagerContent._asyncFindLogins(form, { })
        .then(function(res) {
          LoginManagerContent.loginsFound(res.form, res.loginsFound);
        }).then(null, log);
   } catch(ex) {
     // Eat errors to avoid leaking them to the page
     log(ex);
   }
 }

 window.addEventListener("load", function(event) {
   for (var i = 0; i < document.forms.length; i++) {
     findLogins(document.forms[i]);
   }
});

window.addEventListener("submit", function(event) {
  try {
    LoginManagerContent._onFormSubmit(event.target);
  } catch(ex) {
    // Eat errors to avoid leaking them to the page
    log(ex);
  }
});

if (!window.__firefox__) {
  Object.defineProperty(window, '__firefox__', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {}
  });
}

function LoginInjector() {
  this.inject = function(msg) {
    try {
      LoginManagerContent.receiveMessage(msg);
    } catch(ex) {
      // Eat errors to avoid leaking them to the page
      // alert(ex);
    }
  };
}

Object.defineProperty(window.__firefox__, 'logins', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new LoginInjector())
});

function map(array, callback) {

  var T, A, k;

  if (array == null) {
    throw new TypeError(' array is null or not defined');
  }

  var O = Object(array);
  var len = O.length >>> 0;
  if (typeof callback !== 'function') {
    throw new TypeError(callback + ' is not a function');
  }
  if (arguments.length > 1) {
    T = array;
  }
  A = new Array(len);
  k = 0;
  while (k < len) {

    var kValue, mappedValue;
    if (k in O) {
      kValue = O[k];
      mappedValue = callback.call(T, kValue, k, O);
      A[k] = mappedValue;
    }
    k++;
  }
  return A;
};

})()
