//
//  PatchResource.h
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 12/31/16.
//
//

#ifndef PatchResource_h
#define PatchResource_h

@interface PatchResource : NSObject

@property(nonatomic, retain) NSString *patchGUID;
@property(nonatomic, assign) NSInteger version;
@property(nonatomic, retain) NSDate *createdAt;

- (PatchResource *)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)asDictionary;

// With prefix = NO, "10:50 PM" is returned. With prefix = YES, "at 10:50 PM" is returned.
- (NSString *)getTimeResourceWasCreatedWithPrefix:(BOOL)prefix;

@end

#endif /* PatchResource_h */
