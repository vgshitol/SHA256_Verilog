module k_vector #(parameter K_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              address_read_complete,
    input  reg [ $clog2(K_LENGTH)-1:0]      k_address,
    input  reg [31:0]                       k_data,
   
    /*-----------Outputs--------------------------------*/

    output reg [7:0]                        k_write,
    output reg                              k_vector_complete,  /* hash formation complete flag */
    output reg [31:0]			    cur_k_value				
);

    integer block_bit;
    integer length_bit;

    always @(posedge clock)
        begin
            if(reset || !enable) begin
		cur_k_value <= 0;
                k_vector_complete <= 0;
            end
            else begin
                k_write <= 0;
                if(!address_read_complete) for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
		        cur_k_value[block_bit] <= k_data[block_bit];
		    end	
            end
            k_vector_complete <= address_read_complete;
        end

endmodule
