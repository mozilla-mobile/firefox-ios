#import <UIKit/UIKit.h>

@class SwrveContentStarRatingView;

@protocol SwrveConversationStarRatingViewDelegate
- (void) ratingView:(SwrveContentStarRatingView *) ratingView ratingDidChange:(float) rating;
@end

@interface SwrveContentStarRatingView : UIView

@property (strong, nonatomic) id <SwrveConversationStarRatingViewDelegate> swrveRatingDelegate;

- (id) initWithDefaults;
- (void) updateWithStarColor:(UIColor *) starColor withBackgroundColor:(UIColor *)backgroundColor;

@end
