//
//  User.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/21/16.
//
//

#import <Foundation/Foundation.h>
#import "User.h"

@implementation User

- (User *)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.userId = [dictionary[@"id"] integerValue];
        self.username = dictionary[@"username"];
        self.email = dictionary[@"email"];
        self.isAdmin = [dictionary[@"admin"] boolValue];
        self.authToken = dictionary[@"auth_token"];
    }
    
    return self;
}

@end
