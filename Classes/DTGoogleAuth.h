//
//  DTGoogleAuth.h
//  DTGoogleAuth
//
//  Created by Diego Torres on 05-05-15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

@import Foundation;
@import Accounts;

@class DTGoogleAuth;
typedef void(^DTGoogleAuthHandler)(DTGoogleAuth *auth, NSError *error);
#define DTGoogleErrorDomain ACErrorDomain
typedef ACErrorCode DTGoogleErrorCode;

@interface DTGoogleAuth : NSObject

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
#endif

+ (void)authenticateWithScopes:(NSArray *)scopes clientIdentifier:(NSString *)identifier completion:(DTGoogleAuthHandler)handler;
+ (void)authenticateWithScopes:(NSArray *)scopes clientIdentifier:(NSString *)identifier secretIdentifier:(NSString *)secretIdentifier completion:(DTGoogleAuthHandler)handler;

- (void)oauthTokenWithSecretIdentifier:(NSString *)secretIdentifier completion:(DTGoogleAuthHandler)handler;

@property (nonatomic, readonly) NSString *code;

@property (nonatomic, readonly) NSString *oauthToken;

@end
