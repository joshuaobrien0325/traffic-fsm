`timescale 1ns/1ps

module tb_traffic_fsm;
// signals which connect to the design
    reg clk = 0;
    reg n_rst = 0;
    wire north_red, north_yellow, north_green;
    wire west_red, west_yellow, west_green;


    traffic_fsm #(.CLOCK_FREQ(2)) dut(
        .clk(clk),
        .n_rst(n_rst),
        .north_red(north_red),
        .north_yellow(north_yellow),
        .north_green(north_green),
        .west_red(west_red),
        .west_yellow(west_yellow),
        .west_green(west_green)
    );

    // clock period lasts 10ns
    always #5 clk = ~clk;

    initial begin

        n_rst = 0;
        repeat (3) @(posedge clk);
        @(negedge)n_rst = 1;

        repeat (600) @(posedge clk);

        $finish;
    end
endmodule