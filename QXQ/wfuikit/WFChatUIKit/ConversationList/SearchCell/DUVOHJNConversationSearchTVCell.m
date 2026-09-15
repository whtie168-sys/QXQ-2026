//
//  ConversationSearchTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "DUVOHJNConversationSearchTVCell.h"
#import "AIOIUEHUtilities.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "AIOIUEHConfigManager.h"
#import "AIOIUEHImage.h"

@implementation DUVOHJNConversationSearchTVCell
- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}
  

  
- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
  [self.wsedcPotraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                    context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
  
    if (userInfo.alias.length) {
        self.wsedcTargetLabel.text = userInfo.alias;
    } else if(userInfo.displayName.length > 0) {
        self.wsedcTargetLabel.text = userInfo.displayName;
    } else {
        self.wsedcTargetLabel.text = [NSString stringWithFormat:@"user<%@>", self.message.fromUser];
    }
}

- (void)setMessage:(WFCCMessage *)message {
    _message = message;
    
    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:message.fromUser];
    if(userInfo.userId.length == 0) {
        userInfo = [[WFCCUserInfo alloc] init];
        userInfo.userId = message.fromUser;
    }
    [self updateUserInfo:userInfo];
    
    NSString *strContent = message.digest;
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strContent];
    NSRange range = [strContent rangeOfString:self.keyword options:NSCaseInsensitiveSearch];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
    self.wsedcDigestLabel.attributedText = attrStr;
    
    self.wsedcTimeLabel.hidden = NO;
    self.wsedcTimeLabel.text = [AIOIUEHUtilities formatTimeLabel:message.serverTime];
    self.contentView.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
}

- (UIImageView *)wsedcPotraitView {
    if (!_wsedcPotraitView) {
        _wsedcPotraitView = [[UIImageView alloc] initWithFrame:CGRectMake(19, 19, 30, 30)];
        _wsedcPotraitView.clipsToBounds = YES;
        _wsedcPotraitView.layer.cornerRadius = 5.0;
        [self.contentView addSubview:_wsedcPotraitView];
    }
    return _wsedcPotraitView;
}

- (UILabel *)wsedcTargetLabel {
    if (!_wsedcTargetLabel) {
        _wsedcTargetLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 28 + 16, 19, [UIScreen mainScreen].bounds.size.width - 68  - 68, 10)];
        _wsedcTargetLabel.font = [UIFont systemFontOfSize:10];
        _wsedcTargetLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_wsedcTargetLabel];
    }
    return _wsedcTargetLabel;
}

- (UILabel *)wsedcDigestLabel {
    if (!_wsedcDigestLabel) {
        _wsedcDigestLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 28 + 16, 34, [UIScreen mainScreen].bounds.size.width - 60  - 16, 14)];
        _wsedcDigestLabel.font = [UIFont systemFontOfSize:14];
        _wsedcDigestLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_wsedcDigestLabel];
    }
    return _wsedcDigestLabel;
}

- (UILabel *)wsedcTimeLabel {
    if (!_wsedcTimeLabel) {
        _wsedcTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 52  - 8, 18, 52, 12)];
        _wsedcTimeLabel.font = [UIFont systemFontOfSize:11];
        _wsedcTimeLabel.textAlignment = NSTextAlignmentRight;
        _wsedcTimeLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_wsedcTimeLabel];
    }
    return _wsedcTimeLabel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.wsedcPotraitView sd_cancelCurrentImageLoad];
    self.wsedcPotraitView.image = nil;
}

@end
