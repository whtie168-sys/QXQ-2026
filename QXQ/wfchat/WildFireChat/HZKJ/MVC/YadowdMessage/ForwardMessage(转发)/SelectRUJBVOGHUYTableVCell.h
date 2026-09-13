//
//  SelectRUJBVOGHUYTableVCell.h
//  WildFireChat
//
//  Created by wtb on 2025/4/23.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectRUJBVOGHUYTableVCell : UITableViewCell
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;
- (void)isselectImg:(BOOL)sel;

- (void)setUseInfo:(WFCCUserInfo *)userInfo;
@end

NS_ASSUME_NONNULL_END
