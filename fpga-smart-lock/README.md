# FPGA Smart Lock Simulator

基于 Zynq-7000 FPGA 的双向两级船闸调度与节水推演工程。项目在同一组船流输入下并行运行 EFF、SAVE 和 AUTO 三套调度核心，并通过 VGA 展示船舶排队、闸门动作、水位变化、SAVE POOL 状态以及策略指标。

当前工程面向 **EDK_Z7_TCC / XC7Z020CLG484-1**，开发环境为 **Vivado 2026.1**。

## 功能概览

- 双向船流与大小船随机到达模型
- 两级船闸状态机与船舶通行动画
- SAVE POOL 标准化储水/回用模型
- EFF、SAVE、AUTO 三种调度策略并行运行
- 相同船流输入下的策略对比
- PASS、WAIT、LOAD、FRESH/SHIP、CONG 等指标统计
- MAIN、COMPARE、TREND 三个 VGA 页面
- PB0 手动复位，PB1 页面切换
- 640×480 VGA 输出，未使用区域为纯黑背景

## 三种策略

**EFF**：效率优先。队列中有可通行船舶时尽快发闸，重点降低等待和积压。

**SAVE**：资源优先。倾向于等待更高装载批次，并配合 SAVE POOL 回用部分水量，降低单位船舶的新鲜水消耗。调度器带有等待超时保护，避免长期饥饿。

**AUTO**：自适应策略。根据实时队列压力和等待状态，在 SAVE 与 EFF 之间进行带滞回的切换。`SW[7:6]` 用于调整切换灵敏度。

## 硬件控制

| 输入 | 功能 |
| --- | --- |
| PB0 | 低电平复位，清空队列、统计量和运行状态 |
| PB1 | 松开后切换页面：MAIN → COMPARE → TREND |
| SW[1:0] | 船舶到达强度：LOW / MED / HIGH / PEAK |
| SW[3:2] | MAIN 页面观察对象：EFF / SAVE / AUTO / AUTO |
| SW[5:4] | 大船比例：约 12.5% / 25% / 50% / 75% |
| SW[7:6] | AUTO 滞回灵敏度：sensitive / normal / stable / very stable |

LED 定义：

| LED | 含义 |
| --- | --- |
| LED0 | 1 秒心跳 |
| LED1 | AUTO 当前采用 EFF |
| LED2 | 当前为 COMPARE 页面 |
| LED3 | 任一输入 FIFO 发生过溢出 |

推荐演示起始设置：`SW[7:0] = 01_01_10_00`，即低船流、AUTO 页面、约 25% 大船比例、normal 滞回。

## VGA 页面

### MAIN

显示当前选中策略的船闸运行过程，包括双向队列、两级闸室、水位、闸门、SAVE POOL 和主要统计指标。

### COMPARE

EFF、SAVE、AUTO 三套核心接收相同的到达事件并独立运行。页面并列显示三种策略的 PASS、WAIT、LOAD、FRESH/SHIP 和 CONG，便于直接比较。

### TREND

记录 AUTO 最近 32 秒的队列压力、单位船舶新鲜用水以及策略选择。策略时间带中 SAVE 与 EFF 使用不同颜色显示。

## 工程结构

```text
.
├── constraints/        # EDK_Z7_TCC 引脚与时钟约束
├── docs/               # 架构、指标和板级说明
├── src/                # Verilog RTL
├── tb/                 # 基础 smoke test
├── tools/              # 仓库静态检查脚本
├── create_project.tcl
├── create_project_here.tcl
└── build_bitstream.tcl
```

Vivado 自动生成的工程目录、日志、缓存、bitstream 和报告不提交到仓库，由 `.gitignore` 统一排除。

## 创建 Vivado 工程

克隆仓库后，在 Vivado Tcl Console 中执行：

```tcl
cd D:/path/to/fpga-smart-lock
source create_project_here.tcl
```

脚本会在 `build/vivado/` 下创建工程，顶层模块为 `top`。

也可以直接运行完整 bitstream 流程：

```tcl
cd D:/path/to/fpga-smart-lock
source build_bitstream.tcl
```

完成后请检查：

- `WNS > 0`
- `TNS = 0`
- `WHS > 0`

时序报告和利用率报告输出到 `build/reports/`。

## 本地静态检查

只需要 Python 3：

```bash
python tools/static_check.py
```

该脚本检查核心模块、三策略实例、PB0/PB1 连接、VGA 像素路径中的除法/取模、时钟约束以及关键显示设置。它不能替代 Vivado 综合、实现和时序分析。

## 指标说明

`AVG WAIT` 当前采用“队列长度积分 / 已通过船数”的比较型等待指标，不是逐船时间戳统计得到的严格平均等待时间。`FRESH/SHIP` 为累计新鲜用水量除以已通过船数。详细定义见 `docs/metrics.md`。

## 板级说明

工程使用 100 MHz PL 时钟和板载 VGA。SW4 在本工程中使用经过目标板验证的 G19 引脚；如果使用不同批次或不同版本的扩展板，请先核对原理图和实际连线。完整引脚说明见 `docs/board-and-controls.md`。
