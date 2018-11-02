module msgEn (

    /*-----------Inputs--------------------------------*/

    input       clock,  /* clock */
    input 	    reset,		// resets
    input  reg  start,  /* Go message Signal*/

    /*-----------Outputs--------------------------------*/

    output reg enable  /* zero flag */
);

always @(posedge clock)
    begin
        if(reset) enable <= 0;
        else
            begin
                if(!start && !enable) enable <= 0;
                else enable <= 1;
            end
    end

endmodule