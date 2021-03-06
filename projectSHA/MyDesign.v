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
    reg msgEnable;
    reg finish;

    always @(posedge clk)
        goSignal <= xxx__dut__go;

    always @(posedge clk)
        resetSHA <= reset;

    always @(posedge clk)
        dut__xxx__finish <= finish;


    always @(posedge clk)
        finish <= resetSHA ? 0 : finish;


    always @(posedge clk)
        begin
            if(resetSHA) msgEnable <= 0;
            else msgEnable <= (goSignal || msgEnable) && !finish;
        end

        //hash vector
    reg [ $clog2(NUMBER_OF_Hs)-1:0]          hmemAddress;  // address of letter
    reg hmemAddressCarry;
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

    always @(posedge clk)
        begin
            if(resetSHA) hmemEnable <= 0;
            else hmemEnable <= (goSignal || hmemEnable) && !finish;
        end

        // Counter for Hash Vector
    always @(posedge clk)
        begin
            if(resetSHA || !hmemEnable)  begin
                hmemAddress <= 0;
                hmemAddressCarry <= 0;
                hmemWrite <= 0;
            end
            else if(!hmemAddressCarry) begin
                {hmemAddressCarry,hmemAddress} <= hmemAddress+1;
                hmemWrite <= 0;
            end
            else if(hmemAddressCarry) begin
                hmemAddress <= hmemAddress;
                hmemAddressCarry <= hmemAddressCarry;
                hmemWrite <= 0;
            end
            else begin
                hmemAddress <= hmemAddress;
                hmemAddressCarry <= hmemAddressCarry;
                hmemWrite <= 0;
            end

            hmemAddressComplete <= hmemEnable && !resetSHA ? hmemAddressCarry || hmemAddressComplete: 0;

        end

    reg [255:0] hashVector;

    reg [ $clog2(NUMBER_OF_Hs)-1:0]         hmemAddressPipe1;  // address of letter
    reg [ $clog2(NUMBER_OF_Hs)-1:0]         hmemAddressPipe2;  // address of letter

    reg hmemAddressCompletePipe1;  // address of letter
    reg hmemAddressCompletePipe2;  // address of letter


    always @(posedge clk)
        begin
            hmemAddressPipe1 <= hmemAddress;
            hmemAddressPipe2 <= hmemAddressPipe1;

            hmemAddressCompletePipe1 <= hmemAddressComplete;
            hmemAddressCompletePipe2 <= hmemAddressCompletePipe1;
        end

    genvar hmemIndex;
    generate
        for (hmemIndex=0; hmemIndex<NUMBER_OF_Hs; hmemIndex=hmemIndex+1) begin
            always @(posedge clk) begin
                if(resetSHA || !hmemEnable) hashVector[32*hmemIndex +: 32] <= 0;
                else if (!hmemAddressCompletePipe2 && hmemIndex == hmemAddressPipe2) hashVector[32*hmemIndex +: 32] <= hmemData;
                else hashVector[32*hmemIndex +: 32] <= hashVector[32*hmemIndex +: 32];
            end
        end
    endgenerate

        //message vector
    reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   msgAddress;  // address of letter
        //  reg                                      msgEnable;
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
            if(resetSHA || !msgEnable) begin
                msgAddress <= 0;
                msgWrite <= 0;
            end
            else if(msgAddress < msgLength) begin
                msgWrite <= 0;
                msgAddress <= msgAddress+1;
            end
            else if(msgAddress == msgLength) begin
                msgWrite <= 1;
                msgAddress <= msgAddress;
            end
            else begin
                msgAddress <= msgAddress;
                msgWrite <= 1;
            end

            msgAddressComplete <= (msgAddress == msgLength);
        end

    reg [511:0] msgVector;
    reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0] msgAddressPipe1;
    reg  [ $clog2(MAX_MESSAGE_LENGTH)-1:0] msgAddressPipe2;

    reg  msgAddressCompletePipe1;
    reg  msgAddressCompletePipe2;

    always @(posedge clk)
        begin
            msgAddressPipe1 <= msgAddress;
            msgAddressPipe2 <= msgAddressPipe1;

            msgAddressCompletePipe1 <= msgAddressComplete;
            msgAddressCompletePipe2 <= msgAddressCompletePipe1;
        end

        //K vector
    reg  [ $clog2(NUMBER_OF_Ks)-1:0]         kmemAddress;  // address of letter
    reg  [ $clog2(NUMBER_OF_Ks)-1:0]         kmemAddressPipe1;
    reg  [ $clog2(NUMBER_OF_Ks)-1:0]         kmemAddressPipe2;

    reg  kmemAddressCarry;
    reg                                      kmemEnable;
    reg                                      kmemEnablePipe1;
    reg                                      kmemEnablePipe2;
    reg                                      kmemWrite;
    reg [31:0]                               kmemData;  // read each letter

    reg hashUpdateEnable;

    always @(posedge clk) begin
        kmemEnablePipe1 <= kmemEnable;
        kmemEnablePipe2 <= kmemEnablePipe1;
        hashUpdateEnable <= kmemEnablePipe2;
    end


    always @(posedge clk)
        begin
            //output
            dut__kmem__address <= kmemAddress;
            dut__kmem__enable <= kmemEnable;
            dut__kmem__write <= kmemWrite;

            // input
            kmemData <= kmem__dut__data;
        end

    always @(posedge clk)
        begin
            if(resetSHA) kmemEnable <= 0;
            else kmemEnable <= ((msgAddressCompletePipe2 && hmemAddressCompletePipe2) || kmemEnable) && !finish;
        end

    reg kmemAddressComplete;
    reg kmemAddressCompletePipe1;
    reg kmemAddressCompletePipe2;

    always @(posedge clk)
        begin
            kmemAddressPipe1 <= kmemAddress;
            kmemAddressPipe2 <= kmemAddressPipe1;


            kmemAddressCompletePipe1 <= kmemAddressComplete;
            kmemAddressCompletePipe2 <= kmemAddressCompletePipe1;
        end


    genvar msgIndex;
    generate
        for (msgIndex=0; msgIndex<MAX_MESSAGE_LENGTH; msgIndex=msgIndex+1) begin
            always @(posedge clk) begin
                if(resetSHA || !msgEnable) msgVector[511 - 8*msgIndex -: 8] <= 0;
                else if (!msgAddressCompletePipe1 && msgIndex == msgAddressPipe2) msgVector[511 - 8*msgIndex -: 8] <= msgData;
                else if (msgAddressCompletePipe1) msgVector[511 - 8*msgLength -: 8] <= 8'h80;
                else msgVector[511 - 8*msgIndex -: 8] <= msgVector[511 - 8*msgIndex -: 8];
            end
        end

        always @(posedge clk) begin
            msgVector[71:0] <= msgLength*8;
        end
    endgenerate

    reg [511:0] w_vector;
    reg [31:0] new_w;
    reg startNewW;

    always @(posedge clk)
        begin
            if(resetSHA || !msgEnable) startNewW <= 0;
            else if (msgAddressCompletePipe2) startNewW <= 1;
            else startNewW <= startNewW;
        end


    reg [1:0] hashCycle;
    reg getNewHash;
    reg [5:0] kmemAddressStall;

    always @(posedge clk)
        begin
            if(getNewHash) kmemAddressStall <= kmemAddressPipe2;
            else kmemAddressStall <= kmemAddressStall;
        end


    always @(posedge clk) begin
        if(!kmemEnablePipe1) begin
            hashCycle <= 3;
        end
        else begin
            hashCycle <= hashCycle + 1;
        end

        getNewHash = (hashCycle == 3);
    end

    reg updateEnable;

    genvar nwIndex;
    generate
        for (nwIndex=0; nwIndex< 16; nwIndex=nwIndex+1) begin
            always @(posedge clk) begin
                if(!kmemEnable || resetSHA) w_vector[511 - nwIndex*32 -: 32] <= 0;
                else if(!hashUpdateEnable && !kmemAddressCompletePipe2) w_vector[511 - nwIndex*32 -: 32] <= msgVector[511 - nwIndex*32 -: 32];
                else if(hashUpdateEnable && !kmemAddressCompletePipe2 && getNewHash && (nwIndex == kmemAddressStall[3:0])) w_vector[511 - nwIndex*32 -: 32] <= new_w;
                else w_vector[511 - nwIndex*32 -: 32] <= w_vector[511 - nwIndex*32 -: 32];
            end
        end
    endgenerate

    reg [3:0] index2;
    reg [3:0] index7;
    reg [3:0] index15;
    reg [3:0] index16;

    reg index2Carry;
    reg index7Carry;
    reg index15Carry;
    reg index16Carry;


    always @(*) begin
        if(!startNewW) begin
            index2 = 0;
            index7 = 0;
            index15 = 0;
            index16 = 0;
        end
        else begin
            {index2Carry,index2} = kmemAddressStall[3:0] - 2;
            {index7Carry,index7} = kmemAddressStall[3:0] - 7;
            {index15Carry,index15} = kmemAddressStall[3:0] - 15;
            {index16Carry,index16} = kmemAddressStall[3:0] - 16;
        end
    end

    reg [31:0] s0word;

    always @(*) begin
        s0word = w_vector[511 - index15*32 -: 32];
    end

    reg [31:0] s0w_r1;
    reg [31:0] s0w_r2;
    reg [31:0] s0w_r3;

    always @(*) begin
        s0w_r1 = {s0word[6:0], s0word[31:7]};
        s0w_r2 = {s0word[17:0], s0word[31:18]};
        s0w_r3[28:0] = s0word[31:3];
        s0w_r3[31:29] = 0;
    end

    reg [31:0] sigma0_s0word;

    always @(posedge clk) begin
        sigma0_s0word <= (s0w_r1 ^ s0w_r2) ^ s0w_r3;
    end

    reg [31:0] s1word;

    always @(*) begin
        s1word = w_vector[511 - index2*32 -: 32];
    end

    reg [31:0] s1w_r1;
    reg [31:0] s1w_r2;
    reg [31:0] s1w_r3;

    always @(*) begin
        s1w_r1 ={s1word[16:0], s1word[31:17]};
        s1w_r2 = {s1word[18:0], s1word[31:19]};
        s1w_r3[21:0] = s1word[31:10];
        s1w_r3[31:22] = 0;
    end

    reg [31:0] sigma1_s1word;

    always @(posedge clk) begin
        sigma1_s1word <= s1w_r1 ^ s1w_r2 ^ s1w_r3;
    end

    reg [31:0] word7;
    reg [31:0] word16;

    always @(posedge clk) begin
        word16 <= w_vector[511 - index16*32 -: 32];
        word7 <= w_vector[511 - index7*32 -: 32];
    end

    always @(posedge clk) begin
        new_w <= (sigma0_s0word + sigma1_s1word) + (word16 + word7);
    end



        // Counter for K Vector
    always @(posedge clk)
        begin
            if(resetSHA || !kmemEnable) begin
                kmemAddress <= 0;
                kmemAddressCarry <= 0;
                kmemWrite <= 0;
            end
            else if(!kmemAddressCarry && getNewHash && kmemEnablePipe1) begin
                {kmemAddressCarry,kmemAddress} <= kmemAddress+1;
                kmemWrite <= 0;
            end
            else if(kmemAddressCarry) begin
                kmemAddress <= kmemAddress;
                kmemAddressCarry <= kmemAddressCarry;
                kmemWrite <= 0;
            end
            else begin
                kmemAddress <= kmemAddress;
                kmemAddressCarry <= kmemAddressCarry;
                kmemWrite <= 0;
            end

            kmemAddressComplete <= kmemEnable && !resetSHA ? kmemAddressCarry || kmemAddressComplete: 0;

        end

    reg [31:0] cur_k_value;

    genvar kmemIndex;
    generate
        always @(posedge clk) begin
            if(resetSHA || !kmemEnable) cur_k_value <= 0;
            else if (!kmemAddressCompletePipe2) cur_k_value <= kmemData;
            else cur_k_value <= cur_k_value;
        end
    endgenerate

    reg [31:0] cur_w_value;

    genvar wIndex;
    generate
        for(wIndex = 0; wIndex < 16; wIndex = wIndex + 1) begin
            always @(posedge clk) begin
                if(!kmemEnable || resetSHA) cur_w_value <= 0;
                else if(kmemAddressPipe2 >= 0 && !kmemAddressCompletePipe2) cur_w_value <= w_vector[511 - 32*kmemAddressPipe2[3:0] -: 32];
                else cur_w_value <= cur_w_value;
            end
        end
    endgenerate

    reg [255:0] newHash;

    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] c;
    reg [31:0] d;
    reg [31:0] e;
    reg [31:0] f;
    reg [31:0] g;
    reg [31:0] h;

    always @(posedge clk) begin
        if(!hashUpdateEnable && getNewHash) begin
            a <= hashVector[32*0 +: 32];
            b <= hashVector[32*1 +: 32];
            c <= hashVector[32*2 +: 32];
            d <= hashVector[32*3 +: 32];
            e <= hashVector[32*4 +: 32];
            f <= hashVector[32*5 +: 32];
            g <= hashVector[32*6 +: 32];
            h <= hashVector[32*7 +: 32];
        end
        else if(getNewHash) begin
            a <= newHash[32*0 +: 32];
            b <= newHash[32*1 +: 32];
            c <= newHash[32*2 +: 32];
            d <= newHash[32*3 +: 32];
            e <= newHash[32*4 +: 32];
            f <= newHash[32*5 +: 32];
            g <= newHash[32*6 +: 32];
            h <= newHash[32*7 +: 32];
        end
        else begin
            a <= a;
            b <= b;
            c <= c;
            d <= d;
            e <= e;
            f <= f;
            g <= g;
            h <= h;
        end
    end

    reg [31:0] a_r1;
    reg [31:0] a_r2;
    reg [31:0] a_r3;

    always @(*) begin
        a_r1 = {a[1:0], a[31:2]};// >> 2;
        a_r2 = {a[12:0], a[31:13]}; //a_n >> 13;
        a_r3 = {a[21:0], a[31:22]}; //a_n >> 22;
    end

    reg [31:0] summation0_output;

    always @(posedge clk) begin
        summation0_output <= a_r1 ^ a_r2 ^ a_r3;
    end

    reg [31:0] e_r1;
    reg [31:0] e_r2;
    reg [31:0] e_r3;

    always @(*) begin
        e_r1 = {e[5:0], e[31:6]}; //e_n >> 6;
        e_r2 = {e[10:0], e[31:11]}; //e_n >> 11;
        e_r3 = {e[24:0], e[31:25]}; //e_n >> 25;
    end

    reg [31:0] summation1_output;

    always @(posedge clk) begin
        summation1_output <= e_r1 ^ e_r2 ^ e_r3;
    end

    reg [31:0] major_output;

    always @(posedge clk) begin
        major_output <= (a & b) ^ (b & c) ^ (c & a);
    end

    reg [31:0] choice_output;

    always @(posedge clk) begin
        choice_output <= (e & f) ^ ((~e) & g);
    end

    reg [31:0] t1;
    reg  t1Carry;
    reg [31:0] hPipe1;

    always @(posedge clk) begin
        hPipe1 <= h;
    end

    reg [31:0] dPipe1;

    always @(posedge clk) begin
        dPipe1 <= d;
    end

    reg [31:0] wk;
    reg wkCarry;

    always @(posedge clk) begin
        {wkCarry,wk} <= (cur_w_value + cur_k_value);
    end


    always @(posedge clk) begin
        {t1Carry,t1} <= (summation1_output + choice_output)  + (hPipe1);
    end

    reg [31:0] t1d;
    reg t1dCarry;

    always @(posedge clk) begin
        {t1dCarry,t1d} <= (summation1_output + choice_output)  + (hPipe1 + dPipe1);
    end

    reg [31:0] t2;
    reg  t2Carry;

    always @(posedge clk) begin
        {t2Carry,t2} <= summation0_output + major_output;
    end

    always @(posedge clk) begin
        if(hashCycle == 2 && !kmemAddressComplete) begin
            newHash[32*0 +: 32] <= (t1 + t2) + wk;
            newHash[32*1 +: 32] <= a;
            newHash[32*2 +: 32] <= b;
            newHash[32*3 +: 32] <= c;
            newHash[32*4 +: 32] <= t1d + wk;
            newHash[32*5 +: 32] <= e;
            newHash[32*6 +: 32] <= f;
            newHash[32*7 +: 32] <= g;
        end
        else if(hashCycle == 2 && kmemAddressComplete && !kmemAddressCompletePipe2) begin
            newHash[32*0 +: 32] <= (t1 + t2) + wk + hashVector[32*0 +: 32];
            newHash[32*1 +: 32] <= a + hashVector[32*1 +: 32];
            newHash[32*2 +: 32] <= b + hashVector[32*2 +: 32];
            newHash[32*3 +: 32] <= c + hashVector[32*3 +: 32];
            newHash[32*4 +: 32] <= t1d + wk + hashVector[32*4 +: 32];
            newHash[32*5 +: 32] <= e + hashVector[32*5 +: 32];
            newHash[32*6 +: 32] <= f + hashVector[32*6 +: 32];
            newHash[32*7 +: 32] <= g + hashVector[32*7 +: 32];
        end
        else begin
            newHash[32*0 +: 32] <= newHash[32*0 +: 32];
            newHash[32*1 +: 32] <= newHash[32*1 +: 32];
            newHash[32*2 +: 32] <= newHash[32*2 +: 32];
            newHash[32*3 +: 32] <= newHash[32*3 +: 32];
            newHash[32*4 +: 32] <= newHash[32*4 +: 32];
            newHash[32*5 +: 32] <= newHash[32*5 +: 32];
            newHash[32*6 +: 32] <= newHash[32*6 +: 32];
            newHash[32*7 +: 32] <= newHash[32*7 +: 32];
        end
    end

        //hash vector
     reg  [ $clog2(OUTPUT_LENGTH)-1:0]    domAddress;
     reg  [31:0]                          domData;  // write data
     reg                                  domEnable;
     reg                                  domWrite;

    always @(posedge clk)
        begin
            //output
            dut__dom__address <= domAddress;
            dut__dom__enable <= domEnable;
            dut__dom__write <= domWrite;
            dut__dom__data <= domData;
        end

    reg domAddressComplete;
    reg domAddressCarry;

    always @(posedge clk)
        begin
            if(resetSHA) domEnable <= 0;
            else domEnable <= (kmemAddressCompletePipe2 || domEnable) && !finish;
        end

        // Counter for Hash Vector
    always @(posedge clk)
        begin
            if(resetSHA || !domEnable)  begin
                domAddress <= 0;
                domAddressCarry <= 0;
                domWrite <= 1;
            end
            else if(!domAddressCarry) begin
                {domAddressCarry,domAddress} <= domAddress+1;
                domWrite <= 0;
            end
            else if(domAddressCarry) begin
                domAddress <= domAddress;
                domAddressCarry <= domAddressCarry;
                domWrite <= 0;
            end
            else begin
                domAddress <= domAddress;
                domAddressCarry <= domAddressCarry;
                domWrite <= 1;
            end

            domAddressComplete <= domEnable && !resetSHA ? domAddressCarry || domAddressComplete: 0;

        end

    genvar domIndex;
    generate
        for (domIndex=0; domIndex<NUMBER_OF_Hs; domIndex=domIndex+1) begin
            always @(posedge clk) begin
                if(resetSHA || !domEnable) domData <= 0;
                else if (!domAddressCarry && domIndex == domAddress) domData <= newHash[32*domIndex +: 32];
                else domData <= domData;
            end
        end
    endgenerate

    always @(posedge clk) begin
        finish <= domAddressComplete;
    end


endmodule