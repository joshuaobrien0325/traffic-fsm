`timescale 1ns/1ps

module tb_traffic_fsm;

    localparam CLOCK_FREQ = 2;
    integer errors = 0;
    // signals which connect to the design
    reg clk = 0;
    reg n_rst = 0;
    wire north_red, north_yellow, north_green;
    wire west_red, west_yellow, west_green;

    
    traffic_fsm #(.CLOCK_FREQ(CLOCK_FREQ)) dut(
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

    // error check if both north and west are green at the same time 
    always @(posedge clk) begin
        if ( north_green && west_green) begin
            $display("Error at %0t: both directions are green", $time);
            errors = errors + 1;
        end
    end
    
    // a concatenated 6 bit value containing all lights 
    wire [5:0] lights = {north_red, north_yellow, north_green,
                         west_red, west_yellow, west_green};

    reg [5:0] expected_seq [0:7];
    integer   expected_len [0:7];

    // counts the time each pattern of lights should be on for each state
    initial begin 
        expected_seq[0] = 6'b100_100; expected_len[0] = 5 * CLOCK_FREQ;
        expected_seq[1] = 6'b110_100; expected_len[1] = 5 * CLOCK_FREQ;
        expected_seq[2] = 6'b001_100; expected_len[2] = 60 * CLOCK_FREQ;
        expected_seq[3] = 6'b010_100; expected_len[3] = 5 * CLOCK_FREQ;
        expected_seq[4] = 6'b100_100; expected_len[4] = 5 * CLOCK_FREQ;
        expected_seq[5] = 6'b100_110; expected_len[5] = 5 * CLOCK_FREQ;
        expected_seq[6] = 6'b100_001; expected_len[6] = 60 * CLOCK_FREQ;
        expected_seq[7] = 6'b100_010; expected_len[7] = 5 * CLOCK_FREQ;
    end


    reg [5:0] prev_lights = 6'b100_100; // pattern for the previous clock edge starting at the default state
    integer idx =0;                     // an index of the currently shown pattern
    integer hold = 0;                   // cycles that the current pattern has lasted for 
    reg started = 0;                    // 0 until the first pattern change, the reset isnt timed


    always @(posedge clk) begin
        if (n_rst) begin
            if (lights == prev_lights) begin
                hold = hold + 1;  // keeps counting until the pattern has changed
            end else begin
    
                // when lights change the expected number of cycles is checked against the actual number
                if (started && hold != expected_len[idx]) begin
                    $display("Error at %0t: pattern %b lasted %0d cycles, expected %0d",
                             $time, prev_lights, hold, expected_len[idx]);
                    errors = errors + 1;
                end

                // increases to the next pattern, wraps to 0 if the current idx is 7
                // the next pattern is then checked against its expected pattern
                idx = (idx + 1) % 8; 
                if (lights != expected_seq[idx]) begin
                    $display("Error at %0t: lights are %b, expected %b",
                              $time, lights, expected_seq[idx]);
                    errors = errors + 1;
                end

                // timer begins for the new pattern
                prev_lights = lights;
                hold        = 1;
                started     = 1;
            end
        end else begin
            //while reset is active, return the checkers to their default state
            prev_lights = 6'b100_100;
            idx         = 0;
            hold        = 0;
            started     = 0;
        end
    end



   
    initial begin
        // apply reset for 3 clock cycles reset is released on falling edge to avoid race with design
        n_rst = 0; 
        repeat (3) @(posedge clk);
        @(negedge clk) n_rst = 1;

        // clock runs for 600 cycles
        repeat (600) @(posedge clk);

        // resets during operation, when North is green, then resets mid-phase
        wait (north_green == 1);
        repeat (5) @(posedge clk);
        @(negedge clk) n_rst = 0;

        // holds rest for 2 full cycles and then checks all lights go back to red
        repeat (2) @(posedge clk);
        @(negedge clk);
        if (lights != 6'b100_100) begin
            $display("Error at %0t: lights are %b during reset, expected 100100",
                      $time, lights);
            errors = errors + 1;
        end

        // relesease n_rst and then runs 2 more cycles two check it resets correctly
        n_rst = 1;
        repeat (2 * 150 * CLOCK_FREQ) @(posedge clk);
        if (errors == 0)
            $display("Test Passed");
        else 
            $display("Test failed: %0d errors", errors);

        $finish;
    end
endmodule