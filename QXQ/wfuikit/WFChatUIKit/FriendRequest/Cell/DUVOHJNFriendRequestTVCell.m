//
//  FriendRequestTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/23.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "DUVOHJNFriendRequestTVCell.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "AIOIUEHImage.h"

@interface DUVOHJNFriendRequestTVCell()
@property (nonatomic, strong)UIImageView *trewqPortraitView;
@property (nonatomic, strong)UILabel *tzboeuNameLabel;
@property (nonatomic, strong)UILabel *reasonLabel;
@property (nonatomic, strong)UIButton *acceptBtn;
@end

@implementation DUVOHJNFriendRequestTVCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self initSubViews];
}

- (void)initSubViews {
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
    self.trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 40, 40)];
    self.tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 40 + 20,11, width - 128, 16)];
    self.tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];
    self.tzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
    self.reasonLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 40 + 20, 11 + 15 + 6, width - 128, 14)];
    self.reasonLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
    self.reasonLabel.textColor = [UIColor colorWithHexString:@"0xb3b3b3"];
    
    self.acceptBtn = [[UIButton alloc] initWithFrame:CGRectMake(width - (46 + 16), 16, 46, 28)];
    [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.acceptBtn setTitle:WFCString(@"Accept") forState:UIControlStateNormal];
    [self.acceptBtn setBackgroundColor:[UIColor colorWithHexString:@"0x4764DC"]];
    self.acceptBtn.layer.cornerRadius = 4.f;
    self.acceptBtn.layer.masksToBounds = YES;
    [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.acceptBtn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
    
    [self.contentView addSubview:self.trewqPortraitView];
    [self.contentView addSubview:self.tzboeuNameLabel];
    [self.contentView addSubview:self.reasonLabel];
    [self.contentView addSubview:self.acceptBtn];
    
    [self.acceptBtn addTarget:self action:@selector(onAddBtn:) forControlEvents:UIControlEventTouchDown];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)onAddBtn:(id)sender {
    [self.delegate onAcceptBtn:self.friendRequest.target];
}

- (void)setFriendRequest:(WFCCFriendRequest *)friendRequest {
    _friendRequest = friendRequest;
//    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:friendRequest.target refresh:NO];
    [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[friendRequest.myFriend.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]  placeholderImage: [AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    self.tzboeuNameLabel.text = (friendRequest.myFriend.displayName.length > 0 ? friendRequest.myFriend.displayName : friendRequest.myFriend.name);
    self.reasonLabel.text = friendRequest.reason;
    BOOL expired = NO;
    NSDate *date = [[NSDate alloc] init];
    if (date.timeIntervalSince1970*1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000) {
        expired = YES;
    }
    if (friendRequest.status == 0 && !expired) {
        [self.acceptBtn setTitle:WFCString(@"Accept") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:[UIColor colorWithHexString:@"0x4764DC"]];
        [self.acceptBtn setEnabled:YES];
    } else if (friendRequest.status == 1) {
        [self.acceptBtn setTitle:WFCString(@"Accepted") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:self.backgroundColor];
        [self.acceptBtn setEnabled:NO];
    } else if (friendRequest.status == 2) {
        [self.acceptBtn setTitle:WFCString(@"Rejected") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:self.backgroundColor];
        [self.acceptBtn setEnabled:NO];
    } else { //expired
        [self.acceptBtn setTitle:WFCString(@"Expired") forState:UIControlStateNormal];
        [self.acceptBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.acceptBtn setBackgroundColor:self.backgroundColor];
        [self.acceptBtn setEnabled:NO];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
    self.trewqPortraitView.image = nil;
}

@end
