// Verilog file for the fsm for the pattern matching engine

module choice (
    input 	     	  clock,		    // 100 Mhz clock
    input 	     	  reset,		    // resets
    input  reg [31:0] e,			    // Hash Vectors Single Hash
    input  reg [31:0] f,			    // Hash Vectors Single Hash
    input  reg [31:0] g,			    // Hash Vectors Single Hash
    output reg [31:0] choice_output   	// choice
);

    reg  [31:0] next_choice_output;
    wire [31:0] c1;
    wire [31:0] c2;

    assign c1 = e^f;
    assign c2 = e^g;
    assign next_choice_output = c1 + c2;

    always @(posedge clock or negedge reset)
        begin
            if (!reset) choice_output <= 0;
            else choice_output <= next_choice_output;
        end

endmodule

