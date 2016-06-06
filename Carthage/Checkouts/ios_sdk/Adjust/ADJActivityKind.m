//
//  ADJActivityKind.m
//  Adjust
//
//  Created by Christian Wellenbrock on 11.02.14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJActivityKind.h"

@implementation ADJActivityKindUtil

+ (ADJActivityKind)activityKindFromString:(NSString *)activityKindString {
    if ([@"session" isEqualToString:activityKindString]) {
        return ADJActivityKindSession;
    } else if ([@"event" isEqualToString:activityKindString]) {
        return ADJActivityKindEvent;
    } else if ([@"click" isEqualToString:activityKindString]) {
        return ADJActivityKindClick;
    } else if ([@"attribution" isEqualToString:activityKindString]) {
        return ADJActivityKindAttribution;
    } else {
        return ADJActivityKindUnknown;
    }
}

+ (NSString*)activityKindToString:(ADJActivityKind)activityKind {
    switch (activityKind) {
        case ADJActivityKindSession:       return @"session";
        case ADJActivityKindEvent:         return @"event";
        case ADJActivityKindClick:         return @"click";
        case ADJActivityKindAttribution:   return @"attribution";
        default:                           return @"unknown";
    }
}

@end
