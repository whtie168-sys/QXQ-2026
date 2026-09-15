//
//  WFCCPointsHistory.m
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCCPointsHistory.h"

@implementation WFCCPointsHistoryRecord

@end

@implementation WFCCPointsHistory

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"records" : [WFCCPointsHistoryRecord class]};
}

@end
