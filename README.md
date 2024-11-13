# Arquitectura-computadoras-tp2
Segundo trabajo practico de la materia Arquitectura de Computadoras, referido a la creacion de un modulo UART para una basys 3 en Verilog

# UART Baud Rate Generator

## Descripción del Proyecto

Este módulo Verilog implementa un generador de tasa de baudios (**Baud Rate Generator**) para sistemas de comunicación **UART** (Universal Asynchronous Receiver-Transmitter). El módulo genera señales de habilitación para transmisión y recepción de datos seriales, ajustando la velocidad de transmisión y recepción a la **tasa de baudios** especificada. El diseño soporta una tasa de baudios configurable y utiliza **oversampling** para mejorar la precisión en la recepción de datos.

El módulo está diseñado para funcionar con un reloj de entrada de alta frecuencia, como 100 MHz, y divide la señal de reloj mediante contadores para generar las señales de habilitación (`tx_enable` y `rx_enable`) a la frecuencia adecuada para la comunicación UART.

## Características

- **Frecuencia de reloj de entrada**: 100 MHz (configurable).
- **Tasa de baudios**: 115200 (configurable).
- **Oversampling**: 16x (para la recepción de datos UART, configurable).
- **Contadores**: Dos contadores de 16 bits para sincronizar transmisión y recepción.
- **Generación de señales de habilitación**:
  - `out_tx_enable`: Habilita la transmisión de datos a la tasa de baudios especificada.
  - `out_rx_enable`: Habilita la recepción de datos con oversampling 16x.

## Parámetros

- **`NB_COUNTER`**: Define el ancho de los contadores. El valor predeterminado es 16 bits, lo que permite contar hasta 65535 ciclos de reloj.
- **`CLOCK_RATE`**: Define la frecuencia del reloj de entrada en Hz. El valor predeterminado es 100 MHz (`100_000_000`).
- **`BAUD_RATE`**: Define la tasa de baudios en bits por segundo (bps). El valor predeterminado es 115200 bps.

## Ecuaciones Utilizadas

1. **Transmisión**: La señal `out_tx_enable` se habilita cada cierto número de ciclos de reloj, calculados como:

   `TX_MAX = CLOCK_RATE / BAUD_RATE`

   En el caso predeterminado de un reloj de 100 MHz y una tasa de baudios de 115200:

   `TX_MAX = 100,000,000 / 115200 ≈ 868 ciclos de reloj`

2. **Recepción (Oversampling 16x)**: La señal `out_rx_enable` se habilita cada cierto número de ciclos de reloj, calculados como:

   `RX_MAX = CLOCK_RATE / (BAUD_RATE * 16)`

   Con un reloj de 100 MHz y una tasa de baudios de 115200:

   `RX_MAX = 100,000,000 / (115200 * 16) ≈ 54 ciclos de reloj`



