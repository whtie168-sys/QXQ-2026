//
//  TagMemberTableViewCell.h
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TagMemberTableViewCell : UITableViewCell

- (void)configureWithUserInfo:(WFCCUserInfo *)userInfo;

@end

NS_ASSUME_NONNULL_END
