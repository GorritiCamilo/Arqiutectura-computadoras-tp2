module uart_test_top (Sys_clk, rst_n, SW3, RX, TX, led_on);

    // ------------------------------
    // A Module For Testing UART VALID
    // SW5 - TX
    // SW6 - RX
    // if SW3 pressed, Send Certain Char Through TX
    // Then Wait For 1 Second
    // If Receiving Data From RX
    // Send It Back
    // -------------------------------

    input wire Sys_clk;
    input wire rst_n;
    input wire SW3;
    input wire RX;
    output wire TX;
    output wire led_on;

    assign led_on = ~SW3;  // Using LED to denote

    // ------------The MAIN CONTROL LOGIC
    reg main_state;
    parameter IDLE = 1'b0;
    parameter SEND = 1'b1;
    parameter wait_time = 50_000_000;
    reg [31:0] wait_time_cnt;

    // Mensajes de Log para la FSM
    initial begin
        $display("UART Test Module Initialized");
    end

    always @(posedge clk_out1) begin
        if (!rst_n) begin
            main_state <= 0;
            tx_data_in <= 0;
            wait_time_cnt <= 0;
            $display("[%0t] Reset Active, Initializing...", $time);
        end else begin
            case(main_state)
                IDLE: begin
                    tx_data_en <= 0;
                    if (~SW3) begin
                        wait_time_cnt <= wait_time_cnt + 1;
                    end else begin
                        wait_time_cnt <= 0;
                    end 

                    if (wait_time_cnt > wait_time) begin  // Hold SW3 For 0.5s
                        main_state <= SEND;
                        tx_data_in <= 8'b11111111;
                        $display("[%0t] SW3 held for 0.5s, sending predefined data: %b", $time, tx_data_in);
                    end

                    if (rx_finish) begin
                        tx_data_in <= rx_data;
                        main_state <= SEND;
                        $display("[%0t] Received data: %b, sending back...", $time, rx_data);
                    end
                end
                SEND: begin
                    tx_data_en <= 1;
                    main_state <= IDLE;
                    $display("[%0t] Data sent: %b, returning to IDLE", $time, tx_data_in);
                end
            endcase
        end
    end

    // -------------The CLK WIZARD
    clk_wiz_0 clk_wiz_test (
        .clk_out1(clk_out1),    // output clk_out1
        .reset(!rst_n),         // input reset
        .locked(locked),        // output locked
        .clk_in1(Sys_clk)       // input clk_in1
    );

    // --------------The UART BAUD RATE GENERATOR
    wire tx_enable;
    wire rx_enable;

    uart_baud_rate_generator #(
        .CLOCK_RATE(100_000_000),
        .BAUD_RATE(115200)
    ) baud_gen_inst (
        .in_clk(clk_out1),
        .out_tx_enable(tx_enable),
        .out_rx_enable(rx_enable)
    );

    // --------------The UART RX Module
    wire [7:0] rx_data;
    wire rx_finish;

    UART_RX uart_rx_inst (
        .in_clk(clk_out1),
        .in_rx_en(rx_enable),
        .rst(!rst_n),           // Reset directo sin módulo externo
        .rx_serial_data(RX),
        .rx_finish(rx_finish),
        .rx_data(rx_data)
    );

    // Log para recepción de datos UART
    always @(posedge rx_finish) begin
        $display("[%0t] RX Module: Data received: %b", $time, rx_data);
    end

    // --------------The UART TX Module
    reg [7:0] tx_data_in;
    reg tx_data_en;
    wire tx_finish;

    UART_TX uart_tx_inst (
        .in_clk(clk_out1),
        .out_tx_en(tx_enable),
        .rst(!rst_n),           // Reset directo sin módulo externo
        .tx_data_en(tx_data_en),
        .tx_data_in(tx_data_in),
        .tx_finish(tx_finish),
        .tx_serial_data(TX)
    );

    // Log para finalización de transmisión UART
    always @(posedge tx_finish) begin
        $display("[%0t] TX Module: Transmission complete for data: %b", $time, tx_data_in);
    end

endmodule
