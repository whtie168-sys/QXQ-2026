//
//  ConversationTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JUAHODJNKBubbleTipView.h"
#import <WFChatClient/WFCChatClient.h>


@interface DUVOHJNConversationTVCell : UITableViewCell
@property (strong, nonatomic) UIImageView *wsedcPotraitView;
@property (strong, nonatomic) UILabel *wsedcTargetLabel;
@property (strong, nonatomic) UILabel *wsedcDigestLabel;
@property (strong, nonatomic) UILabel *offcialView;
@property (strong, nonatomic) UIImageView *wsedcStatusView;
@property (strong, nonatomic) UILabel *wsedcTimeLabel;
@property (strong, nonatomic) UIImageView *wsedcSilentImgView;
@property (strong, nonatomic) UIImageView *secretChatView;
@property (nonatomic, strong)JUAHODJNKBubbleTipView *tzboeuBubbleView;
@property (nonatomic, strong)WFCCConversationInfo *info;
@property (nonatomic, strong)WFCCConversationSearchInfo *searchInfo;
@property (nonatomic, assign, getter=isBig)BOOL big;

@end
