//
// Created by Mark Cerqueira on 7/25/16.
//
// A utility wrapper around FXKeychain for storing sensitive information. To use this library you probably
// never need to use this class or its method as ChuckPadSocial exposes everything relevant.

#import <Foundation/Foundation.h>

@class User;

@interface ChuckPadKeychain : NSObject

+ (ChuckPadKeychain *)sharedInstance;

- (void)clearCredentials;

- (void)authSucceededWithUser:(User *)user;

- (NSInteger)getLoggedInUserId;

- (NSString *)getLoggedInUserName;

- (NSString *)getLoggedInEmail;

- (NSString *)getLoggedInAuthToken;

- (BOOL)isLoggedIn;

@end
