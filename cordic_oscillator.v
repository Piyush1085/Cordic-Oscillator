module cordic_oscillator #(
    parameter SFIXED_WIDTH = 32,           // replace <SIZE> with sfixed_internal_t width
    parameter CORDIC_WIDTH = 16,           // width of sfixed_t
    parameter SFIXED_TWO_PI = 32'h6487ED51,         // constant in same format as tuning_word
    parameter SFIXED_ZERO   = 32'd0,
    parameter CORDIC_GAIN   = 16'h26DD          // value used in x_fixed initialization
	 )(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      ce,
    input  wire signed [SFIXED_WIDTH-1:0] tuning_word,
    output wire signed [CORDIC_WIDTH-1:0] sin_out,
    output wire signed [CORDIC_WIDTH-1:0] cos_out,
    output wire                      valid_out
);
    //----------------------------------
    // Phase accumulator
    //----------------------------------
    reg signed [SFIXED_WIDTH-1:0] phase_acc = {SFIXED_WIDTH{1'b0}};
    reg signed [SFIXED_WIDTH-1:0] next_phase;

    always @(posedge clk) begin
        if (rst) begin
            phase_acc <= {SFIXED_WIDTH{1'b0}};
        end
		  else if (ce) begin
            next_phase = phase_acc + tuning_word;
            if (next_phase > SFIXED_TWO_PI)
                phase_acc <= SFIXED_ZERO;
            else
                phase_acc <= next_phase;
        end
    end
	 
	 
    //----------------------------------
    // Fixed Initial Vector
    //----------------------------------
    // NOTE: convert real_to_sfixed to a constant value at synthesis time
    wire signed [CORDIC_WIDTH-1:0] x_fixed  = CORDIC_GAIN;  // normalized
    wire signed [CORDIC_WIDTH-1:0] y_fixed  = {CORDIC_WIDTH{1'b0}};

   //----------------------------------
    // CORDIC Pipeline
    //----------------------------------
    wire signed [CORDIC_WIDTH-1:0] x_out;
    wire signed [CORDIC_WIDTH-1:0] y_out;
    wire        valid_pipe;
	 
	 cordic_pipelined cordic_inst (
        .clk       (clk),
        .rst       (rst),
        .x_in      (x_fixed),
        .y_in      (y_fixed),
        .z_in      (phase_acc[19:0]),
        .x_out     (x_out),
        .y_out     (y_out),
        .z_out     (),          // open
        .valid_in  (1'b1),
        .valid_out (valid_pipe)
    );
	 
	 //----------------------------------
    // Outputs
    //----------------------------------
    assign sin_out   = y_out;
    assign cos_out   = x_out;
    assign valid_out = valid_pipe;

endmodule

	 
