//
//  GroupService.h
//  WildFireChat
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GroupService : NSObject
+ (GroupService *)shared;

//登录后就默认加载一次
- (void)loadAllGroups;

//先从数据库返回，再从服务器获取刷新
- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int code, NSString *msg))errorBlock;

//从服务器获取刷新
- (void)getGroupInfo:(NSString *)groupId
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int code, NSString *msg))errorBlock;

- (void)getGroupMembers:(NSString *)groupId
            forceUpdate:(BOOL)forceUpdate
                success:(void(^)(NSArray<WFCCGroupMember *> *members))successBlock
                  error:(void(^)(int code, NSString *msg))errorBlock;

//从服务器获取刷新
- (void)getGroupMembers:(NSString *)groupId
                success:(void(^)(NSArray<WFCCGroupMember *> *members))successBlock
                  error:(void(^)(int code, NSString *msg))errorBlock;

- (void)getGroupMember:(NSString *)groupId
              memberId:(NSString *)memberId
               success:(void(^)(WFCCGroupMember *member))successBlock
                 error:(void(^)(int code, NSString *msg))errorBlock;

@end

NS_ASSUME_NONNULL_END
