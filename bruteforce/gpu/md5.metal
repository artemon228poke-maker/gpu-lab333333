#include <metal_stdlib>
using namespace metal;

#define F(x, y, z) ((x & y) | (~x & z))
#define G(x, y, z) ((x & z) | (y & ~z))
#define H(x, y, z) (x ^ y ^ z)
#define I(x, y, z) (y ^ (x | ~z))
#define ROTL(x, n) ((x << n) | (x >> (32 - n)))
#define FF(a, b, c, d, x, s, ac) { a += F(b, c, d) + x + ac; a = ROTL(a, s); a += b; }
#define GG(a, b, c, d, x, s, ac) { a += G(b, c, d) + x + ac; a = ROTL(a, s); a += b; }
#define HH(a, b, c, d, x, s, ac) { a += H(b, c, d) + x + ac; a = ROTL(a, s); a += b; }
#define II(a, b, c, d, x, s, ac) { a += I(b, c, d) + x + ac; a = ROTL(a, s); a += b; }

kernel void bruteforce_md5(
    device const uchar* target_hash [[buffer(0)]],
    device char* found_password [[buffer(1)]],
    device atomic_int* is_found [[buffer(2)]],
    constant uint& length [[buffer(3)]],
    uint id [[thread_position_in_grid]]
) {
    if (atomic_load_explicit(is_found, memory_order_relaxed)) return;
    
    char pass[10] = {0};
    uint temp_id = id;
    for (int i = length - 1; i >= 0; i--) {
        uint char_idx = temp_id % 36;
        temp_id /= 36;
        if (char_idx < 10) pass[i] = 48 + char_idx;
        else pass[i] = 97 + (char_idx - 10);
    }
    
    uint w[16] = {0};
    for (uint i = 0; i < length; i++) {
        w[i / 4] |= (uint)(uchar)pass[i] << ((i % 4) * 8);
    }
    w[length / 4] |= 0x80u << ((length % 4) * 8);
    w[14] = length * 8;
    
    uint a = 0x67452301, b = 0xEFCDAB89, c = 0x98BADCFE, d = 0x10325476;
    
    FF(a, b, c, d, w[0], 7, 0xd76aa478); FF(d, a, b, c, w[1], 12, 0xe8c7b756);
    FF(c, d, a, b, w[2], 17, 0x242070db); FF(b, c, d, a, w[3], 22, 0xc1bdceee);
    FF(a, b, c, d, w[4], 7, 0xf57c0faf); FF(d, a, b, c, w[5], 12, 0x4787c62a);
    FF(c, d, a, b, w[6], 17, 0xa8304613); FF(b, c, d, a, w[7], 22, 0xfd469501);
    FF(a, b, c, d, w[8], 7, 0x698098d8); FF(d, a, b, c, w[9], 12, 0x8b44f7af);
    FF(c, d, a, b, w[10], 17, 0xffff5bb1); FF(b, c, d, a, w[11], 22, 0x895cd7be);
    FF(a, b, c, d, w[12], 7, 0x6b901122); FF(d, a, b, c, w[13], 12, 0xfd987193);
    FF(c, d, a, b, w[14], 17, 0xa679438e); FF(b, c, d, a, w[15], 22, 0x49b40821);
    
    GG(a, b, c, d, w[1], 5, 0xf61e2562); GG(d, a, b, c, w[6], 9, 0xc040b340);
    GG(c, d, a, b, w[11], 14, 0x265e5a51); GG(b, c, d, a, w[0], 20, 0xe9b6c7aa);
    GG(a, b, c, d, w[5], 5, 0xd62f105d); GG(d, a, b, c, w[10], 9, 0x02441453);
    GG(c, d, a, b, w[15], 14, 0xd8a1e681); GG(b, c, d, a, w[4], 20, 0xe7d3fbc8);
    GG(a, b, c, d, w[9], 5, 0x21e1cde6); GG(d, a, b, c, w[14], 9, 0xc33707d6);
    GG(c, d, a, b, w[3], 14, 0xf4d50d87); GG(b, c, d, a, w[8], 20, 0x455a14ed);
    GG(a, b, c, d, w[13], 5, 0xa9e3e905); GG(d, a, b, c, w[2], 9, 0xfcefa3f8);
    GG(c, d, a, b, w[7], 14, 0x676f02d9); GG(b, c, d, a, w[12], 20, 0x8d2a4c8a);
    
    HH(a, b, c, d, w[5], 4, 0xfffa3942); HH(d, a, b, c, w[8], 11, 0x8771f681);
    HH(c, d, a, b, w[11], 16, 0x6d9d6122); HH(b, c, d, a, w[14], 23, 0xfde5380c);
    HH(a, b, c, d, w[1], 4, 0xa4beea44); HH(d, a, b, c, w[4], 11, 0x4bdecfa9);
    HH(c, d, a, b, w[7], 16, 0xf6bb4b60); HH(b, c, d, a, w[10], 23, 0xbebfbc70);
    HH(a, b, c, d, w[13], 4, 0x289b7ec6); HH(d, a, b, c, w[0], 11, 0xeaa127fa);
    HH(c, d, a, b, w[3], 16, 0xd4ef3085); HH(b, c, d, a, w[6], 23, 0x04881d05);
    HH(a, b, c, d, w[9], 4, 0xd9d4d039); HH(d, a, b, c, w[12], 11, 0xe6db99e5);
    HH(c, d, a, b, w[15], 16, 0x1fa27cf8); HH(b, c, d, a, w[2], 23, 0xc4ac5665);
    
    II(a, b, c, d, w[0], 6, 0xf4292244); II(d, a, b, c, w[7], 10, 0x432aff97);
    II(c, d, a, b, w[14], 15, 0xab9423a7); II(b, c, d, a, w[5], 21, 0xfc93a039);
    II(a, b, c, d, w[12], 6, 0x655b59c3); II(d, a, b, c, w[3], 10, 0x8f0ccc92);
    II(c, d, a, b, w[10], 15, 0xffeff47d); II(b, c, d, a, w[1], 21, 0x85845dd1);
    II(a, b, c, d, w[8], 6, 0x6fa87e4f); II(d, a, b, c, w[15], 10, 0xfe2ce6e0);
    II(c, d, a, b, w[6], 15, 0xa3014314); II(b, c, d, a, w[13], 21, 0x4e0811a1);
    II(a, b, c, d, w[4], 6, 0xf7537e82); II(d, a, b, c, w[11], 10, 0xbd3af235);
    II(c, d, a, b, w[2], 15, 0x2ad7d2bb); II(b, c, d, a, w[9], 21, 0xeb86d391);
    
    a += 0x67452301; b += 0xEFCDAB89; c += 0x98BADCFE; d += 0x10325476;
    
    uchar hash[16];
    hash[0] = a & 0xff; hash[1] = (a >> 8) & 0xff; hash[2] = (a >> 16) & 0xff; hash[3] = (a >> 24) & 0xff;
    hash[4] = b & 0xff; hash[5] = (b >> 8) & 0xff; hash[6] = (b >> 16) & 0xff; hash[7] = (b >> 24) & 0xff;
    hash[8] = c & 0xff; hash[9] = (c >> 8) & 0xff; hash[10] = (c >> 16) & 0xff; hash[11] = (c >> 24) & 0xff;
    hash[12] = d & 0xff; hash[13] = (d >> 8) & 0xff; hash[14] = (d >> 16) & 0xff; hash[15] = (d >> 24) & 0xff;

    bool match = true;
    for (int i = 0; i < 16; i++) {
        if (hash[i] != target_hash[i]) { match = false; break; }
    }

    if (match) {
        if (atomic_exchange_explicit(is_found, 1, memory_order_relaxed) == 0) {
            for (int i = 0; i < length; i++) found_password[i] = pass[i];
        }
    }
}
