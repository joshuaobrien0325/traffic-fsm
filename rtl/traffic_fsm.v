`timescale 1ns/1ps

module traffic_fsm #(
    parameter CLOCK_FREQ = 100
    )(
        // port list
        input wire clk,
        input wire n_rst,
        output reg north_red,
        output reg north_yellow,
        output reg north_green,
        output reg west_red,
        output reg west_yellow,
        output reg west_green

    );
    // state encodings
    localparam[2:0] North_Next =  3'd0,
                    Start_North = 3'd1,
                    North =       3'd2,
                    Stop_North =  3'd3,
                    West_Next =   3'd4,
                    Start_West =  3'd5,
                    West =        3'd6,
                    Stop_West =   3'd7;

    reg [2:0] state;

    // counter which can hold up to 1 minute of clock cycle's
    localparam Max_Count = CLOCK_FREQ * 60;
    reg[$clog2(Max_Count +1) - 1:0] counter;

    // a task to change once the counter reaches the allotted time
    task change_state(input [2:0] to_state, input integer seconds);
        begin 
            if (counter == seconds * CLOCK_FREQ - 1) begin
                counter <= 0;
                state <= to_state;
            end
        end
    endtask

    // beginning of the always block which runs on every positive edge
    // state, counter and light outputs are all registered i.e. flip-flops
    // the reset n_rst is synchronous with the clock
    always @(posedge clk) begin

        // If a reset is triggered west and north will both go red
        if (!n_rst) begin

            state <= North_Next;
            counter <= 0;
            north_red    <= 1'b1;
            north_yellow <= 1'b0;
            north_green  <= 1'b0;
            west_red     <= 1'b1;
            west_yellow  <= 1'b0;
            west_green   <= 1'b0;
        end else begin

        // setting the default conditions for all light outputs
            north_red     <= 1'b0; 
            north_yellow  <= 1'b0; 
            north_green   <= 1'b0; 
            west_red      <= 1'b0; 
            west_yellow   <= 1'b0; 
            west_green    <= 1'b0; 

            // incrementing counter by one on each positive edge
            counter <= counter + 1'b1;

            // beginning of the case statement which switches through each traffic light state
            case (state)

                // both directions red
                North_Next: begin
                    north_red <= 1'b1;
                    west_red  <= 1'b1;
                    change_state(Start_North, 5);
                end

                // North has yellow and red lights to signal it will soon be green
                Start_North: begin
                    north_red    <= 1'b1;
                    north_yellow <= 1'b1;
                    west_red     <= 1'b1;
                    change_state(North, 5);
                end

                // North lights are now green 
                North: begin
                    north_green <= 1'b1;
                    west_red    <= 1'b1;
                    change_state(Stop_North, 60);
                end

                // North now goes yellow to signal drivers to prepare to stop
                Stop_North: begin
                    north_yellow <= 1'b1;
                    west_red     <= 1'b1;
                    change_state(West_Next, 5);
                end

                //Transitioning from north to west lights both directions red
                West_Next: begin
                    north_red <= 1'b1;
                    west_red  <= 1'b1;
                    change_state(Start_West, 5);
                end

                // West now shows red and yellow letting drivers know it will soon be green
                Start_West: begin
                    north_red <= 1'b1;
                    west_red  <= 1'b1;
                    west_yellow  <= 1'b1;
                    change_state(West, 5);
                end

                // west drivers can now process 
                West: begin
                    north_red  <= 1'b1;
                    west_green <= 1'b1;
                    change_state(Stop_West, 60);
                end
               
                // yellow lights for west drivers telling them to prepare to stop
                Stop_West: begin
                    north_red <= 1'b1;
                    west_yellow <= 1'b1;
                    change_state(North_Next, 5);
                end
                
                // sets the default state to North_Next
                default: state <= North_Next;
            endcase
        end
    end

endmodule

     
