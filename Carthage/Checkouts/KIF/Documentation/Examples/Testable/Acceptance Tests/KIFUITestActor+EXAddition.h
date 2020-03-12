//
//  KIFTester+EXAddition.h
//  Testable
//
//  Created by Brian Nickel on 12/18/12.
//
//

#import <KIF/KIF.h>

@interface KIFUIViewTestActor (EXAddition)

- (KIFUIViewTestActor *)redCell;
- (KIFUIViewTestActor *)blueCell;
- (void)validateSelectedColor:(NSString *)color;

@end
