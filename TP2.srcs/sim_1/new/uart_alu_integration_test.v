`timescale 1ns / 1ps

module uart_alu_integration_test;
    // Señales de prueba
    reg in_clock_100MHz;
    reg in_reset;
    reg in_serial_data;              // Entrada de datos seriales para simular la recepción
    wire out_serial_data;            // Salida de datos seriales de `uart_alu_top`

    // Instancia del módulo `uart_alu_top`
    uart_alu_top uut (
        .in_clock_100MHz(in_clock_100MHz),
        .in_reset(in_reset),
        .in_serial_data(in_serial_data),  // Ahora estamos enviando datos seriales desde aquí
        .out_serial_data(out_serial_data)
    );

    // Generación del reloj de 100 MHz
    initial begin
        in_clock_100MHz = 0;
        forever #5 in_clock_100MHz = ~in_clock_100MHz;  // Período de 10 ns
    end

    // Parámetros de operaciones ALU
    localparam [5:0] SUMA  = 6'b100000;
    localparam [5:0] RESTA = 6'b100010;
    localparam [5:0] AND   = 6'b100100;
    localparam [5:0] OR    = 6'b100101;
    localparam [5:0] XOR   = 6'b100110;
    localparam [5:0] SRA   = 6'b000011;
    localparam [5:0] SRL   = 6'b000010;
    localparam [5:0] NOR   = 6'b100111;

    // Secuencia de pruebas
    initial begin
        // Inicializar señales
        in_reset = 1;
        in_serial_data = 1;  // Línea en alto para UART idle
        $display("Inicializacion completa. Reloj comenzado.");

        // Liberar reset después de algunos ciclos
        #20 in_reset = 0;
        $display("Time: %0t | Reset liberado", $time);
        #20;

        // Secuencia de operaciones para la ALU (envío de datos seriales)
        send_alu_operation_serial(4'b1010, 4'b0011, SUMA, "SUMA");   // A=10, B=3, operación SUMA
        send_alu_operation_serial(4'b1100, 4'b0101, RESTA, "RESTA"); // A=12, B=5, operación RESTA
        send_alu_operation_serial(4'b1010, 4'b0011, AND, "AND");     // A=10, B=3, operación AND
        send_alu_operation_serial(4'b1010, 4'b0011, OR, "OR");       // A=10, B=3, operación OR
        send_alu_operation_serial(4'b1010, 4'b0011, XOR, "XOR");     // A=10, B=3, operación XOR
        send_alu_operation_serial(4'b1010, 4'b0011, SRA, "SRA");     // A=10, B=3, operación SRA
        send_alu_operation_serial(4'b1010, 4'b0011, SRL, "SRL");     // A=10, B=3, operación SRL
        send_alu_operation_serial(4'b1010, 4'b0011, NOR, "NOR");     // A=10, B=3, operación NOR


        #2000000;  // Espera extendida para que todas las operaciones terminen
        $finish;
    end

    // Tarea para enviar operandos y operación a la ALU serialmente
    task send_alu_operation_serial(
        input [3:0] operand_A,
        input [3:0] operand_B,
        input [5:0] operation_code,
        input [7*8:0] operation_name  // Nombre de operación
    );
        begin
            $display("\n--- Iniciando prueba de operacion %s ---", operation_name);

            // Enviar operando A con identificador `00`
            send_byte_serial({4'b0000, operand_A});
            
            // Enviar operando B con identificador `10`
            send_byte_serial({4'b1000, operand_B});
            
            // Enviar código de operación con identificador `01`
            send_byte_serial({2'b01, operation_code});

            // Esperar resultado de la ALU
            wait_for_result(operation_name);
        end
    endtask

    // Tarea para enviar un byte serialmente a través de UART
    task send_byte_serial(input [7:0] data);
        integer i;
        begin
            // Enviar bit de start (0)
            in_serial_data = 0;
            #8680;  // Asumiendo baud rate de 115200, el bit dura 8680 ns
            $display("Time: %0t | Enviando bit de start (0)", $time);

            // Enviar los 8 bits de datos, LSB primero
            for (i = 0; i < 8; i = i + 1) begin
                in_serial_data = data[i];
                #8680;  // Duración de un bit a 115200 bps
                $display("Time: %0t | Enviando bit de dato %0d: %b", $time, i, data[i]);
            end

            // Enviar bit de stop (1)
            in_serial_data = 1;
            #8680;
            $display("Time: %0t | Enviando bit de stop (1)", $time);
        end
    endtask

    // Tarea para esperar y mostrar el resultado de la ALU
    task wait_for_result(input [7*8:0] operation_name);
        begin
            #100000;
        end
    endtask

endmodule
