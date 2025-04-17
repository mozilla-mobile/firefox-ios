import { Logic } from "resource://gre/modules/LoginManager.shared.sys.mjs";

const lazy = {};

ChromeUtils.defineESModuleGetters(lazy, {
  FormLikeFactory: "resource://gre/modules/FormLikeFactory.sys.mjs",
  LoginFormFactory: "resource://gre/modules/shared/LoginFormFactory.sys.mjs",
  LoginHelper: "resource://gre/modules/LoginHelper.sys.mjs",
  LoginRecipesContent: "resource://gre/modules/LoginRecipes.sys.mjs",
});

export const AUTOFILL_STATE = "autofill";

// Events on pages with Shadow DOM could return the shadow host element
// (aEvent.target) rather than the actual username or password field
// (aEvent.composedTarget).
// Only allow input elements (can be extended later) to avoid false negatives.
export class WeakFieldSet extends WeakSet {
  add(value) {
    if (!HTMLInputElement.isInstance(value)) {
      throw new Error("Non-field type added to a WeakFieldSet");
    }
    super.add(value);
  }
}

/**
 * Logic of Capture and Filling.
 *
 * This class will be shared with Firefox iOS and should have no references to
 * Gecko internals. See Bug 1774208.
 */
export class LoginFormState {
  /**
   * Keeps track of filled fields and values.
   */
  fillsByRootElement = new WeakMap();
  /**
   * Keeps track of fields we've filled with generated passwords
   */
  generatedPasswordFields = new WeakFieldSet();
  /**
   * Keeps track of logins that were last submitted.
   */
  lastSubmittedValuesByRootElement = new WeakMap();
  fieldModificationsByRootElement = new WeakMap();
  /**
   * Anything entered into an <input> that we think might be a username
   */
  possibleUsernames = new Set();
  /**
   * Anything entered into an <input> that we think might be a password
   */
  possiblePasswords = new Set();

  /**
   * Keeps track of the formLike of nodes (form or formless password field)
   * that we are watching when they are removed from DOM.
   */
  formLikeByObservedNode = new WeakMap();

  /**
   * Keeps track of all formless password fields that have been
   * updated by the user.
   */
  formlessModifiedPasswordFields = new WeakFieldSet();

  /**
   * Caches the results of the username heuristics
   */
  #cachedIsInferredUsernameField = new WeakMap();
  #cachedIsInferredEmailField = new WeakMap();
  #cachedIsInferredLoginForm = new WeakMap();

  /**
   * Records the mock username field when its associated form is submitted.
   */
  mockUsernameOnlyField = null;

  /**
   * Records the number of possible username event received for this document.
   */
  numFormHasPossibleUsernameEvent = 0;

  captureLoginTimeStamp = 0;

  // Scenarios detected on this page
  #scenariosByRoot = new WeakMap();

  constructor(logger = () => {}, observer = () => {}) {
    LoginFormState.logger = logger;
    this.observer = observer;
  }

  getScenario(inputElement) {
    const formLikeRoot = lazy.FormLikeFactory.findRootForField(inputElement);
    return this.#scenariosByRoot.get(formLikeRoot);
  }

  setScenario(formLikeRoot, scenario) {
    this.#scenariosByRoot.set(formLikeRoot, scenario);
  }

  storeUserInput(field) {
    if (field.value && lazy.LoginHelper.captureInputChanges) {
      if (Logic.isPasswordFieldType(field)) {
        this.possiblePasswords.add(field.value);
      } else if (Logic.isUsernameFieldType(field)) {
        this.possibleUsernames.add(field.value);
      }
    }
  }

  /**
   * Returns true if the input field is considered an email field by
   * 'LoginHelper.isInferredEmailField'.
   *
   * @param {Element} element the field to check.
   * @returns {boolean} True if the element is likely an email field
   */
  isProbablyAnEmailField(inputElement) {
    if (!inputElement) {
      return false;
    }

    let result = this.#cachedIsInferredEmailField.get(inputElement);
    if (result === undefined) {
      result = Logic.isInferredEmailField(inputElement);
      this.#cachedIsInferredEmailField.set(inputElement, result);
    }

    return result;
  }

  /**
   * Returns true if the input field is considered a username field by
   * 'LoginHelper.isInferredUsernameField'. The main purpose of this method
   * is to cache the result because _getFormFields has many call sites and we
   * want to avoid applying the heuristic every time.
   *
   * @param {Element} element the field to check.
   * @returns {boolean} True if the element is likely a username field
   */
  isProbablyAUsernameField(inputElement) {
    let result = this.#cachedIsInferredUsernameField.get(inputElement);
    if (result === undefined) {
      result = Logic.isInferredUsernameField(inputElement);
      this.#cachedIsInferredUsernameField.set(inputElement, result);
    }

    return result;
  }

  /**
   * Returns true if the form is considered a username login form if
   * 1. The input element looks like a username field or the form looks
   *    like a login form
   * 2. The input field doesn't match keywords that indicate the username
   *    is not used for login (ex, search) or the login form is not use
   *    a username to sign-in (ex, authentication code)
   *
   * @param {Element} element the form to check.
   * @returns {boolean} True if the element is likely a login form
   */
  #isProbablyAUsernameLoginForm(formElement, inputElement) {
    let result = this.#cachedIsInferredLoginForm.get(formElement);
    if (result === undefined) {
      // We should revisit these rules after we collect more positive or negative
      // cases for username-only forms. Right now, if-else-based rules are good
      // enough to cover the sites we know, but if we find out defining "weight" for each
      // rule is necessary to improve the heuristic, we should consider switching
      // this with Fathom.

      result = false;
      // Check whether the input field looks like a username field or the
      // form looks like a sign-in or sign-up form.
      if (
        this.isProbablyAUsernameField(inputElement) ||
        Logic.isInferredLoginForm(formElement)
      ) {
        // This is where we collect hints that indicate this is not a username
        // login form.
        if (!Logic.isInferredNonUsernameField(inputElement)) {
          result = true;
        }
      }
      this.#cachedIsInferredLoginForm.set(formElement, result);
    }

    return result;
  }

  /**
   * Given a field, determine whether that field was last filled as a username
   * field AND whether the username is still filled in with the username AND
   * whether the associated password field has the matching password.
   *
   * @note This could possibly be unified with getFieldContext but they have
   * slightly different use cases. getFieldContext looks up recipes whereas this
   * method doesn't need to since it's only returning a boolean based upon the
   * recipes used for the last fill (in _fillForm).
   *
   * @param {HTMLInputElement} aUsernameField element contained in a LoginForm
   *                                          cached in LoginFormFactory.
   * @returns {Boolean} whether the username and password fields still have the
   *                    last-filled values, if previously filled.
   */
  #isLoginAlreadyFilled(aUsernameField) {
    let formLikeRoot = lazy.FormLikeFactory.findRootForField(aUsernameField);
    // Look for the existing LoginForm.
    let existingLoginForm =
      lazy.LoginFormFactory.getForRootElement(formLikeRoot);
    if (!existingLoginForm) {
      throw new Error(
        "#isLoginAlreadyFilled called with a username field with " +
          "no rootElement LoginForm"
      );
    }

    let { login: filledLogin } =
      this.fillsByRootElement.get(formLikeRoot) || {};
    if (!filledLogin) {
      return false;
    }

    // Unpack the weak references.
    let autoFilledUsernameField = filledLogin.usernameField?.get();
    let autoFilledPasswordField = filledLogin.passwordField?.get();

    // Check username and password values match what was filled.
    if (
      !autoFilledUsernameField ||
      autoFilledUsernameField != aUsernameField ||
      autoFilledUsernameField.value != filledLogin.username ||
      (autoFilledPasswordField &&
        autoFilledPasswordField.value != filledLogin.password)
    ) {
      return false;
    }

    return true;
  }

  _togglePasswordFieldMasking(passwordField, unmask) {
    let { editor } = passwordField;

    if (passwordField.type != "password") {
      // The type may have been changed by the website.
      LoginFormState.logger("Field isn't type=password.");
      return;
    }

    if (!unmask && !editor) {
      // It hasn't been created yet but the default is to be masked anyways.
      return;
    }

    if (unmask) {
      editor.unmask(0);
      return;
    }

    if (editor.autoMaskingEnabled) {
      return;
    }
    editor.mask();
  }

  /**
   * Track a form field as has having been filled with a generated password. This adds explicit
   * focus & blur handling to unmask & mask the value, and enables special handling of edits to
   * generated password values (see the observer's input event handler.)
   *
   * @param {HTMLInputElement} passwordField
   */
  _treatAsGeneratedPasswordField(passwordField) {
    this.generatedPasswordFields.add(passwordField);

    // blur/focus: listen for focus changes to we can mask/unmask generated passwords
    for (let eventType of ["blur", "focus"]) {
      passwordField.addEventListener(eventType, this.observer, {
        capture: true,
        mozSystemGroup: true,
      });
    }
    if (passwordField.ownerDocument.activeElement == passwordField) {
      // Unmask the password field
      this._togglePasswordFieldMasking(passwordField, true);
    }
  }

  _formHasModifiedFields(form) {
    const doc = form.rootElement.ownerDocument;
    let userHasInteracted;
    const testOnlyUserHasInteracted =
      lazy.LoginHelper.testOnlyUserHasInteractedWithDocument;
    if (Cu.isInAutomation && testOnlyUserHasInteracted !== null) {
      userHasInteracted = testOnlyUserHasInteracted;
    } else {
      userHasInteracted =
        !lazy.LoginHelper.userInputRequiredToCapture ||
        this.captureLoginTimeStamp != doc.lastUserGestureTimeStamp;
    }

    LoginFormState.logger(
      `_formHasModifiedFields: userHasInteracted: ${userHasInteracted}.`
    );

    // Skip if user didn't interact with the page since last call or ever
    if (!userHasInteracted) {
      return false;
    }

    // check for user inputs to the form fields
    let fieldsModified = this.fieldModificationsByRootElement.get(
      form.rootElement
    );
    // also consider a form modified if there's a difference between fields' .value and .defaultValue
    if (!fieldsModified) {
      fieldsModified = Array.from(form.elements).some(
        field =>
          field.defaultValue !== undefined && field.value !== field.defaultValue
      );
    }
    return fieldsModified;
  }

  _stopTreatingAsGeneratedPasswordField(passwordField) {
    this.generatedPasswordFields.delete(passwordField);

    // Remove all the event listeners added in _passwordEditedOrGenerated
    for (let eventType of ["blur", "focus"]) {
      passwordField.removeEventListener(eventType, this.observer, {
        capture: true,
        mozSystemGroup: true,
      });
    }

    // Mask the password field
    this._togglePasswordFieldMasking(passwordField, false);
  }

  onFocus(field, focusedField, onUsernameFocus) {
    if (field.hasBeenTypePassword && this.generatedPasswordFields.has(field)) {
      // Used to unmask fields with filled generated passwords when focused.
      this._togglePasswordFieldMasking(field, true);
      return;
    }

    if (this.#isLoginAlreadyFilled(focusedField)) {
      LoginFormState.logger("Login already filled.");
      return;
    }

    // Only used for username fields.
    onUsernameFocus(focusedField);
  }

  /** Remove login field highlight when its value is cleared or overwritten.
   */
  static #removeFillFieldHighlight(event) {
    event.target.autofillState = "";
  }

  /**
   * Highlight login fields on autocomplete or autofill on page load.
   * @param {Node} element that needs highlighting.
   */
  static _highlightFilledField(element) {
    element.autofillState = AUTOFILL_STATE;
    // Remove highlighting when the field is changed.
    element.addEventListener(
      "input",
      LoginFormState.#removeFillFieldHighlight,
      {
        mozSystemGroup: true,
        once: true,
      }
    );
  }

  /**
   * Returns the username field of the passed form if the form is a
   * username-only form.
   * A form is considered a username-only form only if it meets all the
   * following conditions:
   * 1. Does not have any password field,
   * 2. Only contains one input field whose type is username compatible.
   * 3. The username compatible input field looks like a username field
   *    or the form itself looks like a sign-in or sign-up form.
   * Additionally, if an input is formless and its autocomplete attribute is
   * set to 'username' (this check is done in the DOM to avoid firing excessive events),
   * we construct a FormLike object using this input and perform the same logic
   * described above to determine if the new FormLike object is username-only.
   *
   * @param {FormLike} form
   *                  the form to check.
   * @param {Object}  recipe=null
   *                  A relevant field override recipe to use.
   * @returns {Element} The username field or null (if the form is not a
   *                    username-only form).
   */
  getUsernameFieldFromUsernameOnlyForm(form, recipe = null) {
    let candidate = null;
    for (let element of form.elements) {
      // We are looking for a username-only form, so if there is a password
      // field in the form, this is NOT a username-only form.
      if (element.hasBeenTypePassword) {
        return null;
      }

      // Ignore input fields whose type are not username compatiable, ex, hidden.
      if (!Logic.isUsernameFieldType(element)) {
        continue;
      }

      if (
        recipe?.notUsernameSelector &&
        element.matches(recipe.notUsernameSelector)
      ) {
        continue;
      }

      // If there are more than two input fields whose type is username
      // compatiable, this is NOT a username-only form.
      if (candidate) {
        return null;
      }
      candidate = element;
    }
    if (
      candidate &&
      this.#isProbablyAUsernameLoginForm(form.rootElement, candidate)
    ) {
      return candidate;
    }

    return null;
  }

  /**
   * @param {LoginForm} form - the LoginForm to look for password fields in.
   * @param {Object} options
   * @param {bool} [options.skipEmptyFields=false] - Whether to ignore password fields with no value.
   *                                                 Used at capture time since saving empty values isn't
   *                                                 useful.
   * @param {Object} [options.fieldOverrideRecipe=null] - A relevant field override recipe to use.
   * @return {Array|null} Array of password field elements for the specified form.
   *                      If no pw fields are found, or if more than 5 are found, then null
   *                      is returned.
   */
  static _getPasswordFields(
    form,
    {
      fieldOverrideRecipe = null,
      minPasswordLength = 0,
      ignoreConnect = false,
    } = {}
  ) {
    // Locate the password fields in the form.
    let pwFields = [];
    for (let i = 0; i < form.elements.length; i++) {
      let element = form.elements[i];
      if (
        !HTMLInputElement.isInstance(element) ||
        !element.hasBeenTypePassword ||
        (!element.isConnected && !ignoreConnect)
      ) {
        continue;
      }

      // Exclude ones matching a `notPasswordSelector`, if specified.
      if (
        fieldOverrideRecipe?.notPasswordSelector &&
        element.matches(fieldOverrideRecipe.notPasswordSelector)
      ) {
        LoginFormState.logger(
          `Skipping password field with id: ${element.id}, name: ${element.name} due to recipe ${fieldOverrideRecipe}.`
        );
        continue;
      }

      // XXX: Bug 780449 tracks our handling of emoji and multi-code-point characters in
      // password fields. To avoid surprises, we should be consistent with the visual
      // representation of the masked password
      if (
        minPasswordLength &&
        element.value.trim().length < minPasswordLength
      ) {
        LoginFormState.logger(
          `Skipping password field with id: ${element.id}, name: ${element.name} as value is too short.`
        );
        continue; // Ignore empty or too-short passwords fields
      }

      pwFields[pwFields.length] = {
        index: i,
        element,
      };
    }

    // If too few or too many fields, bail out.
    if (!pwFields.length) {
      LoginFormState.logger("Form ignored, no password fields.");
      return null;
    }

    if (pwFields.length > 5) {
      LoginFormState.logger(
        `Form ignored, too many password fields:  ${pwFields.length}.`
      );
      return null;
    }

    return pwFields;
  }

  /**
   * Stores passed arguments, and returns whether or not they match the args given the last time
   * this method was called with the same [formLikeRoot]. This is used to avoid sending duplicate
   * messages to the parent.
   *
   * @param {Element} formLikeRoot
   * @param {string} usernameValue
   * @param {string} passwordValue
   * @param {boolean?} [dismissed=false]
   * @param {boolean?} [triggeredByFillingGenerated=false] whether or not this call was triggered by a generated
   *        password being filled into a form-like element.
   *
   * @returns {boolean} true if args match the most recently passed values
   */
  compareAndUpdatePreviouslySentValues(
    formLikeRoot,
    usernameValue,
    passwordValue,
    dismissed = false,
    triggeredByFillingGenerated = false
  ) {
    const lastSentValues =
      this.lastSubmittedValuesByRootElement.get(formLikeRoot);
    if (lastSentValues) {
      if (dismissed && !lastSentValues.dismissed) {
        // preserve previous dismissed value if it was false (i.e. shown/open)
        dismissed = false;
      }
      if (
        lastSentValues.username == usernameValue &&
        lastSentValues.password == passwordValue &&
        lastSentValues.dismissed == dismissed &&
        lastSentValues.triggeredByFillingGenerated ==
          triggeredByFillingGenerated
      ) {
        LoginFormState.logger(
          "compareAndUpdatePreviouslySentValues: values are equivalent, returning true."
        );
        return true;
      }
    }

    // Save the last submitted values so we don't prompt twice for the same values using
    // different capture methods e.g. a form submit event and upon navigation.
    this.lastSubmittedValuesByRootElement.set(formLikeRoot, {
      username: usernameValue,
      password: passwordValue,
      dismissed,
      triggeredByFillingGenerated,
    });
    LoginFormState.logger(
      "compareAndUpdatePreviouslySentValues: values not equivalent, returning false."
    );
    return false;
  }

  fillConfirmFieldWithGeneratedPassword(passwordField) {
    const form = lazy.LoginFormFactory.createFromField(passwordField);
    const previousGeneratedPasswordField = form.elements.some(
      inp => inp !== passwordField && this.generatedPasswordFields.has(inp)
    );
    if (previousGeneratedPasswordField) {
      LoginFormState.logger(
        "Previously-filled generated password input found."
      );
      return;
    }

    const confirmPasswordInput = Logic.findConfirmationField(
      passwordField,
      lazy.LoginFormFactory
    );

    if (confirmPasswordInput && !confirmPasswordInput.value) {
      this._treatAsGeneratedPasswordField(confirmPasswordInput);
      confirmPasswordInput.setUserInput(passwordField.value);
      LoginFormState._highlightFilledField(confirmPasswordInput);
    }
  }

  /**
   * Returns the username and password fields found in the form.
   * Can handle complex forms by trying to figure out what the
   * relevant fields are.
   *
   * @param {LoginForm} form
   * @param {bool} isSubmission
   * @param {Set} recipes
   * @param {Object} options
   * @param {bool} [options.ignoreConnect] - Whether to ignore checking isConnected
   *                                         of the element.
   * @return {Object} {usernameField, newPasswordField, oldPasswordField, confirmPasswordField}
   *
   * usernameField may be null.
   * newPasswordField may be null. If null, this is a username-only form.
   * oldPasswordField may be null. If null, newPasswordField is just
   * "theLoginField". If not null, the form is apparently a
   * change-password field, with oldPasswordField containing the password
   * that is being changed.
   *
   * Note that even though we can create a LoginForm from a text field,
   * this method will only return a non-null usernameField if the
   * LoginForm has a password field.
   */
  _getFormFields(form, isSubmission, recipes, { ignoreConnect = false } = {}) {
    let usernameField = null;
    let newPasswordField = null;
    let oldPasswordField = null;
    let confirmPasswordField = null;
    let emptyResult = {
      usernameField: null,
      newPasswordField: null,
      oldPasswordField: null,
      confirmPasswordField: null,
    };

    let pwFields = null;
    let fieldOverrideRecipe = lazy.LoginRecipesContent.getFieldOverrides(
      recipes,
      form
    );
    if (fieldOverrideRecipe) {
      LoginFormState.logger("fieldOverrideRecipe found ", fieldOverrideRecipe);
      let pwOverrideField = lazy.LoginRecipesContent.queryLoginField(
        form,
        fieldOverrideRecipe.passwordSelector
      );
      if (pwOverrideField) {
        LoginFormState.logger("pwOverrideField found ", pwOverrideField);
        // The field from the password override may be in a different LoginForm.
        let formLike = lazy.LoginFormFactory.createFromField(pwOverrideField);
        pwFields = [
          {
            index: [...formLike.elements].indexOf(pwOverrideField),
            element: pwOverrideField,
          },
        ];
      }

      let usernameOverrideField = lazy.LoginRecipesContent.queryLoginField(
        form,
        fieldOverrideRecipe.usernameSelector
      );
      if (usernameOverrideField) {
        usernameField = usernameOverrideField;
      }
    }

    if (!pwFields) {
      // Locate the password field(s) in the form. Up to 5 supported.
      // If there's no password field, there's nothing for us to do.
      const minSubmitPasswordLength = 2;
      pwFields = LoginFormState._getPasswordFields(form, {
        fieldOverrideRecipe,
        minPasswordLength: isSubmission ? minSubmitPasswordLength : 0,
        ignoreConnect,
      });
    }

    // Check whether this is a username-only form when the form doesn't have
    // a password field. Note that recipes are not supported in username-only
    // forms currently (Bug 1708455).
    if (!pwFields) {
      if (!lazy.LoginHelper.usernameOnlyFormEnabled) {
        return emptyResult;
      }

      usernameField = this.getUsernameFieldFromUsernameOnlyForm(
        form,
        fieldOverrideRecipe
      );

      if (usernameField) {
        LoginFormState.logger(
          `Found username field with name: ${usernameField.name}.`
        );
      }

      return {
        ...emptyResult,
        usernameField,
      };
    }

    if (!usernameField) {
      // Searching backwards from the first password field until we find a field
      // that looks like a "username" field. If no "username" field is found,
      // consider an email-like field a username field, if any.
      // If neither a username-like or an email-like field exists, assume the
      // first text field before the password field is the username.
      // We might not find a username field if the user is already logged in to the site.
      //
      // Note: We only search fields precede the first password field because we
      // don't see sites putting a username field after a password field. We can
      // extend searching to all fields in the form if this turns out not to be the case.

      for (let i = pwFields[0].index - 1; i >= 0; i--) {
        let element = form.elements[i];
        if (!Logic.isUsernameFieldType(element, { ignoreConnect })) {
          continue;
        }

        if (
          fieldOverrideRecipe?.notUsernameSelector &&
          element.matches(fieldOverrideRecipe.notUsernameSelector)
        ) {
          continue;
        }

        // Assume the first text field is the username by default.
        // It will be replaced if we find a likely username field afterward.
        if (!usernameField) {
          usernameField = element;
        }

        if (this.isProbablyAUsernameField(element)) {
          // An username field is found, we are done.
          usernameField = element;
          break;
        } else if (this.isProbablyAnEmailField(element)) {
          // An email field is found, consider it a username field but continue
          // to search for an "username" field.
          // In current implementation, if another email field is found during
          // the process, we will use the new one.
          usernameField = element;
        }
      }
    }

    if (!usernameField) {
      LoginFormState.logger("No username field found.");
    } else {
      LoginFormState.logger(
        `Found username field with name: ${usernameField.name}.`
      );
    }

    let pwGeneratedFields = pwFields.filter(pwField =>
      this.generatedPasswordFields.has(pwField.element)
    );
    if (pwGeneratedFields.length) {
      // we have at least the newPasswordField
      [newPasswordField, confirmPasswordField] = pwGeneratedFields.map(
        pwField => pwField.element
      );
      // if the user filled a field with a generated password,
      // a field immediately previous to that is most likely the old password field
      let idx = pwFields.findIndex(
        pwField => pwField.element === newPasswordField
      );
      if (idx > 0) {
        oldPasswordField = pwFields[idx - 1].element;
      }
      return {
        ...emptyResult,
        usernameField,
        newPasswordField,
        oldPasswordField: oldPasswordField || null,
        confirmPasswordField: confirmPasswordField || null,
      };
    }

    // If we're not submitting a form (it's a page load), there are no
    // password field values for us to use for identifying fields. So,
    // just assume the first password field is the one to be filled in.
    if (!isSubmission || pwFields.length == 1) {
      let passwordField = pwFields[0].element;
      LoginFormState.logger(
        `Found Password field with name: ${passwordField.name}.`
      );
      return {
        ...emptyResult,
        usernameField,
        newPasswordField: passwordField,
        oldPasswordField: null,
      };
    }

    // We're looking for both new and old password field
    // Try to figure out what is in the form based on the password values.
    let pw1 = pwFields[0].element.value;
    let pw2 = pwFields[1] ? pwFields[1].element.value : null;
    let pw3 = pwFields[2] ? pwFields[2].element.value : null;

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
      } else if (pw1 == pw3) {
        // A bit odd, but could make sense with the right page layout.
        newPasswordField = pwFields[0].element;
        oldPasswordField = pwFields[1].element;
      } else {
        // We can't tell which of the 3 passwords should be saved.
        LoginFormState.logger(`Form ignored -- all 3 pw fields differ.`);
        return emptyResult;
      }
    } else if (pw1 == pw2) {
      // pwFields.length == 2
      // Treat as if 1 pw field
      newPasswordField = pwFields[0].element;
      oldPasswordField = null;
    } else {
      // Just assume that the 2nd password is the new password
      oldPasswordField = pwFields[0].element;
      newPasswordField = pwFields[1].element;
    }
    LoginFormState.logger(
      `New Password field id: ${newPasswordField.id}, name: ${newPasswordField.name}.`
    );

    LoginFormState.logger(
      oldPasswordField
        ? `Old Password field id: ${oldPasswordField.id}, name: ${oldPasswordField.name}.`
        : "No Old password field."
    );
    return {
      ...emptyResult,
      usernameField,
      newPasswordField,
      oldPasswordField,
    };
  }

  /**
   * Returns the username and password fields found in the form by input
   * element into form.
   *
   * @param {HTMLInputElement} aField
   *                           A form field
   * @return {Array} [usernameField, newPasswordField, oldPasswordField]
   *
   * Details of these values are the same as _getFormFields.
   */
  getUserNameAndPasswordFields(aField) {
    const noResult = [null, null, null];
    if (!HTMLInputElement.isInstance(aField)) {
      throw new Error("getUserNameAndPasswordFields: input element required");
    }

    if (aField.nodePrincipal.isNullPrincipal || !aField.isConnected) {
      return noResult;
    }

    // If the element is not a login form field, return all null.
    if (!aField.hasBeenTypePassword && !Logic.isUsernameFieldType(aField)) {
      return noResult;
    }

    const form = lazy.LoginFormFactory.createFromField(aField);
    const doc = aField.ownerDocument;
    const formOrigin = Logic.getLoginOrigin(doc.documentURI);
    const recipes = lazy.LoginRecipesContent.getRecipes(
      formOrigin,
      doc.defaultView
    );
    const { usernameField, newPasswordField, oldPasswordField } =
      this._getFormFields(form, false, recipes);

    return [usernameField, newPasswordField, oldPasswordField];
  }

  /**
   * Verify if a field is a valid login form field and
   * returns some information about it's LoginForm.
   *
   * @param {Element} aField
   *                  A form field we want to verify.
   *
   * @returns {Object} an object with information about the
   *                   LoginForm username and password field
   *                   or null if the passed field is invalid.
   */
  getFieldContext(aField) {
    // If the element is not a proper form field, return null.
    if (
      !HTMLInputElement.isInstance(aField) ||
      (!aField.hasBeenTypePassword && !Logic.isUsernameFieldType(aField)) ||
      aField.nodePrincipal.isNullPrincipal ||
      aField.nodePrincipal.schemeIs("about") ||
      !aField.ownerDocument
    ) {
      return null;
    }
    let { hasBeenTypePassword } = aField;

    // This array provides labels that correspond to the return values from
    // `getUserNameAndPasswordFields` so we can know which one aField is.
    const LOGIN_FIELD_ORDER = ["username", "new-password", "current-password"];
    let usernameAndPasswordFields = this.getUserNameAndPasswordFields(aField);
    let fieldNameHint;
    let indexOfFieldInUsernameAndPasswordFields =
      usernameAndPasswordFields.indexOf(aField);
    if (indexOfFieldInUsernameAndPasswordFields == -1) {
      // For fields in the form that are neither username nor password,
      // set fieldNameHint to "other". Right now, in contextmenu, we treat both
      // "username" and "other" field as username fields.
      fieldNameHint = hasBeenTypePassword ? "current-password" : "other";
    } else {
      fieldNameHint =
        LOGIN_FIELD_ORDER[indexOfFieldInUsernameAndPasswordFields];
    }
    let [, newPasswordField] = usernameAndPasswordFields;

    return {
      activeField: {
        disabled: aField.disabled || aField.readOnly,
        fieldNameHint,
      },
      // `passwordField` may be the same as `activeField`.
      passwordField: {
        found: !!newPasswordField,
        disabled:
          newPasswordField &&
          (newPasswordField.disabled || newPasswordField.readOnly),
      },
    };
  }
}
