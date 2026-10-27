#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <iostream>
#include <chrono>

int main() {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        NSError* error = nil;
        
        NSString* source = [NSString stringWithContentsOfFile:@"bruteforce/gpu/md5.metal" encoding:NSUTF8StringEncoding error:&error];
        if (error) { std::cout << "ошибка чтения ядра" << std::endl; return 1; }
        
        id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];
        id<MTLFunction> function = [library newFunctionWithName:@"bruteforce_md5"];
        id<MTLComputePipelineState> pipeline = [device newComputePipelineStateWithFunction:function error:&error];
        
        id<MTLCommandQueue> queue = [device newCommandQueue];
        
        int length = 4;
        long long total_threads = 36 * 36 * 36 * 36;
        
        unsigned char target[16] = {0xf2, 0xe4, 0x9a, 0xf7, 0x95, 0x16, 0x1e, 0x14, 0xac, 0xf9, 0xd9, 0x24, 0x54, 0x73, 0xa3, 0x68};
        char found[10] = {0};
        int is_found = 0;
        
        id<MTLBuffer> buf_target = [device newBufferWithBytes:target length:16 options:MTLResourceStorageModeShared];
        id<MTLBuffer> buf_found = [device newBufferWithBytes:found length:10 options:MTLResourceStorageModeShared];
        id<MTLBuffer> buf_flag = [device newBufferWithBytes:&is_found length:sizeof(int) options:MTLResourceStorageModeShared];
        id<MTLBuffer> buf_len = [device newBufferWithBytes:&length length:sizeof(int) options:MTLResourceStorageModeShared];
        
        auto start = std::chrono::high_resolution_clock::now();
        
        id<MTLCommandBuffer> commandBuffer = [queue commandBuffer];
        id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
        [encoder setComputePipelineState:pipeline];
        [encoder setBuffer:buf_target offset:0 atIndex:0];
        [encoder setBuffer:buf_found offset:0 atIndex:1];
        [encoder setBuffer:buf_flag offset:0 atIndex:2];
        [encoder setBuffer:buf_len offset:0 atIndex:3];
        
        MTLSize gridSize = MTLSizeMake(total_threads, 1, 1);
        MTLSize threadgroupSize = MTLSizeMake(1024, 1, 1);
        
        [encoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
        [encoder endEncoding];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        
        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> diff = end - start;
        
        char* res = (char*)[buf_found contents];
        std::cout << "пароль найден: " << res << std::endl;
        std::cout << "время на gpu: " << diff.count() << " сек" << std::endl;
    }
    return 0;
}
