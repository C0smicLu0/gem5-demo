
====================================================================================================================================================
  Analyze Summary
====================================================================================================================================================
run_dir            : /home/orange/gem5-demo/tests/testing-results/rodinia-gaussian-args3.7.14
latency_files      : cpu=336 gpu=192
ldst_weighted_mean : 79.126918
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : ~/gem5-demo/tests/testing-results/rodinia-gaussian-args3.7.14/analyze.md
output_json        : ~/gem5-demo/tests/testing-results/rodinia-gaussian-args3.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 336
total samples: 52,429,432
mean/min/max: 21.89 / 1 / 22338
slow buckets: >100=5,700,429  >500=23,566  >1000=10,203  >5000=1,928
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH            41,203,543       13.66         1     16499
LD                 7,195,358       59.90         1     16801
Locked_RMW_Read        69,254       47.74         1      8367
Locked_RMW_Write        69,254        1.00         1         1
RMW_Read              88,332       45.26         1      1064
ST                 3,803,691       38.43         1     22338

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 192
total samples: 701,520
mean/min/max: 496.98 / 1 / 4625
slow buckets: >100=411,915  >500=290,753  >1000=148,468  >5000=0
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
LD                   524,560      663.43         1      4625
ST                   176,960        3.57         1      2581

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 79.126918
samples(cpu/gpu/total): 10999049/701520/11700569

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  28.5362%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  35.7297%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses   7.6154%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  58.3462%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses  28.8145%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses  47.0178%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   9.2977%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  57.3651%
  • system.ruby.cp_cntrl10.L1D0cache.m_demand_misses / system.ruby.cp_cntrl10.L1D0cache.m_demand_accesses  45.9109%
  • system.ruby.cp_cntrl10.L1D1cache.m_demand_misses / system.ruby.cp_cntrl10.L1D1cache.m_demand_accesses  43.8171%
  • system.ruby.cp_cntrl10.L1Icache.m_demand_misses / system.ruby.cp_cntrl10.L1Icache.m_demand_accesses   2.5364%
  • system.ruby.cp_cntrl10.L2cache.m_demand_misses / system.ruby.cp_cntrl10.L2cache.m_demand_accesses  60.8086%
  • system.ruby.cp_cntrl11.L1D0cache.m_demand_misses / system.ruby.cp_cntrl11.L1D0cache.m_demand_accesses  48.0585%
  • system.ruby.cp_cntrl11.L1D1cache.m_demand_misses / system.ruby.cp_cntrl11.L1D1cache.m_demand_accesses  44.2688%
  • system.ruby.cp_cntrl11.L1Icache.m_demand_misses / system.ruby.cp_cntrl11.L1Icache.m_demand_accesses   2.5522%
  • system.ruby.cp_cntrl11.L2cache.m_demand_misses / system.ruby.cp_cntrl11.L2cache.m_demand_accesses  60.5973%
  • system.ruby.cp_cntrl12.L1D0cache.m_demand_misses / system.ruby.cp_cntrl12.L1D0cache.m_demand_accesses  51.5929%
  • system.ruby.cp_cntrl12.L1D1cache.m_demand_misses / system.ruby.cp_cntrl12.L1D1cache.m_demand_accesses  45.3696%
  • system.ruby.cp_cntrl12.L1Icache.m_demand_misses / system.ruby.cp_cntrl12.L1Icache.m_demand_accesses   2.7190%
  • system.ruby.cp_cntrl12.L2cache.m_demand_misses / system.ruby.cp_cntrl12.L2cache.m_demand_accesses  62.5256%
  • system.ruby.cp_cntrl13.L1D0cache.m_demand_misses / system.ruby.cp_cntrl13.L1D0cache.m_demand_accesses  43.7170%
  • system.ruby.cp_cntrl13.L1D1cache.m_demand_misses / system.ruby.cp_cntrl13.L1D1cache.m_demand_accesses  42.6007%
  • system.ruby.cp_cntrl13.L1Icache.m_demand_misses / system.ruby.cp_cntrl13.L1Icache.m_demand_accesses   2.5501%
  • system.ruby.cp_cntrl13.L2cache.m_demand_misses / system.ruby.cp_cntrl13.L2cache.m_demand_accesses  60.3444%
  • system.ruby.cp_cntrl14.L1D0cache.m_demand_misses / system.ruby.cp_cntrl14.L1D0cache.m_demand_accesses  47.0456%
  • system.ruby.cp_cntrl14.L1D1cache.m_demand_misses / system.ruby.cp_cntrl14.L1D1cache.m_demand_accesses  44.1731%
  • system.ruby.cp_cntrl14.L1Icache.m_demand_misses / system.ruby.cp_cntrl14.L1Icache.m_demand_accesses   3.2730%
  • system.ruby.cp_cntrl14.L2cache.m_demand_misses / system.ruby.cp_cntrl14.L2cache.m_demand_accesses  63.3630%
  • system.ruby.cp_cntrl15.L1D0cache.m_demand_misses / system.ruby.cp_cntrl15.L1D0cache.m_demand_accesses  46.2588%
  • system.ruby.cp_cntrl15.L1D1cache.m_demand_misses / system.ruby.cp_cntrl15.L1D1cache.m_demand_accesses  43.2420%
  • system.ruby.cp_cntrl15.L1Icache.m_demand_misses / system.ruby.cp_cntrl15.L1Icache.m_demand_accesses   3.5691%
  • system.ruby.cp_cntrl15.L2cache.m_demand_misses / system.ruby.cp_cntrl15.L2cache.m_demand_accesses  63.5058%
  • system.ruby.cp_cntrl16.L1D0cache.m_demand_misses / system.ruby.cp_cntrl16.L1D0cache.m_demand_accesses  49.1648%
  • system.ruby.cp_cntrl16.L1D1cache.m_demand_misses / system.ruby.cp_cntrl16.L1D1cache.m_demand_accesses  41.7476%
  • system.ruby.cp_cntrl16.L1Icache.m_demand_misses / system.ruby.cp_cntrl16.L1Icache.m_demand_accesses   3.6086%
  • system.ruby.cp_cntrl16.L2cache.m_demand_misses / system.ruby.cp_cntrl16.L2cache.m_demand_accesses  64.9023%
  • system.ruby.cp_cntrl17.L1D0cache.m_demand_misses / system.ruby.cp_cntrl17.L1D0cache.m_demand_accesses  51.8119%
  • system.ruby.cp_cntrl17.L1D1cache.m_demand_misses / system.ruby.cp_cntrl17.L1D1cache.m_demand_accesses  47.0132%
  • system.ruby.cp_cntrl17.L1Icache.m_demand_misses / system.ruby.cp_cntrl17.L1Icache.m_demand_accesses   2.5619%
  • system.ruby.cp_cntrl17.L2cache.m_demand_misses / system.ruby.cp_cntrl17.L2cache.m_demand_accesses  62.0279%
  • system.ruby.cp_cntrl18.L1D0cache.m_demand_misses / system.ruby.cp_cntrl18.L1D0cache.m_demand_accesses  44.6602%
  • system.ruby.cp_cntrl18.L1D1cache.m_demand_misses / system.ruby.cp_cntrl18.L1D1cache.m_demand_accesses  41.5859%
  • system.ruby.cp_cntrl18.L1Icache.m_demand_misses / system.ruby.cp_cntrl18.L1Icache.m_demand_accesses   3.0683%
  • system.ruby.cp_cntrl18.L2cache.m_demand_misses / system.ruby.cp_cntrl18.L2cache.m_demand_accesses  62.1397%
  • system.ruby.cp_cntrl19.L1D0cache.m_demand_misses / system.ruby.cp_cntrl19.L1D0cache.m_demand_accesses  51.6654%
  • system.ruby.cp_cntrl19.L1D1cache.m_demand_misses / system.ruby.cp_cntrl19.L1D1cache.m_demand_accesses  47.7992%
  • system.ruby.cp_cntrl19.L1Icache.m_demand_misses / system.ruby.cp_cntrl19.L1Icache.m_demand_accesses   2.6647%
  • system.ruby.cp_cntrl19.L2cache.m_demand_misses / system.ruby.cp_cntrl19.L2cache.m_demand_accesses  61.8970%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses  52.1073%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses  42.9136%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   2.9904%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses  63.3451%
  • system.ruby.cp_cntrl20.L1D0cache.m_demand_misses / system.ruby.cp_cntrl20.L1D0cache.m_demand_accesses  45.2067%
  • system.ruby.cp_cntrl20.L1D1cache.m_demand_misses / system.ruby.cp_cntrl20.L1D1cache.m_demand_accesses  42.4056%
  • system.ruby.cp_cntrl20.L1Icache.m_demand_misses / system.ruby.cp_cntrl20.L1Icache.m_demand_accesses   2.9481%
  • system.ruby.cp_cntrl20.L2cache.m_demand_misses / system.ruby.cp_cntrl20.L2cache.m_demand_accesses  61.6477%
  • system.ruby.cp_cntrl21.L1D0cache.m_demand_misses / system.ruby.cp_cntrl21.L1D0cache.m_demand_accesses  50.2694%
  • system.ruby.cp_cntrl21.L1D1cache.m_demand_misses / system.ruby.cp_cntrl21.L1D1cache.m_demand_accesses  47.8060%
  • system.ruby.cp_cntrl21.L1Icache.m_demand_misses / system.ruby.cp_cntrl21.L1Icache.m_demand_accesses   2.6586%
  • system.ruby.cp_cntrl21.L2cache.m_demand_misses / system.ruby.cp_cntrl21.L2cache.m_demand_accesses  62.6835%
  • system.ruby.cp_cntrl22.L1D0cache.m_demand_misses / system.ruby.cp_cntrl22.L1D0cache.m_demand_accesses  42.5986%
  • system.ruby.cp_cntrl22.L1D1cache.m_demand_misses / system.ruby.cp_cntrl22.L1D1cache.m_demand_accesses  41.4705%
  • system.ruby.cp_cntrl22.L1Icache.m_demand_misses / system.ruby.cp_cntrl22.L1Icache.m_demand_accesses   3.2203%
  • system.ruby.cp_cntrl22.L2cache.m_demand_misses / system.ruby.cp_cntrl22.L2cache.m_demand_accesses  62.7715%
  • system.ruby.cp_cntrl23.L1D0cache.m_demand_misses / system.ruby.cp_cntrl23.L1D0cache.m_demand_accesses  51.5879%
  • system.ruby.cp_cntrl23.L1D1cache.m_demand_misses / system.ruby.cp_cntrl23.L1D1cache.m_demand_accesses  48.8803%
  • system.ruby.cp_cntrl23.L1Icache.m_demand_misses / system.ruby.cp_cntrl23.L1Icache.m_demand_accesses   2.4713%
  • system.ruby.cp_cntrl23.L2cache.m_demand_misses / system.ruby.cp_cntrl23.L2cache.m_demand_accesses  61.3562%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses  45.7224%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses  43.5420%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   2.4520%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses  59.7304%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses  47.2614%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses  44.7085%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   3.1006%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses  62.2500%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses  47.1051%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses  44.4007%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   3.1270%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses  63.4268%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses  51.9066%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses  43.7606%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   3.2832%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses  64.5184%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses  46.5274%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses  44.8739%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   2.7104%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses  61.1731%
  • system.ruby.cp_cntrl8.L1D0cache.m_demand_misses / system.ruby.cp_cntrl8.L1D0cache.m_demand_accesses  42.4177%
  • system.ruby.cp_cntrl8.L1D1cache.m_demand_misses / system.ruby.cp_cntrl8.L1D1cache.m_demand_accesses  39.7320%
  • system.ruby.cp_cntrl8.L1Icache.m_demand_misses / system.ruby.cp_cntrl8.L1Icache.m_demand_accesses   2.5832%
  • system.ruby.cp_cntrl8.L2cache.m_demand_misses / system.ruby.cp_cntrl8.L2cache.m_demand_accesses  59.7049%
  • system.ruby.cp_cntrl9.L1D0cache.m_demand_misses / system.ruby.cp_cntrl9.L1D0cache.m_demand_accesses  46.5839%
  • system.ruby.cp_cntrl9.L1D1cache.m_demand_misses / system.ruby.cp_cntrl9.L1D1cache.m_demand_accesses  43.9368%
  • system.ruby.cp_cntrl9.L1Icache.m_demand_misses / system.ruby.cp_cntrl9.L1Icache.m_demand_accesses   2.4573%
  • system.ruby.cp_cntrl9.L2cache.m_demand_misses / system.ruby.cp_cntrl9.L2cache.m_demand_accesses  60.9533%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   2.2133%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  38.3123%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses  40.2548%
  • system.ruby.scalar_cntrl10.L1cache.m_demand_misses / system.ruby.scalar_cntrl10.L1cache.m_demand_accesses  54.7660%
  • system.ruby.scalar_cntrl11.L1cache.m_demand_misses / system.ruby.scalar_cntrl11.L1cache.m_demand_accesses  57.2464%
  • system.ruby.scalar_cntrl12.L1cache.m_demand_misses / system.ruby.scalar_cntrl12.L1cache.m_demand_accesses  57.1429%
  • system.ruby.scalar_cntrl13.L1cache.m_demand_misses / system.ruby.scalar_cntrl13.L1cache.m_demand_accesses  58.8454%
  • system.ruby.scalar_cntrl14.L1cache.m_demand_misses / system.ruby.scalar_cntrl14.L1cache.m_demand_accesses  60.6526%
  • system.ruby.scalar_cntrl15.L1cache.m_demand_misses / system.ruby.scalar_cntrl15.L1cache.m_demand_accesses  55.1483%
  • system.ruby.scalar_cntrl16.L1cache.m_demand_misses / system.ruby.scalar_cntrl16.L1cache.m_demand_accesses  57.2464%
  • system.ruby.scalar_cntrl17.L1cache.m_demand_misses / system.ruby.scalar_cntrl17.L1cache.m_demand_accesses  57.5592%
  • system.ruby.scalar_cntrl18.L1cache.m_demand_misses / system.ruby.scalar_cntrl18.L1cache.m_demand_accesses  59.2871%
  • system.ruby.scalar_cntrl19.L1cache.m_demand_misses / system.ruby.scalar_cntrl19.L1cache.m_demand_accesses  61.1219%
  • system.ruby.scalar_cntrl2.L1cache.m_demand_misses / system.ruby.scalar_cntrl2.L1cache.m_demand_accesses  41.9655%
  • system.ruby.scalar_cntrl20.L1cache.m_demand_misses / system.ruby.scalar_cntrl20.L1cache.m_demand_accesses  55.8304%
  • system.ruby.scalar_cntrl21.L1cache.m_demand_misses / system.ruby.scalar_cntrl21.L1cache.m_demand_accesses  57.2464%
  • system.ruby.scalar_cntrl22.L1cache.m_demand_misses / system.ruby.scalar_cntrl22.L1cache.m_demand_accesses  57.9817%
  • system.ruby.scalar_cntrl23.L1cache.m_demand_misses / system.ruby.scalar_cntrl23.L1cache.m_demand_accesses  59.7353%
  • system.ruby.scalar_cntrl24.L1cache.m_demand_misses / system.ruby.scalar_cntrl24.L1cache.m_demand_accesses  61.5984%
  • system.ruby.scalar_cntrl25.L1cache.m_demand_misses / system.ruby.scalar_cntrl25.L1cache.m_demand_accesses  56.6308%
  • system.ruby.scalar_cntrl26.L1cache.m_demand_misses / system.ruby.scalar_cntrl26.L1cache.m_demand_accesses  57.5592%
  • system.ruby.scalar_cntrl27.L1cache.m_demand_misses / system.ruby.scalar_cntrl27.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl28.L1cache.m_demand_misses / system.ruby.scalar_cntrl28.L1cache.m_demand_accesses  60.1905%
  • system.ruby.scalar_cntrl29.L1cache.m_demand_misses / system.ruby.scalar_cntrl29.L1cache.m_demand_accesses  62.0825%
  • system.ruby.scalar_cntrl3.L1cache.m_demand_misses / system.ruby.scalar_cntrl3.L1cache.m_demand_accesses  45.2722%
  • system.ruby.scalar_cntrl30.L1cache.m_demand_misses / system.ruby.scalar_cntrl30.L1cache.m_demand_accesses  57.4545%
  • system.ruby.scalar_cntrl31.L1cache.m_demand_misses / system.ruby.scalar_cntrl31.L1cache.m_demand_accesses  57.9817%
  • system.ruby.scalar_cntrl32.L1cache.m_demand_misses / system.ruby.scalar_cntrl32.L1cache.m_demand_accesses  58.8454%
  • system.ruby.scalar_cntrl33.L1cache.m_demand_misses / system.ruby.scalar_cntrl33.L1cache.m_demand_accesses  60.6526%
  • system.ruby.scalar_cntrl34.L1cache.m_demand_misses / system.ruby.scalar_cntrl34.L1cache.m_demand_accesses  62.5743%
  • system.ruby.scalar_cntrl35.L1cache.m_demand_misses / system.ruby.scalar_cntrl35.L1cache.m_demand_accesses  58.3026%
  • system.ruby.scalar_cntrl36.L1cache.m_demand_misses / system.ruby.scalar_cntrl36.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl37.L1cache.m_demand_misses / system.ruby.scalar_cntrl37.L1cache.m_demand_accesses  59.2871%
  • system.ruby.scalar_cntrl38.L1cache.m_demand_misses / system.ruby.scalar_cntrl38.L1cache.m_demand_accesses  61.1219%
  • system.ruby.scalar_cntrl39.L1cache.m_demand_misses / system.ruby.scalar_cntrl39.L1cache.m_demand_accesses  63.0739%
  • system.ruby.scalar_cntrl4.L1cache.m_demand_misses / system.ruby.scalar_cntrl4.L1cache.m_demand_accesses  56.2278%
  • system.ruby.scalar_cntrl40.L1cache.m_demand_misses / system.ruby.scalar_cntrl40.L1cache.m_demand_accesses  59.1760%
  • system.ruby.scalar_cntrl41.L1cache.m_demand_misses / system.ruby.scalar_cntrl41.L1cache.m_demand_accesses  59.1760%
  • system.ruby.scalar_cntrl42.L1cache.m_demand_misses / system.ruby.scalar_cntrl42.L1cache.m_demand_accesses  59.7353%
  • system.ruby.scalar_cntrl43.L1cache.m_demand_misses / system.ruby.scalar_cntrl43.L1cache.m_demand_accesses  61.5984%
  • system.ruby.scalar_cntrl44.L1cache.m_demand_misses / system.ruby.scalar_cntrl44.L1cache.m_demand_accesses  63.5815%
  • system.ruby.scalar_cntrl45.L1cache.m_demand_misses / system.ruby.scalar_cntrl45.L1cache.m_demand_accesses  60.0760%
  • system.ruby.scalar_cntrl46.L1cache.m_demand_misses / system.ruby.scalar_cntrl46.L1cache.m_demand_accesses  60.0760%
  • system.ruby.scalar_cntrl47.L1cache.m_demand_misses / system.ruby.scalar_cntrl47.L1cache.m_demand_accesses  60.5364%
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses  54.3890%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses  57.2464%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses  56.7325%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses  60.1905%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses  78.6722%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses  88.3880%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses  80.6069%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses  75.9428%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses  92.8943%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses  87.8354%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses  82.7993%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses  77.6913%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses  77.0449%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses  91.9383%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses  87.1429%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses  80.7757%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses  80.1926%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses  80.5213%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses  76.3399%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses  88.4488%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses  92.5996%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses  81.0764%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses  83.0925%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses  75.2618%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses  87.4388%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses  92.2495%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses  85.0467%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses  80.4124%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses  84.4078%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses  76.9126%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses  84.0125%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses  93.3078%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses  86.0194%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses  85.4264%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses  78.3784%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses  85.7600%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses  91.2150%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses  87.8244%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses  78.6350%
  • system.ruby.sqc_cntrl40.L1cache.m_demand_misses / system.ruby.sqc_cntrl40.L1cache.m_demand_accesses  78.8012%
  • system.ruby.sqc_cntrl41.L1cache.m_demand_misses / system.ruby.sqc_cntrl41.L1cache.m_demand_accesses  78.9165%
  • system.ruby.sqc_cntrl42.L1cache.m_demand_misses / system.ruby.sqc_cntrl42.L1cache.m_demand_accesses  81.5830%
  • system.ruby.sqc_cntrl43.L1cache.m_demand_misses / system.ruby.sqc_cntrl43.L1cache.m_demand_accesses  89.3773%
  • system.ruby.sqc_cntrl44.L1cache.m_demand_misses / system.ruby.sqc_cntrl44.L1cache.m_demand_accesses  91.2863%
  • system.ruby.sqc_cntrl45.L1cache.m_demand_misses / system.ruby.sqc_cntrl45.L1cache.m_demand_accesses  84.1853%
  • system.ruby.sqc_cntrl46.L1cache.m_demand_misses / system.ruby.sqc_cntrl46.L1cache.m_demand_accesses  81.9596%
  • system.ruby.sqc_cntrl47.L1cache.m_demand_misses / system.ruby.sqc_cntrl47.L1cache.m_demand_accesses  83.9172%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses  79.6675%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses  74.7759%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses  95.3737%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses  87.6307%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses  80.2233%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses   5.9217%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  87.9889%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  59.8325%
  • system.ruby.tcp_cntrl10.L1cache.m_demand_misses / system.ruby.tcp_cntrl10.L1cache.m_demand_accesses  60.7044%
  • system.ruby.tcp_cntrl100.L1cache.m_demand_misses / system.ruby.tcp_cntrl100.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl101.L1cache.m_demand_misses / system.ruby.tcp_cntrl101.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl102.L1cache.m_demand_misses / system.ruby.tcp_cntrl102.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl103.L1cache.m_demand_misses / system.ruby.tcp_cntrl103.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl104.L1cache.m_demand_misses / system.ruby.tcp_cntrl104.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl105.L1cache.m_demand_misses / system.ruby.tcp_cntrl105.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl106.L1cache.m_demand_misses / system.ruby.tcp_cntrl106.L1cache.m_demand_accesses  67.9860%
  • system.ruby.tcp_cntrl107.L1cache.m_demand_misses / system.ruby.tcp_cntrl107.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl108.L1cache.m_demand_misses / system.ruby.tcp_cntrl108.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl109.L1cache.m_demand_misses / system.ruby.tcp_cntrl109.L1cache.m_demand_accesses  67.9775%
  • system.ruby.tcp_cntrl11.L1cache.m_demand_misses / system.ruby.tcp_cntrl11.L1cache.m_demand_accesses  61.0380%
  • system.ruby.tcp_cntrl110.L1cache.m_demand_misses / system.ruby.tcp_cntrl110.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl111.L1cache.m_demand_misses / system.ruby.tcp_cntrl111.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl112.L1cache.m_demand_misses / system.ruby.tcp_cntrl112.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl113.L1cache.m_demand_misses / system.ruby.tcp_cntrl113.L1cache.m_demand_accesses  68.0916%
  • system.ruby.tcp_cntrl114.L1cache.m_demand_misses / system.ruby.tcp_cntrl114.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl115.L1cache.m_demand_misses / system.ruby.tcp_cntrl115.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl116.L1cache.m_demand_misses / system.ruby.tcp_cntrl116.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl117.L1cache.m_demand_misses / system.ruby.tcp_cntrl117.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl118.L1cache.m_demand_misses / system.ruby.tcp_cntrl118.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl119.L1cache.m_demand_misses / system.ruby.tcp_cntrl119.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl12.L1cache.m_demand_misses / system.ruby.tcp_cntrl12.L1cache.m_demand_accesses  61.5994%
  • system.ruby.tcp_cntrl120.L1cache.m_demand_misses / system.ruby.tcp_cntrl120.L1cache.m_demand_accesses  67.8832%
  • system.ruby.tcp_cntrl121.L1cache.m_demand_misses / system.ruby.tcp_cntrl121.L1cache.m_demand_accesses  67.8832%
  • system.ruby.tcp_cntrl122.L1cache.m_demand_misses / system.ruby.tcp_cntrl122.L1cache.m_demand_accesses  67.8832%
  • system.ruby.tcp_cntrl123.L1cache.m_demand_misses / system.ruby.tcp_cntrl123.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl124.L1cache.m_demand_misses / system.ruby.tcp_cntrl124.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl125.L1cache.m_demand_misses / system.ruby.tcp_cntrl125.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl126.L1cache.m_demand_misses / system.ruby.tcp_cntrl126.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl127.L1cache.m_demand_misses / system.ruby.tcp_cntrl127.L1cache.m_demand_accesses  67.8146%
  • system.ruby.tcp_cntrl128.L1cache.m_demand_misses / system.ruby.tcp_cntrl128.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl129.L1cache.m_demand_misses / system.ruby.tcp_cntrl129.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl13.L1cache.m_demand_misses / system.ruby.tcp_cntrl13.L1cache.m_demand_accesses  62.0426%
  • system.ruby.tcp_cntrl130.L1cache.m_demand_misses / system.ruby.tcp_cntrl130.L1cache.m_demand_accesses  68.2477%
  • system.ruby.tcp_cntrl131.L1cache.m_demand_misses / system.ruby.tcp_cntrl131.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl132.L1cache.m_demand_misses / system.ruby.tcp_cntrl132.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl133.L1cache.m_demand_misses / system.ruby.tcp_cntrl133.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl134.L1cache.m_demand_misses / system.ruby.tcp_cntrl134.L1cache.m_demand_accesses  68.5115%
  • system.ruby.tcp_cntrl135.L1cache.m_demand_misses / system.ruby.tcp_cntrl135.L1cache.m_demand_accesses  68.5345%
  • system.ruby.tcp_cntrl136.L1cache.m_demand_misses / system.ruby.tcp_cntrl136.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl137.L1cache.m_demand_misses / system.ruby.tcp_cntrl137.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl138.L1cache.m_demand_misses / system.ruby.tcp_cntrl138.L1cache.m_demand_accesses  69.2042%
  • system.ruby.tcp_cntrl139.L1cache.m_demand_misses / system.ruby.tcp_cntrl139.L1cache.m_demand_accesses  69.4323%
  • system.ruby.tcp_cntrl14.L1cache.m_demand_misses / system.ruby.tcp_cntrl14.L1cache.m_demand_accesses  62.5571%
  • system.ruby.tcp_cntrl140.L1cache.m_demand_misses / system.ruby.tcp_cntrl140.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl141.L1cache.m_demand_misses / system.ruby.tcp_cntrl141.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl142.L1cache.m_demand_misses / system.ruby.tcp_cntrl142.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl143.L1cache.m_demand_misses / system.ruby.tcp_cntrl143.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl144.L1cache.m_demand_misses / system.ruby.tcp_cntrl144.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl145.L1cache.m_demand_misses / system.ruby.tcp_cntrl145.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl146.L1cache.m_demand_misses / system.ruby.tcp_cntrl146.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl147.L1cache.m_demand_misses / system.ruby.tcp_cntrl147.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl148.L1cache.m_demand_misses / system.ruby.tcp_cntrl148.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl149.L1cache.m_demand_misses / system.ruby.tcp_cntrl149.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl15.L1cache.m_demand_misses / system.ruby.tcp_cntrl15.L1cache.m_demand_accesses  63.0081%
  • system.ruby.tcp_cntrl150.L1cache.m_demand_misses / system.ruby.tcp_cntrl150.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl151.L1cache.m_demand_misses / system.ruby.tcp_cntrl151.L1cache.m_demand_accesses  68.0916%
  • system.ruby.tcp_cntrl152.L1cache.m_demand_misses / system.ruby.tcp_cntrl152.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl153.L1cache.m_demand_misses / system.ruby.tcp_cntrl153.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl154.L1cache.m_demand_misses / system.ruby.tcp_cntrl154.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl155.L1cache.m_demand_misses / system.ruby.tcp_cntrl155.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl156.L1cache.m_demand_misses / system.ruby.tcp_cntrl156.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl157.L1cache.m_demand_misses / system.ruby.tcp_cntrl157.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl158.L1cache.m_demand_misses / system.ruby.tcp_cntrl158.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl159.L1cache.m_demand_misses / system.ruby.tcp_cntrl159.L1cache.m_demand_accesses  69.1892%
  • system.ruby.tcp_cntrl16.L1cache.m_demand_misses / system.ruby.tcp_cntrl16.L1cache.m_demand_accesses  63.8695%
  • system.ruby.tcp_cntrl160.L1cache.m_demand_misses / system.ruby.tcp_cntrl160.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl161.L1cache.m_demand_misses / system.ruby.tcp_cntrl161.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl162.L1cache.m_demand_misses / system.ruby.tcp_cntrl162.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl163.L1cache.m_demand_misses / system.ruby.tcp_cntrl163.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl164.L1cache.m_demand_misses / system.ruby.tcp_cntrl164.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl165.L1cache.m_demand_misses / system.ruby.tcp_cntrl165.L1cache.m_demand_accesses  68.3686%
  • system.ruby.tcp_cntrl166.L1cache.m_demand_misses / system.ruby.tcp_cntrl166.L1cache.m_demand_accesses  68.3089%
  • system.ruby.tcp_cntrl167.L1cache.m_demand_misses / system.ruby.tcp_cntrl167.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl168.L1cache.m_demand_misses / system.ruby.tcp_cntrl168.L1cache.m_demand_accesses  68.3089%
  • system.ruby.tcp_cntrl169.L1cache.m_demand_misses / system.ruby.tcp_cntrl169.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl17.L1cache.m_demand_misses / system.ruby.tcp_cntrl17.L1cache.m_demand_accesses  64.8052%
  • system.ruby.tcp_cntrl170.L1cache.m_demand_misses / system.ruby.tcp_cntrl170.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl171.L1cache.m_demand_misses / system.ruby.tcp_cntrl171.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl172.L1cache.m_demand_misses / system.ruby.tcp_cntrl172.L1cache.m_demand_accesses  68.5115%
  • system.ruby.tcp_cntrl173.L1cache.m_demand_misses / system.ruby.tcp_cntrl173.L1cache.m_demand_accesses  68.5345%
  • system.ruby.tcp_cntrl174.L1cache.m_demand_misses / system.ruby.tcp_cntrl174.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl175.L1cache.m_demand_misses / system.ruby.tcp_cntrl175.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl176.L1cache.m_demand_misses / system.ruby.tcp_cntrl176.L1cache.m_demand_accesses  69.2042%
  • system.ruby.tcp_cntrl177.L1cache.m_demand_misses / system.ruby.tcp_cntrl177.L1cache.m_demand_accesses  69.4323%
  • system.ruby.tcp_cntrl178.L1cache.m_demand_misses / system.ruby.tcp_cntrl178.L1cache.m_demand_accesses  69.4915%
  • system.ruby.tcp_cntrl179.L1cache.m_demand_misses / system.ruby.tcp_cntrl179.L1cache.m_demand_accesses  69.6000%
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses  65.8574%
  • system.ruby.tcp_cntrl180.L1cache.m_demand_misses / system.ruby.tcp_cntrl180.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl181.L1cache.m_demand_misses / system.ruby.tcp_cntrl181.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl182.L1cache.m_demand_misses / system.ruby.tcp_cntrl182.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl183.L1cache.m_demand_misses / system.ruby.tcp_cntrl183.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl184.L1cache.m_demand_misses / system.ruby.tcp_cntrl184.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl185.L1cache.m_demand_misses / system.ruby.tcp_cntrl185.L1cache.m_demand_accesses  68.2192%
  • system.ruby.tcp_cntrl186.L1cache.m_demand_misses / system.ruby.tcp_cntrl186.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl187.L1cache.m_demand_misses / system.ruby.tcp_cntrl187.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl188.L1cache.m_demand_misses / system.ruby.tcp_cntrl188.L1cache.m_demand_accesses  68.1416%
  • system.ruby.tcp_cntrl189.L1cache.m_demand_misses / system.ruby.tcp_cntrl189.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses  67.1727%
  • system.ruby.tcp_cntrl190.L1cache.m_demand_misses / system.ruby.tcp_cntrl190.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl191.L1cache.m_demand_misses / system.ruby.tcp_cntrl191.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  55.7203%
  • system.ruby.tcp_cntrl20.L1cache.m_demand_misses / system.ruby.tcp_cntrl20.L1cache.m_demand_accesses  67.8176%
  • system.ruby.tcp_cntrl21.L1cache.m_demand_misses / system.ruby.tcp_cntrl21.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl22.L1cache.m_demand_misses / system.ruby.tcp_cntrl22.L1cache.m_demand_accesses  67.8706%
  • system.ruby.tcp_cntrl23.L1cache.m_demand_misses / system.ruby.tcp_cntrl23.L1cache.m_demand_accesses  67.7896%
  • system.ruby.tcp_cntrl24.L1cache.m_demand_misses / system.ruby.tcp_cntrl24.L1cache.m_demand_accesses  67.6550%
  • system.ruby.tcp_cntrl25.L1cache.m_demand_misses / system.ruby.tcp_cntrl25.L1cache.m_demand_accesses  67.7778%
  • system.ruby.tcp_cntrl26.L1cache.m_demand_misses / system.ruby.tcp_cntrl26.L1cache.m_demand_accesses  67.9860%
  • system.ruby.tcp_cntrl27.L1cache.m_demand_misses / system.ruby.tcp_cntrl27.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl28.L1cache.m_demand_misses / system.ruby.tcp_cntrl28.L1cache.m_demand_accesses  67.7258%
  • system.ruby.tcp_cntrl29.L1cache.m_demand_misses / system.ruby.tcp_cntrl29.L1cache.m_demand_accesses  67.9111%
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses  56.4920%
  • system.ruby.tcp_cntrl30.L1cache.m_demand_misses / system.ruby.tcp_cntrl30.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl31.L1cache.m_demand_misses / system.ruby.tcp_cntrl31.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl32.L1cache.m_demand_misses / system.ruby.tcp_cntrl32.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl33.L1cache.m_demand_misses / system.ruby.tcp_cntrl33.L1cache.m_demand_accesses  67.9775%
  • system.ruby.tcp_cntrl34.L1cache.m_demand_misses / system.ruby.tcp_cntrl34.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl35.L1cache.m_demand_misses / system.ruby.tcp_cntrl35.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl36.L1cache.m_demand_misses / system.ruby.tcp_cntrl36.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl37.L1cache.m_demand_misses / system.ruby.tcp_cntrl37.L1cache.m_demand_accesses  68.0916%
  • system.ruby.tcp_cntrl38.L1cache.m_demand_misses / system.ruby.tcp_cntrl38.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl39.L1cache.m_demand_misses / system.ruby.tcp_cntrl39.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses  57.1607%
  • system.ruby.tcp_cntrl40.L1cache.m_demand_misses / system.ruby.tcp_cntrl40.L1cache.m_demand_accesses  67.7680%
  • system.ruby.tcp_cntrl41.L1cache.m_demand_misses / system.ruby.tcp_cntrl41.L1cache.m_demand_accesses  67.7149%
  • system.ruby.tcp_cntrl42.L1cache.m_demand_misses / system.ruby.tcp_cntrl42.L1cache.m_demand_accesses  67.6558%
  • system.ruby.tcp_cntrl43.L1cache.m_demand_misses / system.ruby.tcp_cntrl43.L1cache.m_demand_accesses  67.7551%
  • system.ruby.tcp_cntrl44.L1cache.m_demand_misses / system.ruby.tcp_cntrl44.L1cache.m_demand_accesses  67.6550%
  • system.ruby.tcp_cntrl45.L1cache.m_demand_misses / system.ruby.tcp_cntrl45.L1cache.m_demand_accesses  67.4926%
  • system.ruby.tcp_cntrl46.L1cache.m_demand_misses / system.ruby.tcp_cntrl46.L1cache.m_demand_accesses  67.6072%
  • system.ruby.tcp_cntrl47.L1cache.m_demand_misses / system.ruby.tcp_cntrl47.L1cache.m_demand_accesses  67.8146%
  • system.ruby.tcp_cntrl48.L1cache.m_demand_misses / system.ruby.tcp_cntrl48.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl49.L1cache.m_demand_misses / system.ruby.tcp_cntrl49.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses  56.8750%
  • system.ruby.tcp_cntrl50.L1cache.m_demand_misses / system.ruby.tcp_cntrl50.L1cache.m_demand_accesses  68.1087%
  • system.ruby.tcp_cntrl51.L1cache.m_demand_misses / system.ruby.tcp_cntrl51.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl52.L1cache.m_demand_misses / system.ruby.tcp_cntrl52.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl53.L1cache.m_demand_misses / system.ruby.tcp_cntrl53.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl54.L1cache.m_demand_misses / system.ruby.tcp_cntrl54.L1cache.m_demand_accesses  68.2477%
  • system.ruby.tcp_cntrl55.L1cache.m_demand_misses / system.ruby.tcp_cntrl55.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl56.L1cache.m_demand_misses / system.ruby.tcp_cntrl56.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl57.L1cache.m_demand_misses / system.ruby.tcp_cntrl57.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl58.L1cache.m_demand_misses / system.ruby.tcp_cntrl58.L1cache.m_demand_accesses  68.5115%
  • system.ruby.tcp_cntrl59.L1cache.m_demand_misses / system.ruby.tcp_cntrl59.L1cache.m_demand_accesses  68.5345%
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses  56.4615%
  • system.ruby.tcp_cntrl60.L1cache.m_demand_misses / system.ruby.tcp_cntrl60.L1cache.m_demand_accesses  67.9487%
  • system.ruby.tcp_cntrl61.L1cache.m_demand_misses / system.ruby.tcp_cntrl61.L1cache.m_demand_accesses  67.8994%
  • system.ruby.tcp_cntrl62.L1cache.m_demand_misses / system.ruby.tcp_cntrl62.L1cache.m_demand_accesses  67.8462%
  • system.ruby.tcp_cntrl63.L1cache.m_demand_misses / system.ruby.tcp_cntrl63.L1cache.m_demand_accesses  67.7896%
  • system.ruby.tcp_cntrl64.L1cache.m_demand_misses / system.ruby.tcp_cntrl64.L1cache.m_demand_accesses  67.9159%
  • system.ruby.tcp_cntrl65.L1cache.m_demand_misses / system.ruby.tcp_cntrl65.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl66.L1cache.m_demand_misses / system.ruby.tcp_cntrl66.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl67.L1cache.m_demand_misses / system.ruby.tcp_cntrl67.L1cache.m_demand_accesses  67.8146%
  • system.ruby.tcp_cntrl68.L1cache.m_demand_misses / system.ruby.tcp_cntrl68.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl69.L1cache.m_demand_misses / system.ruby.tcp_cntrl69.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses  55.9932%
  • system.ruby.tcp_cntrl70.L1cache.m_demand_misses / system.ruby.tcp_cntrl70.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl71.L1cache.m_demand_misses / system.ruby.tcp_cntrl71.L1cache.m_demand_accesses  67.9775%
  • system.ruby.tcp_cntrl72.L1cache.m_demand_misses / system.ruby.tcp_cntrl72.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl73.L1cache.m_demand_misses / system.ruby.tcp_cntrl73.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl74.L1cache.m_demand_misses / system.ruby.tcp_cntrl74.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl75.L1cache.m_demand_misses / system.ruby.tcp_cntrl75.L1cache.m_demand_accesses  68.0916%
  • system.ruby.tcp_cntrl76.L1cache.m_demand_misses / system.ruby.tcp_cntrl76.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl77.L1cache.m_demand_misses / system.ruby.tcp_cntrl77.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl78.L1cache.m_demand_misses / system.ruby.tcp_cntrl78.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl79.L1cache.m_demand_misses / system.ruby.tcp_cntrl79.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl8.L1cache.m_demand_misses / system.ruby.tcp_cntrl8.L1cache.m_demand_accesses  60.1485%
  • system.ruby.tcp_cntrl80.L1cache.m_demand_misses / system.ruby.tcp_cntrl80.L1cache.m_demand_accesses  68.0982%
  • system.ruby.tcp_cntrl81.L1cache.m_demand_misses / system.ruby.tcp_cntrl81.L1cache.m_demand_accesses  68.1068%
  • system.ruby.tcp_cntrl82.L1cache.m_demand_misses / system.ruby.tcp_cntrl82.L1cache.m_demand_accesses  68.0590%
  • system.ruby.tcp_cntrl83.L1cache.m_demand_misses / system.ruby.tcp_cntrl83.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl84.L1cache.m_demand_misses / system.ruby.tcp_cntrl84.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl85.L1cache.m_demand_misses / system.ruby.tcp_cntrl85.L1cache.m_demand_accesses  68.1205%
  • system.ruby.tcp_cntrl86.L1cache.m_demand_misses / system.ruby.tcp_cntrl86.L1cache.m_demand_accesses  68.0376%
  • system.ruby.tcp_cntrl87.L1cache.m_demand_misses / system.ruby.tcp_cntrl87.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl88.L1cache.m_demand_misses / system.ruby.tcp_cntrl88.L1cache.m_demand_accesses  68.1087%
  • system.ruby.tcp_cntrl89.L1cache.m_demand_misses / system.ruby.tcp_cntrl89.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl9.L1cache.m_demand_misses / system.ruby.tcp_cntrl9.L1cache.m_demand_accesses  60.4058%
  • system.ruby.tcp_cntrl90.L1cache.m_demand_misses / system.ruby.tcp_cntrl90.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl91.L1cache.m_demand_misses / system.ruby.tcp_cntrl91.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl92.L1cache.m_demand_misses / system.ruby.tcp_cntrl92.L1cache.m_demand_accesses  68.2477%
  • system.ruby.tcp_cntrl93.L1cache.m_demand_misses / system.ruby.tcp_cntrl93.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl94.L1cache.m_demand_misses / system.ruby.tcp_cntrl94.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl95.L1cache.m_demand_misses / system.ruby.tcp_cntrl95.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl96.L1cache.m_demand_misses / system.ruby.tcp_cntrl96.L1cache.m_demand_accesses  68.5115%
  • system.ruby.tcp_cntrl97.L1cache.m_demand_misses / system.ruby.tcp_cntrl97.L1cache.m_demand_accesses  68.5345%
  • system.ruby.tcp_cntrl98.L1cache.m_demand_misses / system.ruby.tcp_cntrl98.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl99.L1cache.m_demand_misses / system.ruby.tcp_cntrl99.L1cache.m_demand_accesses  68.3333%

Functional Tests (offline evidence)
------------------------------------------------------------------------------------------------
• 资源实例化        PASS
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=48, cu=192, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.024985
  evidence: stats.txt: system.cpu1.ipc=0.000039
  evidence: stats.txt: system.cpu10.ipc=0.000009
• 系统初始化        PASS
  notes: 检测到进入执行阶段迹象
  evidence: simout/simerr:958: Exiting because  exiting with last active thread context
• 功能执行         PASS
  notes: 检测到正常退出迹象
  evidence: simout/simerr:958: Exiting because  exiting with last active thread context
• 结果校验         PASS
  notes: 检测到 correctness/返回状态成功信号
  evidence: simout/simerr:441: [gaussian] pthread_create success tid=0 iter=0
  evidence: simout/simerr:443: [gaussian] pthread_create success tid=1 iter=0
  evidence: simout/simerr:445: [gaussian] pthread_create success tid=2 iter=0
• 异常检查         PASS
  notes: 未命中严重异常关键字
  evidence: (none)
