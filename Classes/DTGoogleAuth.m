//
//  DTGoogleAuth.m
//  DTGoogleAuth
//
//  Created by Diego Torres on 05-05-15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "DTGoogleAuth.h"

#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED)

#define DTQueryComponentsMinVersion NSFoundationVersionNumber10_9_2
#define DTNoQueryItemsMinimum (__MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_10)
@import AppKit.NSWorkspace;

#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "DTSafariViewController.h"
#define DTQueryComponentsMinVersion NSFoundationVersionNumber_iOS_7_1
#define DTNoQueryItemsMinimum (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
@import UIKit.UIApplication;
@import SafariServices;

#endif

#if DTNoQueryItemsMinimum
#import "CMDQueryStringReader.h"
#endif

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@interface DTGoogleAuth () <DTSafariViewControllerDelegate>
#else
@interface DTGoogleAuth ()
#endif

@property (nonatomic, strong) NSString *redirectURI;
@property (nonatomic, strong) NSString *secretIdentifier;
@property (nonatomic, strong) NSString *clientIdentifier;
@property (nonatomic, strong) DTGoogleAuthHandler handler;
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@property (nonatomic, weak) UIViewController *safariVC;
#endif
@end

@implementation DTGoogleAuth

__weak static NSURLSession *_session;
+ (NSURLSession *)session
{
    NSURLSession *session = _session;
    if (!session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config];
        _session = session;
    }
    return session;
}

+ (NSMutableDictionary *)activeAuthentications
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *_activeAuths;
    dispatch_once(&onceToken, ^{
        _activeAuths = [NSMutableDictionary new];
    });
    return _activeAuths;
}

#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
+(void)initialize
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    __unused OSStatus status = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)(bundleIdentifier), (__bridge CFStringRef)(bundleIdentifier));
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleEvent:replyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}
+(void)handleEvent:(NSAppleEventDescriptor *)event replyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    [self handleURL:[NSURL URLWithString:urlString]];
}
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self handleURL:url];
}
#endif

+ (BOOL)handleURL:(NSURL *)url
{
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID caseInsensitiveCompare:url.scheme] != NSOrderedSame) {
        return NO;
    }
    
    NSArray *pathComponents = url.pathComponents;
    if (pathComponents.count == 0 || [pathComponents.lastObject caseInsensitiveCompare:@"DTGoogleAuth"] != NSOrderedSame) {
        return NO;
    }
    
    NSDictionary *queryComponents;
    if (floor(NSFoundationVersionNumber) > DTQueryComponentsMinVersion) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSArray *queryItems = components.queryItems;
        queryComponents = [NSDictionary dictionaryWithObjects:[queryItems valueForKey:NSStringFromSelector(@selector(value))]
                                                      forKeys:[queryItems valueForKey:NSStringFromSelector(@selector(name))]];
    }
#if DTNoQueryItemsMinimum
    else {
        queryComponents = [[[CMDQueryStringReader alloc] initWithString:url.query] dictionaryValue];
    }
#endif
    
    NSString *stateIdentifier = queryComponents[@"state"];
    NSMutableDictionary *activeAuths = [self activeAuthentications];
    DTGoogleAuth *auth = [activeAuths objectForKey:stateIdentifier];
    
    if (!auth) {
        return NO;
    }
    [activeAuths removeObjectForKey:stateIdentifier];
    
    NSString *code = queryComponents[@"code"];
    DTGoogleAuthHandler handler = auth.handler;
    auth.handler = nil;    
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    [auth.safariVC dismissViewControllerAnimated:YES completion:NULL];
#endif
    
    if (code) {
        auth->_code = code;
        NSString *secret = auth.secretIdentifier;
        auth.secretIdentifier = nil;
        
        if (secret) {
            [auth oauthTokenWithSecretIdentifier:secret completion:handler];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                handler(auth, nil);
            });
        }
    } else {
        NSString *errorString = queryComponents[@"error"];
        ACErrorCode errorCode = ACErrorUnknown;
        if ([errorString isEqualToString:@"access_denied"]) {
            errorCode = ACErrorPermissionDenied;
        } else if ([errorString isEqualToString:@"invalid_request"]) {
            errorCode = ACErrorAccessInfoInvalid;
        } else if ([errorString isEqualToString:@"unauthorized_client"]) {
            errorCode = ACErrorClientPermissionDenied;
        }
        NSError *error = [NSError errorWithDomain:DTGoogleErrorDomain code:errorCode userInfo:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            handler(nil, error);
        });
    }
    return YES;
}

+ (void)authenticateWithScopes:(NSArray *)scopes clientIdentifier:(NSString *)identifier completion:(DTGoogleAuthHandler)handler
{
    [self authenticateWithScopes:scopes clientIdentifier:identifier secretIdentifier:nil completion:handler];
}

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (void)authenticateWithScopes:(NSArray *)scopes clientIdentifier:(NSString *)identifier secretIdentifier:(NSString *)secretIdentifier completion:(DTGoogleAuthHandler)handler
{
    [self authenticateWithScopes:scopes clientIdentifier:identifier secretIdentifier:secretIdentifier fromViewController:nil completion:handler];
}
#endif

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (void)authenticateWithScopes:(NSArray *)scopes clientIdentifier:(NSString *)clientIdentifier secretIdentifier:(NSString *)secretIdentifier fromViewController:(UIViewController *)controller completion:(DTGoogleAuthHandler)handler
#else
+ (void)authenticateWithScopes:(NSArray *)scopes clientIdentifier:(NSString *)clientIdentifier secretIdentifier:(NSString *)secretIdentifier completion:(DTGoogleAuthHandler)handler
#endif
{
    NSParameterAssert(scopes.count > 0);
    NSParameterAssert(clientIdentifier);
    NSParameterAssert(handler);
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *redirectURI = [bundleID stringByAppendingString:@":/DTGoogleAuth"];
    NSString *scope = [scopes componentsJoinedByString:@" "];
    NSString *localState = [[NSUUID UUID] UUIDString];
    NSString *path = [NSString stringWithFormat:@"/o/oauth2/auth?scope=%@&state=%@&redirect_uri=%@&response_type=code&client_id=%@&access_type=online", [scope stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], localState, redirectURI, clientIdentifier];
    
    DTGoogleAuth *auth = [DTGoogleAuth new];
    auth.handler = handler;
    auth.redirectURI = redirectURI;
    auth.clientIdentifier = clientIdentifier;
    auth.secretIdentifier = secretIdentifier;

    [[self activeAuthentications] setObject:auth forKey:localState];
    
    NSURL *generatedURL = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:@"https://accounts.google.com"]];
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    [[NSWorkspace sharedWorkspace] openURL:generatedURL];
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    generatedURL = [generatedURL absoluteURL];
    if (controller) {
        while (controller.presentedViewController) {
            controller = controller.presentedViewController;
        }
        
        DTSafariViewController *webController = [[DTSafariViewController alloc] initWithURL:generatedURL];
        webController.delegate = (id)auth;
        auth.safariVC = webController;
        if ([webController isKindOfClass:[DTSafariViewController class]]) {
            webController = (id)[[UINavigationController alloc] initWithRootViewController:webController];
        }
        [controller presentViewController:webController animated:YES completion:NULL];
    } else {
        [[UIApplication sharedApplication] openURL:generatedURL];
        [[NSNotificationCenter defaultCenter] addObserver:auth selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
#endif
}

- (void)oauthTokenWithSecretIdentifier:(NSString *)secretIdentifier completion:(DTGoogleAuthHandler)handler
{
    NSURL *googleURL = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v3/token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:googleURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[NSString stringWithFormat:@"grant_type=authorization_code&client_id=%@&client_secret=%@&redirect_uri=%@&code=%@", self.clientIdentifier, secretIdentifier, self.redirectURI, self.code] dataUsingEncoding:NSUTF8StringEncoding];
    
    [[[self.class session] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        DTGoogleAuth *authObject = self;
        NSString *accessToken;
        if (!error) {
            authObject->_code = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (![dict isKindOfClass:[NSDictionary class]]) {
                dict = nil;
            }
            
            accessToken = [dict objectForKey:@"access_token"];
            if (accessToken.length == 0) {
                error = [NSError errorWithDomain:DTGoogleErrorDomain code:ACErrorUnknown userInfo:nil];
            }
        }
        
        authObject->_oauthToken = accessToken;
        if (error) {
            authObject = nil;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            handler(authObject, error);
        });
    }] resume];
}

#pragma mark - SFSafariVC delegate
    
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DTGoogleAuthHandler handler = self.handler;
    self.handler = nil;
    
    if (handler) {
        NSError *error = [NSError errorWithDomain:DTGoogleErrorDomain code:ACErrorAccountAuthenticationFailed userInfo:nil];
        handler(nil, error);
    }
}

- (void)safariViewControllerDidFinish:(nonnull UIViewController *)controller
{
    DTGoogleAuthHandler handler = self.handler;
    self.handler = nil;
    [controller dismissViewControllerAnimated:YES completion:^{
        if (handler) {
            NSError *error = [NSError errorWithDomain:DTGoogleErrorDomain code:ACErrorAccountAuthenticationFailed userInfo:nil];
            handler(nil, error);
        }
    }];
}
#endif

@end
