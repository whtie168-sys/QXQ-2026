//
//  RUJBVOGHUYShareCardVC.m
//  WUHOIBDK
//
//  Created by Ruby on 2/4/24.
//

#import "RUJBVOGHUYShareCardVC.h"
#import "EPIKNODWVContactsHeaderView.h"
#import "RUJBVOGHUYNewsFriendTVCell.h"

#import "EPIKNODWVContactVC.h"
#import "RUJBVOGHUYGroupVC.h"


@interface RUJBVOGHUYShareCardVC ()<UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCCConversationInfo *>    *dataList;

@property (nonatomic, strong) NSMutableArray<WFCCConversationInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@end

@implementation RUJBVOGHUYShareCardVC

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11, *)) { // https://www.jianshu.com/p/2378ca588efd
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    self.navigationItem.title = _isChinese?@"发送给":@"Send to";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemTitle:LLLLLL(@"OK") action:@selector(finish)]];
    
    _dataList = NSMutableArray.new;
    _searchList = NSMutableArray.new;
    
    // WFCCConversationInfo
    NSArray *datas = [[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type)] lines:@[@(0)]];
    for (WFCCConversationInfo *info in datas) {
        if ([info.conversation.target isEqualToString:@"group_message"]) {
            continue;
        }
        if ([info.conversation.target isEqualToString:_targetId]) {
            continue;
        }
        [_dataList addObject:info];
    }
    
    //设置代理
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"RUJBVOGHUYShareIconTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"RUJBVOGHUYShareIconTVCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"EPIKNODWVContactsHeaderView" bundle:NSBundle.mainBundle] forHeaderFooterViewReuseIdentifier:@"EPIKNODWVContactsHeaderView"];
    
    
    
    
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
- (void)finish {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_searchController.active) {
        return 1;
    }
    return 2;
}
//table 返回的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_searchController.active) {
        return _searchList.count;
    }
    if (section == 0) {
        return 2;
    }
    return _dataList.count;
}
//返回单元格内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_searchController.active || indexPath.section == 1) {
        RUJBVOGHUYShareIconTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RUJBVOGHUYShareIconTVCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (_searchController.active) {
            cell.info = _searchList[indexPath.row];
        }else {
            cell.info = _dataList[indexPath.row];
        }
        cell.sendButton.tag = indexPath.row;
        [cell.sendButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FirendAndGroup"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = IMAGENAME((UNString(@"xaicosgoe%@", (indexPath.row == 0 ? @"Firend" : @"Group"))));
        cell.textLabel.textColor = RGBA(0x222222);
        cell.textLabel.font = PINGFANG_M(15);
        cell.textLabel.text = (indexPath.row == 0 ? (_isChinese?@"选择朋友":@"Choose friends") : (_isChinese?@"选择群聊":@"Select group chat"));
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(85.0, (66.0-0.67), WIDTH-105.0, 0.67)];
        lineView.backgroundColor = RGBCOLOR(224.0, 224.0, 224.0);
        [cell.contentView addSubview:lineView];
        return cell;
    }
}
//@property (nonatomic, assign) NSInteger type;
//
//@property (nonatomic, assign) WFCCConversationType conversationType;
//
//@property (nonatomic, copy) NSString *target; // 单聊为用户id、群聊为群id
//
//@property (nonatomic, copy) NSString *filterId; // 用于过滤
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) { // 选择朋友
            EPIKNODWVContactVC *vc = EPIKNODWVContactVC.new;
            vc.type = 1;
            vc.conversationType = Single_Type;
            vc.target = _targetId;
            vc.filterId = _targetId;
            [self.navigationController pushViewController:vc animated:YES];
        }else { //选择群聊
            RUJBVOGHUYGroupVC *vc = RUJBVOGHUYGroupVC.new;
            vc.type = 1;
            vc.target = _targetId;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (void)send:(UIButton *)sender {
    WFCCConversationInfo *info = nil;
    if (_searchController.active) {
        info = _searchList[sender.tag];
    }else {
        info = _dataList[sender.tag];
    }
    /**
     targetId 目标Id     将targetId分享给目标id(fromUser)
     type 类型，0 用户，1 群组， 3 频道。
     fromUser 分享用户
     */
    WFCCCardMessageContent *card = [WFCCCardMessageContent cardWithTarget:_targetId type:CardType_User from:info.conversation.target];
    
    WS(weakself)
    [[WFCCIMService sharedWFCIMService] send:info.conversation content:card success:^(long long messageUid, long long timestamp) {
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.userInteractionEnabled = NO;
            sender.backgroundColor = UIColor.clearColor;
            [sender setTitle:(self->_isChinese?@"已发送":@"Has been sent") forState:UIControlStateNormal];
            [sender setTitleColor:RGBA(0x888888) forState:UIControlStateNormal];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.view makeToast:LLLLLL(@"SendFailure") duration:1.5 position:CSToastPositionCenter];
        });
    }];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.0;
    }
    if (self.dataList.count == 0) {
        return 0.0;
    }
    return 32.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
// view上设置背景色无效。 请使用方法 willDisplayHeaderView
    EPIKNODWVContactsHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"EPIKNODWVContactsHeaderView"];
    view.raeuionjyTitleLabel.textColor = RGBA(0x222222);
    view.raeuionjyTitleLabel.font = PINGFANG_R(14.0);
    if (section == 0 || _dataList.count == 0) {
        view.raeuionjyTitleLabel.text = @"";
    }else {
        view.raeuionjyTitleLabel.text = (_isChinese?@"最近":@"Recently");
    }
    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = UIColor.groupTableViewBackgroundColor;
}







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
            
            for (WFCCConversationInfo *info in self.dataList) {
                if (info.conversation.type == Single_Type) { // 单聊
                    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:info.conversation.target];
                    
                    if ([userInfo.alias.lowercaseString containsString:searchString.lowercaseString] ||
                        [userInfo.displayName.lowercaseString containsString:searchString.lowercaseString] ||
                        [userInfo.finalName.lowercaseString containsString:searchString.lowercaseString]) {
                        [self.searchList addObject:info];
                    }else if(!isChinese) {
                        if ([pu isMatch:userInfo.alias ofPinYin:searchString] ||
                            [pu isMatch:userInfo.displayName ofPinYin:searchString] ||
                            [pu isMatch:userInfo.finalName ofPinYin:searchString]) {
                            [self.searchList addObject:info];
                        }
                    }
                }else if (info.conversation.type == Group_Type) { // 群聊
                    WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:info.conversation.target];

                    if ([groupInfo.displayName.lowercaseString containsString:searchString.lowercaseString]) {
                        [self.searchList addObject:info];
                    }else if(!isChinese) {
                        if ([pu isMatch:groupInfo.displayName ofPinYin:searchString]) {
                            [self.searchList addObject:info];
                        }
                    }
                }
            }
        }
    }
    [self.tableView reloadData];
}




- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView        = nil;
    _dataList         = nil;
    _searchList     = nil;
}

@end







@interface RUJBVOGHUYShareIconTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;

@end

@implementation RUJBVOGHUYShareIconTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _sendButton.layer.cornerRadius = 10.0;
    _imgView.layer.cornerRadius = 25.0;
    [_sendButton setTitle:LLLLLL(@"Send") forState:UIControlStateNormal];
}

- (void)setInfo:(WFCCConversationInfo *)info {
    _info = info;
    
    if (info.conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:info.conversation.target];
        if(userInfo.userId.length == 0) {
            userInfo = [[WFCCUserInfo alloc] init];
            userInfo.userId = info.conversation.target;
        }
        
        [_imgView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage: [AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                             context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (userInfo.finalName.length > 0) {
            _tzboeuNameLabel.text = userInfo.finalName;
        } else if (userInfo.alias.length) {
            _tzboeuNameLabel.text = userInfo.alias;
        } else if(userInfo.displayName.length > 0) {
            _tzboeuNameLabel.text = userInfo.displayName;
        } else {
            _tzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>",  _info.conversation.target];
        }
    }else if (info.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:info.conversation.target];
        if(groupInfo.target.length == 0) {
            groupInfo = [[WFCCGroupInfo alloc] init];
            groupInfo.target = info.conversation.target;
        }
        
        [_imgView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                             context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (groupInfo.displayName.length > 0) {
            _tzboeuNameLabel.text = groupInfo.displayName;
        }else {
            _tzboeuNameLabel.text = LLLLLL(@"GroupChat");
        }
    }
}

@end
