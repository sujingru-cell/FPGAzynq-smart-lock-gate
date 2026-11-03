# Metrics

VGA 页面使用以下指标比较三种策略。

| 指标 | 含义 |
| --- | --- |
| PASS | 累计通过船舶数量 |
| AVG WAIT | 队列长度积分除以累计通过船数得到的等待代理值 |
| LOAD | 平均闸次装载率，按 4 个容量单位为满载 |
| FRESH/SHIP | 累计新鲜用水量 / 累计通过船数 |
| SAVE | 回用水量占累计用水量的比例 |
| CONG | 当前队列与待进入 FIFO 的压力映射值 |
| POOL | SAVE POOL 当前标准化水位 |

## AVG WAIT

当前实现每秒累加一次双向队列长度，再除以累计通过船数。它适合在同一输入条件下比较 EFF、SAVE、AUTO 的等待趋势，但不是逐船记录到达/离开时间后得到的严格平均等待时间。

## CONG

`pressure_count` 包括两部分：

1. 已进入双向 CA 航道的船舶；
2. 已到达但仍在输入 FIFO 中等待进入航道的船舶。

显示值按约 `2.5 × pressure_count` 映射，并在 100% 饱和。因此约 40 艘排队/待进入船舶对应 100% 拥堵。

## FRESH/SHIP 与 SAVE

`fresh_total` 只累计从上游补充的新鲜水。SAVE POOL 提供的回用水单独计入 `reused_total`。因此：

```text
FRESH/SHIP = fresh_total / passed_total
SAVE       = reused_total / (fresh_total + reused_total)
```

这两个指标分别反映单位通航的新鲜水需求和回用水占比。
