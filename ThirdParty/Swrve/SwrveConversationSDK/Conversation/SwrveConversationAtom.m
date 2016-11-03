#import "SwrveConversationAtom.h"
#import "SwrveBaseConversation.h"

@implementation SwrveConversationAtom

@synthesize tag = _tag;
@synthesize type = _type;
@synthesize view = _view;
@synthesize style;
@synthesize delegate;

#define kCellTag 101

-(id) initWithTag:(NSString *)tag andType:(NSString *)type {
    self = [super init];
    if(self) {
        _tag = tag;
        _type = type;
    }
    return self;
}

-(BOOL) willRequireLandscape {
    return YES;
}

-(void) stop {
    // By default, does nothing. Specialize in subclass
}

-(void) viewDidDisappear {
    // By default, does nothing. Specialize in subclass
}

-(void) removeView {
    _view = nil;
}

-(void) loadViewWithContainerView:(UIView*)containerView {
#pragma unused(containerView)
    NSException *exec = [[NSException alloc] initWithName:@"NotImplemented" reason:@"Not Implemented" userInfo:nil];
    [exec raise];
}

-(NSUInteger) numberOfRowsNeeded {
    return 1;
}

-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
#pragma unused (row)
    NSString *cellId = [NSString stringWithFormat:@"%@CellId", self.type];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    /* First, check if there's a previous one there, we may need to reset the content */
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *v = [cell.contentView viewWithTag:kCellTag];
        if(v) {
            [v removeFromSuperview];
        }
    });
    _view.tag = kCellTag;
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell.contentView addSubview:self->_view];
        cell.contentView.backgroundColor = [UIColor clearColor];
    });
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

-(CGFloat) verticalPadding {
    return 0.0;
}

-(CGFloat) heightForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
#pragma unused (row, tableView)
    return _view.frame.size.height + [self verticalPadding];
}

// Return the new frame that this view needs to sit correctly
// on the screen after an orientation change
-(CGRect) newFrameForOrientationChange {
    return CGRectMake(_view.frame.origin.x, _view.frame.origin.y, _view.superview.frame.size.width, _view.frame.size.height);
}


// iOS8+
-(void)viewWillTransitionToSize:(CGSize)size {
#pragma unused(size)
    // By default, does nothing. Specialize in subclass
}

@end
