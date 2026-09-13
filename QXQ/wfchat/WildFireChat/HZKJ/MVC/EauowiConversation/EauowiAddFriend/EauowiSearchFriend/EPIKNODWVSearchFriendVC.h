//
//  EPIKNODWVSearchFriendVC.h
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface EPIKNODWVSearchFriendVC : QABWJEFDOCYMainVC

@property (nonatomic, copy) NSString *phoneString;

@end

@interface EPIKNODWVSearchUserCVCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end



@interface EPIKNODWVSearchUserCRView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *tzboeuTitleLabel;

@end

NS_ASSUME_NONNULL_END
