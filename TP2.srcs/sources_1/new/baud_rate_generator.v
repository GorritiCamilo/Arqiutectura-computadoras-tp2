`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.17.2024 21:29:16
// Design Name: 
// Module Name: uart_baud_rate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  Baudrate generator {CLOCK_RATE} (internal clock) 
//  {BAUD_RATE} tx/rx pair, with default rx oversampling at 16x 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_baud_rate_generator
#(
    // Parámetros
    parameter NB_COUNTER = 16,           // Ancho de los contadores
    parameter CLOCK_RATE = 100_000_000,  // Frecuencia del reloj en Hz (ej. 100 MHz)
    parameter BAUD_RATE = 115200         // Tasa de baudios
)
(
    // Definición de Puertos del módulo
    input wire in_clk,                   // Señal de reloj de entrada
    output wire out_tx_enable,           // Señal de habilitación para transmisión
    output wire out_rx_enable            // Señal de habilitación para recepción
);

    // Constantes para los contadores RX y TX
    localparam OVERSAMPLE = 16;
    localparam RX_MAX = CLOCK_RATE / (BAUD_RATE * OVERSAMPLE);  // RX oversample de 16x
    localparam TX_MAX = CLOCK_RATE / BAUD_RATE;                 // TX a la tasa de baudios

    // Contadores que van de 0 a RX_MAX/TX_MAX
    reg [NB_COUNTER-1:0] rx_count = {NB_COUNTER{1'b0}};         // Contador RX
    reg [NB_COUNTER-1:0] tx_count = {NB_COUNTER{1'b0}};         // Contador TX

    // Señales de habilitación cuando el contador llega a 0
    assign out_rx_enable = (rx_count == {NB_COUNTER{1'b0}});    // Habilita RX cuando el contador llega a 0
    assign out_tx_enable = (tx_count == {NB_COUNTER{1'b0}});    // Habilita TX cuando el contador llega a 0

    // Lógica del contador RX
    always @(posedge in_clk) begin
        if (rx_count == RX_MAX) begin
            rx_count <= {NB_COUNTER{1'b0}};                     // Reinicia el contador RX
        end else begin
            rx_count <= rx_count + 1;                           // Incrementa el contador RX
        end
    end

    // Lógica del contador TX
    always @(posedge in_clk) begin
        if (tx_count == TX_MAX) begin
            tx_count <= {NB_COUNTER{1'b0}};                     // Reinicia el contador TX
        end else begin
            tx_count <= tx_count + 1;                           // Incrementa el contador TX
        end
    end

endmodule
