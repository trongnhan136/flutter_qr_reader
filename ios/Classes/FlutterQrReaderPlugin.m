#import "FlutterQrReaderPlugin.h"
#import "QrReaderViewController.h"
#import <Vision/VNDetectBarcodesRequest.h>
#import <Vision/VNRequestHandler.h>
#import <Vision/VNObservation.h>

@implementation FlutterQrReaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    // 注册原生视图
    QrReaderViewFactory *viewFactory = [[QrReaderViewFactory alloc] initWithRegistrar:registrar];
    [registrar registerViewFactory:viewFactory withId:@"me.hetian.flutter_qr_reader.reader_view"];
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"me.hetian.flutter_qr_reader"
                                     binaryMessenger:[registrar messenger]];
    FlutterQrReaderPlugin* instance = [[FlutterQrReaderPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"imgQrCode" isEqualToString:call.method]) {
        [self scanQRCode:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)scanQRCode:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString *path = call.arguments[@"file"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (features.count > 0) {
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        NSString *qrData = feature.messageString;
        NSLog(@"TEST message photo: %@", qrData);
        result(qrData);
    } else {
        if (@available(iOS 11.0, *)) {
            VNImageRequestHandler *_handle = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];
            NSError *error;
            
            VNDetectBarcodesRequest *requests = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                if(!error) {
                    NSArray<VNBarcodeObservation *> *vnObservers = ( NSArray<VNBarcodeObservation *> *)request.results;
                    
                    if(vnObservers.count == 0) {
                        result(NULL);
                        return;
                    }
                    NSLog(@"TEST message photo: %@", vnObservers.firstObject.payloadStringValue);
                    result(vnObservers.firstObject.payloadStringValue);
                }
            }];
            requests.symbologies = @[VNBarcodeSymbologyCode128, VNBarcodeSymbologyQR];
            
            [_handle performRequests:@[requests] error:&error];
            
        } else {
            result(NULL);
        }
    }
}

@end
