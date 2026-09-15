//
//  HNWOUIDSelectedUserTVCell.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "HNWOUIDSelectedUserTVCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "AIOIUEHImage.h"
#import "LUDHIOWIVOrganizationCache.h"
#import "LUDHIOWIVEmployee.h"
#import "LUDHIOWIVOrganization.h"
#import "LUDHIOWIVOrgRelationship.h"
#import "LUDHIOWIVOrganizationEx.h"
#import "AIOIUEHConfigManager.h"
#import "LUDHIOWIVEmployeeEx.h"

@interface HNWOUIDSelectedUserTVCell()


@end

@implementation HNWOUIDSelectedUserTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCheckImage:(SelectedStatusType)selectedStatus {
    if (selectedStatus == Disable_Checked) {
        self.checkImageView.image = [AIOIUEHImage imageNamed:@"multi_has_selected"];
    }
    
    if (selectedStatus == Checked) {
        self.checkImageView.image = [AIOIUEHImage imageNamed:@"multi_selected"];
    }
    
    if (selectedStatus == Unchecked) {
        self.checkImageView.image = [AIOIUEHImage imageNamed:@"multi_unselected"];
    }
    
    if(selectedStatus == Disable_Unchecked) {
        self.checkImageView.image = [AIOIUEHImage imageNamed:@"multi_unselected"];
    }
}

- (void)setSelectedObject:(HNWOUIDSelectModel *)selectedUserInfo {
    _selectedObject = selectedUserInfo;
    [self setCheckImage:selectedUserInfo.selectedStatus];
    if(selectedUserInfo.userInfo) {
        [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [AIOIUEHImage imageNamed:@"PersonalChat"]  options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (selectedUserInfo.userInfo.alias.length) {
            self.tzboeuNameLabel.text = selectedUserInfo.userInfo.alias;
        } else {
            self.tzboeuNameLabel.text = selectedUserInfo.userInfo.displayName;
        }
        _nextLevel.hidden = YES;
    } else if(selectedUserInfo.organization) {
        [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.organization.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [AIOIUEHImage imageNamed:@"organization_icon"]  options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.tzboeuNameLabel.text = selectedUserInfo.organization.name;
        self.nextLevel.hidden = NO;
    } else if(selectedUserInfo.employee) {
        [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.employee.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [AIOIUEHImage imageNamed:@"employee"]  options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.tzboeuNameLabel.text = selectedUserInfo.employee.name;
        _nextLevel.hidden = YES;
    }
}

- (void)onNextLevel:(id)sender {
    if([self.delegate respondsToSelector:@selector(didTapNextLevel:)]) {
        [self.delegate didTapNextLevel:self.selectedObject];
    }
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 20, 20, 20)];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}
- (UIImageView *)trewqPortraitView {
    if (!_trewqPortraitView) {
        _trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 10, 40, 40)];
        _trewqPortraitView.layer.masksToBounds = YES;
        _trewqPortraitView.layer.cornerRadius = 20.0;
        [self.contentView addSubview:_trewqPortraitView];
    }
    return _trewqPortraitView;
}

- (UILabel *)tzboeuNameLabel {
    if(!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50 + 40 + 12, 20, [UIScreen mainScreen].bounds.size.width - (16 + 20 + 19 + 40 + 12) - 48, 20)];
        _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
        _tzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (UIButton *)nextLevel {
    if(!_nextLevel) {
        _nextLevel = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 80, 20, 80, 20)];
        [_nextLevel setTitle:@"下级" forState:UIControlStateNormal];
        [_nextLevel setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _nextLevel.titleLabel.font = [UIFont systemFontOfSize:12];
        [_nextLevel addTarget:self action:@selector(onNextLevel:) forControlEvents:UIControlEventTouchDown];
        [self.contentView addSubview:_nextLevel];
    }
    return _nextLevel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
    self.trewqPortraitView.image = nil;
}

@end
