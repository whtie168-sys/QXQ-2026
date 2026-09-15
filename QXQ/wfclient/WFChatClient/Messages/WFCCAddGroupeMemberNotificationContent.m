//
//  WFCCAddGroupeMemberNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCAddGroupeMemberNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"


@implementation WFCCAddGroupeMemberNotificationContent
- (NSString *)resolvedInvitorNameInGroup:(NSString *)groupId {
    if (self.invitor.length == 0) {
        return nil;
    }

    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.invitor inGroup:groupId];
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }
    if (userInfo.groupAlias.length > 0) {
        return userInfo.groupAlias;
    }
    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }
    return self.invitor.length > 0 ? self.invitor : nil;
}

- (NSString *)resolvedInvitorName {
    if (self.invitor.length == 0) {
        return nil;
    }

    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.invitor];
    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }
    return self.invitor.length > 0 ? self.invitor : nil;
}

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.invitor) {
        [dataDict setObject:self.invitor forKey:@"o"];
    }
    
    if (self.invitees) {
        [dataDict setObject:self.invitees forKey:@"ms"];
    }
    
    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if (payload.binaryContent) {
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            self.invitor = dictionary[@"o"];
            self.invitees = dictionary[@"ms"];
            self.groupId = dictionary[@"g"];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}



+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    BOOL isChinese = [WFCCIMService.main isChinese];
    NSString *formatMsg;
    if ([self.invitees count] == 1 && [[self.invitees objectAtIndex:0] isEqualToString:self.invitor]) {
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.invitor]) {
            formatMsg = (isChinese?@"你加入了群聊":@"You joined the group chat");
        } else {
            NSString *invitorName = [self resolvedInvitorNameInGroup:self.groupId];
            if (invitorName.length > 0) {
                formatMsg = [NSString stringWithFormat:@"%@%@", invitorName, (isChinese?@"加入了群聊":@" joined the group chat")];
            } else {
                formatMsg = (isChinese?@"加入了群聊":@"Joined the group chat");
            }
        }
        return formatMsg;
    }
    
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.invitor]) {
        formatMsg = (isChinese?@"你邀请":@"You invite");
    } else {
        NSString *invitorName = [self resolvedInvitorName];
        if (invitorName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", invitorName, (isChinese?@"邀请":@" Invite")];
        } else {
            formatMsg = (isChinese?@"邀请":@"Invite");
        }
    }
    
    int count = 0;
    if([self.invitees containsObject:[WFCCNetworkService sharedInstance].userId]) {
        formatMsg = [formatMsg stringByAppendingString:(isChinese?@" 你":@" you")];
        count++;
    }

    for (NSString *member in self.invitees) {
        if ([member isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            continue;
        } else {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:member];
            if (userInfo.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", member];
            }
            
            count++;
            if(count >= 4) {
                break;
            }
        }
    }
    
    if (self.invitees.count > count) {
        if (isChinese) {
            formatMsg = [formatMsg stringByAppendingFormat:@" 等%ld名成员", self.invitees.count];
        }else {
            formatMsg = [formatMsg stringByAppendingFormat:@" %ld members", self.invitees.count];
        }
    }
    formatMsg = [formatMsg stringByAppendingString:(isChinese?@"加入了群聊":@" joined the group chat")];
    return formatMsg;
}
@end
