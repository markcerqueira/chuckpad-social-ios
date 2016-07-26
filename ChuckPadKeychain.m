//
// Created by Mark Cerqueira on 7/25/16.
//

#import "ChuckPadKeychain.h"

#import "FXKeychain.h"

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
    [[FXKeychain defaultKeychain] setObject:nil forKey:@"username"];
    [[FXKeychain defaultKeychain] setObject:nil forKey:@"email"];
    [[FXKeychain defaultKeychain] setObject:nil forKey:@"password"];
}

- (void)updatePassword:(NSString *)password {
    [[FXKeychain defaultKeychain] setObject:password forKey:@"password"];
}

- (void)authComplete:(NSString *)username withEmail:(NSString *)email withPassword:(NSString *)password {
    [[FXKeychain defaultKeychain] setObject:username forKey:@"username"];
    [[FXKeychain defaultKeychain] setObject:email forKey:@"email"];
    [[FXKeychain defaultKeychain] setObject:password forKey:@"password"];
}

- (NSString *)getLoggedInUserName {
    return [[FXKeychain defaultKeychain] objectForKey:@"username"];
}

- (NSString *)getLoggedInPassword {
    return [[FXKeychain defaultKeychain] objectForKey:@"password"];
}

- (NSString *)getLoggedInEmail {
    return [[FXKeychain defaultKeychain] objectForKey:@"email"];
}

- (BOOL)isLoggedIn {
    for (NSString *key in @[@"username", @"email", @"password"]) {
        if ([[FXKeychain defaultKeychain] objectForKey:key] == nil) {
            return NO;
        }
    }
    return YES;
}

@end
