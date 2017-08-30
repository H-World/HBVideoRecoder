//
//  ViewController.m
//  HBVideoRecoder
//
//  Created by 王寒标 on 2017/8/28.
//  Copyright © 2017年 王寒标. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutPut;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController

#define SystemVersion _SystemVersion()

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeCamera];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if (self.movieOutPut.isRecording) {
        
        [self.movieOutPut stopRecording];
        return;
    }
    
    AVCaptureConnection *connection = [self.movieOutPut connectionWithMediaType:AVMediaTypeVideo];
    if (connection.active && connection.enabled) {
        
        //防抖模式
        AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        if ([self.videoInput.device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
            [connection setPreferredVideoStabilizationMode:stabilizationMode];
        }
        // 预览图层和视频方向保持一致,这个属性设置很重要，如果不设置，那么出来的视频图像可以是倒向左边的。
        connection.videoOrientation = self.previewLayer.connection.videoOrientation;
        // 设置视频输出的文件路径，这里设置为 temp 文件
        NSString *outputFielPath = [NSTemporaryDirectory() stringByAppendingString:@"111.mov"];
        
        // 路径转换成 URL 要用这个方法，用 NSBundle 方法转换成 URL 的话可能会出现读取不到路径的错误
        NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
        
        // 往路径的 URL 开始写入录像 Buffer ,边录边写
        [self.movieOutPut startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    } else {
        
        NSLog(@"No active/enabled connections");
    }
}

#pragma mark - initialize
- (void)initializeCamera {
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        
        [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    AVCaptureDevice *videoCaptureDevice = [self getCameraCaptureDevice:AVCaptureDevicePositionBack];
    NSError *error;
    if (videoCaptureDevice == nil) {
        
        NSLog(@"获取摄像头出错");
    }
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    if (error) {
        NSLog(@"获取摄像头出错1");
    }
    
    AVCaptureDevice *audioCaptureDevice = [self getAudioCaptureDevice];
    if (audioCaptureDevice == nil) {
        NSLog(@"获取音频设备出错");
    }
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"获取音频设备出错1");
    }
    
    self.movieOutPut = [[AVCaptureMovieFileOutput alloc] init];
    
//    [self.captureSession beginConfiguration];
    // 将视频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    
    // 将音频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.audioInput]) {
        [self.captureSession addInput:self.audioInput];
    }
    
    if ([self.captureSession canAddOutput:self.movieOutPut]) {
        [self.captureSession addOutput:self.movieOutPut];
    }
    
//    [self.captureSession commitConfiguration];
    
    // 让会话（AVCaptureSession）勾搭好输入输出，然后把视图渲染到预览层上
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    // 显示在视图表面的图层
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    [self.view.layer addSublayer:self.previewLayer];
    [self.captureSession startRunning];
}

#pragma mark - delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    
    NSLog(@"开始录制");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    NSLog(@"录制结束");
}

#pragma mark - lazyloading
- (AVCaptureSession *)captureSession {
    
    if (!_captureSession) {
        
        _captureSession = [[AVCaptureSession alloc] init];
    }
    
    return _captureSession;
}

- (AVCaptureDevice *)getCameraCaptureDevice:(AVCaptureDevicePosition)position {
    
#if __IPHONE_10_0
    AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray *devices = session.devices;
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            
            return device;
        }
    }
    return nil;
#else
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            
            return device;
        }
    }
    return nil;
#endif
}

- (AVCaptureDevice *)getAudioCaptureDevice {
    
#if __IPHONE_10_0
    AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified];
    NSArray *devices = session.devices;
    for (AVCaptureDevice *device in devices) {
        if (device.deviceType == AVCaptureDeviceTypeBuiltInMicrophone) {
            
            return device;
        }
    }
    return nil;
#else
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            
            return device;
        }
    }
    return nil;
#endif
}

@end
