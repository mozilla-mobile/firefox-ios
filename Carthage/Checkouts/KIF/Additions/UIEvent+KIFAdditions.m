//
//  UIEvent+KIFAdditions.m
//  KIF
//
//  Created by Thomas on 3/1/15.
//
//

#import "UIEvent+KIFAdditions.h"
#import "LoadableCategory.h"
#import <mach/mach_time.h>

MAKE_CATEGORIES_LOADABLE(UIEvent_KIFAdditions)

/* IOKit Private Headers */
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif
typedef struct __IOHIDEvent * IOHIDEventRef;
typedef UInt32 IOOptionBits;
typedef uint32_t IOHIDDigitizerTransducerType;
void IOHIDEventAppendEvent(IOHIDEventRef event, IOHIDEventRef childEvent);
enum {
    kIOHIDDigitizerTransducerTypeStylus  = 0x20,
    kIOHIDDigitizerTransducerTypePuck,
    kIOHIDDigitizerTransducerTypeFinger,
    kIOHIDDigitizerTransducerTypeHand
};
enum {
    kIOHIDDigitizerEventRange                               = 0x00000001,
    kIOHIDDigitizerEventTouch                               = 0x00000002,
    kIOHIDDigitizerEventPosition                            = 0x00000004,
    kIOHIDDigitizerEventStop                                = 0x00000008,
    kIOHIDDigitizerEventPeak                                = 0x00000010,
    kIOHIDDigitizerEventIdentity                            = 0x00000020,
    kIOHIDDigitizerEventAttribute                           = 0x00000040,
    kIOHIDDigitizerEventCancel                              = 0x00000080,
    kIOHIDDigitizerEventStart                               = 0x00000100,
    kIOHIDDigitizerEventResting                             = 0x00000200,
    kIOHIDDigitizerEventSwipeUp                             = 0x01000000,
    kIOHIDDigitizerEventSwipeDown                           = 0x02000000,
    kIOHIDDigitizerEventSwipeLeft                           = 0x04000000,
    kIOHIDDigitizerEventSwipeRight                          = 0x08000000,
    kIOHIDDigitizerEventSwipeMask                           = 0xFF000000,
};
IOHIDEventRef IOHIDEventCreateDigitizerEvent(CFAllocatorRef allocator, AbsoluteTime timeStamp, IOHIDDigitizerTransducerType type,
                                             uint32_t index, uint32_t identity, uint32_t eventMask, uint32_t buttonMask,
                                             IOHIDFloat x, IOHIDFloat y, IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat barrelPressure,
                                             Boolean range, Boolean touch, IOOptionBits options);
IOHIDEventRef IOHIDEventCreateDigitizerFingerEventWithQuality(CFAllocatorRef allocator, AbsoluteTime timeStamp,
                                                              uint32_t index, uint32_t identity, uint32_t eventMask,
                                                              IOHIDFloat x, IOHIDFloat y, IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat twist,
                                                              IOHIDFloat minorRadius, IOHIDFloat majorRadius, IOHIDFloat quality, IOHIDFloat density, IOHIDFloat irregularity,
                                                              Boolean range, Boolean touch, IOOptionBits options);

/* END of IOKit Private Headers */

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
    
}

- (void)kif_setIOHIDEventWithTouches:(NSArray *)touches
{
    uint64_t abTime = mach_absolute_time();
    AbsoluteTime timeStamp = *(AbsoluteTime *) &abTime;
    
    IOHIDEventRef handEvent = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, timeStamp, kIOHIDDigitizerTransducerTypeHand, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    
    for (UITouch *touch in touches)
    {
        uint32_t eventMask = (touch.phase == UITouchPhaseMoved) ? kIOHIDDigitizerEventPosition : (kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch);
        uint32_t isTouching = (touch.phase == UITouchPhaseEnded) ? 0 : 1;
        
        CGPoint touchLocation = [touch locationInView:touch.window];
        
        IOHIDEventRef fingerEvent = IOHIDEventCreateDigitizerFingerEventWithQuality(kCFAllocatorDefault, timeStamp,
                                                                                    (UInt32)[touches indexOfObject:touch], 2,
                                                                                    eventMask, (IOHIDFloat)touchLocation.x, (IOHIDFloat)touchLocation.y,
                                                                                    0, 0, 0, 0, 0, 0, 0, 0,
                                                                                    (IOHIDFloat)isTouching, (IOHIDFloat)isTouching, 0);
        IOHIDEventAppendEvent(handEvent, fingerEvent);
    }
    
    [self _setHIDEvent:handEvent];
}

@end