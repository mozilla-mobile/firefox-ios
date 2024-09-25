/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

import "Assets/CC_Script/Helpers.ios.mjs";
import { Logic } from "Assets/CC_Script/LoginManager.shared.sys.mjs";
import { PasswordGenerator } from "resource://gre/modules/PasswordGenerator.sys.mjs";

// Ensure this module only gets included once. This is
// required for user scripts injected into all frames.
window.__firefox__.includeOnce("LoginsHelper", function() {
  var gEnabled = true;
  var gStoreWhenAutocompleteOff = true;
  var gAutofillForms = true;
  var gDebug = false;

  var KEYCODE_ARROW_DOWN = 40;

  function log(pieces) {
    if (!gDebug)
      return;
    alert(pieces);
  }

  var LoginManagerContent = {
    _getRandomId: function() {
      return Math.round(Math.random() * (Number.MAX_VALUE - Number.MIN_VALUE) + Number.MIN_VALUE).toString()
    },

    // We need to keep track of the field that was focused by the user
    // before the accessory view is clicked so we can yield back the focus
    // when we autofill or cancel the bottomsheet. Webkit doesn't yield
    // focus back to the specific field but rather to the top view.
    activeField: null,

    _messages: [ "RemoteLogins:loginsFound" ],

    // Map from form login requests to information about that request.
    _requests: { },


    receiveMessage: function (msg) {
      switch (msg.name) {
        case "RemoteLogins:loginsFound": {
          console.log("ooooo ---- here ?? ", this.activeField.form, this.activeField)
          this.loginsFound(this.activeField.form, msg.logins);
          break;
        }
      }
    },

    loginsFound : function (form, loginsFound) {
      var autofillForm = gAutofillForms; // && !PrivateBrowsingUtils.isContentWindowPrivate(doc.defaultView);
      this._fillForm(form, autofillForm, true, false, false, loginsFound);
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

      if (!Logic.inputTypeIsCompatibleWithUsername(element)) {
        return false;
      }
      return true;
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

      var formSubmitUrl = LoginUtils._getActionOrigin(form);

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
        formSubmitUrl: formSubmitUrl
      });
    },

    // TODO(issam): Merge this with .setUserInput for form autofill and use that instead.
    fillValue(field, value) {
      const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
      nativeInputValueSetter.call(field, value);

      ["input", "change", "blur"].forEach(eventName => {
        field.dispatchEvent(new Event(eventName, { bubbles: true }));
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
          formSubmitUrl: login.formSubmitUrl,
          httpRealm: login.httpRealm,
          username: login.username,
          password: login.password,
          usernameField: login.usernameField,
          passwordField: login.passwordField
        }
      }
      foundLogins = foundLogins.map(createLogin);
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

      // We only receive one login in the array, which the login the user selected
      const selectedLogin = logins?.[0];

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
            this.fillValue(usernameField, selectedLogin.username);
            dispatchKeyboardEvent(usernameField, "keydown", KEYCODE_ARROW_DOWN);
            dispatchKeyboardEvent(usernameField, "keyup", KEYCODE_ARROW_DOWN);
            // When the keyboard steals focus and gives it back,
            // focusin is not triggered on the input it yields focus back to.
            usernameField.focus();
          }
        }
        if (passwordField.value != selectedLogin.password) {
          this.fillValue(passwordField, selectedLogin.password);
          dispatchKeyboardEvent(passwordField, "keydown", KEYCODE_ARROW_DOWN);
          dispatchKeyboardEvent(passwordField, "keyup", KEYCODE_ARROW_DOWN);
          // When the keyboard steals focus and gives it back,
          // focusin is not triggered on the input it yields focus back to.
          passwordField.focus();
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

  const generatePassword = (rules) => {
    let mapOfRules = null;

    // If the rules are not provided, we will use the default rules
    // The rules are provided by swift depending on the domain
    if(rules) {
      const domainRules = PasswordRulesParser.parsePasswordRules(
        rules
      );
      mapOfRules = transformRulesToMap(domainRules);
    }

    const generatedPassword = PasswordGenerator.generatePassword({
      inputMaxLength: LoginManagerContent.activeField.maxLength,
      rules: mapOfRules ?? undefined,
    });

    return generatedPassword;
  };

  const fillGeneratedPassword = (password) => {
    LoginManagerContent.yieldFocusBackToField();
    LoginManagerContent.activeField.setUserInput(password);
    Logic.fillConfirmFieldWithGeneratedPassword(
      LoginManagerContent.activeField
    );
  };

  function yieldFocusBackToField() {
    LoginManagerContent.activeField?.blur();
    LoginManagerContent.activeField?.focus();
  }

  // define the field types for focus events
  const FocusFieldType = {
    username: "username",
    password: "password"
  };

  function onFocusIn(event) {
    const form = event.target?.form;
    if (!form) {
      return;
    }

    const [username, password] = LoginManagerContent._getFormFields(form, false);
    const field = event.target;
    const formHasNewPassword =
      password && Logic.isProbablyANewPasswordField(password);
    const isPasswordField = field === password;

    LoginManagerContent.activeField = field;
    if (formHasNewPassword && isPasswordField) {
      webkit.messageHandlers.loginsManagerMessageHandler.postMessage({
        type: "generatePassword",
      });
    } else if (!formHasNewPassword && password) {
      webkit.messageHandlers.loginsManagerMessageHandler.postMessage({
        type: "fieldType",
        fieldType:
          field === username ? FocusFieldType.username : FocusFieldType.password,
      });
    }
  }

  document.addEventListener("focusin", (ev) => onFocusIn(ev), {capture: true});
    
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


  window.addEventListener("submit", function(event) {
    try {
      LoginManagerContent._onFormSubmit(event.target);
    } catch(ex) {
      // Eat errors to avoid leaking them to the page
      log(ex);
    }
  });

  function LoginInjector() {
    this.inject = function(msg) {
      try {
        LoginManagerContent.receiveMessage(msg);
      } catch(ex) {
        // Eat errors to avoid leaking them to the page
        // alert(ex);
      }
    };
    this.yieldFocusBackToField = yieldFocusBackToField;
    this.generatePassword = generatePassword;
    this.fillGeneratedPassword = fillGeneratedPassword;
  }

  Object.defineProperty(window.__firefox__, "logins", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: Object.freeze(new LoginInjector())
  });

  function dispatchKeyboardEvent(element, eventName, keyCode) {
    var event = document.createEvent("KeyboardEvent");
    event.initKeyboardEvent(eventName, true, true, window, 0, 0, 0, 0, 0, keyCode);
    element.dispatchEvent(event);
  }
});
