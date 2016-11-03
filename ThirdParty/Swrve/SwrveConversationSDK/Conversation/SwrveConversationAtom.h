#import <UIKit/UIKit.h>
#import "SwrveSetup.h"

@class SwrveBaseConversation;

// Content types
#define kSwrveContentTypeHTML @"html-fragment"
#define kSwrveContentTypeImage @"image"
#define kSwrveContentTypeVideo @"video"
#define kSwrveContentSpacer @"spacer"
// Input types
#define kSwrveInputMultiValue @"multi-value-input"
// Control types
#define kSwrveControlTypeButton @"button"
#define kSwrveControlStarRating @"star-rating"

// Notifications
#define kSwrveNotificationViewReady @"SwrveNotificationViewReady"

// Orientation Change delegate
@protocol SwrveConversationAtomDelegate <NSObject>

@required
- (void) respondToDeviceOrientationChange:(UIDeviceOrientation) orientation;

@end

@interface SwrveConversationAtom : NSObject {
    UIView *_view;
}

@property (readonly, nonatomic) NSString *tag;
@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) UIView *view;
@property (strong, nonatomic)   NSDictionary *style;
@property (strong, nonatomic) id <SwrveConversationAtomDelegate> delegate;

-(id)                initWithTag:(NSString *)tag andType:(NSString *)type;
-(BOOL)              willRequireLandscape;
-(CGRect)            newFrameForOrientationChange;
-(NSUInteger)        numberOfRowsNeeded;
-(CGFloat)           heightForRow:(NSUInteger) row inTableView:(UITableView *)tableView;
-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView;

// Subclasses should override this
-(void) loadViewWithContainerView:(UIView*)containerView;
-(void) viewWillTransitionToSize:(CGSize)size;

// If the atom has some kind of activity going, then
// this is notice to cease it. Defaults to doing nothing.
-(void) stop;
-(void) viewDidDisappear;
// Temporal fix to remove views from model.
-(void) removeView;

@end
