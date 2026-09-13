//
//  ForwardMessageCell.h
//  WUHOIBDK
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>
NS_ASSUME_NONNULL_BEGIN

@interface FCNUOEYForwardMessageCell : UITableViewCell
@property (strong, nonatomic) WFCCConversation *conversation;
@end

NS_ASSUME_NONNULL_END
