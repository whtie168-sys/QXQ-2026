//
//  RUJBVOGHUYCommonGroupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 2/2/24.
//

#import "RUJBVOGHUYCommonGroupVC.h"
#import "RUJBVOGHUYGroupVC.h"

#import "YUBWOIJWDMessageVC.h"

@interface RUJBVOGHUYCommonGroupVC ()<UITableViewDataSource, UITableViewDelegate>
{
    BOOL _isChinese;
}
@property (nonatomic, strong)NSMutableArray<WFCCGroupInfo *> *groups;

@property (nonatomic, strong) UIView *nullView;

@end

@implementation RUJBVOGHUYCommonGroupVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    self.navigationItem.title = (_isChinese?@"我和他的共同群组":@"Common groups");
    
//    if (_groupIds.count) {
//        _groups = NSMutableArray.new;
//        _groups = [[WFCCGroupDB sharedManager] getGroupInfos:_groupIds].mutableCopy;
        
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        self.tableView.backgroundColor = UIColor.whiteColor;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView registerNib:[UINib nibWithNibName:@"RUJBVOGHUYTableVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"RUJBVOGHUYTableVCell"];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
//    }else {
//        [self nullView];
//    }
    
    [self getFriendGroups];
}

- (void)getFriendGroups {
    [SVProgressHUD show];
    [[AppService sharedAppService] groupListQueryUser:@{@"id": self.userId}
                                              success:^(NSArray<WFCCGroupInfo *> * _Nonnull friendgroups) {
        
        [[AppService sharedAppService] groupListQuery:^(NSArray<WFCCGroupInfo *> * _Nonnull mygroups) {
            [SVProgressHUD dismiss];
            [self getCommGroups:friendgroups myGroups:mygroups];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
        }];

    } error:^(int errCode, NSString * _Nonnull message) {
        [SVProgressHUD dismiss];
    }];
}

- (void)getCommGroups:(NSArray *)friendgroups myGroups:(NSArray *)mygroups {
    NSMutableArray *comms = [NSMutableArray new];
    for (WFCCGroupInfo *group1 in friendgroups) {
        for (WFCCGroupInfo *group2 in mygroups) {
            if ([group1.target isEqualToString:group2.target]) {
                [comms addObject:group1];
                break;
            }
        }
    }
    _groups = comms;
    if (_groups.count == 0) {
        [self nullView];
    }
    [self.tableView reloadData];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (int i = 0; i < self.groupIds.count; ++i) {
        for (WFCCGroupInfo *groupInfo in groupInfoList) {
            if([self.groupIds[i] isEqualToString:groupInfo.target]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _groups.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RUJBVOGHUYTableVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RUJBVOGHUYTableVCell" forIndexPath:indexPath];
    cell.groupInfo = _groups[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YUBWOIJWDMessageVC *mvc = YUBWOIJWDMessageVC.new;
    mvc.conversation = [WFCCConversation conversationWithType:Group_Type target:_groups[indexPath.row].target line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.0;
}


- (UIView *)nullView {
    if (!_nullView) {
        _nullView = [[UIView alloc] initWithFrame:CGRectMake((WIDTH-178.0)/2.0, (HEIGHT-320.0)/2.0, 178.0, 225.0)];
        _nullView.backgroundColor = UIColor.clearColor;
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 178.0, 175.0)];
        imgView.image = IMAGENAME(@"commonGroupNull");
        [_nullView addSubview:imgView];
        
        UILabel *nullLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(imgView.frame)+20.0, 178.0, 22.0)];
        nullLabel.textAlignment = NSTextAlignmentCenter;
        nullLabel.text = (_isChinese?@"暂无数据":@"No data yet");
        nullLabel.textColor = RGBA(0x9D9D9D);
        nullLabel.font = PINGFANG_R(14.0);
        [_nullView addSubview:nullLabel];
        
        [self.view addSubview:_nullView];
    }return _nullView;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
