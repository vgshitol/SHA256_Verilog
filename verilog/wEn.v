module msgEn (

    /*-----------Inputs--------------------------------*/

    input       clock,  /* clock */
    input 	    reset,		// resets
    input wire  start1,  /* Go message Signal*/
    input wire  start2,  /* Go message Signal*/

    /*-----------Outputs--------------------------------*/

    output reg enable  /* zero flag */
);

always @(posedge clock)
    begin
	enable <= 0;
	if(reset) enable <= 0;
    else enable <= (start1 && start2) || enable;
    end

endmodule
