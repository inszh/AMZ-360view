//
//  ViewController.m
//  AMZ 360view
//
//  Created by 小雨 on 2023/10/15.
//  Copyright © 2023 小雨. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>


@interface ViewController ()<AVCapturePhotoCaptureDelegate,UITextFieldDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger photoCount; // 用于计数已拍摄的照片数量
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) NSString *filenameText;
@property (nonatomic) CGFloat currentZoomFactor;
@property (nonatomic, strong) UILabel *zoomLabel;
@property (nonatomic, strong) UIButton *zoomInButton;
@property (nonatomic, strong) UIButton *zoomOutButton;
@property (nonatomic, strong) UITextField *filenameTextField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupView];
}


-(void)setupView
{
   self.photoCount = 0;
    
    // 创建预览图层
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    
    // 初始化摄像头设备1
     self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    
    if (input) {
        if ([self.captureSession canAddInput:input]) {
            [self.captureSession addInput:input];
            
            self.photoOutput = [[AVCapturePhotoOutput alloc] init];
            if ([self.captureSession canAddOutput:self.photoOutput]) {
                [self.captureSession addOutput:self.photoOutput];
                
                self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
                self.previewLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height -80);
                [self.view.layer addSublayer:self.previewLayer];
                
                [self.captureSession startRunning];
                
            }
        }
        [self.view.layer addSublayer:self.previewLayer];
        

    } else {
        NSLog(@"无法访问摄像头：%@", error.localizedDescription);
    }
    
    UITextField *filenameTextField = [[UITextField alloc] init];
    self.filenameTextField=filenameTextField;
    filenameTextField.borderStyle = UITextBorderStyleRoundedRect;
    filenameTextField.placeholder = @"输入B0开头的10位ASIN开始";
    filenameTextField.translatesAutoresizingMaskIntoConstraints = NO; // 确保关闭自动布局
    [self.view addSubview:filenameTextField];
    filenameTextField.delegate = self;


    // 创建水平居中的约束
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:filenameTextField
                                                                      attribute:NSLayoutAttributeCenterX
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeCenterX
                                                                     multiplier:1.0
                                                                       constant:0.0];

    // 创建Y值为10的约束
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:filenameTextField
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0
                                                                    constant:44];
    
  // 创建宽度为屏幕一半的约束
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:filenameTextField
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:0.8
                                                                      constant:0.0];
    // 添加约束到视图
    [self.view addConstraint:centerXConstraint];
    [self.view addConstraint:topConstraint];
    [self.view addConstraint:widthConstraint];
    
    
     //创建进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(50, CGRectGetMaxY(self.previewLayer.frame)+ 5, self.view.frame.size.width * 0.75, 30);
    self.progressView.center = CGPointMake(self.view.center.x, CGRectGetMaxY(self.previewLayer.frame));

    self.progressView.progress = 0.0;
    [self.view addSubview:self.progressView];
    
    // 创建开始按钮
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.frame = CGRectMake(0, 0, 100, 50);
    self.startButton.center = CGPointMake(self.view.center.x - 50 , CGRectGetMaxY(self.progressView.frame) + 35);
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startTakingPhotos) forControlEvents:UIControlEventTouchUpInside];

    self.resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.resetButton.frame = CGRectMake(CGRectGetMaxX(self.startButton.frame)  + 10 , self.startButton.frame.origin.y, 100, 50);
    [self.resetButton setTitle:@"重置" forState:UIControlStateNormal];
    [self.resetButton addTarget:self action:@selector(startReset) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置按钮圆角为2
    self.resetButton.layer.cornerRadius = self.startButton.layer.cornerRadius = 2.0;

    [self.startButton setBackgroundColor:[UIColor lightGrayColor]];
    self.startButton.enabled=NO;
    [self.startButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.resetButton setBackgroundColor:[UIColor lightGrayColor]];
    self.resetButton.enabled=NO;
    [self.resetButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.view addSubview:self.startButton];
    [self.view addSubview:self.resetButton];

    


    // 创建显示缩放级别的标签
    self.zoomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)]; // 调整宽度
    self.zoomLabel.text = @"1.0x";
    self.zoomLabel.textAlignment = NSTextAlignmentCenter; // 设置文字居中
    self.zoomLabel.layer.cornerRadius = 2.0;
    self.zoomLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    self.zoomLabel.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.zoomLabel.frame) / 2 - 20, CGRectGetHeight(self.view.frame) / 2);
    [self.view addSubview:self.zoomLabel];
    
    
    // 创建缩放放大按钮
    self.zoomInButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.zoomInButton setTitle:@"放大" forState:UIControlStateNormal];
    [self.zoomInButton addTarget:self action:@selector(zoomIn) forControlEvents:UIControlEventTouchUpInside];
    [self.zoomInButton sizeToFit];
    CGFloat buttonWidth = 60; // 设置为所需的宽度

    // 更新 zoomInButton 的宽度
    self.zoomInButton.frame = CGRectMake(0, 0, buttonWidth, 30);

    self.zoomInButton.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.zoomInButton.frame) / 2 - 20, CGRectGetMaxY(self.zoomLabel.frame) + 20);
    // 设置按钮圆角为2
    self.zoomInButton.layer.cornerRadius = 2.0;
    
    UIColor *customBlueColor = [UIColor colorWithRed:85/255.0 green:150/255.0 blue:243/255.0 alpha:1.0];

    [self.zoomInButton setBackgroundColor:customBlueColor];

    // 设置字体颜色为白色
    [self.zoomInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.zoomInButton];
    
    // 创建缩放缩小按钮
    self.zoomOutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.zoomOutButton setTitle:@"缩小" forState:UIControlStateNormal];
    [self.zoomOutButton addTarget:self action:@selector(zoomOut) forControlEvents:UIControlEventTouchUpInside];
    [self.zoomOutButton sizeToFit];
    
    // 更新 zoomOutButton 的宽度
    self.zoomOutButton.frame = CGRectMake(0, 0, buttonWidth, 30);
    self.zoomOutButton.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.zoomOutButton.frame) / 2 - 20, CGRectGetMaxY(self.zoomInButton.frame) + 20);
    // 设置按钮圆角为2
    self.zoomOutButton.layer.cornerRadius = 2.0;

    [self.zoomOutButton setBackgroundColor:customBlueColor];

    // 设置字体颜色为白色
    [self.zoomOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.zoomOutButton];
    
    
    // 创建增加曝光按钮
    UIButton *increaseExposureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    increaseExposureButton.frame = CGRectMake(0, 0, buttonWidth, 30);
    increaseExposureButton.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.zoomOutButton.frame) / 2 - 20, CGRectGetMaxY(self.zoomOutButton.frame) + 20);
    [increaseExposureButton setBackgroundColor:[UIColor colorWithRed:85/255.0 green:150/255.0 blue:243/255.0 alpha:1.0]];
    [increaseExposureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [increaseExposureButton setTitle:@"增曝" forState:UIControlStateNormal];
    [increaseExposureButton addTarget:self action:@selector(increaseExposure) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:increaseExposureButton];

    // 创建减小曝光按钮
    UIButton *decreaseExposureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    decreaseExposureButton.frame = CGRectMake(0, 0, buttonWidth, 30);
    decreaseExposureButton.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.zoomOutButton.frame) / 2 - 20, CGRectGetMaxY(increaseExposureButton.frame) + 20);
    [decreaseExposureButton setBackgroundColor:[UIColor colorWithRed:85/255.0 green:150/255.0 blue:243/255.0 alpha:1.0]];
    [decreaseExposureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [decreaseExposureButton setTitle:@"减曝" forState:UIControlStateNormal];
    [decreaseExposureButton addTarget:self action:@selector(decreaseExposure) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:decreaseExposureButton];
    
    
    // 初始化当前缩放级别
    self.currentZoomFactor = 1.0;
    
    // 检查设备是否支持缩放
    if (self.captureDevice.isRampingVideoZoom) {
        [self.captureDevice lockForConfiguration:nil];
        self.captureDevice.videoZoomFactor = self.currentZoomFactor;
        [self.captureDevice unlockForConfiguration];
    }
            
}


// 初始化摄像头并开始拍照
- (void)startTakingPhotos
{
    
    self.filenameTextField.userInteractionEnabled = NO;
    // 创建一个串行队列
    dispatch_queue_t queue = dispatch_queue_create("com.example.photoqueue", NULL);
    
    // 创建定时器
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 设置定时器的开始时间、间隔和精度
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 0);
    uint64_t interval = (uint64_t)(1.11 * NSEC_PER_SEC);
    uint64_t leeway = 0; // 定时器允许的误差范围（纳秒）
    
    // 设置定时器的触发时间和间隔
    dispatch_source_set_timer(self.timer, startTime, interval, leeway);
    
    // 设置定时器的触发事件
    dispatch_source_set_event_handler(self.timer, ^{
        [self takePhoto];
    });

    // 启动定时器
    dispatch_resume(self.timer);
    
    [self.startButton setTitle:@"拍摄中" forState:UIControlStateNormal];
    self.resetButton.enabled = self.startButton.enabled = NO;
    [self.startButton setBackgroundColor:[UIColor lightGrayColor]];
    [self.resetButton setBackgroundColor:[UIColor lightGrayColor]];

}




// 拍照
- (void)takePhoto {

    NSString *str = nil;

    if (self.photoCount >= 36 || str==self.filenameText ){
        // 所有照片已经拍摄完成，停止拍摄
        dispatch_source_cancel(self.timer);
        self.timer = nil;
        [self.captureSession stopRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
        [self.startButton setTitle:@"完成" forState:UIControlStateNormal];
        self.startButton.enabled = NO;
        [self.startButton setBackgroundColor:[UIColor lightGrayColor]];
        self.resetButton.enabled = YES;
        [self.resetButton setBackgroundColor:[UIColor colorWithRed:85/255.0 green:150/255.0 blue:243/255.0 alpha:1.0]];

        });
        
        return;
        
    }else{

        AVCapturePhotoSettings *photoSettings = [[AVCapturePhotoSettings alloc] init];
        [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
        
    }
    
    self.photoCount++;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = (CGFloat)self.photoCount / 36.0;
        [self.progressView setProgress:progress animated:YES];
    });

}


- (void)startReset
{
    
    self.photoCount = 0;
    
    self.filenameTextField.text = @"";
    
    self.progressView.progress = 0.0;
    
    self.resetButton.enabled = self.startButton.enabled = NO;
    
    [self.startButton setBackgroundColor:[UIColor lightGrayColor]];
    
    [self.resetButton setBackgroundColor:[UIColor lightGrayColor]];
    
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];

    self.filenameTextField.userInteractionEnabled = YES;
    
    [self.captureSession startRunning];


}



// 保存照片到相册
- (void)savePhotoToAlbum:(UIImage *)image
{

    int photoCount=(int)self.photoCount-1;
    NSString *filename = [NSString stringWithFormat:@"%@_360_%.4d_web.png",self.filenameText,photoCount];
    // 获取当前应用的沙盒目录路径
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];

    // 将图片保存到沙盒目录中
    NSData *imageData = UIImagePNGRepresentation(image);
    BOOL success = [imageData writeToFile:filePath atomically:YES];

    if (success) {
        // 使用PHPhotoLibrary将图片添加到相册中
        PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary performChanges:^{
            PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:filePath]];
            assetChangeRequest.creationDate = [NSDate date];
            assetChangeRequest.location = nil;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"照片保存成功");
            } else {
                NSLog(@"照片保存失败：%@", error.localizedDescription);
            }
        }];
    } else {
        NSLog(@"图片保存到沙盒目录失败");
    }

}


#pragma mark - UIGestureRecognizerDelegate

- (void)zoomIn {
    self.currentZoomFactor += 0.1; // 增加缩放因子
    [self updateZoom];
}

- (void)zoomOut {
    self.currentZoomFactor -= 0.1; // 减小缩放因子
    [self updateZoom];
}

- (void)updateZoom {

    // 限制缩放因子在有效范围内
    self.currentZoomFactor = MAX(1.0, MIN(self.currentZoomFactor, self.captureDevice.activeFormat.videoMaxZoomFactor));
    
    [self.captureDevice lockForConfiguration:nil];
    self.captureDevice.videoZoomFactor = self.currentZoomFactor;
    [self.captureDevice unlockForConfiguration];
    
    self.zoomLabel.text = [NSString stringWithFormat:@"%.1fx", self.currentZoomFactor];

}


- (void)increaseExposure {
    [self adjustExposureWithBias:0.5]; // 增加曝光
}

- (void)decreaseExposure {
    [self adjustExposureWithBias:-0.5]; // 减小曝光
}

- (void)adjustExposureWithBias:(float)bias {
    NSError *error = nil;
       
    if ([self.captureDevice lockForConfiguration:&error]) {
            float currentBias = self.captureDevice.exposureTargetBias;
            float newBias = currentBias + bias;
            // 设置曝光目标偏差
            [self.captureDevice setExposureTargetBias:newBias completionHandler:nil];
        [self.captureDevice unlockForConfiguration];
        
    } else {
        NSLog(@"无法锁定设备配置：%@", error.localizedDescription);
    }
}




#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"拍照错误：%@", error.localizedDescription);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *image = [UIImage imageWithData:photo.fileDataRepresentation];
        [self savePhotoToAlbum:image];
        
        NSLog(@"AVCapturePhotoCaptureDelegate当前线程：%s", dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
  });
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.filenameText = textField.text;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // 允许的字符集（英文和数字）
    
    NSMutableString * changedString=[[NSMutableString alloc]initWithString:textField.text];

    [changedString replaceCharactersInRange:range withString:string];

    
    if (changedString.length>9 ) {

        [self.startButton setBackgroundColor:[UIColor colorWithRed:85/255.0 green:150/255.0 blue:243/255.0 alpha:1.0] ];
        self.startButton.enabled=YES;
               
    }else{

        // filenameTextField 不为空
        [self.startButton setBackgroundColor:[UIColor lightGrayColor]];
        [self.resetButton setBackgroundColor:[UIColor lightGrayColor]];

        self.resetButton.enabled=self.startButton.enabled=NO;
    }
    
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"] invertedSet];
    
    // 检查新输入的字符是否在允许的字符集内
    NSRange characterRange = [string rangeOfCharacterFromSet:allowedCharacters];
    
    if (characterRange.location != NSNotFound || changedString.length > 10) {
        // 输入字符不在允许的字符集内，拒绝输入
        return NO;
        
    } else {
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:[string uppercaseString]];
        
        return NO; // 返回NO，表示不允许textField处理输入
    }
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];

}

@end
