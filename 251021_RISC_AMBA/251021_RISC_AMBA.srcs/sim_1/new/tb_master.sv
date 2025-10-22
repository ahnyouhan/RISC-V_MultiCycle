`timescale 1ns / 1ps

module tb_master();
    // global signals
    logic        PCLK,
    logic        PRESET,
    // APB Interface signals
    logic [31:0] PADDR,
    logic        PWRITE,
    logic        PENABLE,
    logic [31:0] PWDATA,
    logic        PSEL0,
    logic        PSEL1,
    logic        PSEL2,
    logic        PSEL3,
    logic [31:0] PRDATA0,
    logic [31:0] PRDATA1,
    logic [31:0] PRDATA2,
    logic [31:0] PRDATA3,
    logic        PREADY0,
    logic        PREADY1,
    logic        PREADY2,
    logic        PREADY3,

    // Internal Interface Signals
    logic        transfer,
    logic        write,
    logic [31:0] addr,
    logic [31:0] wdata,
    logic [31:0] rdata,
    logic        ready

    // DUT
    APB_Manager DUT (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PSEL0(PSEL0),
        .PSEL1(PSEL1),
        .PSEL2(PSEL2),
        .PSEL3(PSEL3),
        .PRDATA0(PRDATA0),
        .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2),
        .PRDATA3(PRDATA3),
        .PREADY0(PREADY0),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .transfer(transfer),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready)
    );
    
    always #5 PCLK = ~PCLK;

endmodule

module slave (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);
    logic [31:0] mem[0:255]; // 256 단어 RAM

    always_ff @( posedge PCLK, posedge PRESET ) begin : blockName
        if(PRESET) begin
            PRDATA <= 0;
            PREADY <= 0;
        end else if(PSEL && PENABLE) begin
            PREADY <= 1;
            if(PRWITE) mem[PADDR[9:2]] <= PWDATA; // write
            else PRDATA <= mem[PADDR[9:2]];       // read
        end else begin
            PREADY = 0;
        end
    end
    
endmodule
