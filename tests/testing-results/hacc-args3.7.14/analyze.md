
====================================================================================================================================================
  Analyze Summary
====================================================================================================================================================
run_dir            : /home/orange/gem5-demo/tests/testing-results/hacc-args3.7.14
latency_files      : cpu=336 gpu=192
ldst_weighted_mean : 24.978006
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : /home/orange/gem5-demo/tests/testing-results/hacc-args3.7.14/analyze.md
output_json        : /home/orange/gem5-demo/tests/testing-results/hacc-args3.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 336
total samples: 97,657,439
mean/min/max: 11.52 / 1 / 7317
slow buckets: >100=5,270,354  >500=9,656  >1000=555  >5000=24
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH            76,166,776        7.27         1      4111
LD                14,815,023       29.15         1      7317
Locked_RMW_Read        92,160       59.60         1      4529
Locked_RMW_Write        92,160        1.00         1         1
RMW_Read              81,519       47.68         1       823
ST                 6,409,801       20.31         1      5170

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 192
total samples: 1,830,991
mean/min/max: 7.58 / 1 / 422
slow buckets: >100=30,405  >500=0  >1000=0  >5000=0
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
ATOMIC_RETURN            585      212.84       169       422
LD                 1,650,214        8.23         1       275
ST                   180,192        1.00         1         1

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 24.978006
samples(cpu/gpu/total): 21224824/1830406/23055230

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  23.1716%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  35.6659%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses  10.2574%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  41.3549%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses  31.3202%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses  30.7740%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   9.4581%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  58.0358%
  • system.ruby.cp_cntrl10.L1D0cache.m_demand_misses / system.ruby.cp_cntrl10.L1D0cache.m_demand_accesses   0.1282%
  • system.ruby.cp_cntrl10.L1D1cache.m_demand_misses / system.ruby.cp_cntrl10.L1D1cache.m_demand_accesses   0.1308%
  • system.ruby.cp_cntrl10.L1Icache.m_demand_misses / system.ruby.cp_cntrl10.L1Icache.m_demand_accesses   0.0430%
  • system.ruby.cp_cntrl10.L2cache.m_demand_misses / system.ruby.cp_cntrl10.L2cache.m_demand_accesses   1.0504%
  • system.ruby.cp_cntrl11.L1D0cache.m_demand_misses / system.ruby.cp_cntrl11.L1D0cache.m_demand_accesses   0.1381%
  • system.ruby.cp_cntrl11.L1D1cache.m_demand_misses / system.ruby.cp_cntrl11.L1D1cache.m_demand_accesses   0.1369%
  • system.ruby.cp_cntrl11.L1Icache.m_demand_misses / system.ruby.cp_cntrl11.L1Icache.m_demand_accesses   0.0436%
  • system.ruby.cp_cntrl11.L2cache.m_demand_misses / system.ruby.cp_cntrl11.L2cache.m_demand_accesses   1.0714%
  • system.ruby.cp_cntrl12.L1D0cache.m_demand_misses / system.ruby.cp_cntrl12.L1D0cache.m_demand_accesses   0.1460%
  • system.ruby.cp_cntrl12.L1D1cache.m_demand_misses / system.ruby.cp_cntrl12.L1D1cache.m_demand_accesses   0.1519%
  • system.ruby.cp_cntrl12.L1Icache.m_demand_misses / system.ruby.cp_cntrl12.L1Icache.m_demand_accesses   0.0500%
  • system.ruby.cp_cntrl12.L2cache.m_demand_misses / system.ruby.cp_cntrl12.L2cache.m_demand_accesses   1.1939%
  • system.ruby.cp_cntrl13.L1D0cache.m_demand_misses / system.ruby.cp_cntrl13.L1D0cache.m_demand_accesses   0.1596%
  • system.ruby.cp_cntrl13.L1D1cache.m_demand_misses / system.ruby.cp_cntrl13.L1D1cache.m_demand_accesses   0.1630%
  • system.ruby.cp_cntrl13.L1Icache.m_demand_misses / system.ruby.cp_cntrl13.L1Icache.m_demand_accesses   0.0518%
  • system.ruby.cp_cntrl13.L2cache.m_demand_misses / system.ruby.cp_cntrl13.L2cache.m_demand_accesses   1.2638%
  • system.ruby.cp_cntrl14.L1D0cache.m_demand_misses / system.ruby.cp_cntrl14.L1D0cache.m_demand_accesses   0.1716%
  • system.ruby.cp_cntrl14.L1D1cache.m_demand_misses / system.ruby.cp_cntrl14.L1D1cache.m_demand_accesses   0.1778%
  • system.ruby.cp_cntrl14.L1Icache.m_demand_misses / system.ruby.cp_cntrl14.L1Icache.m_demand_accesses   0.0548%
  • system.ruby.cp_cntrl14.L2cache.m_demand_misses / system.ruby.cp_cntrl14.L2cache.m_demand_accesses   1.3647%
  • system.ruby.cp_cntrl15.L1D0cache.m_demand_misses / system.ruby.cp_cntrl15.L1D0cache.m_demand_accesses   0.1917%
  • system.ruby.cp_cntrl15.L1D1cache.m_demand_misses / system.ruby.cp_cntrl15.L1D1cache.m_demand_accesses   0.1965%
  • system.ruby.cp_cntrl15.L1Icache.m_demand_misses / system.ruby.cp_cntrl15.L1Icache.m_demand_accesses   0.0645%
  • system.ruby.cp_cntrl15.L2cache.m_demand_misses / system.ruby.cp_cntrl15.L2cache.m_demand_accesses   1.5558%
  • system.ruby.cp_cntrl16.L1D0cache.m_demand_misses / system.ruby.cp_cntrl16.L1D0cache.m_demand_accesses   0.2113%
  • system.ruby.cp_cntrl16.L1D1cache.m_demand_misses / system.ruby.cp_cntrl16.L1D1cache.m_demand_accesses   0.2211%
  • system.ruby.cp_cntrl16.L1Icache.m_demand_misses / system.ruby.cp_cntrl16.L1Icache.m_demand_accesses   0.0695%
  • system.ruby.cp_cntrl16.L2cache.m_demand_misses / system.ruby.cp_cntrl16.L2cache.m_demand_accesses   1.6831%
  • system.ruby.cp_cntrl17.L1D0cache.m_demand_misses / system.ruby.cp_cntrl17.L1D0cache.m_demand_accesses   0.2380%
  • system.ruby.cp_cntrl17.L1D1cache.m_demand_misses / system.ruby.cp_cntrl17.L1D1cache.m_demand_accesses   0.2484%
  • system.ruby.cp_cntrl17.L1Icache.m_demand_misses / system.ruby.cp_cntrl17.L1Icache.m_demand_accesses   0.0783%
  • system.ruby.cp_cntrl17.L2cache.m_demand_misses / system.ruby.cp_cntrl17.L2cache.m_demand_accesses   1.9146%
  • system.ruby.cp_cntrl18.L1D0cache.m_demand_misses / system.ruby.cp_cntrl18.L1D0cache.m_demand_accesses   0.2709%
  • system.ruby.cp_cntrl18.L1D1cache.m_demand_misses / system.ruby.cp_cntrl18.L1D1cache.m_demand_accesses   0.2939%
  • system.ruby.cp_cntrl18.L1Icache.m_demand_misses / system.ruby.cp_cntrl18.L1Icache.m_demand_accesses   0.0927%
  • system.ruby.cp_cntrl18.L2cache.m_demand_misses / system.ruby.cp_cntrl18.L2cache.m_demand_accesses   2.2316%
  • system.ruby.cp_cntrl19.L1D0cache.m_demand_misses / system.ruby.cp_cntrl19.L1D0cache.m_demand_accesses   0.3098%
  • system.ruby.cp_cntrl19.L1D1cache.m_demand_misses / system.ruby.cp_cntrl19.L1D1cache.m_demand_accesses   0.3349%
  • system.ruby.cp_cntrl19.L1Icache.m_demand_misses / system.ruby.cp_cntrl19.L1Icache.m_demand_accesses   0.1091%
  • system.ruby.cp_cntrl19.L2cache.m_demand_misses / system.ruby.cp_cntrl19.L2cache.m_demand_accesses   2.5634%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses  16.4154%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses   0.0810%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   3.4793%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses  39.5309%
  • system.ruby.cp_cntrl20.L1D0cache.m_demand_misses / system.ruby.cp_cntrl20.L1D0cache.m_demand_accesses   0.3703%
  • system.ruby.cp_cntrl20.L1D1cache.m_demand_misses / system.ruby.cp_cntrl20.L1D1cache.m_demand_accesses   0.4113%
  • system.ruby.cp_cntrl20.L1Icache.m_demand_misses / system.ruby.cp_cntrl20.L1Icache.m_demand_accesses   0.1255%
  • system.ruby.cp_cntrl20.L2cache.m_demand_misses / system.ruby.cp_cntrl20.L2cache.m_demand_accesses   3.0331%
  • system.ruby.cp_cntrl21.L1D0cache.m_demand_misses / system.ruby.cp_cntrl21.L1D0cache.m_demand_accesses   0.4612%
  • system.ruby.cp_cntrl21.L1D1cache.m_demand_misses / system.ruby.cp_cntrl21.L1D1cache.m_demand_accesses   0.5194%
  • system.ruby.cp_cntrl21.L1Icache.m_demand_misses / system.ruby.cp_cntrl21.L1Icache.m_demand_accesses   0.1568%
  • system.ruby.cp_cntrl21.L2cache.m_demand_misses / system.ruby.cp_cntrl21.L2cache.m_demand_accesses   3.7247%
  • system.ruby.cp_cntrl22.L1D0cache.m_demand_misses / system.ruby.cp_cntrl22.L1D0cache.m_demand_accesses   0.6115%
  • system.ruby.cp_cntrl22.L1D1cache.m_demand_misses / system.ruby.cp_cntrl22.L1D1cache.m_demand_accesses   0.7187%
  • system.ruby.cp_cntrl22.L1Icache.m_demand_misses / system.ruby.cp_cntrl22.L1Icache.m_demand_accesses   0.2161%
  • system.ruby.cp_cntrl22.L2cache.m_demand_misses / system.ruby.cp_cntrl22.L2cache.m_demand_accesses   5.0349%
  • system.ruby.cp_cntrl23.L1D0cache.m_demand_misses / system.ruby.cp_cntrl23.L1D0cache.m_demand_accesses   0.8925%
  • system.ruby.cp_cntrl23.L1D1cache.m_demand_misses / system.ruby.cp_cntrl23.L1D1cache.m_demand_accesses   1.1366%
  • system.ruby.cp_cntrl23.L1Icache.m_demand_misses / system.ruby.cp_cntrl23.L1Icache.m_demand_accesses   0.3245%
  • system.ruby.cp_cntrl23.L2cache.m_demand_misses / system.ruby.cp_cntrl23.L2cache.m_demand_accesses   7.4430%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses   0.0886%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses   0.0880%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   0.0292%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses   0.7120%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses   0.0912%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses   0.0926%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   0.0303%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses   0.7394%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses   0.0954%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses   0.0939%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   0.0301%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses   0.7470%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses   0.0997%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses   0.0993%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   0.0332%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses   0.8067%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses   0.1081%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses   0.1049%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   0.0334%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses   0.8336%
  • system.ruby.cp_cntrl8.L1D0cache.m_demand_misses / system.ruby.cp_cntrl8.L1D0cache.m_demand_accesses   0.1133%
  • system.ruby.cp_cntrl8.L1D1cache.m_demand_misses / system.ruby.cp_cntrl8.L1D1cache.m_demand_accesses   0.1132%
  • system.ruby.cp_cntrl8.L1Icache.m_demand_misses / system.ruby.cp_cntrl8.L1Icache.m_demand_accesses   0.0364%
  • system.ruby.cp_cntrl8.L2cache.m_demand_misses / system.ruby.cp_cntrl8.L2cache.m_demand_accesses   0.9012%
  • system.ruby.cp_cntrl9.L1D0cache.m_demand_misses / system.ruby.cp_cntrl9.L1D0cache.m_demand_accesses   0.1206%
  • system.ruby.cp_cntrl9.L1D1cache.m_demand_misses / system.ruby.cp_cntrl9.L1D1cache.m_demand_accesses   0.1178%
  • system.ruby.cp_cntrl9.L1Icache.m_demand_misses / system.ruby.cp_cntrl9.L1Icache.m_demand_accesses   0.0389%
  • system.ruby.cp_cntrl9.L2cache.m_demand_misses / system.ruby.cp_cntrl9.L2cache.m_demand_accesses   0.9475%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   2.9235%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  73.5075%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl10.L1cache.m_demand_misses / system.ruby.scalar_cntrl10.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl11.L1cache.m_demand_misses / system.ruby.scalar_cntrl11.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl12.L1cache.m_demand_misses / system.ruby.scalar_cntrl12.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl13.L1cache.m_demand_misses / system.ruby.scalar_cntrl13.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl14.L1cache.m_demand_misses / system.ruby.scalar_cntrl14.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl15.L1cache.m_demand_misses / system.ruby.scalar_cntrl15.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl16.L1cache.m_demand_misses / system.ruby.scalar_cntrl16.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl17.L1cache.m_demand_misses / system.ruby.scalar_cntrl17.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl18.L1cache.m_demand_misses / system.ruby.scalar_cntrl18.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl19.L1cache.m_demand_misses / system.ruby.scalar_cntrl19.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl2.L1cache.m_demand_misses / system.ruby.scalar_cntrl2.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl20.L1cache.m_demand_misses / system.ruby.scalar_cntrl20.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl21.L1cache.m_demand_misses / system.ruby.scalar_cntrl21.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl22.L1cache.m_demand_misses / system.ruby.scalar_cntrl22.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl23.L1cache.m_demand_misses / system.ruby.scalar_cntrl23.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl24.L1cache.m_demand_misses / system.ruby.scalar_cntrl24.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl25.L1cache.m_demand_misses / system.ruby.scalar_cntrl25.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl26.L1cache.m_demand_misses / system.ruby.scalar_cntrl26.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl27.L1cache.m_demand_misses / system.ruby.scalar_cntrl27.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl28.L1cache.m_demand_misses / system.ruby.scalar_cntrl28.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl29.L1cache.m_demand_misses / system.ruby.scalar_cntrl29.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl3.L1cache.m_demand_misses / system.ruby.scalar_cntrl3.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl30.L1cache.m_demand_misses / system.ruby.scalar_cntrl30.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl31.L1cache.m_demand_misses / system.ruby.scalar_cntrl31.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl32.L1cache.m_demand_misses / system.ruby.scalar_cntrl32.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl33.L1cache.m_demand_misses / system.ruby.scalar_cntrl33.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl34.L1cache.m_demand_misses / system.ruby.scalar_cntrl34.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl35.L1cache.m_demand_misses / system.ruby.scalar_cntrl35.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl36.L1cache.m_demand_misses / system.ruby.scalar_cntrl36.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl37.L1cache.m_demand_misses / system.ruby.scalar_cntrl37.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl38.L1cache.m_demand_misses / system.ruby.scalar_cntrl38.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl39.L1cache.m_demand_misses / system.ruby.scalar_cntrl39.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl4.L1cache.m_demand_misses / system.ruby.scalar_cntrl4.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl40.L1cache.m_demand_misses / system.ruby.scalar_cntrl40.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl41.L1cache.m_demand_misses / system.ruby.scalar_cntrl41.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl42.L1cache.m_demand_misses / system.ruby.scalar_cntrl42.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl43.L1cache.m_demand_misses / system.ruby.scalar_cntrl43.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl44.L1cache.m_demand_misses / system.ruby.scalar_cntrl44.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl45.L1cache.m_demand_misses / system.ruby.scalar_cntrl45.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl46.L1cache.m_demand_misses / system.ruby.scalar_cntrl46.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl47.L1cache.m_demand_misses / system.ruby.scalar_cntrl47.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses 100.0000%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses 100.0000%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses  52.6722%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses   1.1765%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses   1.1380%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses   1.1380%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses   1.1412%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses   1.1380%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses   1.1380%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses   1.1461%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses   1.1765%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses   1.1461%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl40.L1cache.m_demand_misses / system.ruby.sqc_cntrl40.L1cache.m_demand_accesses   1.1461%
  • system.ruby.sqc_cntrl41.L1cache.m_demand_misses / system.ruby.sqc_cntrl41.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl42.L1cache.m_demand_misses / system.ruby.sqc_cntrl42.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl43.L1cache.m_demand_misses / system.ruby.sqc_cntrl43.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl44.L1cache.m_demand_misses / system.ruby.sqc_cntrl44.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl45.L1cache.m_demand_misses / system.ruby.sqc_cntrl45.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl46.L1cache.m_demand_misses / system.ruby.sqc_cntrl46.L1cache.m_demand_accesses   1.1445%
  • system.ruby.sqc_cntrl47.L1cache.m_demand_misses / system.ruby.sqc_cntrl47.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses   1.1429%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses   1.1396%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses   1.1364%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses   1.1380%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses   1.1364%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses  45.9275%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  87.9672%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  85.4723%
  • system.ruby.tcp_cntrl10.L1cache.m_demand_misses / system.ruby.tcp_cntrl10.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl100.L1cache.m_demand_misses / system.ruby.tcp_cntrl100.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl101.L1cache.m_demand_misses / system.ruby.tcp_cntrl101.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl102.L1cache.m_demand_misses / system.ruby.tcp_cntrl102.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl103.L1cache.m_demand_misses / system.ruby.tcp_cntrl103.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl104.L1cache.m_demand_misses / system.ruby.tcp_cntrl104.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl105.L1cache.m_demand_misses / system.ruby.tcp_cntrl105.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl106.L1cache.m_demand_misses / system.ruby.tcp_cntrl106.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl107.L1cache.m_demand_misses / system.ruby.tcp_cntrl107.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl108.L1cache.m_demand_misses / system.ruby.tcp_cntrl108.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl109.L1cache.m_demand_misses / system.ruby.tcp_cntrl109.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl11.L1cache.m_demand_misses / system.ruby.tcp_cntrl11.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl110.L1cache.m_demand_misses / system.ruby.tcp_cntrl110.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl111.L1cache.m_demand_misses / system.ruby.tcp_cntrl111.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl112.L1cache.m_demand_misses / system.ruby.tcp_cntrl112.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl113.L1cache.m_demand_misses / system.ruby.tcp_cntrl113.L1cache.m_demand_accesses   5.5215%
  • system.ruby.tcp_cntrl114.L1cache.m_demand_misses / system.ruby.tcp_cntrl114.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl115.L1cache.m_demand_misses / system.ruby.tcp_cntrl115.L1cache.m_demand_accesses   5.5901%
  • system.ruby.tcp_cntrl116.L1cache.m_demand_misses / system.ruby.tcp_cntrl116.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl117.L1cache.m_demand_misses / system.ruby.tcp_cntrl117.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl118.L1cache.m_demand_misses / system.ruby.tcp_cntrl118.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl119.L1cache.m_demand_misses / system.ruby.tcp_cntrl119.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl12.L1cache.m_demand_misses / system.ruby.tcp_cntrl12.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl120.L1cache.m_demand_misses / system.ruby.tcp_cntrl120.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl121.L1cache.m_demand_misses / system.ruby.tcp_cntrl121.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl122.L1cache.m_demand_misses / system.ruby.tcp_cntrl122.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl123.L1cache.m_demand_misses / system.ruby.tcp_cntrl123.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl124.L1cache.m_demand_misses / system.ruby.tcp_cntrl124.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl125.L1cache.m_demand_misses / system.ruby.tcp_cntrl125.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl126.L1cache.m_demand_misses / system.ruby.tcp_cntrl126.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl127.L1cache.m_demand_misses / system.ruby.tcp_cntrl127.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl128.L1cache.m_demand_misses / system.ruby.tcp_cntrl128.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl129.L1cache.m_demand_misses / system.ruby.tcp_cntrl129.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl13.L1cache.m_demand_misses / system.ruby.tcp_cntrl13.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl130.L1cache.m_demand_misses / system.ruby.tcp_cntrl130.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl131.L1cache.m_demand_misses / system.ruby.tcp_cntrl131.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl132.L1cache.m_demand_misses / system.ruby.tcp_cntrl132.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl133.L1cache.m_demand_misses / system.ruby.tcp_cntrl133.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl134.L1cache.m_demand_misses / system.ruby.tcp_cntrl134.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl135.L1cache.m_demand_misses / system.ruby.tcp_cntrl135.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl136.L1cache.m_demand_misses / system.ruby.tcp_cntrl136.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl137.L1cache.m_demand_misses / system.ruby.tcp_cntrl137.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl138.L1cache.m_demand_misses / system.ruby.tcp_cntrl138.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl139.L1cache.m_demand_misses / system.ruby.tcp_cntrl139.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl14.L1cache.m_demand_misses / system.ruby.tcp_cntrl14.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl140.L1cache.m_demand_misses / system.ruby.tcp_cntrl140.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl141.L1cache.m_demand_misses / system.ruby.tcp_cntrl141.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl142.L1cache.m_demand_misses / system.ruby.tcp_cntrl142.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl143.L1cache.m_demand_misses / system.ruby.tcp_cntrl143.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl144.L1cache.m_demand_misses / system.ruby.tcp_cntrl144.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl145.L1cache.m_demand_misses / system.ruby.tcp_cntrl145.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl146.L1cache.m_demand_misses / system.ruby.tcp_cntrl146.L1cache.m_demand_accesses   5.5901%
  • system.ruby.tcp_cntrl147.L1cache.m_demand_misses / system.ruby.tcp_cntrl147.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl148.L1cache.m_demand_misses / system.ruby.tcp_cntrl148.L1cache.m_demand_accesses   5.5215%
  • system.ruby.tcp_cntrl149.L1cache.m_demand_misses / system.ruby.tcp_cntrl149.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl15.L1cache.m_demand_misses / system.ruby.tcp_cntrl15.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl150.L1cache.m_demand_misses / system.ruby.tcp_cntrl150.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl151.L1cache.m_demand_misses / system.ruby.tcp_cntrl151.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl152.L1cache.m_demand_misses / system.ruby.tcp_cntrl152.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl153.L1cache.m_demand_misses / system.ruby.tcp_cntrl153.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl154.L1cache.m_demand_misses / system.ruby.tcp_cntrl154.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl155.L1cache.m_demand_misses / system.ruby.tcp_cntrl155.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl156.L1cache.m_demand_misses / system.ruby.tcp_cntrl156.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl157.L1cache.m_demand_misses / system.ruby.tcp_cntrl157.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl158.L1cache.m_demand_misses / system.ruby.tcp_cntrl158.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl159.L1cache.m_demand_misses / system.ruby.tcp_cntrl159.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl16.L1cache.m_demand_misses / system.ruby.tcp_cntrl16.L1cache.m_demand_accesses   5.5901%
  • system.ruby.tcp_cntrl160.L1cache.m_demand_misses / system.ruby.tcp_cntrl160.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl161.L1cache.m_demand_misses / system.ruby.tcp_cntrl161.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl162.L1cache.m_demand_misses / system.ruby.tcp_cntrl162.L1cache.m_demand_accesses   5.5556%
  • system.ruby.tcp_cntrl163.L1cache.m_demand_misses / system.ruby.tcp_cntrl163.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl164.L1cache.m_demand_misses / system.ruby.tcp_cntrl164.L1cache.m_demand_accesses   5.5556%
  • system.ruby.tcp_cntrl165.L1cache.m_demand_misses / system.ruby.tcp_cntrl165.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl166.L1cache.m_demand_misses / system.ruby.tcp_cntrl166.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl167.L1cache.m_demand_misses / system.ruby.tcp_cntrl167.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl168.L1cache.m_demand_misses / system.ruby.tcp_cntrl168.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl169.L1cache.m_demand_misses / system.ruby.tcp_cntrl169.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl17.L1cache.m_demand_misses / system.ruby.tcp_cntrl17.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl170.L1cache.m_demand_misses / system.ruby.tcp_cntrl170.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl171.L1cache.m_demand_misses / system.ruby.tcp_cntrl171.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl172.L1cache.m_demand_misses / system.ruby.tcp_cntrl172.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl173.L1cache.m_demand_misses / system.ruby.tcp_cntrl173.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl174.L1cache.m_demand_misses / system.ruby.tcp_cntrl174.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl175.L1cache.m_demand_misses / system.ruby.tcp_cntrl175.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl176.L1cache.m_demand_misses / system.ruby.tcp_cntrl176.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl177.L1cache.m_demand_misses / system.ruby.tcp_cntrl177.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl178.L1cache.m_demand_misses / system.ruby.tcp_cntrl178.L1cache.m_demand_accesses   5.5215%
  • system.ruby.tcp_cntrl179.L1cache.m_demand_misses / system.ruby.tcp_cntrl179.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses   5.5215%
  • system.ruby.tcp_cntrl180.L1cache.m_demand_misses / system.ruby.tcp_cntrl180.L1cache.m_demand_accesses   5.5901%
  • system.ruby.tcp_cntrl181.L1cache.m_demand_misses / system.ruby.tcp_cntrl181.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl182.L1cache.m_demand_misses / system.ruby.tcp_cntrl182.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl183.L1cache.m_demand_misses / system.ruby.tcp_cntrl183.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl184.L1cache.m_demand_misses / system.ruby.tcp_cntrl184.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl185.L1cache.m_demand_misses / system.ruby.tcp_cntrl185.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl186.L1cache.m_demand_misses / system.ruby.tcp_cntrl186.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl187.L1cache.m_demand_misses / system.ruby.tcp_cntrl187.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl188.L1cache.m_demand_misses / system.ruby.tcp_cntrl188.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl189.L1cache.m_demand_misses / system.ruby.tcp_cntrl189.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl190.L1cache.m_demand_misses / system.ruby.tcp_cntrl190.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl191.L1cache.m_demand_misses / system.ruby.tcp_cntrl191.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  85.1764%
  • system.ruby.tcp_cntrl20.L1cache.m_demand_misses / system.ruby.tcp_cntrl20.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl21.L1cache.m_demand_misses / system.ruby.tcp_cntrl21.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl22.L1cache.m_demand_misses / system.ruby.tcp_cntrl22.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl23.L1cache.m_demand_misses / system.ruby.tcp_cntrl23.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl24.L1cache.m_demand_misses / system.ruby.tcp_cntrl24.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl25.L1cache.m_demand_misses / system.ruby.tcp_cntrl25.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl26.L1cache.m_demand_misses / system.ruby.tcp_cntrl26.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl27.L1cache.m_demand_misses / system.ruby.tcp_cntrl27.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl28.L1cache.m_demand_misses / system.ruby.tcp_cntrl28.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl29.L1cache.m_demand_misses / system.ruby.tcp_cntrl29.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl30.L1cache.m_demand_misses / system.ruby.tcp_cntrl30.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl31.L1cache.m_demand_misses / system.ruby.tcp_cntrl31.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl32.L1cache.m_demand_misses / system.ruby.tcp_cntrl32.L1cache.m_demand_accesses   5.5556%
  • system.ruby.tcp_cntrl33.L1cache.m_demand_misses / system.ruby.tcp_cntrl33.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl34.L1cache.m_demand_misses / system.ruby.tcp_cntrl34.L1cache.m_demand_accesses   5.5556%
  • system.ruby.tcp_cntrl35.L1cache.m_demand_misses / system.ruby.tcp_cntrl35.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl36.L1cache.m_demand_misses / system.ruby.tcp_cntrl36.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl37.L1cache.m_demand_misses / system.ruby.tcp_cntrl37.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl38.L1cache.m_demand_misses / system.ruby.tcp_cntrl38.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl39.L1cache.m_demand_misses / system.ruby.tcp_cntrl39.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl40.L1cache.m_demand_misses / system.ruby.tcp_cntrl40.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl41.L1cache.m_demand_misses / system.ruby.tcp_cntrl41.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl42.L1cache.m_demand_misses / system.ruby.tcp_cntrl42.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl43.L1cache.m_demand_misses / system.ruby.tcp_cntrl43.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl44.L1cache.m_demand_misses / system.ruby.tcp_cntrl44.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl45.L1cache.m_demand_misses / system.ruby.tcp_cntrl45.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl46.L1cache.m_demand_misses / system.ruby.tcp_cntrl46.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl47.L1cache.m_demand_misses / system.ruby.tcp_cntrl47.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl48.L1cache.m_demand_misses / system.ruby.tcp_cntrl48.L1cache.m_demand_accesses   5.5215%
  • system.ruby.tcp_cntrl49.L1cache.m_demand_misses / system.ruby.tcp_cntrl49.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl50.L1cache.m_demand_misses / system.ruby.tcp_cntrl50.L1cache.m_demand_accesses   5.5901%
  • system.ruby.tcp_cntrl51.L1cache.m_demand_misses / system.ruby.tcp_cntrl51.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl52.L1cache.m_demand_misses / system.ruby.tcp_cntrl52.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl53.L1cache.m_demand_misses / system.ruby.tcp_cntrl53.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl54.L1cache.m_demand_misses / system.ruby.tcp_cntrl54.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl55.L1cache.m_demand_misses / system.ruby.tcp_cntrl55.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl56.L1cache.m_demand_misses / system.ruby.tcp_cntrl56.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl57.L1cache.m_demand_misses / system.ruby.tcp_cntrl57.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl58.L1cache.m_demand_misses / system.ruby.tcp_cntrl58.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl59.L1cache.m_demand_misses / system.ruby.tcp_cntrl59.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl60.L1cache.m_demand_misses / system.ruby.tcp_cntrl60.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl61.L1cache.m_demand_misses / system.ruby.tcp_cntrl61.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl62.L1cache.m_demand_misses / system.ruby.tcp_cntrl62.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl63.L1cache.m_demand_misses / system.ruby.tcp_cntrl63.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl64.L1cache.m_demand_misses / system.ruby.tcp_cntrl64.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl65.L1cache.m_demand_misses / system.ruby.tcp_cntrl65.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl66.L1cache.m_demand_misses / system.ruby.tcp_cntrl66.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl67.L1cache.m_demand_misses / system.ruby.tcp_cntrl67.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl68.L1cache.m_demand_misses / system.ruby.tcp_cntrl68.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl69.L1cache.m_demand_misses / system.ruby.tcp_cntrl69.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl70.L1cache.m_demand_misses / system.ruby.tcp_cntrl70.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl71.L1cache.m_demand_misses / system.ruby.tcp_cntrl71.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl72.L1cache.m_demand_misses / system.ruby.tcp_cntrl72.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl73.L1cache.m_demand_misses / system.ruby.tcp_cntrl73.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl74.L1cache.m_demand_misses / system.ruby.tcp_cntrl74.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl75.L1cache.m_demand_misses / system.ruby.tcp_cntrl75.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl76.L1cache.m_demand_misses / system.ruby.tcp_cntrl76.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl77.L1cache.m_demand_misses / system.ruby.tcp_cntrl77.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl78.L1cache.m_demand_misses / system.ruby.tcp_cntrl78.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl79.L1cache.m_demand_misses / system.ruby.tcp_cntrl79.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl8.L1cache.m_demand_misses / system.ruby.tcp_cntrl8.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl80.L1cache.m_demand_misses / system.ruby.tcp_cntrl80.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl81.L1cache.m_demand_misses / system.ruby.tcp_cntrl81.L1cache.m_demand_accesses   5.5901%
  • system.ruby.tcp_cntrl82.L1cache.m_demand_misses / system.ruby.tcp_cntrl82.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl83.L1cache.m_demand_misses / system.ruby.tcp_cntrl83.L1cache.m_demand_accesses   5.5215%
  • system.ruby.tcp_cntrl84.L1cache.m_demand_misses / system.ruby.tcp_cntrl84.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl85.L1cache.m_demand_misses / system.ruby.tcp_cntrl85.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl86.L1cache.m_demand_misses / system.ruby.tcp_cntrl86.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl87.L1cache.m_demand_misses / system.ruby.tcp_cntrl87.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl88.L1cache.m_demand_misses / system.ruby.tcp_cntrl88.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl89.L1cache.m_demand_misses / system.ruby.tcp_cntrl89.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl9.L1cache.m_demand_misses / system.ruby.tcp_cntrl9.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl90.L1cache.m_demand_misses / system.ruby.tcp_cntrl90.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl91.L1cache.m_demand_misses / system.ruby.tcp_cntrl91.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl92.L1cache.m_demand_misses / system.ruby.tcp_cntrl92.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl93.L1cache.m_demand_misses / system.ruby.tcp_cntrl93.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl94.L1cache.m_demand_misses / system.ruby.tcp_cntrl94.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl95.L1cache.m_demand_misses / system.ruby.tcp_cntrl95.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl96.L1cache.m_demand_misses / system.ruby.tcp_cntrl96.L1cache.m_demand_accesses   5.4878%
  • system.ruby.tcp_cntrl97.L1cache.m_demand_misses / system.ruby.tcp_cntrl97.L1cache.m_demand_accesses   5.5556%
  • system.ruby.tcp_cntrl98.L1cache.m_demand_misses / system.ruby.tcp_cntrl98.L1cache.m_demand_accesses   5.6250%
  • system.ruby.tcp_cntrl99.L1cache.m_demand_misses / system.ruby.tcp_cntrl99.L1cache.m_demand_accesses   5.5556%

Functional Tests (offline evidence)
------------------------------------------------------------------------------------------------
• 资源实例化        PASS
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=48, cu=192, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.027592
  evidence: stats.txt: system.cpu1.ipc=0.000085
  evidence: stats.txt: system.cpu10.ipc=0.001119
• 系统初始化        PASS
  notes: 检测到进入执行阶段迹象
  evidence: simout/simerr:562: Exiting because  exiting with last active thread context
• 功能执行         PASS
  notes: 检测到正常退出迹象
  evidence: simout/simerr:562: Exiting because  exiting with last active thread context
• 结果校验         PASS
  notes: 检测到 correctness/返回状态成功信号
  evidence: simout/simerr:559: PASS
• 异常检查         PASS
  notes: 未命中严重异常关键字
  evidence: (none)
