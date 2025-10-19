`timescale 1ns / 1ps

module tb_rv32i();
    logic clk;
    logic reset;

    MCU dut (.*);

    always #5 clk = ~clk;

    initial begin
        #00 clk=0; reset =1;
        #10 reset = 0;
        #270000 $finish;
    end
endmodule
