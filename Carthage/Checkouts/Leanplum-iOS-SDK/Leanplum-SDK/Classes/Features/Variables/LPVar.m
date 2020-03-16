//
//  LPVar.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LPVar-Internal.h"
#import "LPVarCache.h"
#import "LPFileManager.h"

static BOOL LPVAR_PRINTED_CALLBACK_WARNING = NO;

@interface LPVar (PrivateProperties)

@property (nonatomic) BOOL isInternal;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *nameComponents;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic) BOOL hadStarted;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSMutableArray *fileReadyBlocks;
@property (nonatomic, strong) NSMutableArray *valueChangedBlocks;
@property (nonatomic) BOOL fileIsPending;
@property (nonatomic) BOOL hasChanged;

@end

@implementation LPVar

@synthesize stringValue=_stringValue;
@synthesize numberValue=_numberValue;
@synthesize hadStarted=_hadStarted;
@synthesize hasChanged=_hasChanged;

+(BOOL)printedCallbackWarning
{
    return LPVAR_PRINTED_CALLBACK_WARNING;
}

+(void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning
{
    LPVAR_PRINTED_CALLBACK_WARNING = newPrintedCallbackWarning;
}

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSNumber *)defaultValue withKind:(NSString *)kind
{
    self = [super init];
    if (self) {
        LP_TRY
        _name = name;
        _nameComponents = [[LPVarCache sharedCache] getNameComponents:name];
        _defaultValue = defaultValue;
        _value = defaultValue;
        _kind = kind;
        [self cacheComputedValues];
        
        [[LPVarCache sharedCache] registerVariable:self];
        if ([kind isEqualToString:LP_KIND_FILE]) { // TODO: && var.stringValue)
            [[LPVarCache sharedCache] registerFile:_stringValue withDefaultValue:_defaultValue];
        }
        if ([name hasPrefix:LP_VALUE_RESOURCES_VARIABLE]) {
            _isInternal = YES;
        }
        [self update];
        LP_END_TRY
    }
    return self;
}

#pragma mark Defines

+ (LPVar *)define:(NSString *)name
{
    return [[LPVarCache sharedCache] define:name with:nil kind:nil];
}

+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:[NSNumber numberWithInt:defaultValue] kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:[NSNumber numberWithFloat:defaultValue] kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithDouble:defaultValue]
                         kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithDouble:defaultValue]
                         kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithShort:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithChar:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithBool:defaultValue]
                         kind:LP_KIND_BOOLEAN];
}

+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithInteger:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithLongLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithUnsignedChar:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithUnsignedInt:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithUnsignedInteger:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithUnsignedLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithUnsignedLongLong:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue
{
    return [[LPVarCache sharedCache] define:name
                         with:[NSNumber numberWithUnsignedShort:defaultValue]
                         kind:LP_KIND_INT];
}

+ (LPVar *)define:(NSString *)name withString:(NSString *)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_STRING];
}

+ (LPVar *)define:(NSString *)name withNumber:(NSNumber *)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_FLOAT];
}

+ (LPVar *)define:(NSString *)name withFile:(NSString *)defaultFilename
{
    return [[LPVarCache sharedCache] define:name with:defaultFilename kind:LP_KIND_FILE];
}

+ (LPVar *)define:(NSString *)name withDictionary:(NSDictionary *)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_DICTIONARY];
}

+ (LPVar *)define:(NSString *)name withArray:(NSArray *)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_ARRAY];
}

+ (LPVar *)define:(NSString *)name withColor:(UIColor *)defaultValue
{
    return [[LPVarCache sharedCache] define:name with:@(leanplum_colorToInt(defaultValue)) kind:LP_KIND_COLOR];
}

#pragma mark Updating

- (void) cacheComputedValues
{
    // Cache computed values.
    if ([_value isKindOfClass:NSString.class]) {
        _stringValue = (NSString *) _value;
        _numberValue = [NSNumber numberWithDouble:[_stringValue doubleValue]];
    } else if ([_value isKindOfClass:NSNumber.class]) {
        _stringValue = [NSString stringWithFormat:@"%@", _value];
        _numberValue = (NSNumber *) _value;
    } else {
        _stringValue = nil;
        _numberValue = nil;
    }
}

- (void)update
{
    NSObject *oldValue = _value;
    _value = [[LPVarCache sharedCache] getMergedValueFromComponentArray:_nameComponents];
    if ([_value isEqual:oldValue] && _hadStarted) {
        return;
    }
    [self cacheComputedValues];
    
    if (![_value isEqual:oldValue]) {
        _hasChanged = YES;
    }
    
    if ([LPVarCache sharedCache].silent && [[self name] hasPrefix:LP_VALUE_RESOURCES_VARIABLE]
        && [_kind isEqualToString:LP_KIND_FILE] && !_fileIsPending) {
        [self triggerFileIsReady];
    }
    
    if ([LPVarCache sharedCache].silent) {
        return;
    }
    
    if ([LPInternalState sharedState].hasStarted) {
        [self triggerValueChanged];
    }
    
    // Check if file exists, otherwise we need to download it.
    // Ignore app icon. This is a special variable that only needs the filename.
    if ([_kind isEqualToString:LP_KIND_FILE]) {
        if ([LPFileManager maybeDownloadFile:_stringValue
                                defaultValue:_defaultValue
                                  onComplete:^{[self triggerFileIsReady];}]) {
            _fileIsPending = YES;
        }
        if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
            [self triggerFileIsReady];
        }
    }
    
    if ([LPInternalState sharedState].hasStarted) {
        _hadStarted = YES;
    }
}

#pragma mark Basic accessors

- (void)triggerValueChanged
{
    LP_BEGIN_USER_CODE
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(valueDidChange:)]) {
        [self.delegate valueDidChange:self];
    }
    
    for (LeanplumVariablesChangedBlock block in _valueChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

- (void)onValueChanged:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [Leanplum throwError:@"[LPVar onValueChanged:] Nil block parameter provided."];
    }
    
    LP_TRY
    if (!_valueChangedBlocks) {
        _valueChangedBlocks = [NSMutableArray array];
    }
    [_valueChangedBlocks addObject:[block copy]];
    if ([LPInternalState sharedState].hasStarted) {
        [self triggerValueChanged];
    }
    LP_END_TRY
}

#pragma mark File handling

- (void)triggerFileIsReady
{
    _fileIsPending = NO;
    LP_BEGIN_USER_CODE
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(fileIsReady:)]) {
        [self.delegate fileIsReady:self];
    }
    
    for (LeanplumVariablesChangedBlock block in _fileReadyBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

- (void)onFileReady:(LeanplumVariablesChangedBlock)block
{
    if (!block) {
        [Leanplum throwError:@"[LPVar onFileReady:] Nil block parameter provided."];
    }
    
    LP_TRY
    if (!_fileReadyBlocks) {
        _fileReadyBlocks = [NSMutableArray array];
    }
    [_fileReadyBlocks addObject:[block copy]];
    if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
        [self triggerFileIsReady];
    }
    LP_END_TRY
}

- (void)setDelegate:(id<LPVarDelegate>)delegate
{
    LP_TRY
    _delegate = delegate;
    if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
        [self triggerFileIsReady];
    }
    LP_END_TRY
}

- (void)warnIfNotStarted
{
    if (!_isInternal && ![LPInternalState sharedState].hasStarted && ![LPVar printedCallbackWarning]) {
        NSLog(@"Leanplum: WARNING: Leanplum hasn't finished retrieving values from the server. You "
              @"should use a callback to make sure the value for '%@' is ready. Otherwise, your "
              @"app may not use the most up-to-date value.", self.name);
        [LPVar setPrintedCallbackWarning:YES];
    }
}

- (NSString *)fileValue
{
    LP_TRY
    [self warnIfNotStarted];
    if ([_kind isEqualToString:LP_KIND_FILE]) {
        return [LPFileManager fileValue:_stringValue withDefaultValue:_defaultValue];
    }
    LP_END_TRY
    return nil;
}

- (UIImage *)imageValue
{
    LP_TRY
    NSString *fileValue = [self fileValue];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileValue]) {
        return [UIImage imageWithContentsOfFile:fileValue];
    }
    LP_END_TRY
    return [UIImage imageNamed:_defaultValue];
}

#pragma mark Dictionary handling

- (id) objectForKey:(NSString *)key
{
    return [self objectForKeyPath:key, nil];
}

- (id) objectAtIndex:(NSUInteger)index
{
    return [self objectForKeyPath:@(index), nil];
}

- (id) objectForKeyPath:(id)firstComponent, ...
{
    LP_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    va_list args;
    va_start(args, firstComponent);
    for (id component = firstComponent;
         component != nil; component = va_arg(args, id)) {
        [components addObject:component];
    }
    va_end(args);
    return [[LPVarCache sharedCache] getMergedValueFromComponentArray:components];
    LP_END_TRY
    return nil;
}

- (id)objectForKeyPathComponents:(NSArray *)pathComponents
{
    LP_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    [components addObjectsFromArray:pathComponents];
    return [[LPVarCache sharedCache] getMergedValueFromComponentArray:components];
    LP_END_TRY
    return nil;
}

- (NSUInteger)count
{
    LP_TRY
    return [[[LPVarCache sharedCache] getMergedValueFromComponentArray:_nameComponents] count];
    LP_END_TRY
}

#pragma mark Value accessors

- (NSNumber *)numberValue
{
    [self warnIfNotStarted];
    return _numberValue;
}

- (NSString *)stringValue
{
    [self warnIfNotStarted];
    return _stringValue;
}

- (int)intValue { return [[self numberValue] intValue]; }
- (double)doubleValue { return [[self numberValue] doubleValue];}
- (float)floatValue { return [[self numberValue] floatValue]; }
- (CGFloat)cgFloatValue { return [[self numberValue] doubleValue]; }
- (short)shortValue { return [[self numberValue] shortValue];}
- (BOOL)boolValue { return [[self numberValue] boolValue]; }
- (char)charValue { return [[self numberValue] charValue]; }
- (long)longValue { return [[self numberValue] longValue]; }
- (long long)longLongValue { return [[self numberValue] longLongValue]; }
- (NSInteger)integerValue { return [[self numberValue] integerValue]; }
- (unsigned char)unsignedCharValue { return [[self numberValue] unsignedCharValue]; }
- (unsigned short)unsignedShortValue { return [[self numberValue] unsignedShortValue]; }
- (unsigned int)unsignedIntValue { return [[self numberValue] unsignedIntValue]; }
- (NSUInteger)unsignedIntegerValue { return [[self numberValue] unsignedIntegerValue]; }
- (unsigned long)unsignedLongValue { return [[self numberValue] unsignedLongValue]; }
- (unsigned long long)unsignedLongLongValue { return [[self numberValue] unsignedLongLongValue]; }
- (UIColor *)colorValue { return leanplum_intToColor([self longLongValue]); }

@end
