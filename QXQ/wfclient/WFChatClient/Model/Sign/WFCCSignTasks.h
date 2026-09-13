//
//  WFCCSignTasks.h
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCSignTaskSignRecord : NSObject

@property(nonatomic, strong)NSString *dateTimestamp;
@property(nonatomic, strong)NSString *status;
@property(nonatomic, strong)NSString *points;

@end

@interface WFCCSignTaskRecent7DaySummary : NSObject
@property(nonatomic, strong)NSString *signedDays;
@property(nonatomic, strong)NSString *earnedPoints;
@property(nonatomic)BOOL hasMoreHistory;

@end

@interface WFCCSignTask : NSObject
@property(nonatomic, strong)NSString *taskId;
@property(nonatomic, strong)NSString *taskCode;
@property(nonatomic, strong)NSString *taskName;

@property(nonatomic, strong)NSString *creatorUserId;
@property(nonatomic, strong)NSString *creatorDisplayName;
@property(nonatomic, strong)NSString *creatorPortrait;
@property(nonatomic, strong)NSString *taskType;
@property(nonatomic, strong)NSString *lifecycleType;
@property(nonatomic, strong)NSString *cycleDays;
@property(nonatomic, strong)NSString *progress;
@property(nonatomic, strong)NSString *target;
@property(nonatomic, strong)NSString *nextRewardDays;
@property(nonatomic, strong)NSString *status;
@property(nonatomic, strong)NSString *rewardDesc;
@property(nonatomic)BOOL allowReSign;
@property(nonatomic, strong)NSString *todayPoints;


@property(nonatomic, strong)NSArray<WFCCSignTaskSignRecord *> *signRecords;
@property(nonatomic, strong)NSArray<WFCCSignTaskRecent7DaySummary *> *recent7DaySummary;

@end

@interface WFCCSignTasks : NSObject
@property(nonatomic, strong)NSArray<WFCCSignTask *> *tasks;
@property(nonatomic, strong)NSString *totalPoints;

@end

NS_ASSUME_NONNULL_END
