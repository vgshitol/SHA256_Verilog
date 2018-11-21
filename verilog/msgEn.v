module msgEn (

    /*-----------Inputs--------------------------------*/

    input       clock,  /* clock */
    input 	reset,		// resets
    input wire  start,  /* Go message Signal*/

    /*-----------Outputs--------------------------------*/

    output reg enable  /* zero flag */
);

always @(posedge clock)
    begin
	enable <=0;
        if(reset) enable <= 0;
        else if (!start && !enable) enable <= 0;
        else enable <= enable;
    end

endmodule
