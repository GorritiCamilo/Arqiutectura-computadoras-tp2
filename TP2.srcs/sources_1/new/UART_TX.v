`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2024 09:20:22 PM
// Design Name: 
// Module Name: UART_TX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  UART transmitter module that converts parallel data to serial format for transmission.
//  It signals when the transmission has completed.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module UART_TX
(
    // Definición de Puertos del módulo
    input wire in_clk,                   // Señal del reloj principal
    input wire out_tx_en,                // Habilitación de transmisión en baudrate
    input wire rst,                      // Señal de reset del módulo
    input wire tx_data_en,               // Señal de habilitación de datos de entrada
    input wire [7:0] tx_data_in,         // Dato paralelo a convertir en serial
    output wire tx_finish,               // Indica la finalización de transmisión
    output reg tx_serial_data            // Dato serial para transmisión
);

    // Parámetros para los estados de la máquina de estados
    localparam WAIT = 1'b0;
    localparam BUSY = 1'b1;

    // Registros internos
    reg state;                           // Estado de la máquina de estados
    reg [3:0] tx_cnt;                    // Contador de bits transmitidos
    reg tx_finish_r;                     // Registro temporal para indicar fin de transmisión
    reg tx_finish_r2, tx_finish_r3;      // Latches para la señal de finalización

    // Máquina de estados para transmisión de datos
    always @(posedge in_clk) begin
        if (rst) begin
            state <= WAIT;
            tx_finish_r <= 1'b0;
            tx_serial_data <= 1'b1;
            tx_cnt <= 0;
        end
        else begin
            case(state)
                WAIT: begin
                    tx_serial_data <= 1'b1;
                    tx_finish_r <= 1'b1;
                    // Inicia transmisión cuando tx_data_en está activo
                    if (tx_data_en) begin
                        state <= BUSY;
                    end
                end
                BUSY: begin
                    tx_finish_r <= 0;
                    if (out_tx_en == 1) begin
                        // Incrementa contador o vuelve al estado de espera tras transmisión completa
                        if (tx_cnt < 4'd9) begin
                            tx_cnt <= tx_cnt + 1;
                        end
                        else begin
                            tx_cnt <= 0;
                            state <= WAIT;
                        end

                        // Asignación de bits de transmisión en serie
                        case(tx_cnt) 
                            4'd0: tx_serial_data <= 0;              // Bit de inicio
                            4'd1: tx_serial_data <= tx_data_in[0];
                            4'd2: tx_serial_data <= tx_data_in[1];
                            4'd3: tx_serial_data <= tx_data_in[2];
                            4'd4: tx_serial_data <= tx_data_in[3];
                            4'd5: tx_serial_data <= tx_data_in[4];
                            4'd6: tx_serial_data <= tx_data_in[5];
                            4'd7: tx_serial_data <= tx_data_in[6];
                            4'd8: tx_serial_data <= tx_data_in[7];
                            4'd9: tx_serial_data <= 1;              // Bit de parada
                        endcase
                    end
                end
            endcase
        end    
    end

    // Latches para capturar el final de la transmisión
    always @(posedge in_clk) begin
        if (rst) begin
            tx_finish_r2 <= 0;
            tx_finish_r3 <= 0;
        end
        else begin
            tx_finish_r2 <= tx_finish_r;
            tx_finish_r3 <= tx_finish_r2;
        end
    end

    // Asignación de la señal de finalización de transmisión
    assign tx_finish = tx_finish_r2 & ~tx_finish_r3;

endmodule
