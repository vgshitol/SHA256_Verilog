module hash #(parameter HASH_LENGTH = 8
) (

    /*-----------Inputs--------------------------------*/

    input                                    clock,  /* clock */
    input                                    reset,
    input  wire                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  wire                              address_read_complete,
    input  wire [ $clog2(HASH_LENGTH)-1:0]   hash_address,
    input  wire [31:0]                       hash_data,

    /*-----------Outputs--------------------------------*/

    output reg 	                            hash_write,
    output reg                              hash_vector_complete,  /* hash formation complete flag */
    output reg [255:0]                      hash_vector
);

    integer block_bit;

 	reg                              hash_vector_complete1;  /* hash formation complete flag */
    	reg                              hash_vector_complete2;  /* hash formation complete flag */
    	
 	reg                              enable1; 
    	reg                              enable2;  

	reg [ $clog2(HASH_LENGTH)-1:0]   hash_address1;
 	reg [ $clog2(HASH_LENGTH)-1:0]   hash_address2;

	

    always @(posedge clock)
        begin
            if(reset || !enable2)
                begin
                    hash_vector <= 0;
                    hash_vector_complete <= 0;
                end
            else if(!hash_vector_complete)
                begin
                    hash_vector <= hash_vector;
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                            hash_vector[block_bit + hash_address2*32] <= hash_data[block_bit];
                end
            else hash_vector <= hash_vector;
	
	hash_address1 <= hash_address;
	hash_address2 <= hash_address1;	

            hash_write <= 0;

            hash_vector_complete1 <= address_read_complete;
            hash_vector_complete2 <= hash_vector_complete1;
            hash_vector_complete  <= hash_vector_complete2;

	enable1 <= enable;
	enable2 <= enable1;	
        end

endmodule
