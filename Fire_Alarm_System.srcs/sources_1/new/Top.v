module Top(
    output [6:0] seg,       // 7-segment display
    output reg [3:0] an,    // Enable for 7-segment
    output [2:0] led_ext,   // External LEDs for hazard states
    output buzzer,          // Buzzer output
    //output [7:0] JA,        //OLED PMOD Port
    output o_CS,          // OLED Chip Select
    output o_MOSI,        // OLED MOSI
    output o_SCK,         // OLED SCK
    output o_DC,          // OLED Data/Command
    output o_RES,         // OLED Reset
    output o_VCCEN,       // OLED VCC Enable
    output o_PMODEN,       // OLED PMOD Enable
    input clk,              // System clock
    input [3:0] hazard_sw,  // Hazard switches (noisy inputs)
    input reset,            // Reset signal
    input silence_sw        // Silence switch
);

    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter SCLK_DIVIDER = 20; //divide clock by 1
    
    parameter WAIT_3_US = 20; 
    parameter WAIT_100_MS = 600000;

    parameter NUM_COL = 96; //# of columns in OLED array
    parameter NUM_ROW = 64; //# of rows in OLED array

    parameter NUM_ASCII_COL  = NUM_COL / ASCII_COL_SIZE; //# of cols of ASCII chars (12 Default)
    parameter NUM_ASCII_ROW  = NUM_ROW / ASCII_ROW_SIZE; //# of rows of ASCII chars (8 Default)

    parameter ASCII_COL_SIZE = 8; //Number of x bits of ASCII char
    parameter ASCII_ROW_SIZE = 8; //Number of y bits of ASCII char


    parameter N_COLOR_BITS = 8;
    
        // Messages to display
    localparam [127:0] FIRE_MSG  = {"FIRE! EVACUATE"}; // Adjust for ASCII limits
    localparam [127:0] SMOKE_MSG = {"GAS EVACUATE"};
    localparam [127:0] CO_MSG    = {"CO ESCAPE"};
    localparam [127:0] IDLE_MSG  = {"SYSTEM STANDBY"}; // Default message
    localparam [7:0] FIRE_COLOR  = 8'hE0; // Red for fire
    localparam [7:0] SMOKE_COLOR = 8'h0F; // Gray for smoke
    localparam [7:0] CO_COLOR    = 8'h0C; // Black for CO
    localparam [7:0] IDLE_COLOR  = 8'h00; // White for idle
    
    reg [127:0] oled_message;   
    reg [7:0] background_color; 

    // Internal signals
    wire clk_1hz;
    wire [3:0] debounced_hazard_sw;
    wire [1:0] detector_out;
    wire [3:0] tens, ones;
    wire countdown_done;
    reg [3:0] current_digit;
    reg [1:0] digit_select;
    wire hazard_active = (detector_out == 2'b00 || detector_out == 2'b01 || detector_out == 2'b10);
    wire debounced_silence_sw;
    wire raw_buzzer; // Raw buzzer signal from BuzzerControl
    wire [6:0] seg_internal; // Internal signal for 7-segment display
        wire [1:0] s_MODE;
    wire s_TICK, s_START;

    //Wires to outputs
    wire s_READY, s_CS, s_MOSI, s_SCK, s_DC, s_RES, s_VCCEN, s_PMODEN;

    wire [WIDTH-1:0] s_background_color;

    wire [NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 1:0] s_ASCII;

    // Clock divider for 1 Hz
    ClockDivider clk_div (
        .clk(clk),
        .reset(reset),
        .clk_1hz(clk_1hz)
    );

    // Debounce switches
    generate
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin : debounce_loop
            Debounce debounce_inst (
                .clk(clk),
                .reset(reset),
                .noisy_signal(hazard_sw[i]),
                .clean_signal(debounced_hazard_sw[i])
            );
        end
    endgenerate

    // Debounce silence switch
    Debounce silence_debounce (
        .clk(clk),
        .reset(reset),
        .noisy_signal(silence_sw),
        .clean_signal(debounced_silence_sw)
    );

    // FSM for state detection
    FSM FSM1 (
        .clk(clk),
        .reset(reset),
        .hazard_sw(debounced_hazard_sw),
        .detector_out(detector_out)
    );

    // Countdown timer
    Countdown timer (
        .clk_1hz(clk_1hz),
        .reset(reset),
        .hazard_active(hazard_active),
        .tens(tens),
        .ones(ones),
        .done(countdown_done)
    );

    // External LED indicators for detector_out states
    assign led_ext[0] = (detector_out == 2'b00); // Fire
    assign led_ext[1] = (detector_out == 2'b01); // Smoke
    assign led_ext[2] = (detector_out == 2'b10); // CO

    // Buzzer control with raw output
    BuzzerControl BC1 (
        .clk(clk),
        .reset(reset),
        .status(detector_out),
        .buzzer(raw_buzzer)
    );

    // Silence switch logic to gate the buzzer output
    assign buzzer = raw_buzzer && !debounced_silence_sw;

    // Refresh clock divider for multiplexing (e.g., 1 kHz)
    reg [16:0] refresh_counter = 0;
    wire refresh_clk = refresh_counter[16];
    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
    end

    // Multiplexing logic for 7-segment display
    always @(posedge refresh_clk or posedge reset) begin
        if (reset) begin
            digit_select <= 2'b00;
            an <= 4'b1111; // All anodes off
        end else begin
            digit_select <= digit_select + 1; // Cycle through digits
            case (digit_select)
                2'b00: begin
                    an <= 4'b1011; // Enable first anode (leftmost)
                    current_digit <= countdown_done ? 4'd1 : tens; // Tens digit
                end
                2'b01: begin
                    an <= 4'b1101; // Enable second anode
                    current_digit <= countdown_done ? 4'd1 : ones; // Ones digit
                end
                2'b10: begin
                    an <= 4'b0111; // Enable third anode
                    current_digit <= countdown_done ? 4'd9 : 4'd0; // Static "911" or blank
                end
                default: begin
                    an <= 4'b1111; // Turn off all anodes
                    current_digit <= 4'd0;
                end
            endcase
        end
    end

    // Drive 7-segment display
    SevSeg display (
        .digit(current_digit),
        .seg(seg_internal) // Connect to internal wire
    );

    // Assign the internal signal to the output
    assign seg = seg_internal;
    
        always @(*) begin
    case (detector_out)
        2'b00: oled_message = FIRE_MSG;  // Fire detected
        2'b01: oled_message = SMOKE_MSG; // Smoke detected
        2'b10: oled_message = CO_MSG;    // CO detected
        default: oled_message = IDLE_MSG; // No hazard
    endcase
end

    always @(*) begin
        case (detector_out)
            2'b00: background_color = FIRE_COLOR;   // Fire
            2'b01: background_color = SMOKE_COLOR;  // Smoke
            2'b10: background_color = CO_COLOR;     // CO
            default: background_color = IDLE_COLOR; // Idle
        endcase
    end

//OLED_interface #(    ESTA ES LA QUE FUNCIONA
//    .WIDTH(8),
//    .N(8),
//    .SCLK_DIVIDER(20)  // Adjust for SPI clock speed
//) oled_inst (
//    .i_CLK(clk),                 // System clock
//    .i_RST(reset),               // Reset signal
//    .i_MODE(2'b10),              // Pixel display mode
//    .i_START(1'b1),              // Start signal (always enabled for dynamic updates)
//    .i_TEXT_COLOR(8'hFF),        // Text color (white)
//    .i_BACKGROUND_COLOR(8'h00), // Background color (black)
//    .i_ASCII(oled_message),      // Dynamic message
//    .o_READY(),                  // Optional: connect if needed
//    .o_CS(o_CS),
//    .o_MOSI(o_MOSI),
//    .o_SCK(o_SCK),
//    .o_DC(o_DC),
//    .o_RES(o_RES),
//    .o_VCCEN(o_VCCEN),
//    .o_PMODEN(o_PMODEN)
//);

    OLED_interface #(
        .WIDTH(8),
        .N(8),
        .SCLK_DIVIDER(20)
    ) oled_inst (
        .i_CLK(clk),
        .i_RST(reset),
        .i_MODE(2'b10),
        .i_START(1'b1),
        .i_TEXT_COLOR(8'hFF),           // Fixed text color (white)
        .i_BACKGROUND_COLOR(background_color), // Dynamic background color
        .i_ASCII(oled_message),         // Message to display
        .o_READY(),
        .o_CS(o_CS),
        .o_MOSI(o_MOSI),
        .o_SCK(o_SCK),
        .o_DC(o_DC),
        .o_RES(o_RES),
        .o_VCCEN(o_VCCEN),
        .o_PMODEN(o_PMODEN)
    );


endmodule