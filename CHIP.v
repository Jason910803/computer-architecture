//----------------------------- DO NOT MODIFY THE I/O INTERFACE!! ------------------------------//
module CHIP #(                                                                                  //
    parameter BIT_W = 32                                                                        //
)(                                                                                              //
    // clock                                                                                    //
        input               i_clk,                                                              //
        input               i_rst_n,                                                            //
    // instruction memory                                                                       //
        input  [BIT_W-1:0]  i_IMEM_data,                                                        //
        output [BIT_W-1:0]  o_IMEM_addr,                                                        //
        output              o_IMEM_cen,                                                         //
    // data memory                                                                              //
        input               i_DMEM_stall,                                                       //
        input  [BIT_W-1:0]  i_DMEM_rdata,                                                       //
        output              o_DMEM_cen,                                                         //
        output              o_DMEM_wen,                                                         //
        output [BIT_W-1:0]  o_DMEM_addr,                                                        //
        output [BIT_W-1:0]  o_DMEM_wdata,                                                       //
    // finnish procedure                                                                        //
        output              o_finish,                                                           //
    // cache                                                                                    //
        input               i_cache_finish,                                                     //
        output              o_proc_finish                                                       //
);                                                                                              //
//----------------------------- DO NOT MODIFY THE I/O INTERFACE!! ------------------------------//

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Parameters
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    //TODO
    // R-Type
    localparam R_type = 7'b0110011;
    /*
    localparam ADD   = 7'b0110011;
    localparam SUB   = 7'b0110011;
    localparam AND   = 7'b0110011;
    localparam XOR   = 7'b0110011;
    localparam MUL   = 7'b0110011;
    */
    localparam I_type = 7'b0010011;
    /*
    localparam ADDI  = 7'b0010011;
    localparam SLTI  = 7'b0010011;
    localparam SLLI  = 7'b0010011;
    localparam SRAI  = 7'b0010011;
    */
    localparam LW    = 7'b0000011;
    
    localparam SB_type = 7'b1100011;
    /*
    localparam BEQ   = 7'b1100011;
    localparam BGE   = 7'b1100011;
    localparam BLT   = 7'b1100011;
    localparam BNE   = 7'b1100011;
    */
    localparam SW    = 7'b0100011;
    // 
    localparam JAL   = 7'b1101111;
    localparam JALR  = 7'b1100111;
    // U-type
    localparam AUIPC = 7'b0010111;
    // ECALL
    localparam ECALL = 7'b1110011;

    // function3
    localparam ADD_FUNC3   = 3'b000;
    localparam SUB_FUNC3   = 3'b000;
    localparam AND_FUNC3   = 3'b111;
    localparam XOR_FUNC3   = 3'b100;
    localparam ADDI_FUNC3  = 3'b000;
    localparam SLTI_FUNC3  = 3'b010;
    localparam SLLI_FUNC3  = 3'b001;
    localparam SRAI_FUNC3  = 3'b101;
    localparam MUL_FUNC3   = 3'b000;
    localparam BEQ_FUCN3   = 3'b000;
    localparam BGE_FUNC3   = 3'b101;
    localparam BLT_FUNC3   = 3'b100;
    localparam BNE_FUNC3   = 3'b001;
    localparam ECALL_FUNC3 = 3'b000;

    // funct7
    localparam ADD_FUNC7  = 7'b0000000;
    localparam SUB_FUNC7  = 7'b0100000;
    localparam AND_FUNC7  = 7'b0000000;
    localparam SLLI_FUNC7 = 7'b0000000;
    localparam SRAI_FUNC7 = 7'b0100000;
    localparam XOR_FUNC7  = 7'b0000000;
    localparam MUL_FUNC7  = 7'b0000001;

    // state
    localparam S_IDLE        = 0;
    localparam S_DO        = 1;
    localparam S_DO_MUL = 2;

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Wires and Registers
// ------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // TODO: any declaration
    reg [BIT_W-1:0] PC, next_PC;
    reg mem_cen, mem_wen, imem_cen, next_mem_cen, next_mem_wen, next_imem_cen, mem_cen_check, next_mem_cen_check, next_mem_wen_check, mem_wen_check;
    reg [BIT_W-1:0] mem_addr, mem_wdata, mem_rdata;

    reg [6:0] control_wire;   //for CONTROLL(opcode)
    reg [2:0] func3_wire;
    reg [6:0] func7_wire;
    reg [31:0] instruction;   //instruction
    reg [3:0] alu_wire;       //for ALU controll
    reg [31:0] imm;           //for IMM Gen

    reg [4:0] rs1;            //register1
    reg [4:0] rs2;            //register2
    reg [4:0] rd;             //rd register
    wire [31:0] rs1_data;     //data of register1
    wire [31:0] rs2_data;     //data of register2
    reg [31:0] rd_data;       //data of rd register
    reg [1:0] buffer, next_buffer;
    // for multipation
    reg mul_valid;
    wire mul_rdy;
    reg [31:0] mul_in_1, mul_in_2;
    wire [31:0] mul_out; 

    reg [1:0] next_state, state; //state

    reg RegWrite;
    integer i;
    reg finish;
    reg test;
// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Continuous Assignment
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: any wire assignment
    assign o_IMEM_addr = PC;
    assign o_IMEM_cen = imem_cen;
    assign o_DMEM_addr = mem_addr;
    assign o_DMEM_wdata = mem_wdata;
    assign o_DMEM_wen = mem_wen;
    assign o_DMEM_cen = mem_cen;
    assign o_finish = finish;
// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Submoddules
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // TODO: Reg_file wire connection
    Reg_file reg0(               
        .i_clk  (i_clk),             
        .i_rst_n(i_rst_n),         
        .wen    (RegWrite),          
        .rs1    (rs1),                
        .rs2    (rs2),                
        .rd     (rd),                 
        .wdata  (rd_data),             
        .rdata1 (rs1_data),           
        .rdata2 (rs2_data)
    );

    MULDIV_unit mul0(
        .clk(i_clk),
        .rst_n(i_rst_n),
        .valid(mul_valid),
        .ready(mul_rdy),
        .in_A(mul_in_1),
        .in_B(mul_in_2),
        .out(mul_out)
    );

// ------------------------------------------------------------------------------------------------------------------------------------------------------
// Always Blocks
// ------------------------------------------------------------------------------------------------------------------------------------------------------

    // Todo: any combinational/sequential circuit

    // initialization
    
    always @(*) begin
        finish = 0;
        instruction = i_IMEM_data;
        //test = buffer == 2'b00 && next_buffer == 2'b10;
        imem_cen = 1;
        next_mem_cen_check = 0;
        next_mem_wen_check = 0;
        next_mem_cen = 0;
        next_mem_wen = 0;
        rd_data = 0;
        control_wire = instruction[6:0];
        func3_wire = instruction[14:12];
        func7_wire = instruction[31:25];
        rd = instruction[11:7];
        rs1 = instruction[19:15];
        rs2 = instruction[24:20];
        imm = 0;
        mem_addr = 0;
        mem_wdata = 0;
        RegWrite = 1;
        mul_valid = 0;
        mul_in_1 = rs1_data;
        mul_in_2 = rs2_data;
        case(control_wire)
            R_type: begin  //for all opcode = 7'b0110011
                next_mem_cen_check = 0;
                next_mem_wen_check = 0;
                RegWrite = 1;
                imem_cen = 1;
                case({func7_wire, func3_wire})
                    {ADD_FUNC7, ADD_FUNC3}: begin
                        rd_data = $signed(rs1_data) + $signed(rs2_data);
                        next_PC = PC + 3'b100;
                    end
                    {SUB_FUNC7, SUB_FUNC3}: begin
                        rd_data = $signed(rs1_data) - $signed(rs2_data);
                        next_PC = PC + 3'b100;
                    end
                    {AND_FUNC7, AND_FUNC3}: begin
                        rd_data = rs1_data & rs2_data;
                        next_PC = PC + 3'b100;
                    end
                    {XOR_FUNC7, XOR_FUNC3}: begin
                        rd_data = rs1_data ^ rs2_data;
                        next_PC = PC + 3'b100;
                    end
                    {MUL_FUNC7, MUL_FUNC3}: begin
                        mul_valid = 1;
                        rd_data = mul_out[31:0];
                        if(mul_rdy) begin
                            next_PC = PC + 3'b100;
                            RegWrite = 1;
                        end
                        else begin
                            next_PC = PC;
                            RegWrite = 0;
                        end
                    end
                    default : begin
                        rd_data = 0;
                        next_PC = PC +3'b100;
                    end
                endcase
            end
            I_type: begin
                rs2 = 0;
                next_mem_cen_check = 0;
                next_mem_wen_check = 0;
                RegWrite = 1;
                imem_cen = 1;
                case(func3_wire)
                    ADDI_FUNC3: begin
                        rd_data = $signed(rs1_data) + $signed(instruction[31:20]);
                        next_PC = PC + 3'b100;
                    end
                    SLTI_FUNC3: begin
                        rd_data = ($signed(rs1_data) < $signed(instruction[31:20]))?1'b1:1'b0;
                        next_PC = PC + 3'b100;
                    end
                    SLLI_FUNC3: begin
                        rd_data = rs1_data << instruction[31:20];
                        next_PC = PC + 3'b100;
                    end
                    SRAI_FUNC3: begin
                            rd_data = rs1_data >>> instruction[24:20];
                            next_PC = PC + 3'b100;
                    end
                    default : begin
                        rd_data = 0;
                        next_PC = PC +3'b100;
                    end                    
                endcase
            end
            LW: begin
                rs2 = 0;
                next_mem_cen_check = 1;
                next_mem_cen = 1;
                next_mem_wen = 0;
                RegWrite = 1;
                mem_addr = $signed({1'b0, rs1_data}) + $signed(instruction[31:20]);
                if(i_DMEM_stall == 0) begin
                    if(mem_cen_check == 0) begin
                        next_PC = PC;
                    end
                    else begin
                        rd_data = i_DMEM_rdata;
                        next_PC = PC + 3'b100;
                        next_mem_cen = 0;
                        next_mem_wen = 0;
                        next_mem_cen_check = 0;
                        next_mem_wen_check = 0;
                    end
                end
                else begin
                    next_PC = PC;
                end
            end
            SW: begin
                rd = 0;
                next_mem_wen_check = 1;
                next_mem_cen = 1;
                next_mem_wen = 1;
                imm[11:0] = {instruction[31:25], instruction[11:7]};
                mem_addr = $signed({1'b0, rs1_data}) + $signed(imm[11:0]);
                if(i_DMEM_stall == 0) begin
                    if(mem_wen_check == 0) begin
                        next_PC = PC;
                    end
                    else begin
                        next_PC = PC + 3'b100;
                        next_mem_cen = 0;
                        next_mem_wen = 0;
                        next_mem_cen_check = 0;
                        next_mem_wen_check = 0;
                    end
                end 
                else begin
                    next_PC = PC;
                    mem_wdata = rs2_data;
                end
            end
            SB_type: begin
                rd = 0;
                next_mem_cen_check = 0;
                next_mem_wen_check = 0;
                imm[12:0] = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                imem_cen = 1;
                case(func3_wire)
                    BEQ_FUCN3: begin
                        next_PC = (rs1_data == rs2_data)?($signed({1'b0, PC}) + $signed(imm[12:0])):(PC + 3'b100);
                    end
                    BGE_FUNC3: begin
                        next_PC = ($signed(rs1_data) >= $signed(rs2_data))?($signed({1'b0, PC}) + $signed(imm[12:0])):(PC + 3'b100);
                    end
                    BNE_FUNC3: begin
                        next_PC = ($signed(rs1_data) != $signed(rs2_data))?($signed({1'b0, PC}) + $signed(imm[12:0])):(PC + 3'b100);
                    end
                    BLT_FUNC3: begin
                        next_PC = ($signed(rs1_data) < $signed(rs2_data))?($signed({1'b0, PC}) + $signed(imm[12:0])):(PC + 3'b100);
                    end
                    default : begin
                        rd_data = 0;
                        next_PC = PC +3'b100;
                    end
                endcase
            end
            JAL: begin
                rs1 = 0;
                rs2 = 0;
                next_mem_cen_check = 0;
                next_mem_wen_check = 0;
                RegWrite = 1;
                imm[20:0] = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                next_PC = $signed({1'b0, PC}) + $signed(imm[20:0]);
                rd_data = PC + 3'b100;
            end
            JALR: begin
                rs2 = 0;
                next_mem_cen_check = 0;
                next_mem_wen_check = 0;
                imm[11:0] = instruction[31:20];
                next_PC = $signed({1'b0, rs1_data}) + $signed(imm[11:0]);
                RegWrite = 1;
                rd_data = PC + 3'b100;
            end
            AUIPC: begin
                rs1 = 0;
                rs2 = 0;
                next_mem_cen_check = 0;
                next_mem_wen_check = 0;
                RegWrite = 1;
                imm[31:12] = instruction[31:12];
                imm[11:0]  = 0;
                rd_data = PC + imm;
                next_PC = PC + 3'b100;
            end
            ECALL: begin
                finish = 1;
                next_PC = PC;
            end
            default : begin
                rd_data = 0;
                next_PC = PC +3'b100;
            end
        endcase
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            instruction = i_IMEM_data;
            state <= S_IDLE;
            mem_cen <= 0;
            mem_wen <= 0;
            mem_cen_check <= 0;
            mem_wen_check <= 0;
        end
        else begin
            PC <= next_PC;
            state <= next_state;
            mem_cen_check <= next_mem_cen_check;
            mem_wen_check <= next_mem_wen_check;
            if (mem_cen_check == 1'b0 && mem_wen_check == 1'b0) begin
                mem_cen <= next_mem_cen;
                mem_wen <= next_mem_wen;
            end
            else begin
                mem_cen <= 0;
                mem_wen <= 0;
            end
        end
    end
    always @(negedge i_DMEM_stall) begin
        buffer <= 0;
    end



    //FSM
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                next_state = (control_wire == 7'b0110011 && ({func7_wire, func3_wire} == {MUL_FUNC7, MUL_FUNC3})) ? S_DO_MUL : S_DO;
            end
            S_DO: begin
                next_state = (control_wire == 7'b0110011 && ({func7_wire, func3_wire} == {MUL_FUNC7, MUL_FUNC3})) ? S_DO_MUL : S_DO;
            end
            S_DO_MUL: begin
                next_state = (mul_rdy) ? S_DO : S_DO_MUL;
            end 
        endcase   
    end

endmodule

module Reg_file(i_clk, i_rst_n, wen, rs1, rs2, rd, wdata, rdata1, rdata2);
   
    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth
    
    input i_clk, i_rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] wdata;
    input [addr_width-1:0] rs1, rs2, rd;

    output [BITS-1:0] rdata1, rdata2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign rdata1 = mem[rs1];
    assign rdata2 = mem[rs2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (rd == i)) ? wdata : mem[i];
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end       
    end
endmodule

module MULDIV_unit(clk, rst_n, valid, ready, in_A, in_B, out);
    input         clk, rst_n;
    input         valid;
    output        ready;
    input  [31:0] in_A, in_B;
    output [63:0] out;

    localparam IDLE = 3'd0;
    localparam MUL  = 3'd1;
    localparam DIV  = 3'd2;
    localparam SHIFT = 3'd3;
    localparam AVG = 3'd4;
    localparam OUT  = 3'd5;

    reg  [ 2:0] state, state_nxt;
    reg  [ 4:0] counter, counter_nxt;
    reg  [63:0] shreg, shreg_nxt;
    reg  [31:0] alu_in, alu_in_nxt;
    reg  [32:0] alu_out; 
    reg         dividend_flag; 
    reg         rdy, rdy_nxt;
    wire [1:0] mode;
    assign mode = 0;
    assign out = shreg;
    assign ready = rdy;
    
    always @(*) begin
        case(state)
            IDLE: begin
               rdy_nxt = 0;
            end
            MUL : begin
                if(counter == 5'd31) rdy_nxt = 1;
                else rdy_nxt = 0;
            end
            DIV : begin
                if(counter == 5'd31) rdy_nxt = 1;
                else rdy_nxt = 0;
            end
            SHIFT : rdy_nxt = 1;
            AVG : rdy_nxt = 1;
            OUT : rdy_nxt = 0;
            default : rdy_nxt = 0;
        endcase
    end
    always @(*) begin
        case(state)
            IDLE: begin
                if(!valid) state_nxt = IDLE; 
                else begin
                    case(mode)
                        2'd0: state_nxt = MUL;
                        2'd1: state_nxt = DIV;
                        2'd2: state_nxt = SHIFT;
                        2'd3: state_nxt = AVG;
                        default: state_nxt = IDLE;
                    endcase
                end
            end
            MUL : begin
                if(counter == 5'd31) state_nxt = OUT;
                else state_nxt = MUL;
            end
            DIV : begin
                if(counter == 5'd31) state_nxt = OUT;
                else state_nxt = DIV;
            end
            SHIFT : state_nxt = OUT;
            AVG : state_nxt = OUT;
            OUT : state_nxt = IDLE;
            default : state_nxt = IDLE;
        endcase
    end
    // Counter counts from 0 to 31 when the state is MUL or DIV
    // Otherwise, keep it zero
    always @(*) begin
        if(state == MUL || state == DIV) begin
            counter_nxt = counter + 1;
        end
        else counter_nxt = 0;
    end
    // ALU input
    always @(*) begin
        case(state)
            IDLE: begin
                if (valid) alu_in_nxt = in_B;
                else       alu_in_nxt = 0;
            end
            OUT : alu_in_nxt = 0;
            default: alu_in_nxt = alu_in;
        endcase
    end
    always @(*) begin
        alu_out = 0;
        dividend_flag = 0;
        case(state)
            MUL: begin
                if(shreg[0] == 1) begin
                    alu_out = shreg[63:32] + alu_in;
                    // $signed(in_A) + $signed(in_B)
                end
                else begin
                    alu_out = shreg[63:32];
                end
            end
            DIV: begin
                // if remainder goes < 0, add divisor back
                dividend_flag = (shreg[63:32] >= alu_in);
                if(dividend_flag) begin
                    alu_out = shreg[63:32] - alu_in;
                end 
                else begin
                    alu_out = shreg[63:32];
                end
            end
            SHIFT: begin
                alu_out = shreg[31:0] >> alu_in[2:0];
            end
            AVG: begin
                alu_out = (shreg[31:0] + alu_in) >> 1;
            end  
        endcase
    end    
    always @(*) begin
        case(state)
            IDLE: begin
                if(!valid) shreg_nxt = 0; 
                else begin
                    if(mode == 2'd1)begin
                        shreg_nxt = {{31{1'b0}}, in_A, {1'b0}}; 
                    end
                    else begin
                        shreg_nxt = {{32{1'b0}}, in_A};
                    end
                end
            end
            MUL: begin
                shreg_nxt = {alu_out, shreg[31:1]};
            end
            DIV: begin
                if(counter == 31)begin
                    if(dividend_flag)begin
                        shreg_nxt = {alu_out[31:0], shreg[30:0], {1'b1}};
                    end
                    else begin
                        shreg_nxt = {alu_out[31:0], shreg[30:0], {1'b0}};
                    end
                end
                else begin
                    if(dividend_flag)begin
                        shreg_nxt = {alu_out[30:0], shreg[31:0], {1'b1}};
                    end
                    else begin
                        shreg_nxt = {alu_out[30:0], shreg[31:0], {1'b0}};
                    end
                end
            end
            SHIFT: begin
                shreg_nxt = {32'b0, alu_out[31:0]};
            end
            AVG: begin
                shreg_nxt = {32'b0, alu_out[31:0]};
            end  
            OUT: begin
                shreg_nxt = shreg;
            end
            default: begin
                shreg_nxt = shreg;
            end
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            counter <= 0;
            shreg <= 0;
            alu_in <= 0;
            rdy <= 0;
        end
        else begin
            state <= state_nxt;
            counter <= counter_nxt;
            shreg <= shreg_nxt;
            alu_in <= alu_in_nxt;
            rdy <= rdy_nxt;
        end
    end
endmodule

module Cache#(
        parameter BIT_W = 32,
        parameter ADDR_W = 32
    )(
        input i_clk,
        input i_rst_n,
        // processor interface
            input i_proc_cen,
            input i_proc_wen,
            input [ADDR_W-1:0] i_proc_addr,
            input [BIT_W-1:0]  i_proc_wdata,
            output [BIT_W-1:0] o_proc_rdata,
            output o_proc_stall,
            input i_proc_finish,
            output o_cache_finish,
        // memory interface
            output o_mem_cen,
            output o_mem_wen,
            output [ADDR_W-1:0] o_mem_addr,
            output [BIT_W*4-1:0]  o_mem_wdata,
            input [BIT_W*4-1:0] i_mem_rdata,
            input i_mem_stall,
            output o_cache_available,
        // others
        input  [ADDR_W-1: 0] i_offset
    );

    assign o_cache_available = 0; // change this value to 1 if the cache is implemented

    //------------------------------------------//
    //          default connection              //
    assign o_mem_cen = i_proc_cen;              //
    assign o_mem_wen = i_proc_wen;              //
    assign o_mem_addr = i_proc_addr;            //
    assign o_mem_wdata = i_proc_wdata;          //
    assign o_proc_rdata = i_mem_rdata[0+:BIT_W];//
    assign o_proc_stall = i_mem_stall;          //
    //------------------------------------------//

    // Todo: BONUS

endmodule