//
//  GestureViewController.m
//  KIF
//
//  Created by Brian Nickel on 7/28/13.
//
//

#import <UIKit/UIKit.h>

@interface GestureViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *lastSwipeDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastVelocityVeluesLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomRightLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *panAreaLabel;

@end

@implementation GestureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.contentSize = CGRectUnion(self.scrollView.bounds, self.bottomRightLabel.frame).size;
}

- (IBAction)swipedUp:(id)sender
{
    self.lastSwipeDescriptionLabel.text = @"Up";
}

- (IBAction)swipedDown:(id)sender
{
    self.lastSwipeDescriptionLabel.text = @"Down";
}

- (IBAction)swipedLeft:(id)sender
{
    self.lastSwipeDescriptionLabel.text = @"Left";
}

- (IBAction)swipedRight:(id)sender
{
    self.lastSwipeDescriptionLabel.text = @"Right";
}

- (IBAction)hadlePanGestureRecognizer:(UIPanGestureRecognizer *)sender
{
    self.lastVelocityVeluesLabel.text = [self formattedVelocityValues:[sender velocityInView:self.panAreaLabel]];
}

- (NSString*)formattedVelocityValues:(CGPoint)velocity
{
    return [NSString stringWithFormat:@"X:%.2f Y:%.2f", velocity.x, velocity.y];
}

@end
