//
//  ViewController.h
//  ImageAlignment
//
//  Created by Andrei Stanescu on 7/29/13.
//

#import <UIKit/UIKit.h>
#import "UIImageViewAligned.h"

@interface ViewController : UIViewController {
    NSArray* _contentModeStrings;
}
@property (weak, nonatomic) IBOutlet UIImageViewAligned *alignedImageView;

@property (weak, nonatomic) IBOutlet UISwitch *swLandscape;
@property (weak, nonatomic) IBOutlet UIButton *btnContentMode;
@property (weak, nonatomic) IBOutlet UISwitch *swAlignTop;
@property (weak, nonatomic) IBOutlet UISwitch *swAlignRight;
@property (weak, nonatomic) IBOutlet UISwitch *swAlignBottom;
@property (weak, nonatomic) IBOutlet UISwitch *swAlignLeft;

- (IBAction)onSwitchLandscape:(id)sender;
- (IBAction)onButtonContentMode:(id)sender;
- (IBAction)onSwitchAlignTop:(id)sender;
- (IBAction)onSwitchAlignRight:(id)sender;
- (IBAction)onSwitchAlignBottom:(id)sender;
- (IBAction)onSwitchAlignLeft:(id)sender;

@end
