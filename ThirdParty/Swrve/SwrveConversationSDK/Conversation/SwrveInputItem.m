#import "SwrveInputItem.h"
#import "SwrveSetup.h"

@implementation SwrveInputItem

@dynamic userResponse;

-(BOOL) isFirstResponder {
    return NO;
}

-(void) resignFirstResponder {
    // Do nothing - subclasses should though.
}

@end
