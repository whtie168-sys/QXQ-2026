//
//  ConversationSearchTableViewController
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

@interface DUVOHJNConversationSearchTableVC : UIViewController
@property(nonatomic, strong)WFCCConversation *conversation;
@property(nonatomic, strong)NSString *keyword;

@property(nonatomic, assign)BOOL messageSelecting;
@property(nonatomic, strong)NSMutableArray *selectedMessageIds;
@end
