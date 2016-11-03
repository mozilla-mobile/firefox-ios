#import "SwrveContentItem.h"

@interface SwrveContentVideo : SwrveContentItem <UIWebViewDelegate, UIGestureRecognizerDelegate>

@property (readonly, atomic, strong) NSString *height;
@property (nonatomic) BOOL interactedWith;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
