// ============================================================
// HazardDetectionUnit.v
// Detects load-use data hazards and inserts pipeline stalls
//
// Hazard condition:
//   ID/EX stage has a LOAD instruction (MemRead = 1)
//   AND its destination register (ID_EX_Rd) matches either
//   source register of the IF/ID instruction
//
// Resolution: stall for 1 cycle
//   PCWrite   = 0  → freeze PC
//   IF_ID_Write= 0 → freeze IF/ID register
//   ControlMux = 1 → insert NOP bubble into ID/EX
// ============================================================

module HazardDetectionUnit(
    input  [4:0] IF_ID_Rs1,
    input  [4:0] IF_ID_Rs2,
    input        ID_EX_MemRead,
    input  [4:0] ID_EX_Rd,

    output reg PCWrite,
    output reg IF_ID_Write,
    output reg ControlMux
);

    always @(*) begin
        if (ID_EX_MemRead &&
            ((ID_EX_Rd == IF_ID_Rs1) || (ID_EX_Rd == IF_ID_Rs2)) &&
            (ID_EX_Rd != 5'b0))
        begin
            // Load-use hazard detected — insert 1-cycle stall
            PCWrite     = 1'b0;
            IF_ID_Write = 1'b0;
            ControlMux  = 1'b1;
        end else begin
            // No hazard — normal operation
            PCWrite     = 1'b1;
            IF_ID_Write = 1'b1;
            ControlMux  = 1'b0;
        end
    end

endmodule
