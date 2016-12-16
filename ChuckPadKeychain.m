//
// Created by Mark Cerqueira on 7/25/16.
//

#import "ChuckPadKeychain.h"

#import "FXKeychain.h"
#import "ChuckPadSocial.h"
#import "User.h"

@implementation ChuckPadKeychain

+ (ChuckPadKeychain *)sharedInstance {
    static ChuckPadKeychain *_instance = nil;
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (FXKeychain *)keychain {
    return [FXKeychain defaultKeychain];
}

- (void)clearCredentials {
    [[self keychain] setObject:nil forKey:[self getUserIdKey]];
    [[self keychain] setObject:nil forKey:[self getUsernameKey]];
    [[self keychain] setObject:nil forKey:[self getEmailKey]];
    [[self keychain] setObject:nil forKey:[self getAuthTokenKey]];
}

- (void)authSucceededWithUser:(User *)user {
    [[self keychain] setObject:@(user.userId) forKey:[self getUserIdKey]];
    [[self keychain] setObject:user.username forKey:[self getUsernameKey]];
    [[self keychain] setObject:user.email forKey:[self getEmailKey]];
    [[self keychain] setObject:user.authToken forKey:[self getAuthTokenKey]];
}

- (NSInteger)getLoggedInUserId {
    return [[[self keychain] objectForKey:[self getUserIdKey]] integerValue];
}

- (NSString *)getLoggedInUserName {
    return [[self keychain] objectForKey:[self getUsernameKey]];
}

- (NSString *)getLoggedInEmail {
    return [[self keychain] objectForKey:[self getEmailKey]];
}

- (NSString *)getLoggedInAuthToken {
    return [[self keychain] objectForKey:[self getAuthTokenKey]];
}

- (BOOL)isLoggedIn {
    for (NSString *key in @[[self getUserIdKey], [self getUsernameKey], [self getEmailKey], [self getAuthTokenKey]]) {
        if ([[self keychain] objectForKey:key] == nil) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)getUserIdKey {
    return [self getKeyForString:@"userId"];
}

- (NSString *)getUsernameKey {
    return [self getKeyForString:@"username"];
}

- (NSString *)getEmailKey {
    return [self getKeyForString:@"email"];
}

- (NSString *)getAuthTokenKey {
    return [self getKeyForString:@"authToken"];
}

- (NSString *)getKeyForString:(NSString *)string {
    return [NSString stringWithFormat:@"%@_%@_%ld", string, [[ChuckPadSocial sharedInstance] getBaseUrl], (long)[[NSUserDefaults standardUserDefaults] integerForKey:ENVIRONMENT_KEY]];
}

// For unit testing only! Please do not call these methods!

static User *memoryUser;

+ (void)copyKeychainInfoToMemory {
    if (![[ChuckPadSocial sharedInstance] isLocalEnvironment]) {
        return;
    }
    
    memoryUser = [[User alloc] initWithDictionary:@{@"id" : @([[ChuckPadKeychain sharedInstance] getLoggedInUserId]),
                                                    @"username" : [[ChuckPadKeychain sharedInstance] getLoggedInUserName],
                                                    @"email": [[ChuckPadKeychain sharedInstance] getLoggedInEmail],
                                                    @"auth_token": [[ChuckPadKeychain sharedInstance] getLoggedInAuthToken]}];
}

+ (void)copyMemoryInfoToKeychain {
    if (![[ChuckPadSocial sharedInstance] isLocalEnvironment]) {
        return;
    }
    
    [[ChuckPadKeychain sharedInstance] authSucceededWithUser:memoryUser];
}

@end
