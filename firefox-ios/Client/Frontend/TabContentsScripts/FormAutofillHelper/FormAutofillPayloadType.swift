// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `FormAutofillPayloadType` enumerates the different types of payloads that the `FormAutofillHelper`
/// class may encounter during the autofill process. Each case represents a specific action related to
/// credit card or address form interaction, providing a clear and structured way to identify and handle
/// different payload scenarios.
enum FormAutofillPayloadType: String {
    /// Indicates a payload type for capturing credit card information from a form submission.
    case formSubmit = "capture-credit-card-form"

    /// Indicates a payload type for filling credit card information into a form.
    case formInput = "fill-credit-card-form"

    /// Indicates a payload type for filling address information into a form.
    case fillAddressForm = "fill-address-form"

    /// Indicates a payload type for capturing address information from a form submission.
    case captureAddressForm = "capture-address-form"
}
