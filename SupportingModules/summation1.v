// Verilog file for the fsm for the pattern matching engine

module summation1 (
	input 	     	  clock,		// 100 Mhz clock
	input 	     	  reset,		// resets
	input  reg [31:0] a,			// Hash Vectors Single Hash
	output reg [31:0] sumation1_output   	// summation 0 output
);  

reg [31:0] next_sumation1_output;
reg [63:0] a_new;
wire [31:0] a_r1;
wire [31:0] a_r2;
wire [31:0] a_r3;

assign a_r1 = a_new >> 6;
assign a_r2 = a_new >> 11;
assign a_r3 = a_new >> 25;

always @(posedge clock or negedge reset)
   begin
   if (!reset) sumation1_output <= 0;
   else sumation1_output <= next_sigma0_output;
end

always @(word)
   begin
	a_new = {a, a};
   end	

always @(a_r1 or a_r2 or a_r3)
begin
	next_sumation1_output = a_r1 + a_r2 + a_r3;
end   
endmodule

