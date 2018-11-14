module hash_process_1 #(parameter WK_LENGTH = 64
) (

    /*-----------Inputs--------------------------------*/

    input                                   clock,  /* clock */
    input                                   reset,
    input  reg                              enable, /* Previous Enable to decide what to do for the next enable*/
    input  reg                              wk_index_complete,
    input  reg [ $clog2(WK_LENGTH)-1:0]     wk_vector_index,
    input  reg [255:0]                      prev_hash,
    input  reg [31:0]  			    cur_w,
    input  reg [31:0]  			    cur_k,

    /*-----------Outputs--------------------------------*/

    output reg                              hash_complete,  /* message formation complete flag */
    output reg [255:0]                      updated_hash
);

    integer block_bit;
    integer block_bit_1;

    reg [31:0] h0;
    reg [31:0] h1;
    reg [31:0] h2;
    reg [31:0] h3;
    reg [31:0] h4;
    reg [31:0] h5;
    reg [31:0] h6;
    reg [31:0] h7;

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
    wire [31:0] t1;
    wire [31:0] t2;

    reg [31:0] a_new;
    reg [31:0] b_new;
    reg [31:0] c_new;
    reg [31:0] d_new;
    reg [31:0] e_new;
    reg [31:0] f_new;
    reg [31:0] g_new;
    reg [31:0] h_new;

    always @(posedge clock)
        begin
            if(reset) begin
		updated_hash <= 0;
	    end
            else if(!enable) begin
		updated_hash <= prev_hash;
	    end
            else begin
		if(!wk_index_complete) begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        updated_hash[block_bit + 32*0] <= a_new[block_bit];
                        updated_hash[block_bit + 32*1] <= b_new[block_bit];
                        updated_hash[block_bit + 32*2] <= c_new[block_bit];
                        updated_hash[block_bit + 32*3] <= d_new[block_bit];
                        updated_hash[block_bit + 32*4] <= e_new[block_bit];
                        updated_hash[block_bit + 32*5] <= f_new[block_bit];
                        updated_hash[block_bit + 32*6] <= g_new[block_bit];
                        updated_hash[block_bit + 32*7] <= h_new[block_bit];
                    end
		end
		else 
		begin 
		for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        updated_hash[block_bit + 32*7] <= a_new[block_bit];
                        updated_hash[block_bit + 32*6] <= b_new[block_bit];
                        updated_hash[block_bit + 32*5] <= c_new[block_bit];
                        updated_hash[block_bit + 32*4] <= d_new[block_bit];
                        updated_hash[block_bit + 32*3] <= e_new[block_bit];
                        updated_hash[block_bit + 32*2] <= f_new[block_bit];
                        updated_hash[block_bit + 32*1] <= g_new[block_bit];
                        updated_hash[block_bit + 32*0] <= h_new[block_bit];
                    end
		end
	    end
	    hash_complete <= wk_index_complete;
        end

    always @(*)
    begin
        if(!hash_complete)
            begin
                for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
                    begin
                        a[block_bit] = updated_hash[block_bit + 32*0];
                        b[block_bit] = updated_hash[block_bit + 32*1];
                        c[block_bit] = updated_hash[block_bit + 32*2];
                        d[block_bit] = updated_hash[block_bit + 32*3];
                        e[block_bit] = updated_hash[block_bit + 32*4];
                        f[block_bit] = updated_hash[block_bit + 32*5];
                        g[block_bit] = updated_hash[block_bit + 32*6];
                        h[block_bit] = updated_hash[block_bit + 32*7];
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

assign w = (hash_complete) ? 0 : cur_w;
assign k = (hash_complete) ? 0 : cur_k;

    always @(*)
    begin
        if(enable && !hash_complete)
            begin
                a_n = {a, a};
                a_r1 = a_n >> 2;
		a_r2 = a_n >> 13;
		a_r3 = a_n >> 22;
                summation0_output = a_r1 ^ a_r2 ^ a_r3;
            end
        else summation0_output = 0;
    end

    always @(*)
    begin
        if(enable && !hash_complete)
            begin
                e_n = {e, e};
                e_r1 = e_n >> 6;
		e_r2 = e_n >> 11;
		e_r3 = e_n >> 25;
                summation1_output = (e_r1 ^ e_r2) ^ e_r3;
            end
        else summation1_output = 0;
    end

    always @(*)
    begin
        if(enable && !hash_complete)
            begin
              m1 = a & b;
	      m2 = a & c;
  	      m3 = b & c;
	      major_output = (m1 ^ m2) ^ m3;
            end
        else major_output = 0;
    end

    always @(*)
    begin
        if(enable && !hash_complete)
            begin
              c1 = e & f;
    	      c2 = (~e) & g;
    	      choice_output = c1 ^ c2;
            end
        else choice_output = 0;
    end

    assign t2 = summation0_output + major_output;
    assign t1 = (summation1_output + choice_output) + (w + k) + h;

always @(*)
begin
for (block_bit = 0 ; block_bit < 32; block_bit = block_bit + 1)
	begin
	h0[block_bit] = prev_hash[block_bit + 32*0];
	h1[block_bit] = prev_hash[block_bit + 32*1];
	h2[block_bit] = prev_hash[block_bit + 32*2];
	h3[block_bit] = prev_hash[block_bit + 32*3];
	h4[block_bit] = prev_hash[block_bit + 32*4];
	h5[block_bit] = prev_hash[block_bit + 32*5];
	h6[block_bit] = prev_hash[block_bit + 32*6];
	h7[block_bit] = prev_hash[block_bit + 32*7];
	end

if(!wk_index_complete)
begin
    a_new = t1 + t2;
    b_new = a;
    c_new = b;
    d_new = c;
    e_new = t1 + d;
    f_new = e;
    g_new = f;
    h_new = g;
end
else if(!hash_complete)
begin
    a_new = a + h0;
    b_new = b + h1;
    c_new = c + h2;
    d_new = d + h3;
    e_new = e + h4;
    f_new = f + h5;
    g_new = g + h6;
    h_new = h + h7;
end
else if(!hash_complete)
begin
    a_new = a;
    b_new = b;
    c_new = c;
    d_new = d;
    e_new = e;
    f_new = f;
    g_new = g;
    h_new = h;
end
end

endmodule
