//
//  SelectedUserCollectionViewCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HNWOUIDSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface HNWOUIDSelectedUserCVCell : UICollectionViewCell
@property (nonatomic, strong)HNWOUIDSelectModel *model;
@property (nonatomic, strong)UIImageView *imgV;
@property (nonatomic, assign)BOOL isSmall;
@end

NS_ASSUME_NONNULL_END
