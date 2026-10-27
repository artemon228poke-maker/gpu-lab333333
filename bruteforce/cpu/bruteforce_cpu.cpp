// это перебор пароля на процессоре, чтобы потом сравнить с видюхой
#include <iostream>
#include <string>
#include <vector>
#include <chrono>
#include "md5.h" // тут лежит сама функция хэширования

using namespace std;

// функция перебора
// принимаем строку, которую ищем (ее хэш), и длину пароля
void start_bruteforce(string target_hash, int length) {
    // словарь из цифр и маленьких букв
    string chars = "0123456789abcdefghijklmnopqrstuvwxyz";
    int chars_len = chars.length();
    
    // тут храним текущий пароль, который собираем
    string current_password(length, '0');
    
    // флаг, чтобы остановить перебор, если нашли
    bool found = false;
    
    // запускаем таймер
    auto start_time = chrono::high_resolution_clock::now();
    long long attempts = 0;

    while (!found) {
        attempts++;
        
        // считаем хэш от текущего пароля
        string current_hash = md5(current_password);
        
        // если хэши совпали - ура, нашли
        if (current_hash == target_hash) {
            auto end_time = chrono::high_resolution_clock::now();
            chrono::duration<double> duration = end_time - start_time;
            
            cout << "пароль найден: " << current_password << endl;
            cout << "потрачено попыток: " << attempts << endl;
            cout << "время на процессоре: " << duration.count() << " сек" << endl;
            found = true;
            break;
        }
        
        // логика перебора (как счетчик в машине)
        // идем с конца строки и увеличиваем символ
        for (int i = length - 1; i >= 0; i--) {
            if (current_password[i] != chars[chars_len - 1]) {
                // находим индекс текущего символа и берем следующий
                size_t idx = chars.find(current_password[i]);
                current_password[i] = chars[idx + 1];
                break;
            } else {
                // если дошли до последнего символа словаря, сбрасываем на первый
                current_password[i] = chars[0];
            }
        }
    }
}

int main(int argc, char* argv[]) {
    // для теста возьмем пароль abc (его хэш ниже)
    // потом поменяем на рандомный
    string target = "900150983cd24fb0d6963f7d28e17f72"; // это хэш от "abc"
    int length = 3; // длина пароля
    
    cout << "старт перебора на cpu" << endl;
    start_bruteforce(target, length);
    
    return 0;
}
