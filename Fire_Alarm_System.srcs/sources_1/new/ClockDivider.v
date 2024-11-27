`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 04:23:04 PM
// Design Name: 
// Module Name: ClockDivider
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


module ClockDivider(
    input clk,        // 100 MHz clock
    input reset,      // Reset signal
    output reg clk_1hz // 1 Hz clock output
);
    reg [26:0] counter = 0; // 27-bit counter for 100M/2 - 1

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_1hz <= 0;
        end else if (counter == 50000000 - 1) begin
            counter <= 0;
            clk_1hz <= ~clk_1hz; // Toggle the 1 Hz clock
        end else
            counter <= counter + 1;
    end
endmodule
