//
//  HNWOUIDSelectedUserTVCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HNWOUIDSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@class LUDHIOWIVOrganization;
@class HNWOUIDSelectModel;
@protocol HNWOUIDSelectedUserTVCellDelegate <NSObject>
- (void)didTapNextLevel:(HNWOUIDSelectModel *)organization;
@end

@interface HNWOUIDSelectedUserTVCell : UITableViewCell
@property (nonatomic, weak)id<HNWOUIDSelectedUserTVCellDelegate> delegate;
@property (nonatomic, strong)HNWOUIDSelectModel *selectedObject;
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *trewqPortraitView;
@property(nonatomic, strong)UILabel *tzboeuNameLabel;
@property(nonatomic, strong)UIButton *nextLevel;

@end

NS_ASSUME_NONNULL_END
