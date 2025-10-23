`timescale 1ns / 1ps

interface apbSignalTester_if (
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

class transaction;
    logic       transfer;
    logic       write;
    rand logic [31:0] addr;
    rand logic [31:0] wdata;
    logic [31:0] rdata;

    constraint c_addr {
        addr inside {
            [32'h1000_0000:32'h1000_000c],
            [32'h1000_1000:32'h1000_100c],
            [32'h1000_2000:32'h1000_200c],
            [32'h1000_3000:32'h1000_300c]
        };
        addr % 4 ==0;
    }

    task print(string tag);
        $display("%0t [%s], transfer = %h, write = %h, addr = %h, wdata = %h, rdata = %h", $time, tag, transfer, write, addr, wdata, rdata);
    endtask //
endclass //transaction

class apbSignal;
    transaction tr;
    virtual apbSignalTester_if m_if;

    function new(virtual apbSignalTester_if m_if);
        this.m_if = m_if;
        this.tr = new();
    endfunction  //new()

    task automatic send();
        tr.transfer = 1'b1;
        tr.write = 1'b1;
        m_if.transfer <= tr.transfer;
        m_if.write    <= tr.write;
        m_if.addr     <= tr.addr;
        m_if.wdata    <= tr.wdata;
        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;
        @(posedge m_if.clk);
        wait (m_if.ready);
        tr.print("   SEND");
        @(posedge m_if.clk);
    endtask
    task automatic receive();
        tr.transfer = 1'b1;
        tr.write = 1'b0;
        m_if.transfer <= tr.transfer;
        m_if.write <= tr.write;
        m_if.addr <= tr.addr;
        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;
        @(posedge m_if.clk);
        wait (m_if.ready);
        tr.rdata = m_if.rdata;
        tr.print("RECEIVE");
        @(posedge m_if.clk);
    endtask
    task automatic compare();
        if(tr.wdata == tr.rdata) begin
            $display("PASS!");
        end else begin
            $display("FAIL..");
        end
    endtask //automatic
    task automatic run(int loop);
        repeat(loop) begin
            tr.randomize();   
            send();
            receive();
            compare();        
        end
        
    endtask



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

    apbSignalTester_if m_if (
        PCLK,
        PRESET
    );

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

    apbSignal apbSignalTester;  // handler

    initial begin
        apbSignalTester = new(m_if);


        repeat (3) @(posedge PCLK);
        apbSignalTester.run(100);

        @(posedge PCLK);
        #20;
        $finish;

    end
endmodule
