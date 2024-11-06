`timescale 1ns / 1ps

module uart_alu_top(
    input wire in_clock_100MHz,       // Reloj principal de 100 MHz
    input wire in_reset,              // Señal de reset
    input wire in_serial_data,        // Entrada de datos seriales para RX
    output wire out_serial_data       // Salida de datos seriales de TX
);

    // Señales internas
    wire baud_tx_enable;              // Habilitación de transmisión del generador de baud rate
    wire baud_rx_enable;              // Habilitación de recepción del generador de baud rate
    wire out_reception_complete;      // Señal de finalización de recepción (RX)
    wire [7:0] out_parallel_data;     // Dato paralelo recibido en RX (8 bits)
    wire in_tx_data_ready;            // Señal que indica al TX que hay un dato listo para enviar
    wire [7:0] out_tx_data;           // Dato a transmitir desde la FIFO de salida (8 bits)

    // Instancia del clk_wiz_0 (generador de reloj)
    wire clk_out;                     // Reloj de salida ajustado a 100 MHz
    clk_wiz_0 clk_gen (
        .clk_in1(in_clock_100MHz),
        .clk_out1(clk_out),
        .reset(in_reset),
        .locked()
    );

    // Instancia del módulo uart_baud_rate_generator
    uart_baud_rate_generator #(
        .CLOCK_RATE_HZ(100_000_000),  // Frecuencia del reloj de 100 MHz
        .BAUD_RATE_BPS(115200)        // Tasa de baudios de 115200
    ) baud_rate_gen_inst (
        .in_clock(clk_out),
        .out_tx_baud_enable(baud_tx_enable),
        .out_rx_baud_enable(baud_rx_enable)
    );

    // Instancia del módulo UART_RX
    UART_RX uart_rx_inst (
        .in_clock(clk_out),
        .in_baudrate_enable(baud_rx_enable),
        .in_reset(in_reset),
        .in_serial_data(in_serial_data),
        .out_reception_complete(out_reception_complete),
        .out_parallel_data(out_parallel_data)
    );

    // Instancia de la interfaz UART-ALU
    interface_UART_ALU uart_alu_interface (
        .in_clock(clk_out),
        .in_reset(in_reset),
        .in_rx_data_ready(out_reception_complete),
        .in_rx_data(out_parallel_data),
        .out_tx_data_ready(in_tx_data_ready),
        .out_tx_data(out_tx_data)
    );

    // Instancia del módulo UART_TX
    UART_TX uart_tx_inst (
        .in_clock(clk_out),
        .in_baudrate_enable(baud_tx_enable),
        .in_reset(in_reset),
        .in_data_enable(in_tx_data_ready),
        .in_parallel_data(out_tx_data),
        .out_transmission_complete(),
        .out_serial_data(out_serial_data)
    );

    // Debug: Monitor de señales internas clave
    initial begin
        $monitor("Time: %0t | out_reception_complete: %b | in_tx_data_ready: %b | out_tx_data: %b",
                 $time, out_reception_complete, in_tx_data_ready, out_tx_data);
    end

endmodule
