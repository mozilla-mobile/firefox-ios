// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class MockPocketSponsoredStoriesProvider: PocketSponsoredStoriesProviderInterface {
    func fetchSponsoredStories() -> Deferred<[PocketSponsoredStory]> {
        let deferred = Deferred<[PocketSponsoredStory]>()
        let path = Bundle(for: type(of: self)).path(forResource: "pocketsponsoredfeed", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let response = try! JSONDecoder().decode(PocketSponsoredRequest.self, from: data)
        deferred.fill(response.spocs)
        return deferred
    }
}
