#import "SwrveContentItem.h"

@interface SwrveContentHTML : SwrveContentItem <UIWebViewDelegate>

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
