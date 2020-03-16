//
//  KIFAccessibilityEnabler.h
//  KIF
//
//  Created by Timothy Clem on 10/11/15.
//
//

#import <Foundation/Foundation.h>

/**
 * Provides a way to enable the Accessibility Inspector.
 */
FOUNDATION_EXTERN void KIFEnableAccessibility(void);

/**
 * Returns YES if `KIFEnableAccessibility` has been already called successfully.
 * It returns NO otherwise.
 */
FOUNDATION_EXTERN BOOL KIFAccessibilityEnabled(void);
