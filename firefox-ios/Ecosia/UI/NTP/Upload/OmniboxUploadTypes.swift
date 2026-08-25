// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Upload sources shown in the top row of the omnibox "AI tools" drawer.
/// Case order mirrors the design's left-to-right layout (Photos, Camera, Files).
public enum OmniboxUploadOption: CaseIterable, Hashable {
    case photos
    case camera
    case files
}

/// Placeholder model for selected upload items. Upload handling is wired in a follow-up.
public struct OmniboxUploadItem: Equatable {
    public enum Source {
        case photos
        case camera
        case files
    }

    public let source: Source
    public let fileName: String
    public let contentTypeIdentifier: String?

    public init(source: Source, fileName: String, contentTypeIdentifier: String?) {
        self.source = source
        self.fileName = fileName
        self.contentTypeIdentifier = contentTypeIdentifier
    }
}

public extension OmniboxUploadOption {
    var iconName: String {
        switch self {
        case .photos: return "upload-photos"
        case .camera: return "upload-camera"
        case .files: return "upload-files"
        }
    }

    var title: String {
        switch self {
        case .photos: return String.localized(.photos)
        case .camera: return String.localized(.camera)
        case .files: return String.localized(.files)
        }
    }

    var accessibilityLabel: String { title }

    var accessibilityHint: String {
        switch self {
        case .photos: return String.localized(.uploadPhotosAccessibilityHint)
        case .camera: return String.localized(.uploadCameraAccessibilityHint)
        case .files: return String.localized(.uploadFilesAccessibilityHint)
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .photos: return "OmniboxUploadPhotosOption"
        case .camera: return "OmniboxUploadCameraOption"
        case .files: return "OmniboxUploadFilesOption"
        }
    }
}

/// Chat modes listed below the upload row in the omnibox "AI tools" drawer.
/// Selecting any mode currently opens the standard Ecosia AI Chat; the case is
/// carried through the selection plumbing so a per-mode parameter can be added later.
public enum OmniboxChatMode: CaseIterable, Hashable {
    case standard
    case thinkLonger
    case displaySources
    case learning
}

public extension OmniboxChatMode {
    var iconName: String {
        switch self {
        case .standard: return "chatmodes-standard-ai-chat"
        case .thinkLonger: return "chatmodes-think-longer"
        case .displaySources: return "chatmodes-display-sources"
        case .learning: return "chatmodes-learning"
        }
    }

    var title: String {
        switch self {
        case .standard: return String.localized(.chatModeStandard)
        case .thinkLonger: return String.localized(.chatModeThinkLonger)
        case .displaySources: return String.localized(.chatModeDisplaySources)
        case .learning: return String.localized(.chatModeLearning)
        }
    }

    var subtitle: String {
        switch self {
        case .standard: return String.localized(.chatModeStandardSubtitle)
        case .thinkLonger: return String.localized(.chatModeThinkLongerSubtitle)
        case .displaySources: return String.localized(.chatModeDisplaySourcesSubtitle)
        case .learning: return String.localized(.chatModeLearningSubtitle)
        }
    }

    /// `mode` field of the `mode_selection` analytics payload. Deliberately its
    /// own value rather than a reuse of `iconName` or the accessibility id, so
    /// renaming an asset or a test hook can't silently re-shape reported data.
    var analyticsIdentifier: String {
        switch self {
        case .standard: return "standard"
        case .thinkLonger: return "think_longer"
        case .displaySources: return "display_sources"
        case .learning: return "learning"
        }
    }

    var accessibilityLabel: String { title }

    var accessibilityHint: String { String.localized(.aiChatAccessibilityHint) }

    var accessibilityIdentifier: String {
        switch self {
        case .standard: return "OmniboxChatModeStandardOption"
        case .thinkLonger: return "OmniboxChatModeThinkLongerOption"
        case .displaySources: return "OmniboxChatModeDisplaySourcesOption"
        case .learning: return "OmniboxChatModeLearningOption"
        }
    }

    /// Extra query items appended to the AI Chat URL so the backend opens the
    /// conversation in this mode. `standard` carries none (plain `/ai-chat`);
    /// the others map to the agreed backend flags:
    /// Think longer → `t=1`, Display sources → `m=2`, Learning → `m=1`.
    var aiChatQueryItems: [URLQueryItem] {
        switch self {
        case .standard: return []
        case .thinkLonger: return [URLQueryItem(name: "t", value: "1")]
        case .displaySources: return [URLQueryItem(name: "m", value: "2")]
        case .learning: return [URLQueryItem(name: "m", value: "1")]
        }
    }
}
