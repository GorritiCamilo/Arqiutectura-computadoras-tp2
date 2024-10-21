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


module UART_BaudRate(in_clk,out_tx_en,out_rx_en);
// El RX CLK esta Oversampled 16 

input wire in_clk;
output wire out_tx_en;
output wire out_rx_en;
/*Numero de ciclos necesarios para habilitar la recepcion/transmicion*/
parameter RX_MAX = 100_000_000/(115200 * 16);   // 100MHz es in_clk; 115200 es clk_rate
parameter TX_MAX = 100_000_000/(115200);

/*Contadores que van de 0 a RX/TX MAX*/
reg[15:0] rx_cnt = 0;
reg[15:0] tx_cnt = 0;

/*Señales de Enable cuando el contador llega a 0*/
assign out_rx_en = (rx_cnt == 0);
assign out_tx_en = (tx_cnt == 0);

always @(posedge in_clk) begin
    if (rx_cnt == RX_MAX) begin
      rx_cnt <= 0;
    end
    else begin
      rx_cnt <= rx_cnt+1;
    end
end

always @(posedge in_clk) begin
    if (tx_cnt == TX_MAX) begin
      tx_cnt <= 0;
    end
    else begin
      tx_cnt <= tx_cnt + 1;
    end  
end


endmodule