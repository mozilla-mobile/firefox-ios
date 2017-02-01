#import "BTNDropinButtonCell.h"

@protocol BTNDropinButtonCellDeprecated <NSObject>

/// The ID of the button this cell represents.
@property (nullable, nonatomic, copy) IBInspectable NSString *buttonId;


/**
 Prepares the cell for display with contextually relevant data.
 @param context A BTNContext object providing context about your user's current activity.
 @param completionHandler A block to be executed upon completion of preparation.
 
 @note The button will not be visible until preparation has completed successfully.
 You should set a completion handler in order to do any work in your view hierarchy
 after completion. For example, you may want to remove this cell from your tableView
 if the button is not displayable.
 
 @warning -prepareWithAppAction: is the preferred approach to render a Button.
 Using this method in conjunction with -prepareWithAppAction: can lead to undefined behavior.
 */
- (void)prepareWithContext:(nonnull BTNContext *)context
                completion:(nullable void(^)(BOOL isDisplayable))completionHandler;

@end
