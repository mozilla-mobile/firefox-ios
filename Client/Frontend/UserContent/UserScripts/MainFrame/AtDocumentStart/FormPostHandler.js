/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

/**
 * This is a workaround for an issue where `<form method="POST" target="_blank">`
 * submits an empty HTTP request body. This seems to be a known WebKit issue that
 * is tracked here: https://bugs.webkit.org/show_bug.cgi?id=140188
 */

// Get the native property descriptors for the `<form>` element's prototype. We
// need to do this because properties on the `<form>` element can be overridden if
// a form field uses the same `[name]` as an existing property. For example, if a
// `<form action="/foo">` contains `<input name="action" value="bar">`, accessing
// the `.action` property on the `<form>` would return the `<input>` element instead
// of returning `"/foo"`.
const FORM_PROTO_PROPS = Object.getOwnPropertyDescriptors(HTMLFormElement.prototype);

// Get the native `submit()` method for the `<form>` element's prototype. We need
// to override it in order to hook our `beforeSubmit()` function before the native
// `submit()` implementation executes.
const FORM_PROTO_SUBMIT = HTMLFormElement.prototype.submit;

// Override the native `submit()` method on the `<form>` element's prototype to
// call `beforeSubmit()` to serialize the form data to send to our native helper
// before calling the native `submit()` implementation.
HTMLFormElement.prototype.submit = function() {
  beforeSubmit(this);
  return FORM_PROTO_SUBMIT.apply(this, arguments);
};

// Listen for all other `submit` events on the `document` and call `beforeSubmit()`
// to serialize the form data to send to our `WKScriptMessageHandler`.
document.addEventListener("submit", function(evt) {
  var form = evt.target;
  if (form.tagName !== "FORM") {
      return;
  }

  beforeSubmit(form);
}, true);

function beforeSubmit(form) {
  // Ensure the `submit` event was for `<form target="_blank" method="POST">`
  // elements only. Also ensure `[enctype="application/x-www-form-urlencoded"]`
  // (which is the default for all `<form>` elements unless otherwise specified).
  // Bail out immediately if any of these conditions are not met.
  var target = (FORM_PROTO_PROPS.target.get.apply(form) || "").toLowerCase();
  if (target !== "_blank") {
    return;
  }

  var method = (FORM_PROTO_PROPS.method.get.apply(form) || "GET").toUpperCase();
  if (method !== "POST") {
    return;
  }

  var enctype = (FORM_PROTO_PROPS.enctype.get.apply(form) || "").toLowerCase();
  if (enctype !== "application/x-www-form-urlencoded") {
    return;
  }

  // Notify our `WKScriptMessageHandler` that we are about to submit this form.
  // This is where we actually serialize the form data for the HTTP request body.
  webkit.messageHandlers.formPostHelper.postMessage({
    action: (FORM_PROTO_PROPS.action.get.apply(form) || window.location.href),
    method: method,
    target: target,
    enctype: enctype,
    requestBody: serializeFormWithURLEncoding(form)
  });
}

// Helper function that serializes the form data for the specified `<form>` element
// in the `application/x-www-form-urlencoded` format. The return value should be a
// string that matches exactly what the HTTP request body would be when submitting
// the specified `<form>` element natively.
function serializeFormWithURLEncoding(form) {
  var values = [];

  [].slice.apply(form.elements).forEach(function(field) {
    // Do not include form fields that are disabled. Also, do not include
    // form fields without a `[name]` or `<input type="file">` fields in
    // the `application/x-www-form-urlencoded` format.
    if (field.disabled || !field.name || field.type === "file") {
      return;
    }

    // URL-encode the field `[name]`.
    var name = encodeURIComponent(field.name);

    // Aggregate all selected options for `<select multiple>` fields by
    // getting all `<option selected>` child elements.
    if (field.type === "select-multiple") {
      [].slice.apply(field.options).forEach(function(option) {
        if (option.selected) {
          values.push(name + "=" + encodeURIComponent(option.value || ""));
        }
      });
    }

    // If the field is not an `<input type="checkbox">` or `<input type="radio">`,
    // we can just get the URL-encoded `[value]` for the field. Otherwise, if it
    // is an `<input type="checkbox">` or `<input type="radio">`, we must ensure
    // it is `[checked]` before getting its URL-encoded `[value]`. Any unchecked
    // `<input type="checkbox">` or `<input type="radio">` fields are not to be
    // included in the `application/x-www-form-urlencoded` format.
    else if ((field.type !== "checkbox" && field.type !== "radio") || field.checked) {
      values.push(name + "=" + encodeURIComponent(field.value || ""));
    }
  });

  // Join all URL-encoded `"name=value"` strings with an `"&"` as required by the
  // `application/x-www-form-urlencoded` format.
  return values.join("&");
}
