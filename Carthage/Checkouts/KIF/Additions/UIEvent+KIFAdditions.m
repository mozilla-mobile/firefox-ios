//
//  UIEvent+KIFAdditions.m
//  KIF
//
//  Created by Thomas on 3/1/15.
//
//

#import "UIEvent+KIFAdditions.h"
#import "LoadableCategory.h"
#import "IOHIDEvent+KIF.h"

MAKE_CATEGORIES_LOADABLE(UIEvent_KIFAdditions)

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface KIFGSEventProxy : NSObject
{
@public
    unsigned int flags;
    unsigned int type;
    unsigned int ignored1;
    float x1;
    float y1;
    float x2;
    float y2;
    unsigned int ignored2[10];
    unsigned int ignored3[7];
    float sizeX;
    float sizeY;
    float x3;
    float y3;
    unsigned int ignored4[3];
}
@end

@implementation KIFGSEventProxy
@end

typedef struct __GSEvent * GSEventRef;

@interface UIEvent (KIFAdditionsMorePrivateHeaders)
- (void)_setGSEvent:(GSEventRef)event;
- (void)_setHIDEvent:(IOHIDEventRef)event;
- (void)_setTimestamp:(NSTimeInterval)timestemp;
@end

@implementation UIEvent (KIFAdditions)

- (void)kif_setEventWithTouches:(NSArray *)touches
{
    NSOperatingSystemVersion iOS8 = {8, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]
        && [[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS8]) {
        [self kif_setIOHIDEventWithTouches:touches];
    } else {
        [self kif_setGSEventWithTouches:touches];
    }
}

- (void)kif_setGSEventWithTouches:(NSArray *)touches
{
    UITouch *touch = touches[0];
    CGPoint location = [touch locationInView:touch.window];
    KIFGSEventProxy *gsEventProxy = [[KIFGSEventProxy alloc] init];
    gsEventProxy->x1 = location.x;
    gsEventProxy->y1 = location.y;
    gsEventProxy->x2 = location.x;
    gsEventProxy->y2 = location.y;
    gsEventProxy->x3 = location.x;
    gsEventProxy->y3 = location.y;
    gsEventProxy->sizeX = 1.0;
    gsEventProxy->sizeY = 1.0;
    gsEventProxy->flags = ([touch phase] == UITouchPhaseEnded) ? 0x1010180 : 0x3010180;
    gsEventProxy->type = 3001;
    
    [self _setGSEvent:(GSEventRef)gsEventProxy];
    
    [self _setTimestamp:(((UITouch*)touches[0]).timestamp)];
}

- (void)kif_setIOHIDEventWithTouches:(NSArray *)touches
{
    IOHIDEventRef event = kif_IOHIDEventWithTouches(touches);
    [self _setHIDEvent:event];
    CFRelease(event);
}

@end