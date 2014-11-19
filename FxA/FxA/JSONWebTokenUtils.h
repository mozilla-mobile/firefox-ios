// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#import <Foundation/Foundation.h>


@class KeyPair;
@class PublicKey;
@class PrivateKey;
@class FXACertificate;


extern NSString * const JSONWebTokenUtilsDefaultAssertionIssuer;

extern const unsigned long long JSONWebTokenUtilsDefaultCertificateDuration;
extern const unsigned long long JSONWebTokenUtilsDefaultAssertionDuration;


@interface JSONWebTokenUtils : NSObject

+ (NSString*) base64EncodedJSONObject: (NSDictionary*) object;

+ (NSString*) encodePayloadString: (NSString*) payloadString withPrivateKeyToSign: (PrivateKey*) privateKey;
+ (NSString*) decodePayloadStringFromToken: (NSString*) token withPublicKeyToVerify: (PublicKey*) publicKey;

+ (NSDictionary*) payloadWithPayload: (NSDictionary*) payload issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt expiresAt: (unsigned long long) expiresAt audience: (NSString*) audience;
+ (NSString*) payloadStringWithPayload: (NSDictionary*) payload issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt expiresAt: (unsigned long long) expiresAt audience: (NSString*) audience;

+ (NSDictionary*) certificatePayloadWithPublicKeyToSign: (PublicKey*) publicKeyToSign email: (NSString*) email;
+ (NSString*) certificatePayloadStringWithPublicKeyToSign: (PublicKey*) publicKeyToSign email: (NSString*) email;

+ (NSString*) certificateWithPublicKeyToSign: (PublicKey*) publicKeyToSign email: (NSString*) email issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt expiresAt: (unsigned long long) expiresAt signingPrivateKey: (PrivateKey*) signingPrivateKey;


+ (NSString*) createAssertionWithPrivateKeyToSignWith: (PrivateKey*) privateKeyToSignWith certificate: (NSString*) certificate audience: (NSString*) audience issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt duration: (unsigned long long) duration;
+ (NSString*) createAssertionWithPrivateKeyToSignWith: (PrivateKey*) privateKeyToSignWith certificate: (NSString*) certificate audience: (NSString*) audience;

@end
