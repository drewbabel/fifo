# Renders sync_fifo_waveform.png (the README sync-FIFO waveform) from sync_wave.csv
# Regenerate the whole figure from the repo root:
#   iverilog -g2012 -s sync_fifo_wave_tb -o swave.vvp rtl/sync_fifo.sv docs/sync_fifo_wave_tb.sv && vvp swave.vvp
#   python3 docs/sync_fifo_waveform.py
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

rows = list(csv.DictReader(open('sync_wave.csv')))
def _si(s):
    s = s.strip()
    return int(s) if s.lstrip('-').isdigit() else -1
def col(n): return [_si(r[n]) for r in rows]
wr_en, rd_en = col('wr_en'), col('rd_en')
full, empty = col('full'), col('empty')
wr_data, rd_data = col('wr_data'), col('rd_data')
N = len(rows)

a, b = 0, N - 1
x = list(range(a, b + 1))

bits = [('wr_en', wr_en), ('rd_en', rd_en), ('full', full), ('empty', empty)]
buses = [('wr_data', wr_data), ('rd_data', rd_data)]
nlanes = len(bits) + len(buses)
lane_h, gap = 0.72, 0.55
pitch = lane_h + gap

fig, ax = plt.subplots(figsize=(13, 0.62 * nlanes + 1.4))
BLUE, RED, GREY = '#2b6cb0', '#c0392b', '#dfe6ee'

def base_of(lane_from_top):
    return (nlanes - 1 - lane_from_top) * pitch

for i, (name, vals) in enumerate(bits):
    base = base_of(i)
    seg = vals[a:b] + [vals[b - 1]]
    ax.axhline(base, color=GREY, lw=0.8, zorder=0)
    ax.step(x, [base + max(v, 0) * lane_h for v in seg], where='post', color=BLUE, lw=1.8, zorder=3)
    ax.text(a - 0.7, base + lane_h / 2, name, ha='right', va='center',
            fontsize=11, family='monospace')

for j, (name, vals) in enumerate(buses):
    base = base_of(len(bits) + j)
    top, bot = base + lane_h, base
    ax.text(a - 0.7, base + lane_h / 2, name, ha='right', va='center',
            fontsize=11, family='monospace')
    seg_start = a
    for i in range(a + 1, b + 1):
        if i == b or vals[i] != vals[i - 1]:
            val = vals[seg_start]
            ax.plot([seg_start, i], [top, top], color=RED, lw=1.7, zorder=3)
            ax.plot([seg_start, i], [bot, bot], color=RED, lw=1.7, zorder=3)
            ax.plot([seg_start, seg_start], [bot, top], color=RED, lw=1.2, zorder=3)
            if i - seg_start >= 2:
                label = "0x??" if val < 0 else f"0x{val:02X}"
                ax.text((seg_start + i) / 2, base + lane_h / 2, label,
                        ha='center', va='center', fontsize=9.0, family='monospace', color=RED)
            seg_start = i

ax.set_xlim(a - 3.3, b + 1)
ax.set_ylim(-0.4, base_of(0) + lane_h + 0.4)
ax.set_yticks([])
ax.set_xlabel('clock cycles', fontsize=10)
xt = list(range(a, b + 1, 4))
ax.set_xticks(xt)
ax.set_xticklabels([str(t - a) for t in xt], fontsize=9)
for s in ('top', 'right', 'left'):
    ax.spines[s].set_visible(False)
ax.set_title('Synchronous FIFO: Fill to Full, Drain to Empty (DEPTH = 8)', fontsize=13, pad=16)
plt.tight_layout()
plt.savefig('sync_fifo_waveform.png', dpi=150, bbox_inches='tight')
print('wrote sync_fifo_waveform.png; rows', N)
