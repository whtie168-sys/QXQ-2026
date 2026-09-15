//
//  WFCCConversationDB.h
//  WFChatClient
//
//  Created by wtb on 2025/8/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversationInfo.h"
#import "WKDB.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCCConversationDB : NSObject

+ (instancetype)sharedManager;

// 初始化数据库
- (void)setupDB;

- (WFCCMessage *)insert:(WFCCConversation *)conversation
                 sender:(NSString *)sender
                content:(WFCCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
                toUsers:(NSArray<NSString *> *)toUsers
             serverTime:(long long)serverTime;

- (NSArray<WFCCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes
                                                    lines:(NSArray<NSNumber *> *)lines;

- (WFCCConversationInfo *)getConversationInfo:(WFCCConversation *)conversation;

- (void)setConversation:(WFCCConversation *)conversation top:(BOOL)isTop;

- (void)setConversation:(WFCCConversation *)conversation silent:(BOOL)isSilent;

- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                                   from:(NSUInteger)fromIndex
                                   count:(NSInteger)count
                               withUser:(NSString *)user;

- (void)getMessagesV2:(WFCCConversation *)conversation
          contentTypes:(NSArray<NSNumber *> *)contentTypes
                  from:(NSUInteger)fromIndex
                 count:(NSInteger)count
              withUser:(NSString *)user
               success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock;

- (void)getMentionedMessages:(WFCCConversation *)conversation
                        from:(NSUInteger)fromIndex
                       count:(NSInteger)count
                     success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                       error:(void(^)(int error_code))errorBlock;

- (void)removeConversation:(WFCCConversation *)conversation clearMessage:(BOOL)clearMessage;

- (void)clearMessages:(WFCCConversation *)conversation before:(int64_t)before;

- (void)clearMessages:(WFCCConversation *)conversation;

- (void)clearAllMessages:(BOOL)removeConversation;

- (void)setConversation:(WFCCConversation *)conversation
              timestamp:(long long)timestamp;

- (long)getFirstUnreadMessageId:(WFCCConversation *)conversation;

- (void)setConversation:(WFCCConversation *)conversation draft:(NSString *)draft;

- (NSString *)getDraft:(WFCCConversation *)conversation;

- (BOOL)markAsUnRead:(WFCCConversation *)conversation syncToOtherClient:(BOOL)sync;

- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(WFCCConversation *)conversation;
- (void)saveReadDict:(NSDictionary *)dict forConversation:(WFCCConversation *)conversation;
- (void)syncReadTime:(long long)readTime forConversation:(WFCCConversation *)conversation;
@end

NS_ASSUME_NONNULL_END
