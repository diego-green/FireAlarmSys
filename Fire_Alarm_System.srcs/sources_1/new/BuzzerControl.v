`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 04:23:04 PM
// Design Name: 
// Module Name: BuzzerControl
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


module BuzzerControl(
    input clk,             // System clock
    input reset,           // Reset signal
    input [1:0] status,    // Alarm status: 00 (Gas), 01 (CO), 10 (Fire), 11 (Idle)
    output reg buzzer      // Buzzer output signal
    );

    reg [31:0] counter;    // Counter for clock division
    reg [31:0] threshold;  // Threshold for toggling buzzer
    reg active;            // Active signal for buzzer logic

    // Set frequency thresholds based on desired output frequencies
    always @ (status)
    begin
        case (status)
            2'b11: begin
                threshold = 0;    // No toggling for idle
                active = 0;       // Disable buzzer
            end
            2'b01: begin
                threshold = 50000;  // CO: 1 kHz frequency
                active = 1;         // Enable buzzer
            end
            2'b10: begin
                threshold = 25000;  // Fire: 2 kHz frequency
                active = 1;         // Enable buzzer
            end
            2'b00: begin
                threshold = 12500;  // Gas: 4 kHz frequency
                active = 1;         // Enable buzzer
            end
            default: begin
                threshold = 0;      // Default to no sound
                active = 0;         // Disable buzzer
            end
        endcase
    end

    // Generate buzzer output
    always @ (posedge clk or posedge reset)
    begin
        if (reset) begin
            counter <= 0;
            buzzer <= 0;
        end
        else if (active == 0) begin
            counter <= 0;           // Reset counter when inactive
            buzzer <= 0;            // Explicitly disable buzzer
        end
        else begin
            if (counter >= threshold) begin
                counter <= 0;
                buzzer <= ~buzzer;  // Toggle buzzer signal
            end
            else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
