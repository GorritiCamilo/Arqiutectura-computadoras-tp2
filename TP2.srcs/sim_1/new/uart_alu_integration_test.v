`timescale 1ns / 1ps

module uart_alu_integration_test;
    // Señales de prueba
    reg in_clock_100MHz;
    reg in_reset;
    reg in_data_enable;
    reg [7:0] in_parallel_data;        // Dato paralelo para transmitir
    wire out_serial_data;              // Salida de datos seriales
    wire out_reception_complete;       // Señal de finalización de recepción (RX)
    wire [7:0] out_parallel_data;      // Dato recibido en paralelo (RX)

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
    localparam [5:0] RESTA = 6'b100010;

    // Secuencia de pruebas
    initial begin
        // Inicialización de señales
        in_reset = 1;
        #20 in_reset = 0;  // Liberar reset
        
        // Enviar operación de prueba
        send_alu_operation(4'b1010, 4'b0011, SUMA, "SUMA");   // A=10, B=3, operación SUMA
        send_alu_operation(4'b1100, 4'b0101, RESTA, "RESTA"); // A=12, B=5, operación RESTA
        
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

    // Tarea para enviar un byte utilizando el protocolo UART
    task send_byte(input [7:0] data);
        begin
            $display("Time: %0t | Sending byte: %b", $time, data);
            in_parallel_data = data;
            in_data_enable = 1;
            #10 in_data_enable = 0;
            #100;  // Espera
        end
    endtask

    // Tarea para esperar y mostrar el resultado procesado por la ALU
    task wait_for_result;
        begin
            $display("Esperando recepción del resultado de la ALU...");
            wait(out_reception_complete);  // Espera hasta que la recepción esté completa
            #100;  // Espera para estabilización
            $display("Time: %0t | Received ALU result: %b", $time, out_parallel_data);
        end
    endtask

endmodule
