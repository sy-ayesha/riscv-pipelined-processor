// ============================================================
// PipelineRegisters.v
// All four inter-stage pipeline registers in one file
// IF/ID  |  ID/EX  |  EX/MEM  |  MEM/WB
// ============================================================


// ------------------------------------------------------------
// IF/ID Pipeline Register
// ------------------------------------------------------------
module IF_ID_Register(
    input         clk,
    input         reset,
    input         flush,        // Branch taken → flush
    input         IF_ID_Write,  // Hazard stall → hold
    input  [31:0] PC_plus_4_in,
    input  [31:0] Instruction_in,

    output reg [31:0] PC_plus_4_out,
    output reg [31:0] Instruction_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            PC_plus_4_out   <= 32'b0;
            Instruction_out <= 32'b0;        // NOP
        end else if (IF_ID_Write) begin
            PC_plus_4_out   <= PC_plus_4_in;
            Instruction_out <= Instruction_in;
        end
        // else: stall — hold current values
    end
endmodule


// ------------------------------------------------------------
// ID/EX Pipeline Register
// ------------------------------------------------------------
module ID_EX_Register(
    input         clk,
    input         reset,
    // Data inputs
    input  [31:0] ReadData1_in,
    input  [31:0] ReadData2_in,
    input  [31:0] Immediate_in,
    input  [31:0] PC_in,
    // Control inputs
    input  [1:0]  ALUOp_in,
    input         ALUSrc_in,
    input         MemWrite_in,
    input         MemRead_in,
    input         Branch_in,
    input         MemtoReg_in,
    input         RegWrite_in,
    // Instruction fields
    input  [2:0]  Funct3_in,
    input  [6:0]  Funct7_in,
    input  [4:0]  Rs1_in,
    input  [4:0]  Rs2_in,
    input  [4:0]  Rd_in,

    // Data outputs
    output reg [31:0] ReadData1_out,
    output reg [31:0] ReadData2_out,
    output reg [31:0] Immediate_out,
    output reg [31:0] PC_out,
    // Control outputs
    output reg [1:0]  ALUOp_out,
    output reg        ALUSrc_out,
    output reg        MemWrite_out,
    output reg        MemRead_out,
    output reg        Branch_out,
    output reg        MemtoReg_out,
    output reg        RegWrite_out,
    // Instruction field outputs
    output reg [2:0]  Funct3_out,
    output reg [6:0]  Funct7_out,
    output reg [4:0]  Rs1_out,
    output reg [4:0]  Rs2_out,
    output reg [4:0]  Rd_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ReadData1_out <= 0; ReadData2_out <= 0; Immediate_out <= 0; PC_out <= 0;
            ALUOp_out <= 0; ALUSrc_out <= 0; MemWrite_out <= 0; MemRead_out <= 0;
            Branch_out <= 0; MemtoReg_out <= 0; RegWrite_out <= 0;
            Funct3_out <= 0; Funct7_out <= 0; Rs1_out <= 0; Rs2_out <= 0; Rd_out <= 0;
        end else begin
            ReadData1_out <= ReadData1_in; ReadData2_out <= ReadData2_in;
            Immediate_out <= Immediate_in; PC_out <= PC_in;
            ALUOp_out <= ALUOp_in; ALUSrc_out <= ALUSrc_in;
            MemWrite_out <= MemWrite_in; MemRead_out <= MemRead_in;
            Branch_out <= Branch_in; MemtoReg_out <= MemtoReg_in; RegWrite_out <= RegWrite_in;
            Funct3_out <= Funct3_in; Funct7_out <= Funct7_in;
            Rs1_out <= Rs1_in; Rs2_out <= Rs2_in; Rd_out <= Rd_in;
        end
    end
endmodule


// ------------------------------------------------------------
// EX/MEM Pipeline Register
// ------------------------------------------------------------
module EX_MEM_Register(
    input         clk,
    input         reset,
    input  [31:0] ALUResult_in,
    input  [31:0] WriteData_in,
    input  [31:0] BranchTarget_in,
    input         Zero_in,
    input         PCSrc_in,
    input         MemWrite_in,
    input         MemRead_in,
    input         MemtoReg_in,
    input         RegWrite_in,
    input  [4:0]  WriteReg_in,

    output reg [31:0] ALUResult_out,
    output reg [31:0] WriteData_out,
    output reg [31:0] BranchTarget_out,
    output reg        Zero_out,
    output reg        PCSrc_out,
    output reg        MemWrite_out,
    output reg        MemRead_out,
    output reg        MemtoReg_out,
    output reg        RegWrite_out,
    output reg [4:0]  WriteReg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ALUResult_out <= 0; WriteData_out <= 0; BranchTarget_out <= 0;
            Zero_out <= 0; PCSrc_out <= 0;
            MemWrite_out <= 0; MemRead_out <= 0; MemtoReg_out <= 0; RegWrite_out <= 0;
            WriteReg_out <= 0;
        end else begin
            ALUResult_out <= ALUResult_in; WriteData_out <= WriteData_in;
            BranchTarget_out <= BranchTarget_in;
            Zero_out <= Zero_in; PCSrc_out <= PCSrc_in;
            MemWrite_out <= MemWrite_in; MemRead_out <= MemRead_in;
            MemtoReg_out <= MemtoReg_in; RegWrite_out <= RegWrite_in;
            WriteReg_out <= WriteReg_in;
        end
    end
endmodule


// ------------------------------------------------------------
// MEM/WB Pipeline Register
// ------------------------------------------------------------
module MEM_WB_Register(
    input         clk,
    input         reset,
    input  [31:0] ALUResult_in,
    input  [31:0] ReadData_in,
    input         MemtoReg_in,
    input         RegWrite_in,
    input  [4:0]  WriteReg_in,

    output reg [31:0] ALUResult_out,
    output reg [31:0] ReadData_out,
    output reg        MemtoReg_out,
    output reg        RegWrite_out,
    output reg [4:0]  WriteReg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ALUResult_out <= 0; ReadData_out <= 0;
            MemtoReg_out <= 0; RegWrite_out <= 0; WriteReg_out <= 0;
        end else begin
            ALUResult_out <= ALUResult_in; ReadData_out <= ReadData_in;
            MemtoReg_out <= MemtoReg_in; RegWrite_out <= RegWrite_in;
            WriteReg_out <= WriteReg_in;
        end
    end
endmodule
