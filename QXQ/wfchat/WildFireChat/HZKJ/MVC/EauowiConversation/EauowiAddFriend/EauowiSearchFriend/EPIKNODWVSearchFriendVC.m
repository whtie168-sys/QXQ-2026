//
//  EPIKNODWVSearchFriendVC.m
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import "EPIKNODWVSearchFriendVC.h"

#import "EPIKNODWVAddValidationVC.h"
#import "RUJBVOGHUYMemberInfoVC.h"
#import "YUBWOIJWDGroupInfoQrVC.h"

@interface EPIKNODWVSearchFriendVC ()<UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>
{
    BOOL _isNumber;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *eubnxowBgView;

@property (weak, nonatomic) IBOutlet UITextField *eubnxowTitleTF;

@property (weak, nonatomic) IBOutlet UIButton *eubnxowSearchButton;


@property (weak, nonatomic) IBOutlet UICollectionView *eubnxowCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *eubnxowLayout;
@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *searchUserList;
@property (nonatomic, strong) NSMutableArray<WFCCGroupInfo *> *searchGroupList;

@property (nonatomic, strong) UILabel *searchKeyLabel;

@end

@implementation EPIKNODWVSearchFriendVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    self.navigationItem.title = _isChinese ? @"搜索朋友/群" : @"Search for friends/group";
    
    ViewRadius(_eubnxowBgView, 15.0)
    ViewRadius(_eubnxowSearchButton, 15.0)
    if (!_isChinese) {
        _eubnxowTitleTF.placeholder = @"Phone number/id/group";
    }
    [_eubnxowSearchButton setTitle:(_isChinese?@"搜索":@"Search") forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    _eubnxowLayout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 20.0);
    _eubnxowLayout.itemSize = CGSizeMake(WIDTH, 60.0);
    _eubnxowLayout.minimumInteritemSpacing = 0.0;
    _eubnxowLayout.minimumLineSpacing = 0.0;
    _eubnxowCollectionView.delegate = self;
    _eubnxowCollectionView.dataSource = self;
    [_eubnxowCollectionView registerNib:[UINib nibWithNibName:@"EPIKNODWVSearchUserCVCell" bundle:nil] forCellWithReuseIdentifier:@"EPIKNODWVSearchUserCVCell"];
    [_eubnxowCollectionView registerNib:[UINib nibWithNibName:@"EPIKNODWVSearchUserCRView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"EPIKNODWVSearchUserCRView"];
    
    _eubnxowTitleTF.delegate = self;
    if (_phoneString.length) {
        _isNumber = YES;
        _eubnxowTitleTF.text = _phoneString;
        [self eubnxowSearch:nil];
    }else {
        _isNumber = NO;
    }
}

- (IBAction)eubnxowSearch:(UIButton *)sender {
    [self.view endEditing:YES];
    
//    for (WFCCGroupSearchInfo *groupSearchInfo in [WFCCIMService.sharedWFCIMService searchGroups:_eubnxowTitleTF.text]) {
//        NSLog(@"%@===%@",groupSearchInfo.groupInfo.target, groupSearchInfo.groupInfo.name);
//    }
//    return;
    
    if (_eubnxowTitleTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_eubnxowTitleTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    if (_eubnxowTitleTF.text.length <= 2) {
        [SVProgressHUD showErrorWithStatus:(_isChinese?@"请输入正确的手机号或ID":@"Please enter the correct phone number or ID")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = (_isChinese ? @"搜索中..." : @"Search...");
    [hud showAnimated:YES];
    
    NSString *pattern =@"[0-9]{5,12}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",pattern];
    _isNumber = [pred evaluateWithObject:_eubnxowTitleTF.text];
    
    WS(weakself)
    [self.searchUserList removeAllObjects];
    [self.searchGroupList removeAllObjects];
    [[AppService sharedAppService] friendSearch:_eubnxowTitleTF.text success:^(NSArray<WFCCUserInfo *> * _Nonnull searchUserList) {
        [hud hideAnimated:YES];
        weakself.searchUserList = [NSMutableArray arrayWithArray:searchUserList];
        if (searchUserList.count == 0) { // 为空
            weakself.searchKeyLabel.hidden = NO;
            weakself.searchKeyLabel.text = (self->_isChinese?@"没有搜索结果":@"No search results");
            [weakself.searchUserList removeAllObjects];
            [weakself.searchGroupList removeAllObjects];
        }else {
            weakself.searchKeyLabel.hidden = YES;
        }
        [weakself.eubnxowCollectionView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"失败"]) {
                text = @"Failure...";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        if (weakself.searchUserList.count) {
            [weakself.searchUserList removeAllObjects];
        }
        if (weakself.searchGroupList.count) {
            [weakself.searchGroupList removeAllObjects];
        }
        [weakself.eubnxowCollectionView reloadData];

    }];
    return;
    
    [AppService.sharedAppService requestUrl:@"/friend/search" params:@{@"q":_eubnxowTitleTF.text, @"limit":@(100)} success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        NSArray *userIds = dict[@"result"][@"users"];
        NSArray *groupIds = dict[@"result"][@"groups"];
        if (userIds.count) {
            weakself.searchUserList = [[WFCCUserDB sharedManager] getUserInfos:userIds inGroup:nil].mutableCopy;
            for (NSString *userId in userIds) {
                [[UserService shared] getUserInfo:userId refresh:YES success:^(WFCCUserInfo * _Nonnull userInfo) {
                    
                } error:^(int errorCode, NSString * _Nonnull message) {
                    
                }];
//                WFCCUserInfo *userInfo = [WFCCIMService.sharedWFCIMService getUserInfo:userId refresh:YES];
//                if (userInfo == nil) {
//                    WFCCUserInfo *aaUserInfo = WFCCUserInfo.new;
//                    aaUserInfo.userId = userId;
//                    [weakself.searchUserList addObject:aaUserInfo];
//                }else {
//                    [weakself.searchUserList addObject:userInfo];
//                }
            }
        }
        if (groupIds.count) {
//            weakself.searchGroupList = [WFCCIMService.sharedWFCIMService getGroupInfos:groupIds refresh:NO].mutableCopy;
            for (NSString *groupId in groupIds) {
                WFCCGroupInfo *groupInfo = [WFCCIMService.sharedWFCIMService getGroupInfo:groupId refresh:YES];
                if (groupInfo == nil) {
                    WFCCGroupInfo *aaGroupId = WFCCGroupInfo.new;
                    aaGroupId.target = groupId;
                    [weakself.searchGroupList addObject:aaGroupId];
                }else {
                    [weakself.searchGroupList addObject:groupInfo];
                }
            }
        }
        NSLog(@"======%@\n%@",weakself.searchUserList,weakself.searchGroupList);
        if (userIds.count == 0 && groupIds.count == 0) { // 为空
            weakself.searchKeyLabel.hidden = NO;
            weakself.searchKeyLabel.text = (self->_isChinese?@"没有搜索结果":@"No search results");
            [weakself.searchUserList removeAllObjects];
            [weakself.searchGroupList removeAllObjects];
        }else {
            weakself.searchKeyLabel.hidden = YES;
        }
        [weakself.eubnxowCollectionView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"失败"]) {
                text = @"Failure...";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        if (weakself.searchUserList.count) {
            [weakself.searchUserList removeAllObjects];
        }
        if (weakself.searchGroupList.count) {
            [weakself.searchGroupList removeAllObjects];
        }
        [weakself.eubnxowCollectionView reloadData];
    }];
    
    /**
    [self.searchUserList removeAllObjects];
    [AppService.sharedAppService requestUrl:@"/meili_search/query_user" params:@{@"q":_eubnxowTitleTF.text, @"limit":@(100)} success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        NSArray *userIds = dict[@"result"];
        if (userIds.count) {
            weakself.searchKeyLabel.hidden = YES;
            weakself.searchUserList = [WFCCIMService.sharedWFCIMService getUserInfos:userIds inGroup:nil].mutableCopy;
            for (NSString *userId in userIds) {
                [WFCCIMService.sharedWFCIMService getUserInfo:userId refresh:YES];
            }
        }else {
            weakself.searchKeyLabel.hidden = NO;
            weakself.searchKeyLabel.text = (self->_isChinese?@"没有搜索结果":@"No search results");
            [weakself.searchUserList removeAllObjects];
        }
        [weakself.eubnxowCollectionView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"失败"]) {
                text = @"Failure...";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        if (weakself.searchUserList.count) {
            [weakself.searchUserList removeAllObjects];
            [weakself.eubnxowCollectionView reloadData];
        }
     }];
     */
}
- (void)hudTitle:(NSString *)title {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger num = 0;
    if (_searchUserList.count > 0) {
        num += 1;
    }
    if (_searchGroupList.count > 0) {
        num += 1;
    }
    return num;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_searchUserList.count == 0 && _searchGroupList.count == 0) {
        return 0;
    }else { // 至少有一个有数据
        if (_searchUserList.count > 0 && _searchGroupList.count > 0) { // 2个都有值
            return (section == 0 ? _searchUserList.count : _searchGroupList.count);
        }else if (_searchUserList.count > 0) { // 只有“用户”有值
            return _searchUserList.count;
        }else { // 只有“群组”有值
            return _searchGroupList.count;
        }
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_searchUserList.count > 0 && _searchGroupList.count > 0) { // 2个都有值
        if (indexPath.section == 0) {
            return [self retureUserCell:collectionView indexPath:indexPath];
        }else {
            return [self retureGroupCell:collectionView indexPath:indexPath];
        }
    }else if (_searchUserList.count > 0) { // 只有“用户”有值
        return [self retureUserCell:collectionView indexPath:indexPath];
    }else { // 只有“群组”有值
        return [self retureGroupCell:collectionView indexPath:indexPath];
    }
    return nil;
}

- (UICollectionViewCell *)retureUserCell:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    EPIKNODWVSearchUserCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EPIKNODWVSearchUserCVCell" forIndexPath:indexPath];
    WFCCUserInfo *userinfo = _searchUserList[indexPath.row];
    [cell.iconView sd_setImageWithURL:URL(userinfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    cell.tzboeuNameLabel.text = userinfo.alias.length > 0 ? userinfo.alias : (userinfo.displayName.length > 0 ? userinfo.displayName : UNString(@"user<%@>", userinfo.userId));
    if (userinfo.finalName.length > 0) {
        cell.tzboeuNameLabel.text = userinfo.finalName;
    }
    if (userinfo.name.length > 0) {
        cell.phoneLabel.text = UNString(@"(%@)", userinfo.name);
    }else {
        cell.phoneLabel.text = @"";
    }
    return cell;
}
- (UICollectionViewCell *)retureGroupCell:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    EPIKNODWVSearchUserCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EPIKNODWVSearchUserCVCell" forIndexPath:indexPath];
    WFCCGroupInfo *groupInfo = _searchGroupList[indexPath.row];
    [cell.iconView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    if (groupInfo.displayName.length == 0) {
        cell.tzboeuNameLabel.text = LLLLLL(@"GroupChat");
    }else {
        cell.tzboeuNameLabel.text = groupInfo.displayName;
    }
//    cell.phoneLabel.text = UNString(@"(%d)", (int)groupInfo.memberCount); // memberCount 该值不准确 第一次加载时数量为0
    cell.phoneLabel.text = @"";
    return cell;
}


- (void)didSelectUserIndexPath:(NSIndexPath *)indexPath {
    WFCCUserInfo *userinfo = _searchUserList[indexPath.row];
    if (userinfo == nil) {
        [self.view makeToast:(_isChinese?@"等待数据加载...":@"Waiting for data to load...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([userinfo.userId isEqualToString:userId]) {
        [self.view makeToast:(_isChinese?@"不能添加自己为好友...":@"Can't add yourself as a friend...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if ([[WFCCIMService sharedWFCIMService] isMyFriend:userinfo.userId]) { // 是好友关系
        RUJBVOGHUYMemberInfoVC *vc = RUJBVOGHUYMemberInfoVC.new;
        vc.userId = userinfo.userId;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        WFCCUserInfo *myuser = [[AppCache sharedAppCache] getMyInfo];
        EPIKNODWVAddValidationVC *vc = EPIKNODWVAddValidationVC.new;
        vc.userInfo = userinfo;
        NSString *name = (myuser.displayName.length > 0 ? myuser.displayName : myuser.name);
        if (myuser.finalName.length > 0) {
            name = myuser.finalName;
        }
        vc.name = name;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)didSelectGroupIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"点击群组的Cell====%ld",indexPath.row);
    WFCCGroupInfo *groupInfo = _searchGroupList[indexPath.row];
    
    YUBWOIJWDGroupInfoQrVC *vc = YUBWOIJWDGroupInfoQrVC.new;
    vc.groupId = groupInfo.target;
    vc.sourceType = GroupMemberSource_Search;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_searchUserList.count > 0 && _searchGroupList.count > 0) { // 2个都有值
        if (indexPath.section == 0) {
            [self didSelectUserIndexPath:indexPath];
        }else {
            [self didSelectGroupIndexPath:indexPath];
        }
    }else if (_searchUserList.count > 0) { // 只有“用户”有值
        [self didSelectUserIndexPath:indexPath];
    }else { // 只有“群组”有值
        [self didSelectGroupIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (_searchUserList.count == 0 && _searchGroupList.count == 0) {
        return CGSizeZero;
    }else { // 至少有一个有数据
        return CGSizeMake(WIDTH, 40.0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSString *searchUserTitle = (_isChinese ? @"查找人" : @"Search users");
    NSString *searchGroupTitle = (_isChinese ? @"查找群" : @"Search group chats");
    if (_searchUserList.count > 0 && _searchGroupList.count > 0) { // 2个都有值
        return [self headCollectionView:collectionView kind:kind indexPath:indexPath title:(indexPath.section==0?searchUserTitle:searchGroupTitle)];
    }else if (_searchUserList.count > 0) { // 只有“用户”有值
        return [self headCollectionView:collectionView kind:kind indexPath:indexPath title:searchUserTitle];
    }else { // 只有“群组”有值
        return [self headCollectionView:collectionView kind:kind indexPath:indexPath title:searchGroupTitle];
    }
}
- (UICollectionReusableView *)headCollectionView:(UICollectionView *)collectionView kind:(NSString *)kind indexPath:(NSIndexPath *)indexPath title:(NSString *)title {
    EPIKNODWVSearchUserCRView *tzboeuHeadView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"EPIKNODWVSearchUserCRView" forIndexPath:indexPath];
    tzboeuHeadView.tzboeuTitleLabel.text = title;
    return tzboeuHeadView;
}


//@param userId 用户ID
//@param reason 请求说明
- (void)sendFriendResest:(WFCCUserInfo *)userInfo {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"InTheRequest");
    [hud showAnimated:YES];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    WS(weakself)
    WFCCUserInfo *myUserInfo = [[AppCache sharedAppCache] getMyInfo];
    [WFCCIMService.sharedWFCIMService sendFriendRequest:userInfo.userId reason:[NSString stringWithFormat:@"%@ %@",(self->_isChinese?@"我是":@"I am"), myUserInfo.displayName] extra:@"" success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            [weakself hudTitle:LLLLLL(@"SentSuccessfully")];
            [self.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if(error_code == 16) { // WFCCErrorCode
                hud.label.text = (self->_isChinese?@"已经发送过添加好友请求了":@"Already sent a friend request");
            } else if(error_code == 18) {
                hud.label.text = self->_isChinese?@"好友请求已被拒绝":@"The friend request has been rejected";
            } else if(error_code == 23) {
                hud.label.text = self->_isChinese?@"已经是好友了":@"We're already friends";
            } else {
                hud.label.text = LLLLLL(@"SendFailure");
            }
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}



- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        for (NSInteger i = 0; i < _searchUserList.count; i ++) {
            WFCCUserInfo *searchUserinfo = _searchUserList[i];
            if ([searchUserinfo.userId isEqualToString:userInfo.userId]) {
                [_searchUserList replaceObjectAtIndex:i withObject:userInfo];
                break;
            }
        }
    }
    [_eubnxowCollectionView reloadData];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (WFCCGroupInfo *groupInfo in groupInfoList) {
        for (NSInteger i = 0; i < _searchGroupList.count; i ++) {
            WFCCGroupInfo *searchGroupinfo = _searchGroupList[i];
            if ([searchGroupinfo.target isEqualToString:groupInfo.target]) {
                [_searchGroupList replaceObjectAtIndex:i withObject:groupInfo];
                break;
            }
        }
    }
    [_eubnxowCollectionView reloadData];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (_searchUserList.count == 0 && _searchGroupList.count == 0) {
        _searchKeyLabel.hidden = NO;
        _searchKeyLabel.text = (_isChinese?@"输入关键词开始搜索":@"Enter a keyword to start your search");
    }else {
        _searchKeyLabel.hidden = YES;
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (NSMutableArray<WFCCUserInfo *> *)searchUserList {
    if (!_searchUserList) {
        _searchUserList = NSMutableArray.new;
    }return _searchUserList;
}
- (NSMutableArray<WFCCGroupInfo *> *)searchGroupList {
    if (!_searchGroupList) {
        _searchGroupList = NSMutableArray.new;
    }return _searchGroupList;
}


- (UILabel *)searchKeyLabel {
    if (!_searchKeyLabel) {
        _searchKeyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 200.0, WIDTH, 30.0)];
        _searchKeyLabel.textAlignment = NSTextAlignmentCenter;
        _searchKeyLabel.textColor = RGBA(0x666666);
        _searchKeyLabel.text = (_isChinese?@"输入关键词开始搜索":@"Enter a keyword to start your search");
        _searchKeyLabel.font = PINGFANG_R(13.0);
        [self.view addSubview:_searchKeyLabel];
    }return _searchKeyLabel;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
@end

@implementation EPIKNODWVSearchUserCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    ViewRadius(_iconView, 20.0);
}

@end


@implementation EPIKNODWVSearchUserCRView

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

@end
