//
//  BackgroundViewController.m
//  KIF
//
//  Created by Jordan Zucker on 5/18/15.
//
//

@interface BackgroundViewController : UIViewController
@property (nonatomic, weak) IBOutlet UILabel *label;
@end

@implementation BackgroundViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    self.label.isAccessibilityElement = YES;
    self.label.text = @"Start";
    self.label.accessibilityLabel = self.label.text;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    self.label.text = @"Back";
    self.label.accessibilityLabel = self.label.text;
}

@end
