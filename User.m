//
//  User.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/21/16.
//
//

#import <Foundation/Foundation.h>
#import "User.h"

@implementation User  {
    
@private
    NSInteger _userId;
    NSString *_username;
    NSString *_email;
    BOOL _isAdmin;
}

@synthesize userId = _userId;
@synthesize username = _username;
@synthesize email = _email;
@synthesize isAdmin = _isAdmin;

- (User *)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.userId = [dictionary[@"id"] integerValue];
        self.username = dictionary[@"username"];
        self.email = dictionary[@"email"];
        self.isAdmin = [dictionary[@"admin"] boolValue];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"userId = %d; username = %@; email = %@, isAdmin = %d", self.userId, self.username, self.email, self.isAdmin];
}

@end