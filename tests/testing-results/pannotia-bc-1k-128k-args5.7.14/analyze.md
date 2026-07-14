
=================================================================================================================================================
  Analyze Summary
=================================================================================================================================================
run_dir            : ~/gem5-demo/tests/testing-results/pannotia-bc-1k-128k-args5.7.14
latency_files      : cpu=320 gpu=160
ldst_weighted_mean : 30.136457
functional         : PASS=5 FAIL=0 UNKNOWN=0
output_md          : ~/.../testing-results/pannotia-bc-1k-128k-args5.7.14/analyze.md
output_json        : ~/.../testing-results/pannotia-bc-1k-128k-args5.7.14/analyze.json

Latency Aggregate (cpu)
------------------------------------------------------------------------------------------------
source files: 320
total samples: 1,148,534,974
mean/min/max: 13.15 / 1 / 25465
slow buckets: >100=73,734,499  >500=14,881  >1000=3,720  >5000=1,551
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
IFETCH           882,742,627        9.77         1     23922
LD               169,073,118       26.02         1     19199
Locked_RMW_Read       262,612       58.46         1      9304
Locked_RMW_Write       262,612        1.00         1         1
RMW_Read           2,202,840       47.01         1      3587
ST                93,991,165       20.84         1     25465

Latency Aggregate (gpu)
------------------------------------------------------------------------------------------------
source files: 160
total samples: 125,563,603
mean/min/max: 58.57 / 1 / 4487
slow buckets: >100=17,921,576  >500=2,276,386  >1000=1,215,764  >5000=0
------------------------------------------------------------------------
type                 samples        mean       min       max
------------------------------------------------------------------------
ATOMIC_RETURN      5,798,751      374.97       169      2655
LD               118,818,116       43.58         1      4487
ST                   946,736        1.13         1       790

Latency Aggregate (ldst)
------------------------------------------------------------------------------------------------
ldst_mean(weighted): 30.136457
samples(cpu/gpu/total): 263064283/119764852/382829135

Cache Miss Rate (last stats dump)
------------------------------------------------------------------------------------------------
优先统计（m_demand_misses / m_demand_accesses）
  • system.ruby.cp_cntrl0.L1D0cache.m_demand_misses / system.ruby.cp_cntrl0.L1D0cache.m_demand_accesses  16.9625%
  • system.ruby.cp_cntrl0.L1D1cache.m_demand_misses / system.ruby.cp_cntrl0.L1D1cache.m_demand_accesses  34.6891%
  • system.ruby.cp_cntrl0.L1Icache.m_demand_misses / system.ruby.cp_cntrl0.L1Icache.m_demand_accesses   8.9623%
  • system.ruby.cp_cntrl0.L2cache.m_demand_misses / system.ruby.cp_cntrl0.L2cache.m_demand_accesses  40.5695%
  • system.ruby.cp_cntrl1.L1D0cache.m_demand_misses / system.ruby.cp_cntrl1.L1D0cache.m_demand_accesses   4.8298%
  • system.ruby.cp_cntrl1.L1D1cache.m_demand_misses / system.ruby.cp_cntrl1.L1D1cache.m_demand_accesses   0.1324%
  • system.ruby.cp_cntrl1.L1Icache.m_demand_misses / system.ruby.cp_cntrl1.L1Icache.m_demand_accesses   0.8979%
  • system.ruby.cp_cntrl1.L2cache.m_demand_misses / system.ruby.cp_cntrl1.L2cache.m_demand_accesses  50.0358%
  • system.ruby.cp_cntrl10.L1D0cache.m_demand_misses / system.ruby.cp_cntrl10.L1D0cache.m_demand_accesses   0.1252%
  • system.ruby.cp_cntrl10.L1D1cache.m_demand_misses / system.ruby.cp_cntrl10.L1D1cache.m_demand_accesses   0.1217%
  • system.ruby.cp_cntrl10.L1Icache.m_demand_misses / system.ruby.cp_cntrl10.L1Icache.m_demand_accesses   2.5872%
  • system.ruby.cp_cntrl10.L2cache.m_demand_misses / system.ruby.cp_cntrl10.L2cache.m_demand_accesses   0.2827%
  • system.ruby.cp_cntrl11.L1D0cache.m_demand_misses / system.ruby.cp_cntrl11.L1D0cache.m_demand_accesses   0.1282%
  • system.ruby.cp_cntrl11.L1D1cache.m_demand_misses / system.ruby.cp_cntrl11.L1D1cache.m_demand_accesses   0.1271%
  • system.ruby.cp_cntrl11.L1Icache.m_demand_misses / system.ruby.cp_cntrl11.L1Icache.m_demand_accesses   2.5893%
  • system.ruby.cp_cntrl11.L2cache.m_demand_misses / system.ruby.cp_cntrl11.L2cache.m_demand_accesses   0.2944%
  • system.ruby.cp_cntrl12.L1D0cache.m_demand_misses / system.ruby.cp_cntrl12.L1D0cache.m_demand_accesses   0.1334%
  • system.ruby.cp_cntrl12.L1D1cache.m_demand_misses / system.ruby.cp_cntrl12.L1D1cache.m_demand_accesses   0.1323%
  • system.ruby.cp_cntrl12.L1Icache.m_demand_misses / system.ruby.cp_cntrl12.L1Icache.m_demand_accesses   5.1175%
  • system.ruby.cp_cntrl12.L2cache.m_demand_misses / system.ruby.cp_cntrl12.L2cache.m_demand_accesses   0.2655%
  • system.ruby.cp_cntrl13.L1D0cache.m_demand_misses / system.ruby.cp_cntrl13.L1D0cache.m_demand_accesses   0.1933%
  • system.ruby.cp_cntrl13.L1D1cache.m_demand_misses / system.ruby.cp_cntrl13.L1D1cache.m_demand_accesses   0.1903%
  • system.ruby.cp_cntrl13.L1Icache.m_demand_misses / system.ruby.cp_cntrl13.L1Icache.m_demand_accesses   2.5915%
  • system.ruby.cp_cntrl13.L2cache.m_demand_misses / system.ruby.cp_cntrl13.L2cache.m_demand_accesses   0.4274%
  • system.ruby.cp_cntrl14.L1D0cache.m_demand_misses / system.ruby.cp_cntrl14.L1D0cache.m_demand_accesses   0.1450%
  • system.ruby.cp_cntrl14.L1D1cache.m_demand_misses / system.ruby.cp_cntrl14.L1D1cache.m_demand_accesses   0.1406%
  • system.ruby.cp_cntrl14.L1Icache.m_demand_misses / system.ruby.cp_cntrl14.L1Icache.m_demand_accesses   2.5906%
  • system.ruby.cp_cntrl14.L2cache.m_demand_misses / system.ruby.cp_cntrl14.L2cache.m_demand_accesses   0.3273%
  • system.ruby.cp_cntrl15.L1D0cache.m_demand_misses / system.ruby.cp_cntrl15.L1D0cache.m_demand_accesses   0.1492%
  • system.ruby.cp_cntrl15.L1D1cache.m_demand_misses / system.ruby.cp_cntrl15.L1D1cache.m_demand_accesses   0.1466%
  • system.ruby.cp_cntrl15.L1Icache.m_demand_misses / system.ruby.cp_cntrl15.L1Icache.m_demand_accesses   2.5932%
  • system.ruby.cp_cntrl15.L2cache.m_demand_misses / system.ruby.cp_cntrl15.L2cache.m_demand_accesses   0.3371%
  • system.ruby.cp_cntrl16.L1D0cache.m_demand_misses / system.ruby.cp_cntrl16.L1D0cache.m_demand_accesses   0.1556%
  • system.ruby.cp_cntrl16.L1D1cache.m_demand_misses / system.ruby.cp_cntrl16.L1D1cache.m_demand_accesses   0.1541%
  • system.ruby.cp_cntrl16.L1Icache.m_demand_misses / system.ruby.cp_cntrl16.L1Icache.m_demand_accesses   2.5936%
  • system.ruby.cp_cntrl16.L2cache.m_demand_misses / system.ruby.cp_cntrl16.L2cache.m_demand_accesses   0.3567%
  • system.ruby.cp_cntrl17.L1D0cache.m_demand_misses / system.ruby.cp_cntrl17.L1D0cache.m_demand_accesses   0.2273%
  • system.ruby.cp_cntrl17.L1D1cache.m_demand_misses / system.ruby.cp_cntrl17.L1D1cache.m_demand_accesses   0.2240%
  • system.ruby.cp_cntrl17.L1Icache.m_demand_misses / system.ruby.cp_cntrl17.L1Icache.m_demand_accesses   2.5964%
  • system.ruby.cp_cntrl17.L2cache.m_demand_misses / system.ruby.cp_cntrl17.L2cache.m_demand_accesses   0.5054%
  • system.ruby.cp_cntrl18.L1D0cache.m_demand_misses / system.ruby.cp_cntrl18.L1D0cache.m_demand_accesses   0.1713%
  • system.ruby.cp_cntrl18.L1D1cache.m_demand_misses / system.ruby.cp_cntrl18.L1D1cache.m_demand_accesses   0.1675%
  • system.ruby.cp_cntrl18.L1Icache.m_demand_misses / system.ruby.cp_cntrl18.L1Icache.m_demand_accesses   2.5959%
  • system.ruby.cp_cntrl18.L2cache.m_demand_misses / system.ruby.cp_cntrl18.L2cache.m_demand_accesses   0.3880%
  • system.ruby.cp_cntrl19.L1D0cache.m_demand_misses / system.ruby.cp_cntrl19.L1D0cache.m_demand_accesses   0.1764%
  • system.ruby.cp_cntrl19.L1D1cache.m_demand_misses / system.ruby.cp_cntrl19.L1D1cache.m_demand_accesses   0.1752%
  • system.ruby.cp_cntrl19.L1Icache.m_demand_misses / system.ruby.cp_cntrl19.L1Icache.m_demand_accesses   2.5995%
  • system.ruby.cp_cntrl19.L2cache.m_demand_misses / system.ruby.cp_cntrl19.L2cache.m_demand_accesses   0.4050%
  • system.ruby.cp_cntrl2.L1D0cache.m_demand_misses / system.ruby.cp_cntrl2.L1D0cache.m_demand_accesses   0.1379%
  • system.ruby.cp_cntrl2.L1D1cache.m_demand_misses / system.ruby.cp_cntrl2.L1D1cache.m_demand_accesses   0.1355%
  • system.ruby.cp_cntrl2.L1Icache.m_demand_misses / system.ruby.cp_cntrl2.L1Icache.m_demand_accesses   2.5821%
  • system.ruby.cp_cntrl2.L2cache.m_demand_misses / system.ruby.cp_cntrl2.L2cache.m_demand_accesses   0.3089%
  • system.ruby.cp_cntrl20.L1D0cache.m_demand_misses / system.ruby.cp_cntrl20.L1D0cache.m_demand_accesses   0.1864%
  • system.ruby.cp_cntrl20.L1D1cache.m_demand_misses / system.ruby.cp_cntrl20.L1D1cache.m_demand_accesses   0.1835%
  • system.ruby.cp_cntrl20.L1Icache.m_demand_misses / system.ruby.cp_cntrl20.L1Icache.m_demand_accesses   2.5993%
  • system.ruby.cp_cntrl20.L2cache.m_demand_misses / system.ruby.cp_cntrl20.L2cache.m_demand_accesses   0.4223%
  • system.ruby.cp_cntrl21.L1D0cache.m_demand_misses / system.ruby.cp_cntrl21.L1D0cache.m_demand_accesses   0.1981%
  • system.ruby.cp_cntrl21.L1D1cache.m_demand_misses / system.ruby.cp_cntrl21.L1D1cache.m_demand_accesses   0.1948%
  • system.ruby.cp_cntrl21.L1Icache.m_demand_misses / system.ruby.cp_cntrl21.L1Icache.m_demand_accesses   2.6026%
  • system.ruby.cp_cntrl21.L2cache.m_demand_misses / system.ruby.cp_cntrl21.L2cache.m_demand_accesses   0.4502%
  • system.ruby.cp_cntrl22.L1D0cache.m_demand_misses / system.ruby.cp_cntrl22.L1D0cache.m_demand_accesses   0.2099%
  • system.ruby.cp_cntrl22.L1D1cache.m_demand_misses / system.ruby.cp_cntrl22.L1D1cache.m_demand_accesses   0.2062%
  • system.ruby.cp_cntrl22.L1Icache.m_demand_misses / system.ruby.cp_cntrl22.L1Icache.m_demand_accesses   2.6026%
  • system.ruby.cp_cntrl22.L2cache.m_demand_misses / system.ruby.cp_cntrl22.L2cache.m_demand_accesses   0.4732%
  • system.ruby.cp_cntrl23.L1D0cache.m_demand_misses / system.ruby.cp_cntrl23.L1D0cache.m_demand_accesses   0.3068%
  • system.ruby.cp_cntrl23.L1D1cache.m_demand_misses / system.ruby.cp_cntrl23.L1D1cache.m_demand_accesses   0.3067%
  • system.ruby.cp_cntrl23.L1Icache.m_demand_misses / system.ruby.cp_cntrl23.L1Icache.m_demand_accesses   5.1073%
  • system.ruby.cp_cntrl23.L2cache.m_demand_misses / system.ruby.cp_cntrl23.L2cache.m_demand_accesses   0.6014%
  • system.ruby.cp_cntrl24.L1D0cache.m_demand_misses / system.ruby.cp_cntrl24.L1D0cache.m_demand_accesses   0.2323%
  • system.ruby.cp_cntrl24.L1D1cache.m_demand_misses / system.ruby.cp_cntrl24.L1D1cache.m_demand_accesses   0.2311%
  • system.ruby.cp_cntrl24.L1Icache.m_demand_misses / system.ruby.cp_cntrl24.L1Icache.m_demand_accesses   2.6073%
  • system.ruby.cp_cntrl24.L2cache.m_demand_misses / system.ruby.cp_cntrl24.L2cache.m_demand_accesses   0.5327%
  • system.ruby.cp_cntrl25.L1D0cache.m_demand_misses / system.ruby.cp_cntrl25.L1D0cache.m_demand_accesses   0.2492%
  • system.ruby.cp_cntrl25.L1D1cache.m_demand_misses / system.ruby.cp_cntrl25.L1D1cache.m_demand_accesses   0.2459%
  • system.ruby.cp_cntrl25.L1Icache.m_demand_misses / system.ruby.cp_cntrl25.L1Icache.m_demand_accesses   2.6125%
  • system.ruby.cp_cntrl25.L2cache.m_demand_misses / system.ruby.cp_cntrl25.L2cache.m_demand_accesses   0.5644%
  • system.ruby.cp_cntrl26.L1D0cache.m_demand_misses / system.ruby.cp_cntrl26.L1D0cache.m_demand_accesses   0.2695%
  • system.ruby.cp_cntrl26.L1D1cache.m_demand_misses / system.ruby.cp_cntrl26.L1D1cache.m_demand_accesses   0.2659%
  • system.ruby.cp_cntrl26.L1Icache.m_demand_misses / system.ruby.cp_cntrl26.L1Icache.m_demand_accesses   2.6142%
  • system.ruby.cp_cntrl26.L2cache.m_demand_misses / system.ruby.cp_cntrl26.L2cache.m_demand_accesses   0.6141%
  • system.ruby.cp_cntrl27.L1D0cache.m_demand_misses / system.ruby.cp_cntrl27.L1D0cache.m_demand_accesses   0.2876%
  • system.ruby.cp_cntrl27.L1D1cache.m_demand_misses / system.ruby.cp_cntrl27.L1D1cache.m_demand_accesses   0.2845%
  • system.ruby.cp_cntrl27.L1Icache.m_demand_misses / system.ruby.cp_cntrl27.L1Icache.m_demand_accesses   5.1035%
  • system.ruby.cp_cntrl27.L2cache.m_demand_misses / system.ruby.cp_cntrl27.L2cache.m_demand_accesses   0.5764%
  • system.ruby.cp_cntrl28.L1D0cache.m_demand_misses / system.ruby.cp_cntrl28.L1D0cache.m_demand_accesses   0.3107%
  • system.ruby.cp_cntrl28.L1D1cache.m_demand_misses / system.ruby.cp_cntrl28.L1D1cache.m_demand_accesses   0.3105%
  • system.ruby.cp_cntrl28.L1Icache.m_demand_misses / system.ruby.cp_cntrl28.L1Icache.m_demand_accesses   2.6226%
  • system.ruby.cp_cntrl28.L2cache.m_demand_misses / system.ruby.cp_cntrl28.L2cache.m_demand_accesses   0.7068%
  • system.ruby.cp_cntrl29.L1D0cache.m_demand_misses / system.ruby.cp_cntrl29.L1D0cache.m_demand_accesses   0.4803%
  • system.ruby.cp_cntrl29.L1D1cache.m_demand_misses / system.ruby.cp_cntrl29.L1D1cache.m_demand_accesses   0.4826%
  • system.ruby.cp_cntrl29.L1Icache.m_demand_misses / system.ruby.cp_cntrl29.L1Icache.m_demand_accesses   2.6308%
  • system.ruby.cp_cntrl29.L2cache.m_demand_misses / system.ruby.cp_cntrl29.L2cache.m_demand_accesses   1.0755%
  • system.ruby.cp_cntrl3.L1D0cache.m_demand_misses / system.ruby.cp_cntrl3.L1D0cache.m_demand_accesses   0.1417%
  • system.ruby.cp_cntrl3.L1D1cache.m_demand_misses / system.ruby.cp_cntrl3.L1D1cache.m_demand_accesses   0.1389%
  • system.ruby.cp_cntrl3.L1Icache.m_demand_misses / system.ruby.cp_cntrl3.L1Icache.m_demand_accesses   5.1177%
  • system.ruby.cp_cntrl3.L2cache.m_demand_misses / system.ruby.cp_cntrl3.L2cache.m_demand_accesses   0.2765%
  • system.ruby.cp_cntrl30.L1D0cache.m_demand_misses / system.ruby.cp_cntrl30.L1D0cache.m_demand_accesses   0.3730%
  • system.ruby.cp_cntrl30.L1D1cache.m_demand_misses / system.ruby.cp_cntrl30.L1D1cache.m_demand_accesses   0.3796%
  • system.ruby.cp_cntrl30.L1Icache.m_demand_misses / system.ruby.cp_cntrl30.L1Icache.m_demand_accesses   5.0913%
  • system.ruby.cp_cntrl30.L2cache.m_demand_misses / system.ruby.cp_cntrl30.L2cache.m_demand_accesses   0.7514%
  • system.ruby.cp_cntrl31.L1D0cache.m_demand_misses / system.ruby.cp_cntrl31.L1D0cache.m_demand_accesses   0.4199%
  • system.ruby.cp_cntrl31.L1D1cache.m_demand_misses / system.ruby.cp_cntrl31.L1D1cache.m_demand_accesses   0.4201%
  • system.ruby.cp_cntrl31.L1Icache.m_demand_misses / system.ruby.cp_cntrl31.L1Icache.m_demand_accesses   2.6459%
  • system.ruby.cp_cntrl31.L2cache.m_demand_misses / system.ruby.cp_cntrl31.L2cache.m_demand_accesses   0.9538%
  • system.ruby.cp_cntrl32.L1D0cache.m_demand_misses / system.ruby.cp_cntrl32.L1D0cache.m_demand_accesses   0.4692%
  • system.ruby.cp_cntrl32.L1D1cache.m_demand_misses / system.ruby.cp_cntrl32.L1D1cache.m_demand_accesses   0.4776%
  • system.ruby.cp_cntrl32.L1Icache.m_demand_misses / system.ruby.cp_cntrl32.L1Icache.m_demand_accesses   2.6531%
  • system.ruby.cp_cntrl32.L2cache.m_demand_misses / system.ruby.cp_cntrl32.L2cache.m_demand_accesses   1.0770%
  • system.ruby.cp_cntrl33.L1D0cache.m_demand_misses / system.ruby.cp_cntrl33.L1D0cache.m_demand_accesses   0.5317%
  • system.ruby.cp_cntrl33.L1D1cache.m_demand_misses / system.ruby.cp_cntrl33.L1D1cache.m_demand_accesses   0.5593%
  • system.ruby.cp_cntrl33.L1Icache.m_demand_misses / system.ruby.cp_cntrl33.L1Icache.m_demand_accesses   2.6718%
  • system.ruby.cp_cntrl33.L2cache.m_demand_misses / system.ruby.cp_cntrl33.L2cache.m_demand_accesses   1.2324%
  • system.ruby.cp_cntrl34.L1D0cache.m_demand_misses / system.ruby.cp_cntrl34.L1D0cache.m_demand_accesses   0.6249%
  • system.ruby.cp_cntrl34.L1D1cache.m_demand_misses / system.ruby.cp_cntrl34.L1D1cache.m_demand_accesses   0.6545%
  • system.ruby.cp_cntrl34.L1Icache.m_demand_misses / system.ruby.cp_cntrl34.L1Icache.m_demand_accesses   2.6880%
  • system.ruby.cp_cntrl34.L2cache.m_demand_misses / system.ruby.cp_cntrl34.L2cache.m_demand_accesses   1.4539%
  • system.ruby.cp_cntrl35.L1D0cache.m_demand_misses / system.ruby.cp_cntrl35.L1D0cache.m_demand_accesses   0.7467%
  • system.ruby.cp_cntrl35.L1D1cache.m_demand_misses / system.ruby.cp_cntrl35.L1D1cache.m_demand_accesses   0.7955%
  • system.ruby.cp_cntrl35.L1Icache.m_demand_misses / system.ruby.cp_cntrl35.L1Icache.m_demand_accesses   2.7191%
  • system.ruby.cp_cntrl35.L2cache.m_demand_misses / system.ruby.cp_cntrl35.L2cache.m_demand_accesses   1.7406%
  • system.ruby.cp_cntrl36.L1D0cache.m_demand_misses / system.ruby.cp_cntrl36.L1D0cache.m_demand_accesses   0.9283%
  • system.ruby.cp_cntrl36.L1D1cache.m_demand_misses / system.ruby.cp_cntrl36.L1D1cache.m_demand_accesses   1.0038%
  • system.ruby.cp_cntrl36.L1Icache.m_demand_misses / system.ruby.cp_cntrl36.L1Icache.m_demand_accesses   2.7484%
  • system.ruby.cp_cntrl36.L2cache.m_demand_misses / system.ruby.cp_cntrl36.L2cache.m_demand_accesses   2.1880%
  • system.ruby.cp_cntrl37.L1D0cache.m_demand_misses / system.ruby.cp_cntrl37.L1D0cache.m_demand_accesses   1.2776%
  • system.ruby.cp_cntrl37.L1D1cache.m_demand_misses / system.ruby.cp_cntrl37.L1D1cache.m_demand_accesses   1.4706%
  • system.ruby.cp_cntrl37.L1Icache.m_demand_misses / system.ruby.cp_cntrl37.L1Icache.m_demand_accesses   2.8367%
  • system.ruby.cp_cntrl37.L2cache.m_demand_misses / system.ruby.cp_cntrl37.L2cache.m_demand_accesses   3.0729%
  • system.ruby.cp_cntrl38.L1D0cache.m_demand_misses / system.ruby.cp_cntrl38.L1D0cache.m_demand_accesses   1.9018%
  • system.ruby.cp_cntrl38.L1D1cache.m_demand_misses / system.ruby.cp_cntrl38.L1D1cache.m_demand_accesses   2.3603%
  • system.ruby.cp_cntrl38.L1Icache.m_demand_misses / system.ruby.cp_cntrl38.L1Icache.m_demand_accesses   2.9636%
  • system.ruby.cp_cntrl38.L2cache.m_demand_misses / system.ruby.cp_cntrl38.L2cache.m_demand_accesses   4.6585%
  • system.ruby.cp_cntrl39.L1D0cache.m_demand_misses / system.ruby.cp_cntrl39.L1D0cache.m_demand_accesses   4.2674%
  • system.ruby.cp_cntrl39.L1D1cache.m_demand_misses / system.ruby.cp_cntrl39.L1D1cache.m_demand_accesses   8.5714%
  • system.ruby.cp_cntrl39.L1Icache.m_demand_misses / system.ruby.cp_cntrl39.L1Icache.m_demand_accesses   3.7066%
  • system.ruby.cp_cntrl39.L2cache.m_demand_misses / system.ruby.cp_cntrl39.L2cache.m_demand_accesses  11.8848%
  • system.ruby.cp_cntrl4.L1D0cache.m_demand_misses / system.ruby.cp_cntrl4.L1D0cache.m_demand_accesses   0.1458%
  • system.ruby.cp_cntrl4.L1D1cache.m_demand_misses / system.ruby.cp_cntrl4.L1D1cache.m_demand_accesses   0.1437%
  • system.ruby.cp_cntrl4.L1Icache.m_demand_misses / system.ruby.cp_cntrl4.L1Icache.m_demand_accesses   2.5832%
  • system.ruby.cp_cntrl4.L2cache.m_demand_misses / system.ruby.cp_cntrl4.L2cache.m_demand_accesses   0.3255%
  • system.ruby.cp_cntrl5.L1D0cache.m_demand_misses / system.ruby.cp_cntrl5.L1D0cache.m_demand_accesses   0.1496%
  • system.ruby.cp_cntrl5.L1D1cache.m_demand_misses / system.ruby.cp_cntrl5.L1D1cache.m_demand_accesses   0.1477%
  • system.ruby.cp_cntrl5.L1Icache.m_demand_misses / system.ruby.cp_cntrl5.L1Icache.m_demand_accesses   2.5851%
  • system.ruby.cp_cntrl5.L2cache.m_demand_misses / system.ruby.cp_cntrl5.L2cache.m_demand_accesses   0.3360%
  • system.ruby.cp_cntrl6.L1D0cache.m_demand_misses / system.ruby.cp_cntrl6.L1D0cache.m_demand_accesses   0.1096%
  • system.ruby.cp_cntrl6.L1D1cache.m_demand_misses / system.ruby.cp_cntrl6.L1D1cache.m_demand_accesses   0.1074%
  • system.ruby.cp_cntrl6.L1Icache.m_demand_misses / system.ruby.cp_cntrl6.L1Icache.m_demand_accesses   2.5848%
  • system.ruby.cp_cntrl6.L2cache.m_demand_misses / system.ruby.cp_cntrl6.L2cache.m_demand_accesses   0.2475%
  • system.ruby.cp_cntrl7.L1D0cache.m_demand_misses / system.ruby.cp_cntrl7.L1D0cache.m_demand_accesses   0.1141%
  • system.ruby.cp_cntrl7.L1D1cache.m_demand_misses / system.ruby.cp_cntrl7.L1D1cache.m_demand_accesses   0.1116%
  • system.ruby.cp_cntrl7.L1Icache.m_demand_misses / system.ruby.cp_cntrl7.L1Icache.m_demand_accesses   2.5863%
  • system.ruby.cp_cntrl7.L2cache.m_demand_misses / system.ruby.cp_cntrl7.L2cache.m_demand_accesses   0.2580%
  • system.ruby.cp_cntrl8.L1D0cache.m_demand_misses / system.ruby.cp_cntrl8.L1D0cache.m_demand_accesses   0.1172%
  • system.ruby.cp_cntrl8.L1D1cache.m_demand_misses / system.ruby.cp_cntrl8.L1D1cache.m_demand_accesses   0.1136%
  • system.ruby.cp_cntrl8.L1Icache.m_demand_misses / system.ruby.cp_cntrl8.L1Icache.m_demand_accesses   2.5857%
  • system.ruby.cp_cntrl8.L2cache.m_demand_misses / system.ruby.cp_cntrl8.L2cache.m_demand_accesses   0.2637%
  • system.ruby.cp_cntrl9.L1D0cache.m_demand_misses / system.ruby.cp_cntrl9.L1D0cache.m_demand_accesses   0.1208%
  • system.ruby.cp_cntrl9.L1D1cache.m_demand_misses / system.ruby.cp_cntrl9.L1D1cache.m_demand_accesses   0.1176%
  • system.ruby.cp_cntrl9.L1Icache.m_demand_misses / system.ruby.cp_cntrl9.L1Icache.m_demand_accesses   2.5874%
  • system.ruby.cp_cntrl9.L2cache.m_demand_misses / system.ruby.cp_cntrl9.L2cache.m_demand_accesses   0.2752%
  • system.ruby.dir_cntrl0.L3CacheMemory.m_demand_misses / system.ruby.dir_cntrl0.L3CacheMemory.m_demand_accesses   0.2103%
  • system.ruby.scalar_cntrl0.L1cache.m_demand_misses / system.ruby.scalar_cntrl0.L1cache.m_demand_accesses  21.8235%
  • system.ruby.scalar_cntrl1.L1cache.m_demand_misses / system.ruby.scalar_cntrl1.L1cache.m_demand_accesses  24.9230%
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
  • system.ruby.scalar_cntrl5.L1cache.m_demand_misses / system.ruby.scalar_cntrl5.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl6.L1cache.m_demand_misses / system.ruby.scalar_cntrl6.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl7.L1cache.m_demand_misses / system.ruby.scalar_cntrl7.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl8.L1cache.m_demand_misses / system.ruby.scalar_cntrl8.L1cache.m_demand_accesses  25.0000%
  • system.ruby.scalar_cntrl9.L1cache.m_demand_misses / system.ruby.scalar_cntrl9.L1cache.m_demand_accesses  25.0000%
  • system.ruby.sqc_cntrl0.L1cache.m_demand_misses / system.ruby.sqc_cntrl0.L1cache.m_demand_accesses   0.2202%
  • system.ruby.sqc_cntrl1.L1cache.m_demand_misses / system.ruby.sqc_cntrl1.L1cache.m_demand_accesses   0.1936%
  • system.ruby.sqc_cntrl10.L1cache.m_demand_misses / system.ruby.sqc_cntrl10.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl11.L1cache.m_demand_misses / system.ruby.sqc_cntrl11.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl12.L1cache.m_demand_misses / system.ruby.sqc_cntrl12.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl13.L1cache.m_demand_misses / system.ruby.sqc_cntrl13.L1cache.m_demand_accesses   6.9767%
  • system.ruby.sqc_cntrl14.L1cache.m_demand_misses / system.ruby.sqc_cntrl14.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl15.L1cache.m_demand_misses / system.ruby.sqc_cntrl15.L1cache.m_demand_accesses   5.5901%
  • system.ruby.sqc_cntrl16.L1cache.m_demand_misses / system.ruby.sqc_cntrl16.L1cache.m_demand_accesses   7.6923%
  • system.ruby.sqc_cntrl17.L1cache.m_demand_misses / system.ruby.sqc_cntrl17.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl18.L1cache.m_demand_misses / system.ruby.sqc_cntrl18.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl19.L1cache.m_demand_misses / system.ruby.sqc_cntrl19.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl2.L1cache.m_demand_misses / system.ruby.sqc_cntrl2.L1cache.m_demand_accesses   5.8065%
  • system.ruby.sqc_cntrl20.L1cache.m_demand_misses / system.ruby.sqc_cntrl20.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl21.L1cache.m_demand_misses / system.ruby.sqc_cntrl21.L1cache.m_demand_accesses   6.2937%
  • system.ruby.sqc_cntrl22.L1cache.m_demand_misses / system.ruby.sqc_cntrl22.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl23.L1cache.m_demand_misses / system.ruby.sqc_cntrl23.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl24.L1cache.m_demand_misses / system.ruby.sqc_cntrl24.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl25.L1cache.m_demand_misses / system.ruby.sqc_cntrl25.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl26.L1cache.m_demand_misses / system.ruby.sqc_cntrl26.L1cache.m_demand_accesses   5.8065%
  • system.ruby.sqc_cntrl27.L1cache.m_demand_misses / system.ruby.sqc_cntrl27.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl28.L1cache.m_demand_misses / system.ruby.sqc_cntrl28.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl29.L1cache.m_demand_misses / system.ruby.sqc_cntrl29.L1cache.m_demand_accesses   5.0847%
  • system.ruby.sqc_cntrl3.L1cache.m_demand_misses / system.ruby.sqc_cntrl3.L1cache.m_demand_accesses   5.2941%
  • system.ruby.sqc_cntrl30.L1cache.m_demand_misses / system.ruby.sqc_cntrl30.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl31.L1cache.m_demand_misses / system.ruby.sqc_cntrl31.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl32.L1cache.m_demand_misses / system.ruby.sqc_cntrl32.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl33.L1cache.m_demand_misses / system.ruby.sqc_cntrl33.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl34.L1cache.m_demand_misses / system.ruby.sqc_cntrl34.L1cache.m_demand_accesses   5.4545%
  • system.ruby.sqc_cntrl35.L1cache.m_demand_misses / system.ruby.sqc_cntrl35.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl36.L1cache.m_demand_misses / system.ruby.sqc_cntrl36.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl37.L1cache.m_demand_misses / system.ruby.sqc_cntrl37.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl38.L1cache.m_demand_misses / system.ruby.sqc_cntrl38.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl39.L1cache.m_demand_misses / system.ruby.sqc_cntrl39.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl4.L1cache.m_demand_misses / system.ruby.sqc_cntrl4.L1cache.m_demand_accesses   5.7692%
  • system.ruby.sqc_cntrl5.L1cache.m_demand_misses / system.ruby.sqc_cntrl5.L1cache.m_demand_accesses   6.0000%
  • system.ruby.sqc_cntrl6.L1cache.m_demand_misses / system.ruby.sqc_cntrl6.L1cache.m_demand_accesses   6.2500%
  • system.ruby.sqc_cntrl7.L1cache.m_demand_misses / system.ruby.sqc_cntrl7.L1cache.m_demand_accesses   5.2632%
  • system.ruby.sqc_cntrl8.L1cache.m_demand_misses / system.ruby.sqc_cntrl8.L1cache.m_demand_accesses   7.3171%
  • system.ruby.sqc_cntrl9.L1cache.m_demand_misses / system.ruby.sqc_cntrl9.L1cache.m_demand_accesses   5.2632%
  • system.ruby.tcc_cntrl0.L2cache.m_demand_misses / system.ruby.tcc_cntrl0.L2cache.m_demand_accesses  41.8119%
  • system.ruby.tcp_cntrl0.L1cache.m_demand_misses / system.ruby.tcp_cntrl0.L1cache.m_demand_accesses  16.6994%
  • system.ruby.tcp_cntrl1.L1cache.m_demand_misses / system.ruby.tcp_cntrl1.L1cache.m_demand_accesses  19.0118%
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
  • system.ruby.tcp_cntrl17.L1cache.m_demand_misses / system.ruby.tcp_cntrl17.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl18.L1cache.m_demand_misses / system.ruby.tcp_cntrl18.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl19.L1cache.m_demand_misses / system.ruby.tcp_cntrl19.L1cache.m_demand_accesses  28.2609%
  • system.ruby.tcp_cntrl2.L1cache.m_demand_misses / system.ruby.tcp_cntrl2.L1cache.m_demand_accesses  16.4681%
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
  • system.ruby.tcp_cntrl3.L1cache.m_demand_misses / system.ruby.tcp_cntrl3.L1cache.m_demand_accesses  17.0431%
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
  • system.ruby.tcp_cntrl4.L1cache.m_demand_misses / system.ruby.tcp_cntrl4.L1cache.m_demand_accesses  15.1928%
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
  • system.ruby.tcp_cntrl5.L1cache.m_demand_misses / system.ruby.tcp_cntrl5.L1cache.m_demand_accesses  15.5789%
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
  • system.ruby.tcp_cntrl6.L1cache.m_demand_misses / system.ruby.tcp_cntrl6.L1cache.m_demand_accesses  15.4534%
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
  • system.ruby.tcp_cntrl7.L1cache.m_demand_misses / system.ruby.tcp_cntrl7.L1cache.m_demand_accesses  15.6128%
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
  notes: 所有 cpu/cu ipc 均非 0/NaN 且数量达标（cpu=80, cu=160, total=240）
  evidence: stats.txt: system.cpu0.ipc=0.034479
  evidence: stats.txt: system.cpu1.ipc=0.000003
  evidence: stats.txt: system.cpu10.ipc=0.000075
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
