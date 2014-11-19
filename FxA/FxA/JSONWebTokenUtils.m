// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


#include "CHNumber.h"
#include "NSData+Utils.h"

#import "KeyPair.h"
#import "PrivateKey.h"
#import "PublicKey.h"
#import "JSONWebTokenUtils.h"


NSString * const JSONWebTokenUtilsDefaultAssertionIssuer = @"127.0.0.1";

const unsigned long long JSONWebTokenUtilsDefaultCertificateDuration = 60 * 60 * 1000;
const unsigned long long JSONWebTokenUtilsDefaultAssertionDuration = 60 * 60 * 1000;


@implementation JSONWebTokenUtils

+ (NSString*) base64EncodedJSONObject: (NSDictionary*) object
{
    NSError *encodingError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject: object options: 0 error: &encodingError];
    if (encodingError != nil) {
        return nil;
    }

    return [data base64URLEncodedStringWithOptions: 0];
}

+ (NSString*) encodePayloadString: (NSString*) payloadString withPrivateKeyToSign: (PrivateKey*) privateKey
{
    NSDictionary *header = @{
        @"alg": privateKey.algorithm,
    };

    NSString *encodedHeader = [self base64EncodedJSONObject: header];
    NSString *encodedPayload = [[payloadString dataUsingEncoding: NSUTF8StringEncoding] base64URLEncodedStringWithOptions: 0];

    NSString *message = [NSString stringWithFormat: @"%@.%@", encodedHeader, encodedPayload];
    NSString *signature = [[privateKey signMessageString: message encoding: NSUTF8StringEncoding] base64URLEncodedStringWithOptions: 0];

    return [NSString stringWithFormat: @"%@.%@", message, signature];
}

+ (NSString*) decodePayloadStringFromToken: (NSString*) token withPublicKeyToVerify: (PublicKey*) publicKey
{
    NSArray *components = [token componentsSeparatedByString: @"."];
    if ([components count] != 3) {
        return nil;
    }

    NSData *message = [[NSString stringWithFormat: @"%@.%@", components[0], components[1]] dataUsingEncoding: NSUTF8StringEncoding];
    NSData *signature = [[NSData alloc] initWithBase64URLEncodedString: components[2] options: 0];

    if ([publicKey verifySignature: signature againstMessage: message] == NO) {
        return nil;
    }

    return [[NSString alloc] initWithData: [[NSData alloc] initWithBase64URLEncodedString: components[1] options: 0] encoding: NSUTF8StringEncoding];
}

+ (NSDictionary*) payloadWithPayload: (NSDictionary*) payload issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt expiresAt: (unsigned long long) expiresAt audience: (NSString*) audience
{
    NSMutableDictionary *fullPayload = [NSMutableDictionary dictionaryWithDictionary: payload];
    fullPayload[@"iss"] = issuer;
    fullPayload[@"iat"] = [NSNumber numberWithUnsignedLongLong: issuedAt];
    if (audience != nil) {
        fullPayload[@"aud"] = audience;
    }
    fullPayload[@"exp"] = [NSNumber numberWithUnsignedLongLong: expiresAt];

    return fullPayload;
}

+ (NSString*) payloadStringWithPayload: (NSDictionary*) payload issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt expiresAt: (unsigned long long) expiresAt audience: (NSString*) audience
{
    NSDictionary *fullPayload = [self payloadWithPayload: payload issuer:issuer issuedAt:issuedAt expiresAt:expiresAt audience:audience];

    NSError *encodingError = nil;
    NSData *payloadData = [NSJSONSerialization dataWithJSONObject: fullPayload options: 0 error: &encodingError];
    if (encodingError != nil) {
        return nil;
    }

    return [[NSString alloc] initWithData: payloadData encoding: NSUTF8StringEncoding];
}

+ (NSDictionary*) certificatePayloadWithPublicKeyToSign: (PublicKey*) publicKey email: (NSString*) email
{
    NSDictionary *payload = @{
        @"principal": @{
            @"email": email
        },
        @"public-key": [publicKey JSONRepresentation]
    };

    return payload;
}

+ (NSString*) certificatePayloadStringWithPublicKeyToSign: (PublicKey*) publicKeyToSign email: (NSString*) email
{
    NSDictionary *payloadObject = [self certificatePayloadWithPublicKeyToSign: publicKeyToSign email: email];

    NSError *encodingError = nil;
    NSData *payload = [NSJSONSerialization dataWithJSONObject: payloadObject options: 0 error: &encodingError];
    if (encodingError != nil) {
        return nil;
    }

    return [[NSString alloc] initWithData: payload encoding:NSUTF8StringEncoding];
}

+ (NSString*) certificateWithPublicKeyToSign: (PublicKey*) publicKeyToSign email: (NSString*) email issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt expiresAt: (unsigned long long) expiresAt signingPrivateKey: (PrivateKey*) signingPrivateKey
{
    NSDictionary *certificatePayload = [JSONWebTokenUtils certificatePayloadWithPublicKeyToSign: publicKeyToSign email: email];
    NSString *payloadString = [JSONWebTokenUtils payloadStringWithPayload: certificatePayload issuer: issuer issuedAt: issuedAt expiresAt:expiresAt audience: nil];
    return [self encodePayloadString: payloadString withPrivateKeyToSign: signingPrivateKey];
}

+ (NSString*) createAssertionWithPrivateKeyToSignWith: (PrivateKey*) privateKeyToSignWith certificate: (NSString*) certificate audience: (NSString*) audience issuer: (NSString*) issuer issuedAt: (unsigned long long) issuedAt duration: (unsigned long long) duration
{
    unsigned long long expiresAt = issuedAt + duration;
    NSString *payloadString = [self payloadStringWithPayload: @{} issuer:issuer issuedAt:issuedAt expiresAt:expiresAt audience:audience];
    NSString *signature = [self encodePayloadString: payloadString withPrivateKeyToSign: privateKeyToSignWith];
    return [NSString stringWithFormat: @"%@~%@", certificate, signature];
}

+ (NSString*) createAssertionWithPrivateKeyToSignWith: (PrivateKey*) privateKeyToSignWith certificate: (NSString*) certificate audience: (NSString*) audience
{
    unsigned long long issuedAt = [[NSDate date] timeIntervalSince1970] * 1000;
    unsigned long long duration = JSONWebTokenUtilsDefaultAssertionDuration;
    return [self createAssertionWithPrivateKeyToSignWith: privateKeyToSignWith certificate: certificate audience: audience
        issuer: JSONWebTokenUtilsDefaultAssertionIssuer issuedAt: issuedAt duration: duration];
}

@end
