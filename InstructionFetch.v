// ============================================================
// InstructionFetch.v
// 5-Stage RISC-V Pipelined Processor — IF Stage
// NED University of Engineering and Technology
// EL-421 Embedded Electronics | Open Ended Lab
// ============================================================

module InstructionFetch(
    input         clk,
    input         reset,
    input         PCWrite,          // Hazard: stall PC when 0
    input         PCSrc,            // 1 = take branch
    input  [31:0] BranchTarget,
    output reg [31:0] PC,
    output     [31:0] Instruction,
    output     [31:0] PC_plus_4
);

    // Instruction Memory — 64 words (bubble sort program)
    reg [31:0] instruction_memory [0:63];

    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1)
            instruction_memory[i] = 32'b0;

        // ---- Initialization ----
        instruction_memory[0]  = 32'h00000B13; // addi x22, x0, 0      (i = 0)
        instruction_memory[1]  = 32'h00000B93; // addi x23, x0, 0      (j = 0)
        instruction_memory[2]  = 32'h00A00513; // addi x10, x0, 10     (max = 10)

        // ---- Loop1: array[i] = i ----
        instruction_memory[3]  = 32'h002B1C13; // slli x24, x22, 2
        instruction_memory[4]  = 32'h036C2023; // sw   x22, 0x200(x24)
        instruction_memory[5]  = 32'h001B0B13; // addi x22, x22, 1
        instruction_memory[6]  = 32'hFEAB1EE3; // bne  x22, x10, Loop1

        // ---- Reset i ----
        instruction_memory[7]  = 32'h00000B13; // addi x22, x0, 0

        // ---- Loop2 (outer): i = 0..9 ----
        instruction_memory[8]  = 32'h002B1C13; // slli x24, x22, 2
        instruction_memory[9]  = 32'h000B0B93; // add  x23, x22, x0    (j = i)

        // ---- Loop3 (inner): j = i..9 ----
        instruction_memory[10] = 32'h002B9C93; // slli x25, x23, 2
        instruction_memory[11] = 32'h000C2083; // lw   x1,  0x200(x24) (a[i])
        instruction_memory[12] = 32'h000CD103; // lw   x2,  0x200(x25) (a[j])
        instruction_memory[13] = 32'h0020D663; // bge  x1,  x2, EndIf

        // ---- Swap ----
        instruction_memory[14] = 32'h00008293; // add  x5,  x1,  x0    (temp = a[i])
        instruction_memory[15] = 32'h002C2023; // sw   x2,  0x200(x24) (a[i] = a[j])
        instruction_memory[16] = 32'h005CD023; // sw   x5,  0x200(x25) (a[j] = temp)

        // ---- EndIf / loop control ----
        instruction_memory[17] = 32'h001B8B93; // addi x23, x23, 1
        instruction_memory[18] = 32'hFFAB9EE3; // bne  x23, x10, Loop3
        instruction_memory[19] = 32'h001B0B13; // addi x22, x22, 1
        instruction_memory[20] = 32'hFEAB1EE3; // bne  x22, x10, Loop2
    end

    assign PC_plus_4  = PC + 4;
    assign Instruction = instruction_memory[PC >> 2];

    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'b0;
        else if (PCSrc)
            PC <= BranchTarget;
        else if (PCWrite)
            PC <= PC_plus_4;
        // else: stall — PC holds its value
    end

endmodule
