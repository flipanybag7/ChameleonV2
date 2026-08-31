#import "CHDeviceCatalog.h"
#import <dispatch/dispatch.h>

NSArray<NSDictionary *> *CHDevicePresets(void) {
    static NSArray<NSDictionary *> *presets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        presets = @[
            @{ @"marketingName": @"iPhone 7", @"deviceModel": @"iPhone", @"machine": @"iPhone9,1", @"hardwareModel": @"D10AP", @"physicalMemoryGB": @2, @"screenWidth": @750, @"screenHeight": @1334, @"screenScale": @2, @"ppi": @326, @"minimumSystemMajor": @10 },
            @{ @"marketingName": @"iPhone 7 Plus", @"deviceModel": @"iPhone", @"machine": @"iPhone9,2", @"hardwareModel": @"D11AP", @"physicalMemoryGB": @3, @"screenWidth": @1080, @"screenHeight": @1920, @"screenScale": @3, @"ppi": @401, @"minimumSystemMajor": @10 },
            @{ @"marketingName": @"iPhone 8", @"deviceModel": @"iPhone", @"machine": @"iPhone10,1", @"hardwareModel": @"D20AP", @"physicalMemoryGB": @2, @"screenWidth": @750, @"screenHeight": @1334, @"screenScale": @2, @"ppi": @326, @"minimumSystemMajor": @11 },
            @{ @"marketingName": @"iPhone 8 Plus", @"deviceModel": @"iPhone", @"machine": @"iPhone10,2", @"hardwareModel": @"D21AP", @"physicalMemoryGB": @3, @"screenWidth": @1080, @"screenHeight": @1920, @"screenScale": @3, @"ppi": @401, @"minimumSystemMajor": @11 },
            @{ @"marketingName": @"iPhone X", @"deviceModel": @"iPhone", @"machine": @"iPhone10,3", @"hardwareModel": @"D22AP", @"physicalMemoryGB": @3, @"screenWidth": @1125, @"screenHeight": @2436, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @11 },
            @{ @"marketingName": @"iPhone XR", @"deviceModel": @"iPhone", @"machine": @"iPhone11,8", @"hardwareModel": @"N841AP", @"physicalMemoryGB": @3, @"screenWidth": @828, @"screenHeight": @1792, @"screenScale": @2, @"ppi": @326, @"minimumSystemMajor": @12 },
            @{ @"marketingName": @"iPhone XS", @"deviceModel": @"iPhone", @"machine": @"iPhone11,2", @"hardwareModel": @"D321AP", @"physicalMemoryGB": @4, @"screenWidth": @1125, @"screenHeight": @2436, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @12 },
            @{ @"marketingName": @"iPhone XS Max", @"deviceModel": @"iPhone", @"machine": @"iPhone11,6", @"hardwareModel": @"D331PAP", @"physicalMemoryGB": @4, @"screenWidth": @1242, @"screenHeight": @2688, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @12 },
            @{ @"marketingName": @"iPhone 11", @"deviceModel": @"iPhone", @"machine": @"iPhone12,1", @"hardwareModel": @"N104AP", @"physicalMemoryGB": @4, @"screenWidth": @828, @"screenHeight": @1792, @"screenScale": @2, @"ppi": @326, @"minimumSystemMajor": @13 },
            @{ @"marketingName": @"iPhone 11 Pro", @"deviceModel": @"iPhone", @"machine": @"iPhone12,3", @"hardwareModel": @"D421AP", @"physicalMemoryGB": @4, @"screenWidth": @1125, @"screenHeight": @2436, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @13 },
            @{ @"marketingName": @"iPhone 11 Pro Max", @"deviceModel": @"iPhone", @"machine": @"iPhone12,5", @"hardwareModel": @"D431AP", @"physicalMemoryGB": @4, @"screenWidth": @1242, @"screenHeight": @2688, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @13 },
            @{ @"marketingName": @"iPhone SE (2nd generation)", @"deviceModel": @"iPhone", @"machine": @"iPhone12,8", @"hardwareModel": @"D79AP", @"physicalMemoryGB": @3, @"screenWidth": @750, @"screenHeight": @1334, @"screenScale": @2, @"ppi": @326, @"minimumSystemMajor": @13 },
            @{ @"marketingName": @"iPhone 12 mini", @"deviceModel": @"iPhone", @"machine": @"iPhone13,1", @"hardwareModel": @"D52GAP", @"physicalMemoryGB": @4, @"screenWidth": @1080, @"screenHeight": @2340, @"screenScale": @3, @"ppi": @476, @"minimumSystemMajor": @14 },
            @{ @"marketingName": @"iPhone 12", @"deviceModel": @"iPhone", @"machine": @"iPhone13,2", @"hardwareModel": @"D53GAP", @"physicalMemoryGB": @4, @"screenWidth": @1170, @"screenHeight": @2532, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @14 },
            @{ @"marketingName": @"iPhone 12 Pro", @"deviceModel": @"iPhone", @"machine": @"iPhone13,3", @"hardwareModel": @"D53PAP", @"physicalMemoryGB": @6, @"screenWidth": @1170, @"screenHeight": @2532, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @14 },
            @{ @"marketingName": @"iPhone 12 Pro Max", @"deviceModel": @"iPhone", @"machine": @"iPhone13,4", @"hardwareModel": @"D54PAP", @"physicalMemoryGB": @6, @"screenWidth": @1284, @"screenHeight": @2778, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @14 },
            @{ @"marketingName": @"iPhone 13 mini", @"deviceModel": @"iPhone", @"machine": @"iPhone14,4", @"hardwareModel": @"D16AP", @"physicalMemoryGB": @4, @"screenWidth": @1080, @"screenHeight": @2340, @"screenScale": @3, @"ppi": @476, @"minimumSystemMajor": @15 },
            @{ @"marketingName": @"iPhone 13", @"deviceModel": @"iPhone", @"machine": @"iPhone14,5", @"hardwareModel": @"D17AP", @"physicalMemoryGB": @4, @"screenWidth": @1170, @"screenHeight": @2532, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @15 },
            @{ @"marketingName": @"iPhone 13 Pro", @"deviceModel": @"iPhone", @"machine": @"iPhone14,2", @"hardwareModel": @"D63AP", @"physicalMemoryGB": @6, @"screenWidth": @1170, @"screenHeight": @2532, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @15 },
            @{ @"marketingName": @"iPhone 13 Pro Max", @"deviceModel": @"iPhone", @"machine": @"iPhone14,3", @"hardwareModel": @"D64AP", @"physicalMemoryGB": @6, @"screenWidth": @1284, @"screenHeight": @2778, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @15 },
            @{ @"marketingName": @"iPhone SE (3rd generation)", @"deviceModel": @"iPhone", @"machine": @"iPhone14,6", @"hardwareModel": @"D49AP", @"physicalMemoryGB": @4, @"screenWidth": @750, @"screenHeight": @1334, @"screenScale": @2, @"ppi": @326, @"minimumSystemMajor": @15 },
            @{ @"marketingName": @"iPhone 14", @"deviceModel": @"iPhone", @"machine": @"iPhone14,7", @"hardwareModel": @"D27AP", @"physicalMemoryGB": @6, @"screenWidth": @1170, @"screenHeight": @2532, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @16 },
            @{ @"marketingName": @"iPhone 14 Plus", @"deviceModel": @"iPhone", @"machine": @"iPhone14,8", @"hardwareModel": @"D28AP", @"physicalMemoryGB": @6, @"screenWidth": @1284, @"screenHeight": @2778, @"screenScale": @3, @"ppi": @458, @"minimumSystemMajor": @16 },
            @{ @"marketingName": @"iPhone 14 Pro", @"deviceModel": @"iPhone", @"machine": @"iPhone15,2", @"hardwareModel": @"D73AP", @"physicalMemoryGB": @6, @"screenWidth": @1179, @"screenHeight": @2556, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @16 },
            @{ @"marketingName": @"iPhone 14 Pro Max", @"deviceModel": @"iPhone", @"machine": @"iPhone15,3", @"hardwareModel": @"D74AP", @"physicalMemoryGB": @6, @"screenWidth": @1290, @"screenHeight": @2796, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @16 },
            @{ @"marketingName": @"iPhone 15", @"deviceModel": @"iPhone", @"machine": @"iPhone15,4", @"hardwareModel": @"D37AP", @"physicalMemoryGB": @6, @"screenWidth": @1179, @"screenHeight": @2556, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @17 },
            @{ @"marketingName": @"iPhone 15 Plus", @"deviceModel": @"iPhone", @"machine": @"iPhone15,5", @"hardwareModel": @"D38AP", @"physicalMemoryGB": @6, @"screenWidth": @1290, @"screenHeight": @2796, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @17 },
            @{ @"marketingName": @"iPhone 15 Pro", @"deviceModel": @"iPhone", @"machine": @"iPhone16,1", @"hardwareModel": @"D83AP", @"physicalMemoryGB": @8, @"screenWidth": @1179, @"screenHeight": @2556, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @17 },
            @{ @"marketingName": @"iPhone 15 Pro Max", @"deviceModel": @"iPhone", @"machine": @"iPhone16,2", @"hardwareModel": @"D84AP", @"physicalMemoryGB": @8, @"screenWidth": @1290, @"screenHeight": @2796, @"screenScale": @3, @"ppi": @460, @"minimumSystemMajor": @17 }
        ];
    });
    return presets;
}
