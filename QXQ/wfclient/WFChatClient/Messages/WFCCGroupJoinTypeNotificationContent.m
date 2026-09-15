//
//  WFCCCreateGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCGroupJoinTypeNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCGroupJoinTypeNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operatorId) {
        [dataDict setObject:self.operatorId forKey:@"o"];
    }
    if (self.type) {
        [dataDict setObject:self.type forKey:@"n"];
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
    if (!payload.binaryContent) {
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.operatorId = dictionary[@"o"];
        self.type = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANGE_JOINTYPE;
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
    NSString *user = (isChinese?@"你":@"You");
    if (![[WFCCNetworkService sharedInstance].userId isEqualToString:self.operatorId]) {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.operatorId inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            user = userInfo.alias;
        } else if(userInfo.groupAlias.length > 0) {
            user = userInfo.groupAlias;
        } else if (userInfo.displayName.length > 0) {
            user = userInfo.displayName;
        } else {
            user = [NSString stringWithFormat:@"%@<%@>",(isChinese?@"管理员":@"Administrator"), self.operatorId];
        }
    }
    
    if ([self.type isEqualToString:@"0"]) {
        return [NSString stringWithFormat:@"%@%@", user, (isChinese?@"开放了加入群组功能":@" has enabled the function of joining groups")];
    } else if ([self.type isEqualToString:@"1"]) {
        return [NSString stringWithFormat:@"%@%@", user, (isChinese?@"仅允许群成员邀请加入群组":@" only allows group members to invite you to join the group")];
    } else {
        return [NSString stringWithFormat:@"%@", user, (isChinese?@"关闭了加入群组功能":@" disables the group joining function")];
    }
    
}
@end
