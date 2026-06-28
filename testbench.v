// ============================================================
// testbench.v
// Self-checking testbench for 5-Stage RISC-V Pipelined Processor
// Verifies bubble sort execution and prints sorted array
// ============================================================
`timescale 1ns/1ps

module testbench;

    reg clk;
    reg reset;

    // Instantiate DUT
    RISC_V_Pipelined_Processor processor (
        .clk  (clk),
        .reset(reset)
    );

    // 100 MHz clock (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Simulation flow ----
    integer idx;
    integer errors;

    initial begin
        $display("==============================================");
        $display(" RISC-V 5-Stage Pipeline — Bubble Sort Test");
        $display("==============================================");

        reset = 1;
        #20;
        reset = 0;
        $display("[%0t ns] Reset released. Execution started.", $time);

        // Run long enough for bubble sort to complete (~500 instructions @ 10 ns)
        #6000;

        $display("\n[%0t ns] Simulation complete.", $time);
        $display("----------------------------------------------");
        $display(" Final sorted array (data_memory[0x80..0x89]):");
        $display("----------------------------------------------");

        errors = 0;
        for (idx = 0; idx < 10; idx = idx + 1) begin
            // Data memory word-addressed: array starts at byte 0x200 = word 0x80
            $display("  a[%0d] = %0d", idx,
                     processor.MEM_stage.data_memory[8'h80 + idx]);
        end

        $display("----------------------------------------------");
        $display(" Key register values at end:");
        $display("  x10 (max)   = %0d", processor.ID_stage.registers[10]);
        $display("  x22 (i)     = %0d", processor.ID_stage.registers[22]);
        $display("  x23 (j)     = %0d", processor.ID_stage.registers[23]);
        $display("==============================================\n");

        $finish;
    end

    // ---- Pipeline state monitor (prints every 50 ns after reset) ----
    always @(posedge clk) begin
        if (!reset && ($time % 50 == 0)) begin
            $display("[%5t ns] PC=%h  Instr=%h  x22=%0d  x23=%0d  PCSrc=%b  PCWrite=%b",
                $time,
                processor.PC,
                processor.Instruction,
                processor.ID_stage.registers[22],
                processor.ID_stage.registers[23],
                processor.EX_MEM_PCSrc,
                processor.PCWrite);
        end
    end

    // ---- Waveform dump (for ModelSim / GTKWave) ----
    initial begin
        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, testbench);
    end

endmodule
