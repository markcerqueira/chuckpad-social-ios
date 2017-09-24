//
//  Patch.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#import <Foundation/Foundation.h>
#import "Patch.h"
#import "ChuckPadSocial.h"
#import "NSDate+Helper.h"

@implementation Patch

static NSDateFormatter *dateFormatter;

- (Patch *)initWithDictionary:(NSDictionary *)dictionary {
    // Initialize our static date formatter so we can convert Ruby DateTime objects to NSDate's properly
    // http://stackoverflow.com/a/26803370/265791
    // http://stackoverflow.com/a/9132422/265791
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }

    if (self = [super init]) {
        self.guid = dictionary[@"guid"];
        self.name = dictionary[@"name"];
        self.patchDescription = dictionary[@"description"];
        self.isFeatured = [dictionary[@"featured"] boolValue];
        self.isDocumentation = [dictionary[@"documentation"] boolValue];
        self.hidden = [dictionary[@"hidden"] boolValue];
        self.latitude = [self safeGetNumberForKey:@"latitude" fromDictionary:dictionary];
        self.longitude = [self safeGetNumberForKey:@"longitude" fromDictionary:dictionary];
        self.creatorId = [dictionary[@"creator_id"] integerValue];
        self.creatorUsername = dictionary[@"creator_username"];
        self.abuseReportCount = [dictionary[@"abuse_count"] integerValue];
        self.resourceUrl = dictionary[@"resource"];
        self.createdAt = [dateFormatter dateFromString:dictionary[@"created_at"]];
        self.updatedAt = [dateFormatter dateFromString:dictionary[@"updated_at"]];
        self.downloadCount = [dictionary[@"download_count"] integerValue];
        self.parentGUID = [self safeGetStringForKey:@"parent_guid" fromDictionary:dictionary];
        self.revision = [dictionary[@"revision"] integerValue];
        self.extraResourceUrl = [self safeGetStringForKey:@"extra_resource" fromDictionary:dictionary];
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

- (NSNumber *)safeGetNumberForKey:(NSString *)key fromDictionary:(NSDictionary *)dictionary {
    if (dictionary[key] != nil && dictionary[key] != [NSNull null] && ![dictionary[key] isEqualToString:@""]) {
        return [NSNumber numberWithFloat:[dictionary[key] intValue]];
    } else {
        return nil;
    }
}

- (NSDictionary *)asDictionary {
    return @{ @"guid" : self.guid,
              @"name" : self.name,
              @"description" : self.patchDescription,
              @"featured" : @(self.isFeatured),
              @"documentation" : @(self.isDocumentation),
              @"hidden" : @(self.hidden),
              @"latitude" : self.latitude ?: [NSNull null],
              @"longitude" : self.longitude ?: [NSNull null],
              @"creator_id" : @(self.creatorId),
              @"creator_username" : self.creatorUsername,
              @"abuse_count" : @(self.abuseReportCount),
              @"resource" : self.resourceUrl,
              @"created_at" : [dateFormatter stringFromDate:self.createdAt],
              @"updated_at" : [dateFormatter stringFromDate:self.updatedAt],
              @"download_count" : @(self.downloadCount),
              @"parent_guid" : self.parentGUID,
              @"revision" : @(self.revision),
              @"extra_resource" : self.extraResourceUrl };
}

- (NSString *)getTimeLastUpdatedWithPrefix:(BOOL)prefix {
    return [self getTime:self.updatedAt WithPrefix:prefix];
}

- (NSString *)getTimeCreatedWithPrefix:(BOOL)prefix {
    return [self getTime:self.createdAt WithPrefix:prefix];
}

- (NSString *)getTime:(NSDate *)date WithPrefix:(BOOL)prefix {
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:date];
    return [NSDate stringForDisplayFromDate:[NSDate dateWithTimeInterval:seconds sinceDate:date] prefixed:prefix];
}

- (BOOL)hasParentPatch {
    return [self.parentGUID length] > 0;
}

- (BOOL)hasAnAbuseReport {
    return self.abuseReportCount > 0;
}

- (BOOL)hasExtraResource {
    return [self.extraResourceUrl length] > 0;
}

+ (BOOL)isLocationSet:(Patch *)patch {
    return patch.latitude != nil && patch.longitude != nil;
}

- (BOOL)locationIsEqual:(Patch *)other {
    BOOL locationIsEqual = YES;
    
    BOOL selfLocationIsSet = [Patch isLocationSet:self];
    BOOL otherLocationIsSet = [Patch isLocationSet:other];

    locationIsEqual &= selfLocationIsSet == otherLocationIsSet;
    
    if (selfLocationIsSet) {
        locationIsEqual &= self.latitude.intValue == other.latitude.intValue;
        locationIsEqual &= self.longitude.intValue == other.longitude.intValue;
    }

    return locationIsEqual;
}

- (BOOL)hasLocation {
    return self.latitude != nil && self.longitude != nil;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    Patch *other = object;
    
    BOOL areEqual = YES;
    
    areEqual &= [self.guid isEqualToString:other.guid] && [self.name isEqualToString:other.name];
    areEqual &= [self.patchDescription isEqualToString:other.patchDescription] && [self.resourceUrl isEqualToString:other.resourceUrl];
    areEqual &= self.isFeatured == other.isFeatured && self.isDocumentation == other.isDocumentation;
    areEqual &= self.hidden == other.hidden && self.creatorId == other.creatorId && [self.creatorUsername isEqualToString:other.creatorUsername];
    areEqual &= [self.createdAt isEqual:other.createdAt] && [self.updatedAt isEqual:other.updatedAt];
    areEqual &= self.downloadCount == other.downloadCount && [self.parentGUID isEqualToString:other.parentGUID];
    areEqual &= [self.extraResourceUrl isEqualToString:other.extraResourceUrl] && self.abuseReportCount == other.abuseReportCount;
    areEqual &= [self locationIsEqual:other];

    return areEqual;
}

@end
