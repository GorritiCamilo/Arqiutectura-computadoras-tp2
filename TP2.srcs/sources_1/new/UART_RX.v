`timescale 1ns / 1ps

module UART_RX
(
    // Definición de Puertos del módulo
    input wire in_clock,                    // Señal de reloj de entrada
    input wire in_baudrate_enable,          // Señal de habilitación para recepción
    input wire in_reset,                    // Señal de reset
    input wire in_serial_data,              // Señal serial de datos de entrada
    output wire out_reception_complete,     // Señal de finalización de recepción
    output reg [7:0] out_parallel_data      // Byte de datos recibido
);

    // Parámetros para los estados de la máquina de estados
    localparam STATE_IDLE = 1'b0;
    localparam STATE_READ = 1'b1;

    // Registros y variables internos
    reg [3:0] sample_counter;                     // Contador de muestras para la sincronización de bits
    reg [2:0] bit_counter;                        // Contador de bits recibidos
    reg reception_complete_flag;                  // Indica la finalización de recepción
    reg reception_complete_delay1, reception_complete_delay2; // Latches para la señal de finalización

    reg in_serial_data_sync1, in_serial_data_sync2, in_serial_data_sync3; // Registros de sincronización para la señal de entrada
    reg state;                                     // Estado actual de la máquina de estados

    // Señal sincronizada para recepción
    wire synchronized_serial_data = in_serial_data_sync3;

    // Doble latch para sincronizar la señal de entrada in_serial_data
    always @(posedge in_clock) begin
        if (in_reset) begin
            in_serial_data_sync1 <= 1;
            in_serial_data_sync2 <= 1;
            in_serial_data_sync3 <= 1;
        end 
        else if (in_baudrate_enable) begin
            in_serial_data_sync1 <= in_serial_data;
            in_serial_data_sync2 <= in_serial_data_sync1;
            in_serial_data_sync3 <= in_serial_data_sync2;
        end
    end

    // Máquina de estados para recepción de datos
    always @(posedge in_clock) begin
        if (in_reset) begin
            sample_counter <= 0;
            bit_counter <= 0;
            out_parallel_data <= 0;
            state <= STATE_IDLE;
            reception_complete_flag <= 1'b0;
        end
        else if (in_baudrate_enable) begin
            case(state)
                STATE_IDLE: begin
                    bit_counter <= 0;
                    // Inicia la lectura cuando se detecta un bit de inicio (0)
                    if (synchronized_serial_data == 0) begin
                        sample_counter <= sample_counter + 1;
                        if (sample_counter == 4'd7) begin   // Mitad del ciclo detectado
                            state <= STATE_READ;            // Cambia al estado de lectura
                        end
                    end
                    else begin
                        sample_counter <= 0;
                    end
                end
                STATE_READ: begin
                    sample_counter <= sample_counter + 1;
                    if (sample_counter == 4'd7) begin
                        bit_counter <= bit_counter + 1;
                        // Asignación de bits recibidos al registro de datos
                        case(bit_counter)
                            3'd0: out_parallel_data[0] <= synchronized_serial_data;
                            3'd1: out_parallel_data[1] <= synchronized_serial_data;
                            3'd2: out_parallel_data[2] <= synchronized_serial_data;
                            3'd3: out_parallel_data[3] <= synchronized_serial_data;
                            3'd4: out_parallel_data[4] <= synchronized_serial_data;
                            3'd5: out_parallel_data[5] <= synchronized_serial_data;
                            3'd6: out_parallel_data[6] <= synchronized_serial_data;
                            3'd7: out_parallel_data[7] <= synchronized_serial_data;
                        endcase

                        // Comprobación de finalización de recepción
                        if (bit_counter == 4'd7) begin
                            state <= STATE_IDLE;
                            reception_complete_flag <= 1;
                        end
                        else begin
                            reception_complete_flag <= 0;
                        end
                    end
                end
            endcase
        end   
    end

    // Latches para capturar el final de la recepción
    always @(posedge in_clock) begin
        if (in_reset) begin
            reception_complete_delay1 <= 0;
            reception_complete_delay2 <= 0;
        end
        else begin
            reception_complete_delay1 <= reception_complete_flag;
            reception_complete_delay2 <= reception_complete_delay1;
        end
    end

    // Asignación de la señal de finalización de recepción
    assign out_reception_complete = reception_complete_delay1 & ~reception_complete_delay2;

endmodule
