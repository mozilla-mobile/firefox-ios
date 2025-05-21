/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Combine
import SwiftUI
import Glean

private var GleanDebugViewURL: URL {
    if let tag = UserDefaults.standard.string(forKey: GleanDebugViewTag), !tag.isEmpty, let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed) {
        return URL(string: "https://debug-ping-preview.firebaseapp.com/pings/\(encodedTag)", invalidCharacters: false)!
    } else {
        return URL(string: "https://debug-ping-preview.firebaseapp.com", invalidCharacters: false)!
    }
}

struct InternalTelemetrySettingsView {
    @ObservedObject var internalSettings = InternalSettings()
}

extension InternalTelemetrySettingsView {
    func sendPendingEventPings() {
        Glean.shared.handleCustomUrl(url: URL(string: "focus-glean-settings://glean?sendPing=events",
                                              invalidCharacters: false)!)
    }

    func sendPendingBaselinePings() {
        Glean.shared.handleCustomUrl(url: URL(string: "focus-glean-settings://glean?sendPing=baseline",
                                              invalidCharacters: false)!)
    }

    func sendPendingMetricsPings() {
        Glean.shared.handleCustomUrl(url: URL(string: "focus-glean-settings://glean?sendPing=metrics",
                                              invalidCharacters: false)!)
    }

    func sendPendingDeletionRequestPings() {
        Glean.shared.handleCustomUrl(url: URL(string: "focus-glean-settings://glean?sendPing=deletion-request",
                                              invalidCharacters: false)!)
    }

    func changeLogPingsToConsole(_ value: Bool) {
        Glean.shared.handleCustomUrl(url: URL(string: "focus-glean-settings://glean?logPings=\(value)",
                                              invalidCharacters: false)!)
    }

    func changeDebugViewTag(_ tag: String) {
        if let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed) {
            Glean.shared.handleCustomUrl(url: URL(string: "focus-glean-settings://glean?debugViewTag=\(encodedTag)",
                                                  invalidCharacters: false)!)
        }
    }
}

extension InternalTelemetrySettingsView: View {
    var body: some View {
        Form {
            if #available(iOS 14, *) {
                loggingSection

                debugViewSection

                eventPingsSection
            } else {
                Text(verbatim: "Internal Telemetry Settings are only available on iOS 14 and newer.")
            }
        }.navigationBarTitle(Text(verbatim: "Telemetry"))
    }

    private var loggingSection: some View {
        return SwiftUI.Section(header: Text(verbatim: "Logging")) {
            Toggle(isOn: $internalSettings.gleanLogPingsToConsole) {
                VStack(alignment: .leading) {
                    Text(verbatim: "Log Pings to Console")
                }
            }.onChange(of: internalSettings.gleanLogPingsToConsole, perform: changeLogPingsToConsole)
        }
    }

    private var debugViewSection: some View {
        return SwiftUI.Section(header: Text(verbatim: "Debug View")) {
            Toggle(isOn: $internalSettings.gleanEnableDebugView) {
                VStack(alignment: .leading) {
                    Text(verbatim: "Enable Debug View")
                    Text(verbatim: "Requires app restart").font(.caption)
                }
            }.disabled(internalSettings.gleanDebugViewTag.isEmpty)

            VStack(alignment: .leading) {
                TextField("Debug View Tag", text: $internalSettings.gleanDebugViewTag)
                    .onChange(of: internalSettings.gleanDebugViewTag, perform: changeDebugViewTag)
            }

            Button(action: { UIApplication.shared.open(GleanDebugViewURL) }) {
                Text(verbatim: "Open Debug View (In Default Browser)")
            }

            Button(action: { UIPasteboard.general.url = GleanDebugViewURL }) {
                Text(verbatim: "Copy Debug View Link")
            }
        }
    }

    private var eventPingsSection: some View {
        return SwiftUI.Section {
            Button(action: { sendPendingEventPings() }) {
                Text(verbatim: "Send Pending Event Pings")
            }

            Button(action: { sendPendingBaselinePings() }) {
                Text(verbatim: "Send Baseline Event Pings")
            }

            Button(action: { sendPendingMetricsPings() }) {
                Text(verbatim: "Send Metrics Event Pings")
            }

            Button(action: { sendPendingDeletionRequestPings() }) {
                Text(verbatim: "Send Deletion Request Event Pings")
            }
        }
    }
}

struct InternalTelemetrySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InternalTelemetrySettingsView()
    }
}
