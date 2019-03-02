module go (

    /*-----------Inputs--------------------------------*/

    input       clock,  /* clock */
    input 	    reset,		// resets
    input wire  start,  /* Go message Signal*/
    input wire restart,
    /*-----------Outputs--------------------------------*/

    output reg enable  /* zero flag */
);

always @(posedge clock)
    begin
	enable <= 0;
	if(reset) enable <= 0;
    else enable <= (start || enable) && !restart;
    end

endmodule
