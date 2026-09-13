//
//  WOPMKDIOFZTAvatarVC.h
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AvatarSetBlock)(NSString *);
@interface WOPMKDIOFZTAvatarVC : QABWJEFDOCYMainVC
@property BOOL isRegister;
@property AvatarSetBlock setBlock;
@end


@interface WOPMKDIOFZTAvatarCVCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *waxiouvIconV;
@end

NS_ASSUME_NONNULL_END
