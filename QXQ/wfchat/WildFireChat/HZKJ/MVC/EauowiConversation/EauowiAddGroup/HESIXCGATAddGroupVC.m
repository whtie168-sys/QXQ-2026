//
//  HESIXCGATAddGroupVC.m
//  QXQ
//
//  Created by Rubyuer on 10/13/23.
//

#import "HESIXCGATAddGroupVC.h"
#import "EPIKNODWVAddGroupCVCell.h"

@interface HESIXCGATAddGroupVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
{
    UIImage *_iconImg;
    NSString *review;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *memberNumLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *oxgcseoaiCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *oxgcseoaiLayout;
@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *oxgcseoais;

@property (weak, nonatomic) IBOutlet UIImageView *oxgcseoaiGroupView;

@property (weak, nonatomic) IBOutlet UIView *oxgcseoaiTitleView;
@property (weak, nonatomic) IBOutlet UITextField *oxgcseoaiTitleTF;


@property (strong, nonatomic) UIImagePickerController *pickerController;


// 入群需要验证的用户
@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *needReviews;


@property (weak, nonatomic) IBOutlet UILabel *groupMemberL;
@property (weak, nonatomic) IBOutlet UILabel *groupAvatarL;
@property (weak, nonatomic) IBOutlet UILabel *groupNameL;

@end

@implementation HESIXCGATAddGroupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    
    _groupMemberL.text = LLLLLL(@"GroupMember");
    _groupAvatarL.text = LLLLLL(@"GroupAvatar");
    _groupNameL.text = LLLLLL(@"GroupName");

    self.navigationItem.title = (_isChinese ? @"新建群聊" : @"New group chat");
    UIButton *item = [self itemTitle:LLLLLL(@"AlertButton") action:@selector(oxgcseoaiOk)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:item];
    
    ViewRadius(_oxgcseoaiTitleView, 15.0);
    ViewRadius(_oxgcseoaiGroupView, 20.0);
    _needReviews = NSMutableArray.new;
    _oxgcseoais = [[NSMutableArray alloc] initWithArray:_iconArray];
    
    if (_oxgcseoais.count <= 1) {
        _oxgcseoaiTitleTF.placeholder = [NSString stringWithFormat:@"%@",(_oxgcseoais.firstObject.friendAlias.length > 0 ? _oxgcseoais.firstObject.friendAlias : _oxgcseoais.firstObject.displayName)];
    }else {
        _oxgcseoaiTitleTF.placeholder = [NSString stringWithFormat:@"%@、%@",(_oxgcseoais.firstObject.friendAlias.length > 0 ? _oxgcseoais.firstObject.friendAlias : _oxgcseoais.firstObject.displayName), (_oxgcseoais[1].friendAlias.length > 0 ? _oxgcseoais[1].friendAlias : _oxgcseoais[1].displayName)];
    }
    [_oxgcseoais insertObject:[WFCCIMService.sharedWFCIMService getUserInfo:WFCCNetworkService.sharedInstance.userId refresh:NO] atIndex:0];
    _memberNumLabel.text = UNString(@"(%ld)", _oxgcseoais.count);
    
    _oxgcseoaiLayout.sectionInset = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
    _oxgcseoaiLayout.itemSize = CGSizeMake(60.0, 60.0);
    _oxgcseoaiLayout.minimumInteritemSpacing = 0.0;
    _oxgcseoaiLayout.minimumLineSpacing = 10.0;
    _oxgcseoaiCollectionView.delegate = self;
    _oxgcseoaiCollectionView.dataSource = self;
    [_oxgcseoaiCollectionView registerNib:[UINib nibWithNibName:@"EPIKNODWVAddGroupCVCell" bundle:nil] forCellWithReuseIdentifier:@"EPIKNODWVAddGroupCVCell"];
}

- (void)oxgcseoaiOk {
    [self.view endEditing:YES];
//    if (_oxgcseoaiTitleTF.text.length <= 0) {
//        [SVProgressHUD showErrorWithStatus:@"请填写群名称"];
//        [SVProgressHUD dismissWithDelay:1.0];
//        return;
//    }
//    if (_iconImg == nil) {
//        [SVProgressHUD showErrorWithStatus:@"请上传群头像"];
//        [SVProgressHUD dismissWithDelay:1.0];
//        return;
//    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要创建群聊吗？":@"Are you sure you want to create a group chat?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakself createGroup];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)createGroup {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [_needReviews removeAllObjects];
    NSMutableArray *userIds = NSMutableArray.new;
    
    for (WFCCUserInfo *userinfo in self.oxgcseoais) {
        UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:userinfo.extra];
        if ([userinfo.userId isEqualToString:WFCCNetworkService.sharedInstance.userId] || extraInfo.disableJoinToGroup == 0) {
            // 当前账号 或者 进群不需要审核
            [userIds addObject:userinfo.userId];
        }else {
            [_needReviews addObject:userinfo];
        }
    }
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_iconImg == nil) { // 没有上传群头像
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [self createHUD:hud group:(_oxgcseoaiTitleTF.text.length > 0 ? _oxgcseoaiTitleTF.text : _oxgcseoaiTitleTF.placeholder) portrait:@"" members:userIds];
        return;
    }
    hud.label.text = LLLLLL(@"Uploading");
    [hud showAnimated:YES];
    
    WS(weakself)
    NSData *portraitData = UIImageJPEGRepresentation(_iconImg, 0.70);
    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakself createHUD:hud group:(weakself.oxgcseoaiTitleTF.text.length > 0 ? weakself.oxgcseoaiTitleTF.text : weakself.oxgcseoaiTitleTF.placeholder) portrait:remoteUrl members:userIds];
        });
    } progress:^(long uploaded, long total) {
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakself.view makeToast:LLLLLL(@"UploadFailure") duration:1.0 position:CSToastPositionCenter];
        });
    }];
}

- (void)createHUD:(MBProgressHUD *)hud group:(NSString *)groupName portrait:(NSString *)portraitUrl members:(NSArray<NSString *> *)memberIds {
    WS(weakself)
    [WFCCIMService.sharedWFCIMService createGroup:@"" name:groupName portrait:portraitUrl type:GroupType_Restricted groupExtra:nil members:memberIds memberExtra:@"" notifyLines:@[@(0)] notifyContent:nil success:^(NSString *groupId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself.needReviews.count <= 0) {
                [hud hideAnimated:YES];
                
                if (weakself.tabBarController.selectedIndex != 0) {
                    weakself.tabBarController.selectedIndex = 0;
                }
                [weakself.navigationController popToRootViewControllerAnimated:YES];
            }else {
                [self sendHUD:hud AddGroupReview:groupId];
            }
        });
    } error:^(int error_code) {
        [hud hideAnimated:YES];
        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:2 position:CSToastPositionCenter];
    }];
}

- (void)sendHUD:(MBProgressHUD *)hud AddGroupReview:(NSString *)groupId {
    NSString *userStr = @"";
    NSMutableArray *inviteUsers = NSMutableArray.new;
    for (NSInteger i = 0; i < _needReviews.count; i ++) {
        WFCCUserInfo *userinfo = _needReviews[i];
        if ([userinfo.userId isEqualToString:WFCCNetworkService.sharedInstance.userId]) {
            continue;
        }
        [inviteUsers addObject:userinfo.userId];
        if (userStr.length >= 25) {
            continue;
        }
        NSString *name = (userinfo.friendAlias.length > 0 ? userinfo.friendAlias : userinfo.displayName);
        if (userStr.length <= 0) {
            userStr = name;
        }else {
            userStr = [NSString stringWithFormat:@"%@, %@",userStr, name];
        }
    }
    
     WS(weakself)
    [AppService.sharedAppService requestUrl:@"/group/invite" params:@{@"groupId":groupId, @"inviteUsers":inviteUsers, @"source":@(2)} success:^(NSDictionary * _Nonnull dict) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"请求已发送":@"Request has been sent") message:(self->_isChinese?UNString(@"%@等开启了入群需审核，对方同意后才会进入群聊", userStr):UNString(@"%@ open the group needs to be reviewed, the other party agrees to enter the group chat", userStr)) preferredStyle:UIAlertControllerStyleAlert];
        [hud hideAnimated:YES];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (weakself.tabBarController.selectedIndex != 0) {
                weakself.tabBarController.selectedIndex = 0;
            }
            [weakself.navigationController popToRootViewControllerAnimated:YES];
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
     } error:^(int errCode, NSString * _Nonnull message) {
         [hud hideAnimated:YES];
//         [weakself.view makeToast:@"邀请加入群组请求失败" duration:2 position:CSToastPositionCenter];
         if (weakself.tabBarController.selectedIndex != 0) {
             weakself.tabBarController.selectedIndex = 0;
         }
         [weakself.navigationController popToRootViewControllerAnimated:YES];
     }];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _oxgcseoais.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EPIKNODWVAddGroupCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EPIKNODWVAddGroupCVCell" forIndexPath:indexPath];
    cell.model = _oxgcseoais[indexPath.row];
    return cell;
}





- (IBAction)oxgcseoaiGroupicon:(UIButton *)sender {
    [self.view endEditing:YES];
    WS(weakself)
    [CommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        self->_iconImg = image;
        weakself.oxgcseoaiGroupView.image = image;
    }];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)dealloc {
    NSLog(@"dealloc - %@",NSStringFromClass(self.class));
}

@end
