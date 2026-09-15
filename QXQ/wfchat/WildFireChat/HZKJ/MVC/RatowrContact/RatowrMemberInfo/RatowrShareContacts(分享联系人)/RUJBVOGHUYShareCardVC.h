//
//  RUJBVOGHUYShareCardVC.h
//  WUHOIBDK
//
//  Created by Ruby on 2/4/24.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface RUJBVOGHUYShareCardVC : QABWJEFDOCYMainVC

@property (nonatomic, copy) NSString *targetId;

@end

@interface RUJBVOGHUYShareIconTVCell : UITableViewCell

@property (nonatomic, strong) WFCCConversationInfo *info;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@end

NS_ASSUME_NONNULL_END
