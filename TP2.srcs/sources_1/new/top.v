module uart_alu_top(
    input wire in_clock_100MHz,       // Reloj principal de 100 MHz
    input wire in_reset,              // Señal de reset
    input wire in_serial_data,        // Entrada de datos seriales para RX
    output wire out_serial_data,      // Salida de datos seriales de TX
    output wire out_tx_data_ready,    // Señal de que el dato está listo para transmisión (expuesta para pruebas)
    output wire [7:0] out_tx_data     // Dato de salida de la ALU (expuesto para pruebas)
);

    // Señales internas
    wire baud_tx_enable;              // Habilitación de transmisión del generador de baud rate
    wire baud_rx_enable;              // Habilitación de recepción del generador de baud rate
    wire out_reception_complete;      // Señal de finalización de recepción (RX)
    wire [7:0] out_parallel_data;     // Dato paralelo recibido en RX (8 bits)

    // Instancia del generador de reloj (clock wizard)
    wire clk_out;                     
    clk_wiz_0 clk_gen (
        .clk_in1(in_clock_100MHz),
        .clk_out1(clk_out),
        .reset(in_reset),
        .locked()  // Esta señal de locked puede usarse para habilitar otros módulos cuando el reloj esté estable
    );

    // Instancia del generador de baud rate
    uart_baud_rate_generator #(
        .CLOCK_RATE_HZ(100_000_000),  
        .BAUD_RATE_BPS(115200)        
    ) baud_rate_gen_inst (
        .in_clock(clk_out),
        .out_tx_baud_enable(baud_tx_enable),
        .out_rx_baud_enable(baud_rx_enable)
    );

    // Instancia de UART_RX (Receptor UART)
    UART_RX uart_rx_inst (
        .in_clock(clk_out),
        .in_baudrate_enable(baud_rx_enable), // Se activa en cada pulso de baudrate para sincronización RX
        .in_reset(in_reset),
        .in_serial_data(in_serial_data),
        .out_reception_complete(out_reception_complete), // Se activa cuando se recibe un byte completo
        .out_parallel_data(out_parallel_data)            // Dato paralelo de 8 bits recibido
    );

    // Instancia de la interfaz UART-ALU
    interface_UART_ALU uart_alu_interface (
        .in_clock(clk_out),
        .in_reset(in_reset),
        .in_rx_data_ready(out_reception_complete),  // Se activa cuando se recibe un byte completo en UART_RX
        .in_rx_data(out_parallel_data),             // Dato paralelo desde UART_RX a la interfaz
        .out_tx_data_ready(out_tx_data_ready),      // Señal de salida indicando que el dato de la ALU está listo
        .out_tx_data(out_tx_data)                   // Dato de salida de la ALU para transmisión
    );

    // Instancia de UART_TX (Transmisor UART)
    UART_TX uart_tx_inst (
        .in_clock(clk_out),
        .in_baudrate_enable(baud_tx_enable),        // Se activa en cada pulso de baudrate para sincronización TX
        .in_reset(in_reset),
        .in_data_enable(out_tx_data_ready),         // Activar la transmisión cuando el dato de la ALU esté listo
        .in_parallel_data(out_tx_data),             // Dato a transmitir desde la ALU
        .out_transmission_complete(),               // Señal opcional de transmisión completa
        .out_serial_data(out_serial_data)           // Salida serial para el transmisor
    );

    // Bloque para logs de depuración
    initial begin
        $display("==== Iniciando simulacion de uart_alu_top ====");
    end

    // Logs de recepción UART_RX
    always @(posedge out_reception_complete) begin
        $display("Time: %0t | Dato recibido completo en UART_RX: %b", $time, out_parallel_data);
    end

    // Logs en interface_UART_ALU cuando el dato es procesado
    always @(posedge clk_out) begin
        if (out_reception_complete) begin
            $display("Time: %0t | interface_UART_ALU: Dato recibido: %b", $time, out_parallel_data);
        end
    end

    // Logs para el resultado de la ALU y señal de datos listos
    always @(posedge out_tx_data_ready) begin
        $display("Time: %0t | Resultado de la ALU listo para transmision: %b", $time, out_tx_data);
    end

    // Logs para transmisión UART_TX
    always @(posedge baud_tx_enable) begin
        if (out_tx_data_ready) begin
            $display("Time: %0t | UART_TX: Enviando dato: %b", $time, out_tx_data);
        end
    end

endmodule
