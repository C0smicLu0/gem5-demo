
=================================================================================================================================================
  Analyze Summary
=================================================================================================================================================
run_dir            : ~/gem5-demo/tests/testing-results/pannotia-bc-1k-128k-args2.7.14
latency_files      : cpu=344 gpu=208
ldst_weighted_mean : 31.416022
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : ~/.../testing-results/pannotia-bc-1k-128k-args2.7.14/analyze.md
output_json        : ~/.../testing-results/pannotia-bc-1k-128k-args2.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 344
total samples: 1,089,137,412
mean/min/max: 13.74 / 1 / 5064
slow buckets: >100=73,635,479  >500=10,445  >1000=1,073  >5000=1
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH           838,225,937       10.17         1      5064
LD               161,069,114       27.20         1      4884
Locked_RMW_Read       261,260       60.08         1      1170
Locked_RMW_Write       261,260        1.00         1         1
RMW_Read           2,198,962       47.12         1      1635
ST                87,120,879       22.27         1      4038

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 208
total samples: 125,624,855
mean/min/max: 58.97 / 1 / 5383
slow buckets: >100=17,933,455  >500=2,286,240  >1000=1,225,667  >5000=3,840
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
ATOMIC_RETURN      5,796,658      374.01       169      2625
LD               118,875,329       44.07         1      5383
ST                   952,868        1.14         1       775

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 31.416022
samples(cpu/gpu/total): 248189993/119828197/368018190

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  16.9732%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  38.4889%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses   8.9638%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  40.5439%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses   4.8939%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses   0.3645%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   0.8758%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  53.4984%
  • system.ruby.cp_cntrl10.L1D0cache.m_demand_misses / system.ruby.cp_cntrl10.L1D0cache.m_demand_accesses   0.8836%
  • system.ruby.cp_cntrl10.L1D1cache.m_demand_misses / system.ruby.cp_cntrl10.L1D1cache.m_demand_accesses   0.9211%
  • system.ruby.cp_cntrl10.L1Icache.m_demand_misses / system.ruby.cp_cntrl10.L1Icache.m_demand_accesses   2.6700%
  • system.ruby.cp_cntrl10.L2cache.m_demand_misses / system.ruby.cp_cntrl10.L2cache.m_demand_accesses   2.0028%
  • system.ruby.cp_cntrl11.L1D0cache.m_demand_misses / system.ruby.cp_cntrl11.L1D0cache.m_demand_accesses   1.0736%
  • system.ruby.cp_cntrl11.L1D1cache.m_demand_misses / system.ruby.cp_cntrl11.L1D1cache.m_demand_accesses   1.1516%
  • system.ruby.cp_cntrl11.L1Icache.m_demand_misses / system.ruby.cp_cntrl11.L1Icache.m_demand_accesses   2.7230%
  • system.ruby.cp_cntrl11.L2cache.m_demand_misses / system.ruby.cp_cntrl11.L2cache.m_demand_accesses   2.4514%
  • system.ruby.cp_cntrl12.L1D0cache.m_demand_misses / system.ruby.cp_cntrl12.L1D0cache.m_demand_accesses   1.3485%
  • system.ruby.cp_cntrl12.L1D1cache.m_demand_misses / system.ruby.cp_cntrl12.L1D1cache.m_demand_accesses   1.4591%
  • system.ruby.cp_cntrl12.L1Icache.m_demand_misses / system.ruby.cp_cntrl12.L1Icache.m_demand_accesses   2.7296%
  • system.ruby.cp_cntrl12.L2cache.m_demand_misses / system.ruby.cp_cntrl12.L2cache.m_demand_accesses   3.0915%
  • system.ruby.cp_cntrl13.L1D0cache.m_demand_misses / system.ruby.cp_cntrl13.L1D0cache.m_demand_accesses   1.9244%
  • system.ruby.cp_cntrl13.L1D1cache.m_demand_misses / system.ruby.cp_cntrl13.L1D1cache.m_demand_accesses   2.2078%
  • system.ruby.cp_cntrl13.L1Icache.m_demand_misses / system.ruby.cp_cntrl13.L1Icache.m_demand_accesses   2.9095%
  • system.ruby.cp_cntrl13.L2cache.m_demand_misses / system.ruby.cp_cntrl13.L2cache.m_demand_accesses   4.9103%
  • system.ruby.cp_cntrl14.L1D0cache.m_demand_misses / system.ruby.cp_cntrl14.L1D0cache.m_demand_accesses   2.7201%
  • system.ruby.cp_cntrl14.L1D1cache.m_demand_misses / system.ruby.cp_cntrl14.L1D1cache.m_demand_accesses   3.4889%
  • system.ruby.cp_cntrl14.L1Icache.m_demand_misses / system.ruby.cp_cntrl14.L1Icache.m_demand_accesses   2.9516%
  • system.ruby.cp_cntrl14.L2cache.m_demand_misses / system.ruby.cp_cntrl14.L2cache.m_demand_accesses   6.6746%
  • system.ruby.cp_cntrl15.L1D0cache.m_demand_misses / system.ruby.cp_cntrl15.L1D0cache.m_demand_accesses   5.9755%
  • system.ruby.cp_cntrl15.L1D1cache.m_demand_misses / system.ruby.cp_cntrl15.L1D1cache.m_demand_accesses  11.5924%
  • system.ruby.cp_cntrl15.L1Icache.m_demand_misses / system.ruby.cp_cntrl15.L1Icache.m_demand_accesses   4.1308%
  • system.ruby.cp_cntrl15.L2cache.m_demand_misses / system.ruby.cp_cntrl15.L2cache.m_demand_accesses  18.0585%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses   0.3799%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses   0.3796%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   2.6085%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses   0.8557%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses   0.4072%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses   0.4096%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   5.1003%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses   0.8014%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses   0.4404%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses   0.4472%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   2.6165%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses   0.9946%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses   0.4797%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses   0.4870%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   2.6287%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses   1.0845%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses   0.5273%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses   0.5373%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   2.6285%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses   1.1864%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses   0.5947%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses   0.6096%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   2.6467%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses   1.3405%
  • system.ruby.cp_cntrl8.L1D0cache.m_demand_misses / system.ruby.cp_cntrl8.L1D0cache.m_demand_accesses   0.6628%
  • system.ruby.cp_cntrl8.L1D1cache.m_demand_misses / system.ruby.cp_cntrl8.L1D1cache.m_demand_accesses   0.6827%
  • system.ruby.cp_cntrl8.L1Icache.m_demand_misses / system.ruby.cp_cntrl8.L1Icache.m_demand_accesses   2.6463%
  • system.ruby.cp_cntrl8.L2cache.m_demand_misses / system.ruby.cp_cntrl8.L2cache.m_demand_accesses   1.4997%
  • system.ruby.cp_cntrl9.L1D0cache.m_demand_misses / system.ruby.cp_cntrl9.L1D0cache.m_demand_accesses   0.7546%
  • system.ruby.cp_cntrl9.L1D1cache.m_demand_misses / system.ruby.cp_cntrl9.L1D1cache.m_demand_accesses   0.7818%
  • system.ruby.cp_cntrl9.L1Icache.m_demand_misses / system.ruby.cp_cntrl9.L1Icache.m_demand_accesses   2.6676%
  • system.ruby.cp_cntrl9.L2cache.m_demand_misses / system.ruby.cp_cntrl9.L2cache.m_demand_accesses   1.7085%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   0.2095%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  21.8371%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses  24.8994%
  • system.ruby.scalar_cntrl10.L1cache.m_demand_misses / system.ruby.scalar_cntrl10.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl11.L1cache.m_demand_misses / system.ruby.scalar_cntrl11.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl12.L1cache.m_demand_misses / system.ruby.scalar_cntrl12.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl13.L1cache.m_demand_misses / system.ruby.scalar_cntrl13.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl14.L1cache.m_demand_misses / system.ruby.scalar_cntrl14.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl15.L1cache.m_demand_misses / system.ruby.scalar_cntrl15.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl16.L1cache.m_demand_misses / system.ruby.scalar_cntrl16.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl17.L1cache.m_demand_misses / system.ruby.scalar_cntrl17.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl18.L1cache.m_demand_misses / system.ruby.scalar_cntrl18.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl19.L1cache.m_demand_misses / system.ruby.scalar_cntrl19.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl2.L1cache.m_demand_misses / system.ruby.scalar_cntrl2.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl20.L1cache.m_demand_misses / system.ruby.scalar_cntrl20.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl21.L1cache.m_demand_misses / system.ruby.scalar_cntrl21.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl22.L1cache.m_demand_misses / system.ruby.scalar_cntrl22.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl23.L1cache.m_demand_misses / system.ruby.scalar_cntrl23.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl24.L1cache.m_demand_misses / system.ruby.scalar_cntrl24.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl25.L1cache.m_demand_misses / system.ruby.scalar_cntrl25.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl26.L1cache.m_demand_misses / system.ruby.scalar_cntrl26.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl27.L1cache.m_demand_misses / system.ruby.scalar_cntrl27.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl28.L1cache.m_demand_misses / system.ruby.scalar_cntrl28.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl29.L1cache.m_demand_misses / system.ruby.scalar_cntrl29.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl3.L1cache.m_demand_misses / system.ruby.scalar_cntrl3.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl30.L1cache.m_demand_misses / system.ruby.scalar_cntrl30.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl31.L1cache.m_demand_misses / system.ruby.scalar_cntrl31.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl32.L1cache.m_demand_misses / system.ruby.scalar_cntrl32.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl33.L1cache.m_demand_misses / system.ruby.scalar_cntrl33.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl34.L1cache.m_demand_misses / system.ruby.scalar_cntrl34.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl35.L1cache.m_demand_misses / system.ruby.scalar_cntrl35.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl36.L1cache.m_demand_misses / system.ruby.scalar_cntrl36.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl37.L1cache.m_demand_misses / system.ruby.scalar_cntrl37.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl38.L1cache.m_demand_misses / system.ruby.scalar_cntrl38.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl39.L1cache.m_demand_misses / system.ruby.scalar_cntrl39.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl4.L1cache.m_demand_misses / system.ruby.scalar_cntrl4.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl40.L1cache.m_demand_misses / system.ruby.scalar_cntrl40.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl41.L1cache.m_demand_misses / system.ruby.scalar_cntrl41.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl42.L1cache.m_demand_misses / system.ruby.scalar_cntrl42.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl43.L1cache.m_demand_misses / system.ruby.scalar_cntrl43.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl44.L1cache.m_demand_misses / system.ruby.scalar_cntrl44.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl45.L1cache.m_demand_misses / system.ruby.scalar_cntrl45.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl46.L1cache.m_demand_misses / system.ruby.scalar_cntrl46.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl47.L1cache.m_demand_misses / system.ruby.scalar_cntrl47.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl48.L1cache.m_demand_misses / system.ruby.scalar_cntrl48.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl49.L1cache.m_demand_misses / system.ruby.scalar_cntrl49.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl50.L1cache.m_demand_misses / system.ruby.scalar_cntrl50.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl51.L1cache.m_demand_misses / system.ruby.scalar_cntrl51.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses  25.0000%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses   0.2200%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses   0.1938%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses   6.9767%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses   6.2937%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses   6.2937%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses   5.1724%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses   5.8824%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses   6.9767%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses   5.2941%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl40.L1cache.m_demand_misses / system.ruby.sqc_cntrl40.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl41.L1cache.m_demand_misses / system.ruby.sqc_cntrl41.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl42.L1cache.m_demand_misses / system.ruby.sqc_cntrl42.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl43.L1cache.m_demand_misses / system.ruby.sqc_cntrl43.L1cache.m_demand_accesses   6.2937%
  • system.ruby.sqc_cntrl44.L1cache.m_demand_misses / system.ruby.sqc_cntrl44.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl45.L1cache.m_demand_misses / system.ruby.sqc_cntrl45.L1cache.m_demand_accesses   6.0403%
  • system.ruby.sqc_cntrl46.L1cache.m_demand_misses / system.ruby.sqc_cntrl46.L1cache.m_demand_accesses   6.7164%
  • system.ruby.sqc_cntrl47.L1cache.m_demand_misses / system.ruby.sqc_cntrl47.L1cache.m_demand_accesses   5.8824%
  • system.ruby.sqc_cntrl48.L1cache.m_demand_misses / system.ruby.sqc_cntrl48.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl49.L1cache.m_demand_misses / system.ruby.sqc_cntrl49.L1cache.m_demand_accesses   7.4380%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl50.L1cache.m_demand_misses / system.ruby.sqc_cntrl50.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl51.L1cache.m_demand_misses / system.ruby.sqc_cntrl51.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses   5.1136%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses   6.9767%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses  41.7938%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  16.6824%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  19.1098%
  • system.ruby.tcp_cntrl10.L1cache.m_demand_misses / system.ruby.tcp_cntrl10.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl100.L1cache.m_demand_misses / system.ruby.tcp_cntrl100.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl101.L1cache.m_demand_misses / system.ruby.tcp_cntrl101.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl102.L1cache.m_demand_misses / system.ruby.tcp_cntrl102.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl103.L1cache.m_demand_misses / system.ruby.tcp_cntrl103.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl104.L1cache.m_demand_misses / system.ruby.tcp_cntrl104.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl105.L1cache.m_demand_misses / system.ruby.tcp_cntrl105.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl106.L1cache.m_demand_misses / system.ruby.tcp_cntrl106.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl107.L1cache.m_demand_misses / system.ruby.tcp_cntrl107.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl108.L1cache.m_demand_misses / system.ruby.tcp_cntrl108.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl109.L1cache.m_demand_misses / system.ruby.tcp_cntrl109.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl11.L1cache.m_demand_misses / system.ruby.tcp_cntrl11.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl110.L1cache.m_demand_misses / system.ruby.tcp_cntrl110.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl111.L1cache.m_demand_misses / system.ruby.tcp_cntrl111.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl112.L1cache.m_demand_misses / system.ruby.tcp_cntrl112.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl113.L1cache.m_demand_misses / system.ruby.tcp_cntrl113.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl114.L1cache.m_demand_misses / system.ruby.tcp_cntrl114.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl115.L1cache.m_demand_misses / system.ruby.tcp_cntrl115.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl116.L1cache.m_demand_misses / system.ruby.tcp_cntrl116.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl117.L1cache.m_demand_misses / system.ruby.tcp_cntrl117.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl118.L1cache.m_demand_misses / system.ruby.tcp_cntrl118.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl119.L1cache.m_demand_misses / system.ruby.tcp_cntrl119.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl12.L1cache.m_demand_misses / system.ruby.tcp_cntrl12.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl120.L1cache.m_demand_misses / system.ruby.tcp_cntrl120.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl121.L1cache.m_demand_misses / system.ruby.tcp_cntrl121.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl122.L1cache.m_demand_misses / system.ruby.tcp_cntrl122.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl123.L1cache.m_demand_misses / system.ruby.tcp_cntrl123.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl124.L1cache.m_demand_misses / system.ruby.tcp_cntrl124.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl125.L1cache.m_demand_misses / system.ruby.tcp_cntrl125.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl126.L1cache.m_demand_misses / system.ruby.tcp_cntrl126.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl127.L1cache.m_demand_misses / system.ruby.tcp_cntrl127.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl128.L1cache.m_demand_misses / system.ruby.tcp_cntrl128.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl129.L1cache.m_demand_misses / system.ruby.tcp_cntrl129.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl13.L1cache.m_demand_misses / system.ruby.tcp_cntrl13.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl130.L1cache.m_demand_misses / system.ruby.tcp_cntrl130.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl131.L1cache.m_demand_misses / system.ruby.tcp_cntrl131.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl132.L1cache.m_demand_misses / system.ruby.tcp_cntrl132.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl133.L1cache.m_demand_misses / system.ruby.tcp_cntrl133.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl134.L1cache.m_demand_misses / system.ruby.tcp_cntrl134.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl135.L1cache.m_demand_misses / system.ruby.tcp_cntrl135.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl136.L1cache.m_demand_misses / system.ruby.tcp_cntrl136.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl137.L1cache.m_demand_misses / system.ruby.tcp_cntrl137.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl138.L1cache.m_demand_misses / system.ruby.tcp_cntrl138.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl139.L1cache.m_demand_misses / system.ruby.tcp_cntrl139.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl14.L1cache.m_demand_misses / system.ruby.tcp_cntrl14.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl140.L1cache.m_demand_misses / system.ruby.tcp_cntrl140.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl141.L1cache.m_demand_misses / system.ruby.tcp_cntrl141.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl142.L1cache.m_demand_misses / system.ruby.tcp_cntrl142.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl143.L1cache.m_demand_misses / system.ruby.tcp_cntrl143.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl144.L1cache.m_demand_misses / system.ruby.tcp_cntrl144.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl145.L1cache.m_demand_misses / system.ruby.tcp_cntrl145.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl146.L1cache.m_demand_misses / system.ruby.tcp_cntrl146.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl147.L1cache.m_demand_misses / system.ruby.tcp_cntrl147.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl148.L1cache.m_demand_misses / system.ruby.tcp_cntrl148.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl149.L1cache.m_demand_misses / system.ruby.tcp_cntrl149.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl15.L1cache.m_demand_misses / system.ruby.tcp_cntrl15.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl150.L1cache.m_demand_misses / system.ruby.tcp_cntrl150.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl151.L1cache.m_demand_misses / system.ruby.tcp_cntrl151.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl152.L1cache.m_demand_misses / system.ruby.tcp_cntrl152.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl153.L1cache.m_demand_misses / system.ruby.tcp_cntrl153.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl154.L1cache.m_demand_misses / system.ruby.tcp_cntrl154.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl155.L1cache.m_demand_misses / system.ruby.tcp_cntrl155.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl156.L1cache.m_demand_misses / system.ruby.tcp_cntrl156.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl157.L1cache.m_demand_misses / system.ruby.tcp_cntrl157.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl158.L1cache.m_demand_misses / system.ruby.tcp_cntrl158.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl159.L1cache.m_demand_misses / system.ruby.tcp_cntrl159.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl16.L1cache.m_demand_misses / system.ruby.tcp_cntrl16.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl160.L1cache.m_demand_misses / system.ruby.tcp_cntrl160.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl161.L1cache.m_demand_misses / system.ruby.tcp_cntrl161.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl162.L1cache.m_demand_misses / system.ruby.tcp_cntrl162.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl163.L1cache.m_demand_misses / system.ruby.tcp_cntrl163.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl164.L1cache.m_demand_misses / system.ruby.tcp_cntrl164.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl165.L1cache.m_demand_misses / system.ruby.tcp_cntrl165.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl166.L1cache.m_demand_misses / system.ruby.tcp_cntrl166.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl167.L1cache.m_demand_misses / system.ruby.tcp_cntrl167.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl168.L1cache.m_demand_misses / system.ruby.tcp_cntrl168.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl169.L1cache.m_demand_misses / system.ruby.tcp_cntrl169.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl17.L1cache.m_demand_misses / system.ruby.tcp_cntrl17.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl170.L1cache.m_demand_misses / system.ruby.tcp_cntrl170.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl171.L1cache.m_demand_misses / system.ruby.tcp_cntrl171.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl172.L1cache.m_demand_misses / system.ruby.tcp_cntrl172.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl173.L1cache.m_demand_misses / system.ruby.tcp_cntrl173.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl174.L1cache.m_demand_misses / system.ruby.tcp_cntrl174.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl175.L1cache.m_demand_misses / system.ruby.tcp_cntrl175.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl176.L1cache.m_demand_misses / system.ruby.tcp_cntrl176.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl177.L1cache.m_demand_misses / system.ruby.tcp_cntrl177.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl178.L1cache.m_demand_misses / system.ruby.tcp_cntrl178.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl179.L1cache.m_demand_misses / system.ruby.tcp_cntrl179.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl180.L1cache.m_demand_misses / system.ruby.tcp_cntrl180.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl181.L1cache.m_demand_misses / system.ruby.tcp_cntrl181.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl182.L1cache.m_demand_misses / system.ruby.tcp_cntrl182.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl183.L1cache.m_demand_misses / system.ruby.tcp_cntrl183.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl184.L1cache.m_demand_misses / system.ruby.tcp_cntrl184.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl185.L1cache.m_demand_misses / system.ruby.tcp_cntrl185.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl186.L1cache.m_demand_misses / system.ruby.tcp_cntrl186.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl187.L1cache.m_demand_misses / system.ruby.tcp_cntrl187.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl188.L1cache.m_demand_misses / system.ruby.tcp_cntrl188.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl189.L1cache.m_demand_misses / system.ruby.tcp_cntrl189.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl190.L1cache.m_demand_misses / system.ruby.tcp_cntrl190.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl191.L1cache.m_demand_misses / system.ruby.tcp_cntrl191.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl192.L1cache.m_demand_misses / system.ruby.tcp_cntrl192.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl193.L1cache.m_demand_misses / system.ruby.tcp_cntrl193.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl194.L1cache.m_demand_misses / system.ruby.tcp_cntrl194.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl195.L1cache.m_demand_misses / system.ruby.tcp_cntrl195.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl196.L1cache.m_demand_misses / system.ruby.tcp_cntrl196.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl197.L1cache.m_demand_misses / system.ruby.tcp_cntrl197.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl198.L1cache.m_demand_misses / system.ruby.tcp_cntrl198.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl199.L1cache.m_demand_misses / system.ruby.tcp_cntrl199.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  16.4366%
  • system.ruby.tcp_cntrl20.L1cache.m_demand_misses / system.ruby.tcp_cntrl20.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl200.L1cache.m_demand_misses / system.ruby.tcp_cntrl200.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl201.L1cache.m_demand_misses / system.ruby.tcp_cntrl201.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl202.L1cache.m_demand_misses / system.ruby.tcp_cntrl202.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl203.L1cache.m_demand_misses / system.ruby.tcp_cntrl203.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl204.L1cache.m_demand_misses / system.ruby.tcp_cntrl204.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl205.L1cache.m_demand_misses / system.ruby.tcp_cntrl205.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl206.L1cache.m_demand_misses / system.ruby.tcp_cntrl206.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl207.L1cache.m_demand_misses / system.ruby.tcp_cntrl207.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl21.L1cache.m_demand_misses / system.ruby.tcp_cntrl21.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl22.L1cache.m_demand_misses / system.ruby.tcp_cntrl22.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl23.L1cache.m_demand_misses / system.ruby.tcp_cntrl23.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl24.L1cache.m_demand_misses / system.ruby.tcp_cntrl24.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl25.L1cache.m_demand_misses / system.ruby.tcp_cntrl25.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl26.L1cache.m_demand_misses / system.ruby.tcp_cntrl26.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl27.L1cache.m_demand_misses / system.ruby.tcp_cntrl27.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl28.L1cache.m_demand_misses / system.ruby.tcp_cntrl28.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl29.L1cache.m_demand_misses / system.ruby.tcp_cntrl29.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses  17.0607%
  • system.ruby.tcp_cntrl30.L1cache.m_demand_misses / system.ruby.tcp_cntrl30.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl31.L1cache.m_demand_misses / system.ruby.tcp_cntrl31.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl32.L1cache.m_demand_misses / system.ruby.tcp_cntrl32.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl33.L1cache.m_demand_misses / system.ruby.tcp_cntrl33.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl34.L1cache.m_demand_misses / system.ruby.tcp_cntrl34.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl35.L1cache.m_demand_misses / system.ruby.tcp_cntrl35.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl36.L1cache.m_demand_misses / system.ruby.tcp_cntrl36.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl37.L1cache.m_demand_misses / system.ruby.tcp_cntrl37.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl38.L1cache.m_demand_misses / system.ruby.tcp_cntrl38.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl39.L1cache.m_demand_misses / system.ruby.tcp_cntrl39.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses  15.2490%
  • system.ruby.tcp_cntrl40.L1cache.m_demand_misses / system.ruby.tcp_cntrl40.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl41.L1cache.m_demand_misses / system.ruby.tcp_cntrl41.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl42.L1cache.m_demand_misses / system.ruby.tcp_cntrl42.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl43.L1cache.m_demand_misses / system.ruby.tcp_cntrl43.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl44.L1cache.m_demand_misses / system.ruby.tcp_cntrl44.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl45.L1cache.m_demand_misses / system.ruby.tcp_cntrl45.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl46.L1cache.m_demand_misses / system.ruby.tcp_cntrl46.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl47.L1cache.m_demand_misses / system.ruby.tcp_cntrl47.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl48.L1cache.m_demand_misses / system.ruby.tcp_cntrl48.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl49.L1cache.m_demand_misses / system.ruby.tcp_cntrl49.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses  15.5966%
  • system.ruby.tcp_cntrl50.L1cache.m_demand_misses / system.ruby.tcp_cntrl50.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl51.L1cache.m_demand_misses / system.ruby.tcp_cntrl51.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl52.L1cache.m_demand_misses / system.ruby.tcp_cntrl52.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl53.L1cache.m_demand_misses / system.ruby.tcp_cntrl53.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl54.L1cache.m_demand_misses / system.ruby.tcp_cntrl54.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl55.L1cache.m_demand_misses / system.ruby.tcp_cntrl55.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl56.L1cache.m_demand_misses / system.ruby.tcp_cntrl56.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl57.L1cache.m_demand_misses / system.ruby.tcp_cntrl57.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl58.L1cache.m_demand_misses / system.ruby.tcp_cntrl58.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl59.L1cache.m_demand_misses / system.ruby.tcp_cntrl59.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses  15.4327%
  • system.ruby.tcp_cntrl60.L1cache.m_demand_misses / system.ruby.tcp_cntrl60.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl61.L1cache.m_demand_misses / system.ruby.tcp_cntrl61.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl62.L1cache.m_demand_misses / system.ruby.tcp_cntrl62.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl63.L1cache.m_demand_misses / system.ruby.tcp_cntrl63.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl64.L1cache.m_demand_misses / system.ruby.tcp_cntrl64.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl65.L1cache.m_demand_misses / system.ruby.tcp_cntrl65.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl66.L1cache.m_demand_misses / system.ruby.tcp_cntrl66.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl67.L1cache.m_demand_misses / system.ruby.tcp_cntrl67.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl68.L1cache.m_demand_misses / system.ruby.tcp_cntrl68.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl69.L1cache.m_demand_misses / system.ruby.tcp_cntrl69.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses  15.5901%
  • system.ruby.tcp_cntrl70.L1cache.m_demand_misses / system.ruby.tcp_cntrl70.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl71.L1cache.m_demand_misses / system.ruby.tcp_cntrl71.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl72.L1cache.m_demand_misses / system.ruby.tcp_cntrl72.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl73.L1cache.m_demand_misses / system.ruby.tcp_cntrl73.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl74.L1cache.m_demand_misses / system.ruby.tcp_cntrl74.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl75.L1cache.m_demand_misses / system.ruby.tcp_cntrl75.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl76.L1cache.m_demand_misses / system.ruby.tcp_cntrl76.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl77.L1cache.m_demand_misses / system.ruby.tcp_cntrl77.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl78.L1cache.m_demand_misses / system.ruby.tcp_cntrl78.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl79.L1cache.m_demand_misses / system.ruby.tcp_cntrl79.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl8.L1cache.m_demand_misses / system.ruby.tcp_cntrl8.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl80.L1cache.m_demand_misses / system.ruby.tcp_cntrl80.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl81.L1cache.m_demand_misses / system.ruby.tcp_cntrl81.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl82.L1cache.m_demand_misses / system.ruby.tcp_cntrl82.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl83.L1cache.m_demand_misses / system.ruby.tcp_cntrl83.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl84.L1cache.m_demand_misses / system.ruby.tcp_cntrl84.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl85.L1cache.m_demand_misses / system.ruby.tcp_cntrl85.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl86.L1cache.m_demand_misses / system.ruby.tcp_cntrl86.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl87.L1cache.m_demand_misses / system.ruby.tcp_cntrl87.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl88.L1cache.m_demand_misses / system.ruby.tcp_cntrl88.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl89.L1cache.m_demand_misses / system.ruby.tcp_cntrl89.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl9.L1cache.m_demand_misses / system.ruby.tcp_cntrl9.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl90.L1cache.m_demand_misses / system.ruby.tcp_cntrl90.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl91.L1cache.m_demand_misses / system.ruby.tcp_cntrl91.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl92.L1cache.m_demand_misses / system.ruby.tcp_cntrl92.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl93.L1cache.m_demand_misses / system.ruby.tcp_cntrl93.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl94.L1cache.m_demand_misses / system.ruby.tcp_cntrl94.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl95.L1cache.m_demand_misses / system.ruby.tcp_cntrl95.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl96.L1cache.m_demand_misses / system.ruby.tcp_cntrl96.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl97.L1cache.m_demand_misses / system.ruby.tcp_cntrl97.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl98.L1cache.m_demand_misses / system.ruby.tcp_cntrl98.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl99.L1cache.m_demand_misses / system.ruby.tcp_cntrl99.L1cache.m_demand_accesses  28.2609%

Functional Tests (offline evidence)
------------------------------------------------------------------------------------------------
• 资源实例化        PASS
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=32, cu=208, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.034489
  evidence: stats.txt: system.cpu1.ipc=0.000003
  evidence: stats.txt: system.cpu10.ipc=0.000023
• 系统初始化        PASS
  notes: 检测到进入执行阶段迹象
  evidence: simout/simerr:660: Exiting because  exiting with last active thread context
• 功能执行         PASS
  notes: 检测到正常退出迹象
  evidence: simout/simerr:660: Exiting because  exiting with last active thread context
• 结果校验         PASS
  notes: 检测到 correctness/返回状态成功信号
  evidence: simout/simerr:657: PASS
• 异常检查         PASS
  notes: 未命中严重异常关键字
  evidence: (none)
