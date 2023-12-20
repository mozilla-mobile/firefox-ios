// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `FormAutofillHelperError` enumerates possible errors that may occur during  Autofill information injection
/// within the `FormAutofillHelper` class. This conforms to the Swift `Error` protocol, allowing for structured
/// error handling and providing clear and specific indications of potential issues in the injection process.
enum FormAutofillHelperError: Error {
    /// Indicates an issue with the injection process in the context of the `FormAutofillHelper` class.
    case injectionIssue

    /// Indicates that the credit card information provided for injection contains invalid or missing fields.
    case injectionInvalidFields

    /// Indicates an issue with the generation or serialization of the JSON payload during the injection process.
    case injectionInvalidJSON
}
