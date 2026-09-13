//
//  NewFriendTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JUAHODJNKBubbleTipView.h"

@interface HNWOUIDNewFriendTVCell : UITableViewCell
@property (nonatomic, strong)UIImageView *trewqPortraitView;
@property (nonatomic, strong)UILabel *tzboeuNameLabel;
//@property (nonatomic, strong)JUAHODJNKBubbleTipView *tzboeuBubbleView;
@property (nonatomic, strong) UILabel *tzboeuRedLabel;
- (void)refresh;

@property (nonatomic, strong) UIView *lineView; // 1204 新增
@property (nonatomic, assign) BOOL isHiddenLine;
@end
