module k_vector #(parameter K_LENGTH = 64 , parameter K_VECTOR_LENGTH = 2048
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              address_read_complete,
    input  reg [ $clog2(K_LENGTH)-1:0]      k_address,
    input  reg [31:0]                       k_data,
    input  reg [K_VECTOR_LENGTH-1:0]        prev_k_vector,

    /*-----------Outputs--------------------------------*/

    output reg [7:0]                        k_write,
    output reg                              k_vector_complete,  /* hash formation complete flag */
    output reg [K_VECTOR_LENGTH-1:0]        k_vector,
    output reg [31:0]			    cur_k_value				
);

    integer block_bit;
    integer length_bit;

    always @(posedge clock)
        begin
            if(reset || !enable) begin
                k_vector = 0;
                k_vector_complete <= 0;
            end
            else begin
                k_write <= 0;
                for (block_bit = 0 ; block_bit < k_address*32; block_bit = block_bit + 1)
                            k_vector[block_bit] <= prev_k_vector[block_bit];

                if(!address_read_complete) for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
			k_vector[block_bit + k_address*32] <= k_data[block_bit];
		        cur_k_value[block_bit] <= k_data[block_bit];
		    end	
                if (address_read_complete) k_vector_complete <= 1;
            end
        end

endmodule
