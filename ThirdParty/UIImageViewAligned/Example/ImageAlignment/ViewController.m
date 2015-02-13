//
//  ViewController.m
//  ImageAlignment
//
//  Created by Andrei Stanescu on 7/29/13.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _contentModeStrings = [NSArray arrayWithObjects:
                                        @"UIViewContentModeScaleToFill",
                                        @"UIViewContentModeScaleAspectFit",      // contents scaled to fit with fixed aspect. remainder is transparent
                                        @"UIViewContentModeScaleAspectFill",     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
                                        @"UIViewContentModeRedraw",              // redraw on bounds change (calls -setNeedsDisplay)
                                        @"UIViewContentModeCenter",              // contents remain same size. positioned adjusted.
                                        @"UIViewContentModeTop",
                                        @"UIViewContentModeBottom",
                                        @"UIViewContentModeLeft",
                                        @"UIViewContentModeRight",
                                        @"UIViewContentModeTopLeft",
                                        @"UIViewContentModeTopRight",
                                        @"UIViewContentModeBottomLeft",
                                        @"UIViewContentModeBottomRight", nil];
    
    _swLandscape.on = (_alignedImageView.image != nil) && _alignedImageView.image.size.width >= _alignedImageView.image.size.height;
    
    _swAlignLeft.on = _alignedImageView.alignLeft;
    _swAlignRight.on = _alignedImageView.alignRight;
    _swAlignTop.on = _alignedImageView.alignTop;
    _swAlignBottom.on = _alignedImageView.alignBottom;
    
    [self refreshContentModeButtonTitle];
}

- (IBAction)onSwitchLandscape:(id)sender {
    if (_swLandscape.on)
        _alignedImageView.image = [UIImage imageNamed:@"melinda_landscape.jpg"];
    else
        _alignedImageView.image = [UIImage imageNamed:@"melinda_portrait.jpg"];
}

- (IBAction)onButtonContentMode:(id)sender
{
    _alignedImageView.contentMode = (_alignedImageView.contentMode + 1) % (UIViewContentModeBottomRight+1);  // bit of hardcoding..but only for the purposes of this example
    [self refreshContentModeButtonTitle];
}

- (IBAction)onSwitchAlignTop:(id)sender {
    _alignedImageView.alignTop
    = _swAlignTop.on;
}

- (IBAction)onSwitchAlignRight:(id)sender {
    _alignedImageView.alignRight = _swAlignRight.on;
}

- (IBAction)onSwitchAlignBottom:(id)sender {
    _alignedImageView.alignBottom = _swAlignBottom.on;
}

- (IBAction)onSwitchAlignLeft:(id)sender {
    _alignedImageView.alignLeft = _swAlignLeft.on;
}

- (void)refreshContentModeButtonTitle
{
    [_btnContentMode setTitle:_contentModeStrings[_alignedImageView.contentMode] forState:UIControlStateNormal];
}
@end
