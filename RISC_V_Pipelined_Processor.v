// ============================================================
// RISC_V_Pipelined_Processor.v   —   TOP-LEVEL MODULE
// 5-Stage RISC-V Pipelined Processor
// NED University of Engineering and Technology
// EL-421 Embedded Electronics | Open Ended Lab
//
// Pipeline stages:  IF → ID → EX → MEM → WB
// Hazard handling:  Load-use stall (HDU)
//                   Branch flush (PCSrc from EX/MEM)
// ============================================================

`include "InstructionFetch.v"
`include "InstructionDecode.v"
`include "Execute.v"
`include "MemoryAccess.v"
`include "WriteBack.v"
`include "PipelineRegisters.v"
`include "HazardDetectionUnit.v"

module RISC_V_Pipelined_Processor(
    input clk,
    input reset
);

    // ---- IF Stage signals ----
    wire [31:0] PC, Instruction, PC_plus_4;

    // ---- IF/ID signals ----
    wire [31:0] IF_ID_PC_plus_4, IF_ID_Instruction;

    // ---- Hazard signals ----
    wire PCWrite, IF_ID_Write, ControlMux;

    // ---- ID Stage signals ----
    wire [31:0] ReadData1, ReadData2, Immediate;
    wire [6:0]  Opcode, Funct7;
    wire [2:0]  Funct3;
    wire [4:0]  Rs1, Rs2, Rd;
    wire [1:0]  ALUOp;
    wire        ALUSrc, MemWrite, MemRead, Branch, MemtoReg, RegWrite;

    // ---- ID/EX signals ----
    wire [31:0] ID_EX_ReadData1, ID_EX_ReadData2, ID_EX_Immediate, ID_EX_PC;
    wire [1:0]  ID_EX_ALUOp;
    wire        ID_EX_ALUSrc, ID_EX_MemWrite, ID_EX_MemRead;
    wire        ID_EX_Branch, ID_EX_MemtoReg, ID_EX_RegWrite;
    wire [2:0]  ID_EX_Funct3;
    wire [6:0]  ID_EX_Funct7;
    wire [4:0]  ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd;

    // ---- EX Stage signals ----
    wire [31:0] EX_ALUResult, EX_BranchTarget;
    wire        EX_Zero, EX_PCSrc;
    wire [4:0]  EX_WriteReg;

    // ---- EX/MEM signals ----
    wire [31:0] EX_MEM_ALUResult, EX_MEM_WriteData, EX_MEM_BranchTarget;
    wire        EX_MEM_Zero, EX_MEM_PCSrc;
    wire        EX_MEM_MemWrite, EX_MEM_MemRead, EX_MEM_MemtoReg, EX_MEM_RegWrite;
    wire [4:0]  EX_MEM_WriteReg;

    // ---- MEM Stage signals ----
    wire [31:0] MEM_ReadData;

    // ---- MEM/WB signals ----
    wire [31:0] MEM_WB_ALUResult, MEM_WB_ReadData;
    wire        MEM_WB_MemtoReg, MEM_WB_RegWrite;
    wire [4:0]  MEM_WB_WriteReg;

    // ---- WB Stage signals ----
    wire [31:0] WB_WriteData;

    // ===========================================================
    //  HAZARD DETECTION UNIT
    // ===========================================================
    HazardDetectionUnit hazard_unit (
        .IF_ID_Rs1    (IF_ID_Instruction[19:15]),
        .IF_ID_Rs2    (IF_ID_Instruction[24:20]),
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_Rd     (ID_EX_Rd),
        .PCWrite      (PCWrite),
        .IF_ID_Write  (IF_ID_Write),
        .ControlMux   (ControlMux)
    );

    // ===========================================================
    //  IF STAGE
    // ===========================================================
    InstructionFetch IF_stage (
        .clk          (clk),
        .reset        (reset),
        .PCWrite      (PCWrite),
        .PCSrc        (EX_MEM_PCSrc),
        .BranchTarget (EX_MEM_BranchTarget),
        .PC           (PC),
        .Instruction  (Instruction),
        .PC_plus_4    (PC_plus_4)
    );

    // ===========================================================
    //  IF/ID PIPELINE REGISTER
    // ===========================================================
    IF_ID_Register if_id_reg (
        .clk             (clk),
        .reset           (reset),
        .flush           (EX_MEM_PCSrc),
        .IF_ID_Write     (IF_ID_Write),
        .PC_plus_4_in    (PC_plus_4),
        .Instruction_in  (Instruction),
        .PC_plus_4_out   (IF_ID_PC_plus_4),
        .Instruction_out (IF_ID_Instruction)
    );

    // ===========================================================
    //  ID STAGE
    // ===========================================================
    InstructionDecode ID_stage (
        .clk        (clk),
        .Instruction(IF_ID_Instruction),
        .WriteData  (WB_WriteData),
        .WriteReg   (MEM_WB_WriteReg),
        .RegWrite   (MEM_WB_RegWrite),
        .ControlMux (ControlMux),
        .ReadData1  (ReadData1),
        .ReadData2  (ReadData2),
        .Immediate  (Immediate),
        .Opcode     (Opcode),
        .Funct3     (Funct3),
        .Funct7     (Funct7),
        .Rs1        (Rs1),
        .Rs2        (Rs2),
        .Rd         (Rd),
        .ALUOp      (ALUOp),
        .ALUSrc     (ALUSrc),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .Branch     (Branch),
        .MemtoReg   (MemtoReg),
        .RegWriteOut(RegWrite)
    );

    // ===========================================================
    //  ID/EX PIPELINE REGISTER
    // ===========================================================
    ID_EX_Register id_ex_reg (
        .clk           (clk),
        .reset         (reset),
        .ReadData1_in  (ReadData1),
        .ReadData2_in  (ReadData2),
        .Immediate_in  (Immediate),
        .PC_in         (IF_ID_PC_plus_4 - 4),   // actual PC of instruction
        .ALUOp_in      (ALUOp),
        .ALUSrc_in     (ALUSrc),
        .MemWrite_in   (MemWrite),
        .MemRead_in    (MemRead),
        .Branch_in     (Branch),
        .MemtoReg_in   (MemtoReg),
        .RegWrite_in   (RegWrite),
        .Funct3_in     (Funct3),
        .Funct7_in     (Funct7),
        .Rs1_in        (Rs1),
        .Rs2_in        (Rs2),
        .Rd_in         (Rd),
        .ReadData1_out (ID_EX_ReadData1),
        .ReadData2_out (ID_EX_ReadData2),
        .Immediate_out (ID_EX_Immediate),
        .PC_out        (ID_EX_PC),
        .ALUOp_out     (ID_EX_ALUOp),
        .ALUSrc_out    (ID_EX_ALUSrc),
        .MemWrite_out  (ID_EX_MemWrite),
        .MemRead_out   (ID_EX_MemRead),
        .Branch_out    (ID_EX_Branch),
        .MemtoReg_out  (ID_EX_MemtoReg),
        .RegWrite_out  (ID_EX_RegWrite),
        .Funct3_out    (ID_EX_Funct3),
        .Funct7_out    (ID_EX_Funct7),
        .Rs1_out       (ID_EX_Rs1),
        .Rs2_out       (ID_EX_Rs2),
        .Rd_out        (ID_EX_Rd)
    );

    // ===========================================================
    //  EX STAGE
    // ===========================================================
    Execute EX_stage (
        .ReadData1   (ID_EX_ReadData1),
        .ReadData2   (ID_EX_ReadData2),
        .Immediate   (ID_EX_Immediate),
        .PC          (ID_EX_PC),
        .ALUOp       (ID_EX_ALUOp),
        .ALUSrc      (ID_EX_ALUSrc),
        .Branch      (ID_EX_Branch),
        .Funct3      (ID_EX_Funct3),
        .Funct7      (ID_EX_Funct7),
        .Rs1         (ID_EX_Rs1),
        .Rs2         (ID_EX_Rs2),
        .Rd          (ID_EX_Rd),
        .ALUResult   (EX_ALUResult),
        .BranchTarget(EX_BranchTarget),
        .Zero        (EX_Zero),
        .PCSrc       (EX_PCSrc),
        .WriteReg    (EX_WriteReg)
    );

    // ===========================================================
    //  EX/MEM PIPELINE REGISTER
    // ===========================================================
    EX_MEM_Register ex_mem_reg (
        .clk             (clk),
        .reset           (reset),
        .ALUResult_in    (EX_ALUResult),
        .WriteData_in    (ID_EX_ReadData2),
        .BranchTarget_in (EX_BranchTarget),
        .Zero_in         (EX_Zero),
        .PCSrc_in        (EX_PCSrc),
        .MemWrite_in     (ID_EX_MemWrite),
        .MemRead_in      (ID_EX_MemRead),
        .MemtoReg_in     (ID_EX_MemtoReg),
        .RegWrite_in     (ID_EX_RegWrite),
        .WriteReg_in     (EX_WriteReg),
        .ALUResult_out   (EX_MEM_ALUResult),
        .WriteData_out   (EX_MEM_WriteData),
        .BranchTarget_out(EX_MEM_BranchTarget),
        .Zero_out        (EX_MEM_Zero),
        .PCSrc_out       (EX_MEM_PCSrc),
        .MemWrite_out    (EX_MEM_MemWrite),
        .MemRead_out     (EX_MEM_MemRead),
        .MemtoReg_out    (EX_MEM_MemtoReg),
        .RegWrite_out    (EX_MEM_RegWrite),
        .WriteReg_out    (EX_MEM_WriteReg)
    );

    // ===========================================================
    //  MEM STAGE
    // ===========================================================
    MemoryAccess MEM_stage (
        .clk      (clk),
        .ALUResult(EX_MEM_ALUResult),
        .WriteData(EX_MEM_WriteData),
        .MemWrite (EX_MEM_MemWrite),
        .MemRead  (EX_MEM_MemRead),
        .ReadData (MEM_ReadData)
    );

    // ===========================================================
    //  MEM/WB PIPELINE REGISTER
    // ===========================================================
    MEM_WB_Register mem_wb_reg (
        .clk          (clk),
        .reset        (reset),
        .ALUResult_in (EX_MEM_ALUResult),
        .ReadData_in  (MEM_ReadData),
        .MemtoReg_in  (EX_MEM_MemtoReg),
        .RegWrite_in  (EX_MEM_RegWrite),
        .WriteReg_in  (EX_MEM_WriteReg),
        .ALUResult_out(MEM_WB_ALUResult),
        .ReadData_out (MEM_WB_ReadData),
        .MemtoReg_out (MEM_WB_MemtoReg),
        .RegWrite_out (MEM_WB_RegWrite),
        .WriteReg_out (MEM_WB_WriteReg)
    );

    // ===========================================================
    //  WB STAGE
    // ===========================================================
    WriteBack WB_stage (
        .ALUResult(MEM_WB_ALUResult),
        .ReadData (MEM_WB_ReadData),
        .MemtoReg (MEM_WB_MemtoReg),
        .WriteData(WB_WriteData)
    );

endmodule
