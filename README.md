# fifo

[![CI](https://github.com/drewbabel/fifo/actions/workflows/ci.yml/badge.svg)](https://github.com/drewbabel/fifo/actions/workflows/ci.yml)

A configurable synchronous and asynchronous FIFO in SystemVerilog, with:

- Binary pointers with a wrap bit for full and empty detection in a single clock domain.
- Gray-coded pointers through two-flop synchronizers to cross two independent clock domains.
- A dual-port memory with separate read and write ports, mapping to distributed RAM at this depth.
- `wptr_full` and `rptr_empty` managing pointer state and flag logic in their own domains.

![Synchronous FIFO block diagram](docs/sync_fifo_block.svg)

![Asynchronous FIFO block diagram](docs/async_fifo_block.svg)

## Verification

| Module | Method |
|--------|--------|
| `synchronizer` | Self-checking testbench |
| `sync_fifo` | Self-checking testbench |
| `async_fifo` | Self-checking testbench + SymbiYosys proofs |

`fifomem`, `wptr_full`, and `rptr_empty` are exercised through the `async_fifo` testbench and covered by its proof.

The asynchronous proof runs unbounded k-induction over every input and clock pattern. It establishes that occupancy never exceeds `DEPTH`, that `empty` and `full` assert exactly at zero and `DEPTH`, that the Gray-coded pointers hold their ring ordering, and that neither pointer ever passes the other.

## Implementation

Synthesized for the Xilinx Artix-7 XC7A35T through Yosys and nextpnr-xilinx.

| Module | LUTs | Flip-flops | Distributed RAM | Fmax |
|--------|------|------------|-----------------|------|
| `synchronizer` | 0 | 2 | 0 | |
| `fifomem` | 2 | 8 | 0 | |
| `sync_fifo` | 8 | 18 | 2 | 324 MHz |
| `wptr_full` | 9 | 9 | 0 | |
| `rptr_empty` | 9 | 9 | 0 | |
| `async_fifo` | 19 | 46 | 2 | 296 MHz write, 343 MHz read |

`fmax.sh` places and routes each FIFO in a registered-boundary harness. The frequencies come from nextpnr-xilinx, an experimental open-source flow with no vendor-signed timing analysis. `async_fifo` carries one frequency per clock domain, since a single figure has no meaning across two independent clocks.

## Building and running

```
make MOD=sync_fifo                                  # run a module's testbench
make wave MOD=sync_fifo                             # run the testbench and open the waveform in Surfer
make formal MOD=async_fifo                          # run the module's SymbiYosys proof
./synth_stats.sh sync_fifo                          # report a module's synthesis cost
./fmax.sh async_fifo tt_async_fifo wr_clk rd_clk    # fmax and utilization
```

### Tool versions

Icarus Verilog 13.0, Yosys 0.66, SymbiYosys 0.66 with Z3, nextpnr-xilinx 0.8.2, and Surfer.
