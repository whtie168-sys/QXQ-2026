//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "SMIOUEJInformationCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "AIOIUEHUtilities.h"


#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@implementation SMIOUEJInformationCell

+ (CGSize)sizeForCell:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGFloat height = [super hightForHeaderArea:msgModel];
    NSString *infoText;
    if ([msgModel.message.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
        WFCCNotificationMessageContent *content = (WFCCNotificationMessageContent *)msgModel.message.content;
        infoText = [content formatNotification:msgModel.message];
    } else {
        infoText = [msgModel.message digest];
    }
    if (infoText.length == 0) {
        return CGSizeMake(0, 0);
    }
    CGSize size = [AIOIUEHUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING;
    size.height += height;
    return CGSizeMake(width, size.height);
}

- (void)setModel:(AIOIUEHMessageModel *)model {
    [super setModel:model];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];

    NSString *infoText;
    if ([model.message.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
        WFCCNotificationMessageContent *content = (WFCCNotificationMessageContent *)model.message.content;
        infoText = [content formatNotification:model.message];
    } else {
        infoText = [model.message digest];
    }
    
    CGFloat width = self.contentView.bounds.size.width;
    
    CGSize size = [AIOIUEHUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    
    
    self.tzboeuAsdfgInfoLabel.text = infoText;
    self.tzboeuAsdfgInfoLabel.hidden = (infoText.length == 0);
    self.tzboeuAsdfgInfoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    CGFloat timeLableEnd = 0;
    if (!self.timeLabel.hidden) {
        timeLableEnd = self.timeLabel.frame.size.height + self.timeLabel.frame.origin.y;
    }
    self.tzboeuAsdfgInfoLabel.frame = CGRectMake((width - size.width)/2 - 8, timeLableEnd + TEXT_LABEL_TOP_PADDING, size.width + 16, size.height + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING);
//    self.tzboeuAsdfgInfoLabel.textAlignment = NSTextAlignmentCenter;

}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];

    BOOL needUpdate = false;
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([self.model.message.content isKindOfClass:[WFCCAddGroupeMemberNotificationContent class]]) {
            WFCCAddGroupeMemberNotificationContent *cnt = (WFCCAddGroupeMemberNotificationContent *)self.model.message.content;
            if ([cnt.invitor isEqualToString:userInfo.userId] || [cnt.invitees containsObject:userInfo.userId]) {
                needUpdate = true;
                break;
            }
        } else if ([self.model.message.content isKindOfClass:[WFCCCreateGroupNotificationContent class]]) {
            WFCCCreateGroupNotificationContent *cnt = (WFCCCreateGroupNotificationContent *)self.model.message.content;
            if ([cnt.creator isEqualToString:userInfo.userId]) {
                needUpdate = true;
                break;
            }
        }
    }
    
    if (needUpdate) {
        [self setModel:self.model];
    }
}

- (UILabel *)tzboeuAsdfgInfoLabel {
    if (!_tzboeuAsdfgInfoLabel) {
        _tzboeuAsdfgInfoLabel = [[UILabel alloc] init];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.font = [UIFont systemFontOfSize:14];
        
        _tzboeuAsdfgInfoLabel.textColor = [UIColor whiteColor];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _tzboeuAsdfgInfoLabel.textAlignment = NSTextAlignmentCenter;
        _tzboeuAsdfgInfoLabel.font = [UIFont systemFontOfSize:14.f];
        _tzboeuAsdfgInfoLabel.layer.masksToBounds = YES;
        _tzboeuAsdfgInfoLabel.layer.cornerRadius = 5.f;
        _tzboeuAsdfgInfoLabel.textAlignment = NSTextAlignmentCenter;
        _tzboeuAsdfgInfoLabel.backgroundColor = [UIColor colorWithRed:201/255.f green:201/255.f blue:201/255.f alpha:1.f];
        
        [self.contentView addSubview:_tzboeuAsdfgInfoLabel];
    }
    return _tzboeuAsdfgInfoLabel; 
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
