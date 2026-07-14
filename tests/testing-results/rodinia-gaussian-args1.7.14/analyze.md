
====================================================================================================================================================
  Analyze Summary
====================================================================================================================================================
run_dir            : /home/orange/gem5-demo/tests/testing-results/rodinia-gaussian-args1.7.14
latency_files      : cpu=352 gpu=224
ldst_weighted_mean : 87.049234
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : ~/gem5-demo/tests/testing-results/rodinia-gaussian-args1.7.14/analyze.md
output_json        : ~/gem5-demo/tests/testing-results/rodinia-gaussian-args1.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 352
total samples: 51,067,506
mean/min/max: 21.71 / 1 / 3125
slow buckets: >100=5,584,664  >500=21,867  >1000=7,929  >5000=0
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH            40,111,954       13.71         1      3125
LD                 7,021,474       60.38         1      1899
Locked_RMW_Read        67,705       38.92         1      2041
Locked_RMW_Write        67,705        1.00         1         1
RMW_Read              81,599       48.52         1      1064
ST                 3,717,069       34.46         1      1359

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 224
total samples: 701,520
mean/min/max: 632.61 / 1 / 5262
slow buckets: >100=441,865  >500=312,398  >1000=202,836  >5000=120
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
LD                   524,560      845.20         1      5262
ST                   176,960        2.44         1      3993

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 87.049234
samples(cpu/gpu/total): 10738543/701520/11440063

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  29.5327%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  41.6515%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses   7.4590%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  58.3304%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses  28.5223%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses  42.0958%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   9.2776%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  57.1364%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses  44.4686%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses  42.0065%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   4.1298%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses  66.3871%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses  44.3441%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses  43.1252%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   3.8430%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses  65.9372%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses  46.8791%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses  41.4405%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   3.8533%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses  65.9147%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses  45.3036%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses  42.9698%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   2.9917%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses  63.3138%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses  45.6379%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses  41.4890%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   3.6766%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses  64.9035%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses  44.4980%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses  42.2251%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   2.5280%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses  61.1008%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   2.2350%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  41.6228%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses  43.0518%
  • system.ruby.scalar_cntrl10.L1cache.m_demand_misses / system.ruby.scalar_cntrl10.L1cache.m_demand_accesses  55.0523%
  • system.ruby.scalar_cntrl11.L1cache.m_demand_misses / system.ruby.scalar_cntrl11.L1cache.m_demand_accesses  55.9292%
  • system.ruby.scalar_cntrl12.L1cache.m_demand_misses / system.ruby.scalar_cntrl12.L1cache.m_demand_accesses  57.5592%
  • system.ruby.scalar_cntrl13.L1cache.m_demand_misses / system.ruby.scalar_cntrl13.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl14.L1cache.m_demand_misses / system.ruby.scalar_cntrl14.L1cache.m_demand_accesses  61.5984%
  • system.ruby.scalar_cntrl15.L1cache.m_demand_misses / system.ruby.scalar_cntrl15.L1cache.m_demand_accesses  55.8304%
  • system.ruby.scalar_cntrl16.L1cache.m_demand_misses / system.ruby.scalar_cntrl16.L1cache.m_demand_accesses  56.3280%
  • system.ruby.scalar_cntrl17.L1cache.m_demand_misses / system.ruby.scalar_cntrl17.L1cache.m_demand_accesses  57.9817%
  • system.ruby.scalar_cntrl18.L1cache.m_demand_misses / system.ruby.scalar_cntrl18.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl19.L1cache.m_demand_misses / system.ruby.scalar_cntrl19.L1cache.m_demand_accesses  62.0825%
  • system.ruby.scalar_cntrl2.L1cache.m_demand_misses / system.ruby.scalar_cntrl2.L1cache.m_demand_accesses  47.2347%
  • system.ruby.scalar_cntrl20.L1cache.m_demand_misses / system.ruby.scalar_cntrl20.L1cache.m_demand_accesses  56.6308%
  • system.ruby.scalar_cntrl21.L1cache.m_demand_misses / system.ruby.scalar_cntrl21.L1cache.m_demand_accesses  56.7325%
  • system.ruby.scalar_cntrl22.L1cache.m_demand_misses / system.ruby.scalar_cntrl22.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl23.L1cache.m_demand_misses / system.ruby.scalar_cntrl23.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl24.L1cache.m_demand_misses / system.ruby.scalar_cntrl24.L1cache.m_demand_accesses  62.5743%
  • system.ruby.scalar_cntrl25.L1cache.m_demand_misses / system.ruby.scalar_cntrl25.L1cache.m_demand_accesses  57.4545%
  • system.ruby.scalar_cntrl26.L1cache.m_demand_misses / system.ruby.scalar_cntrl26.L1cache.m_demand_accesses  57.4545%
  • system.ruby.scalar_cntrl27.L1cache.m_demand_misses / system.ruby.scalar_cntrl27.L1cache.m_demand_accesses  58.8454%
  • system.ruby.scalar_cntrl28.L1cache.m_demand_misses / system.ruby.scalar_cntrl28.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl29.L1cache.m_demand_misses / system.ruby.scalar_cntrl29.L1cache.m_demand_accesses  63.0739%
  • system.ruby.scalar_cntrl3.L1cache.m_demand_misses / system.ruby.scalar_cntrl3.L1cache.m_demand_accesses  51.7185%
  • system.ruby.scalar_cntrl30.L1cache.m_demand_misses / system.ruby.scalar_cntrl30.L1cache.m_demand_accesses  58.3026%
  • system.ruby.scalar_cntrl31.L1cache.m_demand_misses / system.ruby.scalar_cntrl31.L1cache.m_demand_accesses  58.3026%
  • system.ruby.scalar_cntrl32.L1cache.m_demand_misses / system.ruby.scalar_cntrl32.L1cache.m_demand_accesses  59.2871%
  • system.ruby.scalar_cntrl33.L1cache.m_demand_misses / system.ruby.scalar_cntrl33.L1cache.m_demand_accesses  61.1219%
  • system.ruby.scalar_cntrl34.L1cache.m_demand_misses / system.ruby.scalar_cntrl34.L1cache.m_demand_accesses  63.5815%
  • system.ruby.scalar_cntrl35.L1cache.m_demand_misses / system.ruby.scalar_cntrl35.L1cache.m_demand_accesses  59.1760%
  • system.ruby.scalar_cntrl36.L1cache.m_demand_misses / system.ruby.scalar_cntrl36.L1cache.m_demand_accesses  59.1760%
  • system.ruby.scalar_cntrl37.L1cache.m_demand_misses / system.ruby.scalar_cntrl37.L1cache.m_demand_accesses  59.7353%
  • system.ruby.scalar_cntrl38.L1cache.m_demand_misses / system.ruby.scalar_cntrl38.L1cache.m_demand_accesses  61.5984%
  • system.ruby.scalar_cntrl39.L1cache.m_demand_misses / system.ruby.scalar_cntrl39.L1cache.m_demand_accesses  64.0974%
  • system.ruby.scalar_cntrl4.L1cache.m_demand_misses / system.ruby.scalar_cntrl4.L1cache.m_demand_accesses  57.0397%
  • system.ruby.scalar_cntrl40.L1cache.m_demand_misses / system.ruby.scalar_cntrl40.L1cache.m_demand_accesses  60.0760%
  • system.ruby.scalar_cntrl41.L1cache.m_demand_misses / system.ruby.scalar_cntrl41.L1cache.m_demand_accesses  60.0760%
  • system.ruby.scalar_cntrl42.L1cache.m_demand_misses / system.ruby.scalar_cntrl42.L1cache.m_demand_accesses  60.1905%
  • system.ruby.scalar_cntrl43.L1cache.m_demand_misses / system.ruby.scalar_cntrl43.L1cache.m_demand_accesses  62.0825%
  • system.ruby.scalar_cntrl44.L1cache.m_demand_misses / system.ruby.scalar_cntrl44.L1cache.m_demand_accesses  77.0732%
  • system.ruby.scalar_cntrl45.L1cache.m_demand_misses / system.ruby.scalar_cntrl45.L1cache.m_demand_accesses  71.9818%
  • system.ruby.scalar_cntrl46.L1cache.m_demand_misses / system.ruby.scalar_cntrl46.L1cache.m_demand_accesses  71.9818%
  • system.ruby.scalar_cntrl47.L1cache.m_demand_misses / system.ruby.scalar_cntrl47.L1cache.m_demand_accesses  71.9818%
  • system.ruby.scalar_cntrl48.L1cache.m_demand_misses / system.ruby.scalar_cntrl48.L1cache.m_demand_accesses  74.1784%
  • system.ruby.scalar_cntrl49.L1cache.m_demand_misses / system.ruby.scalar_cntrl49.L1cache.m_demand_accesses  77.0732%
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses  54.2955%
  • system.ruby.scalar_cntrl50.L1cache.m_demand_misses / system.ruby.scalar_cntrl50.L1cache.m_demand_accesses  72.6437%
  • system.ruby.scalar_cntrl51.L1cache.m_demand_misses / system.ruby.scalar_cntrl51.L1cache.m_demand_accesses  72.6437%
  • system.ruby.scalar_cntrl52.L1cache.m_demand_misses / system.ruby.scalar_cntrl52.L1cache.m_demand_accesses  72.6437%
  • system.ruby.scalar_cntrl53.L1cache.m_demand_misses / system.ruby.scalar_cntrl53.L1cache.m_demand_accesses  74.1784%
  • system.ruby.scalar_cntrl54.L1cache.m_demand_misses / system.ruby.scalar_cntrl54.L1cache.m_demand_accesses  77.0732%
  • system.ruby.scalar_cntrl55.L1cache.m_demand_misses / system.ruby.scalar_cntrl55.L1cache.m_demand_accesses  73.3179%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses  55.5360%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses  57.2464%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses  61.1219%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses  86.5753%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses  95.0073%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses  84.6260%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses  87.4251%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses  85.3503%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses  81.7420%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses  84.4485%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses  79.8667%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses  83.7877%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses  87.0130%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses  83.7050%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses  85.5263%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses  91.9558%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses  83.4993%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses  84.1499%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses  86.5913%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses  84.1379%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses  87.2047%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses  79.4199%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses  82.4964%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses  84.6761%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses  84.8696%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses  89.0688%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses  90.4181%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses  82.5513%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses  81.9505%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses  85.8974%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses  82.0168%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses  90.9091%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses  83.3585%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses  82.3617%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses  84.2767%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses  85.6140%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses  94.0171%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses  81.2199%
  • system.ruby.sqc_cntrl40.L1cache.m_demand_misses / system.ruby.sqc_cntrl40.L1cache.m_demand_accesses  83.0508%
  • system.ruby.sqc_cntrl41.L1cache.m_demand_misses / system.ruby.sqc_cntrl41.L1cache.m_demand_accesses  82.9231%
  • system.ruby.sqc_cntrl42.L1cache.m_demand_misses / system.ruby.sqc_cntrl42.L1cache.m_demand_accesses  83.7500%
  • system.ruby.sqc_cntrl43.L1cache.m_demand_misses / system.ruby.sqc_cntrl43.L1cache.m_demand_accesses  86.6785%
  • system.ruby.sqc_cntrl44.L1cache.m_demand_misses / system.ruby.sqc_cntrl44.L1cache.m_demand_accesses  94.8276%
  • system.ruby.sqc_cntrl45.L1cache.m_demand_misses / system.ruby.sqc_cntrl45.L1cache.m_demand_accesses 100.0000%
  • system.ruby.sqc_cntrl46.L1cache.m_demand_misses / system.ruby.sqc_cntrl46.L1cache.m_demand_accesses 100.0000%
  • system.ruby.sqc_cntrl47.L1cache.m_demand_misses / system.ruby.sqc_cntrl47.L1cache.m_demand_accesses  96.3437%
  • system.ruby.sqc_cntrl48.L1cache.m_demand_misses / system.ruby.sqc_cntrl48.L1cache.m_demand_accesses  95.3125%
  • system.ruby.sqc_cntrl49.L1cache.m_demand_misses / system.ruby.sqc_cntrl49.L1cache.m_demand_accesses  94.6237%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses  84.4173%
  • system.ruby.sqc_cntrl50.L1cache.m_demand_misses / system.ruby.sqc_cntrl50.L1cache.m_demand_accesses 100.0000%
  • system.ruby.sqc_cntrl51.L1cache.m_demand_misses / system.ruby.sqc_cntrl51.L1cache.m_demand_accesses 100.0000%
  • system.ruby.sqc_cntrl52.L1cache.m_demand_misses / system.ruby.sqc_cntrl52.L1cache.m_demand_accesses  97.3535%
  • system.ruby.sqc_cntrl53.L1cache.m_demand_misses / system.ruby.sqc_cntrl53.L1cache.m_demand_accesses  95.3125%
  • system.ruby.sqc_cntrl54.L1cache.m_demand_misses / system.ruby.sqc_cntrl54.L1cache.m_demand_accesses  95.2381%
  • system.ruby.sqc_cntrl55.L1cache.m_demand_misses / system.ruby.sqc_cntrl55.L1cache.m_demand_accesses 100.0000%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses  89.2966%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses  84.9445%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses  82.7119%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses  83.4495%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses   6.6560%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  87.9131%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  60.0844%
  • system.ruby.tcp_cntrl10.L1cache.m_demand_misses / system.ruby.tcp_cntrl10.L1cache.m_demand_accesses  58.5998%
  • system.ruby.tcp_cntrl100.L1cache.m_demand_misses / system.ruby.tcp_cntrl100.L1cache.m_demand_accesses  68.1946%
  • system.ruby.tcp_cntrl101.L1cache.m_demand_misses / system.ruby.tcp_cntrl101.L1cache.m_demand_accesses  68.1946%
  • system.ruby.tcp_cntrl102.L1cache.m_demand_misses / system.ruby.tcp_cntrl102.L1cache.m_demand_accesses  68.1946%
  • system.ruby.tcp_cntrl103.L1cache.m_demand_misses / system.ruby.tcp_cntrl103.L1cache.m_demand_accesses  68.1946%
  • system.ruby.tcp_cntrl104.L1cache.m_demand_misses / system.ruby.tcp_cntrl104.L1cache.m_demand_accesses  68.1946%
  • system.ruby.tcp_cntrl105.L1cache.m_demand_misses / system.ruby.tcp_cntrl105.L1cache.m_demand_accesses  68.2081%
  • system.ruby.tcp_cntrl106.L1cache.m_demand_misses / system.ruby.tcp_cntrl106.L1cache.m_demand_accesses  68.1542%
  • system.ruby.tcp_cntrl107.L1cache.m_demand_misses / system.ruby.tcp_cntrl107.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl108.L1cache.m_demand_misses / system.ruby.tcp_cntrl108.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl109.L1cache.m_demand_misses / system.ruby.tcp_cntrl109.L1cache.m_demand_accesses  68.3107%
  • system.ruby.tcp_cntrl11.L1cache.m_demand_misses / system.ruby.tcp_cntrl11.L1cache.m_demand_accesses  58.4493%
  • system.ruby.tcp_cntrl110.L1cache.m_demand_misses / system.ruby.tcp_cntrl110.L1cache.m_demand_accesses  68.3089%
  • system.ruby.tcp_cntrl111.L1cache.m_demand_misses / system.ruby.tcp_cntrl111.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl112.L1cache.m_demand_misses / system.ruby.tcp_cntrl112.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl113.L1cache.m_demand_misses / system.ruby.tcp_cntrl113.L1cache.m_demand_accesses  68.5598%
  • system.ruby.tcp_cntrl114.L1cache.m_demand_misses / system.ruby.tcp_cntrl114.L1cache.m_demand_accesses  68.5039%
  • system.ruby.tcp_cntrl115.L1cache.m_demand_misses / system.ruby.tcp_cntrl115.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl116.L1cache.m_demand_misses / system.ruby.tcp_cntrl116.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl117.L1cache.m_demand_misses / system.ruby.tcp_cntrl117.L1cache.m_demand_accesses  69.2042%
  • system.ruby.tcp_cntrl118.L1cache.m_demand_misses / system.ruby.tcp_cntrl118.L1cache.m_demand_accesses  69.4323%
  • system.ruby.tcp_cntrl119.L1cache.m_demand_misses / system.ruby.tcp_cntrl119.L1cache.m_demand_accesses  69.4915%
  • system.ruby.tcp_cntrl12.L1cache.m_demand_misses / system.ruby.tcp_cntrl12.L1cache.m_demand_accesses  58.2640%
  • system.ruby.tcp_cntrl120.L1cache.m_demand_misses / system.ruby.tcp_cntrl120.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl121.L1cache.m_demand_misses / system.ruby.tcp_cntrl121.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl122.L1cache.m_demand_misses / system.ruby.tcp_cntrl122.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl123.L1cache.m_demand_misses / system.ruby.tcp_cntrl123.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl124.L1cache.m_demand_misses / system.ruby.tcp_cntrl124.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl125.L1cache.m_demand_misses / system.ruby.tcp_cntrl125.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl126.L1cache.m_demand_misses / system.ruby.tcp_cntrl126.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl127.L1cache.m_demand_misses / system.ruby.tcp_cntrl127.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl128.L1cache.m_demand_misses / system.ruby.tcp_cntrl128.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl129.L1cache.m_demand_misses / system.ruby.tcp_cntrl129.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl13.L1cache.m_demand_misses / system.ruby.tcp_cntrl13.L1cache.m_demand_accesses  57.7746%
  • system.ruby.tcp_cntrl130.L1cache.m_demand_misses / system.ruby.tcp_cntrl130.L1cache.m_demand_accesses  68.1754%
  • system.ruby.tcp_cntrl131.L1cache.m_demand_misses / system.ruby.tcp_cntrl131.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl132.L1cache.m_demand_misses / system.ruby.tcp_cntrl132.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl133.L1cache.m_demand_misses / system.ruby.tcp_cntrl133.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl134.L1cache.m_demand_misses / system.ruby.tcp_cntrl134.L1cache.m_demand_accesses  68.3805%
  • system.ruby.tcp_cntrl135.L1cache.m_demand_misses / system.ruby.tcp_cntrl135.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl136.L1cache.m_demand_misses / system.ruby.tcp_cntrl136.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl137.L1cache.m_demand_misses / system.ruby.tcp_cntrl137.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl138.L1cache.m_demand_misses / system.ruby.tcp_cntrl138.L1cache.m_demand_accesses  69.1892%
  • system.ruby.tcp_cntrl139.L1cache.m_demand_misses / system.ruby.tcp_cntrl139.L1cache.m_demand_accesses  69.6000%
  • system.ruby.tcp_cntrl14.L1cache.m_demand_misses / system.ruby.tcp_cntrl14.L1cache.m_demand_accesses  57.1178%
  • system.ruby.tcp_cntrl140.L1cache.m_demand_misses / system.ruby.tcp_cntrl140.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl141.L1cache.m_demand_misses / system.ruby.tcp_cntrl141.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl142.L1cache.m_demand_misses / system.ruby.tcp_cntrl142.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl143.L1cache.m_demand_misses / system.ruby.tcp_cntrl143.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl144.L1cache.m_demand_misses / system.ruby.tcp_cntrl144.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl145.L1cache.m_demand_misses / system.ruby.tcp_cntrl145.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl146.L1cache.m_demand_misses / system.ruby.tcp_cntrl146.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl147.L1cache.m_demand_misses / system.ruby.tcp_cntrl147.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl148.L1cache.m_demand_misses / system.ruby.tcp_cntrl148.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl149.L1cache.m_demand_misses / system.ruby.tcp_cntrl149.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl15.L1cache.m_demand_misses / system.ruby.tcp_cntrl15.L1cache.m_demand_accesses  56.2201%
  • system.ruby.tcp_cntrl150.L1cache.m_demand_misses / system.ruby.tcp_cntrl150.L1cache.m_demand_accesses  67.6558%
  • system.ruby.tcp_cntrl151.L1cache.m_demand_misses / system.ruby.tcp_cntrl151.L1cache.m_demand_accesses  67.9934%
  • system.ruby.tcp_cntrl152.L1cache.m_demand_misses / system.ruby.tcp_cntrl152.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl153.L1cache.m_demand_misses / system.ruby.tcp_cntrl153.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl154.L1cache.m_demand_misses / system.ruby.tcp_cntrl154.L1cache.m_demand_accesses  67.6471%
  • system.ruby.tcp_cntrl155.L1cache.m_demand_misses / system.ruby.tcp_cntrl155.L1cache.m_demand_accesses  68.0702%
  • system.ruby.tcp_cntrl156.L1cache.m_demand_misses / system.ruby.tcp_cntrl156.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl157.L1cache.m_demand_misses / system.ruby.tcp_cntrl157.L1cache.m_demand_accesses  67.6471%
  • system.ruby.tcp_cntrl158.L1cache.m_demand_misses / system.ruby.tcp_cntrl158.L1cache.m_demand_accesses  67.1053%
  • system.ruby.tcp_cntrl159.L1cache.m_demand_misses / system.ruby.tcp_cntrl159.L1cache.m_demand_accesses  69.1358%
  • system.ruby.tcp_cntrl16.L1cache.m_demand_misses / system.ruby.tcp_cntrl16.L1cache.m_demand_accesses  63.4113%
  • system.ruby.tcp_cntrl160.L1cache.m_demand_misses / system.ruby.tcp_cntrl160.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl161.L1cache.m_demand_misses / system.ruby.tcp_cntrl161.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl162.L1cache.m_demand_misses / system.ruby.tcp_cntrl162.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl163.L1cache.m_demand_misses / system.ruby.tcp_cntrl163.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl164.L1cache.m_demand_misses / system.ruby.tcp_cntrl164.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl165.L1cache.m_demand_misses / system.ruby.tcp_cntrl165.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl166.L1cache.m_demand_misses / system.ruby.tcp_cntrl166.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl167.L1cache.m_demand_misses / system.ruby.tcp_cntrl167.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl168.L1cache.m_demand_misses / system.ruby.tcp_cntrl168.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl169.L1cache.m_demand_misses / system.ruby.tcp_cntrl169.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl17.L1cache.m_demand_misses / system.ruby.tcp_cntrl17.L1cache.m_demand_accesses  64.4757%
  • system.ruby.tcp_cntrl170.L1cache.m_demand_misses / system.ruby.tcp_cntrl170.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl171.L1cache.m_demand_misses / system.ruby.tcp_cntrl171.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl172.L1cache.m_demand_misses / system.ruby.tcp_cntrl172.L1cache.m_demand_accesses  68.4322%
  • system.ruby.tcp_cntrl173.L1cache.m_demand_misses / system.ruby.tcp_cntrl173.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl174.L1cache.m_demand_misses / system.ruby.tcp_cntrl174.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl175.L1cache.m_demand_misses / system.ruby.tcp_cntrl175.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl176.L1cache.m_demand_misses / system.ruby.tcp_cntrl176.L1cache.m_demand_accesses  69.1892%
  • system.ruby.tcp_cntrl177.L1cache.m_demand_misses / system.ruby.tcp_cntrl177.L1cache.m_demand_accesses  69.6000%
  • system.ruby.tcp_cntrl178.L1cache.m_demand_misses / system.ruby.tcp_cntrl178.L1cache.m_demand_accesses  69.8630%
  • system.ruby.tcp_cntrl179.L1cache.m_demand_misses / system.ruby.tcp_cntrl179.L1cache.m_demand_accesses  71.4286%
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses  65.8318%
  • system.ruby.tcp_cntrl180.L1cache.m_demand_misses / system.ruby.tcp_cntrl180.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl181.L1cache.m_demand_misses / system.ruby.tcp_cntrl181.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl182.L1cache.m_demand_misses / system.ruby.tcp_cntrl182.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl183.L1cache.m_demand_misses / system.ruby.tcp_cntrl183.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl184.L1cache.m_demand_misses / system.ruby.tcp_cntrl184.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl185.L1cache.m_demand_misses / system.ruby.tcp_cntrl185.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl186.L1cache.m_demand_misses / system.ruby.tcp_cntrl186.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl187.L1cache.m_demand_misses / system.ruby.tcp_cntrl187.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl188.L1cache.m_demand_misses / system.ruby.tcp_cntrl188.L1cache.m_demand_accesses  68.0511%
  • system.ruby.tcp_cntrl189.L1cache.m_demand_misses / system.ruby.tcp_cntrl189.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses  67.6409%
  • system.ruby.tcp_cntrl190.L1cache.m_demand_misses / system.ruby.tcp_cntrl190.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl191.L1cache.m_demand_misses / system.ruby.tcp_cntrl191.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl192.L1cache.m_demand_misses / system.ruby.tcp_cntrl192.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl193.L1cache.m_demand_misses / system.ruby.tcp_cntrl193.L1cache.m_demand_accesses  68.2065%
  • system.ruby.tcp_cntrl194.L1cache.m_demand_misses / system.ruby.tcp_cntrl194.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl195.L1cache.m_demand_misses / system.ruby.tcp_cntrl195.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl196.L1cache.m_demand_misses / system.ruby.tcp_cntrl196.L1cache.m_demand_accesses  67.6471%
  • system.ruby.tcp_cntrl197.L1cache.m_demand_misses / system.ruby.tcp_cntrl197.L1cache.m_demand_accesses  69.1729%
  • system.ruby.tcp_cntrl198.L1cache.m_demand_misses / system.ruby.tcp_cntrl198.L1cache.m_demand_accesses  69.8630%
  • system.ruby.tcp_cntrl199.L1cache.m_demand_misses / system.ruby.tcp_cntrl199.L1cache.m_demand_accesses  71.4286%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  56.5854%
  • system.ruby.tcp_cntrl20.L1cache.m_demand_misses / system.ruby.tcp_cntrl20.L1cache.m_demand_accesses  68.0312%
  • system.ruby.tcp_cntrl200.L1cache.m_demand_misses / system.ruby.tcp_cntrl200.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl201.L1cache.m_demand_misses / system.ruby.tcp_cntrl201.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl202.L1cache.m_demand_misses / system.ruby.tcp_cntrl202.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl203.L1cache.m_demand_misses / system.ruby.tcp_cntrl203.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl204.L1cache.m_demand_misses / system.ruby.tcp_cntrl204.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl205.L1cache.m_demand_misses / system.ruby.tcp_cntrl205.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl206.L1cache.m_demand_misses / system.ruby.tcp_cntrl206.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl207.L1cache.m_demand_misses / system.ruby.tcp_cntrl207.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl208.L1cache.m_demand_misses / system.ruby.tcp_cntrl208.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl209.L1cache.m_demand_misses / system.ruby.tcp_cntrl209.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl21.L1cache.m_demand_misses / system.ruby.tcp_cntrl21.L1cache.m_demand_accesses  68.0371%
  • system.ruby.tcp_cntrl210.L1cache.m_demand_misses / system.ruby.tcp_cntrl210.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl211.L1cache.m_demand_misses / system.ruby.tcp_cntrl211.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl212.L1cache.m_demand_misses / system.ruby.tcp_cntrl212.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl213.L1cache.m_demand_misses / system.ruby.tcp_cntrl213.L1cache.m_demand_accesses  67.4419%
  • system.ruby.tcp_cntrl214.L1cache.m_demand_misses / system.ruby.tcp_cntrl214.L1cache.m_demand_accesses  68.0380%
  • system.ruby.tcp_cntrl215.L1cache.m_demand_misses / system.ruby.tcp_cntrl215.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl216.L1cache.m_demand_misses / system.ruby.tcp_cntrl216.L1cache.m_demand_accesses  67.6471%
  • system.ruby.tcp_cntrl217.L1cache.m_demand_misses / system.ruby.tcp_cntrl217.L1cache.m_demand_accesses  67.1053%
  • system.ruby.tcp_cntrl218.L1cache.m_demand_misses / system.ruby.tcp_cntrl218.L1cache.m_demand_accesses  69.1358%
  • system.ruby.tcp_cntrl219.L1cache.m_demand_misses / system.ruby.tcp_cntrl219.L1cache.m_demand_accesses  71.4286%
  • system.ruby.tcp_cntrl22.L1cache.m_demand_misses / system.ruby.tcp_cntrl22.L1cache.m_demand_accesses  67.9945%
  • system.ruby.tcp_cntrl220.L1cache.m_demand_misses / system.ruby.tcp_cntrl220.L1cache.m_demand_accesses  67.8161%
  • system.ruby.tcp_cntrl221.L1cache.m_demand_misses / system.ruby.tcp_cntrl221.L1cache.m_demand_accesses  67.8161%
  • system.ruby.tcp_cntrl222.L1cache.m_demand_misses / system.ruby.tcp_cntrl222.L1cache.m_demand_accesses  67.8161%
  • system.ruby.tcp_cntrl223.L1cache.m_demand_misses / system.ruby.tcp_cntrl223.L1cache.m_demand_accesses  67.8161%
  • system.ruby.tcp_cntrl23.L1cache.m_demand_misses / system.ruby.tcp_cntrl23.L1cache.m_demand_accesses  67.9487%
  • system.ruby.tcp_cntrl24.L1cache.m_demand_misses / system.ruby.tcp_cntrl24.L1cache.m_demand_accesses  67.8994%
  • system.ruby.tcp_cntrl25.L1cache.m_demand_misses / system.ruby.tcp_cntrl25.L1cache.m_demand_accesses  68.0718%
  • system.ruby.tcp_cntrl26.L1cache.m_demand_misses / system.ruby.tcp_cntrl26.L1cache.m_demand_accesses  68.0590%
  • system.ruby.tcp_cntrl27.L1cache.m_demand_misses / system.ruby.tcp_cntrl27.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl28.L1cache.m_demand_misses / system.ruby.tcp_cntrl28.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl29.L1cache.m_demand_misses / system.ruby.tcp_cntrl29.L1cache.m_demand_accesses  68.1205%
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses  57.6650%
  • system.ruby.tcp_cntrl30.L1cache.m_demand_misses / system.ruby.tcp_cntrl30.L1cache.m_demand_accesses  68.0376%
  • system.ruby.tcp_cntrl31.L1cache.m_demand_misses / system.ruby.tcp_cntrl31.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl32.L1cache.m_demand_misses / system.ruby.tcp_cntrl32.L1cache.m_demand_accesses  68.1090%
  • system.ruby.tcp_cntrl33.L1cache.m_demand_misses / system.ruby.tcp_cntrl33.L1cache.m_demand_accesses  68.5598%
  • system.ruby.tcp_cntrl34.L1cache.m_demand_misses / system.ruby.tcp_cntrl34.L1cache.m_demand_accesses  68.5039%
  • system.ruby.tcp_cntrl35.L1cache.m_demand_misses / system.ruby.tcp_cntrl35.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl36.L1cache.m_demand_misses / system.ruby.tcp_cntrl36.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl37.L1cache.m_demand_misses / system.ruby.tcp_cntrl37.L1cache.m_demand_accesses  68.5115%
  • system.ruby.tcp_cntrl38.L1cache.m_demand_misses / system.ruby.tcp_cntrl38.L1cache.m_demand_accesses  68.5345%
  • system.ruby.tcp_cntrl39.L1cache.m_demand_misses / system.ruby.tcp_cntrl39.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses  58.6595%
  • system.ruby.tcp_cntrl40.L1cache.m_demand_misses / system.ruby.tcp_cntrl40.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl41.L1cache.m_demand_misses / system.ruby.tcp_cntrl41.L1cache.m_demand_accesses  67.9443%
  • system.ruby.tcp_cntrl42.L1cache.m_demand_misses / system.ruby.tcp_cntrl42.L1cache.m_demand_accesses  67.9487%
  • system.ruby.tcp_cntrl43.L1cache.m_demand_misses / system.ruby.tcp_cntrl43.L1cache.m_demand_accesses  67.8994%
  • system.ruby.tcp_cntrl44.L1cache.m_demand_misses / system.ruby.tcp_cntrl44.L1cache.m_demand_accesses  67.8462%
  • system.ruby.tcp_cntrl45.L1cache.m_demand_misses / system.ruby.tcp_cntrl45.L1cache.m_demand_accesses  67.7885%
  • system.ruby.tcp_cntrl46.L1cache.m_demand_misses / system.ruby.tcp_cntrl46.L1cache.m_demand_accesses  67.9694%
  • system.ruby.tcp_cntrl47.L1cache.m_demand_misses / system.ruby.tcp_cntrl47.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl48.L1cache.m_demand_misses / system.ruby.tcp_cntrl48.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl49.L1cache.m_demand_misses / system.ruby.tcp_cntrl49.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses  58.8070%
  • system.ruby.tcp_cntrl50.L1cache.m_demand_misses / system.ruby.tcp_cntrl50.L1cache.m_demand_accesses  67.9860%
  • system.ruby.tcp_cntrl51.L1cache.m_demand_misses / system.ruby.tcp_cntrl51.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl52.L1cache.m_demand_misses / system.ruby.tcp_cntrl52.L1cache.m_demand_accesses  67.6516%
  • system.ruby.tcp_cntrl53.L1cache.m_demand_misses / system.ruby.tcp_cntrl53.L1cache.m_demand_accesses  67.8846%
  • system.ruby.tcp_cntrl54.L1cache.m_demand_misses / system.ruby.tcp_cntrl54.L1cache.m_demand_accesses  68.3805%
  • system.ruby.tcp_cntrl55.L1cache.m_demand_misses / system.ruby.tcp_cntrl55.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl56.L1cache.m_demand_misses / system.ruby.tcp_cntrl56.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl57.L1cache.m_demand_misses / system.ruby.tcp_cntrl57.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl58.L1cache.m_demand_misses / system.ruby.tcp_cntrl58.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl59.L1cache.m_demand_misses / system.ruby.tcp_cntrl59.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses  58.9864%
  • system.ruby.tcp_cntrl60.L1cache.m_demand_misses / system.ruby.tcp_cntrl60.L1cache.m_demand_accesses  67.8437%
  • system.ruby.tcp_cntrl61.L1cache.m_demand_misses / system.ruby.tcp_cntrl61.L1cache.m_demand_accesses  67.8437%
  • system.ruby.tcp_cntrl62.L1cache.m_demand_misses / system.ruby.tcp_cntrl62.L1cache.m_demand_accesses  67.8437%
  • system.ruby.tcp_cntrl63.L1cache.m_demand_misses / system.ruby.tcp_cntrl63.L1cache.m_demand_accesses  67.8462%
  • system.ruby.tcp_cntrl64.L1cache.m_demand_misses / system.ruby.tcp_cntrl64.L1cache.m_demand_accesses  67.7885%
  • system.ruby.tcp_cntrl65.L1cache.m_demand_misses / system.ruby.tcp_cntrl65.L1cache.m_demand_accesses  67.7258%
  • system.ruby.tcp_cntrl66.L1cache.m_demand_misses / system.ruby.tcp_cntrl66.L1cache.m_demand_accesses  67.6573%
  • system.ruby.tcp_cntrl67.L1cache.m_demand_misses / system.ruby.tcp_cntrl67.L1cache.m_demand_accesses  67.8472%
  • system.ruby.tcp_cntrl68.L1cache.m_demand_misses / system.ruby.tcp_cntrl68.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl69.L1cache.m_demand_misses / system.ruby.tcp_cntrl69.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses  59.0164%
  • system.ruby.tcp_cntrl70.L1cache.m_demand_misses / system.ruby.tcp_cntrl70.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl71.L1cache.m_demand_misses / system.ruby.tcp_cntrl71.L1cache.m_demand_accesses  67.8146%
  • system.ruby.tcp_cntrl72.L1cache.m_demand_misses / system.ruby.tcp_cntrl72.L1cache.m_demand_accesses  67.6516%
  • system.ruby.tcp_cntrl73.L1cache.m_demand_misses / system.ruby.tcp_cntrl73.L1cache.m_demand_accesses  67.3469%
  • system.ruby.tcp_cntrl74.L1cache.m_demand_misses / system.ruby.tcp_cntrl74.L1cache.m_demand_accesses  67.5481%
  • system.ruby.tcp_cntrl75.L1cache.m_demand_misses / system.ruby.tcp_cntrl75.L1cache.m_demand_accesses  68.0702%
  • system.ruby.tcp_cntrl76.L1cache.m_demand_misses / system.ruby.tcp_cntrl76.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl77.L1cache.m_demand_misses / system.ruby.tcp_cntrl77.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl78.L1cache.m_demand_misses / system.ruby.tcp_cntrl78.L1cache.m_demand_accesses  67.4419%
  • system.ruby.tcp_cntrl79.L1cache.m_demand_misses / system.ruby.tcp_cntrl79.L1cache.m_demand_accesses  68.0380%
  • system.ruby.tcp_cntrl8.L1cache.m_demand_misses / system.ruby.tcp_cntrl8.L1cache.m_demand_accesses  58.9923%
  • system.ruby.tcp_cntrl80.L1cache.m_demand_misses / system.ruby.tcp_cntrl80.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl81.L1cache.m_demand_misses / system.ruby.tcp_cntrl81.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl82.L1cache.m_demand_misses / system.ruby.tcp_cntrl82.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl83.L1cache.m_demand_misses / system.ruby.tcp_cntrl83.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl84.L1cache.m_demand_misses / system.ruby.tcp_cntrl84.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl85.L1cache.m_demand_misses / system.ruby.tcp_cntrl85.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl86.L1cache.m_demand_misses / system.ruby.tcp_cntrl86.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl87.L1cache.m_demand_misses / system.ruby.tcp_cntrl87.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl88.L1cache.m_demand_misses / system.ruby.tcp_cntrl88.L1cache.m_demand_accesses  68.0467%
  • system.ruby.tcp_cntrl89.L1cache.m_demand_misses / system.ruby.tcp_cntrl89.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl9.L1cache.m_demand_misses / system.ruby.tcp_cntrl9.L1cache.m_demand_accesses  58.8053%
  • system.ruby.tcp_cntrl90.L1cache.m_demand_misses / system.ruby.tcp_cntrl90.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl91.L1cache.m_demand_misses / system.ruby.tcp_cntrl91.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl92.L1cache.m_demand_misses / system.ruby.tcp_cntrl92.L1cache.m_demand_accesses  68.1090%
  • system.ruby.tcp_cntrl93.L1cache.m_demand_misses / system.ruby.tcp_cntrl93.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl94.L1cache.m_demand_misses / system.ruby.tcp_cntrl94.L1cache.m_demand_accesses  67.6471%
  • system.ruby.tcp_cntrl95.L1cache.m_demand_misses / system.ruby.tcp_cntrl95.L1cache.m_demand_accesses  68.0702%
  • system.ruby.tcp_cntrl96.L1cache.m_demand_misses / system.ruby.tcp_cntrl96.L1cache.m_demand_accesses  69.2112%
  • system.ruby.tcp_cntrl97.L1cache.m_demand_misses / system.ruby.tcp_cntrl97.L1cache.m_demand_accesses  69.3694%
  • system.ruby.tcp_cntrl98.L1cache.m_demand_misses / system.ruby.tcp_cntrl98.L1cache.m_demand_accesses  69.3950%
  • system.ruby.tcp_cntrl99.L1cache.m_demand_misses / system.ruby.tcp_cntrl99.L1cache.m_demand_accesses  69.4323%

Functional Tests (offline evidence)
------------------------------------------------------------------------------------------------
• 资源实例化        PASS
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=16, cu=224, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.024849
  evidence: stats.txt: system.cpu1.ipc=0.000038
  evidence: stats.txt: system.cpu10.ipc=0.000010
• 系统初始化        PASS
  notes: 检测到进入执行阶段迹象
  evidence: simout/simerr:894: Exiting because  exiting with last active thread context
• 功能执行         PASS
  notes: 检测到正常退出迹象
  evidence: simout/simerr:894: Exiting because  exiting with last active thread context
• 结果校验         PASS
  notes: 检测到 correctness/返回状态成功信号
  evidence: simout/simerr:505: [gaussian] pthread_create success tid=0 iter=0
  evidence: simout/simerr:507: [gaussian] pthread_create success tid=1 iter=0
  evidence: simout/simerr:509: [gaussian] pthread_create success tid=2 iter=0
• 异常检查         PASS
  notes: 未命中严重异常关键字
  evidence: (none)
