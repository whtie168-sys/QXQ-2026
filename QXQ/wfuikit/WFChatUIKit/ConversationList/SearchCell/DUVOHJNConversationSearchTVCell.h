//
//  ConversationSearchTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JUAHODJNKBubbleTipView.h"
#import <WFChatClient/WFCChatClient.h>


@interface DUVOHJNConversationSearchTVCell : UITableViewCell
@property (strong, nonatomic) UIImageView *wsedcPotraitView;
@property (strong, nonatomic) UILabel *wsedcTargetLabel;
@property (strong, nonatomic) UILabel *wsedcDigestLabel;
@property (strong, nonatomic) UILabel *wsedcTimeLabel;
@property (nonatomic, strong)WFCCMessage *message;
@property (nonatomic, strong)NSString *keyword;
@end
