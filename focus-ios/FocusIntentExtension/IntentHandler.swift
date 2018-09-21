/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Intents

class IntentHandler: INExtension, EraseIntentHandling {
    
    func handle(intent: EraseIntent, completion: @escaping (EraseIntentResponse) -> Void) {
        Settings.setSiriRequestErase(to: true)
        completion(EraseIntentResponse(code: .success, userActivity: nil ))
    }
    
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
