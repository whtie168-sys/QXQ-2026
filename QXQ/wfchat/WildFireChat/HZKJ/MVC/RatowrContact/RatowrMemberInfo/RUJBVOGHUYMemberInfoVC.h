//
//  RUJBVOGHUYMemberInfoVC.h
//  QXQ
//
//  Created by Loooooo on 10/18/23.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface RUJBVOGHUYMemberInfoVC : QABWJEFDOCYMainVC

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *groupId;

// 是否名片消息进来的  YES 不显示禁言
@property (nonatomic, assign) BOOL isCardEnter;

@end

NS_ASSUME_NONNULL_END
