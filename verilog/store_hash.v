module store_hash #(parameter HASH_LENGTH = 8
) (

    /*-----------Inputs--------------------------------*/

    input                                    clock,  /* clock */
    input                                    reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(HASH_LENGTH)-1:0]   h_address,
    input  wire [255:0]                      hash_vector,
    
    /*-----------Outputs--------------------------------*/
    output reg [31:0]                       h_data,
    output reg	                            h_write,
    output reg                              h_vector_complete,  /* hash formation complete flag */
    output reg [ $clog2(HASH_LENGTH)-1:0]   h_output_address
    );

    integer block_bit;

    always @(posedge clock)
    begin
            if(reset || !enable) begin
		h_vector_complete <= 0;
                h_write <= 0;
		h_output_address <= 0;
            end
            else if(!h_vector_complete) 		  
	    begin
                h_write <= 1;
		    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
		        h_data[block_bit] <= hash_vector[block_bit + h_address*32];
			h_output_address <= h_address;
    		    end	
            end
            h_vector_complete <= address_read_complete;
    end
endmodule
