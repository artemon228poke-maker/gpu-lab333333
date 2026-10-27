#ifndef MD5_H
#define MD5_H

#include <string>
#include <cstring>
#include <cstdint>
#include <cstdio>

// базовая реализация md5, чтобы не подключать левые библиотеки
// код взят из открытых источников, просто чтобы работало
std::string md5(const std::string &str) {
    uint32_t h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE, h3 = 0x10325476;
    uint64_t bit_len = str.length() * 8;
    std::string msg = str;
    msg += (char)0x80;
    while (msg.length() % 64 != 56) msg += (char)0x00;
    
    for (int i = 0; i < 8; i++) msg += (char)((bit_len >> (i * 8)) & 0xFF);

    for (size_t i = 0; i < msg.length(); i += 64) {
        uint32_t w[16];
        for (int j = 0; j < 16; j++) {
            w[j] = (uint8_t)msg[i + j * 4] | 
                   ((uint8_t)msg[i + j * 4 + 1] << 8) |
                   ((uint8_t)msg[i + j * 4 + 2] << 16) |
                   ((uint8_t)msg[i + j * 4 + 3] << 24);
        }
        uint32_t a = h0, b = h1, c = h2, d = h3;
        // раунды md5 (стандартные сдвиги)
        auto f = [](uint32_t x, uint32_t y, uint32_t z) { return (x & y) | (~x & z); };
        auto g = [](uint32_t x, uint32_t y, uint32_t z) { return (x & z) | (y & ~z); };
        auto h = [](uint32_t x, uint32_t y, uint32_t z) { return x ^ y ^ z; };
        auto i_func = [](uint32_t x, uint32_t y, uint32_t z) { return y ^ (x | ~z); };
        
        auto left_rotate = [](uint32_t x, uint32_t c) { return (x << c) | (x >> (32 - c)); };

        // (тут макросы для раундов, чтобы не писать 64 строки)
        #define FF(a, b, c, d, x, s, ac) { a += f(b, c, d) + x + ac; a = left_rotate(a, s); a += b; }
        #define GG(a, b, c, d, x, s, ac) { a += g(b, c, d) + x + ac; a = left_rotate(a, s); a += b; }
        #define HH(a, b, c, d, x, s, ac) { a += h(b, c, d) + x + ac; a = left_rotate(a, s); a += b; }
        #define II(a, b, c, d, x, s, ac) { a += i_func(b, c, d) + x + ac; a = left_rotate(a, s); a += b; }

        // 1 раунд
        FF(a, b, c, d, w[0], 7, 0xd76aa478); FF(d, a, b, c, w[1], 12, 0xe8c7b756);
        FF(c, d, a, b, w[2], 17, 0x242070db); FF(b, c, d, a, w[3], 22, 0xc1bdceee);
        FF(a, b, c, d, w[4], 7, 0xf57c0faf); FF(d, a, b, c, w[5], 12, 0x4787c62a);
        FF(c, d, a, b, w[6], 17, 0xa8304613); FF(b, c, d, a, w[7], 22, 0xfd469501);
        FF(a, b, c, d, w[8], 7, 0x698098d8); FF(d, a, b, c, w[9], 12, 0x8b44f7af);
        FF(c, d, a, b, w[10], 17, 0xffff5bb1); FF(b, c, d, a, w[11], 22, 0x895cd7be);
        FF(a, b, c, d, w[12], 7, 0x6b901122); FF(d, a, b, c, w[13], 12, 0xfd987193);
        FF(c, d, a, b, w[14], 17, 0xa679438e); FF(b, c, d, a, w[15], 22, 0x49b40821);

        // 2 раунд
        GG(a, b, c, d, w[1], 5, 0xf61e2562); GG(d, a, b, c, w[6], 9, 0xc040b340);
        GG(c, d, a, b, w[11], 14, 0x265e5a51); GG(b, c, d, a, w[0], 20, 0xe9b6c7aa);
        GG(a, b, c, d, w[5], 5, 0xd62f105d); GG(d, a, b, c, w[10], 9, 0x02441453);
        GG(c, d, a, b, w[15], 14, 0xd8a1e681); GG(b, c, d, a, w[4], 20, 0xe7d3fbc8);
        GG(a, b, c, d, w[9], 5, 0x21e1cde6); GG(d, a, b, c, w[14], 9, 0xc33707d6);
        GG(c, d, a, b, w[3], 14, 0xf4d50d87); GG(b, c, d, a, w[8], 20, 0x455a14ed);
        GG(a, b, c, d, w[13], 5, 0xa9e3e905); GG(d, a, b, c, w[2], 9, 0xfcefa3f8);
        GG(c, d, a, b, w[7], 14, 0x676f02d9); GG(b, c, d, a, w[12], 20, 0x8d2a4c8a);

        // 3 раунд
        HH(a, b, c, d, w[5], 4, 0xfffa3942); HH(d, a, b, c, w[8], 11, 0x8771f681);
        HH(c, d, a, b, w[11], 16, 0x6d9d6122); HH(b, c, d, a, w[14], 23, 0xfde5380c);
        HH(a, b, c, d, w[1], 4, 0xa4beea44); HH(d, a, b, c, w[4], 11, 0x4bdecfa9);
        HH(c, d, a, b, w[7], 16, 0xf6bb4b60); HH(b, c, d, a, w[10], 23, 0xbebfbc70);
        HH(a, b, c, d, w[13], 4, 0x289b7ec6); HH(d, a, b, c, w[0], 11, 0xeaa127fa);
        HH(c, d, a, b, w[3], 16, 0xd4ef3085); HH(b, c, d, a, w[6], 23, 0x04881d05);
        HH(a, b, c, d, w[9], 4, 0xd9d4d039); HH(d, a, b, c, w[12], 11, 0xe6db99e5);
        HH(c, d, a, b, w[15], 16, 0x1fa27cf8); HH(b, c, d, a, w[2], 23, 0xc4ac5665);

        // 4 раунд
        II(a, b, c, d, w[0], 6, 0xf4292244); II(d, a, b, c, w[7], 10, 0x432aff97);
        II(c, d, a, b, w[14], 15, 0xab9423a7); II(b, c, d, a, w[5], 21, 0xfc93a039);
        II(a, b, c, d, w[12], 6, 0x655b59c3); II(d, a, b, c, w[3], 10, 0x8f0ccc92);
        II(c, d, a, b, w[10], 15, 0xffeff47d); II(b, c, d, a, w[1], 21, 0x85845dd1);
        II(a, b, c, d, w[8], 6, 0x6fa87e4f); II(d, a, b, c, w[15], 10, 0xfe2ce6e0);
        II(c, d, a, b, w[6], 15, 0xa3014314); II(b, c, d, a, w[13], 21, 0x4e0811a1);
        II(a, b, c, d, w[4], 6, 0xf7537e82); II(d, a, b, c, w[11], 10, 0xbd3af235);
        II(c, d, a, b, w[2], 15, 0x2ad7d2bb); II(b, c, d, a, w[9], 21, 0xeb86d391);

        h0 += a; h1 += b; h2 += c; h3 += d;
    }

    // собираем итоговую строку
    std::string result = "";
    uint32_t arr[4] = {h0, h1, h2, h3};
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            char hex[3];
            sprintf(hex, "%02x", (arr[i] >> (j * 8)) & 0xFF);
            result += hex;
        }
    }
    return result;
}

#endif
