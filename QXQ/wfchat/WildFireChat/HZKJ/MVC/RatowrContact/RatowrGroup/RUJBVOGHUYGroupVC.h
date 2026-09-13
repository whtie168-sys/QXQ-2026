//
//  RUJBVOGHUYGroupVC.h
//  WUHOIBDK
//
//  Created by Ruby on 11/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface RUJBVOGHUYGroupVC : UITableViewController

/**
 * 1  分享联系人到群聊
 *
 */
@property (nonatomic, assign) NSInteger type;
// type = 1 时  该字段🈶值
@property (nonatomic, copy) NSString *target; // 被推荐的用户id、



@end


@interface RUJBVOGHUYTableVCell : UITableViewCell

@property (nonatomic, strong)WFCCGroupInfo *groupInfo;

@end

NS_ASSUME_NONNULL_END
