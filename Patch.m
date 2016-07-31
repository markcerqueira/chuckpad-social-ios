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

@implementation Patch

static NSDateFormatter *dateFormatter;

- (Patch *)initWithDictionary:(NSDictionary *)dictionary {
    // Initialize our static date formatter so we can convert Ruby DateTime objects to NSDate's properly
    // http://stackoverflow.com/a/26803370/265791
    // http://stackoverflow.com/a/9132422/265791
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    if (self = [super init]) {
        self.patchId = [dictionary[@"id"] integerValue];
        self.name = dictionary[@"name"];
        self.patchDescription = dictionary[@"description"];
        self.parentPatchId = [dictionary[@"parent_id"] integerValue];
        self.isFeatured = [dictionary[@"featured"] boolValue];
        self.isDocumentation = [dictionary[@"documentation"] boolValue];
        self.hidden = [dictionary[@"hidden"] boolValue];
        self.creatorId = [dictionary[@"creator_id"] integerValue];
        self.creatorUsername = dictionary[@"creator_username"];
        self.resourceUrl = dictionary[@"resource"];
        self.filename = dictionary[@"filename"];
        self.createdAt = [dateFormatter dateFromString:dictionary[@"created_at"]];
        self.updatedAt = [dateFormatter dateFromString:dictionary[@"updated_at"]];
        self.downloadCount = [dictionary[@"download_count"] integerValue];
    }

    return self;
}

- (NSDictionary *)asDictionary {
    return @{
            @"id" : @(self.patchId),
            @"name" : self.name,
            @"description" : self.patchDescription,
            @"parent_id" : @(self.parentPatchId),
            @"featured" : @(self.isFeatured),
            @"documentation" : @(self.isDocumentation),
            @"hidden" : @(self.hidden),
            @"creator_id" : @(self.creatorId),
            @"creator_username" : self.creatorUsername,
            @"resource" : self.resourceUrl,
            @"filename" : self.filename,
            @"created_at" : [dateFormatter stringFromDate:self.createdAt],
            @"updated_at" : [dateFormatter stringFromDate:self.updatedAt],
            @"download_count" : @(self.downloadCount)
    };
}

- (BOOL)hasParentPatch {
    return self.parentPatchId != -1;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"patchId = %ld; name = %@; documentation = %d, featured = %d", (long)self.patchId, self.name, self.isDocumentation, self.isFeatured];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    Patch *other = object;

    return self.patchId == other.patchId && [self.name isEqualToString:other.name] && [self.patchDescription isEqualToString:other.patchDescription] &&
            self.parentPatchId == other.parentPatchId && self.isFeatured == other.isFeatured && self.isDocumentation == other.isDocumentation &&
            self.hidden == other.hidden && self.creatorId == other.creatorId && [self.creatorUsername isEqualToString:other.creatorUsername] &&
            [self.resourceUrl isEqualToString:other.resourceUrl] && [self.filename isEqualToString:other.filename] &&
            [self.createdAt isEqual:other.createdAt] && [self.updatedAt isEqual:other.updatedAt] && self.downloadCount == other.downloadCount;
}

@end
