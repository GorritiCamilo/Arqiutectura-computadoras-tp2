`timescale 1ns / 1ps

module interface_UART_ALU (
    input wire in_clock,             // Reloj del sistema
    input wire in_reset,             // Señal de reinicio
    input wire in_rx_data_ready,     // Señal de dato recibido listo
    input wire [7:0] in_rx_data,     // Byte de dato recibido
    
    output reg out_tx_data_ready,    // Señal de dato listo para transmisión
    output reg [7:0] out_tx_data     // Byte de dato de salida
);

    // Parámetros
    localparam [1:0] ID_OPERANDO_A = 2'b00;
    localparam [1:0] ID_OPERANDO_B = 2'b10;
    localparam [1:0] ID_OPERACION  = 2'b01;

    // Señales internas para la ALU y control
    reg [3:0] operando_a;
    reg [3:0] operando_b;
    reg [5:0] operacion;
    reg operacion_cargada;        // Indicador de que la operación y los operandos están listos para la ALU
    reg resultado_valido;         // Señal para indicar que el resultado es estable para transmisión
    wire [3:0] resultado_alu;

    // Instancia de la ALU
    alu #(
        .NB_INPUT_DATA(4),
        .NB_OUTPUT_DATA(4),
        .NB_OPERATION(6)
    ) u_alu (
        .in_data_a(operando_a),
        .in_data_b(operando_b),
        .in_operation(operacion),
        .out_data(resultado_alu)
    );

    // Lógica para manejar los datos de entrada y configurar la ALU
    always @(posedge in_clock) begin
        if (in_reset) begin
            // Reiniciar todos los registros y señales
            operando_a <= 4'b0;
            operando_b <= 4'b0;
            operacion <= 6'b0;
            operacion_cargada <= 1'b0;
            resultado_valido <= 1'b0;
            out_tx_data_ready <= 1'b0;
            out_tx_data <= 8'b0;
            $display("Time: %0t | Reset activo - Registros reiniciados", $time);
        end else begin
            // Procesar el dato cuando esté listo
            if (in_rx_data_ready) begin
                $display("Time: %0t | Dato recibido: %b", $time, in_rx_data);
                case (in_rx_data[7:6])
                    ID_OPERANDO_A: begin
                        operando_a <= in_rx_data[3:0];
                        $display("Time: %0t | Operando A cargado: %b", $time, in_rx_data[3:0]);
                    end
                    ID_OPERANDO_B: begin
                        operando_b <= in_rx_data[3:0];
                        $display("Time: %0t | Operando B cargado: %b", $time, in_rx_data[3:0]);
                    end
                    ID_OPERACION: begin
                        operacion <= in_rx_data[5:0];
                        operacion_cargada <= 1'b1;  // Indicar que la operación y los operandos están listos
                        $display("Time: %0t | Operacion cargada: %b", $time, in_rx_data[5:0]);
                    end
                    default: begin
                        $display("Time: %0t | Identificador de dato desconocido: %b", $time, in_rx_data[7:6]);
                    end
                endcase
            end

            // Activar el envío de datos cuando la operación esté cargada
            if (operacion_cargada && !resultado_valido) begin
                out_tx_data <= {4'b0, resultado_alu};  // Colocar el resultado de 4 bits en los bits de menor peso
                out_tx_data_ready <= 1'b1;             // Indicar que el dato está listo para transmisión
                resultado_valido <= 1'b1;              // Marcar el resultado como válido para una transmisión
                operacion_cargada <= 1'b0;             // Reiniciar el indicador de carga de operación
                $display("Time: %0t | Resultado listo para transmision: %b", $time, out_tx_data);
                $display("Time: %0t | Resultado de la ALU: %b", $time, resultado_alu);
            end

            // Desactivar `out_tx_data_ready` una vez capturado el dato
            if (resultado_valido && !in_rx_data_ready) begin
                out_tx_data_ready <= 1'b0;
                resultado_valido <= 1'b0;  // Reset de la bandera solo cuando `out_tx_data_ready` esté desactivado
            end
        end
    end

endmodule
