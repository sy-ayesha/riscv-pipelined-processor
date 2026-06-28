// ============================================================
// MemoryAccess.v
// 5-Stage RISC-V Pipelined Processor — MEM Stage
// Data memory (separate from instruction memory — no structural hazard)
// Array stored at byte-address 0x200 (word-address 0x80 = 128)
// ============================================================

module MemoryAccess(
    input         clk,
    input  [31:0] ALUResult,    // Effective byte address
    input  [31:0] WriteData,
    input         MemWrite,
    input         MemRead,

    output [31:0] ReadData
);

    // 256-word data memory (1 KB)
    reg [31:0] data_memory [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            data_memory[i] = 32'b0;
    end

    // Word-addressed via bits [9:2] of the byte address
    wire [7:0] word_addr = ALUResult[9:2];

    always @(posedge clk) begin
        if (MemWrite)
            data_memory[word_addr] <= WriteData;
    end

    assign ReadData = MemRead ? data_memory[word_addr] : 32'b0;

endmodule
