/*
     File: WeightConverterViewController.m 
 Abstract: View controller to manage conversion of metric to imperial units of weight and vice versa.
 The controller uses two UIPicker objects to allow the user to select the weight in metric or imperial units.
  
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

#import "WeightConverterViewController.h"

#import "MetricPickerController.h"
#import "ImperialPickerController.h"

@interface WeightConverterViewController ()

@property (nonatomic, assign) NSUInteger selectedUnit;

@end

@implementation WeightConverterViewController

#define METRIC_INDEX 0
#define IMPERIAL_INDEX 1

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.navigationItem.title = @"Weight";
	
	// Set the currently-selected unit for self and the segmented control
	_selectedUnit = METRIC_INDEX;
	_segmentedControl.selectedSegmentIndex = _selectedUnit;
	
	[self toggleUnit];
}


- (void)viewDidUnload {    
	self.pickerViewContainer = nil;
	
	self.metricPickerController = nil;
	self.metricPickerViewContainer = nil;
	
	self.imperialPickerController = nil;
	self.imperialPickerViewContainer = nil;
	
	self.segmentedControl = nil;

	[super viewDidUnload];
}


- (IBAction)toggleUnit {
	
	/*
	 When the user changes the selection in the segmented control, set the appropriate picker as the current subview of the picker container view (and remove the previous one).
	 */
	_selectedUnit = [_segmentedControl selectedSegmentIndex];
	if (_selectedUnit == IMPERIAL_INDEX) {
		[_metricPickerViewContainer removeFromSuperview];
		[_pickerViewContainer addSubview:_imperialPickerViewContainer];
		[_imperialPickerController updateLabel];
	} else {
		[_imperialPickerViewContainer removeFromSuperview];
		[_pickerViewContainer addSubview:_metricPickerViewContainer];
		[_metricPickerController updateLabel];
	}
}

@end

