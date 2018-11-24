//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// DUT

module MyDesign #(parameter OUTPUT_LENGTH       = 8,
                  parameter MAX_MESSAGE_LENGTH  = 55,
                  parameter NUMBER_OF_Ks        = 64,
                  parameter NUMBER_OF_Hs        = 8 ,
                  parameter SYMBOL_WIDTH        = 8  )
            (

            //---------------------------------------------------------------------------
            // Control
            //
            output reg                                   dut__xxx__finish     ,
            input  wire                                  xxx__dut__go         ,  
            input  wire  [ $clog2(MAX_MESSAGE_LENGTH)-1:0] xxx__dut__msg_length ,

            //---------------------------------------------------------------------------
            // Message memory interface
            //
            output reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   dut__msg__address  ,  // address of letter
            output reg                                      dut__msg__enable   ,
            output reg                                      dut__msg__write    ,
            input  wire [7:0]                               msg__dut__data     ,  // read each letter
            
            //---------------------------------------------------------------------------
            // K memory interface
            //
            output reg  [ $clog2(NUMBER_OF_Ks)-1:0]     dut__kmem__address  ,
            output reg                                  dut__kmem__enable   ,
            output reg                                  dut__kmem__write    ,
            input  wire [31:0]                          kmem__dut__data     ,  // read data

            //---------------------------------------------------------------------------
            // H memory interface
            //
            output reg  [ $clog2(NUMBER_OF_Hs)-1:0]     dut__hmem__address  ,
            output reg                                  dut__hmem__enable   ,
            output reg                                  dut__hmem__write    ,
            input  wire [31:0]                          hmem__dut__data     ,  // read data


            //---------------------------------------------------------------------------
            // Output data memory 
            //
            output reg  [ $clog2(OUTPUT_LENGTH)-1:0]    dut__dom__address  ,
            output reg  [31:0]                          dut__dom__data     ,  // write data
            output reg                                  dut__dom__enable   ,
            output reg                                  dut__dom__write    ,


            //-------------------------------
            // General
            //
            input  wire                 clk             ,
            input  wire                 reset  

            );


  //---------------------------------------------------------------------------
  //
  //<<<<----  YOUR CODE HERE    ---->>>>

	
	wire msg_address_read_complete;
	wire message_vector_complete;
	wire [511:0] message_vector;

	wire [$clog2(NUMBER_OF_Hs)-1:0]   hash_vector_index;  // index of hash
	wire hash_address_complete;
	wire [255:0] hash_vector;
	wire hash_vector_complete;

	wire k_address_complete;
	wire k_vector_complete;
	wire [31:0] cur_k_value;

	wire w_vector_complete;
	wire [31:0] cur_w_value;
	
	wire [ $clog2(NUMBER_OF_Ks)-1:0]   wk_vector_index;  // index of w
	wire wk_vector_enable;
	wire wk_vector_index_complete;
	wire [255:0] updated_hash;
	wire hash_complete;

	wire [$clog2(NUMBER_OF_Hs)-1:0]   hash_output_vector_index;  // index of hash
	wire hash_output_address_complete;
	wire hash_store_complete;

/** Creating Message Vector **/	
msgEn msgSignal(.clock(clk), .reset(reset), .start(xxx__dut__go), .enable(dut__msg__enable));
	
counter #(.MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)) msgCounter (.clock(clk), .reset(reset), .start(dut__msg__enable), .msg_length(xxx__dut__msg_length), .read_address(dut__msg__address), .read_complete(msg_address_read_complete));

msg_vector #(.MSG_LENGTH(MAX_MESSAGE_LENGTH)) msgBlock (.clock(clk), .reset(reset), .enable(dut__msg__enable), .address_read_complete(msg_address_read_complete), .msg_address(dut__msg__address), 
 .msg_data(msg__dut__data), .msg_write(dut__msg__write), .message_vector(message_vector), .message_vector_complete(message_vector_complete));

/** Creating Hash Vector **/
msgEn hashSignal (.clock(clk), .reset(reset), .start(xxx__dut__go), .enable(dut__hmem__enable));

counter_h #(.NUMBER_OF_BLOCKS(NUMBER_OF_Hs)) Hcounter (.clock(clk), .reset(reset), .start(dut__hmem__enable), .read_address(dut__hmem__address), .read_complete(hash_address_complete));

hash #(.HASH_LENGTH(NUMBER_OF_Hs)) hashBlock (.clock(clk), .reset(reset), .enable(dut__hmem__enable), .address_read_complete(hash_address_complete), .hash_address(dut__hmem__address), .hash_write(dut__hmem__write), 
.hash_data(hmem__dut__data) , .hash_vector_complete(hash_vector_complete), .hash_vector(hash_vector));
	  
/** Creating K Vector **/
wEn wkSignal(.clock(clk), .reset(reset), .start1(message_vector_complete), .start2(hash_vector_complete), .enable(dut__kmem__enable));
	
counter_wk #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Ks)) wkCounter (.clock(clk), .reset(reset), .start(dut__kmem__enable), .read_address(dut__kmem__address), .read_complete(k_address_complete));

k_vector #(.K_LENGTH(NUMBER_OF_Ks)) kBlock (.clock(clk), .reset(reset), .enable(dut__kmem__enable), .address_read_complete(k_address_complete), .k_address(dut__kmem__address), .k_write(dut__kmem__write), 
.k_data(kmem__dut__data) , .k_vector_complete(k_vector_complete), .cur_k_value(cur_k_value));

/** Creating the W Vector**/
w64 #(.W_LENGTH(NUMBER_OF_Ks)) wBlock (.clock(clk), .reset(reset), .enable(dut__kmem__enable), .w_vector_index(dut__kmem__address), .w_index_complete(k_address_complete), .message_vector(message_vector), 
.w_vector_complete(w_vector_complete), .cur_w(cur_w_value));

/** Processing Hash Update**/
msgEn hashUpdateSignal(.clock(clk), .reset(reset), .start(dut__kmem__enable), .enable(wk_vector_enable));
	
counter_wk #(.MAX_MESSAGE_LENGTH(NUMBER_OF_Ks)) hashUpdateCounter (.clock(clk), .reset(reset), .start(wk_vector_enable), .read_address(wk_vector_index), .read_complete(wk_vector_index_complete));
	
hash_update #(.WK_LENGTH(NUMBER_OF_Ks)) hashUpdate (.clock(clk), .reset(reset), .enable(wk_vector_enable), .wk_index_complete(wk_vector_index_complete) , .wk_vector_index(wk_vector_index),
.prev_hash(hash_vector) , .hash_complete(hash_complete) , .updated_hash(updated_hash) , .cur_k(cur_k_value), .cur_w(cur_w_value));
	
/** Storing the Hash Vector **/
msgEn storeHashSignal(.clock(clk), .reset(reset), .start(hash_complete), .enable(dut__dom__enable));
	
counter_h #(.NUMBER_OF_BLOCKS(NUMBER_OF_Hs)) storeHashCounter (.clock(clk), .reset(reset), .start(dut__dom__enable), .read_address(hash_output_vector_index), .read_complete(hash_output_address_complete));

store_hash #(.HASH_LENGTH(NUMBER_OF_Hs)) hashStore (.clock(clk), .reset(reset), .enable(dut__dom__enable), .address_read_complete(hash_output_address_complete), .h_address(hash_output_vector_index), .hash_vector(updated_hash), .h_write(dut__dom__write), 
.h_data(dut__dom__data) , .h_vector_complete(dut__xxx__finish), .h_output_address(dut__dom__address));

endmodule




