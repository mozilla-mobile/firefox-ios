#import "SwrveContentItem.h"

@interface SwrveContentSpacer : SwrveContentItem

@property (readonly, atomic, strong) NSString *height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
