`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2024 09:29:16 PM
// Design Name: 
// Module Name: UART_BaudRate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:     Baudrate generator {CLOCK_RATE} (reloj interno) 
//                  {BAUD_RATE} tx/rx par, con rx oversample por defecto 16x 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_BaudRate
#(
    parameter CLOCK_RATE         = 100000000,   // board clock (por defecto 100MHz)
    parameter BAUD_RATE          = 9600,        // Baud Rate typical
    parameter RX_OVERSAMPLE_RATE = 16
)(
    input wire clk,   // board clock
    output reg rxClk, // baud rate para rx
    output reg txClk  // baud rate para tx
);

localparam RX_ACC_MAX   = CLOCK_RATE / (2 * BAUD_RATE * RX_OVERSAMPLE_RATE);
localparam TX_ACC_MAX   = CLOCK_RATE / (2 * BAUD_RATE);
localparam RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
localparam TX_ACC_WIDTH = $clog2(TX_ACC_MAX);

reg [RX_ACC_WIDTH-1:0] rx_counter = 0;
reg [TX_ACC_WIDTH-1:0] tx_counter = 0;

initial begin
    rxClk = 1'b0;
    txClk = 1'b0;
end

always @(posedge clk) begin
    // rx clock
    if (rx_counter == RX_ACC_MAX[RX_ACC_WIDTH-1:0]) begin
        rx_counter <= 0;
        rxClk      <= ~rxClk;
    end else begin
        rx_counter <= rx_counter + 1'b1;
    end

    // tx clock
    if (tx_counter == TX_ACC_MAX[TX_ACC_WIDTH-1:0]) begin
        tx_counter <= 0;
        txClk      <= ~txClk;
    end else begin
        tx_counter <= tx_counter + 1'b1;
    end
end

endmodule
    