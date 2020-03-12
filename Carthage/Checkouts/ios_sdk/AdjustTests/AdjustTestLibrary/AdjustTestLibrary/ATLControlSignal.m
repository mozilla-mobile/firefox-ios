//
//  ATLControlSignal.m
//  AdjustTestLibrary
//
//  Created by Serj on 20.02.19.
//  Copyright © 2019 adjust. All rights reserved.
//

#import "ATLControlSignal.h"
#import "ATLConstants.h"
#import "ATLUtil.h"

@interface ATLControlSignal()

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *value;

@end

@implementation ATLControlSignal

- (id)initWithSignalType:(ATLSignalType)signalType{
    self = [super init];
    if (self == nil) return nil;
    
    self.type = [self getSignalTypeString:signalType];
    self.value = @"n/a";
    
    return self;
}

- (id)initWithSignalType:(ATLSignalType)signalType
          andSignalValue:(NSString *)signalValue
{
    self = [super init];
    if (self == nil) return nil;
    
    self.type = [self getSignalTypeString:signalType];
    self.value = signalValue;
    
    return self;
}

- (id)initWithJson:(NSString*)json {
    self = [super init];
    if (self == nil) return nil;
    
    NSError *error = nil;
    id jsonFoundation = nil;
    @try {
        NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        jsonFoundation = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error != nil) {
            [ATLUtil debug:@"Failed to init CcontrolSignal from json: [%@]. Details: %@", json, error.description];
            self.type = SIGNAL_UNKNOWN;
            self.value = @"n/a";
        } else {
            NSDictionary *controlSignalMap = (NSDictionary*)jsonFoundation;
            NSString* signalType = controlSignalMap[@"type"];
            if ([self getSignalTypeByString:signalType] == ATLSignalTypeUnknown) {
                [ATLUtil debug:@"Failed to init CcontrolSignal from json: [%@]. Received unknown signal type: [%@]", json, signalType];
                self.type = SIGNAL_UNKNOWN;
                self.value = @"n/a";
            } else {
                self.type = signalType;
                self.value = controlSignalMap[@"value"];
            }
        }
    } @catch (NSException *ex) {
        [ATLUtil debug:@"Failed to init CcontrolSignal from json: [%@]. Details: %@", json, ex.description];
    }
    
    return self;
}

- (NSString*)toJson {
    id objects[] = { self.type, self.value };
    id keys[] = { @"type", @"value" };
    NSUInteger count = sizeof(objects) / sizeof(id);
    NSDictionary *signalParamsMap = [NSDictionary dictionaryWithObjects:objects
                                                           forKeys:keys
                                                             count:count];
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:signalParamsMap options:NSJSONWritingPrettyPrinted error:&writeError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString*)getValue {
    return self.value;
}

- (ATLSignalType)getType {
    return [self getSignalTypeByString:self.type];
}

- (NSString*)getSignalTypeString:(ATLSignalType)signalType {
    switch (signalType) {
        case ATLSignalTypeInfo:
            return SIGNAL_INFO;
        case ATLSignalTypeEndWait:
            return SIGNAL_END_WAIT;
        case ATLSignalTypeUnknown:
            return SIGNAL_UNKNOWN;
        case ATLSignalTypeInitTestSession:
            return SIGNAL_INIT_TEST_SESSION;
        case ATLSignalTypeCancelCurrentTest:
            return SIGNAL_CANCEL_CURRENT_TEST;
        default:
            return SIGNAL_UNKNOWN;
    }
}

- (ATLSignalType)getSignalTypeByString:(NSString*)signalType {
    if ([signalType isEqualToString:SIGNAL_INFO]) {
        return ATLSignalTypeInfo;
    } else if ([signalType isEqualToString:SIGNAL_END_WAIT]) {
        return ATLSignalTypeEndWait;
    } else if ([signalType isEqualToString:SIGNAL_CANCEL_CURRENT_TEST]) {
        return ATLSignalTypeCancelCurrentTest;
    } else if ([signalType isEqualToString:SIGNAL_INIT_TEST_SESSION]) {
        return ATLSignalTypeInitTestSession;
    }
    return ATLSignalTypeUnknown;
}

@end
