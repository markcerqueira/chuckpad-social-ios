//
//  PatchResource.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 12/31/16.
//
//

#import <Foundation/Foundation.h>

#import "PatchResource.h"
#import "NSDate+Helper.h"

@implementation PatchResource

static NSDateFormatter *dateFormatter;

- (PatchResource *)initWithDictionary:(NSDictionary *)dictionary {
    // Initialize our static date formatter so we can convert Ruby DateTime objects to NSDate's properly
    // http://stackoverflow.com/a/26803370/265791
    // http://stackoverflow.com/a/9132422/265791
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    if (self = [super init]) {
        self.patchGUID = dictionary[@"guid"];
        self.version = [dictionary[@"version"] integerValue];
        self.createdAt = [dateFormatter dateFromString:dictionary[@"created_at"]];
    }

    return self;
}

// Use this method to get any parameters that may come down null or are optional. We default to using @"" when not
// present over nil so we can more implement the asDictionary and equals methods.
- (NSString *)safeGetStringForKey:(NSString *)key fromDictionary:(NSDictionary *)dictionary {
    if (dictionary[key] != nil && dictionary[key] != [NSNull null]) {
        return dictionary[key];
    } else {
        return @"";
    }
}

- (NSDictionary *)asDictionary {
    return @{ @"guid" : self.patchGUID,
              @"version" : @(self.version),
              @"created_at" : [dateFormatter stringFromDate:self.createdAt] };
}

- (NSString *)getTimeResourceWasCreatedWithPrefix:(BOOL)prefix {
    return [self getTime:self.createdAt WithPrefix:prefix];
}

- (NSString *)getTime:(NSDate *)date WithPrefix:(BOOL)prefix {
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:date];
    return [NSDate stringForDisplayFromDate:[NSDate dateWithTimeInterval:seconds sinceDate:date] prefixed:prefix];
}

@end
