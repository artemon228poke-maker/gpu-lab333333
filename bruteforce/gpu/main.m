#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

static double get_time(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1000000000.0;
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        int length = argc > 1 ? atoi(argv[1]) : 4;

        if (length < 1 || length > 4) {
            printf("длина должна быть от 1 до 4\n");
            return 1;
        }

        // хэши для проверки разной длины
        const char *hashes[] = {
            "",
            "0cc175b9c0f1b6a831c399e269772661",
            "8a8bb7cd343aa2ad99b7d762030857a2",
            "30f5eef91a397e4bbab4d93aeb286aef",
            "f2e49af795161e14acf9d9245473a368"
        };

        unsigned char target[16];
        for (int i = 0; i < 16; i++) {
            unsigned int value;
            sscanf(hashes[length] + i * 2, "%2x", &value);
            target[i] = (unsigned char)value;
        }

        // получаем доступ к видеочипу
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        if (!device) {
            printf("устройство metal не найдено\n");
            return 1;
        }

        NSError *error = nil;
        NSString *source = [NSString
            stringWithContentsOfFile:@"bruteforce/gpu/md5.metal"
            encoding:NSUTF8StringEncoding error:&error];

        if (!source) {
            printf("не удалось открыть md5.metal\n");
            return 1;
        }

        // загружаем вычислительное ядро
        id<MTLLibrary> library =
            [device newLibraryWithSource:source options:nil error:&error];

        if (!library) {
            NSLog(@"ошибка компиляции metal: %@", error);
            return 1;
        }

        id<MTLFunction> function =
            [library newFunctionWithName:@"bruteforce_md5"];

        id<MTLComputePipelineState> pipeline =
            [device newComputePipelineStateWithFunction:function error:&error];

        if (!pipeline) {
            NSLog(@"ошибка создания pipeline: %@", error);
            return 1;
        }

        id<MTLCommandQueue> queue = [device newCommandQueue];

        // считаем количество возможных паролей
        uint32_t total = 1;
        for (int i = 0; i < length; i++) {
            total *= 36;
        }

        char found[10] = {0};
        int flag = 0;
        uint32_t len = (uint32_t)length;

        // создаем буферы для обмена данными
        id<MTLBuffer> b0 = [device newBufferWithBytes:target length:16 options:MTLResourceStorageModeShared];
        id<MTLBuffer> b1 = [device newBufferWithBytes:found length:10 options:MTLResourceStorageModeShared];
        id<MTLBuffer> b2 = [device newBufferWithBytes:&flag length:sizeof(flag) options:MTLResourceStorageModeShared];
        id<MTLBuffer> b3 = [device newBufferWithBytes:&len length:sizeof(len) options:MTLResourceStorageModeShared];

        if (!queue || !b0 || !b1 || !b2 || !b3) {
            printf("не удалось подготовить буферы metal\n");
            return 1;
        }

        // запускаем параллельный перебор
        double start = get_time();

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];

        [enc setComputePipelineState:pipeline];
        [enc setBuffer:b0 offset:0 atIndex:0];
        [enc setBuffer:b1 offset:0 atIndex:1];
        [enc setBuffer:b2 offset:0 atIndex:2];
        [enc setBuffer:b3 offset:0 atIndex:3];

        NSUInteger groupSize = MIN((NSUInteger)256, pipeline.maxTotalThreadsPerThreadgroup);
        MTLSize grid = MTLSizeMake(total, 1, 1);
        MTLSize group = MTLSizeMake(groupSize, 1, 1);

        [enc dispatchThreads:grid threadsPerThreadgroup:group];
        [enc endEncoding];

        [cmd commit];
        [cmd waitUntilCompleted];

        double elapsed = get_time() - start;

        if (cmd.status != MTLCommandBufferStatusCompleted) {
            NSLog(@"ошибка выполнения metal: %@", cmd.error);
            return 1;
        }

        int resultFlag = *(int *)[b2 contents];
        char *result = (char *)[b1 contents];

        if (resultFlag) {
            printf("GPU (Metal): password=%s threads=%u groups=%llu time=%.6f s\n",
                   result, total,
                   (unsigned long long)((total + groupSize - 1) / groupSize),
                   elapsed);
        } else {
            printf("совпадений нет\n");
        }

        return resultFlag ? 0 : 1;
    }
}
