//
//  AppCache.h
//  WildFireChat
//
//  Created by wtb on 2025/8/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppCache : NSObject
+ (AppCache *)sharedAppCache;

- (void)saveMyInfo:(WFCCUserInfo *)user;
- (WFCCUserInfo *)getMyInfo;
//- (void)saveFriendInfo:(WFCCUserInfo *)user;
//- (WFCCUserInfo *)getFriendInfo:(NSString *)userId;

//- (void)saveMyFriends:(NSArray<WFCCUserInfo *> *)friends;
//- (NSArray<WFCCUserInfo *> *)getMyFriends;
//- (BOOL)isMyFriend:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
