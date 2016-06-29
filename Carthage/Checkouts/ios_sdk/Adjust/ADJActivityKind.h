//
//  ADJActivityKind.h
//  Adjust
//
//  Created by Christian Wellenbrock on 11.02.14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

typedef NS_ENUM(int, ADJActivityKind) {
    ADJActivityKindUnknown       = 0,
    ADJActivityKindSession       = 1,
    ADJActivityKindEvent         = 2,
//    ADJActivityKindRevenue       = 3,
    ADJActivityKindClick         = 4,
    ADJActivityKindAttribution   = 5,
};

@interface ADJActivityKindUtil : NSObject

+ (ADJActivityKind)activityKindFromString:(NSString *)activityKindString;
+ (NSString*)activityKindToString:(ADJActivityKind)activityKind;

@end
