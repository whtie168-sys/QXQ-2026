//
//  GroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "LUDHIOWIVChannelTVCell.h"
#import <SDWebImage/SDWebImage.h>
#import "AIOIUEHImage.h"

@interface LUDHIOWIVChannelTVCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;

@end

@implementation LUDHIOWIVChannelTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 40, 40)];
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, [UIScreen mainScreen].bounds.size.width - 64, 24)];
        [self.contentView addSubview:_name];
    }
    return _name;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setChannelInfo:(WFCCChannelInfo *)channelInfo {
    _channelInfo = channelInfo;
    if (channelInfo.name.length == 0) {
        self.name.text = @"频道";
    } else {
        self.name.text = [NSString stringWithFormat:@"%@", channelInfo.name];
    }
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"channel_default_portrait"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.portrait sd_cancelCurrentImageLoad];
    self.portrait.image = nil;
}
@end
