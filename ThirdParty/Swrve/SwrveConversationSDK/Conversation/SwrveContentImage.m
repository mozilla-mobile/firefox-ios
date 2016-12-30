#import "SwrveContentImage.h"

@interface SwrveContentImage () {
    UIImageView *iv;
    UIImage* image;
}
@end

@implementation SwrveContentImage

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeImage andDictionary:dict];
    return self;
}

-(void) loadViewWithContainerView:(UIView*)containerView {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString* swrve_folder = @"com.ngt.msgs";
        NSURL* bgurl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cache, swrve_folder, self.value, nil]];
        self->image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:bgurl]];
        [self sizeAndDisplayInContainer:containerView];
    });
}

- (void)sizeAndDisplayInContainer:(UIView*)containerView
{
    if (image != nil) {
        // Create _view and add image to it
        _view = iv = [[UIImageView alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Image setting and manipulation should be done on the main thread, otherwise this slows down a lot on iOS 7
            self->iv.image = self->image;
            CGFloat containerWidth = containerView.frame.size.width;
            CGSize imageSize = self->image.size;
            self->iv.frame = CGRectMake(0, 0, containerWidth, ((imageSize.height/imageSize.width)*containerWidth));
            // Notify that the view is ready to be displayed
            [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
        });
    }
}

// Respond to device orientation changes by resizing the width of the view
// Subviews of this should be flexible using AutoResizing masks
-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
    #pragma unused(orientation)
    _view.frame = [self newFrameForOrientationChange];
}

// iOS8+
-(void)viewWillTransitionToSize:(CGSize)size
{
    // Mantain full width
    CGSize imageSize = image.size;
    self->iv.frame = CGRectMake(0, 0, size.width, ((imageSize.height/imageSize.width)*size.width));
}

@end
