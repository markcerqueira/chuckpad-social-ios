//
// Created by Mark Cerqueira on 7/27/16.
//

#import "PatchCache.h"

// Default cache TTL is 5 minutes
int const TIME_TO_LIVE_SECONDS = 5 * 60;

@implementation PatchCache {
    @private NSMutableDictionary *keyToExpireTimeDictionary;
}

+ (PatchCache *)sharedInstance {
    static PatchCache *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PatchCache alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        keyToExpireTimeDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)objectForKey:(id)key {
    id obj = [super objectForKey:key];
    if (obj == nil) {
        return nil;
    }

    if ([self hasExpired:key]) {
        [self removeObjectForKey:key];
        return nil;
    }
    
    return obj;
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    [self setObject:obj forKey:key expire:TIME_TO_LIVE_SECONDS];
}

- (void)setObject:(id)obj forKey:(NSString *)key expire:(NSInteger)seconds {
    [super setObject:obj forKey:key];
    [self updateExpireKey:key expire:seconds];
}

- (void)removeObjectForKey:(id)key {
    if ([key class])
    
    [super removeObjectForKey:key];
    [keyToExpireTimeDictionary removeObjectForKey:key];
}

- (void)removeAllObjects {
    [super removeAllObjects];
    [keyToExpireTimeDictionary removeAllObjects];
}

- (void)updateExpireKey:(NSString *)key expire:(NSInteger)seconds {
    [keyToExpireTimeDictionary setObject:[NSDate dateWithTimeIntervalSinceNow:seconds] forKey:key];
}

- (BOOL)hasExpired:(NSString *)key {
    return [[NSDate date] timeIntervalSinceDate:[keyToExpireTimeDictionary objectForKey:key]] > 0;
}

@end