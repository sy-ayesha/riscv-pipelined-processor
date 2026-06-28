// ============================================================
// WriteBack.v
// 5-Stage RISC-V Pipelined Processor — WB Stage
// Selects ALU result OR memory read data for register write-back
// ============================================================

module WriteBack(
    input  [31:0] ALUResult,
    input  [31:0] ReadData,
    input         MemtoReg,

    output [31:0] WriteData
);

    // MemtoReg = 1 → load instruction  → write memory data
    // MemtoReg = 0 → ALU instruction   → write ALU result
    assign WriteData = MemtoReg ? ReadData : ALUResult;

endmodule
