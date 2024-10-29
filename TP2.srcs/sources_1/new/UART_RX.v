`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2024 10:18:48 PM
// Design Name: 
// Module Name: UART_RX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  UART receiver module for asynchronous data reception.
//  It synchronizes and samples incoming serial data to reconstruct
//  the transmitted byte and signals when reception is complete.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module UART_RX
(
    // Definición de Puertos del módulo
    input wire in_clk,                  // Señal de reloj de entrada
    input wire in_rx_en,                // Señal de habilitación para recepción
    input wire rst,                     // Señal de reset
    input wire rx_serial_data,          // Señal serial de datos de entrada
    output wire rx_finish,              // Señal de finalización de recepción
    output reg [7:0] rx_data            // Byte de datos recibido
);

    // Parámetros para los estados de la máquina de estados
    localparam IDLE = 1'b0;
    localparam READ = 1'b1;

    // Registros y variables internos
    reg rx_serial_data_r, rx_serial_data_r2, rx_serial_data_r3; // Registros de sincronización de señal de entrada
    reg state;                           // Estado de la máquina de estados
    reg [3:0] sample_cnt;                // Contador de muestras para la sincronización
    reg [2:0] rx_cnt;                    // Contador de bits recibidos
    reg rx_finish_r, rx_finish_r2, rx_finish_r3; // Registros para la señal de finalización de recepción

    // Señal sincronizada para recepción
    wire rx_sync = rx_serial_data_r3;

    // Doble latch para sincronizar la señal de entrada rx_serial_data
    always @(posedge in_clk) begin
        if (rst) begin
            rx_serial_data_r <= 1;
            rx_serial_data_r2 <= 1;
            rx_serial_data_r3 <= 1;
        end 
        else if (in_rx_en) begin
            rx_serial_data_r <= rx_serial_data;
            rx_serial_data_r2 <= rx_serial_data_r;
            rx_serial_data_r3 <= rx_serial_data_r2;
        end
    end

    // Máquina de estados para recepción de datos
    always @(posedge in_clk) begin
        if (rst) begin
            sample_cnt <= 0;
            rx_cnt <= 0;
            rx_data <= 0;
            state <= IDLE;
        end
        else if (in_rx_en) begin
            case(state)
                IDLE: begin
                    rx_cnt <= 0;
                    // Inicia la lectura cuando se detecta un bit de inicio (0)
                    if (rx_sync == 0) begin
                        sample_cnt <= sample_cnt + 1;
                        if (sample_cnt == 4'd7) begin   // Mitad del ciclo detectado
                            state <= READ;             // Cambia al estado de lectura
                        end
                    end
                    else begin
                        sample_cnt <= 0;
                    end
                end
                READ: begin
                    sample_cnt <= sample_cnt + 1;
                    if (sample_cnt == 4'd7) begin
                        rx_cnt <= rx_cnt + 1;
                        if (rx_cnt == 4'd7) begin
                            state <= IDLE;
                            rx_finish_r <= 1;
                        end
                        else begin
                            rx_finish_r <= 0;
                        end
                        // Asignación de bits recibidos al registro de datos
                        case(rx_cnt)
                            3'd0: rx_data[0] <= rx_sync;
                            3'd1: rx_data[1] <= rx_sync;
                            3'd2: rx_data[2] <= rx_sync;
                            3'd3: rx_data[3] <= rx_sync;
                            3'd4: rx_data[4] <= rx_sync;
                            3'd5: rx_data[5] <= rx_sync;
                            3'd6: rx_data[6] <= rx_sync;
                            3'd7: rx_data[7] <= rx_sync;
                        endcase
                    end
                end
            endcase
        end   
    end

    // Latch para señal de finalización de recepción
    always @(posedge in_clk) begin
        if (rst) begin
            rx_finish_r2 <= 0;
            rx_finish_r3 <= 0;
        end
        else begin
            rx_finish_r2 <= rx_finish_r;
            rx_finish_r3 <= rx_finish_r2;
        end
    end

    // Asignación de la señal de finalización de recepción
    assign rx_finish = rx_finish_r2 & ~rx_finish_r3;

endmodule
