//
// Created by Mark Cerqueira on 7/27/16.
//

#import "PatchCache.h"

int const TIME_TO_LIVE = 3600;

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

- (id)objectForKey:(NSString *)key {
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
    [self setObject:obj forKey:key expire:TIME_TO_LIVE];
}

- (void)setObject:(id)obj forKey:(NSString *)key expire:(NSInteger)seconds {
    [super setObject:obj forKey:key];
    [self updateExpireKey:key expire:seconds];
}

- (void)removeObjectForKey:(NSString *)key {
    [super removeObjectForKey:key];
    [keyToExpireTimeDictionary removeObjectForKey:key];
}

- (void)removeAllObjects {
    [super removeAllObjects];
    [keyToExpireTimeDictionary removeAllObjects];
}

- (void)updateExpireKey:(NSString *)key expire:(NSInteger)seconds {
    [keyToExpireTimeDictionary setObject:[NSNumber numberWithFloat:([[NSDate date] timeIntervalSince1970] + seconds)]forKey:key];
}

- (BOOL)hasExpired:(NSString *)key {
    NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:[[keyToExpireTimeDictionary objectForKey:key] doubleValue]];
    return [expireDate timeIntervalSinceDate:[NSDate date]] > 0;
}

@end