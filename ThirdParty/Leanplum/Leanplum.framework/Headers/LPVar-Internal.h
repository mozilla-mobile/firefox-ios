//
//  LPVar.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"

@interface LPVar ()

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSObject *)defaultValue withKind:(NSString *)kind;

@property (readonly) BOOL isInternal;
@property (readonly, strong) NSString *name;
@property (readonly, strong) NSArray *nameComponents;
@property (readonly, strong) NSString *stringValue;
@property (readonly, strong) NSNumber *numberValue;
@property (readonly) BOOL hadStarted;
@property (readonly, strong) id value;
@property (readonly, strong) id defaultValue;
@property (readonly, strong) NSString *kind;
@property (readonly, strong) NSMutableArray *fileReadyBlocks;
@property (readonly, strong) NSMutableArray *valueChangedBlocks;
@property (readonly) BOOL fileIsPending;
@property (nonatomic, unsafe_unretained) id <LPVarDelegate> delegate;
@property (readonly) BOOL hasChanged;

- (void) update;
- (void) cacheComputedValues;
- (void) triggerFileIsReady;
- (void) triggerValueChanged;

+(BOOL)printedCallbackWarning;
+(void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning;

@end
