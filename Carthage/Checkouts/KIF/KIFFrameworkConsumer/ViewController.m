//
//  ViewController.m
//  KIFFrameworkConsumer
//
//  Created by Alex Odawa on 3/30/16.
//
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)buttonTapped:(id)sender {
    [self.label performSelector:@selector(setText:) withObject:@"Tapped" afterDelay:0.5];
}

@end
