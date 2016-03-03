
@interface PickerController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate>

@property (weak, nonatomic, readonly) IBOutlet UITextField *dateSelectionTextField;
@property (weak, nonatomic, readonly) IBOutlet UITextField *dateTimeSelectionTextField;
@property (weak, nonatomic, readonly) IBOutlet UITextField *timeSelectionTextField;
@property (weak, nonatomic, readonly) IBOutlet UITextField *countdownSelectionTextField;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) UIDatePicker *dateTimePicker;
@property (strong, nonatomic) UIDatePicker *timePicker;
@property (strong, nonatomic) UIDatePicker *countdownPicker;
@property (strong, nonatomic) IBOutlet UIPickerView *phoneticPickerView;

@end

@implementation PickerController

@synthesize datePicker;
@synthesize dateTimePicker;
@synthesize countdownPicker;
@synthesize timePicker;
@synthesize dateSelectionTextField;
@synthesize dateTimeSelectionTextField;
@synthesize timeSelectionTextField;
@synthesize countdownSelectionTextField;
@synthesize phoneticPickerView;

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

    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(30, 215, 260, 35)];
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.hidden = NO;
    [datePicker addTarget:self action:@selector(datePickerChanged:)
              forControlEvents:UIControlEventValueChanged];
    [datePicker setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];

    dateSelectionTextField.placeholder = NSLocalizedString(@"Date Selection", nil);
    dateSelectionTextField.returnKeyType = UIReturnKeyDone;
    dateSelectionTextField.inputView = datePicker;
    dateSelectionTextField.accessibilityLabel = @"Date Selection";

    dateTimePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(30, 215, 260, 35)];
    dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [dateTimePicker addTarget:self action:@selector(dateTimePickerChanged:)
         forControlEvents:UIControlEventValueChanged];
    [dateTimePicker setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];

    dateTimeSelectionTextField.placeholder = NSLocalizedString(@"Date Time Selection", nil);
    dateTimeSelectionTextField.returnKeyType = UIReturnKeyDone;
    dateTimeSelectionTextField.inputView = dateTimePicker;
    dateTimeSelectionTextField.accessibilityLabel = @"Date Time Selection";

    timePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(30, 215, 260, 35)];
    timePicker.datePickerMode = UIDatePickerModeTime;
    [timePicker addTarget:self action:@selector(timePickerChanged:)
             forControlEvents:UIControlEventValueChanged];
    [timePicker setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];

    timeSelectionTextField.placeholder = NSLocalizedString(@"Time Selection", nil);
    timeSelectionTextField.returnKeyType = UIReturnKeyDone;
    timeSelectionTextField.inputView = timePicker;
    timeSelectionTextField.accessibilityLabel = @"Time Selection";

    countdownPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(30, 215, 260, 35)];
    countdownPicker.datePickerMode = UIDatePickerModeCountDownTimer;
    [countdownPicker addTarget:self action:@selector(countdownPickerChanged:)
         forControlEvents:UIControlEventValueChanged];
    [countdownPicker setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];

    countdownSelectionTextField.placeholder = NSLocalizedString(@"Countdown Selection", nil);
    countdownSelectionTextField.returnKeyType = UIReturnKeyDone;
    countdownSelectionTextField.inputView = countdownPicker;
    countdownSelectionTextField.accessibilityLabel = @"Countdown Selection";

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)datePickerChanged:(id)sender {
    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    NSString *string = [NSString stringWithFormat:@"%@",
                        [dateFormatter stringFromDate:datePicker.date]];
    self.dateSelectionTextField.text = string;
}

- (void)dateTimePickerChanged:(id)sender {
    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, hh:mm aa"];
    NSString *string = [NSString stringWithFormat:@"%@",
                        [dateFormatter stringFromDate:dateTimePicker.date]];
    self.dateTimeSelectionTextField.text = string;
}

- (void)timePickerChanged:(id)sender {
    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a"];
    NSString *string = [dateFormatter stringFromDate:self.timePicker.date];
    self.timeSelectionTextField.text = string;
}

- (void)countdownPickerChanged:(id)sender {
    self.countdownSelectionTextField.text = [NSString stringWithFormat:@"%f", self.countdownPicker.countDownDuration];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [@[@"Alpha", @"Bravo", @"Charlie"] objectAtIndex:row];
}

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityLabelForComponent:(NSInteger)component
{
    return @"Call Sign";
}

@end
