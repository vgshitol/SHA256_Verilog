module w64 #(parameter W_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              w_index_complete,
    input  reg [511:0]                      message_vector,
    input  reg [ $clog2(W_LENGTH)-1:0]      w_vector_index,
    input  reg [2047:0]                     prev_w_vector,

    /*-----------Outputs--------------------------------*/

    output reg                              w_vector_complete,  /* message formation complete flag */
    output reg [2047:0]                     w_vector,
    output reg [31:0]			    cur_w
);

    integer block_bit;
    reg  [31:0] s0w_r1;
    reg  [31:0] s0w_r2;
    reg  [31:0] s0w_r3;
    reg  [31:0] s0word;
    reg  [63:0] double_s0word;
    reg  [31:0] sigma0_s0word;
    
    reg  [31:0] s1w_r1;
    reg  [31:0] s1w_r2;
    reg  [31:0] s1w_r3;
    reg  [31:0] s1word;
    reg  [63:0] double_s1word;
    reg  [31:0] sigma1_s1word;

    reg  [31:0] word16;
    reg  [31:0] word7;
    wire [31:0] new_word;

    integer word_16_bit;
    always @(posedge clock)
        begin

            if(reset || !enable) w_vector <=0;
	    else if(enable && !w_vector_complete && w_vector_index < 16)
            begin
		    for (word_16_bit = 0 ; word_16_bit < w_vector_index*32; word_16_bit = word_16_bit + 1)
                            w_vector[word_16_bit] <= prev_w_vector[word_16_bit];

		    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1) 
		    begin
                        w_vector[block_bit + w_vector_index*32] <= message_vector[511-31 + block_bit - w_vector_index*32];
			cur_w[block_bit] <= message_vector[511-31 + block_bit - w_vector_index*32];
		    end

		    for (word_16_bit = (w_vector_index+1)*32 ; word_16_bit < 2047; word_16_bit = word_16_bit + 1)
                            w_vector[word_16_bit] <= prev_w_vector[word_16_bit];
	    end
	    else if(enable && !w_vector_complete && w_vector_index >= 16)
            begin
    			for (word_16_bit = 0 ; word_16_bit < w_vector_index*32; word_16_bit = word_16_bit + 1)
                            w_vector[word_16_bit] <= prev_w_vector[word_16_bit];

                        for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1) 
			    w_vector[block_bit + w_vector_index*32] <= new_word[block_bit];
			    
    			for (word_16_bit = (w_vector_index+1)*32 ; word_16_bit < 2047; word_16_bit = word_16_bit + 1)
                            w_vector[word_16_bit] <= prev_w_vector[word_16_bit];

			cur_w <= new_word;
 	    end
	    else w_vector <= prev_w_vector;
            
            w_vector_complete <= w_index_complete;		                    
        end

    always @(*)
    begin
        if(enable && !w_vector_complete && w_vector_index >= 16)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    s0word[block_bit] = w_vector[block_bit + (w_vector_index-15)*32];

                double_s0word = {s0word, s0word};
                s0w_r1 = double_s0word >> 7;
                s0w_r2 = double_s0word >> 18;
                s0w_r3 = s0word >> 3;
                sigma0_s0word = (s0w_r1 ^ s0w_r2) ^ s0w_r3;
            end
        else sigma0_s0word = 0;
    end

    always @(*)
        begin
            if(enable && !w_vector_complete && w_vector_index >= 16)
                begin
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                        s1word[block_bit] = w_vector[block_bit + (w_vector_index-2)*32];

                    double_s1word = {s1word, s1word};
                    s1w_r1 = double_s1word >> 17;
                    s1w_r2 = double_s1word >> 19;
                    s1w_r3 = s1word >> 10;
                    sigma1_s1word = (s1w_r1 ^ s1w_r2) ^ s1w_r3;
                end
            else sigma1_s1word = 0;
        end

    always @(*)
        begin
            if(enable && !w_vector_complete && w_vector_index >= 16)
                begin
                    for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                        begin
			word16[block_bit] = w_vector[block_bit + (w_vector_index-16)*32];
                    	word7[block_bit] = w_vector[block_bit + (w_vector_index-7)*32];
                	end
                end
            else begin word16 = 0; word7 = 0; end
        end

    assign new_word = (sigma0_s0word + sigma1_s1word) + (word16 + word7);


endmodule
