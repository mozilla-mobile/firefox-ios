//
//  ADJActivityPackage.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityKind.h"
#import "ADJActivityPackage.h"

@implementation ADJActivityPackage

#pragma mark - Public methods

- (NSString *)extendedString {
    NSMutableString *builder = [NSMutableString string];
    NSArray *excludedKeys = @[@"secret_id", @"app_secret", @"event_callback_id"];

    [builder appendFormat:@"Path:      %@\n", self.path];
    [builder appendFormat:@"ClientSdk: %@\n", self.clientSdk];

    if (self.parameters != nil) {
        NSArray *sortedKeys = [[self.parameters allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        NSUInteger keyCount = [sortedKeys count];

        [builder appendFormat:@"Parameters:"];
        
        for (NSUInteger i = 0; i < keyCount; i++) {
            NSString *key = (NSString *)[sortedKeys objectAtIndex:i];

            if ([excludedKeys containsObject:key]) {
                continue;
            }

            NSString *value = [self.parameters objectForKey:key];
            
            [builder appendFormat:@"\n\t\t%-22s %@", [key UTF8String], value];
        }
    }

    return builder;
}

- (NSInteger)getRetries {
    return self.retries;
}

- (NSInteger)increaseRetries {
    self.retries = self.retries + 1;
    
    return self.retries;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@%@", [ADJActivityKindUtil activityKindToString:self.activityKind], self.suffix];
}

- (NSString *)successMessage {
    return [NSString stringWithFormat:@"Tracked %@%@", [ADJActivityKindUtil activityKindToString:self.activityKind], self.suffix];
}

- (NSString *)failureMessage {
    return [NSString stringWithFormat:@"Failed to track %@%@", [ADJActivityKindUtil activityKindToString:self.activityKind], self.suffix];
}

#pragma mark - NSCoding protocol methods

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];

    if (self == nil) {
        return self;
    }

    self.path = [decoder decodeObjectForKey:@"path"];
    self.suffix = [decoder decodeObjectForKey:@"suffix"];
    self.clientSdk = [decoder decodeObjectForKey:@"clientSdk"];
    self.parameters = [decoder decodeObjectForKey:@"parameters"];
    self.partnerParameters = [decoder decodeObjectForKey:@"partnerParameters"];
    self.callbackParameters = [decoder decodeObjectForKey:@"callbackParameters"];

    NSString *kindString = [decoder decodeObjectForKey:@"kind"];
    self.activityKind = [ADJActivityKindUtil activityKindFromString:kindString];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    NSString *kindString = [ADJActivityKindUtil activityKindToString:self.activityKind];

    [encoder encodeObject:self.path forKey:@"path"];
    [encoder encodeObject:kindString forKey:@"kind"];
    [encoder encodeObject:self.suffix forKey:@"suffix"];
    [encoder encodeObject:self.clientSdk forKey:@"clientSdk"];
    [encoder encodeObject:self.parameters forKey:@"parameters"];
    [encoder encodeObject:self.callbackParameters forKey:@"callbackParameters"];
    [encoder encodeObject:self.partnerParameters forKey:@"partnerParameters"];
}

@end
