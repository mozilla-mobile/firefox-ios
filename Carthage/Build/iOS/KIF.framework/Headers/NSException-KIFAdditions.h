//
//  NSException-KIFAdditions.h
//  KIF
//
//  Created by Tony DiPasquale on 12/20/13.
//
//

#import <Foundation/Foundation.h>

@interface NSException (KIFAdditions)

+ (NSException *)failureInFile:(NSString *)file atLine:(NSInteger)line withDescription:(NSString *)formatString, ...;

@end
