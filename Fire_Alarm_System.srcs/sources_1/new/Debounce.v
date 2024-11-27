`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 04:23:04 PM
// Design Name: 
// Module Name: Debounce
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


module Debounce(
    input clk,
    input reset,
    input noisy_signal,
    output reg clean_signal
    );

    reg [19:0] counter; // Adjust width based on debounce time
    reg stable_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            stable_state <= noisy_signal;
            clean_signal <= noisy_signal;
        end
        else if (noisy_signal != stable_state) begin
            counter <= counter + 1;
            if (counter == 20'd999999) begin // Adjust count for debounce time
                stable_state <= noisy_signal;
                clean_signal <= noisy_signal;
                counter <= 0;
            end
        end
        else begin
            counter <= 0;
        end
    end
endmodule