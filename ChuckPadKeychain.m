//
// Created by Mark Cerqueira on 7/25/16.
//

#import "ChuckPadKeychain.h"

#import "FXKeychain.h"
#import "ChuckPadSocial.h"

@implementation ChuckPadKeychain {

}

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
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getUsernameKey]];
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getEmailKey]];
    [[FXKeychain defaultKeychain] setObject:nil forKey:[self getPasswordKey]];
}

- (void)updatePassword:(NSString *)password {
    [[FXKeychain defaultKeychain] setObject:password forKey:[self getPasswordKey]];
}

- (void)authComplete:(NSString *)username withEmail:(NSString *)email withPassword:(NSString *)password {
    [[FXKeychain defaultKeychain] setObject:username forKey:[self getUsernameKey]];
    [[FXKeychain defaultKeychain] setObject:email forKey:[self getEmailKey]];
    [[FXKeychain defaultKeychain] setObject:password forKey:[self getPasswordKey]];
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
    for (NSString *key in @[[self getUsernameKey], [self getEmailKey], [self getPasswordKey]]) {
        if ([[FXKeychain defaultKeychain] objectForKey:key] == nil) {
            return NO;
        }
    }
    return YES;
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
