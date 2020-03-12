//
//  TapViewController.m
//  Test Suite
//
//  Created by Brian Nickel on 6/26/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TapViewController : UIViewController<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *lineBreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *memoryWarningLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectedPhotoClass;
@property (weak, nonatomic) IBOutlet UITextField *otherTextField;
@property (weak, nonatomic) IBOutlet UITextField *greetingTextField;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UILabel *stepperValueLabel;
@end

@implementation TapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:[UIApplication sharedApplication]];
    self.lineBreakLabel.accessibilityLabel = @"A\nB\nC\n\n";
	self.stepper.isAccessibilityElement = YES;
	self.stepper.accessibilityLabel = @"theStepper";
}

- (void)memoryWarningNotification:(NSNotification *)notification
{
    self.memoryWarningLabel.hidden = NO;
}

- (IBAction)hideMemoryWarning
{
    self.memoryWarningLabel.hidden = YES;
}

- (IBAction)toggleSelected:(UIButton *)sender
{
    sender.selected = !sender.selected;
    self.slider.value = self.slider.value + 1;
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.slider.value = self.slider.value - 1;
    });
}

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    sender.accessibilityValue = [NSString stringWithFormat:@"%d", (int)roundf(sender.value)];
}

- (IBAction)pickPhoto:(id)sender
{
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)stepperValueChanged:(UIStepper *)sender forEvent:(UIEvent *)event
{
	self.stepperValueLabel.text = [NSString stringWithFormat:@"%ld", (long)sender.value];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField == self.otherTextField) {
        [self.greetingTextField becomeFirstResponder];
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.otherTextField && range.length != 0) {
        self.greetingTextField.text = @"Deleted something.";
    }
    
    return YES;
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.selectedPhotoClass.text = NSStringFromClass([info[UIImagePickerControllerOriginalImage] class]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
