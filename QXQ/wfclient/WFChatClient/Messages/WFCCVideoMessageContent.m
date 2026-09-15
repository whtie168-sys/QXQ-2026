//
//  WFCCVideoMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import "WFCCVideoMessageContent.h"
#import "WFCCNetworkService.h"
#import "WFCCIMService.h"
#import "WFCCUtilities.h"
#import "Common.h"
#import <AVFoundation/AVFoundation.h>

@implementation WFCCVideoMessageContent
+ (instancetype)contentPath:(NSString *)localPath thumbnail:(UIImage *)image {
    WFCCVideoMessageContent *content = [[WFCCVideoMessageContent alloc] init];
    content.localPath = localPath;
    content.thumbnail = [WFCCUtilities imageWithRightOrientation:image];
    
    NSURL *videoUrl = [NSURL URLWithString:localPath];
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:videoUrl];
    CMTime time = [avUrl duration];
    content.duration = ceil(time.value/time.timescale);

    return content;
}
- (WFCCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = [self digest:nil];
    payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.45);
    payload.mediaType = Media_Type_VIDEO;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@(_duration) forKey:@"duration"];
    [dict setObject:@(_duration) forKey:@"d"];
    if (_thumbnailUrl) {
        [dict setObject:_thumbnailUrl forKey:@"thumbnailUrl"];
    }
    if (_size.height && _size.width) {
        [dict setObject:@(_size.width) forKey:@"w"];
        [dict setObject:@(_size.height) forKey:@"h"];
    }

    payload.content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        if (payload.binaryContent) {
            self.thumbnail = [UIImage imageWithData:payload.binaryContent];
        }
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        
        NSError *__error = nil;
        if (payload.content) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:kNilOptions
                                                                         error:&__error];
            if (!__error) {
                self.duration = [dictionary[@"duration"] longValue]/1000;
                if(self.duration == 0) {
                    self.duration = [dictionary[@"d"] longValue]/1000;
                }
                self.thumbnailUrl = dictionary[@"thumbnailUrl"];
                self.size = CGSizeMake([dictionary[@"w"] longValue], [dictionary[@"h"] longValue]);
            }
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_VIDEO;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}




+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    NSString *prefix = [WFCCIMService.main isChinese] ? @"[视频]" : @"[Video]";
    NSString *caption = [self mediaCaptionText];
    return caption.length > 0 ? [prefix stringByAppendingString:caption] : prefix;
}
@end
