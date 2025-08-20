`timescale 1ns/1ps

module tb_cordic_oscillator;

  // Parameters
  parameter WIDTH = 16;   // Data width
  parameter ITER  = 20;   // Iterations

  // Inputs
  reg clk;
  reg rst;

 // Outputs
  wire signed [WIDTH-1:0] cos_out;
  wire signed [WIDTH-1:0] sin_out;

  // Instantiate the DUT
  cordic_oscillator #(
    .WIDTH(WIDTH),
    .ITER(ITER)
  ) uut (
    .clk(clk),
    .rst(rst),
    .cos_out(cos_out),
    .sin_out(sin_out)
  );

  // Clock generation: 10ns period (100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset and stimulus
  initial begin
    // Initialize reset
    rst = 1;
    #20;           // keep reset high for 20ns
    rst = 0;       // release reset
  end

 // Run simulation for enough cycles to observe several sine periods
  initial begin
    #2000;   // simulate for 2000ns (adjust if needed)
    $stop;   // stop simulation (so ISim doesn’t run forever)
  end

endmodule
