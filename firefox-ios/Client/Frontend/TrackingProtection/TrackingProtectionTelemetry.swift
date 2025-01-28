// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Glean

struct TrackingProtectionTelemetry {
    func showClearCookiesAlert() {
        GleanMetrics.TrackingProtection.showClearCookiesAlert.record()
    }

    func clearCookiesAndSiteData() {
        GleanMetrics.TrackingProtection.tappedClearCookies.record()
    }

    func showTrackingProtectionDetails() {
        GleanMetrics.TrackingProtection.showEtpDetails.record()
    }

    func showBlockedTrackersDetails() {
        GleanMetrics.TrackingProtection.showEtpBlockedTrackersDetails.record()
    }

    func tappedShowSettings() {
        GleanMetrics.TrackingProtection.showEtpSettings.record()
    }

    func dismissTrackingProtection() {
        GleanMetrics.TrackingProtection.dismissEtpPanel.record()
    }

    func trackShowCertificates() {
        GleanMetrics.TrackingProtection.showCertificates.record()
    }
}
