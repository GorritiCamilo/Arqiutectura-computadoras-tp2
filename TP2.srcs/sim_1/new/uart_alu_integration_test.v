`timescale 1ns / 1ps

module uart_alu_integration_test;
    // Señales de prueba
    reg in_clock_100MHz;
    reg in_reset;
    reg in_rx_data_ready;               // Señal manual de in_rx_data_ready
    reg [7:0] in_rx_data;               // Datos manuales de entrada para el RX
    wire out_serial_data;               // Salida de datos seriales
    wire out_reception_complete;        // Señal de finalización de recepción (RX)
    wire out_tx_data_ready;             // Señal que indica que hay un dato listo para enviar en TX
    wire [7:0] out_tx_data;             // Dato listo para ser transmitido (8 bits)

    // Instancia del módulo `uart_alu_top`
    uart_alu_top uut (
        .in_clock_100MHz(in_clock_100MHz),
        .in_reset(in_reset),
        .in_serial_data(out_serial_data),  // Conectar la salida de TX a la entrada de RX
        .out_serial_data(out_serial_data)
    );

    // Generación del reloj de 100 MHz
    initial begin
        in_clock_100MHz = 0;
        forever #5 in_clock_100MHz = ~in_clock_100MHz;  // Reloj de 100 MHz con periodo de 10 ns
    end

    // Parámetros de las operaciones ALU
    localparam [5:0] SUMA  = 6'b100000;

    // Secuencia de pruebas
    initial begin
        // Inicialización de señales
        in_reset = 1;
        in_rx_data_ready = 0;
        #20 in_reset = 0;  // Liberar reset

        // Enviar datos de prueba (SUMA: operandos A = 10 y B = 3)
        send_alu_operation(4'b1010, 4'b0011, SUMA, "SUMA");

        #2000000;  // Espera extendida para que todas las operaciones terminen
        $finish;
    end

    // Tarea para enviar los operandos y operación a la ALU a través de UART
    task send_alu_operation(
        input [3:0] operand_A,
        input [3:0] operand_B,
        input [5:0] operation_code,
        input [7*8:0] operation_name  // Cadena ASCII para nombre de operación
    );
        begin
            $display("\n--- Testing %s operation ---", operation_name);

            // Enviar operando A con prefijo `0000`
            send_byte({4'b0000, operand_A});
            
            // Enviar operando B con prefijo `0100`
            send_byte({4'b0100, operand_B});
            
            // Enviar código de operación con prefijo `10`
            send_byte({2'b10, operation_code});

            // Esperar el resultado procesado por la ALU
            wait_for_result();
        end
    endtask

    // Tarea para enviar un byte y activar la señal `in_rx_data_ready`
    task send_byte(input [7:0] data);
        begin
            in_rx_data = data;
            in_rx_data_ready = 1;
            #10 in_rx_data_ready = 0;
            #100;  // Espera para estabilización
            $display("Time: %0t | Sent byte: %b", $time, data);
        end
    endtask

    // Tarea para esperar y mostrar el resultado procesado por la ALU
    task wait_for_result;
        begin
            $display("Esperando recepción del resultado de la ALU...");
            wait(out_tx_data_ready);  // Espera hasta que la transmisión esté lista
            #100;  // Espera para estabilización
            $display("Time: %0t | Received ALU result: %b", $time, out_tx_data);
        end
    endtask

    // Monitor para observar el dato serializado en tiempo real
    initial begin
        $monitor("Time: %0t | in_rx_data_ready: %b | in_rx_data: %b | out_tx_data_ready: %b | out_tx_data: %b", 
                 $time, in_rx_data_ready, in_rx_data, out_tx_data_ready, out_tx_data);
    end

endmodule
