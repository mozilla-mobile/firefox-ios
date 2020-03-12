//
//  KIFTextInputTraitsOverrides.h
//  KIF
//
//  Created by Harley Cooper on 1/31/18.
//

@interface KIFTextInputTraitsOverrides : NSObject

/*!
 @abstract If set to @c YES then KIF will observe default autocorrect behavior. If set to @c NO then autocorrect will always be disabled.
 */
+ (BOOL)allowDefaultAutocorrectBehavior;
/*!
 @abstract Set whether KIF will observe default autocorrect behavior. If set to @c NO then autocorrect will always be disabled.
 */
+ (void)setAllowDefaultAutocorrectBehavior:(BOOL)allowDefaultBehavior;

/*!
 @abstract If set to @c YES then KIF will observe default smart quotes behavior. If set to @c NO then smart dashes will always be disabled.
 */
+ (BOOL)allowDefaultSmartDashesBehavior;
/*!
 @abstract Set whether KIF will observe default smart dashes behavior. If set to @c NO then smart dashes will always be disabled.
 */
+ (void)setAllowDefaultSmartDashesBehavior:(BOOL)allowDefaultBehavior;

/*!
 @abstract If set to @c YES then KIF will observe default smart quotes behavior. If set to @c NO then smart quotes will always be disabled.
 */
+ (BOOL)allowDefaultSmartQuotesBehavior;
/*!
@abstract Set whether KIF will observe default smart quotes behavior. If set to @c NO then smart quotes will always be disabled.
 */
+ (void)setAllowDefaultSmartQuotesBehavior:(BOOL)allowDefaultBehavior;

@end
