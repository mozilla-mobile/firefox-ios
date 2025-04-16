/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * A factory to generate FormLike objects that represent a set of related fields
 * which aren't necessarily marked up with a <form> element. FormLike's emulate
 * the properties of an HTMLFormElement which are relevant to form tasks.
 */
export let FormLikeFactory = {
  _propsFromForm: ["action", "autocomplete", "ownerDocument"],

  /**
   * Create a FormLike object from a <form>.
   *
   * @param {HTMLFormElement} aForm
   * @return {FormLike}
   * @throws Error if aForm isn't an HTMLFormElement
   */
  createFromForm(aForm) {
    if (!HTMLFormElement.isInstance(aForm)) {
      throw new Error("createFromForm: aForm must be a HTMLFormElement");
    }

    let formLike = {
      elements: this.gatherFormElements(aForm),
      rootElement: aForm,
    };

    for (let prop of this._propsFromForm) {
      formLike[prop] = aForm[prop];
    }

    this._addToJSONProperty(formLike);

    return formLike;
  },

  gatherFormElements(aForm) {
    // If there is no nested <form> element, just return the form's elements.
    if (!aForm.querySelector("form")) {
      return [...aForm.elements];
    }

    // Get all of the child input and select elements from the form. Nested
    // forms are normally removed during markup parsing, but could be created
    // if the document is modified later. Consider all of the elements that
    // are descendants of the form or within the form's .elements list to be
    // part of the form, except those with a form attribute set to a different
    // form. These are all added in document order.
    let childElements = [...aForm.querySelectorAll("input, select")];
    childElements = childElements.filter(
      e => !e.getAttribute("form") || e.form == aForm
    );

    // Add the element into the child elements list in document order.
    let index = 0;
    for (const formElement of aForm.elements) {
      if (!childElements.includes(formElement)) {
        // Insert elements that appear before the <form> at the beginning and
        // other elements at the end.
        let position = aForm.compareDocumentPosition(formElement);
        if (position & Node.DOCUMENT_POSITION_PRECEDING) {
          childElements.splice(index++, 0, formElement);
          continue;
        } else {
          childElements.push(formElement);
        }
      }
    }

    return childElements;
  },

  /**
   * Create a FormLike object from an element that is the root of the document
   *
   * Currently all <input> not in a <form> are one LoginForm but this
   * shouldn't be relied upon as the heuristics may change to detect multiple
   * "forms" (e.g. registration and login) on one page with a <form>.
   *
   * @param {HTMLElement} aDocumentRoot
   * @param {Object} aOptions
   * @param {boolean} [aOptions.ignoreForm = false]
   *        True to always use owner document as the `form`
   * @return {formLike}
   * @throws Error if aDocumentRoot is null
   */
  createFromDocumentRoot(aDocumentRoot, aOptions = {}) {
    if (!aDocumentRoot) {
      throw new Error("createFromDocumentRoot: aDocumentRoot is null");
    }

    let formLike = {
      action: aDocumentRoot.baseURI,
      autocomplete: "on",
      ownerDocument: aDocumentRoot.ownerDocument,
      rootElement: aDocumentRoot,
    };

    // FormLikes can be created when fields are inserted into the DOM. When
    // many, many fields are inserted one after the other, we create many
    // FormLikes, and computing the elements list becomes more and more
    // expensive. Making the elements list lazy means that it'll only
    // be computed when it's eventually needed (if ever).
    ChromeUtils.defineLazyGetter(formLike, "elements", function () {
      let elements = [];
      for (let el of aDocumentRoot.querySelectorAll(
        "input, select, textarea"
      )) {
        // Exclude elements inside the rootElement that are already in a <form> as
        // they will be handled by their own FormLike.
        if (!el.form || aOptions.ignoreForm) {
          elements.push(el);
        }
      }

      return elements;
    });

    this._addToJSONProperty(formLike);
    return formLike;
  },

  /**
   * Create a FormLike object from an <input>/<select> in a document.
   *
   * If the field is in a <form>, construct the FormLike from the form.
   * Otherwise, create a FormLike with a rootElement (wrapper) according to
   * heuristics. Currently all <input>/<select> not in a <form> are one FormLike
   * but this shouldn't be relied upon as the heuristics may change to detect
   * multiple "forms" (e.g. registration and login) on one page with a <form>.
   *
   * Note that two FormLikes created from the same field won't return the same FormLike object.
   * Use the `rootElement` property on the FormLike as a key instead.
   *
   * @param {HTMLInputElement|HTMLSelectElement} aField
   *        an <input>, <select> or <iframe> field in a document
   * @param {Object} aOptions
   * @param {boolean} [aOptions.ignoreForm = false]
   *        True to always use owner document as the `form`
   * @return {FormLike}
   * @throws Error if aField isn't a password or username field in a document
   */
  createFromField(aField, aOptions = {}) {
    if (
      (!HTMLInputElement.isInstance(aField) &&
        !HTMLIFrameElement.isInstance(aField) &&
        !HTMLSelectElement.isInstance(aField) &&
        !HTMLTextAreaElement.isInstance(aField)) ||
      !aField.ownerDocument
    ) {
      throw new Error("createFromField requires a field in a document");
    }

    const rootElement = this.findRootForField(aField, aOptions);
    return HTMLFormElement.isInstance(rootElement)
      ? this.createFromForm(rootElement)
      : this.createFromDocumentRoot(rootElement, aOptions);
  },

  /**
   * Find the closest <form> if any when aField is inside a ShadowRoot.
   *
   * @param {HTMLInputElement} aField - a password or username field in a document
   * @return {HTMLFormElement|null}
   */
  closestFormIgnoringShadowRoots(aField) {
    let form = aField.closest("form");
    let current = aField;
    while (!form) {
      let shadowRoot = current.getRootNode();
      if (!ShadowRoot.isInstance(shadowRoot)) {
        break;
      }
      let host = shadowRoot.host;
      form = host.closest("form");
      current = host;
    }
    return form;
  },

  /**
   * Determine the Element that encapsulates the related fields. For example, if
   * a page contains a login form and a checkout form which are "submitted"
   * separately, and the username field is passed in, ideally this would return
   * an ancestor Element of the username and password fields which doesn't
   * include any of the checkout fields.
   *
   * @param {HTMLInputElement|HTMLSelectElement} aField
   *        a field in a document
   * @return {HTMLElement} - the root element surrounding related fields
   */
  findRootForField(aField, { ignoreForm = false } = {}) {
    if (!ignoreForm) {
      let form = aField.form || this.closestFormIgnoringShadowRoots(aField);
      if (form) {
        // If a <form> appears inside another form, use the outermost <form> element.
        let parent = form;
        while ((parent = parent.parentNode)) {
          if (HTMLFormElement.isInstance(parent)) {
            form = parent;
          }
        }
        return form;
      }
    }

    return aField.ownerDocument.documentElement;
  },

  /**
   * Add a `toJSON` property to a FormLike so logging which ends up going
   * through dump doesn't include usless garbage from DOM objects.
   */
  _addToJSONProperty(aFormLike) {
    function prettyElementOutput(aElement) {
      let idText = aElement.id ? "#" + aElement.id : "";
      let classText = "";
      for (let className of aElement.classList) {
        classText += "." + className;
      }
      return `<${aElement.nodeName + idText + classText}>`;
    }

    Object.defineProperty(aFormLike, "toJSON", {
      value: () => {
        let cleansed = {};
        for (let key of Object.keys(aFormLike)) {
          let value = aFormLike[key];
          let cleansedValue = value;

          switch (key) {
            case "elements": {
              cleansedValue = [];
              for (let element of value) {
                cleansedValue.push(prettyElementOutput(element));
              }
              break;
            }

            case "ownerDocument": {
              cleansedValue = {
                location: {
                  href: value.location.href,
                },
              };
              break;
            }

            case "rootElement": {
              cleansedValue = prettyElementOutput(value);
              break;
            }
          }

          cleansed[key] = cleansedValue;
        }
        return cleansed;
      },
    });
  },
};
