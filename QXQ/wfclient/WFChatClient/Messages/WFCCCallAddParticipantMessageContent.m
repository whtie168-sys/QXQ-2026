//
//  WFCCCallAddParticipantMessageContent.m
//  Chat86AVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCCallAddParticipantMessageContent.h"

@implementation WFCCCallAddParticipantMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.content = self.callId;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.initiator forKey:@"initiator"];
    if (self.pin) {
        [dict setObject:self.pin forKey:@"pin"];
    }
    
    [dict setObject:self.participants forKey:@"participants"];
    [dict setObject:@(self.audioOnly == YES ? 1:0) forKey:@"audioOnly"];
    [dict setObject:self.existParticipants forKey:@"existParticipants"];
    if(self.autoAnswer) {
        [dict setObject:@(self.autoAnswer) forKey:@"autoAnswer"];
    }
    if(self.clientId.length) {
        [dict setObject:self.clientId forKey:@"clientId"];
    }
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:kNilOptions
                                                     error:nil];
    
    NSMutableDictionary *pd = [@{@"callId":self.callId, @"audioOnly":@(self.audioOnly)} mutableCopy];
    if(self.participants.count) {
        [pd setObject:self.participants forKey:@"participants"];
    }
    
    if(self.existParticipants.count) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        [self.existParticipants enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj[@"userId"]) {
                [arr addObject:obj[@"userId"]];
            }
        }];
        [pd setObject:arr forKey:@"existParticipants"];
    }
    
    payload.pushData = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:pd options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.callId = payload.content;
    if (!payload.binaryContent) {
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.initiator = dictionary[@"initiator"];
        self.pin = dictionary[@"pin"];
        self.participants = dictionary[@"participants"];
        self.audioOnly = [dictionary[@"audioOnly"] boolValue];
        self.existParticipants = dictionary[@"existParticipants"];
        self.autoAnswer = [dictionary[@"autoAnswer"] boolValue];
        self.clientId = [self getString:dictionary ofKey:@"clientId"];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_TYPE_ADD_PARTICIPANT;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}


- (NSString *)digest:(WFCCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    BOOL isChinese = [WFCCIMService.main isChinese];
    WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:message.fromUser inGroup:message.conversation.type == Group_Type ? message.conversation.target : nil];
    NSString *format = @"";
    if ([message.fromUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        format = [format stringByAppendingString:(isChinese?@"您":@"You")];
    } else if (sender.alias.length) {
        format = [format stringByAppendingString:sender.alias];
    } else if(sender.groupAlias.length) {
        format = [format stringByAppendingString:sender.groupAlias];
    } else if(sender.displayName.length) {
        format = [format stringByAppendingString:sender.displayName];
    }
    
    if (!format) {
        format = @"";
    }
    
    format = [format stringByAppendingString:(isChinese?@" 邀请":@" invite")];
    
    for (NSString *p in self.participants) {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:p inGroup:message.conversation.type == Group_Type ? message.conversation.target : nil];
    
        if ([p isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            format = [format stringByAppendingString:(isChinese?@" 您 ":@" you ")];
        } else if (userInfo.alias.length) {
            format = [format stringByAppendingFormat:@" %@ ", userInfo.alias];
        } else if(userInfo.groupAlias.length) {
            format = [format stringByAppendingFormat:@" %@ ", userInfo.groupAlias];
        } else if(sender.displayName.length) {
            format = [format stringByAppendingFormat:@" %@ ", userInfo.displayName];
        }
    }
    
    format = [format stringByAppendingString:(isChinese?@"加入了网络通话":@" joined the network call")];
    
    return format;
}

@end
