
====================================================================================================================================================
  Analyze Summary
====================================================================================================================================================
run_dir            : /home/orange/gem5-demo/tests/testing-results/rodinia-gaussian-args4.7.14
latency_files      : cpu=328 gpu=176
ldst_weighted_mean : 80.655264
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : ~/gem5-demo/tests/testing-results/rodinia-gaussian-args4.7.14/analyze.md
output_json        : ~/gem5-demo/tests/testing-results/rodinia-gaussian-args4.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 328
total samples: 52,940,695
mean/min/max: 22.14 / 1 / 45836
slow buckets: >100=5,754,553  >500=23,238  >1000=10,157  >5000=3,543
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH            41,613,783       13.68         1     25239
LD                 7,256,002       59.85         1     36640
Locked_RMW_Read        70,248       57.58         1     21717
Locked_RMW_Write        70,248        1.00         1        21
RMW_Read              91,682       44.17         1      6519
ST                 3,838,732       41.70         1     45836

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 176
total samples: 701,520
mean/min/max: 508.97 / 1 / 4950
slow buckets: >100=423,950  >500=284,408  >1000=149,342  >5000=0
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
LD                   524,560      680.19         1      4950
ST                   176,960        1.43         1       733

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 80.655264
samples(cpu/gpu/total): 11094734/701520/11796254

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  28.5414%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  40.3198%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses   7.6114%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  58.3946%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses  28.7620%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses  49.5753%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   9.3143%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  57.2668%
  • system.ruby.cp_cntrl10.L1D0cache.m_demand_misses / system.ruby.cp_cntrl10.L1D0cache.m_demand_accesses  42.8365%
  • system.ruby.cp_cntrl10.L1D1cache.m_demand_misses / system.ruby.cp_cntrl10.L1D1cache.m_demand_accesses  40.0362%
  • system.ruby.cp_cntrl10.L1Icache.m_demand_misses / system.ruby.cp_cntrl10.L1Icache.m_demand_accesses   2.5320%
  • system.ruby.cp_cntrl10.L2cache.m_demand_misses / system.ruby.cp_cntrl10.L2cache.m_demand_accesses  58.9686%
  • system.ruby.cp_cntrl11.L1D0cache.m_demand_misses / system.ruby.cp_cntrl11.L1D0cache.m_demand_accesses  50.8880%
  • system.ruby.cp_cntrl11.L1D1cache.m_demand_misses / system.ruby.cp_cntrl11.L1D1cache.m_demand_accesses  46.7029%
  • system.ruby.cp_cntrl11.L1Icache.m_demand_misses / system.ruby.cp_cntrl11.L1Icache.m_demand_accesses   2.5963%
  • system.ruby.cp_cntrl11.L2cache.m_demand_misses / system.ruby.cp_cntrl11.L2cache.m_demand_accesses  61.1842%
  • system.ruby.cp_cntrl12.L1D0cache.m_demand_misses / system.ruby.cp_cntrl12.L1D0cache.m_demand_accesses  44.4934%
  • system.ruby.cp_cntrl12.L1D1cache.m_demand_misses / system.ruby.cp_cntrl12.L1D1cache.m_demand_accesses  41.8728%
  • system.ruby.cp_cntrl12.L1Icache.m_demand_misses / system.ruby.cp_cntrl12.L1Icache.m_demand_accesses   3.4663%
  • system.ruby.cp_cntrl12.L2cache.m_demand_misses / system.ruby.cp_cntrl12.L2cache.m_demand_accesses  63.3688%
  • system.ruby.cp_cntrl13.L1D0cache.m_demand_misses / system.ruby.cp_cntrl13.L1D0cache.m_demand_accesses  44.7972%
  • system.ruby.cp_cntrl13.L1D1cache.m_demand_misses / system.ruby.cp_cntrl13.L1D1cache.m_demand_accesses  42.6172%
  • system.ruby.cp_cntrl13.L1Icache.m_demand_misses / system.ruby.cp_cntrl13.L1Icache.m_demand_accesses   3.0914%
  • system.ruby.cp_cntrl13.L2cache.m_demand_misses / system.ruby.cp_cntrl13.L2cache.m_demand_accesses  61.6136%
  • system.ruby.cp_cntrl14.L1D0cache.m_demand_misses / system.ruby.cp_cntrl14.L1D0cache.m_demand_accesses  45.5986%
  • system.ruby.cp_cntrl14.L1D1cache.m_demand_misses / system.ruby.cp_cntrl14.L1D1cache.m_demand_accesses  42.0705%
  • system.ruby.cp_cntrl14.L1Icache.m_demand_misses / system.ruby.cp_cntrl14.L1Icache.m_demand_accesses   3.7812%
  • system.ruby.cp_cntrl14.L2cache.m_demand_misses / system.ruby.cp_cntrl14.L2cache.m_demand_accesses  63.8855%
  • system.ruby.cp_cntrl15.L1D0cache.m_demand_misses / system.ruby.cp_cntrl15.L1D0cache.m_demand_accesses  43.5031%
  • system.ruby.cp_cntrl15.L1D1cache.m_demand_misses / system.ruby.cp_cntrl15.L1D1cache.m_demand_accesses  41.0132%
  • system.ruby.cp_cntrl15.L1Icache.m_demand_misses / system.ruby.cp_cntrl15.L1Icache.m_demand_accesses   2.5087%
  • system.ruby.cp_cntrl15.L2cache.m_demand_misses / system.ruby.cp_cntrl15.L2cache.m_demand_accesses  59.8925%
  • system.ruby.cp_cntrl16.L1D0cache.m_demand_misses / system.ruby.cp_cntrl16.L1D0cache.m_demand_accesses  49.4200%
  • system.ruby.cp_cntrl16.L1D1cache.m_demand_misses / system.ruby.cp_cntrl16.L1D1cache.m_demand_accesses  46.8580%
  • system.ruby.cp_cntrl16.L1Icache.m_demand_misses / system.ruby.cp_cntrl16.L1Icache.m_demand_accesses   2.7050%
  • system.ruby.cp_cntrl16.L2cache.m_demand_misses / system.ruby.cp_cntrl16.L2cache.m_demand_accesses  61.4151%
  • system.ruby.cp_cntrl17.L1D0cache.m_demand_misses / system.ruby.cp_cntrl17.L1D0cache.m_demand_accesses  49.6503%
  • system.ruby.cp_cntrl17.L1D1cache.m_demand_misses / system.ruby.cp_cntrl17.L1D1cache.m_demand_accesses  47.8699%
  • system.ruby.cp_cntrl17.L1Icache.m_demand_misses / system.ruby.cp_cntrl17.L1Icache.m_demand_accesses   2.6405%
  • system.ruby.cp_cntrl17.L2cache.m_demand_misses / system.ruby.cp_cntrl17.L2cache.m_demand_accesses  60.5177%
  • system.ruby.cp_cntrl18.L1D0cache.m_demand_misses / system.ruby.cp_cntrl18.L1D0cache.m_demand_accesses  43.8470%
  • system.ruby.cp_cntrl18.L1D1cache.m_demand_misses / system.ruby.cp_cntrl18.L1D1cache.m_demand_accesses  41.2297%
  • system.ruby.cp_cntrl18.L1Icache.m_demand_misses / system.ruby.cp_cntrl18.L1Icache.m_demand_accesses   3.4320%
  • system.ruby.cp_cntrl18.L2cache.m_demand_misses / system.ruby.cp_cntrl18.L2cache.m_demand_accesses  62.9353%
  • system.ruby.cp_cntrl19.L1D0cache.m_demand_misses / system.ruby.cp_cntrl19.L1D0cache.m_demand_accesses  50.0387%
  • system.ruby.cp_cntrl19.L1D1cache.m_demand_misses / system.ruby.cp_cntrl19.L1D1cache.m_demand_accesses  47.1727%
  • system.ruby.cp_cntrl19.L1Icache.m_demand_misses / system.ruby.cp_cntrl19.L1Icache.m_demand_accesses   2.7009%
  • system.ruby.cp_cntrl19.L2cache.m_demand_misses / system.ruby.cp_cntrl19.L2cache.m_demand_accesses  61.8405%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses  52.1301%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses  46.0170%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   2.7734%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses  60.3644%
  • system.ruby.cp_cntrl20.L1D0cache.m_demand_misses / system.ruby.cp_cntrl20.L1D0cache.m_demand_accesses  43.5356%
  • system.ruby.cp_cntrl20.L1D1cache.m_demand_misses / system.ruby.cp_cntrl20.L1D1cache.m_demand_accesses  41.2412%
  • system.ruby.cp_cntrl20.L1Icache.m_demand_misses / system.ruby.cp_cntrl20.L1Icache.m_demand_accesses   2.4629%
  • system.ruby.cp_cntrl20.L2cache.m_demand_misses / system.ruby.cp_cntrl20.L2cache.m_demand_accesses  59.0433%
  • system.ruby.cp_cntrl21.L1D0cache.m_demand_misses / system.ruby.cp_cntrl21.L1D0cache.m_demand_accesses  51.7375%
  • system.ruby.cp_cntrl21.L1D1cache.m_demand_misses / system.ruby.cp_cntrl21.L1D1cache.m_demand_accesses  49.8838%
  • system.ruby.cp_cntrl21.L1Icache.m_demand_misses / system.ruby.cp_cntrl21.L1Icache.m_demand_accesses   2.4876%
  • system.ruby.cp_cntrl21.L2cache.m_demand_misses / system.ruby.cp_cntrl21.L2cache.m_demand_accesses  60.6011%
  • system.ruby.cp_cntrl22.L1D0cache.m_demand_misses / system.ruby.cp_cntrl22.L1D0cache.m_demand_accesses  46.4225%
  • system.ruby.cp_cntrl22.L1D1cache.m_demand_misses / system.ruby.cp_cntrl22.L1D1cache.m_demand_accesses  43.9505%
  • system.ruby.cp_cntrl22.L1Icache.m_demand_misses / system.ruby.cp_cntrl22.L1Icache.m_demand_accesses   2.5891%
  • system.ruby.cp_cntrl22.L2cache.m_demand_misses / system.ruby.cp_cntrl22.L2cache.m_demand_accesses  61.2621%
  • system.ruby.cp_cntrl23.L1D0cache.m_demand_misses / system.ruby.cp_cntrl23.L1D0cache.m_demand_accesses  50.6513%
  • system.ruby.cp_cntrl23.L1D1cache.m_demand_misses / system.ruby.cp_cntrl23.L1D1cache.m_demand_accesses  46.1004%
  • system.ruby.cp_cntrl23.L1Icache.m_demand_misses / system.ruby.cp_cntrl23.L1Icache.m_demand_accesses   2.4454%
  • system.ruby.cp_cntrl23.L2cache.m_demand_misses / system.ruby.cp_cntrl23.L2cache.m_demand_accesses  61.5897%
  • system.ruby.cp_cntrl24.L1D0cache.m_demand_misses / system.ruby.cp_cntrl24.L1D0cache.m_demand_accesses  46.0845%
  • system.ruby.cp_cntrl24.L1D1cache.m_demand_misses / system.ruby.cp_cntrl24.L1D1cache.m_demand_accesses  42.7042%
  • system.ruby.cp_cntrl24.L1Icache.m_demand_misses / system.ruby.cp_cntrl24.L1Icache.m_demand_accesses   2.5786%
  • system.ruby.cp_cntrl24.L2cache.m_demand_misses / system.ruby.cp_cntrl24.L2cache.m_demand_accesses  60.2280%
  • system.ruby.cp_cntrl25.L1D0cache.m_demand_misses / system.ruby.cp_cntrl25.L1D0cache.m_demand_accesses  52.2851%
  • system.ruby.cp_cntrl25.L1D1cache.m_demand_misses / system.ruby.cp_cntrl25.L1D1cache.m_demand_accesses  47.6448%
  • system.ruby.cp_cntrl25.L1Icache.m_demand_misses / system.ruby.cp_cntrl25.L1Icache.m_demand_accesses   2.6586%
  • system.ruby.cp_cntrl25.L2cache.m_demand_misses / system.ruby.cp_cntrl25.L2cache.m_demand_accesses  62.2474%
  • system.ruby.cp_cntrl26.L1D0cache.m_demand_misses / system.ruby.cp_cntrl26.L1D0cache.m_demand_accesses  51.8231%
  • system.ruby.cp_cntrl26.L1D1cache.m_demand_misses / system.ruby.cp_cntrl26.L1D1cache.m_demand_accesses  43.1959%
  • system.ruby.cp_cntrl26.L1Icache.m_demand_misses / system.ruby.cp_cntrl26.L1Icache.m_demand_accesses   3.0298%
  • system.ruby.cp_cntrl26.L2cache.m_demand_misses / system.ruby.cp_cntrl26.L2cache.m_demand_accesses  62.3153%
  • system.ruby.cp_cntrl27.L1D0cache.m_demand_misses / system.ruby.cp_cntrl27.L1D0cache.m_demand_accesses  49.9611%
  • system.ruby.cp_cntrl27.L1D1cache.m_demand_misses / system.ruby.cp_cntrl27.L1D1cache.m_demand_accesses  47.3563%
  • system.ruby.cp_cntrl27.L1Icache.m_demand_misses / system.ruby.cp_cntrl27.L1Icache.m_demand_accesses   2.7311%
  • system.ruby.cp_cntrl27.L2cache.m_demand_misses / system.ruby.cp_cntrl27.L2cache.m_demand_accesses  62.1224%
  • system.ruby.cp_cntrl28.L1D0cache.m_demand_misses / system.ruby.cp_cntrl28.L1D0cache.m_demand_accesses  45.0028%
  • system.ruby.cp_cntrl28.L1D1cache.m_demand_misses / system.ruby.cp_cntrl28.L1D1cache.m_demand_accesses  42.8972%
  • system.ruby.cp_cntrl28.L1Icache.m_demand_misses / system.ruby.cp_cntrl28.L1Icache.m_demand_accesses   2.4415%
  • system.ruby.cp_cntrl28.L2cache.m_demand_misses / system.ruby.cp_cntrl28.L2cache.m_demand_accesses  60.4312%
  • system.ruby.cp_cntrl29.L1D0cache.m_demand_misses / system.ruby.cp_cntrl29.L1D0cache.m_demand_accesses  52.3589%
  • system.ruby.cp_cntrl29.L1D1cache.m_demand_misses / system.ruby.cp_cntrl29.L1D1cache.m_demand_accesses  48.1139%
  • system.ruby.cp_cntrl29.L1Icache.m_demand_misses / system.ruby.cp_cntrl29.L1Icache.m_demand_accesses   2.6144%
  • system.ruby.cp_cntrl29.L2cache.m_demand_misses / system.ruby.cp_cntrl29.L2cache.m_demand_accesses  61.6970%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses  50.5019%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses  46.2548%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   2.6163%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses  61.0630%
  • system.ruby.cp_cntrl30.L1D0cache.m_demand_misses / system.ruby.cp_cntrl30.L1D0cache.m_demand_accesses  45.8685%
  • system.ruby.cp_cntrl30.L1D1cache.m_demand_misses / system.ruby.cp_cntrl30.L1D1cache.m_demand_accesses  43.6899%
  • system.ruby.cp_cntrl30.L1Icache.m_demand_misses / system.ruby.cp_cntrl30.L1Icache.m_demand_accesses   2.7262%
  • system.ruby.cp_cntrl30.L2cache.m_demand_misses / system.ruby.cp_cntrl30.L2cache.m_demand_accesses  60.9788%
  • system.ruby.cp_cntrl31.L1D0cache.m_demand_misses / system.ruby.cp_cntrl31.L1D0cache.m_demand_accesses  51.0473%
  • system.ruby.cp_cntrl31.L1D1cache.m_demand_misses / system.ruby.cp_cntrl31.L1D1cache.m_demand_accesses  45.3354%
  • system.ruby.cp_cntrl31.L1Icache.m_demand_misses / system.ruby.cp_cntrl31.L1Icache.m_demand_accesses   2.5963%
  • system.ruby.cp_cntrl31.L2cache.m_demand_misses / system.ruby.cp_cntrl31.L2cache.m_demand_accesses  61.8317%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses  50.8853%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses  45.9860%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   2.7311%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses  62.2186%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses  51.2006%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses  43.2371%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   2.8158%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses  60.4137%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses  51.8890%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses  46.2606%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   2.6506%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses  62.1732%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses  51.4242%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses  42.6960%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   3.0692%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses  62.2050%
  • system.ruby.cp_cntrl8.L1D0cache.m_demand_misses / system.ruby.cp_cntrl8.L1D0cache.m_demand_accesses  45.6804%
  • system.ruby.cp_cntrl8.L1D1cache.m_demand_misses / system.ruby.cp_cntrl8.L1D1cache.m_demand_accesses  43.1362%
  • system.ruby.cp_cntrl8.L1Icache.m_demand_misses / system.ruby.cp_cntrl8.L1Icache.m_demand_accesses   3.2834%
  • system.ruby.cp_cntrl8.L2cache.m_demand_misses / system.ruby.cp_cntrl8.L2cache.m_demand_accesses  62.7414%
  • system.ruby.cp_cntrl9.L1D0cache.m_demand_misses / system.ruby.cp_cntrl9.L1D0cache.m_demand_accesses  43.6351%
  • system.ruby.cp_cntrl9.L1D1cache.m_demand_misses / system.ruby.cp_cntrl9.L1D1cache.m_demand_accesses  40.8812%
  • system.ruby.cp_cntrl9.L1Icache.m_demand_misses / system.ruby.cp_cntrl9.L1Icache.m_demand_accesses   3.1588%
  • system.ruby.cp_cntrl9.L2cache.m_demand_misses / system.ruby.cp_cntrl9.L2cache.m_demand_accesses  62.1094%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   2.2044%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  38.9163%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses  37.5743%
  • system.ruby.scalar_cntrl10.L1cache.m_demand_misses / system.ruby.scalar_cntrl10.L1cache.m_demand_accesses  48.9922%
  • system.ruby.scalar_cntrl11.L1cache.m_demand_misses / system.ruby.scalar_cntrl11.L1cache.m_demand_accesses  48.1707%
  • system.ruby.scalar_cntrl12.L1cache.m_demand_misses / system.ruby.scalar_cntrl12.L1cache.m_demand_accesses  56.7325%
  • system.ruby.scalar_cntrl13.L1cache.m_demand_misses / system.ruby.scalar_cntrl13.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl14.L1cache.m_demand_misses / system.ruby.scalar_cntrl14.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl15.L1cache.m_demand_misses / system.ruby.scalar_cntrl15.L1cache.m_demand_accesses  56.7325%
  • system.ruby.scalar_cntrl16.L1cache.m_demand_misses / system.ruby.scalar_cntrl16.L1cache.m_demand_accesses  55.5360%
  • system.ruby.scalar_cntrl17.L1cache.m_demand_misses / system.ruby.scalar_cntrl17.L1cache.m_demand_accesses  57.1429%
  • system.ruby.scalar_cntrl18.L1cache.m_demand_misses / system.ruby.scalar_cntrl18.L1cache.m_demand_accesses  58.8454%
  • system.ruby.scalar_cntrl19.L1cache.m_demand_misses / system.ruby.scalar_cntrl19.L1cache.m_demand_accesses  60.7692%
  • system.ruby.scalar_cntrl2.L1cache.m_demand_misses / system.ruby.scalar_cntrl2.L1cache.m_demand_accesses  40.3576%
  • system.ruby.scalar_cntrl20.L1cache.m_demand_misses / system.ruby.scalar_cntrl20.L1cache.m_demand_accesses  57.1429%
  • system.ruby.scalar_cntrl21.L1cache.m_demand_misses / system.ruby.scalar_cntrl21.L1cache.m_demand_accesses  55.9292%
  • system.ruby.scalar_cntrl22.L1cache.m_demand_misses / system.ruby.scalar_cntrl22.L1cache.m_demand_accesses  57.5592%
  • system.ruby.scalar_cntrl23.L1cache.m_demand_misses / system.ruby.scalar_cntrl23.L1cache.m_demand_accesses  59.2871%
  • system.ruby.scalar_cntrl24.L1cache.m_demand_misses / system.ruby.scalar_cntrl24.L1cache.m_demand_accesses  61.1219%
  • system.ruby.scalar_cntrl25.L1cache.m_demand_misses / system.ruby.scalar_cntrl25.L1cache.m_demand_accesses  57.5592%
  • system.ruby.scalar_cntrl26.L1cache.m_demand_misses / system.ruby.scalar_cntrl26.L1cache.m_demand_accesses  56.6308%
  • system.ruby.scalar_cntrl27.L1cache.m_demand_misses / system.ruby.scalar_cntrl27.L1cache.m_demand_accesses  57.9817%
  • system.ruby.scalar_cntrl28.L1cache.m_demand_misses / system.ruby.scalar_cntrl28.L1cache.m_demand_accesses  59.7353%
  • system.ruby.scalar_cntrl29.L1cache.m_demand_misses / system.ruby.scalar_cntrl29.L1cache.m_demand_accesses  61.5984%
  • system.ruby.scalar_cntrl3.L1cache.m_demand_misses / system.ruby.scalar_cntrl3.L1cache.m_demand_accesses  44.4444%
  • system.ruby.scalar_cntrl30.L1cache.m_demand_misses / system.ruby.scalar_cntrl30.L1cache.m_demand_accesses  57.9817%
  • system.ruby.scalar_cntrl31.L1cache.m_demand_misses / system.ruby.scalar_cntrl31.L1cache.m_demand_accesses  57.4545%
  • system.ruby.scalar_cntrl32.L1cache.m_demand_misses / system.ruby.scalar_cntrl32.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl33.L1cache.m_demand_misses / system.ruby.scalar_cntrl33.L1cache.m_demand_accesses  60.1905%
  • system.ruby.scalar_cntrl34.L1cache.m_demand_misses / system.ruby.scalar_cntrl34.L1cache.m_demand_accesses  62.0825%
  • system.ruby.scalar_cntrl35.L1cache.m_demand_misses / system.ruby.scalar_cntrl35.L1cache.m_demand_accesses  58.4104%
  • system.ruby.scalar_cntrl36.L1cache.m_demand_misses / system.ruby.scalar_cntrl36.L1cache.m_demand_accesses  58.3026%
  • system.ruby.scalar_cntrl37.L1cache.m_demand_misses / system.ruby.scalar_cntrl37.L1cache.m_demand_accesses  58.8454%
  • system.ruby.scalar_cntrl38.L1cache.m_demand_misses / system.ruby.scalar_cntrl38.L1cache.m_demand_accesses  60.6526%
  • system.ruby.scalar_cntrl39.L1cache.m_demand_misses / system.ruby.scalar_cntrl39.L1cache.m_demand_accesses  62.5743%
  • system.ruby.scalar_cntrl4.L1cache.m_demand_misses / system.ruby.scalar_cntrl4.L1cache.m_demand_accesses  48.9164%
  • system.ruby.scalar_cntrl40.L1cache.m_demand_misses / system.ruby.scalar_cntrl40.L1cache.m_demand_accesses  58.8454%
  • system.ruby.scalar_cntrl41.L1cache.m_demand_misses / system.ruby.scalar_cntrl41.L1cache.m_demand_accesses  59.1760%
  • system.ruby.scalar_cntrl42.L1cache.m_demand_misses / system.ruby.scalar_cntrl42.L1cache.m_demand_accesses  59.2871%
  • system.ruby.scalar_cntrl43.L1cache.m_demand_misses / system.ruby.scalar_cntrl43.L1cache.m_demand_accesses  61.1219%
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses  48.0974%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses  47.5904%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses  49.0683%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses  50.3185%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses  52.3179%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses  80.4071%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses  76.3872%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses  73.7033%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses  70.5314%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses  94.2004%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses  85.6899%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses  81.1980%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses  75.4408%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses  87.9518%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses  93.7063%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses  86.9027%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses  82.1549%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses  78.9973%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses  76.4323%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses  86.0088%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses  90.6937%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses  89.8711%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses  82.3024%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses  76.6667%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses  86.4662%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses  89.4825%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses  92.0755%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses  83.2442%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses  81.4599%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses  78.5216%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses  85.0453%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses  89.1847%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses  94.2085%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses  84.1035%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses  76.4216%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses  84.2508%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses  86.8720%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses  92.9524%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses  86.1868%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses  81.7886%
  • system.ruby.sqc_cntrl40.L1cache.m_demand_misses / system.ruby.sqc_cntrl40.L1cache.m_demand_accesses  77.1102%
  • system.ruby.sqc_cntrl41.L1cache.m_demand_misses / system.ruby.sqc_cntrl41.L1cache.m_demand_accesses  85.0158%
  • system.ruby.sqc_cntrl42.L1cache.m_demand_misses / system.ruby.sqc_cntrl42.L1cache.m_demand_accesses  86.0353%
  • system.ruby.sqc_cntrl43.L1cache.m_demand_misses / system.ruby.sqc_cntrl43.L1cache.m_demand_accesses  90.7063%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses  72.1900%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses  67.9860%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses  70.6192%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses  71.7270%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses  82.5719%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses   5.5877%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  88.4203%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  59.4176%
  • system.ruby.tcp_cntrl10.L1cache.m_demand_misses / system.ruby.tcp_cntrl10.L1cache.m_demand_accesses  61.2758%
  • system.ruby.tcp_cntrl100.L1cache.m_demand_misses / system.ruby.tcp_cntrl100.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl101.L1cache.m_demand_misses / system.ruby.tcp_cntrl101.L1cache.m_demand_accesses  68.1087%
  • system.ruby.tcp_cntrl102.L1cache.m_demand_misses / system.ruby.tcp_cntrl102.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl103.L1cache.m_demand_misses / system.ruby.tcp_cntrl103.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl104.L1cache.m_demand_misses / system.ruby.tcp_cntrl104.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl105.L1cache.m_demand_misses / system.ruby.tcp_cntrl105.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl106.L1cache.m_demand_misses / system.ruby.tcp_cntrl106.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl107.L1cache.m_demand_misses / system.ruby.tcp_cntrl107.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl108.L1cache.m_demand_misses / system.ruby.tcp_cntrl108.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl109.L1cache.m_demand_misses / system.ruby.tcp_cntrl109.L1cache.m_demand_accesses  68.0467%
  • system.ruby.tcp_cntrl11.L1cache.m_demand_misses / system.ruby.tcp_cntrl11.L1cache.m_demand_accesses  61.6168%
  • system.ruby.tcp_cntrl110.L1cache.m_demand_misses / system.ruby.tcp_cntrl110.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl111.L1cache.m_demand_misses / system.ruby.tcp_cntrl111.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl112.L1cache.m_demand_misses / system.ruby.tcp_cntrl112.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl113.L1cache.m_demand_misses / system.ruby.tcp_cntrl113.L1cache.m_demand_accesses  68.1754%
  • system.ruby.tcp_cntrl114.L1cache.m_demand_misses / system.ruby.tcp_cntrl114.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl115.L1cache.m_demand_misses / system.ruby.tcp_cntrl115.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl116.L1cache.m_demand_misses / system.ruby.tcp_cntrl116.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl117.L1cache.m_demand_misses / system.ruby.tcp_cntrl117.L1cache.m_demand_accesses  68.4322%
  • system.ruby.tcp_cntrl118.L1cache.m_demand_misses / system.ruby.tcp_cntrl118.L1cache.m_demand_accesses  68.5039%
  • system.ruby.tcp_cntrl119.L1cache.m_demand_misses / system.ruby.tcp_cntrl119.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl12.L1cache.m_demand_misses / system.ruby.tcp_cntrl12.L1cache.m_demand_accesses  62.1800%
  • system.ruby.tcp_cntrl120.L1cache.m_demand_misses / system.ruby.tcp_cntrl120.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl121.L1cache.m_demand_misses / system.ruby.tcp_cntrl121.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl122.L1cache.m_demand_misses / system.ruby.tcp_cntrl122.L1cache.m_demand_accesses  67.9775%
  • system.ruby.tcp_cntrl123.L1cache.m_demand_misses / system.ruby.tcp_cntrl123.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl124.L1cache.m_demand_misses / system.ruby.tcp_cntrl124.L1cache.m_demand_accesses  67.8832%
  • system.ruby.tcp_cntrl125.L1cache.m_demand_misses / system.ruby.tcp_cntrl125.L1cache.m_demand_accesses  67.8832%
  • system.ruby.tcp_cntrl126.L1cache.m_demand_misses / system.ruby.tcp_cntrl126.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl127.L1cache.m_demand_misses / system.ruby.tcp_cntrl127.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl128.L1cache.m_demand_misses / system.ruby.tcp_cntrl128.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl129.L1cache.m_demand_misses / system.ruby.tcp_cntrl129.L1cache.m_demand_accesses  67.6568%
  • system.ruby.tcp_cntrl13.L1cache.m_demand_misses / system.ruby.tcp_cntrl13.L1cache.m_demand_accesses  62.5000%
  • system.ruby.tcp_cntrl130.L1cache.m_demand_misses / system.ruby.tcp_cntrl130.L1cache.m_demand_accesses  67.8998%
  • system.ruby.tcp_cntrl131.L1cache.m_demand_misses / system.ruby.tcp_cntrl131.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl132.L1cache.m_demand_misses / system.ruby.tcp_cntrl132.L1cache.m_demand_accesses  67.7686%
  • system.ruby.tcp_cntrl133.L1cache.m_demand_misses / system.ruby.tcp_cntrl133.L1cache.m_demand_accesses  67.6558%
  • system.ruby.tcp_cntrl134.L1cache.m_demand_misses / system.ruby.tcp_cntrl134.L1cache.m_demand_accesses  67.9934%
  • system.ruby.tcp_cntrl135.L1cache.m_demand_misses / system.ruby.tcp_cntrl135.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl136.L1cache.m_demand_misses / system.ruby.tcp_cntrl136.L1cache.m_demand_accesses  67.8208%
  • system.ruby.tcp_cntrl137.L1cache.m_demand_misses / system.ruby.tcp_cntrl137.L1cache.m_demand_accesses  67.6538%
  • system.ruby.tcp_cntrl138.L1cache.m_demand_misses / system.ruby.tcp_cntrl138.L1cache.m_demand_accesses  68.2065%
  • system.ruby.tcp_cntrl139.L1cache.m_demand_misses / system.ruby.tcp_cntrl139.L1cache.m_demand_accesses  68.2310%
  • system.ruby.tcp_cntrl14.L1cache.m_demand_misses / system.ruby.tcp_cntrl14.L1cache.m_demand_accesses  62.7240%
  • system.ruby.tcp_cntrl140.L1cache.m_demand_misses / system.ruby.tcp_cntrl140.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl141.L1cache.m_demand_misses / system.ruby.tcp_cntrl141.L1cache.m_demand_accesses  67.6568%
  • system.ruby.tcp_cntrl142.L1cache.m_demand_misses / system.ruby.tcp_cntrl142.L1cache.m_demand_accesses  67.5613%
  • system.ruby.tcp_cntrl143.L1cache.m_demand_misses / system.ruby.tcp_cntrl143.L1cache.m_demand_accesses  67.8117%
  • system.ruby.tcp_cntrl144.L1cache.m_demand_misses / system.ruby.tcp_cntrl144.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl145.L1cache.m_demand_misses / system.ruby.tcp_cntrl145.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl146.L1cache.m_demand_misses / system.ruby.tcp_cntrl146.L1cache.m_demand_accesses  68.0829%
  • system.ruby.tcp_cntrl147.L1cache.m_demand_misses / system.ruby.tcp_cntrl147.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl148.L1cache.m_demand_misses / system.ruby.tcp_cntrl148.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl149.L1cache.m_demand_misses / system.ruby.tcp_cntrl149.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl15.L1cache.m_demand_misses / system.ruby.tcp_cntrl15.L1cache.m_demand_accesses  63.0081%
  • system.ruby.tcp_cntrl150.L1cache.m_demand_misses / system.ruby.tcp_cntrl150.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl151.L1cache.m_demand_misses / system.ruby.tcp_cntrl151.L1cache.m_demand_accesses  68.1754%
  • system.ruby.tcp_cntrl152.L1cache.m_demand_misses / system.ruby.tcp_cntrl152.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl153.L1cache.m_demand_misses / system.ruby.tcp_cntrl153.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl154.L1cache.m_demand_misses / system.ruby.tcp_cntrl154.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl155.L1cache.m_demand_misses / system.ruby.tcp_cntrl155.L1cache.m_demand_accesses  68.4322%
  • system.ruby.tcp_cntrl156.L1cache.m_demand_misses / system.ruby.tcp_cntrl156.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl157.L1cache.m_demand_misses / system.ruby.tcp_cntrl157.L1cache.m_demand_accesses  68.3333%
  • system.ruby.tcp_cntrl158.L1cache.m_demand_misses / system.ruby.tcp_cntrl158.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl159.L1cache.m_demand_misses / system.ruby.tcp_cntrl159.L1cache.m_demand_accesses  69.1983%
  • system.ruby.tcp_cntrl16.L1cache.m_demand_misses / system.ruby.tcp_cntrl16.L1cache.m_demand_accesses  63.7243%
  • system.ruby.tcp_cntrl160.L1cache.m_demand_misses / system.ruby.tcp_cntrl160.L1cache.m_demand_accesses  68.4211%
  • system.ruby.tcp_cntrl161.L1cache.m_demand_misses / system.ruby.tcp_cntrl161.L1cache.m_demand_accesses  68.3686%
  • system.ruby.tcp_cntrl162.L1cache.m_demand_misses / system.ruby.tcp_cntrl162.L1cache.m_demand_accesses  68.3089%
  • system.ruby.tcp_cntrl163.L1cache.m_demand_misses / system.ruby.tcp_cntrl163.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl164.L1cache.m_demand_misses / system.ruby.tcp_cntrl164.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl165.L1cache.m_demand_misses / system.ruby.tcp_cntrl165.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl166.L1cache.m_demand_misses / system.ruby.tcp_cntrl166.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl167.L1cache.m_demand_misses / system.ruby.tcp_cntrl167.L1cache.m_demand_accesses  68.3453%
  • system.ruby.tcp_cntrl168.L1cache.m_demand_misses / system.ruby.tcp_cntrl168.L1cache.m_demand_accesses  68.3686%
  • system.ruby.tcp_cntrl169.L1cache.m_demand_misses / system.ruby.tcp_cntrl169.L1cache.m_demand_accesses  68.3089%
  • system.ruby.tcp_cntrl17.L1cache.m_demand_misses / system.ruby.tcp_cntrl17.L1cache.m_demand_accesses  64.6707%
  • system.ruby.tcp_cntrl170.L1cache.m_demand_misses / system.ruby.tcp_cntrl170.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl171.L1cache.m_demand_misses / system.ruby.tcp_cntrl171.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl172.L1cache.m_demand_misses / system.ruby.tcp_cntrl172.L1cache.m_demand_accesses  68.5764%
  • system.ruby.tcp_cntrl173.L1cache.m_demand_misses / system.ruby.tcp_cntrl173.L1cache.m_demand_accesses  68.6047%
  • system.ruby.tcp_cntrl174.L1cache.m_demand_misses / system.ruby.tcp_cntrl174.L1cache.m_demand_accesses  68.5345%
  • system.ruby.tcp_cntrl175.L1cache.m_demand_misses / system.ruby.tcp_cntrl175.L1cache.m_demand_accesses  68.4466%
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses  65.7197%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses  67.4242%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  54.9232%
  • system.ruby.tcp_cntrl20.L1cache.m_demand_misses / system.ruby.tcp_cntrl20.L1cache.m_demand_accesses  67.9487%
  • system.ruby.tcp_cntrl21.L1cache.m_demand_misses / system.ruby.tcp_cntrl21.L1cache.m_demand_accesses  68.1260%
  • system.ruby.tcp_cntrl22.L1cache.m_demand_misses / system.ruby.tcp_cntrl22.L1cache.m_demand_accesses  68.0672%
  • system.ruby.tcp_cntrl23.L1cache.m_demand_misses / system.ruby.tcp_cntrl23.L1cache.m_demand_accesses  67.9558%
  • system.ruby.tcp_cntrl24.L1cache.m_demand_misses / system.ruby.tcp_cntrl24.L1cache.m_demand_accesses  67.8639%
  • system.ruby.tcp_cntrl25.L1cache.m_demand_misses / system.ruby.tcp_cntrl25.L1cache.m_demand_accesses  68.0079%
  • system.ruby.tcp_cntrl26.L1cache.m_demand_misses / system.ruby.tcp_cntrl26.L1cache.m_demand_accesses  68.0000%
  • system.ruby.tcp_cntrl27.L1cache.m_demand_misses / system.ruby.tcp_cntrl27.L1cache.m_demand_accesses  67.9031%
  • system.ruby.tcp_cntrl28.L1cache.m_demand_misses / system.ruby.tcp_cntrl28.L1cache.m_demand_accesses  67.8462%
  • system.ruby.tcp_cntrl29.L1cache.m_demand_misses / system.ruby.tcp_cntrl29.L1cache.m_demand_accesses  68.0228%
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses  55.6923%
  • system.ruby.tcp_cntrl30.L1cache.m_demand_misses / system.ruby.tcp_cntrl30.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl31.L1cache.m_demand_misses / system.ruby.tcp_cntrl31.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl32.L1cache.m_demand_misses / system.ruby.tcp_cntrl32.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl33.L1cache.m_demand_misses / system.ruby.tcp_cntrl33.L1cache.m_demand_accesses  68.1087%
  • system.ruby.tcp_cntrl34.L1cache.m_demand_misses / system.ruby.tcp_cntrl34.L1cache.m_demand_accesses  68.1063%
  • system.ruby.tcp_cntrl35.L1cache.m_demand_misses / system.ruby.tcp_cntrl35.L1cache.m_demand_accesses  67.9599%
  • system.ruby.tcp_cntrl36.L1cache.m_demand_misses / system.ruby.tcp_cntrl36.L1cache.m_demand_accesses  67.7698%
  • system.ruby.tcp_cntrl37.L1cache.m_demand_misses / system.ruby.tcp_cntrl37.L1cache.m_demand_accesses  68.0070%
  • system.ruby.tcp_cntrl38.L1cache.m_demand_misses / system.ruby.tcp_cntrl38.L1cache.m_demand_accesses  68.4807%
  • system.ruby.tcp_cntrl39.L1cache.m_demand_misses / system.ruby.tcp_cntrl39.L1cache.m_demand_accesses  68.3891%
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses  59.9529%
  • system.ruby.tcp_cntrl40.L1cache.m_demand_misses / system.ruby.tcp_cntrl40.L1cache.m_demand_accesses  67.8462%
  • system.ruby.tcp_cntrl41.L1cache.m_demand_misses / system.ruby.tcp_cntrl41.L1cache.m_demand_accesses  67.7885%
  • system.ruby.tcp_cntrl42.L1cache.m_demand_misses / system.ruby.tcp_cntrl42.L1cache.m_demand_accesses  67.9756%
  • system.ruby.tcp_cntrl43.L1cache.m_demand_misses / system.ruby.tcp_cntrl43.L1cache.m_demand_accesses  67.8917%
  • system.ruby.tcp_cntrl44.L1cache.m_demand_misses / system.ruby.tcp_cntrl44.L1cache.m_demand_accesses  67.7680%
  • system.ruby.tcp_cntrl45.L1cache.m_demand_misses / system.ruby.tcp_cntrl45.L1cache.m_demand_accesses  67.7149%
  • system.ruby.tcp_cntrl46.L1cache.m_demand_misses / system.ruby.tcp_cntrl46.L1cache.m_demand_accesses  67.8676%
  • system.ruby.tcp_cntrl47.L1cache.m_demand_misses / system.ruby.tcp_cntrl47.L1cache.m_demand_accesses  67.8487%
  • system.ruby.tcp_cntrl48.L1cache.m_demand_misses / system.ruby.tcp_cntrl48.L1cache.m_demand_accesses  67.7258%
  • system.ruby.tcp_cntrl49.L1cache.m_demand_misses / system.ruby.tcp_cntrl49.L1cache.m_demand_accesses  67.6573%
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses  60.0199%
  • system.ruby.tcp_cntrl50.L1cache.m_demand_misses / system.ruby.tcp_cntrl50.L1cache.m_demand_accesses  67.8472%
  • system.ruby.tcp_cntrl51.L1cache.m_demand_misses / system.ruby.tcp_cntrl51.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl52.L1cache.m_demand_misses / system.ruby.tcp_cntrl52.L1cache.m_demand_accesses  67.7419%
  • system.ruby.tcp_cntrl53.L1cache.m_demand_misses / system.ruby.tcp_cntrl53.L1cache.m_demand_accesses  67.6568%
  • system.ruby.tcp_cntrl54.L1cache.m_demand_misses / system.ruby.tcp_cntrl54.L1cache.m_demand_accesses  67.8998%
  • system.ruby.tcp_cntrl55.L1cache.m_demand_misses / system.ruby.tcp_cntrl55.L1cache.m_demand_accesses  67.8715%
  • system.ruby.tcp_cntrl56.L1cache.m_demand_misses / system.ruby.tcp_cntrl56.L1cache.m_demand_accesses  67.6516%
  • system.ruby.tcp_cntrl57.L1cache.m_demand_misses / system.ruby.tcp_cntrl57.L1cache.m_demand_accesses  67.3469%
  • system.ruby.tcp_cntrl58.L1cache.m_demand_misses / system.ruby.tcp_cntrl58.L1cache.m_demand_accesses  67.5481%
  • system.ruby.tcp_cntrl59.L1cache.m_demand_misses / system.ruby.tcp_cntrl59.L1cache.m_demand_accesses  68.0702%
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses  59.9787%
  • system.ruby.tcp_cntrl60.L1cache.m_demand_misses / system.ruby.tcp_cntrl60.L1cache.m_demand_accesses  67.7258%
  • system.ruby.tcp_cntrl61.L1cache.m_demand_misses / system.ruby.tcp_cntrl61.L1cache.m_demand_accesses  67.6573%
  • system.ruby.tcp_cntrl62.L1cache.m_demand_misses / system.ruby.tcp_cntrl62.L1cache.m_demand_accesses  67.5824%
  • system.ruby.tcp_cntrl63.L1cache.m_demand_misses / system.ruby.tcp_cntrl63.L1cache.m_demand_accesses  67.7778%
  • system.ruby.tcp_cntrl64.L1cache.m_demand_misses / system.ruby.tcp_cntrl64.L1cache.m_demand_accesses  67.8994%
  • system.ruby.tcp_cntrl65.L1cache.m_demand_misses / system.ruby.tcp_cntrl65.L1cache.m_demand_accesses  67.8462%
  • system.ruby.tcp_cntrl66.L1cache.m_demand_misses / system.ruby.tcp_cntrl66.L1cache.m_demand_accesses  67.7885%
  • system.ruby.tcp_cntrl67.L1cache.m_demand_misses / system.ruby.tcp_cntrl67.L1cache.m_demand_accesses  67.9694%
  • system.ruby.tcp_cntrl68.L1cache.m_demand_misses / system.ruby.tcp_cntrl68.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl69.L1cache.m_demand_misses / system.ruby.tcp_cntrl69.L1cache.m_demand_accesses  67.8873%
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses  59.9311%
  • system.ruby.tcp_cntrl70.L1cache.m_demand_misses / system.ruby.tcp_cntrl70.L1cache.m_demand_accesses  67.8184%
  • system.ruby.tcp_cntrl71.L1cache.m_demand_misses / system.ruby.tcp_cntrl71.L1cache.m_demand_accesses  68.0467%
  • system.ruby.tcp_cntrl72.L1cache.m_demand_misses / system.ruby.tcp_cntrl72.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl73.L1cache.m_demand_misses / system.ruby.tcp_cntrl73.L1cache.m_demand_accesses  67.9518%
  • system.ruby.tcp_cntrl74.L1cache.m_demand_misses / system.ruby.tcp_cntrl74.L1cache.m_demand_accesses  67.8663%
  • system.ruby.tcp_cntrl75.L1cache.m_demand_misses / system.ruby.tcp_cntrl75.L1cache.m_demand_accesses  68.1754%
  • system.ruby.tcp_cntrl76.L1cache.m_demand_misses / system.ruby.tcp_cntrl76.L1cache.m_demand_accesses  68.1818%
  • system.ruby.tcp_cntrl77.L1cache.m_demand_misses / system.ruby.tcp_cntrl77.L1cache.m_demand_accesses  67.9688%
  • system.ruby.tcp_cntrl78.L1cache.m_demand_misses / system.ruby.tcp_cntrl78.L1cache.m_demand_accesses  67.6471%
  • system.ruby.tcp_cntrl79.L1cache.m_demand_misses / system.ruby.tcp_cntrl79.L1cache.m_demand_accesses  68.0702%
  • system.ruby.tcp_cntrl8.L1cache.m_demand_misses / system.ruby.tcp_cntrl8.L1cache.m_demand_accesses  60.6977%
  • system.ruby.tcp_cntrl80.L1cache.m_demand_misses / system.ruby.tcp_cntrl80.L1cache.m_demand_accesses  68.2149%
  • system.ruby.tcp_cntrl81.L1cache.m_demand_misses / system.ruby.tcp_cntrl81.L1cache.m_demand_accesses  68.2081%
  • system.ruby.tcp_cntrl82.L1cache.m_demand_misses / system.ruby.tcp_cntrl82.L1cache.m_demand_accesses  68.1542%
  • system.ruby.tcp_cntrl83.L1cache.m_demand_misses / system.ruby.tcp_cntrl83.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl84.L1cache.m_demand_misses / system.ruby.tcp_cntrl84.L1cache.m_demand_accesses  68.1068%
  • system.ruby.tcp_cntrl85.L1cache.m_demand_misses / system.ruby.tcp_cntrl85.L1cache.m_demand_accesses  68.0590%
  • system.ruby.tcp_cntrl86.L1cache.m_demand_misses / system.ruby.tcp_cntrl86.L1cache.m_demand_accesses  68.0068%
  • system.ruby.tcp_cntrl87.L1cache.m_demand_misses / system.ruby.tcp_cntrl87.L1cache.m_demand_accesses  67.9499%
  • system.ruby.tcp_cntrl88.L1cache.m_demand_misses / system.ruby.tcp_cntrl88.L1cache.m_demand_accesses  68.1644%
  • system.ruby.tcp_cntrl89.L1cache.m_demand_misses / system.ruby.tcp_cntrl89.L1cache.m_demand_accesses  68.1542%
  • system.ruby.tcp_cntrl9.L1cache.m_demand_misses / system.ruby.tcp_cntrl9.L1cache.m_demand_accesses  60.9681%
  • system.ruby.tcp_cntrl90.L1cache.m_demand_misses / system.ruby.tcp_cntrl90.L1cache.m_demand_accesses  68.0942%
  • system.ruby.tcp_cntrl91.L1cache.m_demand_misses / system.ruby.tcp_cntrl91.L1cache.m_demand_accesses  68.0272%
  • system.ruby.tcp_cntrl92.L1cache.m_demand_misses / system.ruby.tcp_cntrl92.L1cache.m_demand_accesses  68.3107%
  • system.ruby.tcp_cntrl93.L1cache.m_demand_misses / system.ruby.tcp_cntrl93.L1cache.m_demand_accesses  68.3089%
  • system.ruby.tcp_cntrl94.L1cache.m_demand_misses / system.ruby.tcp_cntrl94.L1cache.m_demand_accesses  68.2403%
  • system.ruby.tcp_cntrl95.L1cache.m_demand_misses / system.ruby.tcp_cntrl95.L1cache.m_demand_accesses  68.1607%
  • system.ruby.tcp_cntrl96.L1cache.m_demand_misses / system.ruby.tcp_cntrl96.L1cache.m_demand_accesses  68.5764%
  • system.ruby.tcp_cntrl97.L1cache.m_demand_misses / system.ruby.tcp_cntrl97.L1cache.m_demand_accesses  68.6598%
  • system.ruby.tcp_cntrl98.L1cache.m_demand_misses / system.ruby.tcp_cntrl98.L1cache.m_demand_accesses  68.5039%
  • system.ruby.tcp_cntrl99.L1cache.m_demand_misses / system.ruby.tcp_cntrl99.L1cache.m_demand_accesses  68.2310%

Functional Tests (offline evidence)
------------------------------------------------------------------------------------------------
• 资源实例化        PASS
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=64, cu=176, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.024961
  evidence: stats.txt: system.cpu1.ipc=0.000040
  evidence: stats.txt: system.cpu10.ipc=0.000008
• 系统初始化        PASS
  notes: 检测到进入执行阶段迹象
  evidence: simout/simerr:990: Exiting because  exiting with last active thread context
• 功能执行         PASS
  notes: 检测到正常退出迹象
  evidence: simout/simerr:990: Exiting because  exiting with last active thread context
• 结果校验         PASS
  notes: 检测到 correctness/返回状态成功信号
  evidence: simout/simerr:409: [gaussian] pthread_create success tid=0 iter=0
  evidence: simout/simerr:411: [gaussian] pthread_create success tid=1 iter=0
  evidence: simout/simerr:413: [gaussian] pthread_create success tid=2 iter=0
• 异常检查         PASS
  notes: 未命中严重异常关键字
  evidence: (none)
