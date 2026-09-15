//
//  FriendRequestTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/23.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>


@protocol DUVOHJNFriendRequestTVCellDelegate <NSObject>
- (void)onAcceptBtn:(NSString *)targetUserId;
@end


@interface DUVOHJNFriendRequestTVCell : UITableViewCell
@property (nonatomic, strong)WFCCFriendRequest *friendRequest;
@property (nonatomic, weak)id<DUVOHJNFriendRequestTVCellDelegate> delegate;
@end
