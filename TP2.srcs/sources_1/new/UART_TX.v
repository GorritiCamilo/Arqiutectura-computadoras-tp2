`timescale 1ns / 1ps

module UART_TX
(
    // Definición de Puertos del módulo
    input wire in_clock,                   // Señal del reloj principal
    input wire in_baudrate_enable,         // Habilitación de transmisión en baudrate
    input wire in_reset,                   // Señal de reset del módulo
    input wire in_data_enable,             // Señal de habilitación de datos de entrada
    input wire [7:0] in_parallel_data,     // Dato paralelo a convertir en serial
    output wire out_transmission_complete, // Indica la finalización de transmisión
    output reg out_serial_data             // Dato serial para transmisión
);

    // Parámetros para los estados de la máquina de estados
    localparam STATE_IDLE = 1'b0;
    localparam STATE_TRANSMIT = 1'b1;

    // Registros internos
    reg state;                                // Estado actual de la máquina de estados
    reg [3:0] bit_counter;                    // Contador de bits transmitidos
    reg transmission_complete_flag;           // Indica fin de transmisión
    reg transmission_complete_delay1, transmission_complete_delay2; // Latches de señal finalización

    // Máquina de estados para transmisión de datos
    always @(posedge in_clock) begin
        if (in_reset) begin
            state <= STATE_IDLE;
            transmission_complete_flag <= 1'b0;
            out_serial_data <= 1'b1;
            bit_counter <= 0;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    out_serial_data <= 1'b1;
                    transmission_complete_flag <= 1'b1;
                    if (in_data_enable) begin
                        state <= STATE_TRANSMIT;
                    end
                end
                STATE_TRANSMIT: begin
                    transmission_complete_flag <= 0;
                    if (in_baudrate_enable == 1) begin
                        if (bit_counter < 4'd9) begin
                            bit_counter <= bit_counter + 1;
                        end
                        else begin
                            bit_counter <= 0;
                            state <= STATE_IDLE;
                        end

                        // Asignación de bits de transmisión en serie
                        case(bit_counter) 
                            4'd0: out_serial_data <= 0;                   // Bit de inicio
                            4'd1: out_serial_data <= in_parallel_data[0];
                            4'd2: out_serial_data <= in_parallel_data[1];
                            4'd3: out_serial_data <= in_parallel_data[2];
                            4'd4: out_serial_data <= in_parallel_data[3];
                            4'd5: out_serial_data <= in_parallel_data[4];
                            4'd6: out_serial_data <= in_parallel_data[5];
                            4'd7: out_serial_data <= in_parallel_data[6];
                            4'd8: out_serial_data <= in_parallel_data[7];
                            4'd9: out_serial_data <= 1;                   // Bit de parada
                        endcase
                    end
                end
            endcase
        end    
    end

    // Latches para capturar el final de la transmisión
    always @(posedge in_clock) begin
        if (in_reset) begin
            transmission_complete_delay1 <= 0;
            transmission_complete_delay2 <= 0;
        end
        else begin
            transmission_complete_delay1 <= transmission_complete_flag;
            transmission_complete_delay2 <= transmission_complete_delay1;
        end
    end

    // Asignación de la señal de finalización de transmisión
    assign out_transmission_complete = transmission_complete_delay1 & ~transmission_complete_delay2;

endmodule
