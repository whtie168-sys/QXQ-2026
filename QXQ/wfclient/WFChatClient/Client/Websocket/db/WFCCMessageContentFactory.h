//
//  WFCCMessageContentFactory.h
//  WFChatClient
//
//  Created by wtb on 2025/9/2.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCMessageContent.h"

NS_ASSUME_NONNULL_BEGIN


@interface WFCCMessageContentFactory : NSObject

+ (WFCCMessageContent *)messageContentFromJSONString:(NSString *)jsonString;
@end

NS_ASSUME_NONNULL_END
