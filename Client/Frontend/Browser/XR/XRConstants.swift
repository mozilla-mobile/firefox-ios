import Foundation
import ARKit

// URL
let WEB_URL = "https://webxr-ios.webxrexperiments.com/splash.html"
let LAST_URL_KEY = "lastURL"

// MESSAGES
let WEB_AR_INIT_MESSAGE = "initAR"
let WEB_AR_INJECT_POLYFILL = "injectPolyfill"
let WEB_AR_START_WATCH_MESSAGE = "watchAR"
let WEB_AR_REQUEST_MESSAGE = "requestSession"
let WEB_AR_STOP_WATCH_MESSAGE = "stopAR"
let WEB_AR_ON_JS_UPDATE_MESSAGE = "onUpdate"
let WEB_AR_LOAD_URL_MESSAGE = "loadUrl"
let WEB_AR_SET_UI_MESSAGE = "setUIOptions"
let WEB_AR_HIT_TEST_MESSAGE = "hitTest"
let WEB_AR_ADD_ANCHOR_MESSAGE = "addAnchor"
let WEB_AR_REMOVE_ANCHORS_MESSAGE = "removeAnchors"
let WEB_AR_ADD_IMAGE_ANCHOR_MESSAGE = "addImageAnchor"
let WEB_AR_TRACKED_IMAGES_MESSAGE = "setNumberOfTrackedImages"
let WEB_AR_CREATE_IMAGE_ANCHOR_MESSAGE = "createImageAnchor"
let WEB_AR_ACTIVATE_DETECTION_IMAGE_MESSAGE = "activateDetectionImage"
let WEB_AR_DEACTIVATE_DETECTION_IMAGE_MESSAGE = "deactivateDetectionImage"
let WEB_AR_DESTROY_DETECTION_IMAGE_MESSAGE = "destroyDetectionImage"
let WEB_AR_REQUEST_CV_DATA_MESSAGE = "requestComputerVisionData"
let WEB_AR_START_SENDING_CV_DATA_MESSAGE = "startSendingComputerVisionData"
let WEB_AR_STOP_SENDING_CV_DATA_MESSAGE = "stopSendingComputerVisionData"
let WEB_AR_ADD_IMAGE_ANCHOR = "addImageAnchor"
let WEB_AR_GET_WORLD_MAP_MESSAGE = "getWorldMap"
let WEB_AR_SET_WORLD_MAP_MESSAGE = "setWorldMap"
let WEB_AR_IOS_START_RECORDING_MESSAGE = "arkitStartRecording"
let WEB_AR_IOS_INTERRUPTION_ENDED_MESSAGE = "arkitInterruptionEnded"
let WEB_AR_IOS_DID_MOVE_BACK_MESSAGE = "arkitDidMoveBackground"
let WEB_AR_IOS_WILL_ENTER_FOR_MESSAGE = "arkitWillEnterForeground"
let WEB_AR_IOS_TRACKING_STATE_MESSAGE = "arTrackingChanged"
let WEB_AR_IOS_SHOW_DEBUG = "arkitShowDebug"
let WEB_AR_IOS_DID_RECEIVE_MEMORY_WARNING_MESSAGE = "ios_did_receive_memory_warning"
let WEB_AR_IOS_USER_GRANTED_CV_DATA = "userGrantedComputerVisionData"
let WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA = "userGrantedWorldSensingData"
let WEB_AR_IOS_USERSTOPPED_AR = "userStoppedAR"

// OPTIONS
let WEB_AR_CALLBACK_OPTION = "callback"
let WEB_AR_DATA_CALLBACK_OPTION = "data_callback"
let WEB_AR_REQUEST_OPTION = "options"
let WEB_AR_UI_OPTION = "ui"
let WEB_AR_UI_BROWSER_OPTION = "browser"
let WEB_AR_UI_POINTS_OPTION = "points"
let WEB_AR_UI_DEBUG_OPTION = "debug"
let WEB_AR_UI_STATISTICS_OPTION = "statistics"
let WEB_AR_UI_FOCUS_OPTION = "focus"
let WEB_AR_UI_BUILD_OPTION = "build"
let WEB_AR_UI_PLANE_OPTION = "plane"
let WEB_AR_UI_WARNINGS_OPTION = "warnings"
let WEB_AR_UI_ANCHORS_OPTION = "anchors"
let WEB_IOS_SCREEN_SIZE_OPTION = "screenSize"
let WEB_IOS_SCREEN_SCALE_OPTION = "screenScale"
let WEB_IOS_SYSTEM_VERSION_OPTION = "systemVersion"
let WEB_IOS_IS_IPAD_OPTION = "isIpad"
let WEB_IOS_DEVICE_UUID_OPTION = "deviceUUID"
let WEB_AR_URL_OPTION = "url"
let WEB_AR_IOS_WINDOW_RESIZE_MESSAGE = "arkitWindowResize"
let WEB_AR_IOS_ERROR_MESSAGE = "onError"
let WEB_AR_IOS_SIZE_WIDTH_PARAMETER = "width"
let WEB_AR_IOS_SIZE_HEIGHT_PARAMETER = "height"
let WEB_AR_IOS_ERROR_DOMAIN_PARAMETER = "domain"
let WEB_AR_IOS_ERROR_CODE_PARAMETER = "code"
let WEB_AR_IOS_ERROR_MESSAGE_PARAMETER = "message"
let WEB_AR_GEOMETRY_ARRAYS = "geometry_arrays"
let WEB_AR_TYPE_OPTION = "type"
let WEB_AR_X_POSITION_OPTION = "x"
let WEB_AR_Y_POSITION_OPTION = "y"
let WEB_AR_Z_POSITION_OPTION = "z"
let WEB_AR_TRANSFORM_OPTION = "transform"
let WEB_AR_UUID_OPTION = "uuid"
let WEB_AR_NUMBER_OF_TRACKED_IMAGES_OPTION = "numberOfTrackedImages"
let WEB_AR_DETECTION_IMAGE_NAME_OPTION = "uid"
let WEB_AR_GEOMETRY_OPTION = "geometry"
let WEB_AR_BLEND_SHAPES_OPTION = "blendShapes"
let WEB_AR_ANCHOR_TYPE = "type"
let WEB_AR_MUST_SEND_OPTION = "mustSend"
let WEB_AR_PLANE_CENTER_OPTION = "plane_center"
let WEB_AR_PLANE_EXTENT_OPTION = "plane_extent"
let WEB_AR_PLANE_ALIGNMENT_OPTION = "plane_alignment"
let WEB_AR_W_TRANSFORM_OPTION = "world_transform"
let WEB_AR_L_TRANSFORM_OPTION = "local_transform"
let WEB_AR_DISTANCE_OPTION = "distance"
let WEB_AR_ANCHOR_TRANSFORM_OPTION = "anchor_transform"
let WEB_AR_ANCHOR_CENTER_OPTION = "anchor_center"
let WEB_AR_ANCHOR_EXTENT_OPTION = "anchor_extent"
let WEB_AR_WORLD_ALIGNMENT = "alignEUS"
let WEB_AR_WORLDMAPPING_STATUS_MESSAGE = "worldMappingStatus"
let WEB_AR_LIGHT_INTENSITY_OPTION = "light_intensity"
let WEB_AR_LIGHT_AMBIENT_COLOR_TEMPERATURE_OPTION = "ambient_color_temperature"
let WEB_AR_PRIMARY_LIGHT_DIRECTION_OPTION = "primary_light_direction"
let WEB_AR_PRIMARY_LIGHT_INTENSITY_OPTION = "primary_light_intensity"
let WEB_AR_LIGHT_OBJECT_OPTION = "light"
let WEB_AR_CAMERA_OPTION = "camera"
let WEB_AR_PROJ_CAMERA_OPTION = "projection_camera"
let AR_CAMERA_PROJECTION_MATRIX_Z_NEAR = 0.001
let AR_CAMERA_PROJECTION_MATRIX_Z_FAR = 1000.0
let WEB_AR_CAMERA_TRANSFORM_OPTION = "camera_transform"
let WEB_AR_CAMERA_VIEW_OPTION = "camera_view"
let WEB_AR_3D_OBJECTS_OPTION = "objects"
let WEB_AR_3D_REMOVED_OBJECTS_OPTION = "removedObjects"
let WEB_AR_3D_NEW_OBJECTS_OPTION = "newObjects"
let WEB_AR_3D_GEOALIGNED_OPTION = "geoaligned"
let WEB_AR_3D_VIDEO_ACCESS_OPTION = "videoAccess"
let WEB_AR_WORLDMAPPING_NOT_AVAILABLE = "ar_worldmapping_not_available"
let WEB_AR_WORLDMAPPING_LIMITED = "ar_worldmapping_limited"
let WEB_AR_WORLDMAPPING_EXTENDING = "ar_worldmapping_extending"
let WEB_AR_WORLDMAPPING_MAPPED = "ar_worldmapping_mapped"
let PREFER_FPS = 60
let REQUESTED_URL_KEY = "requestedURL"
let MEMORY_ERROR_DOMAIN = "Memory"
let MEMORY_ERROR_CODE = 0
let MEMORY_ERROR_MESSAGE = "Memory warning received"
let WEB_AR_CV_INFORMATION_OPTION = "computer_vision_data"
let AR_SESSION_STARTED_POPUP_TITLE = "AR Session Started"
let AR_SESSION_STARTED_POPUP_MESSAGE = "Rotate device to show the URL bar"
let AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS = 2
let MULTIPLE_AR_SESSIONS_TITLE = "Only one AR experience can run at a time"
let MULTIPLE_AR_SESSIONS_MESSAGE = "Shutting down last AR session"
let MULTIPLE_AR_SESSIONS_POPUP_TIME_IN_SECONDS = 4
let WEB_AR_WORLD_SENSING_DATA_OPTION = "worldSensing"

let UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE = "The selected ARSessionConfiguration is not supported by the current device"
let SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE = "A sensor required to run the session is not available"
let SENSOR_FAILED_ARKIT_ERROR_MESSAGE = "A sensor failed to provide the required input.\nWe will try to restart the session using a Gravity World Alignment"
let WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE = "World tracking has encountered a fatal error"

class Constant: NSObject {
    override private init() {}
    
    static func homeURLKey() -> String { return "homeURL" }
    static func exposeWebXRAPIKey() -> String { return "exposeWebXRAPI" }
    static func polyfillURLKey() -> String { return "polyfillURL" }
    static func urlBarHeight() -> CGFloat { return 49 }
    static func urlBarAnimationTimeInSeconds() -> TimeInterval { return 0.2 }
    static func distantAnchorsDistanceKey() -> String { return "distantAnchorsDistance" }
    static func distantAnchorsDefaultDistanceInMeters() -> Float { return 3 }
    static func lastResetSessionTrackingDateKey() -> String { return "lastResetSessionTrackingDate" }
    static func boxSize() -> CGFloat { return 0.05 }
    static func backgroundOrPausedDateKey() -> String { return "backgroundOrPausedDate" }
    static func useMetalForARKey() -> String { return "useMetalForAR" }
    static func thresholdTimeInSecondsSinceLastTrackingReset() -> Double { return 600 }
    static func pauseTimeInSecondsToRemoveAnchors() -> Double { return 10 }
    static func secondsInBackgroundKey() -> String { return "secondsInBackground" }
    static func sessionInBackgroundDefaultTimeInSeconds() -> Int { return 60 }
    static func minimalWebXREnabled() -> String { return "minimalWebXREnabled" }
    static func worldSensingWebXREnabled() -> String { return "worldSensingWebXREnabled" }
    static func videoCameraAccessWebXREnabled() -> String { return "videoCameraAccessWebXREnabled" }
    static func allowedMinimalSitesKey() -> String { return "allowedMinimalSites" }
    static func allowedWorldSensingSitesKey() -> String { return "allowedWorldSensingSites" }
    static func allowedVideoCameraSitesKey() -> String { return "allowedVideoCameraSites" }
    static func alwaysAllowWorldSensingKey() -> String { return "alwaysAllowWorldSensing" }
    static func liteModeWebXREnabled() -> String { return "liteModeWebXREnabled" }
    static func recordSize() -> CGFloat { return 60.5 }
    static func recordOffsetX() -> CGFloat { return 25.5 }
    static func recordOffsetY() -> CGFloat { return 25.5 }
    static func micSizeW() -> CGFloat { return 27.75 }
    static func micSizeH() -> CGFloat { return 27.75 }
}
