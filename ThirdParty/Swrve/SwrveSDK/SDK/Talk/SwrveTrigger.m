#import "SwrveTrigger.h"
#import "SwrveTriggerCondition.h"

@implementation SwrveTrigger

@synthesize eventName = _eventName;
@synthesize conditions = _conditions;
@synthesize isValidTrigger = _isValidTrigger;

#pragma mark - public function

+ (NSArray *) initTriggersFromDictionary:(NSDictionary *)dictionary {
    
    NSArray* jsonTriggers = [dictionary objectForKey:kTriggerEventListKey];
    if(!jsonTriggers){
        return nil;
    }

    NSMutableArray *resultantTriggers = [[NSMutableArray alloc] init];
    for (NSDictionary* trigger in jsonTriggers){
        if (trigger) {
            SwrveTrigger *swrveTrigger = [[SwrveTrigger alloc] initWithDictionary:trigger];
            if(swrveTrigger) {
                [resultantTriggers addObject:swrveTrigger];
            }
        }
    }
    return resultantTriggers;
}

#pragma mark - private functions

- (id) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if(self) {
        _isValidTrigger = YES;
        _eventName = [[dictionary objectForKey:kTriggerEventNameKey] lowercaseString];
        _conditions = [self produceConditionsFromDictionary: [dictionary objectForKey:kTriggerEventConditionsKey]];
    }
    
    if(_isValidTrigger){
        return self;
    }else{
        return nil;
    }
}

- (NSArray *) produceConditionsFromDictionary:(NSDictionary *) dictionary {
    
    NSMutableArray *resultantConditions = [[NSMutableArray alloc] init];
    NSString *triggerOperator = [dictionary objectForKey:@"op"];
    
    if(![dictionary count]){
        return nil;
    }
    
    if([triggerOperator isEqualToString:@"eq"]) {

        SwrveTriggerCondition *condition = [[SwrveTriggerCondition alloc] initWithDictionary:dictionary andOperator:nil];
        if(condition) {
            [resultantConditions addObject:condition];
        } else {
            _isValidTrigger = NO;
            return nil;
        }
    } else if([triggerOperator isEqualToString:@"and"]) {

        NSDictionary *arguments = [dictionary objectForKey:@"args"];
        if(!arguments){
            _isValidTrigger = NO;
            return nil;
        }
        
        for(NSDictionary *triggerCondition in arguments) {
            
            SwrveTriggerCondition *condition = [[SwrveTriggerCondition alloc] initWithDictionary:triggerCondition andOperator:triggerOperator];
            if (condition) {
                [resultantConditions addObject:condition];
            }
        }
    } else {
        _isValidTrigger = NO;
        return nil;
    }
    
    for (SwrveTriggerCondition *condition in resultantConditions) {
        
        switch (condition.triggerOperator) {
            case SwrveTriggerOperatorAND:
                if([resultantConditions count] <= 1){
                    _isValidTrigger = NO;
                }
                break;
            case SwrveTriggerOperatorOTHER:
                if([resultantConditions count] > 1){
                    _isValidTrigger = NO;
                }
                break;
            default:
                break;
        }
        
        switch (condition.conditionOperator) {
            case SwrveTriggerOperatorEQUALS:
                break;
            case SwrveTriggerOperatorOTHER:
                _isValidTrigger = NO;
                break;
            default:
                _isValidTrigger = NO;
                break;
        }
    }
    
    return resultantConditions;
}

- (BOOL) canTriggerWithPayload:(NSDictionary *)payload {
    
    BOOL canTrigger = YES;
    
    if([_conditions count] > 0) {
        
        for (SwrveTriggerCondition *condition in _conditions) {
            canTrigger = [condition hasFulfilledCondition:payload];
            
            if(!canTrigger){
                return NO;
            }
        }
    }
    
    return canTrigger;
}

- (BOOL) isValidTrigger {
    return _isValidTrigger;
}

@end


