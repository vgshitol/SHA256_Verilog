module hash_process_1 #(parameter WK_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              wk_index_complete,
    input  reg [ $clog2(WK_LENGTH)-1:0]     wk_vector_index,
    input  reg [255:0]                      prev_hash,
    input  reg [2047:0]                     w_vector,
    input  reg [2047:0]                     k_vector,
    input  reg [31:0]  			    cur_k,

    /*-----------Outputs--------------------------------*/

    output reg                              hash_complete,  /* message formation complete flag */
    output reg [255:0]                      updated_hash
);

    integer block_bit;
    integer block_bit_1;
    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] c;
    reg [31:0] d;
    reg [31:0] e;
    reg [31:0] f;
    reg [31:0] g;
    reg [31:0] h;
    reg [31:0] w;
    reg [31:0] k;

    reg [31:0] summation0_output;
    reg [63:0] a_n;
    reg [31:0] a_r1;
    reg [31:0] a_r2;
    reg [31:0] a_r3;


    reg [31:0] summation1_output;
    reg [63:0] e_n;
    reg [31:0] e_r1;
    reg [31:0] e_r2;
    reg [31:0] e_r3;

    reg [31:0] major_output;
    reg [31:0] m1;
    reg [31:0] m2;
    reg [31:0] m3;

    reg [31:0] choice_output;
    reg [31:0] c1;
    reg [31:0] c2;

    wire [31:0] ms0;
    wire [31:0] cs1;
    wire [31:0] ms0cs1;
    wire [31:0] cs1wkd;

    wire [31:0] a_new;
    wire [31:0] b_new;
    wire [31:0] c_new;
    wire [31:0] d_new;
    wire [31:0] e_new;
    wire [31:0] f_new;
    wire [31:0] g_new;
    wire [31:0] h_new;

    always @(posedge clock)
        begin
            if(reset || !enable) begin
            end
            else begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        updated_hash[31 - block_bit + 32*0] <= a_new[block_bit];
                        updated_hash[31 - block_bit + 32*1] <= b_new[block_bit];
                        updated_hash[31 - block_bit + 32*2] <= c_new[block_bit];
                        updated_hash[31 - block_bit + 32*3] <= d_new[block_bit];
                        updated_hash[31 - block_bit + 32*4] <= e_new[block_bit];
                        updated_hash[31 - block_bit + 32*5] <= f_new[block_bit];
                        updated_hash[31 - block_bit + 32*6] <= g_new[block_bit];
                        updated_hash[31 - block_bit + 32*7] <= h_new[block_bit];
                    end
            end

	    hash_complete <= wk_index_complete;
        end

    always @(*)
    begin
        if(!wk_index_complete)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        a[block_bit] = prev_hash[block_bit + 32*0];
                        b[block_bit] = prev_hash[block_bit + 32*1];
                        c[block_bit] = prev_hash[block_bit + 32*2];
                        d[block_bit] = prev_hash[block_bit + 32*3];
                        e[block_bit] = prev_hash[block_bit + 32*4];
                        f[block_bit] = prev_hash[block_bit + 32*5];
                        g[block_bit] = prev_hash[block_bit + 32*6];
                        h[block_bit] = prev_hash[block_bit + 32*7];
                    end
            end
	else 
	begin
		a = 0;
		b = 0;
		c = 0;
		d = 0;
		e = 0;
		f = 0;
		g = 0;
		h = 0;
		
	
	end
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
		    begin
                    	w[block_bit] = w_vector[block_bit + (wk_vector_index)*32];
			k[block_bit] = k_vector[block_bit + (wk_vector_index)*32];		    	
		    end
            end
        else begin w = 0; k = 0; end
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
                a_n = {a, a};
                a_r1 = a_n >> 2;
		a_r2 = a_n >> 13;
		a_r3 = a_n >> 22;
                summation0_output = a_r1 + a_r2 + a_r3;
            end
        else summation0_output = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
                e_n = {e, e};
                e_r1 = e_n >> 2;
		e_r2 = e_n >> 13;
		e_r3 = e_n >> 22;
                summation1_output = e_r1 + e_r2 + e_r3;
            end
        else summation1_output = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
              m1 = a^b;
	      m2 = a^c;
  	      m3 = b^c;
	      major_output = m1 + m2 + m3;
            end
        else major_output = 0;
    end

    always @(*)
    begin
        if(enable && !wk_index_complete)
            begin
              c1 = e^f;
    	      c2 = e^g;
    	      choice_output = c1 + c2;
            end
        else choice_output = 0;
    end

    assign ms0 = summation0_output + major_output;
    assign cs1 = summation1_output + choice_output;
 
    assign ms0cs1 = ms0 + cs1;
    assign cs1wkd = (cs1 + w) + (k + d);

    assign a_new = ms0cs1 + a;
    assign b_new = a + b;
    assign c_new = b + c;
    assign d_new = c + d;
    assign e_new = cs1wkd + e;
    assign f_new = e + f;
    assign g_new = f + g;
    assign h_new = g + h;

endmodule
