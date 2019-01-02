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
    reg goSignal;
    reg resetSHA;
    reg enableMSGVector;
    reg finish;

    always @(posedge clk)
        goSignal <= xxx__dut__go;

    always @(posedge clk)
        resetSHA <= reset;

    always @(posedge clk)
        dut__xxx__finish <= finish;

    always @(posedge clk)
        begin
            if(resetSHA) enableMSGVector <= 0;
            else enableMSGVector <= (goSignal || enableMSGVector) && !finish;
        end

        //message vector
    reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   msgAddress;  // address of letter
    reg                                      msgEnable;
    reg                                      msgWrite;
    reg [7:0]                                msgData;  // read each letter
    reg [ $clog2(MAX_MESSAGE_LENGTH)-1:0]    msgLength;

    always @(posedge clk)
        begin
            //output
            dut__msg__address <= msgAddress;
            dut__msg__enable <= msgEnable;
            dut__msg__write <= msgWrite;
            msgLength <= xxx__dut__msg_length;

            // input
            msgData <= msg__dut__data;
        end

    reg msgAddressComplete;
        // Counter for msg Vector
    always @(posedge clk)
        begin
            if(resetSHA || !enableMSGVector || (msgAddress == msgLength))  msgAddress <= 0;
            else if(msgAddress < msgLength) msgAddress <= msgAddress+1;
            else msgAddress <= msgAddress;

            msgAddressComplete <= (msgAddress == msgLength);
        end

    reg [511:0] msgVector;


    genvar msgIndex;
    generate
        for (msgIndex=0; msgIndex<MAX_MESSAGE_LENGTH; msgIndex=msgIndex+1) begin
            always @(posedge clk) begin
                if(reset || !enableMSGVector) msgVector[511 - 8*msgIndex -: 8] <= 0;
                else if (!msgAddressComplete && msgIndex == msgAddress) msgVector[511 - 8*msgIndex -: 8] <= msgData;
                else if (msgAddressComplete && msgIndex == msgAddress) msgVector[511 - 8*msgIndex -: 8] <= 8'h80;
                else msgVector[511 - 8*msgIndex -: 8] <= msgVector[511 - 8*msgIndex -: 8];
            end
        end

        always @(posedge clk) begin
            if(reset || !enableMSGVector) msgVector[71:0] <= 0;
            else msgVector[71:0] <= msgLength*8;
        end
    endgenerate


        //hash vector
    reg  [ $clog2(NUMBER_OF_Hs)-1:0]         hmemAddress;  // address of letter
    reg                                      hmemEnable;
    reg                                      hmemWrite;
    reg [31:0]                               hmemData;  // read each letter

    always @(posedge clk)
        begin
            //output
            dut__hmem__address <= hmemAddress;
            dut__hmem__enable <= hmemEnable;
            dut__hmem__write <= hmemWrite;

            // input
            hmemData <= hmem__dut__data;
        end

    reg hmemAddressComplete;

        // Counter for Hash Vector
    always @(posedge clk)
        begin
            if(resetSHA || !enableMSGVector || (hmemAddress == 8))  hmemAddress <= 0;
            else if(hmemAddress < 8) hmemAddress <= hmemAddress+1;
            else hmemAddress <= hmemAddress;

            hmemAddressComplete <= (hmemAddress == 8);
        end

    reg [511:0] hashVector;

    genvar hmemIndex;
    generate
        for (hmemIndex=0; hmemIndex<NUMBER_OF_Hs; hmemIndex=hmemIndex+1) begin
            always @(posedge clk) begin
                if(reset || !enableMSGVector) hashVector[hmemIndex +: 32] <= 0;
                else if (!msgAddressComplete && hmemIndex == msgAddress) msgVector[511 - 8*hmemIndex -: 8] <= msgData;
                else if (msgAddressComplete && hmemIndex == msgAddress) msgVector[511 - 8*hmemIndex -: 8] <= 8'h80;
                else msgVector[511 - 8*hmemIndex -: 8] <= msgVector[511 - 8*hmemIndex -: 8];
            end
        end
    endgenerate


        //K vector
    reg  [ $clog2(NUMBER_OF_Ks)-1:0]         hmemAddress;  // address of letter
    reg                                      hmemEnable;
    reg                                      hmemWrite;
    reg [31:0]                               hmemData;  // read each letter

    always @(posedge clk)
        begin
            //output
            dut__hmem__address <= hmemAddress;
            dut__hmem__enable <= hmemEnable;
            dut__hmem__write <= hmemWrite;

            // input
            hmemData <= hmem__dut__data;
        end

    reg hmemAddressComplete;

        // Counter for Hash Vector
    always @(posedge clk)
        begin
            if(resetSHA || !enableMSGVector || (hmemAddress == 8))  hmemAddress <= 0;
            else if(hmemAddress < 8) hmemAddress <= hmemAddress+1;
            else hmemAddress <= hmemAddress;

            hmemAddressComplete <= (hmemAddress == 8);
        end

    reg [511:0] hashVector;

    genvar hmemIndex;
    generate
        for (hmemIndex=0; hmemIndex<NUMBER_OF_Hs; hmemIndex=hmemIndex+1) begin
            always @(posedge clk) begin
                if(reset || !enableMSGVector) hashVector[32*hmemIndex +: 32] <= 0;
                else if (!hmemAddressComplete && hmemIndex == hmemAddress) hashVector[32*hmemIndex +: 32] <= hmemData;
                else msgVector[32*hmemIndex +: 32] <= msgVector[32*hmemIndex +: 32];
            end
        end
    endgenerate

endmodule