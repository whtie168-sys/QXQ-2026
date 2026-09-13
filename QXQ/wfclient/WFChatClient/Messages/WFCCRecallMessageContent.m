//
//  WFCCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCRecallMessageContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"


@implementation WFCCRecallMessageContent
- (WFCCMessagePayload *)encode {
    //注意：在proto层收到撤回命令或主动撤回成功会直接更新被撤回的消息，如果修改encode&decode，需要同步修改
    WFCCMessagePayload *payload = [super encode];
    payload.content = self.operatorId;
    payload.binaryContent = [[[NSNumber numberWithLongLong:self.messageUid] stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    //注意：在proto层收到撤回命令或主动撤回成功会直接更新被撤回的消息，如果修改encode&decode，需要同步修改
    self.operatorId = payload.content;
    self.messageUid = [[[NSString alloc] initWithData:payload.binaryContent encoding:NSUTF8StringEncoding] longLongValue];
    if (self.extra.length) {
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.extra dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            self.originalSender = dictionary[@"s"];
            self.originalContentType = [dictionary[@"t"] intValue];
            self.originalSearchableContent = dictionary[@"sc"];
            self.originalContent = dictionary[@"c"];
            self.originalExtra = dictionary[@"e"];
            self.originalMessageTimestamp = [dictionary[@"ts"] longLongValue];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_RECALL;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}


+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    return [self digest:message];
}


- (NSString *)digest:(WFCCMessage *)message {
    BOOL isChinese = [WFCCIMService.main isChinese];
    if ([self.operatorId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
//        return WFCCString(@"YouRecallAMessage");
        return (isChinese ? @"你撤回了一条消息" : @"You recall a message.");
    } else {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.operatorId];
        if (userInfo.alias.length) {
            if (isChinese) {
                return [NSString stringWithFormat:@"%@撤回了一条消息", userInfo.alias];
            }else {
                return [NSString stringWithFormat:@"%@ recall a message.", userInfo.alias];
            }
        }
        if (userInfo.displayName != nil) {
            if (isChinese) {
                return [NSString stringWithFormat:@"%@撤回了一条消息", userInfo.displayName];
            }else {
                return [NSString stringWithFormat:@"%@ recall a message.", userInfo.displayName];
            }
        }
        if (isChinese) {
            return [NSString stringWithFormat:@"%@撤回了一条消息", self.operatorId];
        }else {
            return [NSString stringWithFormat:@"%@ recall a message.", self.operatorId];
        }
    }
}
@end
