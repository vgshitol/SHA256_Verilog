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

	reg go;
	reg finish;
	reg msgEnable;
   	reg [ $clog2(MAX_MESSAGE_LENGTH)-1:0] 	msgLength;
	reg [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   msgAddress;  // address of letter
        reg                                     msgWrite;
        reg [7:0]                               msgData;  // read each letter
    
	reg 					hashEnable;
	reg [ $clog2(NUMBER_OF_Hs)-1:0]   	hashAddress;  // address of letter
        reg                                     hashWrite;
	reg [31:0]                              hashData;  // read each letter

/**Register All Inputs and Outputs **/
/**Inputs **/
registerIO #(.REGISTER_LENGTH(1)) registerGO(.clock(clk), .reset(reset), .input_to_register(xxx__dut__go), .outputRegister(go));
registerIO #(.REGISTER_LENGTH($clog2(MAX_MESSAGE_LENGTH))) registerMSGLength(.clock(clk), .reset(reset), .input_to_register(xxx__dut__msg_length), .outputRegister(msgLength));
registerIO #(.REGISTER_LENGTH(8)) registerMSGData(.clock(clk), .reset(reset), .input_to_register(msg__dut__data), .outputRegister(msgData));
registerIO #(.REGISTER_LENGTH(32)) registerHashData(.clock(clk), .reset(reset), .input_to_register(hmem__dut__data), .outputRegister(hashData));

/**Outputs**/
registerIO #(.REGISTER_LENGTH(1)) registerMSGEnable(.clock(clk), .reset(reset), .input_to_register(msgEnable), .outputRegister(dut__msg__enable));
registerIO #(.REGISTER_LENGTH($clog2(MAX_MESSAGE_LENGTH))) registerMSGAddress(.clock(clk), .reset(reset), .input_to_register(msgAddress), .outputRegister(dut__msg__address));
registerIO #(.REGISTER_LENGTH(1)) registerMSGWrite(.clock(clk), .reset(reset), .input_to_register(msgWrite), .outputRegister(dut__msg__write));

registerIO #(.REGISTER_LENGTH(1)) registerHashEnable(.clock(clk), .reset(reset), .input_to_register(hashEnable), .outputRegister(dut__hmem__enable));
registerIO #(.REGISTER_LENGTH($clog2(NUMBER_OF_Hs))) registerHashAddress(.clock(clk), .reset(reset), .input_to_register(hashAddress), .outputRegister(dut__hmem__address));
registerIO #(.REGISTER_LENGTH(1)) registerHashWrite(.clock(clk), .reset(reset), .input_to_register(hashWrite), .outputRegister(dut__hmem__write));
/*
registerIO #(.REGISTER_LENGTH(1)) registerKEnable(.clock(clk), .reset(reset), .input_to_register(hashEnable), .outputRegister(dut__hmem__enable));
registerIO #(.REGISTER_LENGTH($clog2(NUMBER_OF_Hs))) registerKAddress(.clock(clk), .reset(reset), .input_to_register(hashAddress), .outputRegister(dut__hmem__address));
registerIO #(.REGISTER_LENGTH(1)) registerKWrite(.clock(clk), .reset(reset), .input_to_register(hashWrite), .outputRegister(dut__hmem__write));
*/
registerIO #(.REGISTER_LENGTH(1)) registerFINISH(.clock(clk), .reset(reset), .input_to_register(finish), .outputRegister(dut__xxx__finish));

/** Creating Message Vector **/	
go msgSignal(.clock(clk), .reset(reset), .start(go), .restart(finish), .enable(msgEnable));
	
counter #(.MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)) msgCounter (.clock(clk), .reset(reset), .start(msgEnable), .msg_length(msgLength), .read_address(msgAddress), .read_complete(msg_address_read_complete));

msg_vector #(.MSG_LENGTH(MAX_MESSAGE_LENGTH)) msgBlock (.clock(clk), .reset(reset), .enable(msgEnable), .address_read_complete(msg_address_read_complete), .msg_address(msgAddress), 
 .msg_data(msgData), .msg_write(msgWrite), .message_vector(message_vector), .message_vector_complete(message_vector_complete));

/** Creating Hash Vector **/
go hashSignal (.clock(clk), .reset(reset), .start(go), .restart(finish),  .enable(hashEnable));

counter_h #(.NUMBER_OF_BLOCKS(NUMBER_OF_Hs)) Hcounter (.clock(clk), .reset(reset), .start(hashEnable), .read_address(hashAddress), .read_complete(hash_address_complete));

hash #(.HASH_LENGTH(NUMBER_OF_Hs)) hashBlock (.clock(clk), .reset(reset), .enable(hashEnable), .address_read_complete(hash_address_complete), .hash_address(hashAddress), .hash_write(hashWrite), 
.hash_data(hashData) , .hash_vector_complete(hash_vector_complete), .hash_vector(hash_vector));
	  
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
.h_data(dut__dom__data) , .h_vector_complete(finish), .h_output_address(dut__dom__address));

endmodule




