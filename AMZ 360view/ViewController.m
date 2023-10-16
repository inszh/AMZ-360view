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
@property (nonatomic, strong) NSString *filenameText;

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

    
    AVCaptureDevice *backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    
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
    
    

     //创建进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(50, CGRectGetMaxY(self.previewLayer.frame)+5, self.view.frame.size.width - 100, 30);
    self.progressView.progress = 0.0;
    [self.view addSubview:self.progressView];

    // 创建开始按钮
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.startButton.frame = CGRectMake(0, 0, 100, 50);
    self.startButton.center = CGPointMake(self.view.center.x, CGRectGetMaxY(self.progressView.frame) + 50);
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    [self.startButton addTarget:self action:@selector(startTakingPhotos) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
    
    UITextField *filenameTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 40)];
    filenameTextField.borderStyle = UITextBorderStyleRoundedRect;
    filenameTextField.placeholder = @"请输入ASIN";
    filenameTextField.delegate = self;
    [self.view addSubview:filenameTextField];
        
}


// 初始化摄像头并开始拍照
- (void)startTakingPhotos
{
    
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
        [self.startButton setTitle:@"拍摄中" forState:UIControlStateNormal];
        self.startButton.enabled = NO;
    });

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

- (void)textFieldDidEndEditing:(UITextField *)textField{
    self.filenameText = textField.text;
        
}

@end
