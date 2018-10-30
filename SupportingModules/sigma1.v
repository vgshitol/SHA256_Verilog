// Verilog file for the fsm for the pattern matching engine

module sigma1 (
	input 	     	  clock,		// 100 Mhz clock
	input 	     	  reset,		// resets
	input  reg [31:0] word,			// Word Vectors Single Word
	output reg [31:0] sigma1_output   	// Sigma 0 output
);  

reg [31:0] next_sigma1_output;
reg [63:0] word_new;
wire [31:0] w_r1;
wire [31:0] w_r2;
wire [31:0] w_r3;

assign w_r1 = word_new >> 17;
assign w_r2 = word_new >> 19;
assign w_r3 = word >> 10;

always @(posedge clock or negedge reset)
   begin
   if (!reset)
      	sigma1_output <= 0;
   else
      begin
	sigma1_output <= next_sigma1_output;
      end
end

always @(word)
   begin
	word_new = {word, word};	
   end	

always @(w_r1 or w_r2 or w_r3)
begin
 next_sigma1_output = w_r1 + w_r2 + w_r3;
end   
endmodule

