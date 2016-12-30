#import "SwrveContentItem.h"

@interface SwrveInputItem : SwrveContentItem

@property(nonatomic,strong) id userResponse;

-(BOOL) isFirstResponder;
-(void) resignFirstResponder;

@end
