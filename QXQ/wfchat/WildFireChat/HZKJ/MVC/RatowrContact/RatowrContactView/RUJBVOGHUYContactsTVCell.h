//
//  RUJBVOGHUYContactsTVCell.h
//  WUHOIBDK
//
//  Created by Ruby on 12/4/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RUJBVOGHUYContactsTVCell : UITableViewCell

- (void)setUserId:(NSString *)userId groupId:(NSString *)groupId;

- (void)showGroupManager;
- (void)showGroupOwn;
- (void)showMember;
- (void)updateUserInfo:(WFCCUserInfo *)userInfo;

@end

NS_ASSUME_NONNULL_END
