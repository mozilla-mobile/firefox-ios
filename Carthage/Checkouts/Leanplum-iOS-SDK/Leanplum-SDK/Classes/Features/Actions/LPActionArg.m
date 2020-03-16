//
//  LPActionArg.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"
#import "LPUtils.h"
#import "LPVarCache.h"
#import "LPCountAggregator.h"

@interface LPActionArg (PrivateProperties)

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, strong) NSString *kind;

@end

@implementation LPActionArg : NSObject

+ (LPActionArg *)argNamed:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPVar argNamed:with:kind:] Empty name parameter provided."];
        return nil;
    }
    LPActionArg *arg = [LPActionArg new];
    LP_TRY
    arg->_name = name;
    arg->_kind = kind;
    arg->_defaultValue = defaultValue;
    if ([kind isEqualToString:LP_KIND_FILE]) {
        [[LPVarCache sharedCache] registerFile:(NSString *) defaultValue
                withDefaultValue:(NSString *) defaultValue];
    }
    LP_END_TRY
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"arg_named"];
    return arg;
}

+ (LPActionArg *)argNamed:(NSString *)name withNumber:(NSNumber *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_FLOAT];
}

+ (LPActionArg *)argNamed:(NSString *)name withString:(NSString *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_STRING];
}

+ (LPActionArg *)argNamed:(NSString *)name withBool:(BOOL)defaultValue
{
    return [self argNamed:name with:@(defaultValue) kind:LP_KIND_BOOLEAN];
}

+ (LPActionArg *)argNamed:(NSString *)name withFile:(NSString *)defaultValue
{
    if (defaultValue == nil) {
        defaultValue = @"";
    }
    return [self argNamed:name with:defaultValue kind:LP_KIND_FILE];
}

+ (LPActionArg *)argNamed:(NSString *)name withDict:(NSDictionary *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_DICTIONARY];
}

+ (LPActionArg *)argNamed:(NSString *)name withArray:(NSArray *)defaultValue
{
    return [self argNamed:name with:defaultValue kind:LP_KIND_ARRAY];
}

+ (LPActionArg *)argNamed:(NSString *)name withAction:(NSString *)defaultValue
{
    if (defaultValue == nil) {
        defaultValue = @"";
    }
    return [self argNamed:name with:defaultValue kind:LP_KIND_ACTION];
}

+ (LPActionArg *)argNamed:(NSString *)name withColor:(UIColor *)defaultValue
{
    return [self argNamed:name with:@(leanplum_colorToInt(defaultValue)) kind:LP_KIND_COLOR];
}

@end
