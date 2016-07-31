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

@implementation Patch {

    @private
    NSInteger _patchId;
    NSString *_name;
    NSString *_patchDescription;
    NSInteger _parentPatchId;
    BOOL _isFeatured;
    BOOL _isDocumentation;
    BOOL _hidden;
    NSInteger _creatorId;
    NSString *_creatorUsername;
    NSString *_contentType;
    NSString *_resourceUrl;
    NSString *_filename;
}

@synthesize name = _name;
@synthesize patchDescription = _patchDescription;
@synthesize parentPatchId = _parentPatchId;
@synthesize patchId = _patchId;
@synthesize isFeatured = _isFeatured;
@synthesize isDocumentation = _isDocumentation;
@synthesize hidden = _hidden;
@synthesize creatorId = _creatorId;
@synthesize creatorUsername = _creatorUsername;
@synthesize contentType = _contentType;
@synthesize resourceUrl = _resourceUrl;
@synthesize filename = _filename;

- (Patch *)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.patchId = [dictionary[@"id"] integerValue];
        self.name = dictionary[@"name"];
        if([dictionary[@"description"] isKindOfClass:[NSString class]])
            self.patchDescription = dictionary[@"description"];
        else
            self.patchDescription = nil;
        self.parentPatchId = [dictionary[@"parent_id"] integerValue];
        self.isFeatured = [dictionary[@"featured"] boolValue];
        self.isDocumentation = [dictionary[@"documentation"] boolValue];
        self.hidden = [dictionary[@"hidden"] boolValue];
        self.creatorId = [dictionary[@"creator_id"] integerValue];
        self.creatorUsername = dictionary[@"creator_username"];
        self.contentType = dictionary[@"content_type"];
        self.resourceUrl = dictionary[@"resource"];
        self.filename = dictionary[@"filename"];
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
            @"content_type" : self.contentType,
            @"resource" : self.resourceUrl,
            @"filename" : self.filename
    };
}

- (BOOL)hasParentPatch {
    return _parentPatchId != -1;
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
            [self.contentType isEqualToString:other.contentType] && [self.resourceUrl isEqualToString:other.resourceUrl] &&
            [self.filename isEqualToString:other.filename];
}

@end
