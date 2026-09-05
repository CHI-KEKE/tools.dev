## 基本

```bash
|json
|line_format "{{._msg}}"
```


## NMQ

```bash
| _props_TaskId = `ba742916-6b34-44d2-83e7-fb89426cb9ca`
|_props_JobName = `RecycleLoyaltyPointsV2`
|= `TaskProcess is FAILED.`
```


##　看 NMQ JOBs 分布

```bash
sum by(_props_JobName) ( count_over_time(
{container="nine1-live-buy-worker-console-nmqv3worker"}
|=`Started new worker process`
| json
|  line_format "{{._props_JobName}}" [1m])
)
```