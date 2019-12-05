import Foundation

/**
 The app internal state
 */
class AppState: NSObject, NSCopying {
    var aRRequest: [AnyHashable : Any] = [:]
    var showMode: ShowMode = .nothing
    var showOptions: ShowOptions = .init(rawValue: 0)
    var webXR = false
    var geometryArrays = false
    var computerVisionFrameRequested = false
    var shouldRemoveAnchorsOnNextARSession = false
    var sendComputerVisionData = false
    var shouldShowSessionStartedPopup = false
    var shouldShowLiteModePopup = false
    var numberOfTimesSendNativeTimeWasCalled: Int = 0
    var numberOfTrackedImages: Int = 0
    var userGrantedSendingComputerVisionData = false
    var askedComputerVisionData = false
    var userGrantedSendingWorldStateData: WebXRAuthorizationState = .notDetermined
    var askedWorldStateData = false

    class func defaultState() -> AppState {
        let state = AppState()

        state.showMode = ShowMode.nothing
        state.showOptions = ShowOptions.init(rawValue: 0)
        state.shouldShowSessionStartedPopup = true
        state.geometryArrays = false
        state.shouldShowLiteModePopup = true
        state.numberOfTimesSendNativeTimeWasCalled = 0
        state.numberOfTrackedImages = 0
        state.userGrantedSendingComputerVisionData = false
        state.userGrantedSendingWorldStateData = .notDetermined
        state.askedComputerVisionData = false
        state.askedWorldStateData = false

        return state
    }

    func updatedShowMode(_ showMode: ShowMode) -> Self {
        self.showMode = showMode
        return self
    }

    func updatedShowOptions(_ showOptions: ShowOptions) -> Self {
        self.showOptions = showOptions
        return self
    }

    func updatedWebXR(_ webXR: Bool) -> Self {
        self.webXR = webXR
        return self
    }

    func updated(withARRequest dict: [AnyHashable : Any]?) -> Self {
        guard let dict = dict else { return self }
        aRRequest = dict
        return self
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = AppState()
        copy.showOptions = showOptions
        copy.showMode = showMode
        copy.webXR = webXR
        copy.geometryArrays = geometryArrays
        copy.aRRequest = aRRequest
        copy.computerVisionFrameRequested = computerVisionFrameRequested
        copy.shouldRemoveAnchorsOnNextARSession = shouldRemoveAnchorsOnNextARSession
        copy.sendComputerVisionData = sendComputerVisionData
        copy.shouldShowSessionStartedPopup = shouldShowSessionStartedPopup
        copy.shouldShowLiteModePopup = shouldShowLiteModePopup
        copy.numberOfTimesSendNativeTimeWasCalled = numberOfTimesSendNativeTimeWasCalled
        copy.numberOfTrackedImages = numberOfTrackedImages
        copy.userGrantedSendingComputerVisionData = userGrantedSendingComputerVisionData
        copy.askedComputerVisionData = askedComputerVisionData
        copy.userGrantedSendingWorldStateData = userGrantedSendingWorldStateData
        copy.askedWorldStateData = askedWorldStateData

        return copy
    }
}

/**
 An enum representing the state of the app UI at a given time
 
 - nothing: Shows the warning labels
 - debug: Shows the helper and build label, and the AR debug info
 - url: Shows the URL Bar
 - urlDebug: Shows the URL Bar and the AR debug info
 */
enum ShowMode: Int {
    case nothing    = 0
    case debug      = 1
    case url        = 2
    case urlDebug   = 3
}
