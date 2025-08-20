module cordic_pipelined #(
    parameter MODE                    = 0,     // 0=ROTATION, 1=VECTORING
    parameter STAGES                  = 16,
    parameter CORDIC_WIDTH            = 16,
    parameter CORDIC_INTERNAL_WIDTH   = 20,
    parameter SFIXED_ZERO             = 32'd0,
    parameter SFIXED_PI               = 32'h3243F6A8,
    parameter SFIXED_PI_OVER_2        = 32'h1921FB54,
    parameter SFIXED_TWO_PI           = 32'h6487ED51
)(
    input  wire                                clk,
    input  wire                                rst,
    input  wire                                valid_in,
    input  wire  signed [CORDIC_WIDTH-1:0]      x_in,
    input  wire  signed [CORDIC_WIDTH-1:0]      y_in,
    input  wire  signed [CORDIC_INTERNAL_WIDTH-1:0] z_in,
    output reg                                 valid_out,
    output wire signed [CORDIC_WIDTH-1:0]      x_out,
    output wire signed [CORDIC_WIDTH-1:0]      y_out,
    output wire signed [CORDIC_WIDTH-1:0]      z_out
);

    wire signed [31:0] ANGLES [0:31];
    assign ANGLES[0]  = 32'h0000C90F;
    assign ANGLES[1]  = 32'h00007253;
    assign ANGLES[2]  = 32'h00003924;
    assign ANGLES[3]  = 32'h00001C9A;
    assign ANGLES[4]  = 32'h00000E4D;
	 assign ANGLES[5]  = 32'h00000726;
    assign ANGLES[6]  = 32'h00000393;
    assign ANGLES[7]  = 32'h000001CA;
    assign ANGLES[8]  = 32'h000000E5;
    assign ANGLES[9]  = 32'h00000072;
    assign ANGLES[10] = 32'h00000039;
    assign ANGLES[11] = 32'h0000001C;
	  assign ANGLES[12] = 32'h0000000E;
    assign ANGLES[13] = 32'h00000007;
    assign ANGLES[14] = 32'h00000003;
    assign ANGLES[15] = 32'h00000001;
    assign ANGLES[16] = 32'h00000001;
    assign ANGLES[17] = 32'h00000000;
    assign ANGLES[18] = 32'h00000000;
	  assign ANGLES[19] = 32'h00000000;
    assign ANGLES[20] = 32'h00000000;
    assign ANGLES[21] = 32'h00000000;
    assign ANGLES[22] = 32'h00000000;
    assign ANGLES[23] = 32'h00000000;
    assign ANGLES[24] = 32'h00000000;
    assign ANGLES[25] = 32'h00000000;
    assign ANGLES[26] = 32'h00000000;
    assign ANGLES[27] = 32'h00000000;
	  assign ANGLES[28] = 32'h00000000;
    assign ANGLES[29] = 32'h00000000;
    assign ANGLES[30] = 32'h00000000;
    assign ANGLES[31] = 32'h00000000;

    // -------------------------------------------------------------------------
    // Simulation-only angle function (not synthesized)
    // -------------------------------------------------------------------------

    // Declare pipeline arrays
	  reg signed [CORDIC_INTERNAL_WIDTH-1:0] x_pipe [0:STAGES];
    reg signed [CORDIC_INTERNAL_WIDTH-1:0] y_pipe [0:STAGES];
    reg signed [CORDIC_INTERNAL_WIDTH-1:0] z_pipe [0:STAGES];
    reg [1:0]  quadrant_stages [0:STAGES];
    reg        valid_pipe      [0:STAGES];

    reg signed [CORDIC_INTERNAL_WIDTH-1:0] x_corrected,y_corrected,z_wrapped;
	 
	 // Stage 0
    always @(posedge clk) begin
      if (rst) begin
         x_pipe[0] <= 0; y_pipe[0] <= 0; z_pipe[0] <= 0;
         quadrant_stages[0] <= 2'b00;
         valid_pipe[0] <= 0;
      end else begin
         z_wrapped = z_in;
         if (z_wrapped >  SFIXED_PI)   z_wrapped =  z_wrapped-SFIXED_TWO_PI;
         else if (z_wrapped <= -SFIXED_PI) z_wrapped =  z_wrapped+SFIXED_TWO_PI;

         if((z_wrapped>=SFIXED_ZERO)&&(z_wrapped<=SFIXED_PI_OVER_2)) begin
            quadrant_stages[0]<=2'b00;  z_pipe[0]<=z_wrapped;
         end
			else if((z_wrapped>SFIXED_PI_OVER_2)&&((z_wrapped<=SFIXED_PI)||(z_wrapped>= -SFIXED_PI_OVER_2))) begin
            quadrant_stages[0]<=2'b01;  z_pipe[0]<=SFIXED_PI-z_wrapped;
         end
         else if((z_wrapped<SFIXED_ZERO)&&(z_wrapped>=-SFIXED_PI_OVER_2)) begin
            quadrant_stages[0]<=2'b11;  z_pipe[0]<= -z_wrapped;
         end
			else begin
            quadrant_stages[0]<=2'b10;  z_pipe[0]<= -(SFIXED_PI+z_wrapped);
         end

         x_pipe[0] <= {{(CORDIC_INTERNAL_WIDTH-CORDIC_WIDTH){x_in[CORDIC_WIDTH-1]}},x_in};
         y_pipe[0] <= {{(CORDIC_INTERNAL_WIDTH-CORDIC_WIDTH){y_in[CORDIC_WIDTH-1]}},y_in};
         valid_pipe[0] <= valid_in;
      end
   end

   // Iterative stages
   genvar i;
   generate
      for (i=0; i<STAGES; i=i+1) begin : STAGES_GEN
         reg signed [CORDIC_INTERNAL_WIDTH-1:0] angle, dx, dy;
         reg sigma;
         always @(posedge clk) begin
           angle = ANGLES[i];
           sigma = (MODE==0) ? z_pipe[i][CORDIC_INTERNAL_WIDTH-1] : y_pipe[i][CORDIC_INTERNAL_WIDTH-1];
            dx    = (y_pipe[i] >>> i);
            dy    = (x_pipe[i] >>> i);

            if (sigma==0) begin
               x_pipe[i+1] <= x_pipe[i] - dx;
               y_pipe[i+1] <= y_pipe[i] + dy;
               z_pipe[i+1] <= z_pipe[i] - angle;
            end else begin
              x_pipe[i+1] <= x_pipe[i] + dx;
               y_pipe[i+1] <= y_pipe[i] - dy;
               z_pipe[i+1] <= z_pipe[i] + angle;
            end
            valid_pipe[i+1]      <= valid_pipe[i];
            quadrant_stages[i+1] <= quadrant_stages[i];
         end
      end
   endgenerate

   // Final quadrant correction
	 always @(posedge clk) begin
      case(quadrant_stages[STAGES])
         2'b00:  begin x_corrected <=  x_pipe[STAGES]; y_corrected <= y_pipe[STAGES]; end
         2'b11:  begin x_corrected <=  x_pipe[STAGES]; y_corrected <= -y_pipe[STAGES];end
         default:begin x_corrected <= -x_pipe[STAGES]; y_corrected <=  y_pipe[STAGES];end
      endcase
      valid_out <= valid_pipe[STAGES];
   end
	
   assign x_out = x_corrected[CORDIC_WIDTH-1:0];
   assign y_out = y_corrected[CORDIC_WIDTH-1:0];
   assign z_out = z_pipe[STAGES][CORDIC_WIDTH-1:0];

endmodule
