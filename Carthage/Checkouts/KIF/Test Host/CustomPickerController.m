//
//  CustomPickerController.m
//  KIF
//
//  Created by Deepakkumar Sharma on 18/08/17.
//
//

#import <Foundation/Foundation.h>

#pragma mark PickerDelegate
@interface PickerDelegate : NSObject<UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate>

-(instancetype)initWithInputTextField:(UITextField*)textField;
@property (strong, nonatomic) UITextField *textField;

@end

@implementation PickerDelegate

-(instancetype)initWithInputTextField:(UITextField *)inputTextField {
    self = [super init];
    self.textField = inputTextField;
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 100;
}

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityLabelForComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            return @"red";
            break;
        case 1:
            return @"green";
            break;
        case 2:
            return @"blue";
            break;
        default:
            return nil;
            break;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSInteger red = [pickerView selectedRowInComponent:0];
    NSInteger green = [pickerView selectedRowInComponent:1];
    NSInteger blue = [pickerView selectedRowInComponent:2];
    NSString *text = [NSString stringWithFormat:@"%ld%ld%ld",(long)red,(long)green,(long)blue];
    [self.textField setText:text];
}

@end

#pragma mark CustomLabelPickerDelegate
@interface CustomLabelPickerDelegate : PickerDelegate

@end

@implementation CustomLabelPickerDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    if (view == nil) {
        view = [[UILabel alloc] init];
    }

    UILabel *label = (UILabel *)view;
    label.text = [NSString stringWithFormat:@"%ld", (long)row];
    label.textAlignment = NSTextAlignmentCenter;

    switch (component) {
        case 0:
            label.backgroundColor = [UIColor redColor];
            break;
        case 1:
            label.backgroundColor = [UIColor greenColor];
            break;
        case 2:
            label.backgroundColor = [UIColor blueColor];
            break;
        default:
            break;
    }

    return label;
}

@end

#pragma mark AttributedTitlePickerDelegate
@interface AttributedTitlePickerDelegate : PickerDelegate

@end

@implementation AttributedTitlePickerDelegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    UIColor *textColor;
    switch (component) {
        case 0:
            textColor = [UIColor redColor];
            break;
        case 1:
            textColor = [UIColor greenColor];
            break;
        case 2:
            textColor = [UIColor blueColor];
            break;
        default:
            textColor = [UIColor blackColor];
            break;
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentLeft;

    NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor};
    NSString *title = [NSString stringWithFormat:@"%ld", (long)row];

    return [[NSAttributedString alloc] initWithString:title attributes:attributes];
}

@end

#pragma mark TextTitlePickerDelegate
@interface TextTitlePickerDelegate : PickerDelegate

@end

@implementation TextTitlePickerDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", (long)row];
}

@end

#pragma mark CustomPickerController
@interface CustomPickerController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *customLabelSelectionTextField;
@property (weak, nonatomic) IBOutlet UITextField *attributedTitleSelectionTextField;
@property (weak, nonatomic) IBOutlet UITextField *textTitleSelectionTextField;
@property (strong, nonatomic) UIPickerView *customLabelPicker;
@property (strong, nonatomic) UIPickerView *attributedTitlePicker;
@property (strong, nonatomic) UIPickerView *textTitlePicker;
@property (strong, nonatomic) PickerDelegate *customLabelPickerDelegate;
@property (strong, nonatomic) PickerDelegate *attributedTitlePickerDelegate;
@property (strong, nonatomic) PickerDelegate *textTitlePickerDelegate;

@end

@implementation CustomPickerController

@synthesize customLabelPicker;
@synthesize customLabelSelectionTextField;
@synthesize attributedTitlePicker;
@synthesize attributedTitleSelectionTextField;
@synthesize textTitlePicker;
@synthesize textTitleSelectionTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    customLabelPicker = [[UIPickerView alloc] init];
    self.customLabelPickerDelegate = [[CustomLabelPickerDelegate alloc] initWithInputTextField:customLabelSelectionTextField];
    customLabelPicker.delegate = self.customLabelPickerDelegate;
    customLabelPicker.dataSource = self.customLabelPickerDelegate;

    customLabelSelectionTextField.placeholder = NSLocalizedString(@"Custom Label Selection", nil);
    customLabelSelectionTextField.inputView = customLabelPicker;
    customLabelSelectionTextField.accessibilityLabel = @"Custom Label Selection";

    attributedTitlePicker = [[UIPickerView alloc] init];
    self.attributedTitlePickerDelegate = [[AttributedTitlePickerDelegate alloc] initWithInputTextField:attributedTitleSelectionTextField];
    attributedTitlePicker.delegate = self.attributedTitlePickerDelegate;
    attributedTitlePicker.dataSource = self.attributedTitlePickerDelegate;

    attributedTitleSelectionTextField.placeholder = NSLocalizedString(@"Attributed Title Selection", nil);
    attributedTitleSelectionTextField.inputView = attributedTitlePicker;
    attributedTitleSelectionTextField.accessibilityLabel = @"Attributed Title Selection";

    textTitlePicker = [[UIPickerView alloc] init];
    self.textTitlePickerDelegate = [[TextTitlePickerDelegate alloc] initWithInputTextField:textTitleSelectionTextField];
    textTitlePicker.delegate = self.textTitlePickerDelegate;
    textTitlePicker.dataSource = self.textTitlePickerDelegate;

    textTitleSelectionTextField.placeholder = NSLocalizedString(@"Text Title Selection", nil);
    textTitleSelectionTextField.inputView = textTitlePicker;
    textTitleSelectionTextField.accessibilityLabel = @"Text Title Selection";
}

@end
