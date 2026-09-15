//
//  WFCCMessageContentFactory.m
//  WFChatClient
//
//  Created by wtb on 2025/9/2.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCMessageContentFactory.h"
#import "WFCCMessageContent.h"
#import "WFCCTextMessageContent.h"
#import "WFCCImageMessageContent.h"
#import "WFCCUnknownMessageContent.h"

#import "WFCCTextMessageContent.h"
#import "WFCCImageMessageContent.h"
#import "WFCCVideoMessageContent.h"
#import "WFCCFileMessageContent.h"
#import "WFCCLocationMessageContent.h"
#import "WFCCUnknownMessageContent.h"
#import "Common.h"

@implementation WFCCMessageContentFactory

//适配野火的返回
+ (WFCCMessageContent *)messageContentFromJSONString:(NSString *)jsonString {
    if (!jsonString || jsonString.length == 0) {
        return nil;
    }
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || !dict) {
        NSLog(@"Failed to parse JSON payload: %@", error);
        return nil;
    }
    
    NSInteger type = [dict[@"type"] integerValue];
    WFCCMessageContent *content = nil;
    
    // 构建 WFCCMessagePayload
    WFCCMessagePayload *payload;

    // 根据 type 创建对应子类
    switch (type) {
        //文本消息
        case MESSAGE_CONTENT_TYPE_TEXT:
            payload = [[WFCCMessagePayload alloc] init];
            content = [[WFCCTextMessageContent alloc] init];
            break;
            
        //语音消息
        case MESSAGE_CONTENT_TYPE_SOUND:
            break;
            
        //图片消息
        case MESSAGE_CONTENT_TYPE_IMAGE:
            content = [[WFCCImageMessageContent alloc] init];
            payload = [[WFCCMediaMessagePayload alloc] init];
            ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = dict[@"remoteMediaUrl"];
            ((WFCCMediaMessagePayload *)payload).localMediaPath = dict[@"localMediaPath"];
            ((WFCCMediaMessagePayload *)payload).mediaType = [dict[@"mediaType"] intValue];
            break;
        
        //位置消息
        case MESSAGE_CONTENT_TYPE_LOCATION:
            content = [[WFCCLocationMessageContent alloc] init];
            break;
           
        //文件消息
        case MESSAGE_CONTENT_TYPE_FILE:
            content = [[WFCCFileMessageContent alloc] init];
            break;
        
        //视频消息
        case MESSAGE_CONTENT_TYPE_VIDEO:
            content = [[WFCCVideoMessageContent alloc] init];
            payload = [[WFCCMediaMessagePayload alloc] init];
            ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = dict[@"remoteMediaUrl"];
            ((WFCCMediaMessagePayload *)payload).localMediaPath = dict[@"localMediaPath"];
            ((WFCCMediaMessagePayload *)payload).mediaType = [dict[@"mediaType"] intValue];
            break;

            //动态表情消息
        case MESSAGE_CONTENT_TYPE_STICKER:
//            content = [[WFCCStickerMessageContent alloc] init];
            break;
            
            //链接消息
        case MESSAGE_CONTENT_TYPE_LINK:
            break;
            
            //存储不计数文本消息
        case MESSAGE_CONTENT_TYPE_P_TEXT:
            break;

            //名片消息
        case MESSAGE_CONTENT_TYPE_CARD:
//            content = [[WFCCCardMessageContent alloc] init];
            break;
           
            //组合消息
        case MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE:
//            content = [[WFCCCompositeMessageContent alloc] init];
            break;
            
            //富通知消息
        case MESSAGE_CONTENT_TYPE_RICH_NOTIFICATION:
//            content = [[WFCCRichNotificationMessageContent alloc] init];
            break;
            
            //文章消息
        case MESSAGE_CONTENT_TYPE_ARTICLES:
//            content = [[WFCCArticlesMessageContent alloc] init];
            break;
        default:
            content = [[WFCCUnknownMessageContent alloc] init];
            break;
    }
    
    payload.contentType = (int)type;
    payload.searchableContent = dict[@"searchableContent"];
    payload.content = dict[@"content"];

    payload.extra = dict[@"extra"];
    payload.pushContent = dict[@"pushContent"];
    
    // 调用 decode 方法让子类解析自己的字段
    if ([content respondsToSelector:@selector(decode:)]) {
        [content decode:payload];
    }
    
    return content;
}

@end
