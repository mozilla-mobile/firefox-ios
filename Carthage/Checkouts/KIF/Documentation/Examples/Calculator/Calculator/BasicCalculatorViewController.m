//
//  ViewController.m
//  Calculator
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "BasicCalculatorViewController.h"

typedef NS_ENUM(NSInteger, CalculatorOperation) {
    Add,
    Subtract,
    Multiply,
    Divide
};

@interface BasicCalculatorViewController ()

@property (weak, nonatomic) IBOutlet UITextField *input1;
@property (weak, nonatomic) IBOutlet UITextField *input2;
@property (weak, nonatomic) IBOutlet UISegmentedControl *operationInput;
@property (weak, nonatomic) IBOutlet UILabel *output;

@end

@implementation BasicCalculatorViewController

- (id)init
{
    self = [super initWithNibName:@"BasicCalculatorViewController" bundle:nil];
    if (self) {
        self.title = @"Basic Calculator";
    }
    return self;
}

- (void)setAccessibilityLabel:(NSString *)label forSegment:(NSInteger)segment
{
    UIView *view = (self.operationInput.subviews)[self.operationInput.subviews.count - segment - 1];
    view.accessibilityLabel = label;
}

- (void)viewDidLoad
{
    [self setAccessibilityLabel:@"Add" forSegment:Add];
    [self setAccessibilityLabel:@"Subtract" forSegment:Subtract];
    [self setAccessibilityLabel:@"Multiply" forSegment:Multiply];
    [self setAccessibilityLabel:@"Divide" forSegment:Divide];
}

- (IBAction)recalculate
{
    double value1 = self.input1.text.doubleValue;
    double value2 = self.input2.text.doubleValue;
    double output;
    
    switch ((CalculatorOperation)self.operationInput.selectedSegmentIndex) {
        case Add:
            output = value1 + value2;
            break;
        case Subtract:
            output = value1 - value2;
            break;
        case Multiply:
            output = value1 * value2;
            break;
        case Divide:
            output = value1 / value2;
            break;
    }
    
    self.output.text = [NSString stringWithFormat:@"%.8f", output];
}

@end
