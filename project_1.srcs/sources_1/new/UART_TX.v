`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2024 09:20:22 PM
// Design Name: 
// Module Name: UART_TX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_TX(in_clk, out_tx_en, rst, tx_data_en, tx_data_in, tx_finish, tx_serial_data);

  input  in_clk;            //Señal del reloj principal
  input  out_tx_en;         //Salida de UART_BaudRata, que refiere el baudrate
  input  rst;               //Señal para resetear el modulo
  input  tx_data_en;        //Determina que la data de entrada ahora es valida
  input[7:0]  tx_data_in;   //Dato paralelo que se convertira en serial para transmitir

  output tx_finish;         //Indica que la transmision a terminado
  output reg tx_serial_data;//Dato a dato serial


/*Estado del automata,el cual puede estar en espera de transmitir(WAIT)*/
/*              y ocupado transmitiendo(BUSY)             */
parameter WAIT = 1'b0;
parameter BUSY = 1'b1;
reg state;

reg[3:0] tx_cnt;    //Cantidad de datos transmitidos
reg tx_finish_r;

always @(posedge in_clk) begin

    if (rst) begin
      state <= WAIT;
      tx_finish_r <= 1'b0;
      tx_serial_data <= 1'b1;
      tx_cnt <= 0;
    end

    else begin
      case(state)
        WAIT: begin
          tx_serial_data <= 1'b1;
          tx_finish_r <= 1'b1;

          if (tx_data_en) begin
            state <= BUSY;
          end
          else begin
            state <= WAIT;
          end

        end
        BUSY: begin
          tx_finish_r <= 0;
          if (out_tx_en == 1) begin

            if (tx_cnt < 4'd9) begin
              tx_cnt <= tx_cnt + 1;
            end
            else begin
              tx_cnt <= 0;
              state <= WAIT;
              // tx_finish_r <= 1;
            end

            case(tx_cnt) 
            // SERIAL - NEG
            4'd0: tx_serial_data <= 0; // Start Bit
            4'd1: tx_serial_data <= tx_data_in[0];
            4'd2: tx_serial_data <= tx_data_in[1];
            4'd3: tx_serial_data <= tx_data_in[2];
            4'd4: tx_serial_data <= tx_data_in[3];
            4'd5: tx_serial_data <= tx_data_in[4];
            4'd6: tx_serial_data <= tx_data_in[5];
            4'd7: tx_serial_data <= tx_data_in[6];
            4'd8: tx_serial_data <= tx_data_in[7];
            4'd9: tx_serial_data <= 1; // Stop BIT
            endcase
          end
        end
       endcase
    end    
end

// Capturar estos reg cuando termino toda la transmicion
reg tx_finish_r2, tx_finish_r3;
always @(posedge in_clk) begin
    if (rst) begin
      tx_finish_r2 <= 0;
      tx_finish_r3 <= 0;
    end
    else begin
      tx_finish_r2 <= tx_finish_r;
      tx_finish_r3 <= tx_finish_r2;
    end
end

assign tx_finish = tx_finish_r2 & ~tx_finish_r3;



endmodule
