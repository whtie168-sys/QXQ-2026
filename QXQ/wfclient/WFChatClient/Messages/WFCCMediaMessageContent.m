//
//  WFCCMediaMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/6.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"
#import "WFCCUtilities.h"
#import "Common.h"


@implementation WFCCMediaMessageContent
- (NSString *)localPath {
    _localPath = [WFCCUtilities getSendBoxFilePath:_localPath];
    return _localPath;
}

- (NSString *)mediaCaptionText {
    if (self.extra.length == 0) {
        return nil;
    }

    NSData *data = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *extraDictionary = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![extraDictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }

    NSString *caption = extraDictionary[@"extMsg"];
    if (![caption isKindOfClass:NSString.class]) {
        return nil;
    }
    caption = [caption stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return caption.length > 0 ? caption : nil;
}
@end
