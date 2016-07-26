//
// Created by Mark Cerqueira on 7/25/16.
//
// A utility wrapper around FXKeychain for storing sensitive information. To use this library you probably
// never need to use this class or its method as ChuckPadSocial exposes everything relevant.

#import <Foundation/Foundation.h>


@interface ChuckPadKeychain : NSObject

+ (ChuckPadKeychain *)sharedInstance;

- (void)clearCredentials;

- (void)updatePassword:(NSString *)password;

- (void)authComplete:(NSString *)username withEmail:(NSString *)email withPassword:(NSString *)password;

- (NSString *)getLoggedInUserName;

- (NSString *)getLoggedInEmail;

- (NSString *)getLoggedInPassword;

- (BOOL)isLoggedIn;

@end
