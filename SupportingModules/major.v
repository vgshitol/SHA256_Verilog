// Verilog file for the fsm for the pattern matching engine

module major (
	input 	     	  clock,			// 100 Mhz clock
	input 	     	  reset,			// resets
	input  reg [31:0] a,			    // Hash Vectors Single Hash
	input  reg [31:0] b,			    // Hash Vectors Single Hash
	input  reg [31:0] c,			    // Hash Vectors Single Hash
	output reg [31:0] major_output   	// major output
);  

reg [31:0] next_major_output;
wire [31:0] m1;
wire [31:0] m2;
wire [31:0] m3;

assign m1 = a^b;
assign m2 = a^c;
assign m3 = b^c;
assign next_major_output = m1 + m2 + m3;

always @(posedge clock or negedge reset)
    begin
        if (!reset) major_output <= 0;
        else major_output <= next_major_output;
    end
endmodule

