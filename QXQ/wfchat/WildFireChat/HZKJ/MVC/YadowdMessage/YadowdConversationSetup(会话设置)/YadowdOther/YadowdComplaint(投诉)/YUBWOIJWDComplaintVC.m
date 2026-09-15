//
//  YUBWOIJWDComplaintVC.m
//  QXQ
//
//  Created by Loooooo on 10/17/23.
//

#import "YUBWOIJWDComplaintVC.h"
#import "YUBWOIJWDComplaintBBVC.h"


@interface YUBWOIJWDComplaintVC ()

@property (weak, nonatomic) IBOutlet UILabel *complaintAL;
@property (weak, nonatomic) IBOutlet UILabel *complaintBL;
@property (weak, nonatomic) IBOutlet UILabel *complaintCL;

@end

@implementation YUBWOIJWDComplaintVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"CauseOfComplaint");
    
    _complaintAL.text = LLLLLL(@"ComplaintDescA");
    _complaintBL.text = LLLLLL(@"ComplaintDescB");
    _complaintCL.text = LLLLLL(@"ComplaintDescC");
}


- (IBAction)raeuionjyComplaint:(UIButton *)sender {
    YUBWOIJWDComplaintBBVC *vc = YUBWOIJWDComplaintBBVC.new;
    vc.reason = @[_complaintAL.text, _complaintAL.text, _complaintCL.text, @""][sender.tag];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
