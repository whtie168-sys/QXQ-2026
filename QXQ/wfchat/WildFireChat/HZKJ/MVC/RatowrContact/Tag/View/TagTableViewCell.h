//
//  TagTableViewCell.h
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface TagTableViewCell : UITableViewCell

- (void)configWithModel:(WFCCUserTag *)model;
- (void)configWithTitle:(NSString *)title countText:(NSString *)countText membersText:(NSString *)membersText;

@end

NS_ASSUME_NONNULL_END
