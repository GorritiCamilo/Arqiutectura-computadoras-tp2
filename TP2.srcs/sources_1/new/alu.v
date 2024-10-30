`timescale 1ns / 1ps


module alu
#(  
    // Parámetros
    parameter NB_INPUT_DATA = 4,   //Ancho Bus de datos de entrada
    parameter NB_OUTPUT_DATA = NB_INPUT_DATA,   //Ancho Bus de datos de salida
    parameter NB_OPERATION = 6  //Ancho Bus de operaciones
)
(   
    // Definición de Puertos del módulo
    input wire signed [NB_INPUT_DATA-1:0] in_data_a,  //Dato de 4 bits
    input wire signed [NB_INPUT_DATA-1:0] in_data_b,  //Dato de 4 bits
    input wire [NB_OPERATION-1:0] in_operation,  //Operando de 6 bits
    output wire signed [NB_OUTPUT_DATA-1:0] out_data  //Resultado de 4 bits
);

// Declaración de señales internas del módulo
reg [NB_OUTPUT_DATA-1:0] tmp;

// Definición de constantes para cada operación
localparam [5:0] SUMA      = 6'b100000;
localparam [5:0] RESTA     = 6'b100010;
localparam [5:0] AND       = 6'b100100;
localparam [5:0] OR        = 6'b100101;
localparam [5:0] XOR       = 6'b100110;
localparam [5:0] SRA       = 6'b000011;
localparam [5:0] SRL       = 6'b000010;
localparam [5:0] NOR       = 6'b100111;

always @(*) begin
    case (in_operation)
        SUMA:     tmp = in_data_a + in_data_b;  // Suma
        RESTA:    tmp = in_data_a - in_data_b;  // Resta
        AND:   tmp = in_data_a & in_data_b;  // AND
        OR:    tmp = in_data_a | in_data_b;  // OR
        XOR:   tmp = in_data_a ^ in_data_b;  // XOR
        SRA:   tmp = in_data_a >>> in_data_b;  // SRA (Shift Right Arithmetic)
        SRL:   tmp = in_data_a >> in_data_b;   // SRL (Shift Right Logical)
        NOR:   tmp = ~(in_data_a | in_data_b);  // NOR
        default:  tmp = {NB_OUTPUT_DATA{1'b1}};  // Todos los bits en 1
    endcase
end

assign out_data = tmp;

endmodule