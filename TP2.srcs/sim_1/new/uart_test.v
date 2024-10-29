`timescale 1ns / 1ps


module uart_test_top;
    // Definición de señales de prueba
    reg in_clock;                      // Señal de reloj de 100 MHz
    reg in_reset;                      // Señal de reset
    reg in_data_enable;                // Señal de habilitación de datos de entrada
    reg [7:0] in_parallel_data;        // Dato paralelo para enviar
    wire out_transmission_complete;    // Señal de finalización de transmisión (TX)
    wire out_serial_data;              // Dato serial transmitido (TX)
    wire out_reception_complete;       // Señal de finalización de recepción (RX)
    wire [7:0] out_parallel_data;      // Dato recibido en paralelo (RX)
    wire baud_tx_enable;               // Habilitación de transmisión generada por el baud rate generator
    wire baud_rx_enable;               // Habilitación de recepción generada por el baud rate generator

    // Instancia del módulo UART_TX
    UART_TX uart_tx_inst (
        .in_clock(in_clock),
        .in_baudrate_enable(baud_tx_enable),   // Conectar señal de habilitación generada por el baud rate generator
        .in_reset(in_reset),
        .in_data_enable(in_data_enable),
        .in_parallel_data(in_parallel_data),
        .out_transmission_complete(out_transmission_complete),
        .out_serial_data(out_serial_data)
    );

    // Instancia del módulo UART_RX
    UART_RX uart_rx_inst (
        .in_clock(in_clock),
        .in_baudrate_enable(baud_rx_enable),   // Conectar señal de habilitación generada por el baud rate generator
        .in_reset(in_reset),
        .in_serial_data(out_serial_data),      // Conectar salida serial de TX a la entrada serial de RX
        .out_reception_complete(out_reception_complete),
        .out_parallel_data(out_parallel_data)
    );

    // Instancia del módulo uart_baud_rate_generator
    uart_baud_rate_generator #(
        .CLOCK_RATE_HZ(100_000_000),     // Frecuencia del reloj de 100 MHz
        .BAUD_RATE_BPS(115200)           // Tasa de baudios de 115200
    ) baud_rate_gen_inst (
        .in_clock(in_clock),
        .out_tx_baud_enable(baud_tx_enable),   // Conectar a la señal de habilitación de transmisión
        .out_rx_baud_enable(baud_rx_enable)    // Conectar a la señal de habilitación de recepción
    );

    // Generación del reloj de 100 MHz
    initial begin
        in_clock = 0;
        forever #5 in_clock = ~in_clock;  // Reloj de 100 MHz con periodo de 10 ns
    end

    // Estímulos de prueba para enviar datos de TX a RX
    initial begin
        // Inicialización de señales
        in_reset = 1;
        in_data_enable = 0;
        in_parallel_data = 8'b10101010;  // Dato de prueba

        // Liberar reset después de unos ciclos de reloj
        #20 in_reset = 0;

        // Proceso de transmisión de prueba
        forever begin
            #10 in_data_enable = 1;        // Activar señal de habilitación de datos
            #10 in_data_enable = 0;        // Desactivar habilitación de datos después de enviar
            wait(out_transmission_complete); // Espera hasta que finalice la transmisión
            #100;                          // Espera antes de siguiente transmisión
        end
    end

    // Monitor para observar el dato serializado y el dato recibido en paralelo
    initial begin
        $monitor("Time: %0t | Serial Output: %b", $time, out_serial_data);
    end

    // Imprimir dato recibido en paralelo cuando la recepción esté completa
    always @(posedge out_reception_complete) begin
        $display("Time: %0t | Parallel Data Received: %b", $time, out_parallel_data);
    end

endmodule
