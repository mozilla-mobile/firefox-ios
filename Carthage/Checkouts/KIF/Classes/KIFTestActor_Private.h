#import <KIF/KIFTestActor.h>


@interface KIFTestActor ()

- (instancetype)initWithFile:(NSString *)file line:(NSInteger)line delegate:(id<KIFTestActorDelegate>)delegate;

@end
