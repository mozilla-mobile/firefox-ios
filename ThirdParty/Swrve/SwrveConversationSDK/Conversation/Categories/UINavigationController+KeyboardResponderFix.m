#import "UINavigationController+KeyboardResponderFix.h"

@implementation UINavigationController (KeyboardResponderFix)

-(BOOL)disablesAutomaticKeyboardDismissal{
    return NO;
}

@end
