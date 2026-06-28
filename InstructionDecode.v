// ============================================================
// InstructionDecode.v
// 5-Stage RISC-V Pipelined Processor — ID Stage
// Includes: Register File, Immediate Generator, Control Unit
// ============================================================

module InstructionDecode(
    input         clk,
    input  [31:0] Instruction,
    input  [31:0] WriteData,
    input  [4:0]  WriteReg,
    input         RegWrite,
    input         ControlMux,       // Hazard: zero control signals when 1

    output [31:0] ReadData1,
    output [31:0] ReadData2,
    output [31:0] Immediate,
    output [6:0]  Opcode,
    output [2:0]  Funct3,
    output [6:0]  Funct7,
    output [4:0]  Rs1,
    output [4:0]  Rs2,
    output [4:0]  Rd,
    output [1:0]  ALUOp,
    output        ALUSrc,
    output        MemWrite,
    output        MemRead,
    output        Branch,
    output        MemtoReg,
    output        RegWriteOut
);

    // ---- Register File (32 x 32-bit) ----
    reg [31:0] registers [0:31];

    wire [6:0] opcode = Instruction[6:0];
    assign Opcode = opcode;
    assign Funct3 = Instruction[14:12];
    assign Funct7 = Instruction[31:25];
    assign Rs1    = Instruction[19:15];
    assign Rs2    = Instruction[24:20];
    assign Rd     = Instruction[11:7];

    assign ReadData1 = (Rs1 != 0) ? registers[Rs1] : 32'b0;
    assign ReadData2 = (Rs2 != 0) ? registers[Rs2] : 32'b0;

    always @(posedge clk) begin
        if (RegWrite && WriteReg != 5'b0)
            registers[WriteReg] <= WriteData;
    end

    // ---- Immediate Generator ----
    reg [31:0] immediate;
    always @(*) begin
        case (opcode)
            7'b0010011,       // I-type: addi, slti, etc.
            7'b0000011:       // I-type: lw
                immediate = {{20{Instruction[31]}}, Instruction[31:20]};
            7'b0100011:       // S-type: sw
                immediate = {{20{Instruction[31]}}, Instruction[31:25], Instruction[11:7]};
            7'b1100011:       // B-type: branches
                immediate = {{20{Instruction[31]}}, Instruction[7], Instruction[30:25],
                             Instruction[11:8], 1'b0};
            default:
                immediate = 32'b0;
        endcase
    end
    assign Immediate = immediate;

    // ---- Control Unit ----
    reg [1:0] aluop;
    reg alusrc, memwrite, memread, branch, memtoreg, regwriteout;

    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type
                aluop = 2'b10; alusrc = 0; memwrite = 0;
                memread = 0; branch = 0; memtoreg = 0; regwriteout = 1;
            end
            7'b0010011: begin // I-type (addi, slli)
                aluop = 2'b00; alusrc = 1; memwrite = 0;
                memread = 0; branch = 0; memtoreg = 0; regwriteout = 1;
            end
            7'b0000011: begin // lw
                aluop = 2'b00; alusrc = 1; memwrite = 0;
                memread = 1; branch = 0; memtoreg = 1; regwriteout = 1;
            end
            7'b0100011: begin // sw
                aluop = 2'b00; alusrc = 1; memwrite = 1;
                memread = 0; branch = 0; memtoreg = 0; regwriteout = 0;
            end
            7'b1100011: begin // branch (bne, bge, beq)
                aluop = 2'b01; alusrc = 0; memwrite = 0;
                memread = 0; branch = 1; memtoreg = 0; regwriteout = 0;
            end
            default: begin
                aluop = 2'b00; alusrc = 0; memwrite = 0;
                memread = 0; branch = 0; memtoreg = 0; regwriteout = 0;
            end
        endcase
    end

    // When ControlMux=1 (hazard stall), zero out all control signals
    assign ALUOp      = ControlMux ? 2'b0 : aluop;
    assign ALUSrc     = ControlMux ? 1'b0 : alusrc;
    assign MemWrite   = ControlMux ? 1'b0 : memwrite;
    assign MemRead    = ControlMux ? 1'b0 : memread;
    assign Branch     = ControlMux ? 1'b0 : branch;
    assign MemtoReg   = ControlMux ? 1'b0 : memtoreg;
    assign RegWriteOut= ControlMux ? 1'b0 : regwriteout;

endmodule
