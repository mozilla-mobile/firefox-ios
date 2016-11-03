#import "SwrveConversationContainerViewController.h"

@interface SwrveConversationContainerViewController ()

@property (nonatomic, retain) UIViewController* childController;
@property (nonatomic) BOOL displayedChildrenViewController;
@property (nonatomic, retain) NSDictionary *lightBoxStyle;
@property (nonatomic, retain) UIColor* lightBoxColor;

@end

@implementation SwrveConversationContainerViewController

@synthesize childController;
@synthesize displayedChildrenViewController;
@synthesize lightBoxStyle = _lightBoxStyle;
@synthesize lightBoxColor = _lightBoxColor;

-(id) initWithChildViewController:(UIViewController*)child {
    if (self = [super init]) {
        self.childController = child;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!displayedChildrenViewController) {
        displayedChildrenViewController = YES;
        childController.view.backgroundColor = [UIColor clearColor];
        childController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:childController animated:YES completion:nil];
    }
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    } completion:NULL];
}

@end
