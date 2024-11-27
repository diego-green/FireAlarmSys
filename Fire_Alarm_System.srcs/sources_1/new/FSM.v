`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 04:23:04 PM
// Design Name: 
// Module Name: FSM
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

module FSM (
    input clk, // Clock signal
    input reset, // Reset input (active-high)
    input [3:0] hazard_sw, // Binary input from switches
    output reg [1:0] detector_out // Output of the sequence detector
);

    // State encoding
    parameter fire = 3'b000,
              smoke = 3'b001,
              CO = 3'b011,
              IDLE = 3'b100,
              Check_sw = 3'b101,
              R = 3'b110;

    // Registers to hold the current and next state
    reg [2:0] current_state, next_state;

    // State register logic with reset
    always @(posedge clk or posedge reset) begin
        if (reset) 
            current_state <= IDLE; // Reset to IDLE state
        else
            current_state <= next_state; // Transition to next state
    end

    // Next state logic
    always @(current_state, hazard_sw) begin
        case (current_state)
            IDLE: begin
                next_state = Check_sw; // Always transition to Check_sw
            end

            Check_sw: begin
                if (hazard_sw == 1) 
                    next_state = fire;
                else if (hazard_sw == 2)
                    next_state = smoke;
                else if (hazard_sw == 4)
                    next_state = CO;
                else
                    next_state = IDLE; // Default to IDLE
            end

            fire: begin
                if (reset) 
                    next_state = IDLE; // Reset takes priority
                else
                    next_state = fire; // Remain in fire state
            end

            smoke: begin
                if (reset) 
                    next_state = IDLE; // Reset takes priority
                else
                    next_state = smoke; // Remain in smoke state
            end

            CO: begin
                if (reset) 
                    next_state = IDLE; // Reset takes priority
                else
                    next_state = CO; // Remain in CO state
            end
            
            default: next_state = IDLE; // Default to IDLE state
        endcase
    end

    // Output logic based on current state
    always @(current_state) begin
        case (current_state)
            IDLE: detector_out <= 2'b11; // Example output for IDLE
            Check_sw: detector_out <= 2'b11; // Example output for Check_sw
            fire: detector_out <= 2'b00; // Output for fire state
            smoke: detector_out <= 2'b01; // Output for smoke state
            CO: detector_out <= 2'b10; // Output for CO state
            default: detector_out <= 2'b11; // Default output
        endcase
    end

endmodule