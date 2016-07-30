//
//  Patch.h
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#ifndef Patch_h
#define Patch_h

@interface Patch : NSObject

@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *patchDescription;
@property(nonatomic, assign) NSInteger patchId;
@property(nonatomic, assign) NSInteger parentPatchId;
@property(nonatomic, assign) NSInteger creatorId;
@property(nonatomic, retain) NSString *creatorUsername;
@property(nonatomic, assign) BOOL isFeatured;
@property(nonatomic, assign) BOOL isDocumentation;
@property(nonatomic, assign) BOOL hidden;
@property(nonatomic, retain) NSString *filename;
@property(nonatomic, retain) NSString *contentType;
@property(nonatomic, retain) NSString *resourceUrl;

- (Patch *)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)asDictionary;

- (BOOL)hasParentPatch;

- (NSString *)description;

@end


#endif /* Patch_h */
