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
    BOOL _isFeatured;
    BOOL _isDocumentation;
    BOOL _hidden;
    NSInteger _creatorId;
    NSString *_creatorUsername;
    NSString *_contentType;
    NSString *_resourceUrl;
    NSString *_filename;
}

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

- (NSString *)description {
    return [NSString stringWithFormat:@"patchId = %ld; name = %@; documentation = %d, featured = %d", (long)self.patchId, self.name, self.isDocumentation, self.isFeatured];
}

- (NSString *)getResourceUrl {
    return [NSString stringWithFormat:@"%@/%@", [[ChuckPadSocial sharedInstance] getBaseUrl], _resourceUrl];
}


@end
