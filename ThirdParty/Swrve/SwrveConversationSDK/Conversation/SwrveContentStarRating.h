#import "SwrveContentItem.h"
#import "SwrveContentStarRatingView.h"

@interface SwrveContentStarRating : SwrveContentItem <SwrveConversationStarRatingViewDelegate>

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *) dict;

@property (readwrite, nonatomic) float      currentRating;
@property (readonly, nonatomic) NSString   *starColor;

@end
