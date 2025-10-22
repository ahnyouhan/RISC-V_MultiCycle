`timescale 1ns / 1ps

module tb_master();
    // global signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface signals
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic        PSEL0, PSEL1, PSEL2, PSEL3;
    logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3;
    logic        PREADY0, PREADY1, PREADY2, PREADY3;

    // Internal Interface Signals
    logic        transfer;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        ready;

    // DUT
    APB_Manager DUT (.*);

    // ──────────────── 4개 슬레이브 인스턴스 (연결 수정됨) ────────────────
    
    // Slave 0 (RAM, 1000_0xxx) -> PSEL0, PRDATA3, PREADY3
    slave U_RAM (
        .PCLK(PCLK), .PRESET(PRESET), .PADDR(PADDR), .PWRITE(PWRITE), .PENABLE(PENABLE), .PWDATA(PWDATA),
        .PSEL(PSEL0),
        .PRDATA(PRDATA3),
        .PREADY(PREADY3)
    );

    // Slave 1 (P1, 1000_1xxx) -> PSEL1, PRDATA0, PREADY0
    slave U_P1 (
        .PCLK(PCLK), .PRESET(PRESET), .PADDR(PADDR), .PWRITE(PWRITE), .PENABLE(PENABLE), .PWDATA(PWDATA),
        .PSEL(PSEL1),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0)
    );

    // Slave 2 (P2, 1000_2xxx) -> PSEL2, PRDATA1, PREADY1
    slave U_P2 (
        .PCLK(PCLK), .PRESET(PRESET), .PADDR(PADDR), .PWRITE(PWRITE), .PENABLE(PENABLE), .PWDATA(PWDATA),
        .PSEL(PSEL2),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1)
    );

    // Slave 3 (P3, 1000_3xxx) -> PSEL3, PRDATA2, PREADY2
    slave U_P3 (
        .PCLK(PCLK), .PRESET(PRESET), .PADDR(PADDR), .PWRITE(PWRITE), .PENABLE(PENABLE), .PWDATA(PWDATA),
        .PSEL(PSEL3),
        .PRDATA(PRDATA2),
        .PREADY(PREADY2)
    );

    // ──────────────── 클럭 생성 ────────────────
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    // ──────────────── FSM 정의 (2-State로 수정) ────────────────
    typedef enum logic {IDLE, WAIT_RDY} master_state;
    master_state state, next_state;

    logic [31:0] addr_reg;
    logic [31:0] wdata_reg;
    logic [6:0]  tx_count_reg; // 0~99 (100개 카운트)

    // ──────────────── 상태 업데이트 (Sequential) ────────────────
    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            state        <= IDLE;
            addr_reg     <= 32'h1000_0000; // Slave0(RAM) 부터 시작
            wdata_reg    <= 32'h1;
            tx_count_reg <= 7'd0;
        end else begin
            state <= next_state;

            // 트랜잭션이 완료되었을 때 (WAIT_RDY -> IDLE로 복귀 시)
            // 다음 트랜잭션 값을 미리 준비
            if (state == WAIT_RDY && ready) begin
                if (tx_count_reg < 99) begin
                    tx_count_reg <= tx_count_reg + 1;
                    wdata_reg    <= wdata_reg + 1;

                    // 다음 보낼 주소 계산 (tx_count_reg 값 기준)
                    case (tx_count_reg[1:0])
                        2'd0: addr_reg <= 32'h1000_1000; // 다음은 Slave1
                        2'd1: addr_reg <= 32'h1000_2000; // 다음은 Slave2
                        2'd2: addr_reg <= 32'h1000_3000; // 다음은 Slave3
                        2'd3: addr_reg <= 32'h1000_0000; // 다음은 Slave0
                    endcase
                end else begin
                    tx_count_reg <= tx_count_reg + 1; // 100
                end
            end
        end
    end

    // ──────────────── FSM 조합 논리 (Combinational) ────────────────
    always_comb begin
        next_state = state;
        transfer   = 1'b0;
        write      = 1'b1; // 쓰기 전용
        addr       = addr_reg;
        wdata      = wdata_reg;

        case (state)
            IDLE: begin
                if (tx_count_reg < 100) begin
                    // 1. transfer를 1 사이클만 켜서 트랜잭션 시작
                    transfer   = 1'b1;
                    next_state = WAIT_RDY;
                end else begin
                    // 100개 완료 후 멈춤
                    transfer   = 1'b0;
                    next_state = IDLE;
                end
            end
            WAIT_RDY: begin
                // 2. transfer=0으로 내리고 ready 신호 대기
                transfer = 1'b0;
                if (ready) begin
                    next_state = IDLE; // 3. 완료! 다시 IDLE로
                end else begin
                    next_state = WAIT_RDY; // 계속 대기
                end
            end
        endcase
    end
    
    // ──────────────── 시뮬레이션 제어 ────────────────
    initial begin
        PRESET = 1;
        #20 PRESET = 0; // 20ns 동안 리셋

        // 100개 데이터 전송 완료될 때까지 기다림
        wait (tx_count_reg == 100);
        #100; // 추가 대기
        $display("T=%0t: 100회 쓰기 완료. 시뮬레이션 종료.", $time);
        $finish;
    end

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
    logic [7:0] mem[0:2**12-1];

    always_ff @( posedge PCLK, posedge PRESET ) begin
        if(PRESET) begin
            PRDATA <= 0;
            PREADY <= 0;
        end else if(PSEL && PENABLE) begin
            PREADY <= 1;
            if(PWRITE) begin 
                mem[PADDR[11:0]+0] <= PWDATA[7:0]; // write
                mem[PADDR[11:0]+1] <= PWDATA[15:8]; // write
                mem[PADDR[11:0]+2] <= PWDATA[23:16]; // write
                mem[PADDR[11:0]+3] <= PWDATA[31:24]; // write
            end else begin
                PRDATA[7:0] <= mem[PADDR[11:0]+0];       // read
                PRDATA[15:8] <= mem[PADDR[11:0]+1];       // read
                PRDATA[23:16] <= mem[PADDR[11:0]+2];       // read
                PRDATA[31:24] <= mem[PADDR[11:0]+3];       // read
            end
        end else begin
            PREADY <= 0;
        end
    end
    
endmodule

