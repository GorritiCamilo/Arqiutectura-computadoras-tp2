#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <bitset>

// Configuración del UART en /dev/ttyUSB0
int configurarUART() {
    int uart_filestream = open("/dev/ttyUSB0", O_RDWR | O_NOCTTY | O_NDELAY);
    if (uart_filestream == -1) {
        std::cerr << "Error al abrir /dev/ttyUSB0." << std::endl;
        return -1;
    }

    struct termios options;
    tcgetattr(uart_filestream, &options);
    options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;  // Configuración del baud rate y demás parámetros
    options.c_iflag = IGNPAR;
    options.c_oflag = 0;
    options.c_lflag = 0;

    tcflush(uart_filestream, TCIFLUSH);
    tcsetattr(uart_filestream, TCSANOW, &options);

    return uart_filestream;
}

// Función para leer y mostrar en binario cualquier dato recibido
void leerYMostrarBinario(int uart_filestream) {
    char byte;
    while (true) {
        int leido = read(uart_filestream, &byte, 1);
        if (leido > 0) {
            char ultimos4Bits = byte & 0x0F;
            std::cout << "Recibo: " << std::bitset<8>(byte) << std::endl;
            std::cout << "Resultado en binario: " << std::bitset<4>(ultimos4Bits) << std::endl;
            std::cout << "Resultado en hexadecimal: " << std::hex << static_cast<int>(ultimos4Bits) << std::endl;
            std::cout << "Resultado en decimal: " << static_cast<int>(ultimos4Bits) << std::endl;
        }
        usleep(100000);  // Espera breve para evitar una carga innecesaria en la CPU
    }
}

int main() {
    int uart_filestream = configurarUART();
    if (uart_filestream == -1) {
        return -1;
    }

    leerYMostrarBinario(uart_filestream);

    close(uart_filestream);
    return 0;
}
