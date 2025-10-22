`timescale 1ns / 1ps

interface apb_master_if (
    input logic clk,
    input logic reset
);
    logic        transfer;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        ready;
endinterface
class apbSignal;
    logic                        transfer;
    logic                        write;
    rand logic                 [31:0] addr;
    rand logic            [31:0] wdata;
    // logic                 [31:0] rdata;
    // logic                        ready;
    constraint c_addr{
        addr inside {[32'h1000_0000:32'h1000_000c]};
    }
    constraint c_wdata{
        wdata inside {[32'h00000000:32'hFFFFFFFF]};
    }
    virtual apb_master_if        m_if;
    function new(virtual apb_master_if m_if);
        this.m_if = m_if;
    endfunction  //new()

    task automatic send(logic [31:0] addr);
        m_if.transfer <= 1'b1;
        m_if.write    <= 1'b1;
        m_if.addr     <= addr;
        m_if.wdata    <= wdata;
        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;
        @(posedge m_if.clk);
        wait (m_if.ready);
        @(posedge m_if.clk);
    endtask
    task automatic receive(logic [31:0] addr);
        m_if.transfer <= 1'b1;
        m_if.write <= 1'b0;
        m_if.addr <= addr;
        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;
        @(posedge m_if.clk);
        wait (m_if.ready);
        @(posedge m_if.clk);
    endtask  //automatic



endclass  //

module tb_APB ();
    //global signals
    logic        PCLK;
    logic        PRESET;
    //APB Interface Signal;
    logic [ 3:0] PADDR;
    logic        PWRITE;
    //logic        PSEL;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;

    logic        PSEL0;
    logic        PSEL1;
    logic        PSEL2;
    logic        PSEL3;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic        PREADY0;
    logic        PREADY1;
    logic        PREADY2;
    logic        PREADY3;

    apb_master_if m_if (
        PCLK,
        PRESET
    );

    apbSignal apbUART;  // handler
    apbSignal apbGPIO;  // handler
    apbSignal apbTimer;  // handler

    APB_Manager dut_manager (
        .*,
        .transfer(m_if.transfer),
        .write(m_if.write),
        .addr(m_if.addr),
        .wdata(m_if.wdata),
        .rdata(m_if.rdata),
        .ready(m_if.ready)
    );
    APB_Slave dut_slave0 (
        .PSEL  (PSEL0),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0),
        .*
    );
    APB_Slave dut_slave1 (
        .PSEL  (PSEL1),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1),
        .*
    );
    APB_Slave dut_slave2 (
        .PSEL  (PSEL2),
        .PRDATA(PRDATA2),
        .PREADY(PREADY2),
        .*
    );
    APB_Slave dut_slave3 (
        .PSEL  (PSEL3),
        .PRDATA(PRDATA3),
        .PREADY(PREADY3),
        .*
    );

    always #5 PCLK = ~PCLK;

    initial begin
        #00 PCLK = 0;
        PRESET = 1;
        #10 PRESET = 0;
    end

    initial begin
        apbUART  = new(m_if);
        apbGPIO  = new(m_if);
        apbTimer = new(m_if);

        repeat (3) @(posedge PCLK);

        apbUART.randomize();
        apbUART.send(32'h1000_0000);
        apbUART.receive(32'h1000_0000);

        apbGPIO.randomize();
        apbGPIO.send(32'h1000_1000);
        apbGPIO.receive(32'h1000_1000);

        apbTimer.randomize();
        apbTimer.send(32'h1000_2000);
        apbTimer.receive(32'h1000_2000);

        @(posedge PCLK);
        #20;
        $finish;

    end
endmodule
