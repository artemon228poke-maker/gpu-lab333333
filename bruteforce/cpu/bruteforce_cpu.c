#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <CommonCrypto/CommonDigest.h>

const char alphabet[] = "0123456789abcdefghijklmnopqrstuvwxyz";

const char *hashes[] = {
    "",
    "0cc175b9c0f1b6a831c399e269772661",
    "8a8bb7cd343aa2ad99b7d762030857a2",
    "30f5eef91a397e4bbab4d93aeb286aef",
    "f2e49af795161e14acf9d9245473a368"
};

// считаем время выполнения
double get_time(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1000000000.0;
}

// считаем md5 для текущей строки
void calculate_md5(const char *text, char result[33]) {
    unsigned char digest[CC_MD5_DIGEST_LENGTH];

    CC_MD5(text, (CC_LONG)strlen(text), digest);

    for (int i = 0; i < 16; i++) {
        sprintf(result + i * 2, "%02x", digest[i]);
    }
    result[32] = '\0';
}

int main(int argc, char *argv[]) {
    int length = 4;

    if (argc > 1) {
        length = atoi(argv[1]);
    }

    if (length < 1 || length > 4) {
        printf("длина должна быть от 1 до 4\n");
        return 1;
    }

    // считаем количество возможных вариантов
    uint64_t total = 1;
    for (int i = 0; i < length; i++) {
        total *= 36;
    }

    char password[5] = {0};
    char hash[33];

    double start = get_time();

    // перебираем все варианты по порядку
    for (uint64_t id = 0; id < total; id++) {
        uint64_t number = id;

        // получаем строку из номера варианта
        for (int j = length - 1; j >= 0; j--) {
            password[j] = alphabet[number % 36];
            number /= 36;
        }
        password[length] = '\0';

        // сравниваем полученный хэш с заданным
        calculate_md5(password, hash);

        if (strcmp(hash, hashes[length]) == 0) {
            printf("CPU (C): password=%s attempts=%llu time=%.6f s\n",
                   password,
                   (unsigned long long)(id + 1),
                   get_time() - start);
            return 0;
        }
    }

    printf("совпадений нет\n");
    return 1;
}
