//
//  LiveSession.m
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/3/18.
//

#import <Foundation/Foundation.h>

#import "LiveSession.h"

@implementation LiveSession

static NSDateFormatter *dateFormatter;

- (LiveSession *)initWithDictionary:(NSDictionary *)dictionary {
    // Initialize our static date formatter so we can convert Ruby DateTime objects to NSDate's properly
    // http://stackoverflow.com/a/26803370/265791
    // http://stackoverflow.com/a/9132422/265791
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    if (self = [super init]) {
        self.sessionGUID = dictionary[@"session_guid"];
        self.creatorID = [dictionary[@"creator_id"] integerValue];
        self.sessionTitle = dictionary[@"title"];
        self.creatorUsername = dictionary[@"creator_username"];
        self.state = [dictionary[@"state"] integerValue];
        self.occupancy = [dictionary[@"occupancy"] integerValue];
        self.createdAt = [dateFormatter dateFromString:dictionary[@"created_at"]];
        self.lastActive = [dateFormatter dateFromString:dictionary[@"last_active"]];
    }
    
    return self;
}

- (BOOL)isSessionOpen {
    return self.state == 0;
}

- (BOOL)isSessionClosed {
    return ![self isSessionOpen];
}

- (NSDictionary *)asDictionary {
    return @{ @"session_guid" : self.sessionGUID,
              @"creator_id" : @(self.creatorID),
              @"title" : self.sessionTitle,
              @"creator_username" : self.creatorUsername,
              @"state" : @(self.state),
              @"occupancy" : @(self.occupancy),
              @"created_at" : [dateFormatter stringFromDate:self.createdAt],
              @"last_active" : [dateFormatter stringFromDate:self.lastActive] };
}

@end
