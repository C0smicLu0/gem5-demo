
=================================================================================================================================================
  Analyze Summary
=================================================================================================================================================
run_dir            : ~/gem5-demo/tests/testing-results/pannotia-bc-1k-128k-args4.7.14
latency_files      : cpu=328 gpu=176
ldst_weighted_mean : 30.596697
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : ~/.../testing-results/pannotia-bc-1k-128k-args4.7.14/analyze.md
output_json        : ~/.../testing-results/pannotia-bc-1k-128k-args4.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 328
total samples: 1,124,256,833
mean/min/max: 13.39 / 1 / 27817
slow buckets: >100=73,711,883  >500=13,355  >1000=2,796  >5000=819
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH           864,592,170        9.93         1     27817
LD               165,798,885       26.49         1     14866
Locked_RMW_Read       262,174       56.07         1      7547
Locked_RMW_Write       262,174        1.00         1         1
RMW_Read           2,202,065       47.13         1      2226
ST                91,139,365       21.40         1     15427

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 176
total samples: 125,564,541
mean/min/max: 58.47 / 1 / 5946
slow buckets: >100=17,912,704  >500=2,261,393  >1000=1,196,344  >5000=4,560
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
ATOMIC_RETURN      5,786,937      372.94       169      2609
LD               118,828,732       43.61         1      5946
ST                   948,872        1.13         1       789

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 30.596697
samples(cpu/gpu/total): 256938250/119777604/376715854

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  16.9777%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  32.9741%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses   8.9596%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  40.5615%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses   4.7630%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses   0.1637%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   0.8924%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  51.1557%
  • system.ruby.cp_cntrl10.L1D0cache.m_demand_misses / system.ruby.cp_cntrl10.L1D0cache.m_demand_accesses   0.2340%
  • system.ruby.cp_cntrl10.L1D1cache.m_demand_misses / system.ruby.cp_cntrl10.L1D1cache.m_demand_accesses   0.2325%
  • system.ruby.cp_cntrl10.L1Icache.m_demand_misses / system.ruby.cp_cntrl10.L1Icache.m_demand_accesses   2.5956%
  • system.ruby.cp_cntrl10.L2cache.m_demand_misses / system.ruby.cp_cntrl10.L2cache.m_demand_accesses   0.5208%
  • system.ruby.cp_cntrl11.L1D0cache.m_demand_misses / system.ruby.cp_cntrl11.L1D0cache.m_demand_accesses   0.1729%
  • system.ruby.cp_cntrl11.L1D1cache.m_demand_misses / system.ruby.cp_cntrl11.L1D1cache.m_demand_accesses   0.1724%
  • system.ruby.cp_cntrl11.L1Icache.m_demand_misses / system.ruby.cp_cntrl11.L1Icache.m_demand_accesses   2.5985%
  • system.ruby.cp_cntrl11.L2cache.m_demand_misses / system.ruby.cp_cntrl11.L2cache.m_demand_accesses   0.3967%
  • system.ruby.cp_cntrl12.L1D0cache.m_demand_misses / system.ruby.cp_cntrl12.L1D0cache.m_demand_accesses   0.1830%
  • system.ruby.cp_cntrl12.L1D1cache.m_demand_misses / system.ruby.cp_cntrl12.L1D1cache.m_demand_accesses   0.1797%
  • system.ruby.cp_cntrl12.L1Icache.m_demand_misses / system.ruby.cp_cntrl12.L1Icache.m_demand_accesses   2.5983%
  • system.ruby.cp_cntrl12.L2cache.m_demand_misses / system.ruby.cp_cntrl12.L2cache.m_demand_accesses   0.4167%
  • system.ruby.cp_cntrl13.L1D0cache.m_demand_misses / system.ruby.cp_cntrl13.L1D0cache.m_demand_accesses   0.1914%
  • system.ruby.cp_cntrl13.L1D1cache.m_demand_misses / system.ruby.cp_cntrl13.L1D1cache.m_demand_accesses   0.1899%
  • system.ruby.cp_cntrl13.L1Icache.m_demand_misses / system.ruby.cp_cntrl13.L1Icache.m_demand_accesses   2.6022%
  • system.ruby.cp_cntrl13.L2cache.m_demand_misses / system.ruby.cp_cntrl13.L2cache.m_demand_accesses   0.4362%
  • system.ruby.cp_cntrl14.L1D0cache.m_demand_misses / system.ruby.cp_cntrl14.L1D0cache.m_demand_accesses   0.2882%
  • system.ruby.cp_cntrl14.L1D1cache.m_demand_misses / system.ruby.cp_cntrl14.L1D1cache.m_demand_accesses   0.2861%
  • system.ruby.cp_cntrl14.L1Icache.m_demand_misses / system.ruby.cp_cntrl14.L1Icache.m_demand_accesses   2.6023%
  • system.ruby.cp_cntrl14.L2cache.m_demand_misses / system.ruby.cp_cntrl14.L2cache.m_demand_accesses   0.6430%
  • system.ruby.cp_cntrl15.L1D0cache.m_demand_misses / system.ruby.cp_cntrl15.L1D0cache.m_demand_accesses   0.2153%
  • system.ruby.cp_cntrl15.L1D1cache.m_demand_misses / system.ruby.cp_cntrl15.L1D1cache.m_demand_accesses   0.2144%
  • system.ruby.cp_cntrl15.L1Icache.m_demand_misses / system.ruby.cp_cntrl15.L1Icache.m_demand_accesses   2.6077%
  • system.ruby.cp_cntrl15.L2cache.m_demand_misses / system.ruby.cp_cntrl15.L2cache.m_demand_accesses   0.4900%
  • system.ruby.cp_cntrl16.L1D0cache.m_demand_misses / system.ruby.cp_cntrl16.L1D0cache.m_demand_accesses   0.3224%
  • system.ruby.cp_cntrl16.L1D1cache.m_demand_misses / system.ruby.cp_cntrl16.L1D1cache.m_demand_accesses   0.3206%
  • system.ruby.cp_cntrl16.L1Icache.m_demand_misses / system.ruby.cp_cntrl16.L1Icache.m_demand_accesses   2.6078%
  • system.ruby.cp_cntrl16.L2cache.m_demand_misses / system.ruby.cp_cntrl16.L2cache.m_demand_accesses   0.7212%
  • system.ruby.cp_cntrl17.L1D0cache.m_demand_misses / system.ruby.cp_cntrl17.L1D0cache.m_demand_accesses   0.2432%
  • system.ruby.cp_cntrl17.L1D1cache.m_demand_misses / system.ruby.cp_cntrl17.L1D1cache.m_demand_accesses   0.2436%
  • system.ruby.cp_cntrl17.L1Icache.m_demand_misses / system.ruby.cp_cntrl17.L1Icache.m_demand_accesses   2.6132%
  • system.ruby.cp_cntrl17.L2cache.m_demand_misses / system.ruby.cp_cntrl17.L2cache.m_demand_accesses   0.5598%
  • system.ruby.cp_cntrl18.L1D0cache.m_demand_misses / system.ruby.cp_cntrl18.L1D0cache.m_demand_accesses   0.2778%
  • system.ruby.cp_cntrl18.L1D1cache.m_demand_misses / system.ruby.cp_cntrl18.L1D1cache.m_demand_accesses   0.2781%
  • system.ruby.cp_cntrl18.L1Icache.m_demand_misses / system.ruby.cp_cntrl18.L1Icache.m_demand_accesses   5.1033%
  • system.ruby.cp_cntrl18.L2cache.m_demand_misses / system.ruby.cp_cntrl18.L2cache.m_demand_accesses   0.5628%
  • system.ruby.cp_cntrl19.L1D0cache.m_demand_misses / system.ruby.cp_cntrl19.L1D0cache.m_demand_accesses   0.3955%
  • system.ruby.cp_cntrl19.L1D1cache.m_demand_misses / system.ruby.cp_cntrl19.L1D1cache.m_demand_accesses   0.3991%
  • system.ruby.cp_cntrl19.L1Icache.m_demand_misses / system.ruby.cp_cntrl19.L1Icache.m_demand_accesses   2.6205%
  • system.ruby.cp_cntrl19.L2cache.m_demand_misses / system.ruby.cp_cntrl19.L2cache.m_demand_accesses   0.8899%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses   0.1696%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses   0.1695%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   2.5869%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses   0.3831%
  • system.ruby.cp_cntrl20.L1D0cache.m_demand_misses / system.ruby.cp_cntrl20.L1D0cache.m_demand_accesses   0.3067%
  • system.ruby.cp_cntrl20.L1D1cache.m_demand_misses / system.ruby.cp_cntrl20.L1D1cache.m_demand_accesses   0.3061%
  • system.ruby.cp_cntrl20.L1Icache.m_demand_misses / system.ruby.cp_cntrl20.L1Icache.m_demand_accesses   2.6219%
  • system.ruby.cp_cntrl20.L2cache.m_demand_misses / system.ruby.cp_cntrl20.L2cache.m_demand_accesses   0.6922%
  • system.ruby.cp_cntrl21.L1D0cache.m_demand_misses / system.ruby.cp_cntrl21.L1D0cache.m_demand_accesses   0.3343%
  • system.ruby.cp_cntrl21.L1D1cache.m_demand_misses / system.ruby.cp_cntrl21.L1D1cache.m_demand_accesses   0.3354%
  • system.ruby.cp_cntrl21.L1Icache.m_demand_misses / system.ruby.cp_cntrl21.L1Icache.m_demand_accesses   2.6309%
  • system.ruby.cp_cntrl21.L2cache.m_demand_misses / system.ruby.cp_cntrl21.L2cache.m_demand_accesses   0.7700%
  • system.ruby.cp_cntrl22.L1D0cache.m_demand_misses / system.ruby.cp_cntrl22.L1D0cache.m_demand_accesses   0.5167%
  • system.ruby.cp_cntrl22.L1D1cache.m_demand_misses / system.ruby.cp_cntrl22.L1D1cache.m_demand_accesses   0.5222%
  • system.ruby.cp_cntrl22.L1Icache.m_demand_misses / system.ruby.cp_cntrl22.L1Icache.m_demand_accesses   2.6340%
  • system.ruby.cp_cntrl22.L2cache.m_demand_misses / system.ruby.cp_cntrl22.L2cache.m_demand_accesses   1.1534%
  • system.ruby.cp_cntrl23.L1D0cache.m_demand_misses / system.ruby.cp_cntrl23.L1D0cache.m_demand_accesses   0.4125%
  • system.ruby.cp_cntrl23.L1D1cache.m_demand_misses / system.ruby.cp_cntrl23.L1D1cache.m_demand_accesses   0.4172%
  • system.ruby.cp_cntrl23.L1Icache.m_demand_misses / system.ruby.cp_cntrl23.L1Icache.m_demand_accesses   2.6468%
  • system.ruby.cp_cntrl23.L2cache.m_demand_misses / system.ruby.cp_cntrl23.L2cache.m_demand_accesses   0.9490%
  • system.ruby.cp_cntrl24.L1D0cache.m_demand_misses / system.ruby.cp_cntrl24.L1D0cache.m_demand_accesses   0.4594%
  • system.ruby.cp_cntrl24.L1D1cache.m_demand_misses / system.ruby.cp_cntrl24.L1D1cache.m_demand_accesses   0.4711%
  • system.ruby.cp_cntrl24.L1Icache.m_demand_misses / system.ruby.cp_cntrl24.L1Icache.m_demand_accesses   2.6532%
  • system.ruby.cp_cntrl24.L2cache.m_demand_misses / system.ruby.cp_cntrl24.L2cache.m_demand_accesses   1.0541%
  • system.ruby.cp_cntrl25.L1D0cache.m_demand_misses / system.ruby.cp_cntrl25.L1D0cache.m_demand_accesses   0.5288%
  • system.ruby.cp_cntrl25.L1D1cache.m_demand_misses / system.ruby.cp_cntrl25.L1D1cache.m_demand_accesses   0.5527%
  • system.ruby.cp_cntrl25.L1Icache.m_demand_misses / system.ruby.cp_cntrl25.L1Icache.m_demand_accesses   2.6739%
  • system.ruby.cp_cntrl25.L2cache.m_demand_misses / system.ruby.cp_cntrl25.L2cache.m_demand_accesses   1.2317%
  • system.ruby.cp_cntrl26.L1D0cache.m_demand_misses / system.ruby.cp_cntrl26.L1D0cache.m_demand_accesses   0.6211%
  • system.ruby.cp_cntrl26.L1D1cache.m_demand_misses / system.ruby.cp_cntrl26.L1D1cache.m_demand_accesses   0.6428%
  • system.ruby.cp_cntrl26.L1Icache.m_demand_misses / system.ruby.cp_cntrl26.L1Icache.m_demand_accesses   2.6836%
  • system.ruby.cp_cntrl26.L2cache.m_demand_misses / system.ruby.cp_cntrl26.L2cache.m_demand_accesses   1.4346%
  • system.ruby.cp_cntrl27.L1D0cache.m_demand_misses / system.ruby.cp_cntrl27.L1D0cache.m_demand_accesses   0.7407%
  • system.ruby.cp_cntrl27.L1D1cache.m_demand_misses / system.ruby.cp_cntrl27.L1D1cache.m_demand_accesses   0.7909%
  • system.ruby.cp_cntrl27.L1Icache.m_demand_misses / system.ruby.cp_cntrl27.L1Icache.m_demand_accesses   2.7186%
  • system.ruby.cp_cntrl27.L2cache.m_demand_misses / system.ruby.cp_cntrl27.L2cache.m_demand_accesses   1.7344%
  • system.ruby.cp_cntrl28.L1D0cache.m_demand_misses / system.ruby.cp_cntrl28.L1D0cache.m_demand_accesses   0.9267%
  • system.ruby.cp_cntrl28.L1D1cache.m_demand_misses / system.ruby.cp_cntrl28.L1D1cache.m_demand_accesses   1.0012%
  • system.ruby.cp_cntrl28.L1Icache.m_demand_misses / system.ruby.cp_cntrl28.L1Icache.m_demand_accesses   2.7432%
  • system.ruby.cp_cntrl28.L2cache.m_demand_misses / system.ruby.cp_cntrl28.L2cache.m_demand_accesses   2.1686%
  • system.ruby.cp_cntrl29.L1D0cache.m_demand_misses / system.ruby.cp_cntrl29.L1D0cache.m_demand_accesses   1.2605%
  • system.ruby.cp_cntrl29.L1D1cache.m_demand_misses / system.ruby.cp_cntrl29.L1D1cache.m_demand_accesses   1.4389%
  • system.ruby.cp_cntrl29.L1Icache.m_demand_misses / system.ruby.cp_cntrl29.L1Icache.m_demand_accesses   5.0462%
  • system.ruby.cp_cntrl29.L2cache.m_demand_misses / system.ruby.cp_cntrl29.L2cache.m_demand_accesses   2.6721%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses   0.1768%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses   0.1748%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   5.1178%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses   0.3444%
  • system.ruby.cp_cntrl30.L1D0cache.m_demand_misses / system.ruby.cp_cntrl30.L1D0cache.m_demand_accesses   1.9497%
  • system.ruby.cp_cntrl30.L1D1cache.m_demand_misses / system.ruby.cp_cntrl30.L1D1cache.m_demand_accesses   2.4613%
  • system.ruby.cp_cntrl30.L1Icache.m_demand_misses / system.ruby.cp_cntrl30.L1Icache.m_demand_accesses   2.9762%
  • system.ruby.cp_cntrl30.L2cache.m_demand_misses / system.ruby.cp_cntrl30.L2cache.m_demand_accesses   4.8105%
  • system.ruby.cp_cntrl31.L1D0cache.m_demand_misses / system.ruby.cp_cntrl31.L1D0cache.m_demand_accesses   5.3775%
  • system.ruby.cp_cntrl31.L1D1cache.m_demand_misses / system.ruby.cp_cntrl31.L1D1cache.m_demand_accesses   9.8751%
  • system.ruby.cp_cntrl31.L1Icache.m_demand_misses / system.ruby.cp_cntrl31.L1Icache.m_demand_accesses   3.5690%
  • system.ruby.cp_cntrl31.L2cache.m_demand_misses / system.ruby.cp_cntrl31.L2cache.m_demand_accesses  14.1097%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses   0.1815%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses   0.1797%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   2.5883%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses   0.4061%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses   0.1912%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses   0.1881%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   5.1157%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses   0.3743%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses   0.1401%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses   0.1378%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   2.5906%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses   0.3181%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses   0.2059%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses   0.2044%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   2.5937%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses   0.4623%
  • system.ruby.cp_cntrl8.L1D0cache.m_demand_misses / system.ruby.cp_cntrl8.L1D0cache.m_demand_accesses   0.1519%
  • system.ruby.cp_cntrl8.L1D1cache.m_demand_misses / system.ruby.cp_cntrl8.L1D1cache.m_demand_accesses   0.1500%
  • system.ruby.cp_cntrl8.L1Icache.m_demand_misses / system.ruby.cp_cntrl8.L1Icache.m_demand_accesses   2.5931%
  • system.ruby.cp_cntrl8.L2cache.m_demand_misses / system.ruby.cp_cntrl8.L2cache.m_demand_accesses   0.3463%
  • system.ruby.cp_cntrl9.L1D0cache.m_demand_misses / system.ruby.cp_cntrl9.L1D0cache.m_demand_accesses   0.2220%
  • system.ruby.cp_cntrl9.L1D1cache.m_demand_misses / system.ruby.cp_cntrl9.L1D1cache.m_demand_accesses   0.2214%
  • system.ruby.cp_cntrl9.L1Icache.m_demand_misses / system.ruby.cp_cntrl9.L1Icache.m_demand_accesses   2.5957%
  • system.ruby.cp_cntrl9.L2cache.m_demand_misses / system.ruby.cp_cntrl9.L2cache.m_demand_accesses   0.4978%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   0.2101%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  21.8575%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses  24.9466%
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
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses  25.0000%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses   0.2202%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses   0.1938%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses   6.0403%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses   5.3571%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses   5.6604%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses   6.7669%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses   5.6604%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses   6.7669%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses   5.6604%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses   6.7669%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses   7.6923%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses   6.7669%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl40.L1cache.m_demand_misses / system.ruby.sqc_cntrl40.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl41.L1cache.m_demand_misses / system.ruby.sqc_cntrl41.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl42.L1cache.m_demand_misses / system.ruby.sqc_cntrl42.L1cache.m_demand_accesses   6.5217%
  • system.ruby.sqc_cntrl43.L1cache.m_demand_misses / system.ruby.sqc_cntrl43.L1cache.m_demand_accesses   6.2937%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses   6.2069%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses   5.0847%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses  41.7793%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  16.5636%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  19.1583%
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
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  16.4398%
  • system.ruby.tcp_cntrl20.L1cache.m_demand_misses / system.ruby.tcp_cntrl20.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl21.L1cache.m_demand_misses / system.ruby.tcp_cntrl21.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl22.L1cache.m_demand_misses / system.ruby.tcp_cntrl22.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl23.L1cache.m_demand_misses / system.ruby.tcp_cntrl23.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl24.L1cache.m_demand_misses / system.ruby.tcp_cntrl24.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl25.L1cache.m_demand_misses / system.ruby.tcp_cntrl25.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl26.L1cache.m_demand_misses / system.ruby.tcp_cntrl26.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl27.L1cache.m_demand_misses / system.ruby.tcp_cntrl27.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl28.L1cache.m_demand_misses / system.ruby.tcp_cntrl28.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl29.L1cache.m_demand_misses / system.ruby.tcp_cntrl29.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses  17.0713%
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
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses  15.1794%
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
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses  15.6143%
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
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses  15.4845%
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
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses  15.6001%
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
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=64, cu=176, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.034480
  evidence: stats.txt: system.cpu1.ipc=0.000003
  evidence: stats.txt: system.cpu10.ipc=0.000059
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
