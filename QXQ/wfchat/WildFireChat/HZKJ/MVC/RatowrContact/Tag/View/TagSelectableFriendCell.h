//
//  TagSelectableFriendCell.h
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TagSelectableFriendCell : UITableViewCell

- (void)configureWithUserInfo:(WFCCUserInfo *)userInfo selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
