//
//  LPActionContext.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"
#import "LPVarCache.h"
#import "LPFileManager.h"
#import "LPUtils.h"
#import "LPCountAggregator.h"

typedef void (^LPFileCallback)(NSString* value, NSString *defaultValue);

@interface LPActionContext (PrivateProperties)

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *originalMessageId;
@property (nonatomic, strong) NSNumber *priority;
@property (nonatomic, strong) NSDictionary *args;
@property (nonatomic, strong) LPActionContext *parentContext;
@property (nonatomic) int contentVersion;
@property (nonatomic, strong) NSString *key;
@property (nonatomic) BOOL preventRealtimeUpdating;

@end

@interface LPActionContext()

@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end


@implementation LPActionContext

@synthesize name=_name;
@synthesize messageId=_messageId;
@synthesize originalMessageId=_originalMessageId;
@synthesize priority=_priority;
@synthesize args=_args;
@synthesize parentContext=_parentContext;
@synthesize contentVersion=_contentVersion;
@synthesize key=_key;
@synthesize preventRealtimeUpdating=_preventRealtimeUpdating;
@synthesize contextualValues=_contextualValues;
@synthesize countAggregator=_countAggregator;

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
{
    return [LPActionContext actionContextWithName:name
                                             args:args
                                        messageId:messageId
                                originalMessageId:nil
                                         priority:[NSNumber numberWithInt:DEFAULT_PRIORITY]];
}

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
                         originalMessageId:(NSString *)originalMessageId
                                  priority:(NSNumber *)priority

{
    LPActionContext *context = [[LPActionContext alloc] init];
    context->_name = name;
    context->_args = args;
    context->_messageId = messageId;
    context->_originalMessageId = originalMessageId;
    context->_contentVersion = [[LPVarCache sharedCache] contentVersion];
    context->_preventRealtimeUpdating = NO;
    context->_isRooted = YES;
    context->_isPreview = NO;
    context->_priority = priority;
    context->_countAggregator = [LPCountAggregator sharedAggregator];
    return context;
}

- (NSDictionary *)defaultValues
{
    return [LPVarCache sharedCache].actionDefinitions[_name][@"values"];
}

/**
 * Downloads missing files that are part of this action.
 */
- (void)maybeDownloadFiles
{
    [self maybeDownloadFilesWithinArgs:_args withPrefix:@"" withDefaultValues:[self defaultValues]];
}

/**
 * Downloads missing files that are part of this action.
 */
- (void)maybeDownloadFilesWithinArgs:(NSDictionary *)args
                          withPrefix:(NSString *)prefix
                   withDefaultValues:(NSDictionary *)defaultValues
{
    [self forEachFile:args
           withPrefix:prefix
    withDefaultValues:defaultValues
             callback:^(NSString *value, NSString *defaultValue) {
                 [LPFileManager maybeDownloadFile:value
                                     defaultValue:defaultValue
                                       onComplete:^{}];
             }];
}

- (void)forEachFile:(NSDictionary *)args
         withPrefix:(NSString *)prefix
  withDefaultValues:(NSDictionary *)defaultValues
           callback:(LPFileCallback)callback
{
    NSDictionary *kinds = [LPVarCache sharedCache].actionDefinitions[_name][@"kinds"];
    for (NSString *arg in args) {
        id value = args[arg];
        id defaultValue = nil;
        if ([defaultValues isKindOfClass:[NSDictionary class]]) {
            defaultValue = defaultValues[arg];
        }
        NSString *prefixAndArg = [NSString stringWithFormat:@"%@%@", prefix, arg];
        NSString *kind = kinds[prefixAndArg];

        if ((kind == nil || ![kind isEqualToString:LP_KIND_ACTION])
            && [value isKindOfClass:[NSDictionary class]]
            && !value[LP_VALUE_ACTION_ARG]) {
            [self forEachFile:value
                   withPrefix:[NSString stringWithFormat:@"%@.", prefixAndArg]
            withDefaultValues:defaultValue
                     callback:callback];

        } else if ([kind isEqualToString:LP_KIND_FILE] &&
                   ![arg isEqualToString:LP_APP_ICON_NAME]) {
            callback(value, defaultValue);

            // Check for specific file type extension (HTML).
        } else if ([arg hasPrefix:@"__file__"] && ![LPUtils isNullOrEmpty:value]) {
            callback(value, defaultValue);

            // Need to check for nil because server actions like push notifications aren't
            // defined in the SDK, and so there's no associated metadata.
        } else if ([kind isEqualToString:LP_KIND_ACTION] || kind == nil) {
            NSDictionary *actionArgs = [self dictionaryNamed:prefixAndArg];
            if (![actionArgs isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            LPActionContext *context = [LPActionContext
                                        actionContextWithName:actionArgs[LP_VALUE_ACTION_ARG]
                                        args:actionArgs
                                        messageId:_messageId];
            [context forEachFile:context->_args
                      withPrefix:@""
               withDefaultValues:[context defaultValues]
                        callback:callback];
        }
    }
}

- (BOOL)hasMissingFiles
{
    __block BOOL hasMissingFiles = NO;
    LP_TRY
    [self forEachFile:_args
           withPrefix:@""
    withDefaultValues:[self defaultValues]
             callback:^(NSString *value, NSString *defaultValue) {
                 if ([LPFileManager shouldDownloadFile:value defaultValue:defaultValue]) {
                     hasMissingFiles = YES;
                 }
             }];
    LP_END_TRY
    return hasMissingFiles;
}

- (NSString *)actionName
{
    return _name;
}

- (void)setProperArgs
{
    if (!_preventRealtimeUpdating && [[LPVarCache sharedCache] contentVersion] > _contentVersion) {
        LPActionContext *parent = _parentContext;
        if (parent) {
            _args = [parent getChildArgs:_key];
        } else if (_messageId) {
            NSDictionary *message = [LPVarCache sharedCache].messages[_messageId];
            if (message) {
                _args = message[LP_KEY_VARS];
            }
        }
    }
}

- (id)objectNamed:(NSString *)name
{
    LP_TRY
    [self setProperArgs];
    return [[LPVarCache sharedCache] getValueFromComponentArray:[[LPVarCache sharedCache] getNameComponents:name]
                                         fromDict:_args];
    LP_END_TRY
    return nil;
}

- (NSString *)stringNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext stringNamed:] Empty name parameter provided."];
        return nil;
    }
    return [self fillTemplate:[[self objectNamed:name] description]];
}

- (NSString *)fillTemplate:(NSString *)value
{
    if (!_contextualValues || !value || [value rangeOfString:@"##"].location == NSNotFound) {
        return value;
    }

    NSDictionary *parameters = _contextualValues.parameters;

    for (NSString *parameterName in [parameters keyEnumerator]) {
        NSString *placeholder = [NSString stringWithFormat:@"##Parameter %@##", parameterName];
        value = [value stringByReplacingOccurrencesOfString:placeholder
                                                 withString:[parameters[parameterName]
                                                             description]];
    }
    if (_contextualValues.previousAttributeValue) {
        value = [value
                 stringByReplacingOccurrencesOfString:@"##Previous Value##"
                 withString:[_contextualValues
                             .previousAttributeValue description]];
    }
    if (_contextualValues.attributeValue) {
        value = [value stringByReplacingOccurrencesOfString:@"##Value##"
                                                 withString:[_contextualValues.attributeValue
                                                             description]];
    }
    return value;
}

- (NSURL *)htmlWithTemplateNamed:(NSString *)templateName
{
    if ([LPUtils isNullOrEmpty:templateName]) {
        [Leanplum throwError:@"[LPActionContext htmlWithTemplateNamed:] "
         "Empty name parameter provided."];
        return nil;
    }

    LP_TRY
    [self setProperArgs];

    // Replace to local file path recursively.
    __block __weak NSMutableDictionary* (^weakReplaceFileToLocalPath) (NSMutableDictionary *);
    NSMutableDictionary* (^replaceFileToLocalPath) (NSMutableDictionary *);
    weakReplaceFileToLocalPath = replaceFileToLocalPath =
    [^ NSMutableDictionary* (NSMutableDictionary *vars){
        for (NSString *key in [vars allKeys]) {
            id obj = vars[key];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                vars[key] = weakReplaceFileToLocalPath(obj);
            } else if ([key hasPrefix:@"__file__"] && [obj isKindOfClass:[NSString class]]
                       && [obj length] > 0 && ![key isEqualToString:templateName]) {
                NSString *filePath = [LPFileManager fileValue:obj withDefaultValue:@""];
                NSString *prunedKey = [key stringByReplacingOccurrencesOfString:@"__file__"
                                                                     withString:@""];
                vars[prunedKey] = [[NSString stringWithFormat:@"file://%@", filePath]
                                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
                [vars removeObjectForKey:key];
            }
        }
        return vars;
    } copy];
    NSMutableDictionary *htmlVars = replaceFileToLocalPath([_args mutableCopy]);
    htmlVars[@"messageId"] = self.messageId;

    // Triggering Event.
    if (self.contextualValues && self.contextualValues.arguments) {
        htmlVars[@"displayEvent"] = self.contextualValues.arguments;
    }

    // Add HTML Vars.
    NSString *jsonString = [LPJSON stringFromJSON:htmlVars];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    // Template.
    NSError *error;
    NSString *htmlString = [NSString stringWithContentsOfFile:[self fileNamed:templateName]
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (error) {
        LPLog(LPError, @"Fail to get HTML template.");
        return nil;
    }
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"##Vars##"
                                                       withString:jsonString];

    htmlString = [self fillTemplate:htmlString];

    // Save filled template to temp file which will be used by WebKit
    NSString *randomUUID = [[[NSUUID UUID] UUIDString] lowercaseString];
    NSString *tmpPath = [LPFileManager fileRelativeToDocuments:randomUUID createMissingDirectories:YES];
    NSURL *tmpURL = [[NSURL fileURLWithPath:tmpPath] URLByAppendingPathExtension:@"html"];

    [htmlString writeToURL:tmpURL atomically:YES encoding:NSUTF8StringEncoding error:nil];

    return tmpURL;
    LP_END_TRY
    return nil;
}

- (NSString *)getDefaultValue:(NSString *)name
{
    NSArray *components = [name componentsSeparatedByString:@"."];
    NSDictionary *defaultValues = self.defaultValues;
    for (int i = 0; i < components.count; i++) {
        if (defaultValues == nil) {
            return nil;
        }
        id value = defaultValues[components[i]];
        if (i == components.count - 1) {
            return (NSString *) value;
        }
        defaultValues = (NSDictionary *) value;
    }
    return nil;
}

- (NSString *)fileNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext fileNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    NSString *stringValue = [self stringNamed:name];
    NSString *defaultValue = [self getDefaultValue:name];
    return [LPFileManager fileValue:stringValue withDefaultValue:defaultValue];
    LP_END_TRY
}

- (NSNumber *)numberNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext numberNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:NSNumber.class]) {
        return object;
    }
    return [NSNumber numberWithDouble:[[object description] doubleValue]];
    LP_END_TRY
}

- (BOOL)boolNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext boolNamed:] Empty name parameter provided."];
        return NO;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:NSNumber.class]) {
        return [(NSNumber *) object boolValue];
    }
    return [[object description] boolValue];
    LP_END_TRY
}

- (NSDictionary *)dictionaryNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext dictionaryNamed:] Empty name parameter provided."];
        return nil;
    }
    LP_TRY
    id object = [self objectNamed:name];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *) object;
    }

    if ([object isKindOfClass:[NSString class]]) {
        return [LPJSON JSONFromString:object];
    }
    LP_END_TRY
    return nil;
}

- (NSArray *)arrayNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext arrayNamed:] Empty name parameter provided."];
        return nil;
    }
    return (NSArray *) [self objectNamed:name];
}

- (UIColor *)colorNamed:(NSString *)name
{
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext colorNamed:] Empty name parameter provided."];
        return nil;
    }
    return leanplum_intToColor([[self numberNamed:name] longLongValue]);
}

- (NSDictionary *)getChildArgs:(NSString *)name
{
    LP_TRY
    NSDictionary *actionArgs = [self dictionaryNamed:name];
    if (![actionArgs isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *defaultArgs = [LPVarCache sharedCache].actionDefinitions
    [actionArgs[LP_VALUE_ACTION_ARG]]
    [@"values"];
    actionArgs = [[LPVarCache sharedCache] mergeHelper:defaultArgs withDiffs:actionArgs];
    return actionArgs;
    LP_END_TRY
}

/**
 * Prefix given event with all parent actionContext names to while filtering out the string
 * "action" (used in ExperimentVariable names but filtered out from event names).
 */
- (NSString *)eventWithParentEventNamesFromEvent:(NSString *)event
{
    LP_TRY
    NSMutableString *fullEventName = [NSMutableString string];
    LPActionContext *context = self;
    NSMutableArray *parents = [NSMutableArray array];
    while (context->_parentContext != nil) {
        [parents addObject:context];
        context = context->_parentContext;
    }
    NSString *actionName;
    for (NSInteger i = parents.count - 1; i >= -1; i--) {
        if (i > -1) {
            actionName = ((LPActionContext *) parents[i])->_key;
        } else {
            actionName = event;
        }
        if (actionName == nil) {
            fullEventName = nil;
            break;
        }
        actionName = [actionName stringByReplacingOccurrencesOfString:@" action"
                                                           withString:@""
                                                              options:NSCaseInsensitiveSearch
                                                                range:NSMakeRange(0,
                                                                                  actionName.length)
                      ];

        if (fullEventName.length) {
            [fullEventName appendString:@" "];
        }
        [fullEventName appendString:actionName];
    }

    return fullEventName;
    LP_END_TRY
}

- (void)runActionNamed:(NSString *)name
{
    LP_TRY
    if ([LPUtils isNullOrEmpty:name]) {
        [Leanplum throwError:@"[LPActionContext runActionNamed:] Empty name parameter provided."];
        return;
    }
    NSDictionary *args = [self getChildArgs:name];
    if (!args) {
        return;
    }

    // Chain to existing message.
    NSString *messageId = args[LP_VALUE_CHAIN_MESSAGE_ARG];
    NSString *actionType = args[LP_VALUE_ACTION_ARG];

    void (^executeChainedMessage)(void) = ^void(void) {
        LPActionContext *chainedActionContext =
        [Leanplum createActionContextForMessageId:messageId];
        chainedActionContext.contextualValues = self.contextualValues;
        chainedActionContext->_preventRealtimeUpdating = self->_preventRealtimeUpdating;
        chainedActionContext->_isRooted = self->_isRooted;
        dispatch_async(dispatch_get_main_queue(), ^{
            [Leanplum triggerAction:chainedActionContext handledBlock:^(BOOL success) {
                if (success) {
                    // Track when the chain message is viewed.
                    [[LPInternalState sharedState].actionManager
                     recordMessageImpression:[chainedActionContext messageId]];
                }
            }];
        });
    };

    if (messageId && [actionType isEqualToString:LP_VALUE_CHAIN_MESSAGE_ACTION_NAME]) {
        NSDictionary *message = [[LPVarCache sharedCache] messages][messageId];
        if (message) {
            executeChainedMessage();
            return;
        } else {
            // Message doesn't seem to be on the device,
            // so let's forceContentUpdate and retry showing it.
            [Leanplum forceContentUpdate: ^(void) {
                NSDictionary *message = [[LPVarCache sharedCache] messages][messageId];
                if (message) {
                    executeChainedMessage();
                }
            }];
        }
    }

    LPActionContext *childContext = [LPActionContext
                                     actionContextWithName:args[LP_VALUE_ACTION_ARG]
                                     args:args messageId:_messageId];
    childContext.contextualValues = self.contextualValues;
    childContext->_preventRealtimeUpdating = _preventRealtimeUpdating;
    childContext->_isRooted = _isRooted;
    childContext->_parentContext = self;
    childContext->_key = name;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Leanplum triggerAction:childContext];
    });
    LP_END_TRY
    
    [self.countAggregator incrementCount:@"run_action_named"];
}

- (void)runTrackedActionNamed:(NSString *)name
{
    if (!IS_NOOP && _messageId && _isRooted) {
        if ([LPUtils isNullOrEmpty:name]) {
            [Leanplum throwError:@"[LPActionContext runTrackedActionNamed:] Empty name parameter "
             @"provided."];
            return;
        }
        [self trackMessageEvent:name withValue:0.0 andInfo:nil andParameters:nil];
    }
    [self runActionNamed:name];
    
    [self.countAggregator incrementCount:@"run_tracked_action_named"];
}

- (void)trackMessageEvent:(NSString *)event withValue:(double)value andInfo:(NSString *)info
            andParameters:(NSDictionary *)params
{
    if (!IS_NOOP && _messageId) {
        event = [self eventWithParentEventNamesFromEvent:event];
        if (event) {
            [Leanplum track:event
                  withValue:value
                    andInfo:info
                    andArgs:@{LP_PARAM_MESSAGE_ID: _messageId}
              andParameters:params];
        }
    }
}

- (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params
{
    if (!IS_NOOP && _messageId) {
        [Leanplum track:event
              withValue:value
                andInfo:nil
                andArgs:@{LP_PARAM_MESSAGE_ID: _messageId}
          andParameters:params];
    }
}

- (void)muteFutureMessagesOfSameKind
{
    LP_TRY
    [[LPActionManager sharedManager] muteFutureMessagesOfKind:_messageId];
    LP_END_TRY
}

+ (void)sortByPriority:(NSMutableArray *)actionContexts
{
    [actionContexts sortUsingComparator:^(LPActionContext *contextA, LPActionContext *contextB) {
        NSNumber *priorityA = [contextA priority];
        NSNumber *priorityB = [contextB priority];
        return [priorityA compare:priorityB];
    }];
}

@end
