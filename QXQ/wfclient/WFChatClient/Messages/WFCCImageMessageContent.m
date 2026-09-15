//
//  WFCCImageMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import "WFCCImageMessageContent.h"
#import "WFCCNetworkService.h"
#import "WFCCIMService.h"
#import "WFCCUtilities.h"
#import "JSONHelper.h"
#import "Common.h"


@implementation WFCCImageMessageContent
+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path {
    return [WFCCImageMessageContent contentFrom:image cachePath:path fullImage:NO];
}

+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path fullImage:(BOOL)fullImage {
    WFCCImageMessageContent *content = [[WFCCImageMessageContent alloc] init];
    
    if(!fullImage) {
        image = [WFCCUtilities image:image scaleInSize:CGSizeMake(1024, 1024)];
    }
    
    NSData *imgData = UIImageJPEGRepresentation(image, 1.0); // IM默认为0.85
        
    
    [imgData writeToFile:path atomically:YES];
    
    content.localPath = path;
    content.size = image.size;
//    content.thumbnail = image;
    content.thumbnail = [WFCCUtilities generateThumbnail:image withWidth:301 withHeight:301];
    return content;
}

- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = [self digest:nil];
    
    NSMutableDictionary *dataDict = nil;
    if (self.size.width > 0 && self.size.height > 0) {
        dataDict = [NSMutableDictionary dictionary];
        [dataDict setValue:@(self.size.width) forKey:@"w"];
        [dataDict setValue:@(self.size.height) forKey:@"h"];
        if (self.thumbParameter.length) {
            [dataDict setValue:self.thumbParameter forKey:@"tp"];
        }
    } else if (![[WFCCIMService sharedWFCIMService] imageThumbPara]) {
        dataDict = nil;
        if(!self.thumbnail && self.localPath.length) {
            UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];
            if(image) {
                self.thumbnail = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
            }
        }
        payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
    } else {
        dataDict = [NSMutableDictionary dictionary];
        UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];
        if (image) {
            [dataDict setValue:[[WFCCIMService sharedWFCIMService] imageThumbPara] forKey:@"tp"];
            [dataDict setValue:@(image.size.width) forKey:@"w"];
            [dataDict setValue:@(image.size.height) forKey:@"h"];
        } else {
            payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
            dataDict = nil;
        }
    }
    
    if (dataDict) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict
                                                       options:kNilOptions
                                                         error:nil];
        payload.content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    payload.mediaType = Media_Type_IMAGE;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        if ([payload.binaryContent length]) {
            self.thumbnail = [UIImage imageWithData:payload.binaryContent];
        }
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        self.name = mediaPayload.searchableContent;
        if([self.name rangeOfString:([WFCCIMService.main isChinese]?@"[图片]":@"[Picture]")].location == 0) {
            self.name = [self.name substringFromIndex:([WFCCIMService.main isChinese]?@"[图片]":@"[Picture]").length];
        }
        if (mediaPayload.content.length) {
            NSError *__error = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:kNilOptions
                                                                         error:&__error];
            if (!__error) {
                NSString *str1 = dictionary[@"w"];
                NSString *str2 = dictionary[@"h"];
                self.thumbParameter = dictionary[@"tp"];
                self.size = CGSizeMake([str1 intValue], [str2 intValue]);
            }
        }
        if (CGSizeEqualToSize(self.size, CGSizeZero) && self.extra.length) {
            NSDictionary *extraDic = [JSONHelper jsonObjectFromString:self.extra];
            if ([extraDic isKindOfClass:[NSDictionary class]] && extraDic[@"width"] && extraDic[@"height"]) {
                self.size = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
            }
        }
    }
}

- (UIImage *)thumbnail {
    if(_thumbnail == [WFCCIMService sharedWFCIMService].defaultThumbnailImage) {
        _thumbnail = nil;
    }
    
    if (!_thumbnail && self.localPath.length && [[NSFileManager defaultManager] isExecutableFileAtPath:self.localPath]) {
        UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];
        _thumbnail = [WFCCUtilities generateThumbnail:image withWidth:120 withHeight:120];
    }
    if (!_thumbnail) {
        _thumbnail = [WFCCIMService sharedWFCIMService].defaultThumbnailImage;
    }
    
    return _thumbnail;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_IMAGE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    NSString *prefix = [WFCCIMService.main isChinese] ? @"[图片]" : @"[Picture]";
    NSString *caption = [self mediaCaptionText];
    if (caption.length > 0) {
        return [prefix stringByAppendingString:caption];
    }
    return [prefix stringByAppendingString:(self.name.length > 0 ? self.name : @"")];
}
@end
