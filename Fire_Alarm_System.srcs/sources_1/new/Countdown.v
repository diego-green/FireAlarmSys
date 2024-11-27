`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 04:23:04 PM
// Design Name: 
// Module Name: Countdown
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


module Countdown(
    input clk_1hz,        // 1 Hz clock
    input reset,          // Reset signal
    input hazard_active,  // Trigger for countdown
    output reg [3:0] tens, // Tens digit
    output reg [3:0] ones, // Ones digit
    output reg done       // Signal when countdown reaches 0
);

    always @(posedge clk_1hz or posedge reset) begin
        if (reset) begin
            tens <= 4'd1;  // Initialize tens to 1
            ones <= 4'd0;  // Initialize ones to 0
            done <= 0;
        end else if (hazard_active) begin
            if (tens == 0 && ones == 0) begin
                done <= 1; // Countdown complete
            end else if (ones == 0) begin
                ones <= 9;           // Reset ones to 9
                if (tens > 0) tens <= tens - 1; // Decrement tens only if greater than 0
            end else begin
                ones <= ones - 1;    // Decrement ones
            end
        end
    end
endmodule
