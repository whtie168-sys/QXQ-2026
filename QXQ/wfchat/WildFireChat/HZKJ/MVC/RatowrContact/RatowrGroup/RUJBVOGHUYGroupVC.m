//
//  RUJBVOGHUYGroupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "RUJBVOGHUYGroupVC.h"
#import "YUBWOIJWDMessageVC.h"

#import "PIUODJNSendBusinessCardsPopView.h"

@interface RUJBVOGHUYGroupVC ()<UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong)NSMutableArray<WFCCGroupInfo *> *groups;

@property (nonatomic, strong) NSMutableArray<WFCCGroupInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@end

@implementation RUJBVOGHUYGroupVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self refreshList];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11, *)) { // https://www.jianshu.com/p/2378ca588efd
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"GroupChat");
    
    _groups = NSMutableArray.new;
    _searchList = NSMutableArray.new;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"RUJBVOGHUYTableVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"RUJBVOGHUYTableVCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(WIDTH - 15 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    } else {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;

        self.tableView.tableHeaderView = _searchController.searchBar;
        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
    
    self.definesPresentationContext = YES;
}

- (void)refreshList {
    [self.groups removeAllObjects];
//    NSArray *groupIds = [WFCCIMService.sharedWFCIMService getFavGroups];
    
    WS(weakself) // 获取当前用户的所有群组，注意这个方法的代价比较大，不建议高频使用
    [[AppService sharedAppService] groupListQuery:^(NSArray<WFCCGroupInfo *> * _Nonnull groups) {
        [[WFCCGroupDB sharedManager] deleteAllGroup];
        [[WFCCGroupDB sharedManager] insertOrUpdateGroupInfos:groups];

        weakself.groups = [NSMutableArray arrayWithArray:groups];
        [weakself.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
    
//    [WFCCIMService.sharedWFCIMService getMyGroups:^(NSArray<NSString *> *groupIds) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            for (NSInteger i = (groupIds.count - 1); i >= 0; i --) {
//                WFCCGroupInfo *groupInfo = [WFCCIMService.sharedWFCIMService getGroupInfo:groupIds[i] refresh:YES];
//                if (groupInfo) {
//                    groupInfo.target = groupIds[i];
//                    [self.groups addObject:groupInfo];
//                }
//            }
//            [weakself.tableView reloadData];
//        });
//    } error:^(int error_code) {
//    }];
}
- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (int i = 0; i < self.groups.count; ++i) {
        for (WFCCGroupInfo *groupInfo in groupInfoList) {
            if([self.groups[i].target isEqualToString:groupInfo.target]) {
                self.groups[i] = groupInfo;
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_searchController.active) {
        return _searchList.count;
    }
    return self.groups.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RUJBVOGHUYTableVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RUJBVOGHUYTableVCell" forIndexPath:indexPath];
    if (_searchController.active) {
        cell.groupInfo = _searchList[indexPath.row];
    }else {
        if (self.groups && self.groups.count > 0) {
            if (indexPath.row <= self.groups.count-1) {
                cell.groupInfo = self.groups[indexPath.row];
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCGroupInfo *groupInfo = (_searchController.active ? _searchList[indexPath.row] : _groups[indexPath.row]);
    
    if (_type == 1) { // 分享联系人到群聊
    
        WFCCUserInfo *targetUserinfo = [[WFCCUserDB sharedManager] getUserInfo:_target];
        
        PIUODJNSendBusinessCardsPopView *popView = [[PIUODJNSendBusinessCardsPopView alloc] init];
        popView.conversationType = Group_Type;
        WS(weakself)
        [popView setCardsBlock:^{
//            @param targetId 目标Id
//            @param type 类型，0 用户，1 群组， 3 频道。
//            @param fromUser 分享用户。
            WFCCCardMessageContent *card = [WFCCCardMessageContent cardWithTarget:targetUserinfo.userId type:CardType_User from:groupInfo.target];
            WFCCConversation *conversation = [WFCCConversation conversationWithType:Group_Type target:groupInfo.target line:0];
            
            [[WFCCIMService sharedWFCIMService] send:conversation content:card success:^(long long messageUid, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakself.navigationController popViewControllerAnimated:YES];
                    });
                });
            } error:^(int error_code) {
            }];
        }];
        NSString *name = (targetUserinfo.alias.length > 0 ? targetUserinfo.alias : targetUserinfo.displayName);
        if (targetUserinfo.finalName.length > 0) {
            name = targetUserinfo.finalName;
        }
        if ([CommonHelper.main isChinese]) {
            [popView showCommand:[NSString stringWithFormat:@"将%@发送给%@",name, groupInfo.displayName] imgA:targetUserinfo.portrait imB:groupInfo.portrait];
        }else {
            [popView showCommand:[NSString stringWithFormat:@"Send %@ to %@",name, groupInfo.displayName] imgA:targetUserinfo.portrait imB:groupInfo.portrait];
        }
        return;
    }
    YUBWOIJWDMessageVC *mvc = YUBWOIJWDMessageVC.new;
    mvc.conversation = [WFCCConversation conversationWithType:Group_Type target:groupInfo.target line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.0;
}


//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//       // [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        
//    }
//}
//
//- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *groupId = self.groups[indexPath.row].target;
//    __weak typeof(self) ws = self;
//    
//    
//    UITableViewRowAction *cancel = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"移除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
//        
//        [[WFCCIMService sharedWFCIMService] setFavGroup:groupId fav:NO success:^{
//            [ws.view makeToast:@"已移除" duration:2.0 position:CSToastPositionCenter];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [ws refreshList];
//            });
//            
//        }error:^(int error_code) {
//            [ws.view makeToast:@"操作失败" duration:2 position:CSToastPositionCenter];
//        }];
//    }];
//    cancel.backgroundColor = [UIColor redColor];
//    return @[cancel];
//}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
}
- (void)didPresentSearchController:(UISearchController *)searchController {
}
- (void)willDismissSearchController:(UISearchController *)searchController {
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
        // 1. 获取当前的输入模式
        if (@available(iOS 13.0, *)) {
            UITextInputMode *currentInputMode = searchController.searchBar.searchTextField.textInputMode;
            NSString *keyboardLanguage = currentInputMode.primaryLanguage;
            // 2. 判断是否是中文键盘（可能是 zh-Hans、zh-Hant 等）
            BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

            // 3. 获取 markedTextRange
            UITextRange *markedRange = searchController.searchBar.searchTextField.markedTextRange;
            // 4. 只有当【使用中文键盘】且【没有拼音未上屏】时才触发搜索
            if (isChineseKeyboard && markedRange != nil) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }
        [self.searchList removeAllObjects];
        if (searchString.length > 0) {
            QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
            BOOL isChinese = [pu isChinese:searchString];
            
            for (WFCCGroupInfo *model in self.groups) {
                if ([model.displayName.lowercaseString containsString:searchString.lowercaseString]) {
                    [self.searchList addObject:model];
                } else if(!isChinese) {
                    if ([pu isMatch:model.displayName ofPinYin:searchString]) {
                        [self.searchList addObject:model];
                    }
                }
            }
        }
    }
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end



@interface RUJBVOGHUYTableVCell ()
@property (weak, nonatomic) IBOutlet UIImageView *portraitImgView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@end

@implementation RUJBVOGHUYTableVCell

- (void)awakeFromNib{
    [super awakeFromNib];
    _portraitImgView.layer.cornerRadius = 20.0;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    
    if (groupInfo.displayName.length == 0) {
        _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)",LLLLLL(@"GroupChat") ,(int)groupInfo.memberCount];
    } else {
        _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.displayName, (int)groupInfo.memberCount];
    }

//    if (groupInfo.portrait.length) {
        [_portraitImgView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                     context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    } else {
//        __weak typeof(self)ws = self;
//        NSString *groupId = groupInfo.target;
//        
//        [[NSNotificationCenter defaultCenter] addObserverForName:@"GroupPortraitChanged" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
//            NSString *path = [note.userInfo objectForKey:@"path"];
//            if ([ws.groupInfo.target isEqualToString:groupId] && [groupId isEqualToString:note.object]) {
//                [ws.portraitImgView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"]];
//            }
//        }];
//        
//        NSString *path = [WFCCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//            return [AIOIUEHImage imageNamed:@"groupIcon"];
//        }];
//        if (path) {
//            [_portraitImgView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"]];
//        }
//    }
}

@end

