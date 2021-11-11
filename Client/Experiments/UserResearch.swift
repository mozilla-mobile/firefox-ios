// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import MozillaAppServices

/// This procol will give access to the `Experiments` singleton and require
/// the conforming class to set up an experiment.
protocol UserResearch {
    func setupExperiment()
}

extension UserResearch {
    var experiments: NimbusApi {
        return Experiments.shared
    }
}
