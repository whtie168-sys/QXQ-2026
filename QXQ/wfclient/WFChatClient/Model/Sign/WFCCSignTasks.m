//
//  WFCCSignTasks.m
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCCSignTasks.h"

@implementation WFCCSignTaskSignRecord

@end


@implementation WFCCSignTaskRecent7DaySummary

@end


@implementation WFCCSignTask

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"signRecords" : [WFCCSignTaskSignRecord class]};
}

@end


@implementation WFCCSignTasks

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"tasks" : [WFCCSignTask class]};
}

@end
