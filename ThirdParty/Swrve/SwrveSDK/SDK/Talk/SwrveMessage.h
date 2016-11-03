#import "SwrveMessageFormat.h"

/*! Enumerates the possible types of action that can be associated with tapping a message button. */
typedef enum {
    kSwrveActionDismiss,    /*!< Cancel the message display */
    kSwrveActionCustom,     /*!< Handle the custom action string associated with the button */
    kSwrveActionInstall     /*!< Go to the url specified in the button’s action string */
} SwrveActionType;

/*! A block that will be called when a button is pressed inside
 * an in-app message.
 */
typedef void (^SwrveMessageResult)(SwrveActionType type, NSString* action, NSInteger appId);

@class SwrveMessageController;
@class SwrveCampaign;
@class SwrveButton;

/*! In-app message. */
@interface SwrveMessage : NSObject

@property (nonatomic, weak)              SwrveCampaign* campaign; /*!< Reference to parent campaign */
@property (nonatomic, retain)            NSNumber* messageID;     /*!< Identifies the message in a campaign */
@property (nonatomic, retain)            NSString* name;          /*!< Name of the message */
@property (nonatomic, retain)            NSNumber* priority;      /*!< Priority of the message */
@property (nonatomic, retain)            NSArray*  formats;       /*!< Array of multiple formats for this message */

/*! Create an in-app message from the JSON content.
 *
 * \param json In-app message JSON content.
 * \param campaign Parent in-app campaign.
 * \param controller Message controller.
 * \returns Parsed in-app message.
 */
+(SwrveMessage*)fromJSON:(NSDictionary*)json forCampaign:(SwrveCampaign*)campaign forController:(SwrveMessageController*)controller;

/*! Obtain the best format for the given orientation.
 *
 * \param orientation Wanted orientation for the message.
 * \returns In-app message format for the given orientation.
 */
-(SwrveMessageFormat*)getBestFormatFor:(UIInterfaceOrientation)orientation;

/*! Check if assets are downloaded.
 *
 * \returns TRUE if all assets have been downloaded.
 */
-(BOOL)assetsReady:(NSSet*)assets;

/*! Check if the message has any format for the given device orientation.
 *
 * \param orientation Device orientation.
 * \returns TRUE if the message has any format with the given orientation.
 */
-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation;

/*! Notify that this message was shown to the user.
 */
-(void)wasShownToUser;

@end
