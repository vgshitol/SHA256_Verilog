module hash #(parameter HASH_LENGTH = 8
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              address_read_complete,
    input  reg [ $clog2(HASH_LENGTH)-1:0]   hash_address,
    input  reg [31:0]                       hash_data,
    input  reg [255:0]                      prev_hash_vector,

    /*-----------Outputs--------------------------------*/

    output reg [7:0]                        hash_write,
    output reg                              hash_vector_complete,  /* hash formation complete flag */
    output reg [255:0]                      hash_vector
);

    integer block_bit;
    integer length_bit;

    always @(posedge clock)
        begin
            if(reset || !enable) begin
                hash_vector = 0;
                hash_vector_complete <= 0;
            end
            else begin
                hash_write <= 0;
                for (block_bit = 0 ; block_bit < hash_address*32; block_bit = block_bit + 1)
                            hash_vector[block_bit] <= prev_hash_vector[block_bit];

                if(!address_read_complete) for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    hash_vector[block_bit + hash_address*32] <= hash_data[block_bit];

                if (address_read_complete) hash_vector_complete <= 1;
            end
        end

endmodule
