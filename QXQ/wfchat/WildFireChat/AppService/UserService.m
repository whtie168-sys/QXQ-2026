//
//  UserService.m
//  WildFireChat
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "UserService.h"
static UserService *shareduserton = nil;

@implementation UserService
+ (UserService *)shared {
    if (shareduserton == nil) {
        @synchronized (self) {
            if (shareduserton == nil) {
                shareduserton = [[UserService alloc] init];
            }
        }
    }

    return shareduserton;
}



//登录后就默认加载一次(包括文件传输助手，群通知用于会话列表)
- (void)loadAllFriend {
    [[AppService sharedAppService] friendList:^(NSArray<WFCCUserInfo *> * _Nonnull friends) {
        NSMutableArray *fileList = [NSMutableArray new];
        //去除黑名单
        for (WFCCUserInfo *friend in friends) {
            if ([friend.name isEqualToString:@"FireRobot"] || [friend.userId isEqualToString:@"FireRobot"] || // 86 Messenger
                [friend.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
                [friend.name isEqualToString:@"group_message"]) { // 群通知
                [fileList addObject:friend];
            }
        }
        [[WFCCUserDB sharedManager] deleteAllFriends];
        [[WFCCUserDB sharedManager] saveFriends:friends];
        [[WFCCUserDB sharedManager] insertOrUpdateUserInfos:fileList];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:nil];
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}

//获取所有好友
- (void)getMyFriendList:(BOOL)refresh
                success:(void(^)(NSArray<WFCCUserInfo *> *users, BOOL isCache))successBlock
                  error:(void(^)(int errorCode, NSString *message))errorBlock {
    // 先从本地数据库查
    NSArray *users = [[WFCCUserDB sharedManager] getAllFriendInfos];
    // 回调本地数据（即使是空也先回调一次）
    if (successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(users, YES);
        });
    }
    if (refresh) {
        [[AppService sharedAppService] friendList:^(NSArray<WFCCUserInfo *> * _Nonnull friends) {
            NSMutableArray *userList = [NSMutableArray new];
            //去除黑名单
            for (WFCCUserInfo *friend in friends) {
                if ([friend.name isEqualToString:@"FireRobot"] || [friend.userId isEqualToString:@"FireRobot"] || // 86 Messenger
                    [friend.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
                    [friend.name isEqualToString:@"group_message"]) { // 群通知
                    continue;
                }
                if ([[WFCCUserDB sharedManager] isBlackListed:friend.userId]) {
                    continue;
                }
                [userList addObject:friend];
            }
            
            //先删除数据库里的缓存
            [[WFCCUserDB sharedManager] deleteAllFriends];
            [[WFCCUserDB sharedManager] saveFriends:userList];

            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(userList, NO);
                });
            }

        } error:^(int errCode, NSString * _Nonnull message) {
            if (errorBlock) errorBlock(errCode, message);
        }];
    }
}

- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock {
    if (!userId.length) {
        if (errorBlock) errorBlock(-1, @"userId 为空");
        return;
    }
    
    // 先从本地数据库查, 查询用户表
    WFCCUserInfo *user = [[WFCCUserDB sharedManager] getUserInfo:userId];
    // 回调本地数据（即使是空也先回调一次）
    if (successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(user);
        });
    }
    
    if (refresh) {
        [[AppService sharedAppService] getUserInfo:userId
                                           success:^(WFCCUserInfo * _Nonnull userInfo) {
            // 存数据库
            [[WFCCUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
            if (successBlock) {
                successBlock(userInfo);
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            if (errorBlock) errorBlock(errCode, message);
        }];
    } else {
    }
}

//直接从服务器获取刷新
- (void)getUserInfo:(NSString *)userId
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock {
    [[AppService sharedAppService] getUserInfo:userId
                                       success:^(WFCCUserInfo * _Nonnull userInfo) {
        // 存数据库
        [[WFCCUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
        if (successBlock) {
            successBlock(userInfo);
        }
    } error:^(int errCode, NSString * _Nonnull message) {
        if (errorBlock) errorBlock(errCode, message);
    }];
}


- (void)getUserInfo:(NSString *)userId
            inGroup:(NSString *)groupId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock {
    if (!userId.length) {
        if (errorBlock) errorBlock(-1, @"userId 为空");
        return;
    }
    
    // 先从本地数据库查, 查询用户表
    WFCCUserInfo *user = [[WFCCUserDB sharedManager] getUserInfo:userId inGroup:groupId];
    // 回调本地数据（即使是空也先回调一次）
    if (successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(user);
        });
    }

    // 如果需要刷新，从服务器拉取
    if (refresh) {
        [[AppService sharedAppService] getUserInfo:userId
                                           success:^(WFCCUserInfo * _Nonnull userInfo) {
            // 存数据库
            [[WFCCUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
            // 如果是群内，查群成员表，补充 groupAlias
            if (groupId.length > 0 && userInfo) {
                [[AppService sharedAppService] getGroupMember:groupId
                                                     memberId:userId
                                                      success:^(WFCCGroupMember * _Nonnull member) {
                    userInfo.groupAlias = member.alias;
                    if (successBlock) {
                        successBlock(userInfo);
                    }
                } error:^(int errCode, NSString * _Nonnull message) {
                    
                }];
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            if (errorBlock) errorBlock(errCode, message);
        }];
    } else {

    }
}

//从群里批量获取个人信息
- (void)getUserInfos:(NSArray<NSString *> *)userIds
             inGroup:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(NSArray<WFCCUserInfo *> *users))successBlock
               error:(void(^)(int errorCode, NSString *message))errorBlock {
    if (refresh) {
        [[AppService sharedAppService] getUserInfos:userIds
                                            success:^(NSArray<WFCCUserInfo *> * _Nonnull users) {
            [[WFCCUserDB sharedManager] saveGroupMembers:groupId members:users];
            users = [[WFCCUserDB sharedManager] getUserInfos:userIds inGroup:groupId];
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(users);
                });
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
    } else {
        // 先从本地数据库查, 查询用户表
        NSArray *users = [[WFCCUserDB sharedManager] getUserInfos:userIds inGroup:groupId];
        // 回调本地数据（即使是空也先回调一次）
        if (successBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(users);
            });
        }
    }
}
@end
