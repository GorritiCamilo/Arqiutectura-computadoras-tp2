`timescale 1ns / 1ps

module uart_baud_rate_generator
#(
    // Parámetros
    parameter NB_COUNTER = 16,                   // Ancho de los contadores
    parameter CLOCK_RATE_HZ = 100_000_000,       // Frecuencia del reloj en Hz (ej. 100 MHz)
    parameter BAUD_RATE_BPS = 115200             // Tasa de baudios en bits por segundo
)
(
    // Definición de Puertos del módulo
    input wire in_clock,                         // Señal de reloj de entrada
    output wire out_tx_baud_enable,              // Señal de habilitación para transmisión
    output wire out_rx_baud_enable               // Señal de habilitación para recepción
);

    // Constantes para los contadores RX y TX
    localparam OVERSAMPLE_RATE = 16;
    localparam RX_COUNTER_MAX = CLOCK_RATE_HZ / (BAUD_RATE_BPS * OVERSAMPLE_RATE);  // RX oversample de 16x
    localparam TX_COUNTER_MAX = CLOCK_RATE_HZ / BAUD_RATE_BPS;                      // TX a la tasa de baudios

    // Contadores que van de 0 a RX_COUNTER_MAX/TX_COUNTER_MAX
    reg [NB_COUNTER-1:0] rx_sample_counter = {NB_COUNTER{1'b0}};   // Contador RX para oversampling
    reg [NB_COUNTER-1:0] tx_baud_counter = {NB_COUNTER{1'b0}};     // Contador TX para baud rate

    // Señales de habilitación cuando el contador llega a 0
    assign out_rx_baud_enable = (rx_sample_counter == {NB_COUNTER{1'b0}});  // Habilita RX cuando el contador llega a 0
    assign out_tx_baud_enable = (tx_baud_counter == {NB_COUNTER{1'b0}});    // Habilita TX cuando el contador llega a 0

    // Lógica del contador RX
    always @(posedge in_clock) begin
        if (rx_sample_counter == RX_COUNTER_MAX) begin
            rx_sample_counter <= {NB_COUNTER{1'b0}};               // Reinicia el contador RX
        end else begin
            rx_sample_counter <= rx_sample_counter + 1;            // Incrementa el contador RX
        end
    end

    // Lógica del contador TX
    always @(posedge in_clock) begin
        if (tx_baud_counter == TX_COUNTER_MAX) begin
            tx_baud_counter <= {NB_COUNTER{1'b0}};                 // Reinicia el contador TX
        end else begin
            tx_baud_counter <= tx_baud_counter + 1;                // Incrementa el contador TX
        end
    end

endmodule
