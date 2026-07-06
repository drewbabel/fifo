# Renders async_fifo_waveform.png (the README async-FIFO waveform) from async_wave.csv
# Two independent clocks are shown as their own lanes so the clock-domain crossing
# is visible: full asserts a synchronizer delay after the write side fills, and
# empty asserts a synchronizer delay after the read side drains.
# Regenerate the whole figure from the repo root:
#   iverilog -g2012 -s async_fifo_wave_tb -o awave.vvp rtl/synchronizer.sv rtl/fifomem.sv \
#     rtl/rptr_empty.sv rtl/wptr_full.sv rtl/async_fifo.sv docs/async_fifo_wave_tb.sv && vvp awave.vvp
#   python3 docs/async_fifo_waveform.py
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

rows = list(csv.DictReader(open('async_wave.csv')))
def _si(s):
    s = s.strip()
    return int(s) if s.lstrip('-').isdigit() else -1
def col(n): return [_si(r[n]) for r in rows]
t = [v / 1000.0 for v in col('t')]  # timescale prints ps; show ns
wr_clk, rd_clk = col('wr_clk'), col('rd_clk')
wr_en, rd_en = col('wr_en'), col('rd_en')
full, empty = col('full'), col('empty')
rd_data = col('rd_data')
N = len(rows)

a, b = 0, N - 1
x = t[a:b + 1]

bits = [('wr_clk', wr_clk), ('wr_en', wr_en), ('full', full),
        ('rd_clk', rd_clk), ('rd_en', rd_en), ('empty', empty)]
buses = [('rd_data', rd_data)]
nlanes = len(bits) + len(buses)
lane_h, gap = 0.72, 0.55
pitch = lane_h + gap

fig, ax = plt.subplots(figsize=(14, 0.62 * nlanes + 1.4))
BLUE, RED, GREY = '#2b6cb0', '#c0392b', '#dfe6ee'

def base_of(lane_from_top):
    return (nlanes - 1 - lane_from_top) * pitch

for i, (name, vals) in enumerate(bits):
    base = base_of(i)
    seg = vals[a:b + 1]
    ax.axhline(base, color=GREY, lw=0.8, zorder=0)
    ax.step(x, [base + max(v, 0) * lane_h for v in seg], where='post', color=BLUE, lw=1.6, zorder=3)
    ax.text(x[0] - (x[-1] - x[0]) * 0.035, base + lane_h / 2, name, ha='right', va='center',
            fontsize=11, family='monospace')

for j, (name, vals) in enumerate(buses):
    base = base_of(len(bits) + j)
    top, bot = base + lane_h, base
    ax.text(x[0] - (x[-1] - x[0]) * 0.035, base + lane_h / 2, name, ha='right', va='center',
            fontsize=11, family='monospace')
    seg_start = a
    for i in range(a + 1, b + 1):
        if i == b or vals[i] != vals[i - 1]:
            val = vals[seg_start]
            xs0, xs1 = t[seg_start], t[i]
            ax.plot([xs0, xs1], [top, top], color=RED, lw=1.6, zorder=3)
            ax.plot([xs0, xs1], [bot, bot], color=RED, lw=1.6, zorder=3)
            ax.plot([xs0, xs0], [bot, top], color=RED, lw=1.1, zorder=3)
            if xs1 - xs0 >= 12:
                label = "0x??" if val < 0 else f"0x{val:02X}"
                ax.text((xs0 + xs1) / 2, base + lane_h / 2, label,
                        ha='center', va='center', fontsize=8.5, family='monospace', color=RED)
            seg_start = i

span = x[-1] - x[0]
ax.set_xlim(x[0] - span * 0.11, x[-1] + span * 0.02)
ax.set_ylim(-0.4, base_of(0) + lane_h + 0.4)
ax.set_yticks([])
ax.set_xlabel('time (ns)', fontsize=10)
for s in ('top', 'right', 'left'):
    ax.spines[s].set_visible(False)
ax.set_title('Asynchronous FIFO: Write Domain Fills, Read Domain Drains (independent clocks)',
             fontsize=13, pad=16)
plt.tight_layout()
plt.savefig('async_fifo_waveform.png', dpi=150, bbox_inches='tight')
print('wrote async_fifo_waveform.png; rows', N)
