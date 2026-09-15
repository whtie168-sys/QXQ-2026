//
//  YUBWOIJWDGroupIconCVCell.h
//  WUHOIBDK
//
//  Created by Ruby on 12/11/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YUBWOIJWDGroupIconCVCell : UICollectionViewCell

@property (nonatomic, strong) WFCCGroupMember *member;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (nonatomic, assign) BOOL showsOwnerBadge;
@property (nonatomic, assign) BOOL showsManagerBadge;


@end

NS_ASSUME_NONNULL_END
