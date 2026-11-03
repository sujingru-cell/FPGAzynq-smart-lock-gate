from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def strip_verilog_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    return text


verilog_files = sorted(SRC.glob("*.v"))
if not verilog_files:
    fail("no Verilog sources found")

modules = []
for path in verilog_files:
    text = strip_verilog_comments(read(path))
    modules.extend(re.findall(r"\bmodule\s+([A-Za-z_]\w*)", text))
    if len(re.findall(r"\bmodule\b", text)) != len(re.findall(r"\bendmodule\b", text)):
        fail(f"module/endmodule mismatch in {path.name}")

required_modules = {
    "simulation_core_v5p",
    "scheduler_v5p",
    "arrival_fifo_v5p",
    "trend_history_v5p",
    "vga_aux_pages_v5p",
    "vga_scene_v5",
}
missing = sorted(required_modules.difference(modules))
if missing:
    fail("missing modules: " + ", ".join(missing))

top = read(SRC / "top.v")
for instance in ("u_eff", "u_save", "u_auto"):
    if instance not in top:
        fail(f"missing policy core instance: {instance}")

for mode in (".POLICY_MODE(2'd0)", ".POLICY_MODE(2'd1)", ".POLICY_MODE(2'd2)"):
    if mode not in top:
        fail(f"missing policy mode: {mode}")

if "pb0_sync" not in top or "~pb0_sync" not in top:
    fail("PB0 reset synchronizer not found")
if ".pb_n(pb1)" not in top:
    fail("PB1 page-button connection not found")

for filename in ("vga_scene_v5.v", "vga_aux_pages_v5p.v"):
    text = strip_verilog_comments(read(SRC / filename))
    text = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("`timescale"))
    text = re.sub(r'"(?:\\.|[^"\\])*"', "", text)
    if re.search(r"(?<!/)/(?!/)|%", text):
        fail(f"runtime divide/modulo found in VGA source: {filename}")

xdc = read(ROOT / "constraints" / "edk_z7_tcc_v5_parallel.xdc")
if "PACKAGE_PIN AA18" not in xdc or "IOSTANDARD LVCMOS33 [get_ports clk]" not in xdc:
    fail("100 MHz clock constraint does not match the target board")
if "PACKAGE_PIN H17 [get_ports pb0]" not in xdc:
    fail("PB0 pin constraint missing")
if "PACKAGE_PIN C19 [get_ports pb1]" not in xdc:
    fail("PB1 pin constraint missing")

water_model = read(SRC / "water_model_v5.v")
if "step_div == 3'd4" not in water_model:
    fail("water transition pacing check failed")

main_vga = read(SRC / "vga_scene_v5.v")
aux_vga = read(SRC / "vga_aux_pages_v5p.v")
if "r = 4'h0; g = 4'h0; b = 4'h0;" not in main_vga:
    fail("MAIN background is not forced to black")
if "r=0; g=0; b=0;" not in aux_vga:
    fail("auxiliary VGA background is not forced to black")

print("Repository checks passed")
print(f"  Verilog files : {len(verilog_files)}")
print(f"  Modules       : {len(modules)}")
print("  Policy cores  : EFF / SAVE / AUTO")
print("  Controls      : PB0 reset, PB1 page")
print("  VGA pixel path: no runtime divide/modulo")
print("  Clock         : AA18, LVCMOS33, 100 MHz")
