//
//  WFCCCreateGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCCreateGroupNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCCreateGroupNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.creator) {
        [dataDict setObject:self.creator forKey:@"o"];
    }
    if (self.groupName) {
        [dataDict setObject:self.groupName forKey:@"n"];
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
    NSError *__error = nil;
    if (payload.binaryContent) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            self.creator = dictionary[@"o"];
            self.groupName = dictionary[@"n"];
            self.groupId = dictionary[@"g"];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CREATE_GROUP;
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
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.creator]) {
        return [NSString stringWithFormat:@"%@\"%@\"", (isChinese?@"你创建了群":@"You created the group "), self.groupName];
    } else {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.creator inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            return [NSString stringWithFormat:@"%@%@\"%@\"", userInfo.alias, (isChinese?@"创建了群":@" created a group chat "), self.groupName];
        } else if(userInfo.groupAlias.length > 0) {
            return [NSString stringWithFormat:@"%@%@\"%@\"", userInfo.groupAlias, (isChinese?@"创建了群":@" created a group chat "), self.groupName];
        } else if (userInfo.displayName.length > 0) {
            return [NSString stringWithFormat:@"%@%@\"%@\"", userInfo.displayName, (isChinese?@"创建了群":@" created a group chat "), self.groupName];
        } else {
            if (isChinese) {
                return [NSString stringWithFormat:@"用户<%@>创建了群\"%@\"", self.creator, self.groupName];
            }else {
                return [NSString stringWithFormat:@"User <%@> created a group chat \"%@\"", self.creator, self.groupName];
            }
        }
    }
}

@end
