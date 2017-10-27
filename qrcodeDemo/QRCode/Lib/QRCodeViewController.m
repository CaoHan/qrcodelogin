//
//  QRCodeViewController.m
//  QRCode
//
//  Created by 王聪 on 16/5/22.
//  Copyright © 2016年 王聪. All rights reserved.
//

#import "QRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface QRCodeViewController () <UITabBarDelegate,AVCaptureMetadataOutputObjectsDelegate>

// 显示扫描后的结果
@property (weak, nonatomic) IBOutlet UILabel *resultLab;

// 高度约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeightCons;

// 扫描线
@property (weak, nonatomic) IBOutlet UIImageView *scanLineView;

// 扫描线的约束，这里很重要，动画效果主要是根据设置这个的值实现的
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanLineCons;

// 自定义ToolBar
@property (weak, nonatomic) IBOutlet UITabBar *customTabBar;

// 会话
@property (nonatomic, strong) AVCaptureSession *session;

// 输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;

// 输出设备
@property (nonatomic, strong) AVCaptureMetadataOutput *output;

// 预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

// 会话图层
@property (nonatomic, strong) CALayer *drawLayer;


// 扫描完成回调block
@property (copy, nonatomic) void (^completionBlock) (NSString *);

// 音频播放
@property (strong, nonatomic) AVAudioPlayer        *beepPlayer;

@end

@implementation QRCodeViewController

#pragma mark - 懒加载
// 会话
- (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}
// 拿到输入设备
- (AVCaptureDeviceInput *)deviceInput
{
    if (_deviceInput == nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        _deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    }
    return _deviceInput;
}
// 拿到输出对象
- (AVCaptureMetadataOutput *)output
{
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc] init];
    }
    return _output;
}
// 创建预览图层
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.frame = [UIScreen mainScreen].bounds;
    }
    return _previewLayer;
}
// 创建用于绘制边线的图层
- (CALayer *)drawLayer
{
    if (_drawLayer == nil) {
        _drawLayer = [[CALayer alloc] init];
        _drawLayer.frame = [UIScreen mainScreen].bounds;
    }
    return _drawLayer;
}

- (AVAudioPlayer *)beepPlayer
{
    if (_beepPlayer == nil) {
        NSString * wavPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
        NSData* data = [[NSData alloc] initWithContentsOfFile:wavPath];
        _beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
    }
    return _beepPlayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.customTabBar.selectedItem = self.customTabBar.items[0];
    self.customTabBar.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startAnimation];
    
    [self startScan];
    
    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] setAlpha:0];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

#pragma mark - Managing the Block

- (void)setCompletionWithBlock:(void (^) (NSString *resultAsString))completionBlock
{
    self.completionBlock = completionBlock;
}


#pragma 扫描过程
- (void)startScan
{
    // 1.判断是否能够将输入添加到会话中
    if (![self.session canAddInput:self.deviceInput]) {
        return;
    }
    
    // 2.判断是否能够将输出添加到会话中
    if (![self.session canAddOutput:self.output]) {
        return;
    }
    
    // 3.将输入和输出都添加到会话中
    [self.session addInput:self.deviceInput];
    
    [self.session addOutput:self.output];
    
    // 4.设置输出能够解析的数据类型
    // 注意: 设置能够解析的数据类型, 一定要在输出对象添加到会员之后设置, 否则会报错
    self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes;
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 如果想实现只扫描一张图片, 那么系统自带的二维码扫描是不支持的
    // 只能设置让二维码只有出现在某一块区域才去扫描
//    self.output.rectOfInterest = CGRectMake(0.0, 0.0, 1, 1);
    
    // 设置二维码区域参开http://www.tuicool.com/articles/6jUjmur
    CGFloat ScreenHigh = [UIScreen mainScreen].bounds.size.height;
    CGFloat ScreenWidth = [UIScreen mainScreen].bounds.size.width;
    [self.output setRectOfInterest : CGRectMake (( 160 )/ ScreenHigh ,(( ScreenWidth - 300 )/ 2 )/ ScreenWidth , 300 / ScreenHigh , 300 / ScreenWidth)];
    
    // 5.添加预览图层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    // 添加绘制图层
    [self.previewLayer addSublayer:self.drawLayer];
    
    // 6.告诉session开始扫描
    [self.session startRunning];
}

- (void)stopScan
{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }

    [self stopAnimation];
}


- (void)startAnimation
{
    // 让约束从顶部开始
    self.scanLineCons.constant = 0;
    [self.view layoutIfNeeded];

    // 设置动画指定的次数

    [UIView animateWithDuration:2.0 animations:^{
        // 1.修改约束
        self.scanLineCons.constant = self.containerHeightCons.constant;
        
        [UIView setAnimationRepeatCount:MAXFLOAT];
        
        // 2.强制更新界面
        [self.view layoutIfNeeded];
    }];
}

// 停止动画
- (void)stopAnimation
{
    [self.view.layer removeAllAnimations];
}

/**
 *  当从二维码中获取到信息时，就会调用下面的方法
 *
 *  @param captureOutput   输出对象
 *  @param metadataObjects 信息
 *  @param connection
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 0.清空图层
    [self clearCorners];
    
    if (metadataObjects.count == 0 || metadataObjects == nil) {
        return;
    }
    
    
    // 1.获取扫描到的数据
    // 注意: 要使用stringValue

    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects lastObject];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode] && [metadataObj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            self.resultLab.text = [metadataObjects.lastObject stringValue];
            [self.resultLab sizeToFit];
            
            // 扫描结果
            NSString *result = [metadataObjects.lastObject stringValue];
            
            // 停止扫描
            [self stopScan];
            
            if (_completionBlock) {
                [self.beepPlayer play];
                _completionBlock(result);
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(reader:didScanResult:)]) {
                [self.delegate reader:self didScanResult:result];
            }
            return;
        }
    }

    
    // 2.获取扫描到的二维码的位置
    // 2.1转换坐标
    for (AVMetadataObject *object in metadataObjects) {
        // 2.1.1判断当前获取到的数据, 是否是机器可识别的类型
        if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            // 2.1.2将坐标转换界面可识别的坐标
            AVMetadataMachineReadableCodeObject *codeObject = (AVMetadataMachineReadableCodeObject *)[self.previewLayer transformedMetadataObjectForMetadataObject:object];
            // 2.1.3绘制图形
            [self drawCorners:codeObject];
        }
    }
}


/**
 *  画出二维码的边框
 *
 *  @param codeObject 保存了坐标的对象
 */
- (void)drawCorners:(AVMetadataMachineReadableCodeObject *)codeObject
{
    if (codeObject.corners.count == 0) {
        return;
    }
    
    // 1.创建一个图层
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.lineWidth = 4;
    layer.strokeColor = [UIColor redColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    
    // 2.创建路径
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint point = CGPointZero;
    NSInteger index = 0;
    
    // 2.1移动到第一个点
    // 从corners数组中取出第0个元素, 将这个字典中的x/y赋值给point
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)codeObject.corners[index++], &point);
    [path moveToPoint:point];
    
    // 2.2移动到其它的点
    while (index < codeObject.corners.count) {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)codeObject.corners[index++], &point);
        [path addLineToPoint:point];
    }
    // 2.3关闭路径
    [path closePath];
    
    // 2.4绘制路径
    layer.path = path.CGPath;
    
    // 3.将绘制好的图层添加到drawLayer上
    [self.drawLayer addSublayer:layer];
}

/**
 *  清除边线
 */
- (void)clearCorners
{
    if (self.drawLayer.sublayers == nil || self.drawLayer.sublayers.count == 0) {
        return;
    }
    
    for (CALayer *subLayer in self.drawLayer.sublayers) {
        [subLayer removeFromSuperlayer];
    }
}


/**
 *  选择tabBar时进行跳转
 *
 *  @param tabBar tabbar
 *  @param item   tabBar的item
 */
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.tag == 1) {
        self.containerHeightCons.constant = 300;
    } else {
        self.containerHeightCons.constant = 150;
    }
    
    // 2.停止动画
    [self.view.layer removeAllAnimations];
    [self.scanLineView.layer removeAllAnimations];
    
    // 3.重新开始动画
    [self startAnimation];
}

- (void)back
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
