//
//  WFCCAnnouncementMessageContent.m
//  WUHOIBDK
//
//  Created by Ruby on 11/30/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WFCCAnnouncementMessageContent.h"
#import "Common.h"
#import "WFCCIMService.h"

@implementation WFCCAnnouncementMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.searchableContent = self.text;
    payload.mentionedType = self.mentionedType;
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    
    self.text = payload.searchableContent;
    self.mentionedType = payload.mentionedType;
}

+ (int)getContentType {
    return GROUP_ANNOUNCEMENT_MESSAGE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (instancetype)announcementWith:(NSString *)text {
    WFCCAnnouncementMessageContent *announcement = [[WFCCAnnouncementMessageContent alloc] init];
    announcement.text = text;
    return announcement;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return ([WFCCIMService.main isChinese]?@"[公告]":@"[Announcement]");
}

@end
