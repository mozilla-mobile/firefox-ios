#import "SwrveMessageController.h"

@class SwrveMessageController;

/*! In-app message button. */
@interface SwrveButton : NSObject

@property (nonatomic, retain)            NSString* name;                        /*!< The name of the button. */
@property (nonatomic, retain)            NSString* image;                       /*!< The cached path of the button image on disk. */
@property (atomic)                       SwrveActionType actionType;            /*!< Type of action associated with this button. */
@property (nonatomic, retain)            NSString* actionString;                /*!< Custom action string for the button. */
@property (atomic)                       CGPoint center;                        /*!< Position of the button. */
@property (atomic)                       CGSize  size;                          /*!< Size of the button. */
@property (atomic)                       long messageID;                        /*!< Message identifier associated with this button. */
@property (atomic)                       long appID;                            /*!< ID of the target installation app. */
@property (nonatomic, weak)              SwrveMessageController* controller;    /*!< Reference to parent message controller. */
@property (nonatomic, weak)              SwrveMessage* message;                 /*!< Reference to parent message. */

/*! Create a button with the given orientation and position.
 *
 * \param delegate Event action delegate.
 * \param selector Button click selector.
 * \param scale Parent message scale.
 * \param cx Position in the x-axis.
 * \param cy Position in the y-axis.
 * \returns New button instance.
 */
-(UIButton*)createButtonWithDelegate:(id)delegate
                            andSelector:(SEL)selector
                               andScale:(float)scale
                             andCenterX:(float)cx
                             andCenterY:(float)cy;

/*! Notify that the button was pressed by the user. This method
 * is called automatically by the SDK.
 */
-(void)wasPressedByUser;

@end
