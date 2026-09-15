//
//  WFCCGroupDB.h
//  WFChatClient
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDB.h"
#import "WFCCGroupInfo.h"
#import "WFCCGroupMember.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCCGroupDB : NSObject
+ (instancetype)sharedManager;

// 初始化数据库
- (void)setupDB;

- (void)insertOrUpdateGroupInfo:(WFCCGroupInfo *)groupInfo;
- (void)insertOrUpdateGroupInfos:(NSArray<WFCCGroupInfo *> *)groupInfos;
- (BOOL)deleteGroupFromDB:(NSString *)groupId;
//删除所有群
- (void)deleteAllGroup;

//删除群里所有成员
- (void)deleteGroupMembers:(NSString *)groupId;

- (WFCCGroupInfo *)getGroupInfoFromDB:(NSString *)groupId;
- (NSArray<WFCCGroupInfo *> *)getGroupInfos:(NSArray<NSString *> *)groupIds;

- (void)insertOrUpdateGroupMembers:(NSArray<WFCCGroupMember *> *)members groupId:(NSString *)groupId;
- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId;
- (WFCCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId;
//获取群成员ids
- (NSArray<NSString *> *)getGroupMemberUserIds:(NSString *)groupId;
@end

NS_ASSUME_NONNULL_END
