# Architecture

## 数据流

三套策略核心共用同一组随机到达事件，但各自维护独立的 FIFO、接近航道、调度器、船闸状态和统计量。

```text
                   common arrival stream
                           |
          +----------------+----------------+
          |                |                |
        EFF              SAVE             AUTO
          |                |                |
     arrival FIFO     arrival FIFO     arrival FIFO
          |                |                |
      CA lanes          CA lanes          CA lanes
          |                |                |
      scheduler         scheduler         scheduler
          |                |                |
      lock FSM          lock FSM          lock FSM
       /    \            /    \            /    \
   water   anim      water   anim      water   anim
       \    /            \    /            \    /
       metrics           metrics           metrics
          +----------------+----------------+
                           |
                  MAIN / COMPARE / TREND
```

这样做的目的，是让 EFF、SAVE 和 AUTO 在相同输入条件下运行，同时允许它们因为调度差异形成不同的队列和水资源状态。

## 主要模块

- `top.v`：顶层连接、公共船流生成、三核心实例、VGA 页面选择和 LED。
- `simulation_core_v5p.v`：一套完整策略核心的封装。
- `arrival_fifo_v5p.v`：缓存尚未进入 CA 航道的到达事件。
- `ca_lane_v5.v`：双向接近航道的元胞自动机模型和批次选择。
- `scheduler_v5p.v`：EFF、SAVE、AUTO 调度逻辑。
- `lock_core_v5.v`：两级船闸通航状态机。
- `water_model_v5.v`：标准化水位与 SAVE POOL 模型。
- `animation_v5.v`：闸门和船舶移动动画。
- `vga_scene_v5.v`：MAIN 页面。
- `vga_aux_pages_v5p.v`：COMPARE 和 TREND 页面。
- `trend_history_v5p.v`：AUTO 32 秒趋势缓存。

## 调度逻辑

### EFF

只要船闸空闲且一侧存在可选批次，就允许发闸。两侧同时满足条件时，优先考虑等待时间、装载量和轮换方向。

### SAVE

优先等待达到 4 个容量单位的批次。为避免长时间等待，调度器同时设置等待超时和单侧等待保护。

### AUTO

AUTO 使用队列压力的高/低阈值形成滞回区间。压力达到高阈值时转向 EFF；压力回落到低阈值时转向 SAVE。等待时间过长也会触发 EFF。

| SW[7:6] | 高阈值 | 低阈值 |
| --- | ---: | ---: |
| 00 | 5 | 2 |
| 01 | 8 | 4 |
| 10 | 11 | 6 |
| 11 | 14 | 8 |

## SAVE POOL

水位采用 0～100 的标准化单位。SAVE 模式下，部分降水过程会优先向 SAVE POOL 储水，后续充水阶段优先从池中回用；不足部分再计入新鲜水。EFF 对应的快速水路不使用储水池回用。

该模型用于比较策略间的水资源趋势，不等同于真实船闸的完整水力学仿真。
