//
// Created by Mark Cerqueira on 7/27/16.
//

#import <Foundation/Foundation.h>

// If no expiring time is specified, this default will be used.
extern const int TIME_TO_LIVE_SECONDS;

@interface PatchCache : NSCache

+ (PatchCache *)sharedInstance;

- (id)objectForKey:(id)key;

- (void)setObject:(id)obj forKey:(id)key;

- (void)setObject:(id)obj forKey:(id)key expire:(NSInteger)seconds;

- (void)removeObjectForKey:(id)key;

- (void)removeAllObjects;

@end