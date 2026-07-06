`timescale 1ns / 1ps
// Throwaway testbench that generates async_wave.csv for the README waveform figure.
// Write and read run on independent clocks (wr_clk faster than rd_clk) so the
// clock-domain crossing is visible: the write side fills and asserts full, then
// the read side drains and asserts empty, each flag reacting a synchronizer
// delay after the far pointer crosses. A fine sample clock dumps every signal.
//
// Regenerate the CSV from the repo root:
//   iverilog -g2012 -s async_fifo_wave_tb -o awave.vvp rtl/synchronizer.sv rtl/fifomem.sv \
//     rtl/rptr_empty.sv rtl/wptr_full.sv rtl/async_fifo.sv docs/async_fifo_wave_tb.sv && vvp awave.vvp
// then render the PNG with docs/async_fifo_waveform.py
module async_fifo_wave_tb;
  localparam int WIDTH = 8;
  localparam int DEPTH = 8;

  logic wr_clk = 0, rd_clk = 0;
  logic wr_rst_n = 0, rd_rst_n = 0;
  logic wr_en = 0, rd_en = 0;
  logic [WIDTH-1:0] wr_data;
  logic [WIDTH-1:0] rd_data;
  logic full, empty;

  async_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
      .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
      .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
  );

  always #5 wr_clk = ~wr_clk;   // 10 ns period (write domain, fast)
  always #8 rd_clk = ~rd_clk;   // 16 ns period (read domain, slow)

  // Write side: reset, then push until full
  initial begin
    wr_data = 8'hC0;
    repeat (2) @(posedge wr_clk);
    wr_rst_n = 1'b1;
    @(posedge wr_clk);
    for (int i = 0; i < DEPTH + 6; i++) begin
      #1;
      if (!full) begin
        wr_en   = 1'b1;
        wr_data = 8'hC0 + i;
      end else begin
        wr_en = 1'b0;
      end
      @(posedge wr_clk);
    end
    #1 wr_en = 1'b0;
  end

  // Read side: hold, let the FIFO fill, then drain until empty
  initial begin
    repeat (2) @(posedge rd_clk);
    rd_rst_n = 1'b1;
    // wait for full to propagate into the read domain, then drain
    wait (full);
    repeat (3) @(posedge rd_clk);
    for (int i = 0; i < DEPTH + 6; i++) begin
      #1 rd_en = (!empty);
      @(posedge rd_clk);
    end
    #1 rd_en = 1'b0;
  end

  // Fine sample clock: dump every signal on a 2 ns grid
  logic sclk = 0;
  always #1 sclk = ~sclk;  // 2 ns period
  integer f;
  initial begin
    f = $fopen("async_wave.csv", "w");
    $fwrite(f, "t,wr_clk,rd_clk,wr_en,rd_en,full,empty,rd_data\n");
  end
  always @(posedge sclk)
    if (f != 0)
      $fwrite(f, "%0t,%b,%b,%b,%b,%b,%b,%0d\n",
              $time, wr_clk, rd_clk, wr_en, rd_en, full, empty, rd_data);

  // End a little after the FIFO drains back to empty
  initial begin
    @(posedge wr_rst_n);
    wait (full);   // filled
    wait (empty);  // drained
    repeat (8) @(posedge rd_clk);
    $fclose(f); f = 0;
    $finish;
  end

  initial begin
    #100000;
    $display("TIMEOUT");
    $fclose(f); f = 0;
    $finish;
  end
endmodule
