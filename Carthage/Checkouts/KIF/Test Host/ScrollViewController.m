//
//  ScrollViewController.m
//  KIF
//
//  Created by Hilton Campbell on 2/20/14.
//
//

#import <UIKit/UIKit.h>

@interface ScrollViewController : UIViewController<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation ScrollViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.scrollView.accessibilityLabel = @"Scroll View";
    self.scrollView.contentSize = CGSizeMake(2000, 2000);
    self.scrollView.delegate = self;
    
    UIButton *bottomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [bottomButton setTitle:@"Down" forState:UIControlStateNormal];
    bottomButton.backgroundColor = [UIColor greenColor];
    bottomButton.frame = CGRectMake(1000, 1500, 100, 50);
    [self.scrollView addSubview:bottomButton];
    
    UIButton *upButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [upButton setTitle:@"Up" forState:UIControlStateNormal];
    upButton.backgroundColor = [UIColor greenColor];
    upButton.frame = CGRectMake(1000, 500, 100, 50);
    [self.scrollView addSubview:upButton];
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [rightButton setTitle:@"Right" forState:UIControlStateNormal];
    rightButton.backgroundColor = [UIColor greenColor];
    rightButton.frame = CGRectMake(1500, 1000, 100, 50);
    [self.scrollView addSubview:rightButton];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [leftButton setTitle:@"Left" forState:UIControlStateNormal];
    leftButton.backgroundColor = [UIColor greenColor];
    leftButton.frame = CGRectMake(500, 1000, 100, 50);
    [self.scrollView addSubview:leftButton];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(1500, 1500, 100, 100)];
    textView.backgroundColor = [UIColor redColor];
    textView.accessibilityLabel = @"TextView";
    [self.scrollView addSubview:textView];
}

#pragma mark UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return scrollView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    // do nothing
}


@end
