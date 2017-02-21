#import "BTNModelObject.h"
#import "BTNText.h"
@import UIKit;

/**
 BTNImage objects represent an image and how it should be rendered.
 */
@interface BTNImage : BTNModelObject

/// The URL of an image to be retrieved.
@property (nullable, nonatomic, copy, readonly) NSURL *URL;


/// The fill mode of an image (aspect fit or aspect fill).
@property (nonatomic, assign, readonly) UIViewContentMode fillMode;


/// Alternative text for the image.
@property (nullable, nonatomic, copy, readonly) BTNText *altText;

@end
