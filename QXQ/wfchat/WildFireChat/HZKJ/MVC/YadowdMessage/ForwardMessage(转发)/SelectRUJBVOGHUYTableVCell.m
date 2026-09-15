//
//  SelectRUJBVOGHUYTableVCell.m
//  WildFireChat
//
//  Created by wtb on 2025/4/23.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "SelectRUJBVOGHUYTableVCell.h"

@interface SelectRUJBVOGHUYTableVCell ()
@property (weak, nonatomic) IBOutlet UIImageView *portraitImgView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property IBOutlet UIImageView *selectImg;
@end


@implementation SelectRUJBVOGHUYTableVCell

- (void)awakeFromNib{
    [super awakeFromNib];
    _portraitImgView.layer.cornerRadius = 20.0;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)isselectImg:(BOOL)sel {
    self.selectImg.image = sel ? [UIImage imageNamed:@"zhuanfaGroup_select"] :[UIImage imageNamed:@"zhuanfaGroup_"];
}

- (void)setUseInfo:(WFCCUserInfo *)userInfo {
    [_portraitImgView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage: [AIOIUEHImage imageNamed:@"PersonalChat"]  options:SDWebImageScaleDownLargeImages
                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    if (userInfo.finalName.length) {
        self.tzboeuNameLabel.text = userInfo.finalName;
    } else if (userInfo.alias.length) {
        self.tzboeuNameLabel.text = userInfo.alias;
    } else if (userInfo.groupAlias.length) {
        self.tzboeuNameLabel.text = userInfo.groupAlias;
    } else if(userInfo.displayName.length > 0) {
        self.tzboeuNameLabel.text = userInfo.displayName;
    } else {
        self.tzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
    }

}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    
    if (groupInfo.displayName.length == 0) {
        _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)",LLLLLL(@"GroupChat") ,(int)groupInfo.memberCount];
    } else {
        _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.displayName, (int)groupInfo.memberCount];
    }

    [_portraitImgView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                     context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
}

@end
