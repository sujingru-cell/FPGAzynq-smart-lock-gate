# Board and controls

目标器件：`XC7Z020CLG484-1`  
目标板：EDK_Z7_TCC  
PL 时钟：100 MHz

## 时钟

| 信号 | 引脚 | I/O 标准 |
| --- | --- | --- |
| clk | AA18 | LVCMOS33 |

AA18 在该板上的时钟路由需要实现阶段的 `CLOCK_DEDICATED_ROUTE FALSE` 例外。该约束单独放在 `constraints/clock_impl.xdc`，并由工程脚本设置为只用于 Implementation。

## 按键

| 信号 | 引脚 | I/O 标准 | 功能 |
| --- | --- | --- | --- |
| PB0 | H17 | LVCMOS18 | 低电平复位 |
| PB1 | C19 | LVCMOS18 | 页面切换 |

## 拨码开关

| 信号 | 引脚 |
| --- | --- |
| SW0 | E19 |
| SW1 | H18 |
| SW2 | F19 |
| SW3 | G22 |
| SW4 | G19 |
| SW5 | H22 |
| SW6 | H20 |
| SW7 | F22 |

SW4 的 G19 是本工程在目标硬件上实际验证使用的连接。如果板卡版本不同，请重新核对该引脚。

## LED

| 信号 | 引脚 |
| --- | --- |
| LED0 | B20 |
| LED1 | D20 |
| LED2 | C20 |
| LED3 | A21 |

## VGA

VGA 为 4 bit/channel RGB，加 HSYNC/VSYNC。完整约束位于 `constraints/edk_z7_tcc_v5_parallel.xdc`。
