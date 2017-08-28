//
//  ViewController.m
//  HBVideoRecoder
//
//  Created by 王寒标 on 2017/8/28.
//  Copyright © 2017年 王寒标. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureInput *videoInput;
@property (nonatomic, strong) AVCaptureInput *audioInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutPut;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController

#define SystemVersion _SystemVersion()

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    // 将视频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    
    // 将音频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.audioInput]) {
        [self.captureSession addInput:self.audioInput];
        AVCaptureConnection *captureConnection = [self.movieOutPut connectionWithMediaType:AVMediaTypeVideo];
        // 标识视频录入时稳定音频流的接受，我们这里设置为自动
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    // 让会话（AVCaptureSession）勾搭好输入输出，然后把视图渲染到预览层上
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    // 显示在视图表面的图层
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    [self.view.layer addSublayer:self.previewLayer];
}

- (AVCaptureSession *)captureSession {
    
    if (!_captureSession) {
        
        _captureSession = [[AVCaptureSession alloc] init];
    }
    
    return _captureSession;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if (self.captureSession.running) {
        
        [self.captureSession stopRunning];
    } else {
        
        [self.captureSession startRunning];
    }
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
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            
            return device;
        }
    }
    return nil;
#endif
}

@end
