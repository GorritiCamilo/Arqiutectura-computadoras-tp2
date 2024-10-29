`timescale 1ns / 1ps

module test_baud_rate_generator;

    // Definición de las señales del testbench
    reg tb_clk;                          // Señal de reloj para la simulación
    wire tb_tx_enable;                   // Señal de habilitación para transmisión (salida del DUT)
    wire tb_rx_enable;                   // Señal de habilitación para recepción (salida del DUT)

    // Parámetros para la simulación
    parameter NB_COUNTER = 16;           // Ancho de los contadores (igual al módulo DUT)
    parameter CLOCK_RATE = 100_000_000;  // Frecuencia de reloj en Hz
    parameter BAUD_RATE = 115200;        // Tasa de baudios

    // Tiempos teóricos de habilitación
    real expected_tx_period = 1e9 / BAUD_RATE;                 // Tiempo teórico de TX en ns
    real expected_rx_period = 1e9 / (BAUD_RATE * 16);          // Tiempo teórico de RX en ns

    // Variables para registrar los tiempos reales de activación
    time last_tx_time, last_rx_time;
    time tx_period_actual, rx_period_actual;

    // Flags para saltar la primera activación (en tiempo 0)
    reg first_tx_enable = 1;
    reg first_rx_enable = 1;

    // Instancia del módulo uart_baud_rate_generator (Device Under Test - DUT)
    uart_baud_rate_generator
    #(
        .NB_COUNTER(NB_COUNTER),
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE)
    )
    dut (
        .in_clk(tb_clk),
        .out_tx_enable(tb_tx_enable),
        .out_rx_enable(tb_rx_enable)
    );

    // Generador de reloj
    initial begin
        tb_clk = 0;
        forever #5 tb_clk = ~tb_clk; // Período de 10ns -> 100MHz
    end

    // Bloque de simulación
    initial begin
        // Inicialización de variables
        last_tx_time = 0;
        last_rx_time = 0;

        // Inicio de la simulación
        $display("Iniciando la simulacion...");

        // Monitorear las señales para verlas durante la simulación
        $monitor("Time: %0t | TX_Enable: %b | RX_Enable: %b", $time, tb_tx_enable, tb_rx_enable);

        // Simula durante 1 segundo
        #1_000_000_000;

        // Terminar la simulación
        $display("Simulación completada.");
        $finish;
    end

    // Monitorear y verificar los tiempos de habilitación de TX y RX
    always @(posedge tb_tx_enable) begin
        if (!first_tx_enable) begin
            tx_period_actual = $time - last_tx_time;
            last_tx_time = $time;

            // Comparar con el valor esperado (tolerancia de 1%)
            if (tx_period_actual < (expected_tx_period * 0.99) || tx_period_actual > (expected_tx_period * 1.01)) begin
                $display("ERROR: TX_Enable activado a tiempo incorrecto. Tiempo real: %0t ns, Esperado: %0t ns", tx_period_actual, expected_tx_period);
            end else begin
                $display("TX_Enable correcto. Tiempo real: %0t ns, Esperado: %0t ns", tx_period_actual, expected_tx_period);
            end
        end else begin
            // Ignorar la primera activación
            first_tx_enable = 0;
            last_tx_time = $time;
        end
    end

    always @(posedge tb_rx_enable) begin
        if (!first_rx_enable) begin
            rx_period_actual = $time - last_rx_time;
            last_rx_time = $time;

            // Comparar con el valor esperado (tolerancia de 1%)
            if (rx_period_actual < (expected_rx_period * 0.99) || rx_period_actual > (expected_rx_period * 1.01)) begin
                $display("ERROR: RX_Enable activado a tiempo incorrecto. Tiempo real: %0t ns, Esperado: %0t ns", rx_period_actual, expected_rx_period);
            end else begin
                $display("RX_Enable correcto. Tiempo real: %0t ns, Esperado: %0t ns", rx_period_actual, expected_rx_period);
            end
        end else begin
            // Ignorar la primera activación
            first_rx_enable = 0;
            last_rx_time = $time;
        end
    end

endmodule
