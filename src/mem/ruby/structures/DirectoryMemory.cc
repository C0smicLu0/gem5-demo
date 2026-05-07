#include "mem/ruby/structures/DirectoryMemory.hh"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iomanip>

#include "base/addr_range.hh"
#include "base/intmath.hh"
#include "base/logging.hh"
#include "base/output.hh"
#include "debug/RubyCache.hh"
#include "debug/RubyStats.hh"
#include "mem/ruby/network/Network.hh"
#include "mem/ruby/slicc_interface/RubySlicc_Util.hh"
#include "mem/ruby/system/RubySystem.hh"
#include "sim/system.hh"

namespace gem5
{

namespace ruby
{

// 多粒度影子目录统计（MgStats）
// 这部分统计有两条输出路径：
//    通过 gem5 的 stats 系统输出到默认的 stats.txt
//    另外在 simout 下创建一个按粒度命名的子目录（如 mg-64B-1KiB）
DirectoryMemory::MgStats::MgStats(statistics::Group *parent)
    : statistics::Group(parent, "mg"),
        ADD_STAT(obs_shared, "mg: observed shared reads"),
        ADD_STAT(obs_exclusive, "mg: observed exclusive requests"),
        ADD_STAT(obs_eviction, "mg: observed evictions"),
        ADD_STAT(obs_total, "mg: observed requests total"),
        ADD_STAT(split_attempts, "mg: split attempts on private conflict"),
        ADD_STAT(split_actual, "mg: actual splits (parent size > min)"),
        ADD_STAT(merge_attempts, "mg: merge attempts"),
        ADD_STAT(merge_success, "mg: merge successes"),
        ADD_STAT(alloc_new, "mg: new entry allocations"),
        ADD_STAT(alloc_fail, "mg: failed allocations (no grain fits)"),
        ADD_STAT(block_state_live, "mg: live block-state entries"),
        ADD_STAT(req_unknown_type, "mg: requests with unknown MachineType"),
        ADD_STAT(private_break_cpu_owner_gpu_req, "mg: CPU private broken by GPU"),
        ADD_STAT(private_break_gpu_owner_cpu_req, "mg: GPU private broken by CPU"),
        ADD_STAT(private_break_cpu_owner_cpu_req, "mg: CPU private broken by CPU"),
        ADD_STAT(private_break_gpu_owner_gpu_req, "mg: GPU private broken by GPU"),
        ADD_STAT(private_break_unknown, "mg: private breaks with unknown type"),
        ADD_STAT(obs_shared_by_type, "mg: observed shared reads by MachineType"),
        ADD_STAT(obs_exclusive_by_type, "mg: observed exclusive by MachineType"),
        ADD_STAT(obs_eviction_by_type, "mg: observed evictions by MachineType"),
        ADD_STAT(grain_entry_live, "mg: live entries by grain"),
        ADD_STAT(grain_alloc_new, "mg: new allocations by grain"),
        ADD_STAT(grain_split_parent, "mg: split parent size by grain"),
        ADD_STAT(grain_merge_success, "mg: merge success by grain"),
        ADD_STAT(grain_private_break_cpu_owner_gpu_req, "mg: CPU private broken by GPU (by grain)"),
        ADD_STAT(grain_private_break_gpu_owner_cpu_req, "mg: GPU private broken by CPU (by grain)"),
        ADD_STAT(grain_live_coverage_bytes, "mg: live coverage bytes by grain"),
        ADD_STAT(grain_live_coverage_ratio_ppm, "mg: live coverage ratio (ppm) by grain"),
        ADD_STAT(live_entry_total, "mg: live entry total"),
        ADD_STAT(live_coverage_total_bytes, "mg: live coverage bytes total"),
        ADD_STAT(eff_bytes_per_entry, "mg: effective bytes per entry"),
        ADD_STAT(avg_grain_size_weighted_by_entries, "mg: avg grain size weighted by entries"),
        ADD_STAT(min_grain_coverage_ratio_ppm, "mg: min grain coverage ratio (ppm)"),
        ADD_STAT(entry_churn_total, "mg: entry churn total"),
        ADD_STAT(entry_churn_alloc, "mg: entry churn caused by alloc"),
        ADD_STAT(entry_churn_split, "mg: entry churn caused by split"),
        ADD_STAT(entry_churn_merge, "mg: entry churn caused by merge"),
        ADD_STAT(entry_churn_eviction, "mg: entry churn caused by eviction"),
        ADD_STAT(churn_alloc_by_grain, "mg: churn alloc by grain"),
        ADD_STAT(churn_eviction_by_grain, "mg: churn eviction by grain"),
        ADD_STAT(split_transition_by_grain, "mg: split transitions by grain"),
        ADD_STAT(merge_transition_by_grain, "mg: merge transitions by grain"),
        ADD_STAT(entry_churn_per_1k_obs, "mg: entry churn per 1k observed requests"),
        ADD_STAT(split_actual_per_1k_obs, "mg: split actual per 1k observed requests"),
        ADD_STAT(merge_success_per_1k_obs, "mg: merge success per 1k observed requests"),
        ADD_STAT(dir_probe_msgs_sg, "traffic: directory probe messages (single-gran real)"),
        ADD_STAT(dir_probe_bytes_sg, "traffic: directory probe bytes (single-gran real)"),
        ADD_STAT(dir_probe_msgs_mg_est, "traffic: directory probe messages (multi-gran estimated)"),
        ADD_STAT(dir_probe_bytes_mg_est, "traffic: directory probe bytes (multi-gran estimated)"),
        ADD_STAT(dir_response_msgs_sg, "traffic: directory response messages"),
        ADD_STAT(dir_response_bytes_sg, "traffic: directory response bytes"),
        ADD_STAT(dir_mem_msgs_sg, "traffic: directory->memory messages"),
        ADD_STAT(dir_mem_bytes_sg, "traffic: directory->memory bytes"),
        ADD_STAT(dir_trigger_msgs_sg, "traffic: directory trigger messages"),
        ADD_STAT(dir_trigger_bytes_sg, "traffic: directory trigger bytes"),
        ADD_STAT(dir_total_msgs_sg, "traffic: total directory coherence messages (single-gran real)"),
        ADD_STAT(dir_total_bytes_sg, "traffic: total directory coherence bytes (single-gran real)"),
        ADD_STAT(dir_total_msgs_mg_est, "traffic: total directory coherence messages (multi-gran estimated)"),
        ADD_STAT(dir_total_bytes_mg_est, "traffic: total directory coherence bytes (multi-gran estimated)"),
        ADD_STAT(probe_msg_reduction_est, "traffic: estimated probe message reduction (SG - MG_est)"),
        ADD_STAT(probe_byte_reduction_est, "traffic: estimated probe byte reduction (SG - MG_est)"),
        ADD_STAT(sharer_count_total, "mg: total sharer count across shared samples"),
        ADD_STAT(sharer_count_samples, "mg: number of sharer distribution samples"),
        ADD_STAT(sharer_count_avg, "mg: average sharer count across shared samples"),
        ADD_STAT(sharer_count_max, "mg: max sharer count across shared samples"),
        ADD_STAT(sharer_count_hist, "mg: sharer count histogram"),
        ADD_STAT(probe_hit_by_grain, "mg: probe hit entry grain distribution"),
        ADD_STAT(custom_parent_shared_hit, "mg: custom retained-parent lookups observing shared state"),
        ADD_STAT(custom_parent_shared_est_total, "mg: estimated fanout sum on custom retained shared parent hits"),
        ADD_STAT(custom_parent_shared_est_by_grain, "mg: estimated fanout on custom retained shared parent hits by grain"),

        ADD_STAT(trace_split_events, "mg: traced split events"),
        ADD_STAT(trace_merge_events, "mg: traced merge events"),
        ADD_STAT(trace_eviction_events, "mg: traced eviction events")
{
    // 以 MachineType 为维度的统计（下标直接对应 MachineType 枚举值）
    obs_shared_by_type.init(MachineType_NUM);
    obs_exclusive_by_type.init(MachineType_NUM);
    obs_eviction_by_type.init(MachineType_NUM);

    for (int i = 0; i < MachineType_NUM; ++i) {
        const auto name = MachineType_to_string(
            static_cast<MachineType>(i));
        obs_shared_by_type.subname(i, name);
        obs_exclusive_by_type.subname(i, name);
        obs_eviction_by_type.subname(i, name);
    }
}

// 初始化所有按粒度统计的 statistics::Vector
void
DirectoryMemory::MgStats::initGrains(const std::vector<uint32_t> &grains)
{
    const size_t stat_count = std::max<size_t>(1, grains.size());
    const size_t pair_count = std::max<size_t>(1, grains.size() * grains.size());

    // 以粒度集合为维度的统计
    grain_entry_live.init(stat_count);
    grain_alloc_new.init(stat_count);
    grain_split_parent.init(stat_count);
    grain_merge_success.init(stat_count);
    grain_private_break_cpu_owner_gpu_req.init(stat_count);
    grain_private_break_gpu_owner_cpu_req.init(stat_count);
    grain_live_coverage_bytes.init(stat_count);
    grain_live_coverage_ratio_ppm.init(stat_count);
    churn_alloc_by_grain.init(stat_count);
    churn_eviction_by_grain.init(stat_count);
    sharer_count_hist.init(16);
    probe_hit_by_grain.init(stat_count);
    custom_parent_shared_est_by_grain.init(stat_count);
    split_transition_by_grain.init(pair_count);
    merge_transition_by_grain.init(pair_count);

    for (size_t i = 0; i < 16; ++i) {
        sharer_count_hist.subname(i, std::to_string(i) + "_sharers");
    }

    if (grains.empty()) {
        const std::string label = "disabled";
        grain_entry_live.subname(0, label);
        grain_alloc_new.subname(0, label);
        grain_split_parent.subname(0, label);
        grain_merge_success.subname(0, label);
        grain_private_break_cpu_owner_gpu_req.subname(0, label);
        grain_private_break_gpu_owner_cpu_req.subname(0, label);
        grain_live_coverage_bytes.subname(0, label);
        grain_live_coverage_ratio_ppm.subname(0, label);
        churn_alloc_by_grain.subname(0, label);
        churn_eviction_by_grain.subname(0, label);
        probe_hit_by_grain.subname(0, label);
        custom_parent_shared_est_by_grain.subname(0, label);
        split_transition_by_grain.subname(0, label);
        merge_transition_by_grain.subname(0, label);
        return;
    }

    for (size_t i = 0; i < grains.size(); ++i) {
        // 设置每一列的名字，便于阅读（例如 64B/1024B）
        const std::string label = std::to_string(grains[i]) + "B";
        grain_entry_live.subname(i, label);
        grain_alloc_new.subname(i, label);
        grain_split_parent.subname(i, label);
        grain_merge_success.subname(i, label);
        grain_private_break_cpu_owner_gpu_req.subname(i, label);
        grain_private_break_gpu_owner_cpu_req.subname(i, label);
        grain_live_coverage_bytes.subname(i, label);
        grain_live_coverage_ratio_ppm.subname(i, label);
        churn_alloc_by_grain.subname(i, label);
        churn_eviction_by_grain.subname(i, label);
        probe_hit_by_grain.subname(i, label);
        custom_parent_shared_est_by_grain.subname(i, label);
    }

    // 生成 N×N 的粒度转移标签（from -> to）
    for (size_t i = 0; i < grains.size(); ++i) {
        const std::string from_label = std::to_string(grains[i]) + "B";
        for (size_t j = 0; j < grains.size(); ++j) {
            const std::string to_label = std::to_string(grains[j]) + "B";
            const std::string pair_label = from_label + "->" + to_label;
            const size_t idx = i * grains.size() + j;
            split_transition_by_grain.subname(idx, pair_label);
            merge_transition_by_grain.subname(idx, pair_label);
        }
    }
}

DirectoryMemory::DirectoryMemory(const Params &p)
    : SimObject(p), addrRanges(p.addr_ranges.begin(), p.addr_ranges.end())
    , mg_enable(p.mg_enable), mg_region_grains(p.mg_region_grains)
	    , mg_policy(
	        p.mg_policy == "ideal" ? MgPolicy::Ideal :
	        p.mg_policy == "custom" ? MgPolicy::Custom :
	        p.mg_policy == "acg" ? MgPolicy::Acg :
	        p.mg_policy == "baseline" ? MgPolicy::Baseline :
	        p.mg_policy == "profile" ? MgPolicy::Profile :
	        (fatal("Unknown mg_policy '%s' (expected ideal/custom/acg/baseline/profile)",
	               p.mg_policy), MgPolicy::Ideal))
    , mg_profile_thresholds(p.mg_profile_thresholds)
	    , mg_shatter_threshold(p.mg_shatter_threshold)
    , mgStats(this)
{
    m_size_bytes = 0;
    for (const auto &r: addrRanges) {
        m_size_bytes += r.size();
    }
    m_size_bits = floorLog2(m_size_bytes);
    m_num_entries = 0;
    m_block_size = p.block_size;
    m_ruby_system = p.ruby_system;

    // Even when multi-granularity metadata is disabled, the vector stats are
    // still registered in the stats database. Initialize them to zero length
    // so stats dumping does not fatal on uninitialized vectors.
    if (!mgEnabled()) {
        mgStats.initGrains({});
    }
}

const char *
// 返回当前影子目录策略名称，用于输出目录和摘要文件标识。
DirectoryMemory::mgPolicyName() const
{
    switch (mg_policy) {
      case MgPolicy::Custom:
        return "custom";
      case MgPolicy::Acg:
        return "acg";
	      case MgPolicy::Baseline:
	        return "baseline";
	      case MgPolicy::Profile:
	        return "profile";
	      default:
	        return "ideal";
	    }
}

void
// 校验 custom 模式下的粒度集合是否满足通用可配置链的基本要求。
DirectoryMemory::mgValidateCustomGrains(const std::vector<uint32_t> &grains) const
{
    fatal_if(grains.empty(),
             "Custom mg_policy requires at least one configured grain");
    fatal_if(grains.front() != m_block_size,
             "Custom mg_policy requires the minimum grain to be exactly %uB",
             m_block_size);
}

void
// 校验 ACG 模式下的粒度集合是否正好等于固定链。
DirectoryMemory::mgValidateAcgGrains(const std::vector<uint32_t> &grains) const
{
    static const std::vector<uint32_t> expected =
        {64, 128, 256, 512, 1024, 2048, 4096};
    fatal_if(grains != expected,
             "ACG mg_policy requires dir-region-grains to be exactly "
             "64B,128B,256B,512B,1KiB,2KiB,4KiB; got a different set");
}

void
// 校验 baseline 模式下只允许单一的 64B 粒度。
DirectoryMemory::mgValidateBaselineGrains(const std::vector<uint32_t> &grains) const
{
    static const std::vector<uint32_t> expected = {64};
    fatal_if(grains != expected,
             "Baseline mg_policy requires dir-region-grains to be exactly "
             "64B; got a different set");
}

uint32_t
// 返回 custom 当前配置链中当前粒度的下一层更细粒度。
DirectoryMemory::mgCustomNextSmallerSize(uint32_t size) const
{
    return mgNextSmallerSize(size);
}

uint32_t
// 返回当前父粒度在 custom 当前配置链下包含的直接子区个数。
DirectoryMemory::mgCustomChildCount(uint32_t size) const
{
    const uint32_t child = mgCustomNextSmallerSize(size);
    return child ? (size / child) : 0;
}

uint32_t
// 根据访问 block 地址计算其落入父条目的哪一个直接子区。
DirectoryMemory::mgCustomChildIndex(const MgEntry &entry, Addr block_base) const
{
    const uint32_t child_size = mgCustomNextSmallerSize(entry.size);
    fatal_if(child_size == 0, "No custom child size for grain %u", entry.size);
    const Addr child_base = mgRegionBase(block_base, child_size);
    fatal_if(child_base < entry.base || child_base >= (entry.base + entry.size),
             "Address %#x does not fall inside parent [%#x, %#x)",
             block_base, entry.base, entry.base + entry.size);
    return static_cast<uint32_t>((child_base - entry.base) / child_size);
}

Addr
// 根据父条目和子区编号计算该直接子区的起始地址。
DirectoryMemory::mgCustomChildBase(const MgEntry &entry, uint32_t child_idx) const
{
    const uint32_t child_size = mgCustomNextSmallerSize(entry.size);
    fatal_if(child_size == 0, "No custom child size for grain %u", entry.size);
    fatal_if(child_idx >= mgCustomChildCount(entry.size),
             "Child index %u out of range for parent grain %u",
             child_idx, entry.size);
    return entry.base + static_cast<Addr>(child_idx) * child_size;
}

bool
// 判断父条目指定子区是否已经被 delegated 到更细粒度条目。
DirectoryMemory::mgIsChildDelegated(const MgEntry &entry, uint32_t child_idx) const
{
    const size_t word_idx = child_idx / 64;
    if (word_idx >= entry.delegated_mask.size()) {
        return false;
    }
    const uint64_t bit = uint64_t(1) << (child_idx % 64);
    return (entry.delegated_mask[word_idx] & bit) != 0;
}

void
// 设置或清除父条目中某个直接子区的 delegated 标记位。
DirectoryMemory::mgSetChildDelegated(MgEntry &entry, uint32_t child_idx,
                                     bool delegated)
{
    const size_t word_idx = child_idx / 64;
    const uint64_t bit = uint64_t(1) << (child_idx % 64);
    if (delegated) {
        if (entry.delegated_mask.size() <= word_idx) {
            entry.delegated_mask.resize(word_idx + 1, 0);
        }
        entry.delegated_mask[word_idx] |= bit;
    } else {
        if (word_idx >= entry.delegated_mask.size()) {
            return;
        }
        entry.delegated_mask[word_idx] &= ~bit;
        while (!entry.delegated_mask.empty() &&
               entry.delegated_mask.back() == 0) {
            entry.delegated_mask.pop_back();
        }
    }
}

uint32_t
// 返回 ACG 固定链中当前粒度的下一层更粗粒度。
DirectoryMemory::mgAcgNextLargerSize(uint32_t size) const
{
    switch (size) {
      case 64: return 128;
      case 128: return 256;
      case 256: return 512;
      case 512: return 1024;
      case 1024: return 2048;
      case 2048: return 4096;
      default: return 0;
    }
}

Addr
// 计算 ACG buddy merge 后父粒度区域的对齐基地址。
DirectoryMemory::mgAcgMergedBase(Addr base, uint32_t size) const
{
    const uint32_t merged_size = mgAcgNextLargerSize(size);
    return merged_size ? mgRegionBase(base, merged_size) : 0;
}

Addr
// 计算当前条目在 ACG buddy merge 下的同粒度 buddy 基地址。
DirectoryMemory::mgAcgBuddyBase(Addr base, uint32_t size) const
{
    const Addr merged_base = mgAcgMergedBase(base, size);
    if (!merged_base) {
        return 0;
    }
    return (merged_base == base) ? (base + size) : merged_base;
}

bool
// 判断两个 ACG 同粒度条目是否满足 buddy 合并的精确条件。
DirectoryMemory::mgAcgCanMergePair(const MgEntry &a, const MgEntry &b) const
{
    if (a.size != b.size) {
        return false;
    }
    const uint32_t merged_size = mgAcgNextLargerSize(a.size);
    if (merged_size == 0) {
        return false;
    }
    const Addr merged_base = mgAcgMergedBase(a.base, a.size);
    if (!merged_base || !mgRegionFitsRanges(merged_base, merged_size)) {
        return false;
    }
    const Addr buddy_base = mgAcgBuddyBase(a.base, a.size);
    if (buddy_base != b.base) {
        return false;
    }
    // 影子目录当前没有 busy 位，这里按“都不忙”的近似来复现 ACG 的状态约束。
    return mgLineEqual(a.line, b.line);
}

DirectoryMemory::MgEntry *
// 按访问地址查找父条目已经下放出去的那个直接子条目。
DirectoryMemory::mgFindDelegatedChild(MgEntry &entry, Addr block_base)
{
    if (!mgUseCustomPolicy()) {
        return nullptr;
    }
    const uint32_t child_size = mgCustomNextSmallerSize(entry.size);
    if (child_size == 0) {
        return nullptr;
    }
    const uint32_t child_idx = mgCustomChildIndex(entry, block_base);
    if (!mgIsChildDelegated(entry, child_idx)) {
        return nullptr;
    }
    const Addr child_base = mgCustomChildBase(entry, child_idx);
    MgEntry *child = mgFindEntryAtSize(child_base, child_size);
    fatal_if(!child,
             "custom policy invariant broken: delegated child missing "
             "for parent base=%#x size=%u child_base=%#x child_size=%u",
             entry.base, entry.size, child_base, child_size);
    return child;
}

const DirectoryMemory::MgEntry *
// const 版本：按访问地址查找父条目已经下放出去的那个直接子条目。
DirectoryMemory::mgFindDelegatedChild(const MgEntry &entry, Addr block_base) const
{
    return const_cast<DirectoryMemory *>(this)->mgFindDelegatedChild(
        const_cast<MgEntry &>(entry), block_base);
}

bool
// 判断一个条目自身是否还持有更细一级 delegated 子区。
DirectoryMemory::mgEntryHasDelegatedChildren(const MgEntry &entry) const
{
    for (uint64_t word : entry.delegated_mask) {
        if (word != 0) {
            return true;
        }
    }
    return false;
}

bool
// 判断一个子条目是否已经满足被父条目精确吸回的条件。
DirectoryMemory::mgCanAbsorbChildIntoParent(const MgEntry &child,
                                            const MgEntry &parent) const
{
    if (!child.has_parent) {
        return false;
    }
    if (child.parent_base != parent.base || child.parent_size != parent.size) {
        return false;
    }
    if (mgEntryHasDelegatedChildren(child)) {
        return false;
    }
    return mgLineEqual(child.line, parent.line);
}

void
// 从当前子条目开始执行 custom 模式下的逐级局部回并。
DirectoryMemory::mgCustomTryMergeUp(MgEntry &entry)
{
    MgEntry *current = &entry;
    while (current && current->has_parent) {
        // 只做父子局部检查：先定位当前 child 对应的直接父条目
        MgEntry *parent = mgFindEntryAtSize(current->parent_base,
                                            current->parent_size);
        // 只有当 child 已经完整、且与 parent 语义完全一致时，才允许精确吸回。
        if (!parent || !mgCanAbsorbChildIntoParent(*current, *parent)) {
            return;
        }

        // 算出该 child 在父条目中的子区编号，后续需要清掉对应 delegated bit。
        const uint32_t child_idx = mgCustomChildIndex(*parent, current->base);
        const Addr child_base = current->base;
        const uint32_t child_size = current->size;

        MgTraceEntry trace;
        trace.op = MgTraceEntry::Op::Merge;
        trace.tick = curTick();
        trace.parent_base = parent->base;
        trace.parent_size = parent->size;
        trace.target_size = child_size;
        trace.conflict_block = 0;
        trace.requestor = MachineID();
        trace.owner = current->line.owner.value_or(MachineID());
        trace.want_excl = false;

        MgTraceEntry::ChildInfo ci;
        ci.base = child_base;
        ci.size = child_size;
        ci.is_conflict = false;
        ci.is_sparse_keep = false;
        ci.state = current->line.state;
        ci.owner = current->line.owner;
        trace.children.push_back(ci);

        // 真正执行吸回父条目：
        //   1. 清除父条目的 delegated 标记
        //   2. 删除当前 child entry
        mgSetChildDelegated(*parent, child_idx, false);
        mgEraseEntry(child_base, child_size, MgChurnCause::Merge);
        mgTraceLogMerge(trace);

        // 更新 merge 成功及 child -> parent 的粒度转移统计。
        mgStats.merge_success++;
        const size_t merge_idx = mgGrainIndex(parent->size);
        if (merge_idx != MgInvalidIndex) {
            mgStats.grain_merge_success[merge_idx]++;
        }

        const size_t fi = mgGrainIndex(child_size);
        const size_t ti = mgGrainIndex(parent->size);
        if (fi != MgInvalidIndex && ti != MgInvalidIndex) {
            const size_t n = mg_region_grains_asc.size();
            const size_t pair_idx = fi * n + ti;
            if (pair_idx < mgStats.merge_transition_by_grain.size()) {
                mgStats.merge_transition_by_grain[pair_idx]++;
            }
        }

        // 若父条目自身也有父条目，且此时已经重新满足回并条件，则继续逐级向上检查。
        current = parent;
    }
}

void
// 为 ACG 的 unmatched-type 冲突创建一个 64B 例外项，并保留原粗粒度父条目。
DirectoryMemory::mgAcgCreateBlockException(MgEntry &parent, Addr block_base,
                                           const MgLineInfo &child_line,
                                           MachineID requestor,
                                           std::optional<MachineID> trace_owner,
                                           bool want_excl,
                                           bool count_attempt,
                                           bool record_private_break)
{
    fatal_if(parent.size <= mg_min_region_grain,
             "ACG exception split requires a coarse parent; got size %u",
             parent.size);
    const Addr child_base = mgBlockBase(block_base);
    fatal_if(mgFindEntryAtSize(child_base, mg_min_region_grain),
             "ACG exception split would create duplicate 64B entry at %#x",
             child_base);

    if (count_attempt) {
        mgStats.split_attempts++;
    }
    if (record_private_break && trace_owner) {
        mgRecordPrivateBreak(*trace_owner, requestor, parent.size);
    }

    const size_t from_idx = mgGrainIndex(parent.size);
    const size_t to_idx = mgGrainIndex(mg_min_region_grain);
    if (from_idx != MgInvalidIndex && to_idx != MgInvalidIndex) {
        const size_t n = mg_region_grains_asc.size();
        const size_t pair_idx = from_idx * n + to_idx;
        if (pair_idx < mgStats.split_transition_by_grain.size()) {
            mgStats.split_transition_by_grain[pair_idx]++;
        }
    }
    mgStats.split_actual++;
    if (from_idx != MgInvalidIndex) {
        mgStats.grain_split_parent[from_idx]++;
    }

    MgEntry child;
    child.base = child_base;
    child.size = mg_min_region_grain;
    child.line = child_line;
    child.acg_exception = true;
    mgInsertEntry(child, MgChurnCause::Split);

    MgTraceEntry trace;
    trace.op = MgTraceEntry::Op::Split;
    trace.tick = curTick();
    trace.parent_base = parent.base;
    trace.parent_size = parent.size;
    trace.target_size = mg_min_region_grain;
    trace.conflict_block = child_base;
    trace.requestor = requestor;
    trace.owner = trace_owner.value_or(MachineID());
    trace.want_excl = want_excl;

    MgTraceEntry::ChildInfo ci;
    ci.base = child.base;
    ci.size = child.size;
    ci.is_conflict = true;
    ci.is_sparse_keep = false;
    ci.state = child.line.state;
    ci.owner = child.line.owner;
    trace.children.push_back(ci);
    mgTraceLogSplit(trace);

    // 如果该 block 的更细条目已经把某个更粗背景条目完全遮蔽，则直接删除该粗粒度条目。
    mgAcgPruneFullyShadowedParents(child_base, mg_min_region_grain,
                                   MgChurnCause::Split);
}

bool
// 判断某个 ACG 粗粒度条目是否已经被更细粒度条目完全遮蔽。
DirectoryMemory::mgAcgEntryFullyShadowedByFiner(const MgEntry &entry)
{
    if (!mgUseAcgPolicy() || entry.size <= mg_min_region_grain) {
        return false;
    }

    for (Addr blk = entry.base; blk < entry.base + entry.size; blk += m_block_size) {
        MgEntry *cover = mgFindEntry(blk);
        if (!cover || cover->size >= entry.size) {
            return false;
        }
    }
    return true;
}

void
// 沿更粗粒度方向清理已经被更细粒度条目完全遮蔽的 ACG 背景条目。
DirectoryMemory::mgAcgPruneFullyShadowedParents(Addr block_base,
                                                uint32_t finer_size,
                                                MgChurnCause cause)
{
    if (!mgUseAcgPolicy()) {
        return;
    }

    for (uint32_t size : mg_region_grains_asc) {
        if (size <= finer_size) {
            continue;
        }
        const Addr base = mgRegionBase(block_base, size);
        MgEntry *entry = mgFindEntryAtSize(base, size);
        if (!entry) {
            continue;
        }
        if (mgAcgEntryFullyShadowedByFiner(*entry)) {
            mgEraseEntry(base, size, cause);
        }
    }
}

void
// 从当前 ACG 条目出发，只检查它的 buddy，并在成功后继续逐级向上合并。
DirectoryMemory::mgAcgTryMergeUp(Addr base, uint32_t size)
{
    Addr current_base = base;
    uint32_t current_size = size;

    while (true) {
        MgEntry *current = mgFindEntryAtSize(current_base, current_size);
        if (!current) {
            return;
        }

        const uint32_t merged_size = mgAcgNextLargerSize(current_size);
        if (merged_size == 0) {
            return;
        }

        const Addr merged_base = mgAcgMergedBase(current_base, current_size);
        const Addr buddy_base = mgAcgBuddyBase(current_base, current_size);
        if (!merged_base || !buddy_base ||
            !mgRegionFitsRanges(merged_base, merged_size)) {
            return;
        }

        MgEntry *buddy = mgFindEntryAtSize(buddy_base, current_size);
        if (!buddy || !mgAcgCanMergePair(*current, *buddy)) {
            return;
        }

        const MgLineInfo merged_line = current->line;
        MgEntry *existing_parent = mgFindEntryAtSize(merged_base, merged_size);
        // 若目标父项已存在但语义不一致，则停止沿当前 buddy 链继续向上合并。
        if (existing_parent && !mgLineEqual(existing_parent->line, merged_line)) {
            return;
        }

        MgTraceEntry trace;
        trace.op = MgTraceEntry::Op::Merge;
        trace.tick = curTick();
        trace.parent_base = merged_base;
        trace.parent_size = merged_size;
        trace.target_size = current_size;
        trace.conflict_block = 0;
        trace.requestor = MachineID();
        trace.owner = current->line.owner.value_or(MachineID());
        trace.want_excl = false;

        for (Addr child_base : {current_base, buddy_base}) {
            MgTraceEntry::ChildInfo ci;
            ci.base = child_base;
            ci.size = current_size;
            ci.is_conflict = false;
            ci.is_sparse_keep = false;
            ci.state = current->line.state;
            ci.owner = current->line.owner;
            trace.children.push_back(ci);
        }

        mgEraseEntry(current_base, current_size, MgChurnCause::Merge);
        mgEraseEntry(buddy_base, current_size, MgChurnCause::Merge);

        if (!existing_parent) {
            MgEntry merged;
            merged.base = merged_base;
            merged.size = merged_size;
            merged.line = merged_line;
            mgInsertEntry(merged, MgChurnCause::Merge);
        }

        // merge 后如果更粗背景条目已被 finer 表示完全覆盖，则直接删除该背景条目。
        mgAcgPruneFullyShadowedParents(merged_base, merged_size,
                                       MgChurnCause::Merge);

        mgTraceLogMerge(trace);
        mgStats.merge_success++;

        const size_t from_idx = mgGrainIndex(current_size);
        const size_t to_idx = mgGrainIndex(merged_size);
        if (to_idx != MgInvalidIndex) {
            mgStats.grain_merge_success[to_idx]++;
        }
        if (from_idx != MgInvalidIndex && to_idx != MgInvalidIndex) {
            const size_t n = mg_region_grains_asc.size();
            const size_t pair_idx = from_idx * n + to_idx;
            if (pair_idx < mgStats.merge_transition_by_grain.size()) {
                mgStats.merge_transition_by_grain[pair_idx]++;
            }
        }

        // 当前这一层合并成功后，继续拿新形成的父条目向更高一层递归尝试。
        current_base = merged_base;
        current_size = merged_size;
    }
}

void
DirectoryMemory::init()
{
    m_num_entries = m_size_bytes / m_block_size;
    m_entries = new AbstractCacheEntry*[m_num_entries];
    for (int i = 0; i < m_num_entries; i++)
        m_entries[i] = NULL;

    mgInit();
}

DirectoryMemory::~DirectoryMemory()
{
    mgTraceFinalize();
    // free up all the directory entries
    for (uint64_t i = 0; i < m_num_entries; i++) {
        if (m_entries[i] != NULL) {
            delete m_entries[i];
        }
    }
    delete [] m_entries;
}

bool
DirectoryMemory::isPresent(Addr address)
{
    for (const auto& r: addrRanges) {
        if (r.contains(address)) {
            return true;
        }
    }
    return false;
}

uint64_t
DirectoryMemory::mapAddressToLocalIdx(Addr address)
{
    uint64_t ret = 0;
    for (const auto& r: addrRanges) {
        if (r.contains(address)) {
            ret += r.getOffset(address);
            break;
        }
        ret += r.size();
    }
    return ret >> (floorLog2(m_block_size));
}

AbstractCacheEntry*
DirectoryMemory::lookup(Addr address)
{
    assert(isPresent(address));
    DPRINTF(RubyCache, "Looking up address: %#x\n", address);

    uint64_t idx = mapAddressToLocalIdx(address);
    assert(idx < m_num_entries);
    return m_entries[idx];
}

AbstractCacheEntry*
DirectoryMemory::allocate(Addr address, AbstractCacheEntry *entry)
{
    assert(isPresent(address));
    uint64_t idx;
    DPRINTF(RubyCache, "Looking up address: %#x\n", address);

    idx = mapAddressToLocalIdx(address);
    assert(idx < m_num_entries);
    assert(m_entries[idx] == NULL);
    entry->changePermission(AccessPermission_Read_Only);
    entry->initBlockSize(m_block_size);
    entry->setRubySystem(m_ruby_system);
    m_entries[idx] = entry;

    return entry;
}

void
DirectoryMemory::deallocate(Addr address)
{
    assert(isPresent(address));
    uint64_t idx;
    DPRINTF(RubyCache, "Removing entry for address: %#x\n", address);

    idx = mapAddressToLocalIdx(address);
    assert(idx < m_num_entries);
    assert(m_entries[idx] != NULL);
    delete m_entries[idx];
    m_entries[idx] = NULL;
}

void
DirectoryMemory::print(std::ostream& out) const
{
}

void
DirectoryMemory::recordRequestType(DirectoryRequestType requestType) {
    DPRINTF(RubyStats, "Recorded statistic: %s\n",
            DirectoryRequestType_to_string(requestType));
}

int
DirectoryMemory::mgEstimateProbeFanout(Addr address, MachineID requestor,
                                       bool is_invalidation,
                                       int fallback_fanout)
{
    // 估算按影子目录语义发 probe，这次大概要发给多少个目标
    //
    // 这里不改变协议真实行为，只做一个多粒度目录视角下的 fanout 估计
    // 供后面的 traffic 统计对比：
    //   - fallback_fanout: 真实单粒度目录路径下的 fanout（SG real）
    //   - 返回值        : 多粒度目录视角下的估计 fanout（MG estimated）
    //
    // 估算原则：
    //   1. 如果没开 mg，直接退回真实 fanout
    //   2. Private(owner)：
    //        - requestor 就是 owner -> 不需要 probe，fanout=0
    //        - requestor 不是 owner -> 最多只需要定向到 owner，fanout=1
    //   3. Shared(sharers)：
    //        - fanout 约等于 sharers 数减去 requestor 自己
    //        - 对 shared-read 的 downgrade 路径，不允许估计值比真实值更大
    if (fallback_fanout <= 0) {
        return 0;
    }
    if (!mgEnabled()) {
        return fallback_fanout;
    }

    std::lock_guard<std::mutex> guard(mg_mutex);
    const Addr block_base = mgBlockBase(address);
    const MgFindResult find_result = mgFindEntryDetailed(block_base);
    MgEntry *entry = find_result.entry;
    if (!entry) {
        return fallback_fanout;
    }

    int est = fallback_fanout;
    const size_t grain_idx = mgGrainIndex(entry->size);
    if (grain_idx != MgInvalidIndex) {
        mgStats.probe_hit_by_grain[grain_idx]++;
    }
    if (entry->line.state == MgState::Private && entry->line.owner) {
        est = (entry->line.owner.value() == requestor) ? 0 : 1;
    } else if (entry->line.state == MgState::Shared) {
        const int sharers = static_cast<int>(entry->line.sharers.size());
        const int has_self = entry->line.sharers.count(requestor) ? 1 : 0;
        est = std::max(0, sharers - has_self);
        if (!is_invalidation) {
            // Downgrade probes for shared-read path should not over-estimate.
            est = std::min(est, fallback_fanout);
        }
    }

    est = std::max(0, est);
    if (find_result.kind == MgFindKind::CustomParent &&
        entry->line.state == MgState::Shared) {
        mgStats.custom_parent_shared_hit++;
        mgStats.custom_parent_shared_est_total += static_cast<uint64_t>(est);
        if (grain_idx != MgInvalidIndex) {
            mgStats.custom_parent_shared_est_by_grain[grain_idx] +=
                static_cast<uint64_t>(est);
        }
    }
    mgRecordShatterProfileProbeReductionLocked(
        block_base, requestor, is_invalidation, fallback_fanout, est,
        find_result);
    return est;
}

void
DirectoryMemory::mgRecordProbeTraffic(MessageSizeType msg_size, int fanout_sg,
                                      int fanout_mg_est)
{
    // 记录目录发出的 probe 流量
    //
    // 这里同时维护两套口径：
    //   - SG (single-gran real): 真实单粒度目录下实际会发出的 probe 数量
    //   - MG_est (multi-gran estimated): 根据影子目录元数据估算的多粒度 probe 数量
    //
    // 两者都按消息数和字节数累计，便于后面做：
    //   - probe_msg_reduction_est
    //   - probe_byte_reduction_est
    //
    // 注意：这里只是统计估计值，不会真正改变协议的发包行为。
    const uint64_t bytes_per_msg = Network::MessageSizeType_to_int(msg_size);
    const uint64_t sg_msgs = fanout_sg > 0 ? static_cast<uint64_t>(fanout_sg) : 0;
    const uint64_t mg_msgs =
        fanout_mg_est > 0 ? static_cast<uint64_t>(fanout_mg_est) : 0;

    const uint64_t sg_bytes = sg_msgs * bytes_per_msg;
    const uint64_t mg_bytes = mg_msgs * bytes_per_msg;

    mgStats.dir_probe_msgs_sg += sg_msgs;
    mgStats.dir_probe_bytes_sg += sg_bytes;
    mgStats.dir_probe_msgs_mg_est += mg_msgs;
    mgStats.dir_probe_bytes_mg_est += mg_bytes;

    mgStats.dir_total_msgs_sg += sg_msgs;
    mgStats.dir_total_bytes_sg += sg_bytes;
    mgStats.dir_total_msgs_mg_est += mg_msgs;
    mgStats.dir_total_bytes_mg_est += mg_bytes;

    if (sg_msgs >= mg_msgs) {
        mgStats.probe_msg_reduction_est += (sg_msgs - mg_msgs);
    }
    if (sg_bytes >= mg_bytes) {
        mgStats.probe_byte_reduction_est += (sg_bytes - mg_bytes);
    }
}

void
DirectoryMemory::mgRecordResponseTraffic(MessageSizeType msg_size, int fanout)
{
    // 记录目录返回响应的流量
    //
    // 和 probe 不同，response 路径目前并没有因为影子目录而改变
    // 因此这里只记录一份真实流量，并把同样的值同时累计到：
    //   - SG total
    //   - MG_est total
    //
    // 这样做是为了保证总流量口径一致：
    //   probe 可能因多粒度估计而不同，
    //   但 response / memory 这类路径当前默认认为不变。
    const uint64_t bytes_per_msg = Network::MessageSizeType_to_int(msg_size);
    const uint64_t msgs = fanout > 0 ? static_cast<uint64_t>(fanout) : 0;
    const uint64_t bytes = msgs * bytes_per_msg;

    mgStats.dir_response_msgs_sg += msgs;
    mgStats.dir_response_bytes_sg += bytes;

    // Response path is currently unchanged by the shadow metadata.
    mgStats.dir_total_msgs_sg += msgs;
    mgStats.dir_total_bytes_sg += bytes;
    mgStats.dir_total_msgs_mg_est += msgs;
    mgStats.dir_total_bytes_mg_est += bytes;
}

void
DirectoryMemory::mgRecordMemTraffic(MessageSizeType msg_size)
{
    // 记录目录向内存侧发送请求的流量
    //
    // 当前影子目录只估算 coherence/probe 侧的潜在优化
    // 并不改变 directory->memory 这条路径的消息数量与大小，
    // 因此这里同样把真实值同时记入：
    //   - SG total
    //   - MG_est total
    //
    // 这样 total 流量里只有 probe 部分会体现 SG 与 MG_est 的差异。
    const uint64_t bytes = Network::MessageSizeType_to_int(msg_size);

    mgStats.dir_mem_msgs_sg++;
    mgStats.dir_mem_bytes_sg += bytes;

    // Memory path is currently unchanged by the shadow metadata.
    mgStats.dir_total_msgs_sg++;
    mgStats.dir_total_bytes_sg += bytes;
    mgStats.dir_total_msgs_mg_est++;
    mgStats.dir_total_bytes_mg_est += bytes;
}

void
DirectoryMemory::mgRecordTriggerTraffic(MessageSizeType msg_size)
{
    // 记录目录发送的 trigger 控制消息流量
    //
    // 当前 trigger 路径不参与 SG/MG_est 的差分估计，
    // 因此这里和 response / memory 一样，把同样的真实值同时记入
    // SG total 与 MG_est total。
    const uint64_t bytes = Network::MessageSizeType_to_int(msg_size);

    mgStats.dir_trigger_msgs_sg++;
    mgStats.dir_trigger_bytes_sg += bytes;

    mgStats.dir_total_msgs_sg++;
    mgStats.dir_total_bytes_sg += bytes;
    mgStats.dir_total_msgs_mg_est++;
    mgStats.dir_total_bytes_mg_est += bytes;
}


void
// 初始化/校验多粒度配置（粒度集合、对齐、64B 倍数）
DirectoryMemory::mgInit()
{
    if (!mgEnabled()) {
        return;
    }

    fatal_if(m_block_size != 64,
             "Multi-granularity directory requires 64B Ruby block size; got %uB",
             m_block_size);

    std::vector<uint32_t> grains = mg_region_grains;
    std::sort(grains.begin(), grains.end());
    // 粒度去重 
    grains.erase(std::unique(grains.begin(), grains.end()), grains.end());

    fatal_if(grains.empty(),
             "mg_enable is set but mg_region_grains is empty");
    
    // 检查粒度是否正确
    for (uint32_t g : grains) {
        fatal_if(g < m_block_size,
                 "Region grain must be >= %uB; got %uB",
                 m_block_size, g);
        fatal_if((g % m_block_size) != 0,
                 "Region grain must be a multiple of %uB; got %uB",
                 m_block_size, g);
        fatal_if(!isPowerOf2(g),
                 "Region grain must be a power of two; got %uB", g);
    }

    fatal_if(std::find(grains.begin(), grains.end(), m_block_size) == grains.end(),
             "Region grain set must include the 64B block size (%uB)",
             m_block_size);
    if (mgUseCustomPolicy()) {
        mgValidateCustomGrains(grains);
    } else if (mgUseAcgPolicy()) {
        mgValidateAcgGrains(grains);
    } else if (mgUseBaselinePolicy()) {
        mgValidateBaselineGrains(grains);
    }

    mg_region_grains_asc = grains;
    mg_region_grains_desc = grains;
    std::reverse(mg_region_grains_desc.begin(), mg_region_grains_desc.end());
    mg_min_region_grain = mg_region_grains_asc.front();
    mg_max_region_grain = mg_region_grains_desc.front();

    for (uint32_t size : mg_region_grains_asc) {
        mg_entries.emplace(size, std::unordered_map<Addr, MgEntry>{});
    }

    // 预先建立粒度到下标的映射：
    //   mg_grain_to_index[64] = 0  mg_grain_to_index[256]  = 1  mg_grain_to_index[1024] = 2
    mg_grain_to_index.clear();
    for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
        mg_grain_to_index.emplace(mg_region_grains_asc[i], i);
    }

    // 初始化统计维度，并设置输出目录与 dump 回调 (把影子目录的摘要统计输出到文件)
    mgStats.initGrains(mg_region_grains_asc);
    mgSetupStatsOutput();
    mgTraceSetup();
}

Addr
// 将任意地址对齐到其所在 64B block 的 base（最小粒度固定为 64B）
DirectoryMemory::mgBlockBase(Addr address) const
{
    return address & ~(Addr(m_block_size - 1));
}

Addr
// 将任意地址对齐到其所在 region 的 base（region_size 必须为 2 的幂）
DirectoryMemory::mgRegionBase(Addr address, uint32_t region_size) const
{
    return address & ~(Addr(region_size - 1));
}

bool
// 判断 [base, base+size) 是否完全落在同一个 directory 的 addrRange 内
DirectoryMemory::mgRegionFitsRanges(Addr base, uint32_t size) const
{
    if (size == 0) {
        return false;
    }
    const Addr last = base + (size - 1);
    for (const auto &r : addrRanges) {
        if (r.contains(base) && r.contains(last)) {
            return true;
        }
    }
    return false;
}

uint32_t
// 冷启动分配策略：ideal/custom 采用最大粒度优先，acg/baseline 固定从 64B block entry 起步。
DirectoryMemory::mgChooseAllocSize(Addr block_base) const
{
    if (mgUseAcgPolicy() || mgUseBaselinePolicy()) {
        const uint32_t size = mg_min_region_grain;
        const Addr base = mgRegionBase(block_base, size);
        if (!mgRegionFitsRanges(base, size)) {
            return 0;
        }
        if (mgHasEntryOverlap(base, size)) {
            return 0;
        }
        return size;
    }

    for (uint32_t size : mg_region_grains_desc) {
        const Addr base = mgRegionBase(block_base, size);
        if (!mgRegionFitsRanges(base, size)) {
            continue;
        }
        if (mgHasEntryOverlap(base, size)) {
            continue;
        }
        return size;
    }
    return 0;
}

bool
// 判断候选范围 [base, base+size) 是否与当前已有的任意多粒度条目重叠
// 支持稀疏 split 产生空洞时，防止后续冷启动又分配一个更大粒度条目
DirectoryMemory::mgHasEntryOverlap(Addr base, uint32_t size) const
{
    const Addr limit = base + size;
    for (const auto &size_map : mg_entries) {
        const uint32_t entry_size = size_map.first;
        for (const auto &kv : size_map.second) {
            const Addr entry_base = kv.first;
            const Addr entry_limit = entry_base + entry_size;
            if (entry_limit <= base || entry_base >= limit) {
                continue;
            }
            return true;
        }
    }
    return false;
}

uint32_t
// 获取比当前粒度更小的一档粒度（来自配置集合 mg_region_grains_asc）
// 若 size 已是最小粒度，则返回 0
DirectoryMemory::mgNextSmallerSize(uint32_t size) const
{
    for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
        if (mg_region_grains_asc[i] == size) {
            if (i == 0) {
                return 0;
            }
            return mg_region_grains_asc[i - 1];
        }
    }
    return 0;
}

uint32_t
// 获取比当前粒度更大的一档粒度（来自配置集合 mg_region_grains_asc）
// 若 size 已是最大粒度，则返回 0
DirectoryMemory::mgNextLargerSize(uint32_t size) const
{
    for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
        if (mg_region_grains_asc[i] == size) {
            if (i + 1 >= mg_region_grains_asc.size()) {
                return 0;
            }
            return mg_region_grains_asc[i + 1];
        }
    }
    return 0;
}

DirectoryMemory::MgEntry *
// 查找覆盖该 64B block 的条目（按粒度集合从大到小匹配）
// 这里的 most specific wins 依赖于 split 过程中删除父条目，使覆盖关系保持唯一
DirectoryMemory::mgFindEntry(Addr block_base)
{
    return mgFindEntryDetailed(block_base).entry;
}

DirectoryMemory::MgFindResult
DirectoryMemory::mgFindEntryDetailed(Addr block_base)
{
    // ideal 模式：依赖 split 时删除父条目，因此通常只会有一个覆盖条目；
    // custom 模式：父条目会保留，需要沿 delegated_mask 逐级向下查找，
    // 返回当前真正负责该 block 的最具体条目；
    // acg 模式：允许粗粒度区域项与更细例外项重叠，始终采用 finest entry wins。
    if (mgUseAcgPolicy()) {
        MgEntry *best = nullptr;
        uint32_t best_size = 0;
        for (auto &size_map : mg_entries) {
            const uint32_t entry_size = size_map.first;
            for (auto &kv : size_map.second) {
                const Addr entry_base = kv.first;
                if (block_base < entry_base ||
                    block_base >= (entry_base + entry_size)) {
                    continue;
                }
                if (!best || entry_size < best_size) {
                    best = &kv.second;
                    best_size = entry_size;
                }
            }
        }
        return {best, best ? MgFindKind::AcgFinest : MgFindKind::None};
    }

    if (mgUseCustomPolicy()) {
        MgEntry *root = nullptr;
        for (uint32_t size : mg_region_grains_desc) {
            const Addr base = mgRegionBase(block_base, size);
            MgEntry *entry = mgFindEntryAtSize(base, size);
            if (entry) {
                root = entry;
                break;
            }
        }
        if (!root) {
            MgEntry *best = nullptr;
            uint32_t best_size = 0;
            for (auto &size_map : mg_entries) {
                const uint32_t entry_size = size_map.first;
                for (auto &kv : size_map.second) {
                    const Addr entry_base = kv.first;
                    if (block_base < entry_base ||
                        block_base >= (entry_base + entry_size)) {
                        continue;
                    }
                    if (!best || entry_size < best_size) {
                        best = &kv.second;
                        best_size = entry_size;
                    }
                }
            }
            return {best, best ? MgFindKind::FallbackScan : MgFindKind::None};
        }

        MgEntry *current = root;
        while (current) {
            MgEntry *child = mgFindDelegatedChild(*current, block_base);
            if (!child) {
                if (current->has_parent) {
                    return {current, MgFindKind::CustomChild};
                }
                if (mgEntryHasDelegatedChildren(*current)) {
                    return {current, MgFindKind::CustomParent};
                }
                return {current, MgFindKind::CustomRootLeaf};
            }
            current = child;
        }
        return {};
    }

    for (uint32_t size : mg_region_grains_desc) {
        const Addr base = mgRegionBase(block_base, size);
        MgEntry *entry = mgFindEntryAtSize(base, size);
        if (entry) {
            const MgFindKind kind =
                (mgUseBaselinePolicy() && entry->size == m_block_size)
                    ? MgFindKind::BaselineLeaf
                    : MgFindKind::Standard;
            return {entry, kind};
        }
    }

    // debug 使用
    // 慢路径：若由于实现 bug 或异常重叠导致按 base 精确查找失败，
    // 这里扫描所有条目，返回覆盖该 block 的最细粒度条目
    // 正常情况下不应走到这里（因为我们尽量保持覆盖关系唯一且对齐）
    MgEntry *best = nullptr;
    uint32_t best_size = 0;
    for (auto &size_map : mg_entries) {
        const uint32_t entry_size = size_map.first;
        for (auto &kv : size_map.second) {
            const Addr entry_base = kv.first;
            if (block_base < entry_base || block_base >= (entry_base + entry_size)) {
                continue;
            }
            if (!best || entry_size < best_size) {
                best = &kv.second;
                best_size = entry_size;
            }
        }
    }
    // 打印 warn 信息，提示实现可能出现错误
    if (best) {
        static int mg_slow_find_prints = 0;
        const int max_prints = 16;
        if (mg_slow_find_prints < max_prints) {
            mg_slow_find_prints++;
            warn("mg: slow-path find for block_base=%#x hit entry base=%#x size=%u\n",
                 block_base, best->base, best->size);
            if (mg_slow_find_prints == max_prints) {
                warn("mg: further slow-path find prints suppressed\n");
            }
        }
    }
    return {best, best ? MgFindKind::FallbackScan : MgFindKind::None};
}

// 在指定粒度 size 的条目表中查找 base 对应的条目；不存在则返回 nullptr
DirectoryMemory::MgEntry *
DirectoryMemory::mgFindEntryAtSize(Addr base, uint32_t size)
{
    auto size_it = mg_entries.find(size);
    if (size_it == mg_entries.end()) {
        return nullptr;
    }
    auto &table = size_it->second;
    auto it = table.find(base);
    if (it == table.end()) {
        return nullptr;
    }
    return &it->second;
}

// 查找或分配一个覆盖 block_base 的多粒度条目：
//  若已有任意粒度条目覆盖该 block，直接返回
//  否则按当前 policy 选择初始粒度（ideal/custom 为最大粒度优先，acg/baseline 为 64B 起步）
//  并按首次触碰语义初始化为 PRIVATE/SHARED
//  若该地址不属于本目录或无法分配，则返回 nullptr
DirectoryMemory::MgEntry *
DirectoryMemory::mgGetOrAllocEntry(Addr block_base, bool first_touch_excl,
                                   MachineID requestor)
{
    if (auto *existing = mgFindEntry(block_base)) {
        return existing;
    }

    const uint32_t region_size = mgChooseAllocSize(block_base);
    if (region_size == 0) {
        // 不在本目录范围或无法找到合适粒度时，直接跳过元数据分配
        // 统计一次分配失败（候选粒度会跨出目录范围或与现有条目 overlap） 输出调试信息
        mgStats.alloc_fail++;
        static int mg_alloc_fail_prints = 0;
        const int max_prints = 16;
        if (mg_alloc_fail_prints < max_prints) {
            mg_alloc_fail_prints++;
            warn("mg: no grain fits block_base=%#x (requestor=%s)\n",
                 block_base, requestor);
            for (uint32_t size : mg_region_grains_desc) {
                const Addr base = mgRegionBase(block_base, size);
                const bool fits = mgRegionFitsRanges(base, size);
                const bool overlap = mgHasEntryOverlap(base, size);
                warn("mg:  candidate size=%u base=%#x fits=%d overlap=%d\n",
                     size, base, fits, overlap);
            }
            if (mg_alloc_fail_prints == max_prints) {
                warn("mg: further alloc-fail debug prints suppressed\n");
            }
        }
        return nullptr;
    }

    const Addr base = mgRegionBase(block_base, region_size);
    MgEntry entry;
    entry.base = base;
    entry.size = region_size;

    if (first_touch_excl) {
        entry.line.state = MgState::Private;
        entry.line.owner = requestor;
        entry.line.sharers.clear();
    } else {
        entry.line.state = MgState::Shared;
        entry.line.owner.reset();
        entry.line.sharers.clear();
        entry.line.sharers.insert(requestor);
    }

    mgInsertEntry(entry, MgChurnCause::Alloc);
    // 统计：成功新建一个 entry（冷启动分配）
    mgStats.alloc_new++;
    const size_t idx = mgGrainIndex(region_size);
    if (idx != MgInvalidIndex) {
        // 统计：按粒度记录新建 entry 次数
        mgStats.grain_alloc_new[idx]++;
    }
    MgEntry *inserted = mgFindEntryAtSize(base, region_size);
    assert(inserted != nullptr);
    // ACG 的初始分配固定从 64B 开始，因此在成功插入后立即尝试 buddy merge，
    // 让相邻且状态一致的新 block entry 能尽快恢复到更粗粒度表示。
    if (mgUseAcgPolicy()) {
        mgTryMergeLocked(base, region_size);
        inserted = mgFindEntry(base);
        assert(inserted != nullptr);
    }
    return inserted;
}

// 在对应粒度表中插入一个条目；若同 base+size 已存在则跳过插入
void
DirectoryMemory::mgInsertEntry(const MgEntry &entry, MgChurnCause cause)
{
    auto size_it = mg_entries.find(entry.size);
    fatal_if(size_it == mg_entries.end(),
             "Unknown entry size %u", entry.size);
    auto &table = size_it->second;
    auto it = table.find(entry.base);
    if (it != table.end()) {
        // 已存在同 base+size 的条目，跳过插入，避免重复覆盖
        static int mg_dup_prints = 0;
        const int max_prints = 16;
        if (mg_dup_prints < max_prints) {
            mg_dup_prints++;
            warn("mg: duplicate insert skipped at %#x size %u\n",
                 entry.base, entry.size);
            if (mg_dup_prints == max_prints) {
                warn("mg: further duplicate-insert prints suppressed\n");
            }
        }
        return;
    }
    table.emplace(entry.base, entry);

    // 统计：entry 插入（按粒度）
    const size_t idx = mgGrainIndex(entry.size);
    if (idx != MgInvalidIndex) {
        mgStats.grain_entry_live[idx]++;
        mgStats.grain_live_coverage_bytes[idx] += entry.size;
    }
    // 统计：entry churn 总量，以及来源分布
    mgStats.entry_churn_total++;
    switch (cause) {
      case MgChurnCause::Alloc:
        mgStats.entry_churn_alloc++;
        if (idx != MgInvalidIndex) {
            mgStats.churn_alloc_by_grain[idx]++;
        }
        break;
      case MgChurnCause::Split:
        mgStats.entry_churn_split++;
        break;
      case MgChurnCause::Merge:
        mgStats.entry_churn_merge++;
        break;
      case MgChurnCause::Eviction:
        mgStats.entry_churn_eviction++;
        break;
      default:
        break;
    }

    // 统计：entry live 总数 / 覆盖字节
    mgStats.live_entry_total++;
    mgStats.live_coverage_total_bytes += entry.size;
}

// 从对应粒度表中删除 base+size 的条目；不存在则无动作。
void
DirectoryMemory::mgEraseEntry(Addr base, uint32_t size, MgChurnCause cause)
{
    auto size_it = mg_entries.find(size);
    if (size_it == mg_entries.end()) {
        return;
    }
    auto &table = size_it->second;
    const auto erased = table.erase(base);
    if (erased == 0) {
        return;
    }
    // 统计：entry 删除（按粒度），并维护 live 计数
    const size_t idx = mgGrainIndex(size);
    if (idx != MgInvalidIndex) {
        if (mgStats.grain_entry_live[idx].value() > 0) {
            mgStats.grain_entry_live[idx]--;
        }
        if (mgStats.grain_live_coverage_bytes[idx].value() >= size) {
            mgStats.grain_live_coverage_bytes[idx] -= size;
        }
    }
    // 统计：entry churn 总量，以及来源分布
    mgStats.entry_churn_total++;
    switch (cause) {
      case MgChurnCause::Alloc:
        mgStats.entry_churn_alloc++;
        break;
      case MgChurnCause::Split:
        mgStats.entry_churn_split++;
        break;
      case MgChurnCause::Merge:
        mgStats.entry_churn_merge++;
        break;
      case MgChurnCause::Eviction:
        mgStats.entry_churn_eviction++;
        if (idx != MgInvalidIndex) {
            mgStats.churn_eviction_by_grain[idx]++;
        }
        break;
      default:
        break;
    }

    // 统计：entry live 总数 / 覆盖字节
    if (mgStats.live_entry_total.value() > 0) {
        mgStats.live_entry_total--;
    }
    if (mgStats.live_coverage_total_bytes.value() >= size) {
        mgStats.live_coverage_total_bytes -= size;
    }
}

// 判断在 [base, base+size) 范围内，是否仍存在 old owner 的“私有块”
// 这里用 mg_block_states（触碰记录）作为 private-cache presence 的代理：
//     若某 64B block 记录为 PRIVATE(owner)，则认为该 block 驻留于 owner 的私有缓存
//     exclude 用于 split 冲突侧：把当前冲突 block 排除，避免它影响是否还剩旧 owner 块的判断
bool
DirectoryMemory::mgHasPrivateBlockInRange(Addr base, uint32_t size,
                                          MachineID owner,
                                          std::optional<Addr> exclude) const
{
    const Addr limit = base + size;
    for (const auto &it : mg_block_states) {
        const Addr blk = it.first;
        if (blk < base || blk >= limit) {
            continue;
        }
        if (exclude && blk == *exclude) {
            continue;
        }
        const MgLineInfo &line = it.second;
        if (line.state == MgState::Private && line.owner &&
            line.owner.value() == owner) {
            return true;
        }
    }
    return false;
}

bool
// 比较两个 sharers 集合是否完全相同
// 用于 merge 判定 只有当两侧共享者集合一致时，才认为共享语义可直接合并
DirectoryMemory::mgSharersEqual(const std::unordered_set<MachineID> &a,
                                const std::unordered_set<MachineID> &b)
{
    if (a.size() != b.size()) {
        return false;
    }
    for (const auto &x : a) {
        if (b.find(x) == b.end()) {
            return false;
        }
    }
    return true;
}

bool
// 比较两个 MgLineInfo（private/shared + owner/sharers）是否等价
// PRIVATE：要求 owner 相同/SHARED：要求 sharers 集合相同
DirectoryMemory::mgLineEqual(const MgLineInfo &a, const MgLineInfo &b)
{
    if (a.state != b.state) {
        return false;
    }
    if (a.state == MgState::Private) {
        return a.owner.has_value() && b.owner.has_value() &&
               a.owner.value() == b.owner.value();
    }
    return mgSharersEqual(a.sharers, b.sharers);
}


void
DirectoryMemory::mgSplitPrivateOnConflict(MgEntry &entry, Addr block_base,
                                          MachineID requestor, bool want_excl,
                                          bool count_break)
{
    // split 的两种模式：
    //   ideal  : 直接挑选一个“尽量粗、但足够隔离冲突”的目标粒度，然后一步拆到位
    //   custom : 只把当前访问落入的下一层子区 carve out，父条目继续保留
    //   acg    : 保留原粗粒度父条目，只为当前冲突 block 分配一个 64B 例外项
    //   baseline: 固定 64B 单粒度，不创建新条目，只原地修改当前块语义
    if (mgUseBaselinePolicy()) {
        if (entry.line.state != MgState::Private || !entry.line.owner) {
            return;
        }

        const MachineID owner = entry.line.owner.value();
        if (count_break) {
            mgRecordPrivateBreak(owner, requestor, entry.size);
        }

        if (want_excl) {
            entry.line.state = MgState::Private;
            entry.line.owner = requestor;
            entry.line.sharers.clear();
        } else {
            entry.line.state = MgState::Shared;
            entry.line.owner.reset();
            entry.line.sharers.clear();
            entry.line.sharers.insert(owner);
            entry.line.sharers.insert(requestor);
        }
        return;
    }

    if (mgUseAcgPolicy()) {
        if (entry.line.state != MgState::Private || !entry.line.owner) {
            return;
        }

        const MachineID owner = entry.line.owner.value();
        if (entry.size == mg_min_region_grain) {
            if (count_break) {
                mgStats.split_attempts++;
                mgRecordPrivateBreak(owner, requestor, entry.size);
            }
            if (want_excl) {
                entry.line.state = MgState::Private;
                entry.line.owner = requestor;
                entry.line.sharers.clear();
                mgTryMergeLocked(entry.base, entry.size);
            } else {
                entry.line.state = MgState::Shared;
                entry.line.owner.reset();
                entry.line.sharers.clear();
                entry.line.sharers.insert(owner);
                entry.line.sharers.insert(requestor);
            }
            return;
        }

        MgLineInfo child_line;
        if (want_excl) {
            child_line.state = MgState::Private;
            child_line.owner = requestor;
            child_line.sharers.clear();
        } else {
            child_line.state = MgState::Shared;
            child_line.owner.reset();
            child_line.sharers.clear();
            child_line.sharers.insert(owner);
            child_line.sharers.insert(requestor);
        }

        mgAcgCreateBlockException(entry, block_base, child_line, requestor,
                                  owner, want_excl, count_break,
                                  /*record_private_break*/true);
        mgTryMergeLocked(mgBlockBase(block_base), mg_min_region_grain);
        return;
    }

    if (mgUseCustomPolicy()) {
        if (entry.line.state != MgState::Private || !entry.line.owner) {
            return;
        }

        // 顶层 private 冲突：只做一次事件记账，避免后续局部下放重复计数。
        if (count_break) {
            mgStats.split_attempts++;
        }

        const MachineID owner = entry.line.owner.value();
        if (count_break) {
            mgRecordPrivateBreak(owner, requestor, entry.size);
        }

        if (entry.size == mg_min_region_grain) {
            // 已到最小粒度时不能再下放，只能原地改成最终语义。
            if (want_excl) {
                entry.line.state = MgState::Private;
                entry.line.owner = requestor;
                entry.line.sharers.clear();
                mgTryMergeLocked(entry.base, entry.size);
            } else {
                entry.line.state = MgState::Shared;
                entry.line.owner.reset();
                entry.line.sharers.clear();
                entry.line.sharers.insert(owner);
                entry.line.sharers.insert(requestor);
            }
            return;
        }

        const uint32_t child_size = mgCustomNextSmallerSize(entry.size);
        fatal_if(child_size == 0,
                 "custom policy missing next child grain for %u", entry.size);

        const uint32_t child_idx = mgCustomChildIndex(entry, block_base);
        const Addr child_base = mgCustomChildBase(entry, child_idx);
        fatal_if(mgIsChildDelegated(entry, child_idx),
                 "custom split requested on already-delegated child "
                 "parent=%#x size=%u child=%#x size=%u",
                 entry.base, entry.size, child_base, child_size);
        fatal_if(mgFindEntryAtSize(child_base, child_size),
                 "custom split would create duplicate child at %#x size %u",
                 child_base, child_size);

        const size_t from_idx = mgGrainIndex(entry.size);
        const size_t to_idx = mgGrainIndex(child_size);
        if (from_idx != MgInvalidIndex && to_idx != MgInvalidIndex) {
            const size_t n = mg_region_grains_asc.size();
            const size_t pair_idx = from_idx * n + to_idx;
            if (pair_idx < mgStats.split_transition_by_grain.size()) {
                mgStats.split_transition_by_grain[pair_idx]++;
            }
        }
        mgStats.split_actual++;
        if (from_idx != MgInvalidIndex) {
            mgStats.grain_split_parent[from_idx]++;
        }

        MgTraceEntry trace;
        trace.op = MgTraceEntry::Op::Split;
        trace.tick = curTick();
        trace.parent_base = entry.base;
        trace.parent_size = entry.size;
        trace.target_size = child_size;
        trace.conflict_block = block_base;
        trace.requestor = requestor;
        trace.owner = owner;
        trace.want_excl = want_excl;

        MgEntry child;
        child.base = child_base;
        child.size = child_size;
        child.line = entry.line;
        child.has_parent = true;
        child.parent_base = entry.base;
        child.parent_size = entry.size;

        // custom 的核心：父条目保留，只把当前命中的下一层子区 carve out 成独立 child。
        if (want_excl) {
            child.line.state = MgState::Private;
            child.line.owner = requestor;
            child.line.sharers.clear();
        } else {
            child.line.state = MgState::Shared;
            child.line.owner.reset();
            child.line.sharers.clear();
            child.line.sharers.insert(owner);
            child.line.sharers.insert(requestor);
        }

        mgSetChildDelegated(entry, child_idx, true);
        mgInsertEntry(child, MgChurnCause::Split);

        MgTraceEntry::ChildInfo ci;
        ci.base = child.base;
        ci.size = child.size;
        ci.is_conflict = true;
        ci.is_sparse_keep = false;
        ci.state = child.line.state;
        ci.owner = child.line.owner;
        trace.children.push_back(ci);
        mgTraceLogSplit(trace);

        if (want_excl) {
            mgTryMergeLocked(child.base, child.size);
        }
        return;
    }

    // 该函数处理一个 Private 条目被其他 requestor 触碰的场景。
    //   1. 先判断最合适的 target_size
    //   2. 直接从 parent_size 一步拆到 target_size
    //   3. 只在 target_size 这一层创建需要保留的子条目（稀疏 split）
    //
    // 目标：
    //   - 避免 1KiB -> 512B -> 256B -> 64B 的多层递归开销
    //   - 直接落到“冲突子区间已足够隔离、且没有其它 old-owner 私有块干扰”的粒度
    //   - 同时保留非冲突但仍含 old-owner 私有块的子区间
    if (entry.line.state != MgState::Private || !entry.line.owner)
        return;
 
    // count_break=true 代表顶层第一次进入 split 逻辑的场景。
    // 这里记的是发生了多少次 private conflict，需要进入 split 处理。
    if (count_break)
        mgStats.split_attempts++;
 
    const MachineID owner = entry.line.owner.value();
    // 记录 private break 的方向：谁原来拥有该 Private 区域，谁来打破它
    if (count_break)
        mgRecordPrivateBreak(owner, requestor, entry.size);
 
    const Addr   parent_base = entry.base;
    const uint32_t parent_size = entry.size;
    const MgLineInfo parent_line = entry.line;
 
    // 已经是最小粒度，就地修改
    // 到了最小粒度以后，已经没有更细的目录层级可拆
    // 因此这里不再创建子条目，而是直接把当前条目改成最终状态：
    //   - want_excl=true : 该最小粒度块直接转交给新 requestor 私有
    //   - want_excl=false: 该最小粒度块变成 Shared(owner, requestor)
    if (parent_size == mg_min_region_grain) {
        if (want_excl) {
            entry.line.state  = MgState::Private;
            entry.line.owner  = requestor;
            entry.line.sharers.clear();
            mgTryMergeLocked(entry.base, entry.size);
        } else {
            entry.line.state = MgState::Shared;
            entry.line.owner.reset();
            entry.line.sharers.clear();
            entry.line.sharers.insert(owner);
            entry.line.sharers.insert(requestor);
        }
        return;
    }
 
    // 确定拆分目标粒度
    // 从比 parent 更小的候选粒度里，按从粗到细的顺序扫描
    // 选择尽量粗、已经足够隔离冲突的那一级。
    //
    // 条件：在包含冲突 block 的 candidate 子区间里，除当前冲突 block 外，
    // 不再存在 old owner 的其它私有块。
    //
    // 一旦满足这个条件，说明把父条目直接拆到 candidate 即可：
    //   - 冲突子区间可以安全地单独交给 requestor / Shared
    //   - 同时这个粒度已经足够粗，能尽量减少 split 后的子条目数
    //
    // 如果所有更粗候选都不满足，才退化为直接拆到最小粒度。
    uint32_t target_size = mg_min_region_grain;
    // ideal 的核心：从粗到细找已足够隔离冲突的最粗目标粒度。
    for (uint32_t candidate : mg_region_grains_desc) {
        if (candidate >= parent_size) {
            continue;
        }
        if ((parent_size % candidate) != 0) continue;
 
        const Addr cbase = mgRegionBase(block_base, candidate);
        const bool other_private =
            mgHasPrivateBlockInRange(cbase, candidate, owner, block_base);
        if (!other_private) {
            target_size = candidate;
            break;
        }
    }
 
    // 统计
    const size_t from_idx = mgGrainIndex(parent_size);
    const size_t to_idx   = mgGrainIndex(target_size);
    if (from_idx != MgInvalidIndex && to_idx != MgInvalidIndex) {
        const size_t n = mg_region_grains_asc.size();
        const size_t pair_idx = from_idx * n + to_idx;
        if (pair_idx < mgStats.split_transition_by_grain.size())
            mgStats.split_transition_by_grain[pair_idx]++;
    }
    mgStats.split_actual++;
    if (from_idx != MgInvalidIndex)
        mgStats.grain_split_parent[from_idx]++;
 
    // 追踪日志初始化 
    MgTraceEntry trace;
    trace.op = MgTraceEntry::Op::Split;
    trace.tick = curTick();
    trace.parent_base = parent_base;
    trace.parent_size = parent_size;
    trace.target_size = target_size;
    trace.conflict_block = block_base;
    trace.requestor = requestor;
    trace.owner = owner;
    trace.want_excl = want_excl;
 
    // ideal split：父条目被整体替换掉，后续只由 target_size 这一层的子条目表示该区域。
    mgEraseEntry(parent_base, parent_size, MgChurnCause::Split);
 
    // 在 target_size 粒度上创建子条目：
    //   1. 冲突子区间：必须创建，并直接写成最终状态
    //   2. 非冲突子区间：基于当前选出的最优 target_size重新切分后，
    //      只有在其中仍检测到 old owner 私有块时才保留
    //   3. 否则直接跳过，形成稀疏空洞，减少条目数量
    const Addr     conflict_base = mgRegionBase(block_base, target_size);
    const uint32_t num_children  = parent_size / target_size;
 
    for (uint32_t i = 0; i < num_children; ++i) {
        const Addr child_base = parent_base + i * target_size;
        const bool is_conflict = (child_base == conflict_base);

        if (is_conflict) {
            // 冲突子区间必须保留，并直接写成这次访问之后的新语义。
            // 冲突子区间：这是包含当前 block_base 的那一个子范围。
            // 它不再保留 old owner 语义，而是直接写成这次请求后的最终状态。
            MgEntry child;
            child.base = child_base;
            child.size = target_size;
            if (want_excl) {
                child.line.state = MgState::Private;
                child.line.owner = requestor;
                child.line.sharers.clear();
            } else {
                child.line.state = MgState::Shared;
                child.line.owner.reset();
                child.line.sharers.clear();
                child.line.sharers.insert(owner);
                child.line.sharers.insert(requestor);
            }
            mgInsertEntry(child, MgChurnCause::Split);
 
            // 追踪：冲突子条目
            MgTraceEntry::ChildInfo ci;
            ci.base = child_base;
            ci.size = target_size;
            ci.is_conflict = true;
            ci.is_sparse_keep = false;
            ci.state = child.line.state;
            ci.owner = child.line.owner;
            trace.children.push_back(ci);
        } else {
            // 非冲突子区间只有在仍能观察到 old-owner 私有块时才保留，否则留空形成稀疏 split。
            // 非冲突子区间：只有当它在“当前选中的 target_size 粒度”下，
            // 仍看得到 old owner 的私有块 presence 时才保留；
            // 否则直接跳过，不创建条目。
            //
            // 这里依赖 mgHasPrivateBlockInRange() 扫描 mg_block_states
            // 也就是利用 64B 级别的 block-state 记录来判断该子区间
            // 是否还值得保留成一个 MgEntry。
            if (mgHasPrivateBlockInRange(child_base, target_size,
                                         owner, std::nullopt)) {
                MgEntry child;
                child.base = child_base;
                child.size = target_size;
                child.line = parent_line;
                mgInsertEntry(child, MgChurnCause::Split);
 
                // 追踪：保留的非冲突子条目
                MgTraceEntry::ChildInfo ci;
                ci.base = child_base;
                ci.size = target_size;
                ci.is_conflict = false;
                ci.is_sparse_keep = true;
                ci.state = child.line.state;
                ci.owner = child.line.owner;
                trace.children.push_back(ci);
            }
            // 无私有块  跳过（稀疏），不记录
        }
    }
 
    // 写入追踪日志 
    mgTraceLogSplit(trace);
 
    // 拆分完成后尝试向上合并
    // 只有独占请求才尝试合并：因为冲突子区间此时已经变成新的 Private(requestor)
    if (want_excl)
        mgTryMergeLocked(conflict_base, target_size);
}


void
DirectoryMemory::mgTryMergeLocked(Addr base, uint32_t size)
{
    // merge 的两种模式：
    //   ideal  : 在所有更粗粒度里寻找当前可成立的最大候选
    //   custom : 只检查当前条目与其父条目，满足条件就逐级回并
    //   acg    : 从当前条目出发，只检查当前同粒度 buddy；
    //            成功后继续拿新父条目向更高一层递归尝试
    //   baseline: 固定 64B 单粒度，不执行 merge
    if (mgUseBaselinePolicy()) {
        return;
    }

    if (mgUseAcgPolicy()) {
        MgEntry *entry = mgFindEntryAtSize(base, size);
        if (!entry) {
            return;
        }
        mgStats.merge_attempts++;
        mgAcgTryMergeUp(base, size);
        return;
    }

    if (mgUseCustomPolicy()) {
        MgEntry *entry = mgFindEntryAtSize(base, size);
        if (!entry) return;

        if (!entry->is_shattered) {
            if (!entry->has_parent) return;
            mgStats.merge_attempts++;
            mgCustomTryMergeUp(*entry);
            return;
        }

        // shatter 产生的独立 64B entry 没有父指针，只能按相邻 buddy
        // 逐级向上恢复；每一级仍要求状态和 owner/sharers 完全一致。
        Addr current_base = base;
        uint32_t current_size = size;
        while (true) {
            MgEntry *current = mgFindEntryAtSize(current_base, current_size);
            if (!current || !current->is_shattered) return;
            if (mgEntryHasDelegatedChildren(*current)) return;

            const bool is_private_merge =
                current->line.state == MgState::Private && current->line.owner;
            const bool is_shared_merge =
                current->line.state == MgState::Shared;
            if (!is_private_merge && !is_shared_merge) return;

            mgStats.merge_attempts++;

            const MgLineInfo merged_line = current->line;
            const bool merged_is_shattered = current->is_shattered;
            const uint32_t next_size = mgNextLargerSize(current_size);
            if (next_size == 0) return;
            if ((next_size % current_size) != 0) return;

            const Addr candidate_base = mgRegionBase(current_base, next_size);
            if (!mgRegionFitsRanges(candidate_base, next_size)) return;

            const uint32_t ratio = next_size / current_size;
            bool all_match = true;
            for (uint32_t i = 0; i < ratio; ++i) {
                const Addr child_base = candidate_base + i * current_size;
                MgEntry *child = mgFindEntryAtSize(child_base, current_size);
                if (!child || !child->is_shattered ||
                    mgEntryHasDelegatedChildren(*child) ||
                    !mgLineEqual(child->line, merged_line)) {
                    all_match = false;
                    break;
                }
            }
            if (!all_match) return;

            MgEntry *existing_parent =
                mgFindEntryAtSize(candidate_base, next_size);
            if (existing_parent &&
                (!existing_parent->is_shattered ||
                 mgEntryHasDelegatedChildren(*existing_parent) ||
                 !mgLineEqual(existing_parent->line, merged_line))) {
                return;
            }

            MgTraceEntry trace;
            trace.op = MgTraceEntry::Op::Merge;
            trace.tick = curTick();
            trace.parent_base = candidate_base;
            trace.parent_size = next_size;
            trace.target_size = current_size;
            trace.conflict_block = 0;
            trace.requestor = MachineID();
            trace.owner = merged_line.owner.value_or(MachineID());
            trace.want_excl = false;

            for (uint32_t i = 0; i < ratio; ++i) {
                MgTraceEntry::ChildInfo ci;
                ci.base = candidate_base + i * current_size;
                ci.size = current_size;
                ci.is_conflict = false;
                ci.is_sparse_keep = false;
                ci.state = merged_line.state;
                ci.owner = merged_line.owner;
                trace.children.push_back(ci);
            }

            for (uint32_t i = 0; i < ratio; ++i) {
                mgEraseEntry(candidate_base + i * current_size,
                             current_size, MgChurnCause::Merge);
            }

            MgEntry merged;
            merged.base = candidate_base;
            merged.size = next_size;
            merged.line = merged_line;
            merged.is_shattered = merged_is_shattered;
            if (!existing_parent) {
                mgInsertEntry(merged, MgChurnCause::Merge);
            }

            mgTraceLogMerge(trace);
            mgStats.merge_success++;

            const size_t from_idx = mgGrainIndex(current_size);
            const size_t to_idx = mgGrainIndex(next_size);
            if (to_idx != MgInvalidIndex) {
                mgStats.grain_merge_success[to_idx]++;
            }
            if (from_idx != MgInvalidIndex && to_idx != MgInvalidIndex) {
                const size_t n = mg_region_grains_asc.size();
                const size_t pair_idx = from_idx * n + to_idx;
                if (pair_idx < mgStats.merge_transition_by_grain.size()) {
                    mgStats.merge_transition_by_grain[pair_idx]++;
                }
            }

            current_base = candidate_base;
            current_size = next_size;
        }
    }

    // ideal 模式：尝试把 Private 条目恢复到当前能成立的最大更粗粒度。
    MgEntry *entry = mgFindEntryAtSize(base, size);
    if (!entry || entry->line.state != MgState::Private || !entry->line.owner) {
        return;
    }

    mgStats.merge_attempts++;

    const MachineID owner = entry->line.owner.value();
    uint32_t best_size = 0;
    Addr best_base = 0;

    for (auto it = mg_region_grains_desc.begin();
         it != mg_region_grains_desc.end(); ++it)
    {
        const uint32_t candidate_size = *it;
        if (candidate_size <= size) break;
        if ((candidate_size % size) != 0) continue;

        const Addr candidate_base = mgRegionBase(base, candidate_size);
        if (!mgRegionFitsRanges(candidate_base, candidate_size)) {
            continue;
        }

        const uint32_t ratio = candidate_size / size;
        bool all_match = true;
        for (uint32_t i = 0; i < ratio; ++i) {
            const Addr child_base = candidate_base + i * size;
            MgEntry *child = mgFindEntryAtSize(child_base, size);
            if (!child ||
                child->line.state != MgState::Private || !child->line.owner ||
                child->line.owner.value() != owner)
            {
                all_match = false;
                break;
            }
        }

        if (all_match) {
            best_size = candidate_size;
            best_base = candidate_base;
            break;
        }
    }

    if (best_size == 0) return;

    const uint32_t ratio = best_size / size;
    for (uint32_t i = 0; i < ratio; ++i) {
        mgEraseEntry(best_base + i * size, size, MgChurnCause::Merge);
    }

    MgEntry merged;
    merged.base = best_base;
    merged.size = best_size;
    merged.line.state = MgState::Private;
    merged.line.owner = owner;
    merged.line.sharers.clear();
    mgInsertEntry(merged, MgChurnCause::Merge);

    {
        MgTraceEntry trace;
        trace.op = MgTraceEntry::Op::Merge;
        trace.tick = curTick();
        trace.parent_base = best_base;
        trace.parent_size = best_size;
        trace.target_size = size;
        trace.conflict_block = 0;
        trace.requestor = MachineID();
        trace.owner = owner;
        trace.want_excl = false;

        for (uint32_t i = 0; i < ratio; ++i) {
            MgTraceEntry::ChildInfo ci;
            ci.base = best_base + i * size;
            ci.size = size;
            ci.is_conflict = false;
            ci.is_sparse_keep = false;
            ci.state = MgState::Private;
            ci.owner = owner;
            trace.children.push_back(ci);
        }

        mgTraceLogMerge(trace);
    }

    mgStats.merge_success++;
    const size_t merge_idx = mgGrainIndex(best_size);
    if (merge_idx != MgInvalidIndex)
        mgStats.grain_merge_success[merge_idx]++;

    const size_t fi = mgGrainIndex(size);
    const size_t ti = mgGrainIndex(best_size);
    if (fi != MgInvalidIndex && ti != MgInvalidIndex) {
        const size_t n = mg_region_grains_asc.size();
        const size_t pair_idx = fi * n + ti;
        if (pair_idx < mgStats.merge_transition_by_grain.size())
            mgStats.merge_transition_by_grain[pair_idx]++;
    }
}

// 粒度统计部分
// =====================================================================
// 将粒度 size 映射到统计用的 index；未命中返回 MgInvalidIndex
size_t
DirectoryMemory::mgGrainIndex(uint32_t size) const
{
    // 这里返回的 index 对应 mg_region_grains_asc 的顺序
    auto it = mg_grain_to_index.find(size);
    if (it == mg_grain_to_index.end()) {
        return MgInvalidIndex;
    }
    return it->second;
}

// 记录某类请求在指定 MachineType 下的计数（非法类型记入 unknown）
void
DirectoryMemory::mgCountByRequestor(statistics::Vector &vec,
                                     MachineID requestor)
{
    // MachineID.type 是 SLICC 生成的 MachineType 枚举，用于区分 CPU CorePair / GPU TCP 等
    const auto idx = static_cast<size_t>(requestor.type);
    if (idx >= vec.size()) {
        mgStats.req_unknown_type++;
        return;
    }
    vec[idx]++;
}

// 判定是否为 CPU 侧发起者类型（用于统计 CPU<->GPU 打破私有语义）
bool
DirectoryMemory::mgIsCpuMachineType(MachineType type) const
{
    switch (type) {
      case MachineType_L0Cache:
      case MachineType_L1Cache:
      case MachineType_L2Cache:
      case MachineType_L3Cache:
      case MachineType_CorePair:
      case MachineType_Cache:
        return true;
      default:
        return false;
    }
}

// 判定是否为 GPU 侧发起者类型（用于统计 CPU<->GPU 打破私有语义）
bool
DirectoryMemory::mgIsGpuMachineType(MachineType type) const
{
    switch (type) {
      case MachineType_TCP:
      case MachineType_TCC:
      case MachineType_TCCdir:
      case MachineType_SQC:
        return true;
      default:
        return false;
    }
}

// 记录private 被打破的方向（CPU->GPU / GPU->CPU）及粒度
// 当目录条目为 PRIVATE 且 requestor != owner 时认为发生一次 private break
// 这类事件越少，意味着粗粒度 private region越稳定（抢占越少）
void
DirectoryMemory::mgRecordPrivateBreak(MachineID owner, MachineID requestor,
                                      uint32_t parent_size)
{
    const bool owner_cpu = mgIsCpuMachineType(owner.type);
    const bool owner_gpu = mgIsGpuMachineType(owner.type);
    const bool req_cpu = mgIsCpuMachineType(requestor.type);
    const bool req_gpu = mgIsGpuMachineType(requestor.type);

    const size_t idx = mgGrainIndex(parent_size);

    if (owner_cpu && req_gpu) {
        mgStats.private_break_cpu_owner_gpu_req++;
        if (idx != MgInvalidIndex) {
            mgStats.grain_private_break_cpu_owner_gpu_req[idx]++;
        }
    } else if (owner_gpu && req_cpu) {
        mgStats.private_break_gpu_owner_cpu_req++;
        if (idx != MgInvalidIndex) {
            mgStats.grain_private_break_gpu_owner_cpu_req[idx]++;
        }
    } else if (owner_cpu && req_cpu) {
        mgStats.private_break_cpu_owner_cpu_req++;
    } else if (owner_gpu && req_gpu) {
        mgStats.private_break_gpu_owner_gpu_req++;
    } else {
        mgStats.private_break_unknown++;
    }
}

void
DirectoryMemory::mgRecordSharerSample(uint64_t sharer_count)
{
    mgStats.sharer_count_total += sharer_count;
    mgStats.sharer_count_samples++;
    if (sharer_count > mgStats.sharer_count_max.value()) {
        mgStats.sharer_count_max = sharer_count;
    }

    const uint64_t bucket = std::min<uint64_t>(sharer_count, 15);
    mgStats.sharer_count_hist[bucket]++;
}

void
DirectoryMemory::mgRecordShatterProfileAccess(const MgEntry &entry,
                                              bool is_exclusive)
{
    if (!mgUseProfilePolicy() || entry.size <= mg_min_region_grain ||
        entry.line.state != MgState::Shared) {
        return;
    }

    auto &by_base = mg_shatter_profile_regions[entry.size];
    MgShatterProfileRegion &region = by_base[entry.base];
    region.access_count++;
    if (is_exclusive) {
        region.exclusive_count++;
    }
    region.max_sharers =
        std::max<uint64_t>(region.max_sharers, entry.line.sharers.size());
}

std::vector<uint32_t>
DirectoryMemory::mgProfileThresholds() const
{
    std::vector<uint32_t> thresholds;
    if (mg_profile_thresholds.empty()) {
        thresholds = {1, 2, 3, 4, 5, 6, 8, 12, 16};
    } else {
        thresholds.assign(mg_profile_thresholds.begin(),
                          mg_profile_thresholds.end());
        std::sort(thresholds.begin(), thresholds.end());
        thresholds.erase(std::unique(thresholds.begin(), thresholds.end()),
                         thresholds.end());
    }
    return thresholds;
}

void
DirectoryMemory::mgRecordShatterProfileProbeReductionLocked(
    Addr block_base, MachineID requestor, bool is_invalidation,
    int fallback_fanout, int current_est, const MgFindResult &find_result)
{
    if (!mgUseProfilePolicy() || fallback_fanout <= 0 || !find_result.entry) {
        return;
    }

    auto estimate_line_fanout = [&](const MgLineInfo &line) {
        int est = fallback_fanout;
        if (line.state == MgState::Private && line.owner) {
            est = (line.owner.value() == requestor) ? 0 : 1;
        } else if (line.state == MgState::Shared) {
            const int sharers = static_cast<int>(line.sharers.size());
            const int has_self = line.sharers.count(requestor) ? 1 : 0;
            est = std::max(0, sharers - has_self);
            if (!is_invalidation) {
                est = std::min(est, fallback_fanout);
            }
        }
        return std::max(0, est);
    };

    MgEntry *coarse_entry = find_result.entry;
    if (coarse_entry->has_parent) {
        MgEntry *parent = mgFindEntryAtSize(coarse_entry->parent_base,
                                            coarse_entry->parent_size);
        if (parent) {
            coarse_entry = parent;
        }
    }
    if (coarse_entry->size <= mg_min_region_grain ||
        coarse_entry->line.state != MgState::Shared) {
        return;
    }

    const int coarse_est = estimate_line_fanout(coarse_entry->line);
    int fine_est = current_est;
    if (find_result.entry == coarse_entry) {
        auto block_it = mg_block_states.find(block_base);
        if (block_it == mg_block_states.end()) {
            return;
        }
        fine_est = estimate_line_fanout(block_it->second);
    }

    if (coarse_est <= fine_est) {
        return;
    }

    const uint64_t reduction =
        static_cast<uint64_t>(coarse_est - fine_est);
    const uint64_t sharers = coarse_entry->line.sharers.size();
    for (uint32_t threshold : mgProfileThresholds()) {
        if (sharers > threshold) {
            mg_shatter_profile_probe_reduction_by_threshold[threshold] +=
                reduction;
        }
    }
}

// 将粒度大小格式化为易读字符串（用于文件名/统计输出）
std::string
DirectoryMemory::mgFormatGrain(uint32_t size) const
{
    if ((size % (1024 * 1024)) == 0) {
        return std::to_string(size / (1024 * 1024)) + "MiB";
    }
    if ((size % 1024) == 0) {
        return std::to_string(size / 1024) + "KiB";
    }
    return std::to_string(size) + "B";
}

// 用粒度集合拼出输出子目录名（用于区分实验配置）
std::string
DirectoryMemory::mgGrainTag() const
{
    std::string tag = "mg-";
    tag += mgPolicyName();
    for (uint32_t size : mg_region_grains_asc) {
        tag += "-";
        tag += mgFormatGrain(size);
    }
    return tag;
}

// 将对象名转换为安全文件名（替换 '.' '/' ' ' 等字符）
std::string
DirectoryMemory::mgSafeName(const std::string &name) const
{
    std::string safe = name;
    for (char &c : safe) {
        if (c == '.' || c == '/' || c == ' ') {
            c = '_';
        }
    }
    return safe;
}

// 初始化统计输出目录，并注册 stats dump 回调
void
DirectoryMemory::mgSetupStatsOutput()
{
    if (mg_stats_dir) {
        return;
    }
    // 以粒度集合生成子目录名：例如 mg-64B-1KiB 或 mg-64B-512B-2KiB
    mg_stats_dir_name = mgGrainTag();
    mg_stats_dir = simout.createSubdirectory(mg_stats_dir_name);
    // 注册回调：当 gem5 dump stats（如退出或 m5 dumpstats）时会调用 mgDumpStats()
    statistics::registerDumpCallback([this]() { mgDumpStats(); });
}

// 将关键统计项写入独立文件，便于按粒度目录分类
void
DirectoryMemory::mgDumpStats()
{
    if (!mgEnabled()) {
        return;
    }

    // 先基于当前 mg_entries 计算 live 快照，避免 stats.reset 导致的计数失真
    std::vector<uint64_t> live_entries_by_grain(mg_region_grains_asc.size(), 0);
    std::vector<uint64_t> live_coverage_by_grain(mg_region_grains_asc.size(), 0);
    uint64_t live_entry_total = 0;
    uint64_t live_coverage_total = 0;
    uint64_t live_block_state_total = 0;

    struct ShatterProfileRegionSnapshot
    {
        Addr base = 0;
        uint32_t size = 0;
        uint64_t coarse_sharers = 0;
        uint64_t access_count = 0;
        uint64_t exclusive_count = 0;
        uint64_t fine_non_empty_blocks = 0;
        uint64_t fine_shared_blocks = 0;
        uint64_t fine_sharer_total = 0;
        uint64_t fine_sharer_max = 0;
        uint64_t est_entry_cost = 0;
        uint64_t dispersion_ppm = 0;
        std::string sharer_ids_str;   // 新增：sharer ID 字符串，格式 "CorePair0|TCP3"

    };
    std::vector<ShatterProfileRegionSnapshot> shatter_profile_regions;
    std::vector<ShatterProfileRegionSnapshot> shatter_profile_detail_regions;
    std::unordered_map<uint32_t, uint64_t>
        shatter_profile_probe_reduction_by_threshold;

    {
        std::lock_guard<std::mutex> guard(mg_mutex);
        for (const auto &size_map : mg_entries) {
            const uint32_t size = size_map.first;
            const size_t idx = mgGrainIndex(size);
            if (idx == MgInvalidIndex) {
                continue;
            }
            const uint64_t count = size_map.second.size();
            live_entries_by_grain[idx] = count;
            live_coverage_by_grain[idx] = count * size;
            live_entry_total += count;
            live_coverage_total += count * size;
        }
        live_block_state_total = mg_block_states.size();

        if (mgUseProfilePolicy()) {
            shatter_profile_probe_reduction_by_threshold =
                mg_shatter_profile_probe_reduction_by_threshold;
            for (const auto &size_map : mg_shatter_profile_regions) {
                const uint32_t size = size_map.first;
                if (size <= mg_min_region_grain) {
                    continue;
                }
                for (const auto &kv : size_map.second) {
                    const Addr base = kv.first;
                    const MgShatterProfileRegion &profile = kv.second;
                    ShatterProfileRegionSnapshot detail_snap;
                    detail_snap.base = base;
                    detail_snap.size = size;
                    detail_snap.access_count = profile.access_count;
                    detail_snap.exclusive_count = profile.exclusive_count;
                    detail_snap.coarse_sharers = profile.max_sharers;
                    // 新增：从 live entry 的 sharers 集合构建 sharer_ids_str
                    MgEntry *live_entry_for_ids = mgFindEntryAtSize(base, size);
                    if (live_entry_for_ids &&
                        live_entry_for_ids->line.state == MgState::Shared) {
                            std::string ids;
                        for (const auto &mid : live_entry_for_ids->line.sharers) {
                                if (!ids.empty()) ids += "|";
                                ids += MachineType_to_string(mid.type) + std::to_string(mid.num);
                        }
                        detail_snap.sharer_ids_str = ids;
                    }
                    shatter_profile_detail_regions.push_back(detail_snap);

                    if (profile.max_sharers <= 1) {
                        continue;
                    }

                    ShatterProfileRegionSnapshot snap;
                    snap.base = base;
                    snap.size = size;
                    snap.access_count = profile.access_count;
                    snap.exclusive_count = profile.exclusive_count;
                    snap.coarse_sharers = profile.max_sharers;

                    MgEntry *live_entry = mgFindEntryAtSize(base, size);
                    if (live_entry && live_entry->line.state == MgState::Shared) {
                        snap.coarse_sharers =
                            std::max<uint64_t>(snap.coarse_sharers,
                                               live_entry->line.sharers.size());
                    }

                    for (Addr blk = base; blk < base + size;
                         blk += m_block_size) {
                        auto blk_it = mg_block_states.find(blk);
                        if (blk_it == mg_block_states.end()) {
                            continue;
                        }

                        snap.fine_non_empty_blocks++;
                        uint64_t fine_sharers = 0;
                        if (blk_it->second.state == MgState::Private) {
                            fine_sharers = blk_it->second.owner ? 1 : 0;
                        } else {
                            fine_sharers = blk_it->second.sharers.size();
                            if (fine_sharers > 1) {
                                snap.fine_shared_blocks++;
                            }
                        }
                        snap.fine_sharer_total += fine_sharers;
                        snap.fine_sharer_max =
                            std::max(snap.fine_sharer_max, fine_sharers);
                    }
                    if (snap.fine_non_empty_blocks == 0) {
                        continue;
                    }

                    const uint64_t fine_blocks =
                        snap.fine_non_empty_blocks ? snap.fine_non_empty_blocks
                                                   : 1;
                    const uint64_t fine_avg_sharers =
                        snap.fine_sharer_total / fine_blocks;
                    snap.dispersion_ppm =
                        (snap.coarse_sharers * 1000000ULL) /
                        std::max<uint64_t>(1, fine_avg_sharers);

                    snap.est_entry_cost =
                        snap.fine_non_empty_blocks > 1
                            ? snap.fine_non_empty_blocks - 1
                            : 0;

                    shatter_profile_regions.push_back(snap);
                }
            }
        }
    }
    std::sort(shatter_profile_detail_regions.begin(),
              shatter_profile_detail_regions.end(),
              [](const ShatterProfileRegionSnapshot &lhs,
                 const ShatterProfileRegionSnapshot &rhs) {
                  return lhs.size != rhs.size ? lhs.size < rhs.size
                                              : lhs.base < rhs.base;
              });

    // 将快照值写回 stats，保证输出一致
    mgStats.live_entry_total = live_entry_total;
    mgStats.live_coverage_total_bytes = live_coverage_total;
    mgStats.block_state_live = live_block_state_total;
    for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
        mgStats.grain_entry_live[i] = live_entries_by_grain[i];
        mgStats.grain_live_coverage_bytes[i] = live_coverage_by_grain[i];
    }

    // 将摘要输出逻辑做成一个局部函数，便于同时输出到两个位置：
    //     默认 simout/<mg-grains>/...（和 gem5 的 outdir 绑定）
    //     固定工作目录下的 mg_run_out/<mg-grains>/...（便于跑 tests 时也能统一收集）
    auto emit_summary = [&](std::ostream &out) {
        const int key_width = 34;
        auto header = [&](const char *title) {
            out << "[" << title << "]\n";
        };
        auto kv_u64 = [&](const char *key, uint64_t val) {
            out << "  " << std::left << std::setw(key_width) << key
                << ": " << val << "\n";
        };
        auto kv_percent = [&](const char *key, double val) {
            out << "  " << std::left << std::setw(key_width) << key
                << ": " << std::fixed << std::setprecision(2) << val
                << "%\n" << std::defaultfloat << std::setprecision(6);
        };
        auto list_by_grain = [&](const char *key,
                                 const statistics::VCounter &vals) {
            out << "  " << std::left << std::setw(key_width) << key << ": ";
            for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
                if (i) {
                    out << " ";
                }
                out << mgFormatGrain(mg_region_grains_asc[i]) << "="
                    << vals[i];
            }
            out << "\n";
        };
        auto list_by_type = [&](const char *key,
                                const statistics::VCounter &vals) {
            out << "  " << std::left << std::setw(key_width) << key << ": ";
            for (int i = 0; i < MachineType_NUM; ++i) {
                if (i) {
                    out << " ";
                }
                out << MachineType_to_string(static_cast<MachineType>(i))
                    << "=" << vals[i];
            }
            out << "\n";
        };
        auto list_transitions = [&](const char *key,
                                    const statistics::VCounter &vals) {
            out << "  " << std::left << std::setw(key_width) << key << ": ";
            bool any = false;
            const size_t n = mg_region_grains_asc.size();
            for (size_t i = 0; i < n; ++i) {
                for (size_t j = 0; j < n; ++j) {
                    const size_t idx = i * n + j;
                    if (idx >= vals.size()) {
                        continue;
                    }
                    const uint64_t v = vals[idx];
                    if (v == 0) {
                        continue;
                    }
                    if (any) {
                        out << " ";
                    }
                    out << mgFormatGrain(mg_region_grains_asc[i]) << "->"
                        << mgFormatGrain(mg_region_grains_asc[j]) << "="
                        << v;
                    any = true;
                }
            }
            if (!any) {
                out << "none";
            }
            out << "\n";
        };

        out << "object: " << name() << "\n";
        out << "policy: " << mgPolicyName() << "\n";
        out << "grains: ";
        for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
            if (i) {
                out << ",";
            }
            out << mgFormatGrain(mg_region_grains_asc[i]);
        }
        out << "\n\n";

        header("OBS");
        kv_u64("obs_shared", mgStats.obs_shared.value());
        kv_u64("obs_exclusive", mgStats.obs_exclusive.value());
        kv_u64("obs_eviction", mgStats.obs_eviction.value());
        kv_u64("obs_total", mgStats.obs_total.value());
        out << "\n";

        header("SPLIT_MERGE");
        kv_u64("split_attempts", mgStats.split_attempts.value());
        kv_u64("split_actual", mgStats.split_actual.value());
        kv_u64("merge_attempts", mgStats.merge_attempts.value());
        kv_u64("merge_success", mgStats.merge_success.value());
        out << "\n";

        header("PRIVATE_BREAK");
        kv_u64("cpu_owner_gpu_req",
               mgStats.private_break_cpu_owner_gpu_req.value());
        kv_u64("gpu_owner_cpu_req",
               mgStats.private_break_gpu_owner_cpu_req.value());
        kv_u64("cpu_owner_cpu_req",
               mgStats.private_break_cpu_owner_cpu_req.value());
        kv_u64("gpu_owner_gpu_req",
               mgStats.private_break_gpu_owner_gpu_req.value());
        kv_u64("unknown", mgStats.private_break_unknown.value());
        out << "\n";

        header("BLOCK_STATE");
        kv_u64("block_state_live", mgStats.block_state_live.value());
        out << "\n";

        // Fragmentation：live entry 总数、覆盖字节、平均粒度等
        const uint64_t live_entry_total = mgStats.live_entry_total.value();
        const uint64_t live_cov_total = mgStats.live_coverage_total_bytes.value();
        const uint64_t eff_bytes_per_entry =
            live_entry_total ? (live_cov_total / live_entry_total) : 0;
        mgStats.eff_bytes_per_entry = eff_bytes_per_entry;

        header("FRAGMENTATION");
        kv_u64("live_entry_total", live_entry_total);
        kv_u64("live_coverage_total_bytes", live_cov_total);
        kv_u64("eff_bytes_per_entry", eff_bytes_per_entry);
        out << "\n";

        header("GRAIN_LIVE");
        statistics::VCounter live_vals;
        mgStats.grain_entry_live.value(live_vals);
        list_by_grain("entry_live_by_grain", live_vals);

        // Coverage：按粒度的覆盖字节与覆盖占比（ppm）
        statistics::VCounter cov_vals;
        mgStats.grain_live_coverage_bytes.value(cov_vals);
        list_by_grain("grain_live_coverage_bytes", cov_vals);

        statistics::VCounter ratio_vals;
        ratio_vals.resize(mg_region_grains_asc.size());
        const uint64_t cov_denom = live_cov_total ? live_cov_total : 1;
        for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
            ratio_vals[i] = (cov_vals[i] * 1000000ULL) / cov_denom;
            mgStats.grain_live_coverage_ratio_ppm[i] = ratio_vals[i];
        }
        list_by_grain("grain_live_coverage_ratio_ppm", ratio_vals);

        statistics::VCounter alloc_vals;
        mgStats.grain_alloc_new.value(alloc_vals);
        list_by_grain("alloc_new_by_grain", alloc_vals);

        statistics::VCounter split_vals;
        mgStats.grain_split_parent.value(split_vals);
        list_by_grain("split_parent_by_grain", split_vals);

        statistics::VCounter merge_vals;
        mgStats.grain_merge_success.value(merge_vals);
        list_by_grain("merge_success_by_grain", merge_vals);

        statistics::VCounter cog_vals;
        mgStats.grain_private_break_cpu_owner_gpu_req.value(cog_vals);
        list_by_grain("private_break_cpu_owner_gpu_req_by_grain", cog_vals);

        statistics::VCounter goc_vals;
        mgStats.grain_private_break_gpu_owner_cpu_req.value(goc_vals);
        list_by_grain("private_break_gpu_owner_cpu_req_by_grain", goc_vals);
        out << "\n";

        // Churn：归一化到每 1000 次观测请求
        const uint64_t obs_total = mgStats.obs_total.value();
        const uint64_t churn_denom = obs_total ? obs_total : 1;
        const uint64_t entry_churn_total = mgStats.entry_churn_total.value();
        const uint64_t entry_churn_per_1k_obs =
            (entry_churn_total * 1000ULL) / churn_denom;
        const uint64_t split_actual_per_1k_obs =
            (mgStats.split_actual.value() * 1000ULL) / churn_denom;
        const uint64_t merge_success_per_1k_obs =
            (mgStats.merge_success.value() * 1000ULL) / churn_denom;
        mgStats.entry_churn_per_1k_obs = entry_churn_per_1k_obs;
        mgStats.split_actual_per_1k_obs = split_actual_per_1k_obs;
        mgStats.merge_success_per_1k_obs = merge_success_per_1k_obs;

        header("CHURN");
        kv_u64("entry_churn_total", entry_churn_total);
        kv_u64("entry_churn_alloc", mgStats.entry_churn_alloc.value());
        kv_u64("entry_churn_split", mgStats.entry_churn_split.value());
        kv_u64("entry_churn_merge", mgStats.entry_churn_merge.value());
        kv_u64("entry_churn_eviction", mgStats.entry_churn_eviction.value());

        // 额外给一个简单的占比（ppm），便于不同 workload/不同长度 run 之间横向比较。
        const uint64_t churn_share_denom = entry_churn_total ? entry_churn_total : 1;
        kv_u64("churn_alloc_ratio_ppm",
               (mgStats.entry_churn_alloc.value() * 1000000ULL) / churn_share_denom);
        kv_u64("churn_split_ratio_ppm",
               (mgStats.entry_churn_split.value() * 1000000ULL) / churn_share_denom);
        kv_u64("churn_merge_ratio_ppm",
               (mgStats.entry_churn_merge.value() * 1000000ULL) / churn_share_denom);
        kv_u64("churn_eviction_ratio_ppm",
               (mgStats.entry_churn_eviction.value() * 1000000ULL) / churn_share_denom);

        statistics::VCounter churn_alloc_vals;
        mgStats.churn_alloc_by_grain.value(churn_alloc_vals);
        list_by_grain("churn_alloc_by_grain", churn_alloc_vals);

        statistics::VCounter churn_ev_vals;
        mgStats.churn_eviction_by_grain.value(churn_ev_vals);
        list_by_grain("churn_eviction_by_grain", churn_ev_vals);

        statistics::VCounter split_trans_vals;
        mgStats.split_transition_by_grain.value(split_trans_vals);
        list_transitions("split_transition_by_grain", split_trans_vals);

        statistics::VCounter merge_trans_vals;
        mgStats.merge_transition_by_grain.value(merge_trans_vals);
        list_transitions("merge_transition_by_grain", merge_trans_vals);

        kv_u64("entry_churn_per_1k_obs", entry_churn_per_1k_obs);
        kv_u64("split_actual_per_1k_obs", split_actual_per_1k_obs);
        kv_u64("merge_success_per_1k_obs", merge_success_per_1k_obs);
        out << "\n";

        header("TRAFFIC");
        kv_u64("dir_probe_msgs_sg", mgStats.dir_probe_msgs_sg.value());
        kv_u64("dir_probe_bytes_sg", mgStats.dir_probe_bytes_sg.value());
        kv_u64("dir_probe_msgs_mg_est", mgStats.dir_probe_msgs_mg_est.value());
        kv_u64("dir_probe_bytes_mg_est", mgStats.dir_probe_bytes_mg_est.value());
        kv_u64("probe_msg_reduction_est", mgStats.probe_msg_reduction_est.value());
        kv_u64("probe_byte_reduction_est", mgStats.probe_byte_reduction_est.value());
        kv_u64("dir_response_msgs_sg", mgStats.dir_response_msgs_sg.value());
        kv_u64("dir_response_bytes_sg", mgStats.dir_response_bytes_sg.value());
        kv_u64("dir_mem_msgs_sg", mgStats.dir_mem_msgs_sg.value());
        kv_u64("dir_mem_bytes_sg", mgStats.dir_mem_bytes_sg.value());
        kv_u64("dir_trigger_msgs_sg", mgStats.dir_trigger_msgs_sg.value());
        kv_u64("dir_trigger_bytes_sg", mgStats.dir_trigger_bytes_sg.value());
        kv_u64("dir_total_msgs_sg", mgStats.dir_total_msgs_sg.value());
        kv_u64("dir_total_bytes_sg", mgStats.dir_total_bytes_sg.value());
        kv_u64("dir_total_msgs_mg_est", mgStats.dir_total_msgs_mg_est.value());
        kv_u64("dir_total_bytes_mg_est", mgStats.dir_total_bytes_mg_est.value());
        out << "\n";

        header("PROBE_HIT_GRAIN");
        statistics::VCounter probe_hit_vals;
        mgStats.probe_hit_by_grain.value(probe_hit_vals);
        list_by_grain("probe_hit_by_grain", probe_hit_vals);
        out << "\n";

        header("CUSTOM_PARENT_CONTAMINATION");
        kv_u64("custom_parent_shared_hit",
               mgStats.custom_parent_shared_hit.value());
        kv_u64("custom_parent_shared_est_total",
               mgStats.custom_parent_shared_est_total.value());
        statistics::VCounter parent_est_vals;
        mgStats.custom_parent_shared_est_by_grain.value(parent_est_vals);
        list_by_grain("custom_parent_shared_est_by_grain", parent_est_vals);
        out << "\n";

        const uint64_t sharer_count_total = mgStats.sharer_count_total.value();
        const uint64_t sharer_count_samples = mgStats.sharer_count_samples.value();
        const uint64_t sharer_count_avg =
            sharer_count_samples ? (sharer_count_total / sharer_count_samples) : 0;
        mgStats.sharer_count_avg = sharer_count_avg;

        header("SHARER_DISTRIBUTION");
        kv_u64("sharer_count_avg", sharer_count_avg);
        kv_u64("sharer_count_max", mgStats.sharer_count_max.value());
        kv_u64("sharer_count_samples", sharer_count_samples);
        statistics::VCounter sharer_hist_vals;
        mgStats.sharer_count_hist.value(sharer_hist_vals);
        out << "  " << std::left << std::setw(key_width) << "sharer_count_hist"
            << ": ";
	        for (size_t i = 0; i < sharer_hist_vals.size(); ++i) {
	            if (i) {
	                out << " ";
	            }
	            out << i << "_sharers=" << sharer_hist_vals[i];
	        }
	        out << "\n\n";

	        if (mgUseProfilePolicy()) {
	            header("SHATTER_PROFILE");
	            std::vector<uint32_t> thresholds = mgProfileThresholds();

            uint64_t coarse_shared_entries = shatter_profile_regions.size();
            uint64_t coarse_sharer_total = 0;
            uint64_t coarse_sharer_max = 0;
            uint64_t fine_sharer_total = 0;
            uint64_t fine_block_total = 0;
            uint64_t high_dispersion_regions = 0;
            uint64_t profile_access_total = 0;
            uint64_t profile_exclusive_total = 0;
            for (const auto &region : shatter_profile_regions) {
                coarse_sharer_total += region.coarse_sharers;
                coarse_sharer_max =
                    std::max(coarse_sharer_max, region.coarse_sharers);
                fine_sharer_total += region.fine_sharer_total;
                fine_block_total += region.fine_non_empty_blocks;
                profile_access_total += region.access_count;
                profile_exclusive_total += region.exclusive_count;
                if (region.dispersion_ppm >= 2000000ULL) {
                    high_dispersion_regions++;
                }
	            }
	            kv_u64("coarse_shared_entries", coarse_shared_entries);
	            kv_u64("coarse_sharer_avg",
                       coarse_shared_entries
                           ? coarse_sharer_total / coarse_shared_entries
                           : 0);
            kv_u64("coarse_sharer_max", coarse_sharer_max);
            kv_u64("fine_avg_sharers",
                   fine_block_total ? fine_sharer_total / fine_block_total : 0);
            kv_u64("high_dispersion_regions", high_dispersion_regions);
            kv_u64("profile_access_total", profile_access_total);
            kv_u64("profile_exclusive_total", profile_exclusive_total);
            kv_u64("profile_access_avg",
                   coarse_shared_entries
                       ? profile_access_total / coarse_shared_entries
                       : 0);
            kv_u64("profile_exclusive_avg",
                   coarse_shared_entries
                       ? profile_exclusive_total / coarse_shared_entries
                       : 0);
            kv_percent("profile_exclusive_pct",
                       profile_access_total
                           ? (static_cast<double>(profile_exclusive_total) *
                              100.0) /
                                 static_cast<double>(profile_access_total)
                           : 0.0);
            out << "\n";

            out << "  " << std::right
                << std::setw(6) << "thr"
                << std::setw(8) << "cand"
                << std::setw(12) << "acc"
                << std::setw(12) << "excl"
                << std::setw(9) << "max_shr"
                << std::setw(12) << "probe_red"
                << std::setw(12) << "entry_grow"
                << std::setw(12) << "entry_total"
                << std::setw(12) << "grow_pct"
                << std::setw(10) << "score"
                << std::left << "\n";

            out << std::fixed;
            for (uint64_t threshold : thresholds) {
                uint64_t candidate_regions = 0;
                uint64_t candidate_access = 0;
                uint64_t candidate_exclusive = 0;
                uint64_t candidate_max_sharers = 0;
                uint64_t est_entry_growth = 0;
                for (const auto &region : shatter_profile_regions) {
                    if (region.coarse_sharers <= threshold) {
                        continue;
                    }
                    candidate_regions++;
                    candidate_access += region.access_count;
                    candidate_exclusive += region.exclusive_count;
                    candidate_max_sharers =
                        std::max(candidate_max_sharers, region.coarse_sharers);
                    est_entry_growth += region.est_entry_cost;
                }
                const auto reduction_it =
                    shatter_profile_probe_reduction_by_threshold.find(
                        threshold);
                const uint64_t est_probe_reduction =
                    reduction_it !=
                            shatter_profile_probe_reduction_by_threshold.end()
                        ? reduction_it->second
                        : 0;

                const uint64_t est_entry_total =
                    live_entry_total + est_entry_growth;
                const double entry_growth_percent =
                    live_entry_total
                        ? (static_cast<double>(est_entry_total) * 100.0) /
                              static_cast<double>(live_entry_total)
                        : 100.0;
                const double score =
                    est_entry_growth
                        ? static_cast<double>(est_probe_reduction) /
                              static_cast<double>(est_entry_growth)
                        : static_cast<double>(est_probe_reduction);

                out << "  " << std::right
                    << std::setw(6) << threshold
                    << std::setw(8) << candidate_regions
                    << std::setw(12) << candidate_access
                    << std::setw(12) << candidate_exclusive
                    << std::setw(9) << candidate_max_sharers
                    << std::setw(12) << est_probe_reduction
                    << std::setw(12) << est_entry_growth
                    << std::setw(12) << est_entry_total
                    << std::setw(11) << std::setprecision(2)
                    << entry_growth_percent << "%"
                    << std::setw(10) << std::setprecision(4) << score
                    << std::left << "\n";
            }
            out << std::defaultfloat << std::setprecision(6) << "\n";
        }

	        header("REQ_BY_TYPE");
	        statistics::VCounter shared_vals;
        mgStats.obs_shared_by_type.value(shared_vals);
        list_by_type("req_shared_by_type", shared_vals);

        statistics::VCounter exclusive_vals;
        mgStats.obs_exclusive_by_type.value(exclusive_vals);
        list_by_type("req_exclusive_by_type", exclusive_vals);

        statistics::VCounter eviction_vals;
        mgStats.obs_eviction_by_type.value(eviction_vals);
        list_by_type("req_eviction_by_type", eviction_vals);
        kv_u64("req_unknown_type", mgStats.req_unknown_type.value());

        out << "----\n";
    };

    // 每个 DirectoryMemory 对象输出一个文件，便于多目录/多实例区分
    const std::string safe_name = mgSafeName(name());
    const std::string filename = "mg_stats_" + safe_name + ".txt";
    const std::string profile_filename =
        "mg_shatter_profile_" + safe_name + ".csv";

    auto emit_profile_csv = [&](std::ostream &out, bool write_header) {
        if (write_header) {
            out << "tick,object,base,size,access_count,exclusive_count,"
                << "max_sharers,sharer_ids\n";   // 新增列头
        }
        for (const auto &region : shatter_profile_detail_regions) {
            out << curTick() << "," << name() << ",0x"
                << std::hex << region.base << std::dec << ","
                << region.size << "," << region.access_count << ","
                << region.exclusive_count << "," << region.coarse_sharers << ","
                << region.sharer_ids_str << "\n";   // 新增列值
        }
    };

    auto emit_baseline_csv = [&](std::ostream &out, bool write_header) {
        if (write_header) {
            out << "tick,object,base,size,access_count,exclusive_count,"
                   "max_sharers,sharer_ids\n";
        }
        auto it = mg_shatter_profile_regions.find(mg_min_region_grain);
        if (it != mg_shatter_profile_regions.end()) {
            for (const auto &kv : it->second) {
                // 把 sharer_ids 拼成 "CorePair0|TCP3" 形式
                std::string ids_str;
                for (const auto &id : kv.second.sharer_ids) {
                    if (!ids_str.empty()) ids_str += "|";
                    ids_str += id;
                }
                out << curTick() << "," << name() << ",0x"
                    << std::hex << kv.first << std::dec << ","
                    << mg_min_region_grain << ","
                    << kv.second.access_count << ","
                    << kv.second.exclusive_count << ","
                    << kv.second.max_sharers << ","
                    << ids_str << "\n";
            }
        }
    };

    // 输出到 simout（遵循 gem5 outdir 机制）
    if (mg_stats_dir) {
        OutputStream *os = mg_stats_dir->open(
            filename, std::ios::out | std::ios::app, true, true);
        emit_summary(*os->stream());
        mg_stats_dir->close(os);

        if (mgUseProfilePolicy()) {
            const std::string profile_path =
                mg_stats_dir->resolve(profile_filename);
            const bool write_header =
                !std::filesystem::exists(profile_path) ||
                std::filesystem::file_size(profile_path) == 0;
            OutputStream *profile_os = mg_stats_dir->open(
                profile_filename, std::ios::out | std::ios::app, true, true);
            emit_profile_csv(*profile_os->stream(), write_header);
            mg_stats_dir->close(profile_os);
        }
         // 新增：baseline CSV 也写到 mg_stats_dir
        if (mgUseBaselinePolicy()) {
            const std::string baseline_csv_name =
                "mg_baseline_profile_" + safe_name + ".csv";
            const std::string baseline_path =
                mg_stats_dir->resolve(baseline_csv_name);
            const bool write_header =
                !std::filesystem::exists(baseline_path) ||
                std::filesystem::file_size(baseline_path) == 0;
            OutputStream *bout = mg_stats_dir->open(
                baseline_csv_name, std::ios::out | std::ios::app, true, true);
            emit_baseline_csv(*bout->stream(), write_header);
            mg_stats_dir->close(bout);
        }
    }

    // 额外输出到固定目录 mg_run_out
    const std::string tag = !mg_stats_dir_name.empty() ? mg_stats_dir_name
                                                       : mgGrainTag();
    const std::filesystem::path hard_dir =
        std::filesystem::path("mg_run_out") / tag;
    std::error_code ec;
    std::filesystem::create_directories(hard_dir, ec);
    if (!ec) {
        std::ofstream fout(hard_dir / filename, std::ios::out | std::ios::app);
        if (fout.is_open()) {
            emit_summary(fout);
        }
        if (mgUseProfilePolicy()) {
            const std::filesystem::path profile_path =
                hard_dir / profile_filename;
            const bool write_header =
                !std::filesystem::exists(profile_path) ||
                std::filesystem::file_size(profile_path) == 0;
            std::ofstream profile_out(profile_path,
                                      std::ios::out | std::ios::app);
            if (profile_out.is_open()) {
                emit_profile_csv(profile_out, write_header);
            }
        }
        if (mgUseBaselinePolicy()) {
            const std::string baseline_csv_name = "mg_baseline_profile_" + safe_name + ".csv";
            const std::filesystem::path path = hard_dir / baseline_csv_name;
            const bool write_header = !std::filesystem::exists(path) || std::filesystem::file_size(path) == 0;
            std::ofstream bout(path, std::ios::out | std::ios::app);
            if (bout.is_open()) {
                emit_baseline_csv(bout, write_header);
            }
        }
    }
    mgTraceFlush();
}

void
DirectoryMemory::mgTraceSetup()
{
    if (!mgEnabled()) return;
 
    const std::string safe_name = mgSafeName(name());
    const std::string filename = "mg_trace_" + safe_name + ".log";
 
    // 在 simout 子目录下创建追踪文件
    if (mg_stats_dir) {
        const std::string full_path =
            simout.directory() + "/" + mg_stats_dir_name + "/" + filename;
        mg_trace_file.open(full_path, std::ios::out | std::ios::trunc);
        if (mg_trace_file.is_open()) {
            mg_trace_file << "# Multi-Granularity Directory Operation Trace\n";
            mg_trace_file << "# object: " << name() << "\n";
            mg_trace_file << "# policy: " << mgPolicyName() << "\n";
            mg_trace_file << "# grains: ";
            for (size_t i = 0; i < mg_region_grains_asc.size(); ++i) {
                if (i) mg_trace_file << ",";
                mg_trace_file << mgFormatGrain(mg_region_grains_asc[i]);
            }
            mg_trace_file << "\n";
            mg_trace_file << "#\n";
            mg_trace_file << "# SPLIT: parent region broken into children\n";
            mg_trace_file << "#   CONFLICT = child containing the conflicting block\n";
            mg_trace_file << "#   KEPT     = non-conflict child retained (has private blocks)\n";
            mg_trace_file << "#   P=Private S=Shared, followed by owner MachineID\n";
            mg_trace_file << "# MERGE: children combined into parent\n";
            mg_trace_file << "#\n";
            mg_trace_file.flush();
        }
    }
 
    // 额外在 mg_run_out 下也创建
    const std::string tag = !mg_stats_dir_name.empty()
        ? mg_stats_dir_name : mgGrainTag();
    const std::filesystem::path hard_dir =
        std::filesystem::path("mg_run_out") / tag;
    std::error_code ec;
    std::filesystem::create_directories(hard_dir, ec);
    // mg_run_out 的追踪文件在 flush 时按需写入（共用 mg_trace_buffer）
}
 
void
DirectoryMemory::mgTraceFinalize()
{
    mgTraceFlush();
    if (mg_trace_file.is_open()) {
        mg_trace_file << "# END total_split="
                      << mgStats.trace_split_events.value()
                      << " total_merge="
                      << mgStats.trace_merge_events.value()
                      << " total_eviction="
                      << mgStats.trace_eviction_events.value()
                      << "\n";
        mg_trace_file.close();
    }
}
 
std::string
DirectoryMemory::mgTraceFormatEntry(const MgTraceEntry &entry) const
{
    std::ostringstream out;
 
    // 操作类型
    if (entry.op == MgTraceEntry::Op::Split) {
    out << "SPLIT";
    } else if (entry.op == MgTraceEntry::Op::Merge) {
        out << "MERGE";
    } else {
        out << "EVICT";
    }
 
    // 时间戳与父条目范围
    out << " tick=" << entry.tick
        << " parent=[0x" << std::hex << entry.parent_base
        << ",0x" << (entry.parent_base + entry.parent_size) << ")"
        << std::dec
        << " psize=" << mgFormatGrain(entry.parent_size)
        << " tsize=" << mgFormatGrain(entry.target_size);
 
    // Split 特有：冲突信息
    if (entry.op == MgTraceEntry::Op::Split) {
        out << " conflict_blk=0x" << std::hex << entry.conflict_block
            << std::dec
            << " req=" << entry.requestor
            << " owner=" << entry.owner
            << " excl=" << (entry.want_excl ? "Y" : "N");
    } else if (entry.op == MgTraceEntry::Op::Merge) {
        out << " merged_owner=" << entry.owner;
    } else {
        // Eviction
        out << " evict_blk=0x" << std::hex << entry.conflict_block
            << std::dec
            << " req=" << entry.requestor;
    }
 
    // 子条目列表
    out << " nchildren=" << entry.children.size();
    for (size_t i = 0; i < entry.children.size(); ++i) {
        const auto &c = entry.children[i];
        out << "\n  child[" << i << "] "
            << "[0x" << std::hex << c.base
            << ",0x" << (c.base + c.size) << ")"
            << std::dec
            << " " << mgFormatGrain(c.size);
 
        if (entry.op == MgTraceEntry::Op::Eviction) {
            // Eviction 专用：显示前后状态变化
            out << (c.prev_state == MgState::Private ? " [WAS P]" : " [WAS S]");
            if (c.was_deleted) {
                out << " DELETED";
            } else {
                out << " UPGRADED->P";  // Shared → Private
            }
        } else if (c.is_conflict) {
            out << " CONFLICT";
        } else if (c.is_sparse_keep) {
            out << " KEPT";
        } else {
            out << " MERGED";
        }
 
        if (c.state == MgState::Private) {
            out << " P";
            if (c.owner) {
                out << " owner=" << c.owner.value();
            }
        } else {
            out << " S";
        }
    }
 
    return out.str();
}
 
void
// 记录一次 split 事件到 trace 缓冲区并在必要时触发 flush。
DirectoryMemory::mgTraceLogSplit(const MgTraceEntry &entry)
{
    mgStats.trace_split_events++;
    mg_trace_buffer.push_back(entry);
    if (mg_trace_buffer.size() >= MgTraceFlushThreshold) {
        mgTraceFlush();
    }
}
 
void
// 记录一次 merge 事件到 trace 缓冲区并在必要时触发 flush。
DirectoryMemory::mgTraceLogMerge(const MgTraceEntry &entry)
{
    mgStats.trace_merge_events++;
    mg_trace_buffer.push_back(entry);
    if (mg_trace_buffer.size() >= MgTraceFlushThreshold) {
        mgTraceFlush();
    }
}
 
void
// 记录一次 eviction 事件到 trace 缓冲区并在必要时触发 flush。
DirectoryMemory::mgTraceLogEviction(const MgTraceEntry &entry)
{
    mgStats.trace_eviction_events++;
    mg_trace_buffer.push_back(entry);
    if (mg_trace_buffer.size() >= MgTraceFlushThreshold) {
        mgTraceFlush();
    }
}

void
// 将当前累积的 trace 缓冲内容批量写入日志文件。
DirectoryMemory::mgTraceFlush()
{
    if (!mg_trace_file.is_open() || mg_trace_buffer.empty()) return;
 
    for (const auto &e : mg_trace_buffer) {
        mg_trace_file << mgTraceFormatEntry(e) << "\n";
    }
    mg_trace_buffer.clear();
    mg_trace_file.flush();
}

// 粒度统计结束
// =====================================================================
// 递归获取顶级父条目 (Root)
DirectoryMemory::MgEntry *
DirectoryMemory::mgGetRoot(MgEntry *entry)
{
    MgEntry *curr = entry;
    // 不断沿着 parent_base 向上爬，直到没有 parent 为止
    while (curr && curr->has_parent) {
        MgEntry *parent = mgFindEntryAtSize(curr->parent_base, curr->parent_size);
        if (!parent) break;
        curr = parent;
    }
    return curr;
}

// 递归删除整棵多粒度树
void
DirectoryMemory::mgEraseTree(MgEntry *entry)
{
    if (!entry) return;
    const Addr base = entry->base;
    const uint32_t size = entry->size;
    const uint32_t child_size = mgCustomNextSmallerSize(size);

    // 如果有更细粒度的层级，检查 mask 并递归删除子节点
    if (child_size > 0) {
        const uint32_t num_children = size / child_size;
        for (uint32_t i = 0; i < num_children; ++i) {
            if (mgIsChildDelegated(*entry, i)) {
                Addr child_base = base + i * child_size;
                MgEntry *child = mgFindEntryAtSize(child_base, child_size);
                if (child) {
                    mgEraseTree(child);
                }
            }
        }
    }
    // 子节点都删干净了，最后删除自己
    mgEraseEntry(base, size, MgChurnCause::Split);
}

// 彻底打碎膨胀的大条目
void
DirectoryMemory::mgShatterSharedEntry(MgEntry &entry)
{
    // 1. 找到整棵树的根节点 (比如 32KiB 的条目)
    MgEntry *root = mgGetRoot(&entry);
    if (!root) return;

    const Addr root_base = root->base;
    const uint32_t root_size = root->size;

    // 2. 彻底销毁这棵树（包括根节点和所有已下放的子节点），防止留下悬空指针
    mgEraseTree(root);
    mgStats.split_actual++;

    // 3. 遍历底层触碰记录，将这片大区域内所有【真实存活】的 64B 块提取出来，变成独立的碎块根节点
    std::vector<Addr> blocks_to_merge;
    for (Addr blk = root_base; blk < root_base + root_size; blk += m_block_size) {
        auto it = mg_block_states.find(blk);
        if (it != mg_block_states.end()) {
            MgEntry child;
            child.base = blk;
            child.size = m_block_size;
            child.line = it->second; // 继承该 64B 块真实的 Owner 或 Sharers
            child.is_shattered = true; // 打上碎块烙印
            child.has_parent = false;  // 已经没有树了，大家都是独立的 Root
            mgInsertEntry(child, MgChurnCause::Split);
            blocks_to_merge.push_back(blk);
        }
    }

    // 4. 碎块就绪，立刻触发底层相邻合并（Bottom-up）
    for (Addr blk : blocks_to_merge) {
        mgTryMergeLocked(blk, m_block_size);
    }
}
void
// 观测到读共享/读类型请求（如 RdBlk/RdBlkS）
DirectoryMemory::mgObserveSharedRead(Addr address, MachineID requestor)
{
    if (!mgEnabled()) {
        return;
    }
    // std::lock_guard 退出该作用域会自动 unlock，构建时自动 lock
    std::lock_guard<std::mutex> guard(mg_mutex);

    const Addr block_base = mgBlockBase(address);
    if (!mgRegionFitsRanges(block_base, m_block_size)) {
        // 该地址不属于本目录的 addr_ranges（或跨目录 interleave 边界） 不记录元数据 输出调试信息
        static int mg_skip_sr_prints = 0;
        const int max_prints = 16;
        if (mg_skip_sr_prints < max_prints) {
            mg_skip_sr_prints++;
            warn("mg: skip shared-read addr=%#x block_base=%#x (out of range)\n",
                 address, block_base);
            if (mg_skip_sr_prints == max_prints) {
                warn("mg: further shared-read skip prints suppressed\n");
            }
        }
        return;
    }

    // 目录观察到一次 shared-read
    mgStats.obs_shared++;
    mgStats.obs_total++;
    mgCountByRequestor(mgStats.obs_shared_by_type, requestor);
    MgEntry *entry = mgFindEntry(block_base);
    if (!entry) {
        entry = mgGetOrAllocEntry(block_base, /*excl*/false, requestor);
        if (!entry) {
            return;
        }
    }

    if (entry->line.state == MgState::Private && entry->line.owner &&
        entry->line.owner.value() != requestor) {
        mgSplitPrivateOnConflict(*entry, block_base, requestor,
                                 /*want_excl*/false);
        entry = mgFindEntry(block_base);
    }

    bool block_state_updated = false;
    auto update_block_state = [&]() {
        if (block_state_updated) {
            return;
        }

        auto blk_it = mg_block_states.find(block_base);
        if (blk_it == mg_block_states.end()) {
            MgLineInfo line;
            if (entry && entry->line.state == MgState::Private &&
                entry->line.owner &&
                entry->line.owner.value() == requestor) {
                line.state = MgState::Private;
                line.owner = requestor;
                line.sharers.clear();
            } else {
                line.state = MgState::Shared;
                line.owner.reset();
                line.sharers.clear();
                if (entry && entry->line.state == MgState::Private &&
                    entry->line.owner) {
                    line.sharers.insert(entry->line.owner.value());
                }
                line.sharers.insert(requestor);
            }

            auto [it, inserted] =
                mg_block_states.emplace(block_base, std::move(line));
            if (inserted) {
                mgStats.block_state_live++;
            }
        } else {
            MgLineInfo &line = blk_it->second;
            if (line.state == MgState::Private) {
                if (!line.owner) {
                    line.state = MgState::Shared;
                    line.sharers.clear();
                    line.sharers.insert(requestor);
                } else if (line.owner.value() != requestor) {
                    const MachineID old_owner = line.owner.value();
                    line.state = MgState::Shared;
                    line.owner.reset();
                    line.sharers.clear();
                    line.sharers.insert(old_owner);
                    line.sharers.insert(requestor);
                }
            } else {
                line.sharers.insert(requestor);
            }
        }

        block_state_updated = true;
    };

    if (entry && entry->line.state == MgState::Shared) {
        entry->line.sharers.insert(requestor);
        mgRecordSharerSample(entry->line.sharers.size());
        mgRecordShatterProfileAccess(*entry, /*is_exclusive*/false);
        if (!mgUseProfilePolicy() && mgUseCustomPolicy() &&
            entry->line.sharers.size() > mg_shatter_threshold &&
            entry->size > mg_min_region_grain && !entry->is_shattered) {
            // shatter 依赖 mg_block_states 重建 64B entry，必须先记录当前访问块。
            update_block_state();
            mgShatterSharedEntry(*entry);
            entry = mgFindEntry(block_base);
        }
    }

    update_block_state();

    // 🌟 【新增代码】为 Baseline 记录 64B 的访问画像
    if (mgUseBaselinePolicy() && entry) {
        auto &region = mg_shatter_profile_regions[mg_min_region_grain][block_base];
        region.access_count++;
        region.max_sharers = std::max<uint64_t>(
            region.max_sharers, entry->line.sharers.size()
        );
        // 记录具体的 requestor ID
        const std::string rid = MachineType_to_string(requestor.type)
                                + std::to_string(requestor.num);
        region.sharer_ids.insert(rid);
    }
}

void
DirectoryMemory::mgObserveExclusive(Addr address, MachineID requestor)
{
    if (!mgEnabled()) {
        return;
    }
    std::lock_guard<std::mutex> guard(mg_mutex);

    const Addr block_base = mgBlockBase(address);
    if (!mgRegionFitsRanges(block_base, m_block_size)) {
        // 该地址不属于本目录的 addr_ranges（或跨目录 interleave 边界），不记录元数据
        static int mg_skip_ex_prints = 0;
        const int max_prints = 16;
        if (mg_skip_ex_prints < max_prints) {
            mg_skip_ex_prints++;
            warn("mg: skip exclusive addr=%#x block_base=%#x (out of range)\n",
                 address, block_base);
            if (mg_skip_ex_prints == max_prints) {
                warn("mg: further exclusive skip prints suppressed\n");
            }
        }
        return;
    }

    // 目录观察到一次 exclusive 请求（由协议 hook 调用）
    mgStats.obs_exclusive++;
    mgStats.obs_total++;
    mgCountByRequestor(mgStats.obs_exclusive_by_type, requestor);
    MgEntry *entry = mgFindEntry(block_base);
    if (!entry) {
        entry = mgGetOrAllocEntry(block_base, /*excl*/true, requestor);
        if (!entry) {
            return;
        }
    }

    if (entry->line.state == MgState::Private && entry->line.owner &&
        entry->line.owner.value() != requestor) {
        mgSplitPrivateOnConflict(*entry, block_base, requestor,
                                 /*want_excl*/true);
        entry = mgFindEntry(block_base);
	    } else if (entry->line.state == MgState::Shared) {
	        mgRecordShatterProfileAccess(*entry, /*is_exclusive*/true);
	        if (entry->line.sharers.size() == 1 &&
	            entry->line.sharers.find(requestor) != entry->line.sharers.end()) {
            entry->line.state = MgState::Private;
            entry->line.owner = requestor;
            entry->line.sharers.clear();
            mgTryMergeLocked(entry->base, entry->size);
        } else if (mgUseBaselinePolicy()) {
            // baseline 固定为 64B 条目，独占写命中 shared 时直接升级当前块为私有。
            entry->line.state = MgState::Private;
            entry->line.owner = requestor;
            entry->line.sharers.clear();
        } else if (mgUseAcgPolicy()) {
            if (entry->size == mg_min_region_grain) {
                entry->line.state = MgState::Private;
                entry->line.owner = requestor;
                entry->line.sharers.clear();
                mgTryMergeLocked(entry->base, entry->size);
            } else {
                MgLineInfo child_line;
                child_line.state = MgState::Private;
                child_line.owner = requestor;
                child_line.sharers.clear();
                mgAcgCreateBlockException(*entry, block_base, child_line,
                                          requestor, std::nullopt,
                                          /*want_excl*/true,
                                          /*count_attempt*/true,
                                          /*record_private_break*/false);
                entry = mgFindEntry(block_base);
                mgTryMergeLocked(mgBlockBase(block_base), mg_min_region_grain);
            }
        } else if (mgUseCustomPolicy() && entry->size > mg_min_region_grain) {
            const uint32_t child_size = mgCustomNextSmallerSize(entry->size);
            fatal_if(child_size == 0,
                     "custom policy missing next child grain for %u",
                     entry->size);

            const uint32_t child_idx = mgCustomChildIndex(*entry, block_base);
            const Addr child_base = mgCustomChildBase(*entry, child_idx);
            fatal_if(mgIsChildDelegated(*entry, child_idx),
                     "shared custom carve-out requested on delegated child "
                     "parent=%#x size=%u child=%#x size=%u",
                     entry->base, entry->size, child_base, child_size);
            fatal_if(mgFindEntryAtSize(child_base, child_size),
                     "shared custom carve-out would create duplicate child "
                     "at %#x size %u",
                     child_base, child_size);

            const size_t from_idx = mgGrainIndex(entry->size);
            const size_t to_idx = mgGrainIndex(child_size);
            if (from_idx != MgInvalidIndex && to_idx != MgInvalidIndex) {
                const size_t n = mg_region_grains_asc.size();
                const size_t pair_idx = from_idx * n + to_idx;
                if (pair_idx < mgStats.split_transition_by_grain.size()) {
                    mgStats.split_transition_by_grain[pair_idx]++;
                }
            }
            mgStats.split_actual++;
            if (from_idx != MgInvalidIndex) {
                mgStats.grain_split_parent[from_idx]++;
            }

            MgTraceEntry trace;
            trace.op = MgTraceEntry::Op::Split;
            trace.tick = curTick();
            trace.parent_base = entry->base;
            trace.parent_size = entry->size;
            trace.target_size = child_size;
            trace.conflict_block = block_base;
            trace.requestor = requestor;
            trace.owner = MachineID();
            trace.want_excl = true;

            MgEntry child;
            child.base = child_base;
            child.size = child_size;
            child.line = entry->line;
            child.line.state = MgState::Private;
            child.line.owner = requestor;
            child.line.sharers.clear();
            child.has_parent = true;
            child.parent_base = entry->base;
            child.parent_size = entry->size;

            mgSetChildDelegated(*entry, child_idx, true);
            mgInsertEntry(child, MgChurnCause::Split);

            MgTraceEntry::ChildInfo ci;
            ci.base = child.base;
            ci.size = child.size;
            ci.is_conflict = true;
            ci.is_sparse_keep = false;
            ci.state = child.line.state;
            ci.owner = child.line.owner;
            trace.children.push_back(ci);
            mgTraceLogSplit(trace);

            entry = mgFindEntry(block_base);
        }
    }

    // exclusive 会让该 block 的触碰记录趋向 PRIVATE(requestor)
    auto [it, inserted] = mg_block_states.emplace(block_base, MgLineInfo{});
    if (inserted) {
        mgStats.block_state_live++;
    }
    MgLineInfo &line = it->second;
    line.state = MgState::Private;
    line.owner = requestor;
    line.sharers.clear();

    // 🌟 【新增代码】为 Baseline 记录 64B 的写请求与访问画像
    if (mgUseBaselinePolicy()) {
        auto &region = mg_shatter_profile_regions[mg_min_region_grain][block_base];
        region.access_count++;
        region.exclusive_count++;
        region.max_sharers = std::max<uint64_t>(region.max_sharers, 1);
        // 记录具体的 requestor ID
        const std::string rid = MachineType_to_string(requestor.type)
                                + std::to_string(requestor.num);
        region.sharer_ids.insert(rid);
    }
}

void
DirectoryMemory::mgObserveEviction(Addr address, MachineID requestor)
{
    if (!mgEnabled()) {
        return;
    }
    std::lock_guard<std::mutex> guard(mg_mutex);

    const Addr block_base = mgBlockBase(address);
    if (!mgRegionFitsRanges(block_base, m_block_size)) {
        // 该地址不属于本目录的 addr_ranges（或跨目录 interleave 边界），不记录元数据
        static int mg_skip_ev_prints = 0;
        const int max_prints = 16;
        if (mg_skip_ev_prints < max_prints) {
            mg_skip_ev_prints++;
            warn("mg: skip eviction addr=%#x block_base=%#x (out of range)\n",
                 address, block_base);
            if (mg_skip_ev_prints == max_prints) {
                warn("mg: further eviction skip prints suppressed\n");
            }
        }
        return;
    }
    
    // 目录观察到一次 eviction/writeback（由协议 hook 调用）
    mgStats.obs_eviction++;
    mgStats.obs_total++;
    mgCountByRequestor(mgStats.obs_eviction_by_type, requestor);
    auto blk_it = mg_block_states.find(block_base);
    if (blk_it != mg_block_states.end()) {
        MgLineInfo &line = blk_it->second;
        if (line.state == MgState::Private) {
            if (line.owner && line.owner.value() == requestor) {
                // 触碰记录删除：该 block 不再被认为驻留在 requestor 私有缓存
                mg_block_states.erase(blk_it);
                if (mgStats.block_state_live.value() > 0) {
                    mgStats.block_state_live--;
                }
            }
        } else {
            line.sharers.erase(requestor);
            if (line.sharers.empty()) {
                // sharers 清空：删除触碰记录
                mg_block_states.erase(blk_it);
                if (mgStats.block_state_live.value() > 0) {
                    mgStats.block_state_live--;
                }
            } else if (line.sharers.size() == 1) {
                const MachineID new_owner = *line.sharers.begin();
                line.state = MgState::Private;
                line.owner = new_owner;
                line.sharers.clear();
            }
        }
    }
    MgEntry *entry = mgFindEntry(block_base);
    if (!entry) {
        return;
    }
    if (mgUseAcgPolicy()) {
        // ACG 的粗粒度区域项保留为背景语义，单个 block eviction 只处理最细 block 例外项。
        if (entry->size != mg_min_region_grain) {
            return;
        }
    } else if (mgUseCustomPolicy() && !entry->has_parent &&
               entry->size != mg_min_region_grain) {
        return;
    } else if (!mgUseCustomPolicy() && entry->size != mg_min_region_grain) {
        return;
    }

    if (entry->line.state == MgState::Shared) {
        entry->line.sharers.erase(requestor);
        mgRecordSharerSample(entry->line.sharers.size());
        if (entry->line.sharers.empty()) {
            if (mgUseAcgPolicy()) {
                mgEraseEntry(entry->base, entry->size, MgChurnCause::Eviction);
                return;
            }
            if (mgUseCustomPolicy() && entry->has_parent) {
                MgEntry *parent = mgFindEntryAtSize(entry->parent_base,
                                                    entry->parent_size);
                if (parent) {
                    entry->line = parent->line;
                    if (!mgEntryHasDelegatedChildren(*entry)) {
                        mgTryMergeLocked(entry->base, entry->size);
                    }
                    return;
                }
            }
            mgEraseEntry(entry->base, entry->size, MgChurnCause::Eviction);
            return;
        }
        if (entry->line.sharers.size() == 1) {
            const MachineID new_owner = *entry->line.sharers.begin();
            entry->line.state = MgState::Private;
            entry->line.owner = new_owner;
            entry->line.sharers.clear();
            mgTryMergeLocked(entry->base, entry->size);
            return;
        }
    } else if (entry->line.state == MgState::Private) {
        if (entry->line.owner && entry->line.owner.value() == requestor) {
            if (mgUseAcgPolicy()) {
                mgEraseEntry(entry->base, entry->size, MgChurnCause::Eviction);
                return;
            }
            if (mgUseCustomPolicy() && entry->has_parent) {
                MgEntry *parent = mgFindEntryAtSize(entry->parent_base,
                                                    entry->parent_size);
                if (parent) {
                    entry->line = parent->line;
                    if (!mgEntryHasDelegatedChildren(*entry)) {
                        mgTryMergeLocked(entry->base, entry->size);
                    }
                    return;
                }
            }
            mgEraseEntry(entry->base, entry->size, MgChurnCause::Eviction);
            return;
        }
    }
}

} // namespace ruby
} // namespace gem5
