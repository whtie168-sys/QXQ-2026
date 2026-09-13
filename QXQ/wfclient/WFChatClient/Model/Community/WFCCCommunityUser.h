//
//  WFCCCommunityUser.h
//  WFChatClient
//
//  Created by wtb on 2026/4/17.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCCCommunityUser : NSObject
@property(nonatomic, strong)NSString *uid;
@property(nonatomic, strong)NSString *displayName;
@property(nonatomic, strong)NSString *portrait;
@property(nonatomic)int64_t lastPublishTime;
@end

NS_ASSUME_NONNULL_END
