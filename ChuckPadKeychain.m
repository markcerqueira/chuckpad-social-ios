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

- (void)clearCredentials {
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getUserIdKey]];
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getUsernameKey]];
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getEmailKey]];
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getPasswordKey]];
}

- (void)updatePassword:(NSString *)password {
    [[FXKeychain defaultKeychain] setObject:password forKey:[self getPasswordKey]];
}

- (void)authSucceededWithUser:(User *)user password:(NSString *)password {
    [[FXKeychain defaultKeychain] setObject:@(user.userId) forKey:[self getUserIdKey]];
    [[FXKeychain defaultKeychain] setObject:user.username forKey:[self getUsernameKey]];
    [[FXKeychain defaultKeychain] setObject:user.email forKey:[self getEmailKey]];
    [[FXKeychain defaultKeychain] setObject:password forKey:[self getPasswordKey]];
}

- (NSInteger)getLoggedInUserId {
    return [[[FXKeychain defaultKeychain] objectForKey:[self getUserIdKey]] integerValue];
}

- (NSString *)getLoggedInUserName {
    return [[FXKeychain defaultKeychain] objectForKey:[self getUsernameKey]];
}

- (NSString *)getLoggedInPassword {
    return [[FXKeychain defaultKeychain] objectForKey:[self getPasswordKey]];
}

- (NSString *)getLoggedInEmail {
    return [[FXKeychain defaultKeychain] objectForKey:[self getEmailKey]];
}

- (BOOL)isLoggedIn {
    for (NSString *key in @[[self getUserIdKey], [self getUsernameKey], [self getEmailKey], [self getPasswordKey]]) {
        if ([[FXKeychain defaultKeychain] objectForKey:key] == nil) {
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

- (NSString *)getPasswordKey {
    return [self getKeyForString:@"password"];
}

- (NSString *)getKeyForString:(NSString *)string {
    return [NSString stringWithFormat:@"%@%@%d", string, [[ChuckPadSocial sharedInstance] getBaseUrl], [[NSUserDefaults standardUserDefaults] integerForKey:@"Environment"]];
}

@end
