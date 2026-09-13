//
//  GroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "JUAHODJNKGroupTVCell.h"
#import <SDWebImage/SDWebImage.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "AIOIUEHImage.h"


@interface JUAHODJNKGroupTVCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;
@property (strong, nonatomic) UIView *line;
@end

@implementation JUAHODJNKGroupTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _portrait.frame = CGRectMake(20.0, (self.frame.size.height - 40) / 2.0, 40, 40);
    _name.frame = CGRectMake(20.0 + 40 + 10.0, (self.frame.size.height - 20) / 2.0, [UIScreen mainScreen].bounds.size.width - (20.0 + 40 + 10.0), 20);
    self.line.frame = CGRectMake(CGRectGetMinX(_name.frame), self.frame.size.height - 0.5, _name.frame.size.width - 20.0, 0.5);
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [UIImageView new];
        _portrait.layer.cornerRadius = 20.0f;
        _portrait.layer.masksToBounds = YES;
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [UILabel new];
        _name.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        _name.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0];
        [self.contentView addSubview:_name];
    }
    return _name;
}
- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = RGBCOLOR(224.0, 224.0, 224.0);
        [self.contentView addSubview:_line];
    }return _line;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    if (groupInfo.displayName.length == 0) {
        self.name.text = @"群聊";
    } else {
        self.name.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.displayName, (int)groupInfo.memberCount];
    }
    
//    if (groupInfo.portrait.length) {
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    } else {
//        __weak typeof(self)ws = self;
//        NSString *groupId = groupInfo.target;
//        
//        [[NSNotificationCenter defaultCenter] addObserverForName:@"GroupPortraitChanged" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
//            NSString *path = [note.userInfo objectForKey:@"path"];
//            if ([ws.groupInfo.target isEqualToString:groupId] && [groupId isEqualToString:note.object]) {
//                [ws.portrait sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"]];
//            }
//        }];
//        
//        NSString *path = [WFCCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//            return [AIOIUEHImage imageNamed:@"PersonalChat"];
//        }];
//        
//        if (path) {
//            [self.portrait sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"]];
//        }
//    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.portrait sd_cancelCurrentImageLoad];
    self.portrait.image = nil;
}
@end
