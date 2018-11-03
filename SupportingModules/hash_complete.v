module hash_complete (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg [255:0]                      prev_hash,
    input  reg [255:0]                      updated_hash,
   
    /*-----------Outputs--------------------------------*/

    output reg                              hash_complete,  /* message formation complete flag */
    output reg [255:0]                      final_hash
);

integer block_bit;

  always @(posedge clock)
        begin
            if(reset || !enable) begin
		final_hash <= prev_hash;
            end
            else
		begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        final_hash[block_bit + 32*7] <= prev_hash[block_bit + 32*0] +  updated_hash[block_bit + 32*0];
                        final_hash[block_bit + 32*6] <= prev_hash[block_bit + 32*1] +  updated_hash[block_bit + 32*1];
                        final_hash[block_bit + 32*5] <= prev_hash[block_bit + 32*2] +  updated_hash[block_bit + 32*2];
                        final_hash[block_bit + 32*4] <= prev_hash[block_bit + 32*3] +  updated_hash[block_bit + 32*3];
                        final_hash[block_bit + 32*3] <= prev_hash[block_bit + 32*4] +  updated_hash[block_bit + 32*4];
                        final_hash[block_bit + 32*2] <= prev_hash[block_bit + 32*5] +  updated_hash[block_bit + 32*5];
                        final_hash[block_bit + 32*1] <= prev_hash[block_bit + 32*6] +  updated_hash[block_bit + 32*6];
                        final_hash[block_bit + 32*0] <= prev_hash[block_bit + 32*7] +  updated_hash[block_bit + 32*7];
                    end
		end
	    hash_complete <= enable;
        end
endmodule

