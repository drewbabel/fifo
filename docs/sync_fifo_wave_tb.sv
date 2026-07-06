`timescale 1ns / 1ps
// Throwaway testbench that generates sync_wave.csv for the README waveform figure.
// A short DEPTH=8 instance is filled to full, then drained to empty, so the
// full/empty flags and the pointer wrap are both visible in one readable window.
//
// Regenerate the CSV from the repo root:
//   iverilog -g2012 -s sync_fifo_wave_tb -o swave.vvp rtl/sync_fifo.sv docs/sync_fifo_wave_tb.sv && vvp swave.vvp
// then render the PNG with docs/sync_fifo_waveform.py
module sync_fifo_wave_tb;
  localparam int WIDTH = 8;
  localparam int DEPTH = 8;

  logic clk = 0, rst_n = 0;
  logic wr_en = 0, rd_en = 0;
  logic [WIDTH-1:0] wr_data;
  logic [WIDTH-1:0] rd_data;
  logic full, empty;

  sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
      .clk(clk), .rst_n(rst_n),
      .wr_en(wr_en), .rd_en(rd_en),
      .wr_data(wr_data), .rd_data(rd_data),
      .full(full), .empty(empty)
  );

  always #5 clk = ~clk;  // 10 ns period

  integer f;
  initial begin
    f = $fopen("sync_wave.csv", "w");
    $fwrite(f, "t,wr_en,rd_en,full,empty,wr_data,rd_data\n");
    wr_data = 8'hA0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // Write until full: A0, A1, ...
    for (int i = 0; i < DEPTH + 2; i++) begin
      #1 wr_en = 1'b1; rd_en = 1'b0; wr_data = 8'hA0 + i;
      @(posedge clk);
    end
    #1 wr_en = 1'b0;
    @(posedge clk);

    // Read until empty
    for (int i = 0; i < DEPTH + 2; i++) begin
      #1 rd_en = 1'b1; wr_en = 1'b0;
      @(posedge clk);
    end
    #1 rd_en = 1'b0;
    repeat (2) @(posedge clk);
    $fclose(f);
    $finish;
  end

  // Sample every clock into the CSV
  always @(posedge clk)
    $fwrite(f, "%0t,%b,%b,%b,%b,%0d,%0d\n",
            $time, wr_en, rd_en, full, empty, wr_data, rd_data);

  initial begin
    #100000;
    $fclose(f);
    $display("TIMEOUT");
    $finish;
  end
endmodule
