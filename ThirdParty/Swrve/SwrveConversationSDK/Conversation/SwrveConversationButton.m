#import "SwrveConversationButton.h"
#import "SwrveConversationUIButton.h"
#import "SwrveSetup.h"

@implementation SwrveConversationButton

@synthesize description = _description;
@synthesize actions = _actions;
@synthesize target = _target;

-(id) initWithTag:(NSString *)tag andDescription:(NSString *)description {
    self = [super initWithTag:tag andType:kSwrveControlTypeButton];
    if(self) {
        _description = description;
        _target = nil;
    }
    return self;
}

-(BOOL) endsConversation {
    return _target == nil;
}

-(UIView *)view {
    if(_view == nil) {
        SwrveConversationUIButton *button = [SwrveConversationUIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:_description forState:UIControlStateNormal];
        _view = button;
    }
    return _view;
}

@end
