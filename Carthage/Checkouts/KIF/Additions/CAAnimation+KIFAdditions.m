//
//  CAAnimation+KIFAdditions.m
//  Pods
//
//  Created by Justin Martin on 6/6/16.
//

#import "CAAnimation+KIFAdditions.h"


@implementation CAAnimation (KIFAdditions)

- (double)KIF_completionTime;
{
    if (self.repeatDuration > 0) {
        return self.beginTime + self.repeatDuration;
    } else if (self.repeatCount == HUGE_VALF) {
        return HUGE_VALF;
    } else if (self.repeatCount > 0) {
        return self.beginTime + (self.repeatCount * self.duration);
    } else {
        return self.beginTime + self.duration;
    }
}

@end
