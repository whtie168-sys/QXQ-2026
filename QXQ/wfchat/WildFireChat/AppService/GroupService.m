//
//  GroupService.m
//  WildFireChat
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "GroupService.h"
static GroupService *sharedton = nil;

@implementation GroupService
+ (GroupService *)shared {
    if (sharedton == nil) {
        @synchronized (self) {
            if (sharedton == nil) {
                sharedton = [[GroupService alloc] init];                
            }
        }
    }

    return sharedton;
}

- (void)receiveNotif {
    [[GroupService shared] loadAllGroups];
}

//登录后就默认加载一次
- (void)loadAllGroups {
    [[AppService sharedAppService] groupListQuery:^(NSArray<WFCCGroupInfo *> * _Nonnull groups) {
        [[WFCCGroupDB sharedManager] deleteAllGroup];
        [[WFCCGroupDB sharedManager] insertOrUpdateGroupInfos:groups];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:nil];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int code, NSString *msg))errorBlock {
    if (!groupId) {
        if (errorBlock) errorBlock(-1, @"invalid groupId");
        return;
    }
    
    // 直接从数据库取
    WFCCGroupInfo *local = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:groupId];
    if (local) {
        if (successBlock) successBlock(local);
    }
    
    if (refresh) {
        [[AppService sharedAppService] getGroupInfo:groupId success:^(WFCCGroupInfo *groupInfo) {
            [[WFCCGroupDB sharedManager] insertOrUpdateGroupInfo:groupInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated
                                                                object:groupId
                                                              userInfo:@{@"groupInfoList":groupInfo ? @[groupInfo] : @[]}];
            if (successBlock) successBlock(groupInfo);
        } error:^(int errCode, NSString *message) {
            // 从 DB 兜底
            WFCCGroupInfo *local = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:groupId];
            if (local) {
                if (successBlock) successBlock(local);
            } else {
                if (errorBlock) errorBlock(errCode, message);
            }
        }];
    }
}

//从服务器获取刷新
- (void)getGroupInfo:(NSString *)groupId
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int code, NSString *msg))errorBlock {
    [[AppService sharedAppService] getGroupInfo:groupId success:^(WFCCGroupInfo *groupInfo) {
        [[WFCCGroupDB sharedManager] insertOrUpdateGroupInfo:groupInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated
                                                            object:groupId
                                                          userInfo:@{@"groupInfoList":groupInfo ? @[groupInfo] : @[]}];
        if (successBlock) successBlock(groupInfo);
    } error:^(int errCode, NSString *message) {
        // 从 DB 兜底
        WFCCGroupInfo *local = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:groupId];
        if (local) {
            if (successBlock) successBlock(local);
        } else {
            if (errorBlock) errorBlock(errCode, message);
        }
    }];
}


- (void)getGroupMembers:(NSString *)groupId
            forceUpdate:(BOOL)forceUpdate
                success:(void(^)(NSArray<WFCCGroupMember *> *members))successBlock
                  error:(void(^)(int code, NSString *msg))errorBlock {
    
    if (!groupId) return;

    if (forceUpdate) {
        [[AppService sharedAppService] getGroupMembers:groupId success:^(NSArray<WFCCGroupMember *> *members) {
            //全量保存群成员前，先删除数据库里原来的旧的群成员，再保存
            [[WFCCGroupDB sharedManager] deleteGroupMembers:groupId];
            [[WFCCGroupDB sharedManager] insertOrUpdateGroupMembers:members groupId:groupId];
            if (successBlock) successBlock(members);
        } error:^(int code, NSString *msg) {
            NSLog(@"fetch group members error: %d, %@", code, msg);
            NSArray *result = [[WFCCGroupDB sharedManager] getGroupMembers:groupId];
            if (result) {
                if (successBlock) successBlock(result);
            } else {
                if (errorBlock) errorBlock(-2, @"group not found in db");
            }
        }];
    } else {
        // 先从本地数据库查
        NSArray *result = [[WFCCGroupDB sharedManager] getGroupMembers:groupId];
        if (successBlock) successBlock(result);
    }
}

- (void)getGroupMembers:(NSString *)groupId
                success:(void(^)(NSArray<WFCCGroupMember *> *members))successBlock
                  error:(void(^)(int code, NSString *msg))errorBlock {
    [[AppService sharedAppService] getGroupMembers:groupId success:^(NSArray<WFCCGroupMember *> *members) {
        //全量保存群成员前，先删除数据库里原来的旧的群成员，再保存
        [[WFCCGroupDB sharedManager] deleteGroupMembers:groupId];
        [[WFCCGroupDB sharedManager] insertOrUpdateGroupMembers:members groupId:groupId];
        if (successBlock) successBlock(members);
    } error:^(int code, NSString *msg) {
        NSLog(@"fetch group members error: %d, %@", code, msg);
        NSArray *result = [[WFCCGroupDB sharedManager] getGroupMembers:groupId];
        if (result) {
            if (successBlock) successBlock(result);
        } else {
            if (errorBlock) errorBlock(-2, @"group not found in db");
        }
    }];
}

//从服务器获取单个群成员
- (void)getGroupMember:(NSString *)groupId
              memberId:(NSString *)memberId
               success:(void(^)(WFCCGroupMember *member))successBlock
                 error:(void(^)(int code, NSString *msg))errorBlock {
    if (!groupId) return;
    
    [[AppService sharedAppService] getGroupMember:groupId
                                         memberId:memberId
                                          success:^(WFCCGroupMember * _Nonnull member) {
        [[WFCCGroupDB sharedManager] insertOrUpdateGroupMembers:@[member] groupId:groupId];
        if (successBlock) successBlock(member);
    } error:^(int errCode, NSString * _Nonnull message) {
        NSLog(@"fetch group members error: %d, %@", errCode, message);
        WFCCGroupMember *m = [[WFCCGroupDB sharedManager] getGroupMember:groupId memberId:memberId];
        if (m) {
            if (successBlock) successBlock(m);
        } else {
            if (errorBlock) errorBlock(-2, @"group not found in db");
        }
    }];
}

@end
