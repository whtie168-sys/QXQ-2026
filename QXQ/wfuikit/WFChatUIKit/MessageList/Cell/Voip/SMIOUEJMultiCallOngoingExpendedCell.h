//
//  SMIOUEJMultiCallOngoingExpendedCell.h
//  WFChatUIKit
//
//  Created by Rain on 2022/5/8.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol SMIOUEJMultiCallOngoingExpendedCellDelegate <NSObject>
-(void)didJoinButtonPressed;
-(void)didCancelButtonPressed;
@end

@interface SMIOUEJMultiCallOngoingExpendedCell : UITableViewCell
@property(nonatomic, weak)id<SMIOUEJMultiCallOngoingExpendedCellDelegate> delegate;
@property(nonatomic, strong)UILabel *callHintLabel;
@property(nonatomic, strong)UIButton *joinButton;
@property(nonatomic, strong)UIButton *cancelButton;
@end

NS_ASSUME_NONNULL_END
