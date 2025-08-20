module cordic_stage #(
    parameter integer ITERATION = 0,
    parameter MODE      = 0,
    parameter CORDIC_INTERNAL_WIDTH = 20
)(
    input  wire                               clk,
    input  wire signed [CORDIC_INTERNAL_WIDTH-1:0] x_in,
    input  wire signed [CORDIC_INTERNAL_WIDTH-1:0] y_in,
    input  wire signed [CORDIC_INTERNAL_WIDTH-1:0] z_in,
    output reg  signed [CORDIC_INTERNAL_WIDTH-1:0] x_out,
    output reg  signed [CORDIC_INTERNAL_WIDTH-1:0] y_out,
    output reg  signed [CORDIC_INTERNAL_WIDTH-1:0] z_out
);

// -----------------------------------------------------------------------------
// Function to return arctan(1/2^i) in fixed-point (CORDIC_FRAC fractional bits)
// -----------------------------------------------------------------------------
function automatic signed [31:0] cordic_angle;
    input integer i;
    // CORDIC_FRAC = 14 in your design
    real angle_real;
begin
    angle_real = $atan(1.0 / (2.0**i));              // compute arctan
    cordic_angle = $rtoi( angle_real * (2.0**14) );  // convert to fixed-point (Q2.14)
end
endfunction

    // ---------------------------------------------------------------------
    // internal combinational variables
    // ---------------------------------------------------------------------
    reg signed [CORDIC_INTERNAL_WIDTH-1:0] dx;
    reg signed [CORDIC_INTERNAL_WIDTH-1:0] dy;
    reg signed [CORDIC_INTERNAL_WIDTH-1:0] angle;
    reg sigma;

    always @(posedge clk) begin
       // get the angle constant for this iteration
        angle = cordic_angle[ITERATION];

        // sigma = sign bit (MODE dependent)
        if (MODE == 0)
            sigma = z_in[CORDIC_INTERNAL_WIDTH-1]; // take MSB of z
        else
            sigma = y_in[CORDIC_INTERNAL_WIDTH-1]; // take MSB of y

        // right shifts
        dx = (y_in >>> ITERATION);
        dy = (x_in >>> ITERATION);
		  
		  // update values
        if (sigma == 1'b0) begin
            x_out <= x_in - dx;
            y_out <= y_in + dy;
            z_out <= z_in - angle;
        end
        else begin
            x_out <= x_in + dx;
            y_out <= y_in - dy;
            z_out <= z_in + angle;
        end
    end
endmodule
