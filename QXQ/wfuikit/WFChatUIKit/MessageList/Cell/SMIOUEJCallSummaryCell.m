//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "SMIOUEJCallSummaryCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "AIOIUEHUtilities.h"
#import "AIOIUEHImage.h"
#import "UIFont+YH.h"

#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@implementation SMIOUEJCallSummaryCell

+ (CGSize)sizeForClientArea:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSString *text = [SMIOUEJCallSummaryCell getCallText:msgModel.message.content];
    CGSize textSize = [AIOIUEHUtilities getTextDrawingSize:text font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 8000)];
    return CGSizeMake(textSize.width + 20, 30);
}

+ (NSString *)getCallText:(WFCCCallStartMessageContent *)startContent {
    BOOL isChinese = [WFCCIMService.main isChinese];
    NSString *text;
    if (startContent.isAudioOnly) {
        text = (isChinese?@"语音通话":@"Voice call");
    } else {
        text = (isChinese?@"视频通话":@"Video call");
    }

#if WFCU_SUPPORT_VOIP
    if(startContent.status == kWFAVCallEndReasonInterrupted) {
        text = (isChinese?@"通话中断":@"Dropped call");
    } else if(startContent.status == kWFAVCallEndReasonRemoteInterrupted) {
        text = (isChinese?@"对方通话中断":@"Incoming call dropped");
    }
#endif
    
    if (startContent.connectTime > 0 && startContent.endTime > 0) {
        long long duration = startContent.endTime - startContent.connectTime;
        if (duration <= 0) {
            return text;
        }
        duration = duration/1000; //转化成s
        if (duration == 0) {
            return text;
        }
        
        long long hour = duration/3600; //小时数
        duration = duration - hour * 3600; //去除小时
        long long mins = duration/60;  //分钟数
        duration = duration - mins*60;
        long long second = duration;
        
        if (hour) {
            text = [text stringByAppendingFormat:@"%lld:", hour];
        }
        
        text = [text stringByAppendingFormat:@" %02lld:", mins];
        text = [text stringByAppendingFormat:@"%02lld", second];
    } else {
#if WFCU_SUPPORT_VOIP
        switch (startContent.status) {
            case kWFAVCallEndReasonBusy:
                text = (isChinese?@"线路忙":@"Network busy");
                break;
            case kWFAVCallEndReasonSignalError:
                text = isChinese ? @"网络错误" : @"Network error";
                break;
            case kWFAVCallEndReasonHangup:
                text = isChinese ? @"已取消" : @"Cancelled";
                break;
            case kWFAVCallEndReasonMediaError:
                text = isChinese ? @"网络错误" : @"Network error";
                break;
            case kWFAVCallEndReasonRemoteHangup:
                text = isChinese ? @"对方已取消" : @"Other party cancelled";
                break;
            case kWFAVCallEndReasonOpenCameraFailure:
                text = isChinese ? @"网络错误" : @"Network error";
                break;
            case kWFAVCallEndReasonTimeout:
                text = isChinese ? @"未接听" : @"Not answered";
                break;
            case kWFAVCallEndReasonAcceptByOtherClient:
                text = isChinese ? @"其它端已接听" : @"The other end has answered the call";
                break;
            case kWFAVCallEndReasonAllLeft:
                text = isChinese ? @"通话已结束" : @"Call has ended";
                break;
            case kWFAVCallEndReasonRemoteBusy:
                text = isChinese ? @"对方线路忙" : @"The other party is busy online";
                break;
            case kWFAVCallEndReasonRemoteTimeout:
                text = isChinese ? @"对方未接听" : @"The other party did not answer";
                break;
            case kWFAVCallEndReasonRemoteNetworkError:
                text = isChinese ? @"对方网络错误" : @"Network error of the other party";
                break;
            case kWFAVCallEndReasonRoomDestroyed:
                text = isChinese ? @"通话已结束" : @"Call has ended";
                break;
            case kWFAVCallEndReasonRoomNotExist:
                text = isChinese ? @"通话已结束" : @"Call has ended";
                break;
            case kWFAVCallEndReasonRoomParticipantsFull:
                text = isChinese ? @"已达到最大参与人数" : @"The maximum number of participants has been reached";
                break;
            case kWFAVCallEndReasonInterrupted:
                text = isChinese ? @"通话中断" : @"Dropped call";
                break;
            case kWFAVCallEndReasonRemoteInterrupted:
                text = isChinese ? @"对方通话中断" : @"Incoming call dropped";
                break;
            default:
                break;
        }
#endif
    }
    
    return text;
}

- (void)setModel:(AIOIUEHMessageModel *)model {
    [super setModel:model];
    
    CGFloat width = self.tzboeuContentArea.bounds.size.width;
    
    self.tzboeuAsdfgInfoLabel.text = [SMIOUEJCallSummaryCell getCallText:model.message.content];
    self.tzboeuAsdfgInfoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    
    if (model.message.direction == MessageDirection_Send) {
//        self.tzboeuAsdfgInfoLabel.frame = CGRectMake(0, 0, width - 25, 30);
//        self.tzboeuModeImageView.frame = CGRectMake(width - 25, 3, 25, 25);
        self.tzboeuModeImageView.frame = CGRectMake(5.0, 7.0, 17.0, 17.0);
        self.tzboeuAsdfgInfoLabel.frame = CGRectMake(CGRectGetMaxX(self.tzboeuModeImageView.frame)+10.0, 0, width - 27.0, 30);
    } else {
//        self.tzboeuAsdfgInfoLabel.frame = CGRectMake(0, 0, width-25, 30);
//        self.tzboeuModeImageView.frame = CGRectMake(width-25, 3, 25, 25);
        self.tzboeuModeImageView.frame = CGRectMake(5.0, 7.0, 17.0, 17.0);
        self.tzboeuAsdfgInfoLabel.frame = CGRectMake(CGRectGetMaxX(self.tzboeuModeImageView.frame)+10.0, 0, width - 27.0, 30);
    }
    if ([self.model.message.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
        WFCCCallStartMessageContent *startContent = (WFCCCallStartMessageContent *)self.model.message.content;
        if (startContent.isAudioOnly) {
            self.tzboeuModeImageView.image = [AIOIUEHImage imageNamed:@"vioce_flag1"];
        } else {
            self.tzboeuModeImageView.image = [AIOIUEHImage imageNamed:@"video_flag1"];
        }
    }
}

- (UILabel *)tzboeuAsdfgInfoLabel {
    if (!_tzboeuAsdfgInfoLabel) {
        _tzboeuAsdfgInfoLabel = [[UILabel alloc] init];
        _tzboeuAsdfgInfoLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:13.0];
        
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _tzboeuAsdfgInfoLabel.textAlignment = NSTextAlignmentLeft;
        _tzboeuAsdfgInfoLabel.layer.masksToBounds = YES;
        _tzboeuAsdfgInfoLabel.userInteractionEnabled = YES;
        [self.tzboeuContentArea addSubview:_tzboeuAsdfgInfoLabel];
    }
    return _tzboeuAsdfgInfoLabel; 
}
- (UIImageView *)tzboeuModeImageView {
    if (!_tzboeuModeImageView) {
        _tzboeuModeImageView = [[UIImageView alloc] init];
        [self.tzboeuContentArea addSubview:_tzboeuModeImageView];
    }
    return _tzboeuModeImageView;
}
@end
