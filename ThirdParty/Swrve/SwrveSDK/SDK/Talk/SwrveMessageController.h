#import "SwrveMessageViewController.h"

#if COCOAPODS

#import <SwrveConversationSDK/SwrveBaseConversation.h>

#else

#import "SwrveBaseConversation.h"

#endif

static NSString* const AUTOSHOW_AT_SESSION_START_TRIGGER = @"Swrve.Messages.showAtSessionStart";

@class SwrveBaseCampaign;
@class SwrveMessage;
@class SwrveConversation;
@class SwrveButton;
@class Swrve;
@class SwrveConversationsNavigationController;
@class SwrveConversationItemViewController;

/*! A block that will be called when an install button in an in-app message
 * is pressed.
 *
 * Returning FALSE stops the normal flow preventing
 * Swrve to process the install action. Return TRUE otherwise.
 */
typedef BOOL (^SwrveInstallButtonPressedCallback) (NSString* appStoreUrl);

/*! A block that will be called when a custom button in an in-app message
 * is pressed.
 */
typedef void (^SwrveCustomButtonPressedCallback) (NSString* action);

/*! Delegate used to control how in-app messages are shown in your app. */
@protocol SwrveMessageDelegate <NSObject>

@optional

/*! Called when an event is raised by the Swrve SDK. Look up a message
 * to display. Return nil if no message should be displayed. By default
 * the SwrveMessageController will search for messages with the provided
 * trigger.
 *
 * \param eventName Trigger event.
 * \param payload Event payload.
 * \returns Message with the given trigger event.
 */
- (SwrveMessage*)findMessageForEvent:(NSString*) eventName withPayload:(NSDictionary *)payload;


/*! Called when an event is raised by the Swrve SDK. Look up a conversation
 * to display. Return nil if no conversation should be displayed. By default
 * the SwrveMessageController will search for conversations with the provided
 * trigger.
 *
 * \param eventName Trigger event.
 * \param payload Event payload.
 * \returns Conversation with the given trigger event.
 */
- (SwrveConversation*)getConversationForEvent:(NSString*) eventName withPayload:(NSDictionary *)payload;

/*! Called when a message should be shown. Should show and react to the action
 * in the message. By default the SwrveMessageController will display the
 * message as a modal dialog. If an install action is returned by the dialog
 * it will direct the user to the app store. If you have a custom action you
 * should create a custom delegate to process it in your app.
 *
 * \param message Message to be displayed.
 */
- (void)showMessage:(SwrveMessage *)message;

/*! Called when a conversation should be shown. Should show and react to the action
 * in the conversation.
 *
 * \param conversation Conversation to be displayed.
 */
- (void)showConversation:(SwrveConversation *)conversation;

/*! Called when the message will be shown to the user. The message is shown in
 * a separate UIWindow. This selector is called before that UIWindow is shown.
 *
 * \param viewController Message view controller.
 */
- (void) messageWillBeShown:(SwrveMessageViewController *) viewController;

/*! Called when the message will be hidden from the user. The message is shown
 * in a separate UIWindow. This selector is called before that UIWindow is
 * hidden.
 *
 * \param viewController Message view controller.
 */
- (void) messageWillBeHidden:(SwrveMessageViewController*) viewController;

/*! Called to animate the display of a message. Implement this selector
 * to customize the display of the message.
 *
 * \param viewController Message view controller.
 */
- (void) beginShowMessageAnimation:(SwrveMessageViewController*) viewController;

/*! Called to animate the hiding of a message. Implement this selector to
 * customize the hiding of the message. If you implement this you must call
 * [SwrveMessageController dismissMessageWindow] to dismiss the message window
 * after your animation is complete.
 *
 * \param viewController Message view controller.
 */
- (void) beginHideMessageAnimation:(SwrveMessageViewController*) viewController;

@end

/*! In-app messages controller */
#if defined(__IPHONE_10_0)
@interface SwrveMessageController : NSObject<SwrveMessageDelegate, SwrveMessageEventHandler, CAAnimationDelegate>
#else
@interface SwrveMessageController : NSObject<SwrveMessageDelegate, SwrveMessageEventHandler>
#endif

@property (nonatomic) Swrve*  analyticsSDK;                                             /*!< Analytics SDK reference. */
@property (nonatomic, retain) UIColor* inAppMessageBackgroundColor;                     /*!< Background color of in-app messages. */
@property (nonatomic, retain) UIColor* conversationLightboxColor;                       /*!< Background color of conversations. */
@property (nonatomic, retain) id <SwrveMessageDelegate> showMessageDelegate;            /*!< Implement this delegate to intercept in-app messages. */
@property (nonatomic, copy)   SwrveCustomButtonPressedCallback customButtonCallback;    /*!< Implement this delegate to process custom button actions. */
@property (nonatomic, copy)   SwrveInstallButtonPressedCallback installButtonCallback;  /*!< Implement this delegate to intercept install button actions. */
@property (nonatomic, retain) CATransition* showMessageTransition;                      /*!< Animation for displaying messages. */
@property (nonatomic, retain) CATransition* hideMessageTransition;                      /*!< Animation for hiding messages. */

@property (nonatomic, retain) SwrveConversationItemViewController* swrveConversationItemViewController;


/*! Initialize the message controller.
 *
 * \param swrve Swrve SDK instance.
 * \returns Initialized message controller.
 */
- (id)initWithSwrve:(Swrve*)swrve;

/*! Find an in-app message for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 * 
 * \param event Trigger event name.
 * \returns In-app message for the given tirgger.
 */
- (SwrveMessage*)getMessageForEvent:(NSString *)event;

/*! Find an in-app conversation for the given trigger event that also satisfies the rules
 * set up in the dashboard.
 *
 * \param event Trigger event name.
 * \returns In-app conversation for the given tirgger.
 */
- (SwrveConversation*)getConversationForEvent:(NSString *)event;

/*! Notify that the user pressed an in-app message button.
 *
 * \param button Button pressed by the user.
 */
-(void)buttonWasPressedByUser:(SwrveButton*)button;

/*! Notify that a message was shown to the user.
 *
 * \param message Message that was shown to the user.
 */
-(void)messageWasShownToUser:(SwrveMessage*)message;

/*! Obtain the app store URL configured for the given app.
 *
 * \param appID App ID of the target app.
 * \returns App store url for the given app.
 */
- (NSString*)getAppStoreURLForGame:(long)appID;

/*! Format the given time into POSIX time. For internal use.
 *
 * \param date Date to format into text.
 * \returns Date formatted into a POSIX string.
 */
+(NSString*)getTimeFormatted:(NSDate*)date;

/*! Shuffle the given array randomly. For internal use.
 *
 \param source Array to be shuffled.
 \returns Copy of the array, now shuffled randomly.
 */
+(NSArray*)shuffled:(NSArray*)source;

/*! Called when an event is raised by the Swrve SDK. For internal use.
 *
 * \param event Event triggered.
 * \returns YES if an in-app message was shown.
 */
-(BOOL)eventRaised:(NSDictionary*)event;

#if !defined(SWRVE_NO_PUSH)

/*! Call this method when you get a push notification device token from Apple.
 *
 * \param deviceToken Apple device token for your app.
 */
- (void)setDeviceToken:(NSData*)deviceToken;

/*! Process the given push notification. Internally, it calls -pushNotificationReceived:atApplicationState: with the current application state.
 *
 * \param userInfo Push notification information.
 */
- (void)pushNotificationReceived:(NSDictionary*)userInfo;

/*! Process the given push notification.
 *
 * \param userInfo Push notification information.
 * \param applicationState Application state at the time when the push notificatin was received.
 */
- (void)pushNotificationReceived:(NSDictionary*)userInfo atApplicationState:(UIApplicationState)applicationState;
#endif //!defined(SWRVE_NO_PUSH)

/*! Check if the user is a QA user. For internal use.
 *
 * \returns TRUE if the current user is a QA user.
 */
- (BOOL)isQaUser;

/*! Creates a new fullscreen UIWindow, adds messageViewController to it and makes
 * it visible. If a message window is already displayed, nothing is done.
 *
 * \param messageViewController Message view controller.
 */
- (void) showMessageWindow:(UIViewController*) messageViewController;

/*! Dismisses the message if it is visible. If the message window is not visible
 * nothing is done.
 */
- (void) dismissMessageWindow;

/*! Used internally to determine if the conversation filters are supporter at this moment
 *
 * \param filters Filters we need to support to display the campaign.
 * \returns nil if all devices are supported or the name of the filter that is not supported.
 */
-(NSString*) supportsDeviceFilters:(NSArray*)filters;

/*! Called internally when the app became active */
-(void) appDidBecomeActive;

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the current orientation.
 *
 * To obtain all Message Center campaigns independent of their orientation support
 * use the messageCenterCampaignsThatSupportOrientation(UIInterfaceOrientationUnknown) method.
 *
 * \returns List of active Message Center campaigns.
 */
-(NSArray*) messageCenterCampaigns;

/*! Get the list active Message Center campaigns targeted for this user.
 * It will exclude campaigns that have been deleted with the
 * removeCampaign method and those that do not support the given orientation.
 *
 * \returns List of active Message Center campaigns that support the given orientation.
 */
-(NSArray*) messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation;

/*! Display the given campaign without the need to trigger an event and skipping
 * the configured rules.
 * \param campaign Campaign that will be displayed.
 * \returns if the campaign was shown.
 */
-(BOOL)showMessageCenterCampaign:(SwrveBaseCampaign*)campaign;

/*! Remove this campaign. It won't be returned anymore by the method getCampaigns.
 *
 * \param campaign Campaing that will be removed.
 */
-(void)removeMessageCenterCampaign:(SwrveBaseCampaign*)campaign;

/*! PRIVATE: Save campaigns current state*/
-(void)saveCampaignsState;

/*! PRIVATE: ensure any currently displaying conversations are dismissed*/
-(void) cleanupConversationUI;

@end

