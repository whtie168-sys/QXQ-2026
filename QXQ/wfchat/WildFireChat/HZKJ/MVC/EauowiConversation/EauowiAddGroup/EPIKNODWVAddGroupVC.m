//
//  EPIKNODWVAddGroupVC.m
//  QXQ
//
//  Created by Loooooo on 10/13/23.
//

#import "EPIKNODWVAddGroupVC.h"
#import "EPIKNODWVAddGroupCVCell.h"

@interface EPIKNODWVAddGroupVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
{
    UIImage *_iconImg;
    NSString *review;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *memberNumLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *eubnxowCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *eubnxowLayout;
@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *eubnxows;

@property (weak, nonatomic) IBOutlet UIImageView *eubnxowGroupView;

@property (weak, nonatomic) IBOutlet UIView *eubnxowTitleView;
@property (weak, nonatomic) IBOutlet UITextField *eubnxowTitleTF;


@property (strong, nonatomic) UIImagePickerController *pickerController;


// 入群需要验证的用户
@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *needReviews;


@property (weak, nonatomic) IBOutlet UILabel *groupMemberL;
@property (weak, nonatomic) IBOutlet UILabel *groupAvatarL;
@property (weak, nonatomic) IBOutlet UILabel *yzdoajGroupNameL;

@end

@implementation EPIKNODWVAddGroupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    
    _groupMemberL.text = LLLLLL(@"GroupMember");
    _groupAvatarL.text = LLLLLL(@"GroupAvatar");
    _yzdoajGroupNameL.text = LLLLLL(@"GroupName");

    self.navigationItem.title = (_isChinese ? @"新建群聊" : @"New group chat");
    UIButton *item = [self itemTitle:LLLLLL(@"AlertButton") action:@selector(eubnxowOk)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:item];
    
    ViewRadius(_eubnxowTitleView, 15.0);
    ViewRadius(_eubnxowGroupView, 20.0);
    _needReviews = NSMutableArray.new;
    _eubnxows = [[NSMutableArray alloc] initWithArray:_iconArray];
    
    if (_eubnxows.count <= 1) {
        _eubnxowTitleTF.placeholder = [NSString stringWithFormat:@"%@",(_eubnxows.firstObject.finalName.length > 0 ? _eubnxows.firstObject.finalName : _eubnxows.firstObject.displayName)];
    }else {
        _eubnxowTitleTF.placeholder = [NSString stringWithFormat:@"%@、%@",(_eubnxows.firstObject.finalName.length > 0 ? _eubnxows.firstObject.finalName : _eubnxows.firstObject.displayName), (_eubnxows[1].finalName.length > 0 ? _eubnxows[1].finalName : _eubnxows[1].displayName)];
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    WFCCUserInfo *userInfo = [[AppCache sharedAppCache] getMyInfo];
    [self.eubnxows insertObject:userInfo atIndex:0];
    
    _memberNumLabel.text = UNString(@"(%ld)", _eubnxows.count);
    
    _eubnxowLayout.sectionInset = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
    _eubnxowLayout.itemSize = CGSizeMake(60.0, 60.0);
    _eubnxowLayout.minimumInteritemSpacing = 0.0;
    _eubnxowLayout.minimumLineSpacing = 10.0;
    _eubnxowCollectionView.delegate = self;
    _eubnxowCollectionView.dataSource = self;
    [_eubnxowCollectionView registerNib:[UINib nibWithNibName:@"EPIKNODWVAddGroupCVCell" bundle:nil] forCellWithReuseIdentifier:@"EPIKNODWVAddGroupCVCell"];
}

- (void)eubnxowOk {
    [self.view endEditing:YES];
//    if (_eubnxowTitleTF.text.length <= 0) {
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
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    for (WFCCUserInfo *userinfo in self.eubnxows) {
        UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:userinfo.extra];
//        if ([userinfo.userId isEqualToString:userId] || extraInfo.disableJoinToGroup == 0) {
            // 当前账号 或者 进群不需要审核
            [userIds addObject:userinfo.userId];
//        }else {
//            [_needReviews addObject:userinfo];
//        }
    }
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_iconImg == nil) { // 没有上传群头像
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [self createHUD:hud group:(_eubnxowTitleTF.text.length > 0 ? _eubnxowTitleTF.text : _eubnxowTitleTF.placeholder) portrait:@"" members:userIds];
        return;
    }
    hud.label.text = LLLLLL(@"Uploading");
    [hud showAnimated:YES];
    
    WS(weakself)
    NSData *portraitData = UIImageJPEGRepresentation(_iconImg, 0.70);
    [[AppService sharedAppService] generateUploadFile:@"groupAvatar"
                                              success:^(NSString * _Nonnull uploadUrl, NSString * _Nonnull requestUrl) {
        [[AppService sharedAppService] uploadData:portraitData
                                              url:uploadUrl
                                        remoteUrl:requestUrl
                                          success:^(NSString * _Nonnull remoteUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [weakself createHUD:hud group:(weakself.eubnxowTitleTF.text.length > 0 ? weakself.eubnxowTitleTF.text : weakself.eubnxowTitleTF.placeholder) portrait:remoteUrl members:userIds];
            });

        } progress:^(long uploaded, long total) {
            
        } fail:^(int error_code) {
            
        }];
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakself.view makeToast:LLLLLL(@"UploadFailure") duration:1.0 position:CSToastPositionCenter];
        });

    }];
    
//    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [hud hideAnimated:YES];
//            [weakself createHUD:hud group:(weakself.eubnxowTitleTF.text.length > 0 ? weakself.eubnxowTitleTF.text : weakself.eubnxowTitleTF.placeholder) portrait:remoteUrl members:userIds];
//        });
//    } progress:^(long uploaded, long total) {
//    } error:^(int error_code) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [hud hideAnimated:YES];
//            [weakself.view makeToast:LLLLLL(@"UploadFailure") duration:1.0 position:CSToastPositionCenter];
//        });
//    }];
}

- (void)createHUD:(MBProgressHUD *)hud group:(NSString *)groupName portrait:(NSString *)portraitUrl members:(NSArray<NSString *> *)memberIds {
    WS(weakself)
    [[AppService sharedAppService] groupAdd:groupName
                                    userIds:memberIds
                                description:@""
                                   portrait:portraitUrl
                                    success:^(NSString *groupId) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            if (weakself.needReviews.count <= 0) {
                [hud hideAnimated:YES];
                
                if (weakself.tabBarController.selectedIndex != 0) {
                    weakself.tabBarController.selectedIndex = 0;
                }
                [weakself.navigationController popToRootViewControllerAnimated:YES];
//            }else {
//                [self sendHUD:hud AddGroupReview:groupId];
//            }
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:2 position:CSToastPositionCenter];
    }];
    
//    [WFCCIMService.sharedWFCIMService createGroup:@"" name:groupName portrait:portraitUrl type:GroupType_Restricted groupExtra:nil members:memberIds memberExtra:@"" notifyLines:@[@(0)] notifyContent:nil success:^(NSString *groupId) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (weakself.needReviews.count <= 0) {
//                [hud hideAnimated:YES];
//                
//                if (weakself.tabBarController.selectedIndex != 0) {
//                    weakself.tabBarController.selectedIndex = 0;
//                }
//                [weakself.navigationController popToRootViewControllerAnimated:YES];
//            }else {
//                [self sendHUD:hud AddGroupReview:groupId];
//            }
//        });
//    } error:^(int error_code) {
//        [hud hideAnimated:YES];
//        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:2 position:CSToastPositionCenter];
//    }];
}

- (void)sendHUD:(MBProgressHUD *)hud AddGroupReview:(NSString *)groupId {
    NSString *userStr = @"";
    NSMutableArray *inviteUsers = NSMutableArray.new;
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    for (NSInteger i = 0; i < self.eubnxows.count; i ++) {
        WFCCUserInfo *userinfo = self.eubnxows[i];
        if ([userinfo.userId isEqualToString:userId]) {
            continue;
        }
        [inviteUsers addObject:userinfo.userId];
        if (userStr.length >= 25) {
            continue;
        }
        NSString *name = (userinfo.alias.length > 0 ? userinfo.alias : userinfo.displayName);
        if (userinfo.finalName.length > 0) {
            name = userinfo.finalName;
        }
        if (userStr.length <= 0) {
            userStr = name;
        }else {
            userStr = [NSString stringWithFormat:@"%@, %@",userStr, name];
        }
    }
    
     WS(weakself)
    [[AppService sharedAppService] groupInvite:groupId
                                   inviteUsers:inviteUsers
                                        source:@"2"
                                       success:^{
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
    
//    [AppService.sharedAppService requestUrl:@"/group/invite" params:@{@"groupId":groupId, @"inviteUsers":inviteUsers, @"source":@(2)} success:^(NSDictionary * _Nonnull dict) {
//        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"请求已发送":@"Request has been sent") message:(self->_isChinese?UNString(@"%@等开启了入群需审核，对方同意后才会进入群聊", userStr):UNString(@"%@ open the group needs to be reviewed, the other party agrees to enter the group chat", userStr)) preferredStyle:UIAlertControllerStyleAlert];
//        [hud hideAnimated:YES];
//        
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//            if (weakself.tabBarController.selectedIndex != 0) {
//                weakself.tabBarController.selectedIndex = 0;
//            }
//            [weakself.navigationController popToRootViewControllerAnimated:YES];
//        }];
//        [alertController addAction:cancelAction];
//        [self presentViewController:alertController animated:YES completion:nil];
//     } error:^(int errCode, NSString * _Nonnull message) {
//         [hud hideAnimated:YES];
////         [weakself.view makeToast:@"邀请加入群组请求失败" duration:2 position:CSToastPositionCenter];
//         if (weakself.tabBarController.selectedIndex != 0) {
//             weakself.tabBarController.selectedIndex = 0;
//         }
//         [weakself.navigationController popToRootViewControllerAnimated:YES];
//     }];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _eubnxows.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EPIKNODWVAddGroupCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EPIKNODWVAddGroupCVCell" forIndexPath:indexPath];
    cell.model = _eubnxows[indexPath.row];
    return cell;
}





- (IBAction)eubnxowGroupicon:(UIButton *)sender {
    [self.view endEditing:YES];
    WS(weakself)
    [CommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        self->_iconImg = image;
        weakself.eubnxowGroupView.image = image;
    }];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)dealloc {
    NSLog(@"dealloc - %@",NSStringFromClass(self.class));
}

@end
