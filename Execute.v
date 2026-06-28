// ============================================================
// Execute.v
// 5-Stage RISC-V Pipelined Processor — EX Stage
// Includes: ALU, Branch Logic, Branch Target Calculation
// ============================================================

module Execute(
    input  [31:0] ReadData1,
    input  [31:0] ReadData2,
    input  [31:0] Immediate,
    input  [31:0] PC,
    input  [1:0]  ALUOp,
    input         ALUSrc,
    input         Branch,
    input  [2:0]  Funct3,
    input  [6:0]  Funct7,
    input  [4:0]  Rs1,
    input  [4:0]  Rs2,
    input  [4:0]  Rd,

    output reg [31:0] ALUResult,
    output     [31:0] BranchTarget,
    output reg        Zero,
    output reg        PCSrc,
    output     [4:0]  WriteReg
);

    wire [31:0] ALUInput2 = ALUSrc ? Immediate : ReadData2;

    // Branch target: PC + (imm << 1)  — imm already has bit-0 = 0
    assign BranchTarget = PC + Immediate;
    assign WriteReg     = Rd;

    // ---- ALU Control Decoder ----
    reg [3:0] ALUControl;
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0010; // ADD  (addi, lw, sw)
            2'b01: ALUControl = 4'b0110; // SUB  (branch compare)
            2'b10: begin                  // R-type / I-shift
                case (Funct3)
                    3'b000: ALUControl = (Funct7 == 7'b0100000) ? 4'b0110 : 4'b0010; // sub/add
                    3'b001: ALUControl = 4'b0100; // sll / slli
                    3'b010: ALUControl = 4'b0111; // slt
                    3'b100: ALUControl = 4'b0101; // xor
                    3'b110: ALUControl = 4'b0001; // or
                    3'b111: ALUControl = 4'b0000; // and
                    default: ALUControl = 4'b0010;
                endcase
            end
            default: ALUControl = 4'b0010;
        endcase
    end

    // ---- ALU ----
    always @(*) begin
        case (ALUControl)
            4'b0000: ALUResult = ReadData1 & ALUInput2;                         // AND
            4'b0001: ALUResult = ReadData1 | ALUInput2;                         // OR
            4'b0010: ALUResult = ReadData1 + ALUInput2;                         // ADD
            4'b0100: ALUResult = ReadData1 << ALUInput2[4:0];                   // SLL
            4'b0101: ALUResult = ReadData1 ^ ALUInput2;                         // XOR
            4'b0110: ALUResult = ReadData1 - ALUInput2;                         // SUB
            4'b0111: ALUResult = ($signed(ReadData1) < $signed(ALUInput2)) ? 32'd1 : 32'd0; // SLT
            default:  ALUResult = ReadData1 + ALUInput2;
        endcase
        Zero = (ALUResult == 32'b0);
    end

    // ---- Branch Resolution ----
    always @(*) begin
        if (Branch) begin
            case (Funct3)
                3'b000: PCSrc = Zero;                                  // beq
                3'b001: PCSrc = ~Zero;                                 // bne
                3'b100: PCSrc = ($signed(ReadData1) <  $signed(ReadData2)); // blt
                3'b101: PCSrc = ($signed(ReadData1) >= $signed(ReadData2)); // bge
                3'b110: PCSrc = (ReadData1 <  ReadData2);              // bltu
                3'b111: PCSrc = (ReadData1 >= ReadData2);              // bgeu
                default: PCSrc = 1'b0;
            endcase
        end else begin
            PCSrc = 1'b0;
        end
    end

endmodule
