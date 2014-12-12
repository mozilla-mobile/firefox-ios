/*
     File: MetricPickerController.m 
 Abstract: Controller to managed a picker view displaying metric weights.
  
  Version: 1.4 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "MetricPickerController.h"

@implementation MetricPickerController

// Identifiers and widths for the various components
#define KG_COMPONENT 0
#define KG_COMPONENT_WIDTH 88
#define KG0_LABEL_WIDTH 46

#define G0_COMPONENT 3
#define G0_COMPONENT_WIDTH 74
#define G0_LABEL_WIDTH 44

#define G_COMPONENT_WIDTH 50

// Identifies for component views
#define VIEW_TAG 41
#define SUB_LABEL_TAG 42
#define LABEL_TAG 43

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	
	return 4;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	
	// Number of rows depends on the currently-selected unit and the component.
    if (component == KG_COMPONENT) {
        return 20;
    }
    return 10;
}


- (UIView *)labelCellWidth:(CGFloat)width rightOffset:(CGFloat)offset {
	
	// Create a new view that contains a label offset from the right.
	CGRect frame = CGRectMake(0.0, 0.0, width, 32.0);
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.tag = VIEW_TAG;
	
	frame.size.width = width - offset;
	UILabel *subLabel = [[UILabel alloc] initWithFrame:frame];
	subLabel.textAlignment = NSTextAlignmentRight;
	subLabel.backgroundColor = [UIColor clearColor];
	subLabel.font = [UIFont systemFontOfSize:24.0];
	subLabel.userInteractionEnabled = NO;
	
	subLabel.tag = SUB_LABEL_TAG;
	
	[view addSubview:subLabel];

	return view;
}


- (UIView *)viewForComponent:(NSInteger)component {
	
	/*
	 Return a view appropriate for the specified picker view and component.
	 If it's the picker view, or if it's the kg or g component of the metric view, create a UIView that contains a label.  The label can then be offset in the containing view so that its text does not overlap the unit symbol.
	 For the remaining components, simple create a label to contain the text.
	 Give all the views tags so they can be idntified easily.
	 */
	
	if (component == KG_COMPONENT) {		
		return [self labelCellWidth:KG_COMPONENT_WIDTH rightOffset:KG0_LABEL_WIDTH];
	}
    
	if (component == G0_COMPONENT) {
		return [self labelCellWidth:G0_COMPONENT_WIDTH rightOffset:G0_LABEL_WIDTH];
	}
	
	CGRect frame = CGRectMake(0.0, 0.0, 36.0, 32.0);
	UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
	aLabel.textAlignment = NSTextAlignmentCenter;
	aLabel.backgroundColor = [UIColor clearColor];
	aLabel.font = [UIFont systemFontOfSize:24.0];
	aLabel.userInteractionEnabled = NO;
	aLabel.tag = LABEL_TAG;
	return aLabel;
}


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
	
	UIView *returnView = nil;
	
	// Reuse the label if possible, otherwise create and configure a new one.
	if ((view.tag == VIEW_TAG) || (view.tag == LABEL_TAG)) {
		returnView = view;
	}
	else {
		returnView = [self viewForComponent:component];
	}
	
	// The text shown in the component is just the number of the component.
	NSString *text = [NSString stringWithFormat:@"%zd", row];
	
	// Where to set the text in depends on what sort of view it is.
	UILabel *theLabel = nil;
	if (returnView.tag == VIEW_TAG) {
		theLabel = (UILabel *)[returnView viewWithTag:SUB_LABEL_TAG];
	}
	else {
		theLabel = (UILabel *)returnView;
	}
    
	theLabel.text = text;
	return returnView;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	
	// The width of the component depends on the currently-selected unit and the component.
    
    if (component == KG_COMPONENT) {
        return KG_COMPONENT_WIDTH;
    }
    if (component == G0_COMPONENT) {
        return G0_COMPONENT_WIDTH;
    }
    return G_COMPONENT_WIDTH;	
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	// If the user chooses a new row, update the label accordingly.
	[self updateLabel];
}


- (void)updateLabel {
	
    /*
     If the user has entered metric units, find the number of grams and convert that to pounds and ounces.
     Don't display 0 lbs; round 15.95 ounces up to 1 lb, and use NSDecimalNumberHandler to round ounces for a more attractive display.
     */
    
    static NSDecimalNumberHandler* roundingBehavior = nil;
    
    if (roundingBehavior == nil) {
        roundingBehavior = 
        [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundPlain scale:1 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    }		
    
    NSInteger grams = 0;
    grams += [self.pickerView selectedRowInComponent:3];
    grams += [self.pickerView selectedRowInComponent:2] * 10;
    grams += [self.pickerView selectedRowInComponent:1] * 100;
    grams += [self.pickerView selectedRowInComponent:0] * 1000;
    
    NSDecimalNumber *ouncesDecimal;
    NSDecimalNumber *roundedOunces;
    
    float ounces = grams / 28.349;
    
    if (ounces >= 15.95) {
        NSInteger lbs = ounces / 16;
        ounces -= lbs * 16;
        if (ounces >= 15.95) {
            ounces = 0;
            lbs += 1;
        }
        ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:ounces];
        roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
        self.label.text = [NSString stringWithFormat:@"%zd lbs  %@ oz", lbs, roundedOunces];
    }
    else {
        ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:ounces];
        roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
        self.label.text = [NSString stringWithFormat:@"%@ oz", roundedOunces];
    }
}

@end
