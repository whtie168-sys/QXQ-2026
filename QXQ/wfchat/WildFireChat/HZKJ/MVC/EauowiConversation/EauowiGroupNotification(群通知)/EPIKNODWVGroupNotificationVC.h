//
//  EPIKNODWVGroupNotificationVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/25/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface EPIKNODWVGroupNotificationVC : QABWJEFDOCYMainVC

@end


@interface EPIKNODWVGroupNotificationTVCell : UITableViewCell

@property (nonatomic, strong) WaitAcceptList *acceptList;

@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@end

NS_ASSUME_NONNULL_END
