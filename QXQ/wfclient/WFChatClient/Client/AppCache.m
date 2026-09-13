//
//  AppCache.m
//  WildFireChat
//
//  Created by wtb on 2025/8/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "AppCache.h"
static AppCache *sharedSingleton = nil;

@implementation AppCache
+ (AppCache *)sharedAppCache {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[AppCache alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)saveMyInfo:(WFCCUserInfo *)user {
    [self saveFriendInfo:user];
}

- (WFCCUserInfo *)getMyInfo {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    return [self getFriendInfo:userId];
}

- (void)saveFriendInfo:(WFCCUserInfo *)user {
    NSString *myId = [NSString stringWithFormat:@"friend_user_%@",user.userId];
    [[NSUserDefaults standardUserDefaults] setObject:[user mj_JSONData] forKey:myId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (WFCCUserInfo *)getFriendInfo:(NSString *)userId {
    NSString *myId = [NSString stringWithFormat:@"friend_user_%@",userId];
    WFCCUserInfo *user = [WFCCUserInfo mj_objectWithKeyValues:[[NSUserDefaults standardUserDefaults] objectForKey:myId]];
    return user;
}


- (void)saveMyFriends:(NSArray<WFCCUserInfo *> *)friends {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *myId = [NSString stringWithFormat:@"friends_%@",userId];
    [[NSUserDefaults standardUserDefaults] setObject:[WFCCUserInfo mj_keyValuesArrayWithObjectArray:friends] forKey:myId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<WFCCUserInfo *> *)getMyFriends {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *myId = [NSString stringWithFormat:@"friends_%@",userId];
    NSArray *list = [WFCCUserInfo mj_objectArrayWithKeyValuesArray:[[NSUserDefaults standardUserDefaults] objectForKey:myId]];
    return list;
}

- (BOOL)isMyFriend:(NSString *)userId {
    NSArray *myFriends = [[AppCache sharedAppCache] getMyFriends];
    for (WFCCUserInfo *user in myFriends) {
        if ([user.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}
@end
