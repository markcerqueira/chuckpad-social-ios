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

@property(nonatomic, retain) NSString *guid;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *patchDescription;
@property(nonatomic, assign) NSString *parentGUID;
@property(nonatomic, assign) NSInteger creatorId;
@property(nonatomic, retain) NSString *creatorUsername;
@property(nonatomic, assign) NSInteger abuseReportCount;
@property(nonatomic, assign) BOOL isFeatured;
@property(nonatomic, assign) BOOL isDocumentation;
@property(nonatomic, assign) BOOL hidden;
@property(nonatomic, retain) NSNumber *latitude;
@property(nonatomic, retain) NSNumber *longitude;
@property(nonatomic, assign) NSInteger revision;
@property(nonatomic, retain) NSString *resourceUrl;
@property(nonatomic, retain) NSString *extraResourceUrl;

// These times are in UTC. When first created, createdAt and updatedAt will be equal. As revisions
// are made, updatedAt will update, but createdAt will never update.
@property(nonatomic, retain) NSDate *createdAt;
@property(nonatomic, retain) NSDate *updatedAt;

@property(nonatomic, assign) NSInteger downloadCount;

- (Patch *)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)asDictionary;

- (BOOL)hasParentPatch;

- (BOOL)hasAnAbuseReport;

- (BOOL)hasExtraResource;

- (BOOL)hasLocation;

// With prefix = NO, "10:50 PM" is returned. With prefix = YES, "at 10:50 PM" is returned; note that
// "at" prefix is added)
- (NSString *)getTimeLastUpdatedWithPrefix:(BOOL)prefix;

- (NSString *)getTimeCreatedWithPrefix:(BOOL)prefix;

@end

#endif /* Patch_h */
