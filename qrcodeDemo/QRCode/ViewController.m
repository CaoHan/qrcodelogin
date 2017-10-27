//
//  ViewController.m
//  QRCode


#import "ViewController.h"
#import "QRCodeViewController.h"

@interface ViewController () <QRCodeViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)scanCode:(UIButton *)sender {
    
    QRCodeViewController *qrVc = [[QRCodeViewController alloc] init];
    qrVc.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qrVc];
    
    // 设置扫描完成后的回调
    __weak typeof (self) wSelf = self;
    [qrVc setCompletionWithBlock:^(NSString *resultAsString) {
        [wSelf.navigationController popViewControllerAnimated:YES];
//        [[[UIAlertView alloc] initWithTitle:@"扫描完成" message:resultAsString delegate:self cancelButtonTitle:@"好的" otherButtonTitles: nil] show];
    }];
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - 代理方法
- (void)reader:(QRCodeViewController *)reader didScanResult:(NSString *)result
{
    NSLog(@"%@",result);
    //创建 假的user_id 和 假的user_token 用于绑定  根据实际需求
    NSInteger user_id = 1;
    NSString *user_token = @"this_is_user_token";
    [self dismissViewControllerAnimated:YES completion:^{
        //请求服务端接口
        NSError *error;
        NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.103/qrcodelogin/bindqruuid.php?qruuid=%@&user_id=%ld&user_token=%@",result,(long)user_id,user_token];
        //加载一个NSURL对象
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        //将请求的url数据放到NSData对象中
        NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
        NSLog(@"接收到的数据为%@",jsonDic);
    }];
}



@end
