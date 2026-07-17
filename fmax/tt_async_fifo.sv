// Async FIFO harness
module tt_async_fifo (
    input  logic wr_clk,
    input  logic rd_clk,
    input  logic rst_n,
    input  logic si,
    output logic so_w,
    output logic so_r
);
  localparam int NW = 9;

  logic [NW-1:0] win_r;
  logic rin_r;
  logic full_w;
  logic [7:0] rd_data_w;
  logic empty_w;

  always_ff @(posedge wr_clk) win_r <= {win_r[NW-2:0], si};
  always_ff @(posedge rd_clk) rin_r <= si;

  async_fifo dut (
      .wr_clk  (wr_clk),
      .wr_rst_n(rst_n),
      .wr_en   (win_r[0]),
      .wr_data (win_r[8:1]),
      .full    (full_w),
      .rd_clk  (rd_clk),
      .rd_rst_n(rst_n),
      .rd_en   (rin_r),
      .rd_data (rd_data_w),
      .empty   (empty_w)
  );

  always_ff @(posedge wr_clk) so_w <= full_w;
  always_ff @(posedge rd_clk) so_r <= ^{rd_data_w, empty_w};
endmodule
