`timescale 1ns / 1ps

module interface_UART_ALU(
    input wire in_clock,
    input wire in_reset,
    input wire in_rx_data_ready,            // Señal que indica que el RX tiene un dato listo
    input wire [7:0] in_rx_data,            // Dato recibido desde UART_RX (8 bits)
    output wire out_tx_data_ready,          // Señal que indica al TX que hay un dato listo para enviar
    output wire [7:0] out_tx_data           // Dato a enviar desde la FIFO de salida a UART_TX (8 bits)
);

    // FIFO de entrada (almacena datos recibidos del RX)
    reg [7:0] fifo_in [15:0];               // FIFO de entrada de 16 espacios de 8 bits
    reg [3:0] fifo_in_head, fifo_in_tail;   // Punteros de cabeza y cola para la FIFO de entrada
    wire fifo_in_empty = (fifo_in_head == fifo_in_tail);
    wire fifo_in_full = ((fifo_in_head + 1) % 16 == fifo_in_tail);

    // FIFO de salida (almacena resultados de la ALU)
    reg [7:0] fifo_out [15:0];              // FIFO de salida de 16 espacios de 8 bits
    reg [3:0] fifo_out_head, fifo_out_tail; // Punteros de cabeza y cola para la FIFO de salida
    wire out_fifo_empty = (fifo_out_head == fifo_out_tail);
    wire fifo_out_full = ((fifo_out_head + 1) % 16 == fifo_out_tail);

    // Señales de datos y control para la ALU
    reg [3:0] alu_data_a, alu_data_b;       // Datos de entrada a la ALU (4 bits cada uno)
    reg [5:0] alu_operation;                // Operación de la ALU (6 bits)
    wire [3:0] alu_result;                  // Resultado de la ALU (4 bits)
    reg alu_ready;                          // Señal para indicar que la ALU ha procesado los datos

    // Instancia de la ALU
    alu #(
        .NB_INPUT_DATA(4),
        .NB_OUTPUT_DATA(4),
        .NB_OPERATION(6)
    ) alu_inst (
        .in_data_a(alu_data_a),
        .in_data_b(alu_data_b),
        .in_operation(alu_operation),
        .out_data(alu_result)
    );

    // Control de entrada: Escritura en FIFO de entrada
    always @(posedge in_clock) begin
        if (in_reset) begin
            fifo_in_head <= 0;
        end else if (in_rx_data_ready && !fifo_in_full) begin
            fifo_in[fifo_in_head] <= in_rx_data;
            fifo_in_head <= fifo_in_head + 1;
        end
    end

    // Control de datos desde FIFO de entrada hacia ALU
    reg processing_data;
    always @(posedge in_clock) begin
        if (in_reset) begin
            processing_data <= 0;
            alu_data_a <= 0;
            alu_data_b <= 0;
            alu_operation <= 0;
        end else if (!fifo_in_empty && !processing_data) begin
            // Procesar el siguiente dato de la FIFO de entrada
            processing_data <= 1;
            case (fifo_in[fifo_in_tail][7:6]) // Clasificación CC
                2'b00: alu_data_a <= fifo_in[fifo_in_tail][3:0]; // Dato A
                2'b01: alu_data_b <= fifo_in[fifo_in_tail][3:0]; // Dato B
                2'b10: alu_operation <= fifo_in[fifo_in_tail][5:0]; // Operación
            endcase
        end else if (alu_ready) begin
            processing_data <= 0; // Liberamos el procesamiento una vez listo
        end
    end

    // Bloque separado para controlar la señal alu_ready
    always @(posedge in_clock) begin
        if (in_reset) begin
            alu_ready <= 0;
        end else if (!fifo_in_empty && !processing_data && fifo_in[fifo_in_tail][7:6] == 2'b10) begin
            alu_ready <= 1; // Activa alu_ready cuando la operación está lista
        end else if (alu_ready) begin
            alu_ready <= 0; // Desactiva alu_ready después de una operación
        end
    end

    // Bloque separado para actualizar fifo_in_tail
    always @(posedge in_clock) begin
        if (in_reset) begin
            fifo_in_tail <= 0;
        end else if (!fifo_in_empty && processing_data) begin
            fifo_in_tail <= fifo_in_tail + 1;
        end
    end

    // Bloque separado para actualizar fifo_out_tail
    always @(posedge in_clock) begin
        if (in_reset) begin
            fifo_out_tail <= 0;
        end else if (out_tx_data_ready) begin
            fifo_out_tail <= fifo_out_tail + 1;
        end
    end

    // Control de salida: Escritura en FIFO de salida
    always @(posedge in_clock) begin
        if (in_reset) begin
            fifo_out_head <= 0;
        end else if (alu_ready && !fifo_out_full) begin
            // Almacena el resultado de la ALU extendido a 8 bits
            fifo_out[fifo_out_head] <= {4'b0000, alu_result}; 
            fifo_out_head <= fifo_out_head + 1;
        end
    end

    // Asignación para transmisión
    assign out_tx_data_ready = !out_fifo_empty;         // Indica al TX si hay datos para enviar
    assign out_tx_data = fifo_out[fifo_out_tail];       // Envía el dato de la FIFO de salida

endmodule
