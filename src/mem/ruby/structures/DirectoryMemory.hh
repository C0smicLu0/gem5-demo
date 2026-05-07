#ifndef __MEM_RUBY_STRUCTURES_DIRECTORYMEMORY_HH__
#define __MEM_RUBY_STRUCTURES_DIRECTORYMEMORY_HH__

#include <cstdint>
#include <iostream>
#include <limits>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <fstream>
#include <set>

#include "base/addr_range.hh"
// gem5 统计框架（出现在 stats.txt 中）
#include "base/statistics.hh"
#include "mem/ruby/common/Address.hh"
#include "mem/ruby/common/MachineID.hh"
#include "mem/ruby/protocol/DirectoryRequestType.hh"
#include "mem/ruby/protocol/MessageSizeType.hh"
#include "mem/ruby/slicc_interface/AbstractCacheEntry.hh"
#include "params/RubyDirectoryMemory.hh"
#include "sim/sim_object.hh"

namespace gem5
{
// simout 输出目录对象（gem5 提供）
class OutputDirectory;
}

namespace gem5
{

namespace ruby
{

class DirectoryMemory : public SimObject
{
  public:
    typedef RubyDirectoryMemoryParams Params;
    DirectoryMemory(const Params &p);
    ~DirectoryMemory();

    void init();

    /**
     * Return the index in the directory based on an address
     *
     * This function transforms an address which belongs to a not
     * necessarily continuous vector of address ranges into a flat
     * address that we use to index in the directory
     *
     * @param an input address
     * @return the corresponding index in the directory
     *
     */
    uint64_t mapAddressToLocalIdx(Addr address);

    uint64_t getSize() { return m_size_bytes; }

    bool isPresent(Addr address);
    AbstractCacheEntry *lookup(Addr address);
    AbstractCacheEntry *allocate(Addr address, AbstractCacheEntry* new_entry);

    // Explicitly free up this address
    void deallocate(Addr address);

    void print(std::ostream& out) const;
    void recordRequestType(DirectoryRequestType requestType);

    // Directory/LLC coherence traffic accounting:
    //  - SG(real): actual traffic observed in current single-granularity protocol.
    //  - MG(est):  estimated traffic if multi-granularity metadata were used
    //              for probe destination precision.
    // 估算一次 probe 在多粒度目录视角下需要通知多少个目标。
    int mgEstimateProbeFanout(Addr address, MachineID requestor,
                              bool is_invalidation, int fallback_fanout);
    // 记录目录 probe 流量的真实单粒度口径与多粒度估计口径。
    void mgRecordProbeTraffic(MessageSizeType msg_size, int fanout_sg,
                              int fanout_mg_est);
    // 记录目录返回 response 消息的流量。
    void mgRecordResponseTraffic(MessageSizeType msg_size, int fanout);
    // 记录目录发往内存侧请求的流量。
    void mgRecordMemTraffic(MessageSizeType msg_size);
    // 记录目录发送 trigger 控制消息的流量。
    void mgRecordTriggerTraffic(MessageSizeType msg_size);

	// mgObserveSharedRead：观测到读共享/读类型请求（如 RdBlk/RdBlkS）。
	// mgObserveExclusive：观测到独占/写意图请求（如 RdBlkM）。
	// mgObserveEviction：观测到逐出/回写类事件（如 VicClean/VicDirty）。
	void mgObserveSharedRead(Addr address, MachineID requestor);
	void mgObserveExclusive(Addr address, MachineID requestor);
	void mgObserveEviction(Addr address, MachineID requestor);

  private:
    // Private copy constructor and assignment operator
    DirectoryMemory(const DirectoryMemory& obj);
    DirectoryMemory& operator=(const DirectoryMemory& obj);

  private:
	    // 影子目录的“语义状态”：
	    // Private：该范围在影子视角下可视为“单一 owner 私有”
	    // Shared：该范围在影子视角下由多个 sharer 共享
	    enum class MgState : uint8_t
	    {
	        Private,
	        Shared,
	    };

        enum class MgPolicy : uint8_t
	        {
	            Ideal,
	            Custom,
	            Acg,
	            Baseline,
	            Profile,
	        };

	    struct MgLineInfo
	    {
	        // 影子状态：Private / Shared
	        MgState state = MgState::Shared;
	        // 当 state==Private 时有效：该范围/该块的默认 owner（MachineID）
	        std::optional<MachineID> owner;
	        // 当 state==Shared 时有效：共享者集合（MachineID set）
	        std::unordered_set<MachineID> sharers;
			    };

            struct MgShatterProfileRegion
            {
                uint64_t access_count = 0;
                uint64_t exclusive_count = 0;
                uint64_t max_sharers = 0;
                std::set<std::string> sharer_ids;
            };

		    struct MgEntry
		    {
		        // 覆盖范围起点：必须对齐到 size（base = align(addr, size)）
		        Addr base = 0;
		        // 覆盖范围大小（粒度，单位 bytes，例如 64B/512B/1KiB）
		        uint32_t size = 0;
		        // 覆盖范围的默认影子语义（Private/Shared + owner/sharers）
		        MgLineInfo line;
                // custom 模式：动态位图，记录下一层哪些子区已经下放给更细粒度条目。
                std::vector<uint64_t> delegated_mask;
                // custom 模式：父子关联。顶层条目 has_parent=false。
                Addr parent_base = 0;
                uint32_t parent_size = 0;
                bool has_parent = false;
                // ACG 模式：标记该条目是否是由粗粒度区域 carve-out 出来的例外项。
                bool acg_exception = false;
                // [新增]：标记该条目是否是由“大于4个sharer”的规则打碎并重新相邻合并而来的
                bool is_shattered = false;
		    };

		    // 将“MgEntry 的插入/删除（entry churn）”归因到不同来源事件。
		    // 注意：这是影子目录的内部统计口径，用于分析目录元数据维护开销；
		    // 不会改变 GPU_VIPER 协议语义与消息流。
		    enum class MgChurnCause : uint8_t
		    {
		        Alloc,    // 冷启动分配：首次触碰创建 entry
		        Split,    // 拆分：删除父 entry / 创建子 entry
		        Merge,    // 合并：删除子 entry / 创建父 entry
		        Eviction, // 驱逐/回写：导致 entry 被删除（通常最小粒度条目）
		        Other,    // 其他路径（兜底）
		    };

    // 多粒度影子目录的统计集合：
    // 一部分作为 gem5 stats（stats.txt 可见）
    // 同时我们会在 simout 下单独输出一份可读摘要文件，方便按粒度配置归档对比
    struct MgStats : public statistics::Group
    {
        MgStats(statistics::Group *parent);

        // 根据粒度集合初始化所有“按粒度统计”的 vector
        void initGrains(const std::vector<uint32_t> &grains);

        // 行为统计（事件计数）
        statistics::Scalar obs_shared;
        statistics::Scalar obs_exclusive;
        statistics::Scalar obs_eviction;
        // 所有观测请求总数（obs_shared + obs_exclusive + obs_eviction）
        statistics::Scalar obs_total;

        // split：coarse private 遇到其他 requestor 的次数 / 实际发生拆分的次数（parent_size > min）
        statistics::Scalar split_attempts;
        statistics::Scalar split_actual;

        // merge：尝试次数 / 成功次数
        statistics::Scalar merge_attempts;
        statistics::Scalar merge_success;

        // 冷启动分配：新分配次数 / 分配失败次数（没有任何粒度能 fit，通常是 overlap 或 out-of-range）
        statistics::Scalar alloc_new;
        statistics::Scalar alloc_fail;

        // 触碰记录（mg_block_states）规模
        statistics::Scalar block_state_live;

        // requestor.type 非法/未知时的计数（用于排查分类规则是否覆盖完全）
        statistics::Scalar req_unknown_type;

        // CPU GPU 打破 private 统计
        // 当命中一个 PRIVATE entry 且 requestor != owner 时，认为“private 被打破”
        // 这里统计打破的方向：CPU owner 被 GPU 打破 / GPU owner 被 CPU 打破 等
        statistics::Scalar private_break_cpu_owner_gpu_req;
        statistics::Scalar private_break_gpu_owner_cpu_req;
        statistics::Scalar private_break_cpu_owner_cpu_req;
        statistics::Scalar private_break_gpu_owner_gpu_req;
        statistics::Scalar private_break_unknown;

        // 按请求者类型统计（MachineType）
        statistics::Vector obs_shared_by_type;
        statistics::Vector obs_exclusive_by_type;
        statistics::Vector obs_eviction_by_type;

        // 按粒度统计
        // 每个 vector 的下标对应 mg_region_grains_asc 的顺序（通过 mg_grain_to_index 映射）
        statistics::Vector grain_entry_live;
        statistics::Vector grain_alloc_new;
        // 统计每次实际拆分时的父粒度。
        // ideal/custom/acg 都会在“实际创建新子条目/例外项”时记录一次父粒度，
        // 因此该向量反映的是：哪些父粒度最常被直接打破。
        statistics::Vector grain_split_parent;
        statistics::Vector grain_merge_success;

        // “CPU owner 被 GPU 打破 / GPU owner 被 CPU 打破”的按粒度统计
        statistics::Vector grain_private_break_cpu_owner_gpu_req;
        statistics::Vector grain_private_break_gpu_owner_cpu_req;

        // Coverage（按粒度的覆盖字节与覆盖占比）
        // live_coverage_bytes：当前 live entry 覆盖的字节数（按粒度累加）
        statistics::Vector grain_live_coverage_bytes;
        // live_coverage_ratio_ppm：coverage bytes / live_coverage_total_bytes（ppm）
        statistics::Vector grain_live_coverage_ratio_ppm;

        // Fragmentation（派生统计）
        // live entry 总数 / 总覆盖字节
        statistics::Scalar live_entry_total;
        statistics::Scalar live_coverage_total_bytes;
        // 平均每个 entry 覆盖的字节数（= 总覆盖字节 / entry 总数）
        statistics::Scalar eff_bytes_per_entry;
        // 按 entry 数加权的平均粒度大小（与 eff_bytes_per_entry 等价，但保留便于对比）
        statistics::Scalar avg_grain_size_weighted_by_entries;
        // 最小粒度的覆盖占比（ppm）
        statistics::Scalar min_grain_coverage_ratio_ppm;

	    // Churn（结构抖动/维护成本）
	    // 结构变化总量：entry_inserts + entry_erases
	    statistics::Scalar entry_churn_total;
	    // entry_churn_total 的来源分布：分别由 alloc/split/merge/eviction 引起的增删次数
	    statistics::Scalar entry_churn_alloc;
        statistics::Scalar entry_churn_split;
        statistics::Scalar entry_churn_merge;
        statistics::Scalar entry_churn_eviction;
        // churn 的“粒度分布”（alloc/eviction 发生在哪些粒度上）
        statistics::Vector churn_alloc_by_grain;
        statistics::Vector churn_eviction_by_grain;
        // churn 的“粒度转移”（split/merge 从什么粒度 -> 什么粒度）
        // 使用 N×N 向量（N = 粒度个数），下标映射：from_idx * N + to_idx
        statistics::Vector split_transition_by_grain;
        statistics::Vector merge_transition_by_grain;
        // 归一化到每 1000 次观测请求
        statistics::Scalar entry_churn_per_1k_obs;
        statistics::Scalar split_actual_per_1k_obs;
        statistics::Scalar merge_success_per_1k_obs;

        // Coherence traffic stats (bytes/messages)
        statistics::Scalar dir_probe_msgs_sg;
        statistics::Scalar dir_probe_bytes_sg;
        statistics::Scalar dir_probe_msgs_mg_est;
        statistics::Scalar dir_probe_bytes_mg_est;
        statistics::Scalar dir_response_msgs_sg;
        statistics::Scalar dir_response_bytes_sg;
        statistics::Scalar dir_mem_msgs_sg;
        statistics::Scalar dir_mem_bytes_sg;
        statistics::Scalar dir_trigger_msgs_sg;
        statistics::Scalar dir_trigger_bytes_sg;
        statistics::Scalar dir_total_msgs_sg;
        statistics::Scalar dir_total_bytes_sg;
        statistics::Scalar dir_total_msgs_mg_est;
        statistics::Scalar dir_total_bytes_mg_est;
        statistics::Scalar probe_msg_reduction_est;
        statistics::Scalar probe_byte_reduction_est;

        // Sharer distribution（shared 条目的 sharer 数分布）
        statistics::Scalar sharer_count_total;
        statistics::Scalar sharer_count_samples;
        statistics::Scalar sharer_count_avg;
        statistics::Scalar sharer_count_max;
        statistics::Vector sharer_count_hist;

        // Probe 命中的条目粒度分布
        statistics::Vector probe_hit_by_grain;

        statistics::Scalar custom_parent_shared_hit;
        statistics::Scalar custom_parent_shared_est_total;
        statistics::Vector custom_parent_shared_est_by_grain;

        // 操作追踪计数
        statistics::Scalar trace_split_events;
        statistics::Scalar trace_merge_events;
        statistics::Scalar trace_eviction_events;
	    };

    // 初始化/校验多粒度配置（粒度集合、对齐、64B 倍数）
    void mgInit();

	    // 多粒度目录是否启用：必须显式开启且粒度集合非空
	    // mg_region_grains 里必须包含 64B（最小粒度），其余粒度用于 region entry
	    bool mgEnabled() const { return mg_enable && !mg_region_grains.empty(); }

    // 将任意地址对齐到其所在 64B block 的 base（最小粒度固定为 64B）
    Addr mgBlockBase(Addr address) const;

    // 将任意地址对齐到其所在 region 的 base（region_size 必须为 2 的幂）
    Addr mgRegionBase(Addr address, uint32_t region_size) const;

    // 判断 [base, base+size) 是否完全落在同一个 directory 的 addrRange 内
    // 用于避免 region 跨越多个 directory controller/范围
    bool mgRegionFitsRanges(Addr base, uint32_t size) const;

    // 冷启动分配策略：ideal/custom/profile 选择最大可用粒度，acg 固定从 64B 起分配。
    uint32_t mgChooseAllocSize(Addr block_base) const;

    // 判断候选范围是否与已有 entry 重叠（用于避免稀疏 split 后产生覆盖冲突）
    bool mgHasEntryOverlap(Addr base, uint32_t size) const;

    // 获取比当前粒度更小的一档粒度（来自配置集合），若不存在返回 0
    uint32_t mgNextSmallerSize(uint32_t size) const;

    // 获取比当前粒度更大的一档粒度（来自配置集合），若不存在返回 0
    uint32_t mgNextLargerSize(uint32_t size) const;

    // 查找覆盖该 block 的“当前实际负责条目”。
    // ideal 模式下依赖“父条目删除”，通常是唯一覆盖项；
    // custom 模式下会先命中父条目，再沿 delegated child 逐级向下钻取；
    // acg 模式下允许粗粒度项和例外项重叠，遵循 finest entry wins。
    MgEntry *mgFindEntry(Addr block_base);

    enum class MgFindKind : uint8_t {
        None,
        Standard,
        BaselineLeaf,
        CustomParent,
        CustomChild,
        CustomRootLeaf,
        AcgFinest,
        FallbackScan,
    };

    struct MgFindResult
    {
        MgEntry *entry = nullptr;
        MgFindKind kind = MgFindKind::None;
    };

    // 带分类信息的查找版本，用于统计“custom 命中父项/子项”的根因。
    MgFindResult mgFindEntryDetailed(Addr block_base);

    // 查找指定 base+size 的 entry（仅在对应粒度表中查找）
    MgEntry *mgFindEntryAtSize(Addr base, uint32_t size);

    // 查找或分配 entry：若不存在则按当前 policy 选择初始粒度并初始化语义
    // first_touch_excl=true  => PRIVATE, owner=requestor
    // first_touch_excl=false => SHARED,  sharers={requestor}
    MgEntry *mgGetOrAllocEntry(Addr block_base, bool first_touch_excl,
                               MachineID requestor);

	    // 插入/删除 entry：
	    // - 统一入口便于维护覆盖关系与断言
	    // - cause 用于统计：将这次 entry 的增删归因到 alloc/split/merge/eviction 等来源
	    void mgInsertEntry(const MgEntry &entry, MgChurnCause cause);
	    void mgEraseEntry(Addr base, uint32_t size, MgChurnCause cause);

    // 判断某个范围内是否存在“owner 的私有块”（使用触碰记录做近似）
    bool mgHasPrivateBlockInRange(Addr base, uint32_t size, MachineID owner,
                                  std::optional<Addr> exclude) const;

    // policy / custom / acg mode 辅助
	    // 返回当前是否启用 custom 局部 carve-out 策略；profile 复用 custom 行为。
	    bool mgUseCustomPolicy() const
	    { return mg_policy == MgPolicy::Custom || mg_policy == MgPolicy::Profile; }
	    // 返回当前是否启用 profile-guided shatter 阈值分析模式。
	    bool mgUseProfilePolicy() const { return mg_policy == MgPolicy::Profile; }
    // 返回当前是否启用 ACG 例外块策略。
    bool mgUseAcgPolicy() const { return mg_policy == MgPolicy::Acg; }
    // 返回当前是否启用传统 64B 单粒度 baseline 策略。
    bool mgUseBaselinePolicy() const { return mg_policy == MgPolicy::Baseline; }
    // 返回当前策略名称字符串，用于输出目录和摘要文件标识。
    const char *mgPolicyName() const;
    // 校验 custom 模式下的粒度链是否满足通用可配置要求。
    void mgValidateCustomGrains(const std::vector<uint32_t> &grains) const;
    // 校验 ACG 模式下的粒度链是否符合固定要求。
    void mgValidateAcgGrains(const std::vector<uint32_t> &grains) const;
    // 校验 baseline 模式下的粒度集合是否只包含 64B。
    void mgValidateBaselineGrains(const std::vector<uint32_t> &grains) const;
    // 返回 custom 当前配置链中当前粒度的下一层更细粒度。
    uint32_t mgCustomNextSmallerSize(uint32_t size) const;
    // 返回 ACG 固定链中当前粒度的下一层更粗粒度。
    uint32_t mgAcgNextLargerSize(uint32_t size) const;
    // 计算 ACG buddy merge 时，当前条目所在合并父区域的基地址。
    Addr mgAcgMergedBase(Addr base, uint32_t size) const;
    // 计算当前条目在 ACG buddy merge 下的同粒度 buddy 基地址。
    Addr mgAcgBuddyBase(Addr base, uint32_t size) const;
    // 判断两个 ACG 同粒度条目是否满足 buddy 合并条件。
    bool mgAcgCanMergePair(const MgEntry &a, const MgEntry &b) const;
    // 为 ACG 的 unmatched-type 冲突创建一个 64B 例外项。
    void mgAcgCreateBlockException(MgEntry &parent, Addr block_base,
                                   const MgLineInfo &child_line,
                                   MachineID requestor,
                                   std::optional<MachineID> trace_owner,
                                   bool want_excl,
                                   bool count_attempt,
                                   bool record_private_break);
    // 判断某个 ACG 粗粒度条目是否已经被更细粒度条目完全遮蔽。
    bool mgAcgEntryFullyShadowedByFiner(const MgEntry &entry);
    // 沿更粗粒度方向清理已经被更细粒度条目完全遮蔽的 ACG 背景条目。
    void mgAcgPruneFullyShadowedParents(Addr block_base, uint32_t finer_size,
                                        MgChurnCause cause);
    // 从当前 ACG 条目出发，只检查它的 buddy，并在成功后继续逐级向上合并。
    void mgAcgTryMergeUp(Addr base, uint32_t size);
    // 返回当前父粒度在 custom 当前配置链下包含多少个下一层子区。
    uint32_t mgCustomChildCount(uint32_t size) const;
    // 根据访问地址计算其落在父条目的哪一个下一层子区。
    uint32_t mgCustomChildIndex(const MgEntry &entry, Addr block_base) const;
    // 根据父条目和子区编号计算该子区的对齐起始地址。
    Addr mgCustomChildBase(const MgEntry &entry, uint32_t child_idx) const;
    // 判断父条目的某个下一层子区当前是否已经被下放。
    bool mgIsChildDelegated(const MgEntry &entry, uint32_t child_idx) const;
    // 设置或清除父条目中某个下一层子区的下放标记位。
    void mgSetChildDelegated(MgEntry &entry, uint32_t child_idx, bool delegated);
    // 在 custom 模式下按地址查找父条目已下放的直接子条目。
    MgEntry *mgFindDelegatedChild(MgEntry &entry, Addr block_base);
    // const 版本：按地址查找父条目已下放的直接子条目。
    const MgEntry *mgFindDelegatedChild(const MgEntry &entry,
                                        Addr block_base) const;
    // 判断一个条目自身是否还带有更细一级的已下放子区。
    bool mgEntryHasDelegatedChildren(const MgEntry &entry) const;
    // 判断一个子条目是否已经满足被父条目精确吸回的条件。
    bool mgCanAbsorbChildIntoParent(const MgEntry &child,
                                    const MgEntry &parent) const;
    // 从当前子条目开始执行 custom 模式下的逐级局部回并。
    void mgCustomTryMergeUp(MgEntry &entry);

    // 当 coarse PRIVATE entry 被其他 requestor 触碰时触发 split。
    // ideal 模式：直接选择一个尽量粗、但已足够隔离冲突的 target_size，
    //             然后一步拆到该粒度。
    // custom 模式：只把当前访问落入的“下一层子区”下放，父条目继续保留。
    // acg 模式：保留原粗粒度父条目，只为当前冲突 block 建一个 64B 例外项。
    // baseline 模式：固定 64B 单粒度，不创建新条目，只在当前块上直接改状态。
    // count_break 用于控制 private-break / split_attempts 是否记账。
    void mgSplitPrivateOnConflict(MgEntry &entry, Addr block_base,
                                  MachineID requestor, bool want_excl,
                                  bool count_break = true);
    // [新增]：将共享者过多的大条目彻底打碎，只保留活跃的 64B 细粒度条目
    void mgShatterSharedEntry(MgEntry &entry);
    // [新增]：递归获取当前条目所在的整棵树的根节点
    MgEntry *mgGetRoot(MgEntry *entry);
    // [新增]：递归删除整棵多粒度树
    void mgEraseTree(MgEntry *entry);
    // 比较两个 sharer 集合是否相等：用于判断是否能够合并
    static bool mgSharersEqual(const std::unordered_set<MachineID> &a,
                              const std::unordered_set<MachineID> &b);

    // 比较两份元数据是否等价：PRIVATE 比 owner；SHARED 比 sharers 集合
    static bool mgLineEqual(const MgLineInfo &a, const MgLineInfo &b);

    // ideal 模式：尝试把当前 Private 条目恢复到“可成立的最大更粗粒度”。
    // custom 模式：仅在父子局部执行逐级回并，不做全局扫描。
    // acg 模式：从当前条目出发沿 buddy 链逐级向上合并，每次只检查当前同粒度 buddy。
    // baseline 模式：固定 64B 单粒度，不执行 merge。
    // 要求调用者已持有 mg_mutex，保证 merge 过程原子性。
    void mgTryMergeLocked(Addr base, uint32_t size);

    // 将粒度 size 映射到统计用的 index；未命中返回 MgInvalidIndex
    // （避免每次都线性扫描 mg_region_grains_asc）
    size_t mgGrainIndex(uint32_t size) const;

    // 记录某类请求在指定 MachineType 下的计数（非法类型记入 unknown）
    void mgCountByRequestor(statistics::Vector &vec, MachineID requestor);

    // 分类规则：判断某个 MachineType 属于 CPU 侧还是 GPU 侧（用于 CPU↔GPU 方向统计）
    bool mgIsCpuMachineType(MachineType type) const;
    bool mgIsGpuMachineType(MachineType type) const;

    // 记录一次“private 被打破”的方向；parent_size 用于按粒度统计（打破发生在多大粒度上）
    void mgRecordPrivateBreak(MachineID owner, MachineID requestor,
                              uint32_t parent_size);
	    // 记录一次 shared 条目的 sharer 数采样。
	    void mgRecordSharerSample(uint64_t sharer_count);
	    // profile 模式下记录一次粗粒度 shared 条目的访问压力。
	    void mgRecordShatterProfileAccess(const MgEntry &entry,
	                                      bool is_exclusive);
    // 返回去重排序后的 profile 候选 shatter 阈值。
    std::vector<uint32_t> mgProfileThresholds() const;
    // profile 模式下按 traffic fanout 口径累计各候选阈值的 probe 减少估计。
    void mgRecordShatterProfileProbeReductionLocked(
        Addr block_base, MachineID requestor, bool is_invalidation,
        int fallback_fanout, int current_est, const MgFindResult &find_result);

    // 统计输出辅助：格式化粒度/生成子目录/输出简表
    std::string mgFormatGrain(uint32_t size) const;
    std::string mgGrainTag() const;
    std::string mgSafeName(const std::string &name) const;
    void mgSetupStatsOutput();
    void mgDumpStats();

    const std::string m_name;
    AbstractCacheEntry **m_entries;
    // int m_size;  // # of memory module blocks this directory is
                    // responsible for
    uint64_t m_size_bytes;
    uint64_t m_size_bits;
    uint64_t m_num_entries;
    uint32_t m_block_size;

    RubySystem *m_ruby_system = nullptr;

    // 多粒度目录的配置与元数据（独立于原有 m_entries）
    const bool mg_enable;                         // 是否启用该元数据框架（SimObject 参数）
    const std::vector<uint32_t> mg_region_grains; // 用户配置的粒度集合（bytes，包含 64B）
	    const MgPolicy mg_policy;                     // ideal / custom / acg / baseline
	    const std::vector<uint32_t> mg_profile_thresholds; // profile 候选 sharer 阈值
	    std::vector<uint32_t> mg_region_grains_desc;  // 内部使用：降序粒度集合（最大粒度优先）
    std::vector<uint32_t> mg_region_grains_asc;   // 内部使用：升序粒度集合（最小粒度优先）
    uint32_t mg_min_region_grain = 0;             // 最小粒度（应为 64B）
    uint32_t mg_shatter_threshold = 0;  // 新增
    uint32_t mg_max_region_grain = 0;             // 最大粒度
    mutable std::mutex mg_mutex;                  // 保护 entry/split/merge 的原子更新

    // grain size -> index（index 对应 mg_region_grains_asc 的顺序）
    std::unordered_map<uint32_t, size_t> mg_grain_to_index;
    static constexpr size_t MgInvalidIndex = std::numeric_limits<size_t>::max();

    // 影子目录的“条目表”（多粒度结构本体）：
    // 第一层 key：粒度 size
    // 第二层 key：对齐后的 base（base 必须是 size 对齐）
    std::unordered_map<uint32_t, std::unordered_map<Addr, MgEntry>>
        mg_entries; // key=size -> (key=base -> MgEntry)

    // 影子目录的“按 64B block 的触碰/驻留近似记录”：
    // key：block_base（64B 对齐）
    // value：该块的影子状态（MgLineInfo）
    // 主要用途：支持稀疏 split（iMgD-style）：
    //   在拆分父 region 时，用它近似判断某个子范围内是否仍存在旧 owner 的私有块，
    //   从而决定该子范围是否需要创建子 MgEntry（空洞则不创建）。
    std::unordered_map<Addr, MgLineInfo>
        mg_block_states; // 触碰记录，用于稀疏 split

    // profile 模式下按 entry 粒度记录粗粒度 shared 区域访问压力。
    std::unordered_map<uint32_t,
        std::unordered_map<Addr, MgShatterProfileRegion>>
        mg_shatter_profile_regions;
    std::unordered_map<uint32_t, uint64_t>
        mg_shatter_profile_probe_reduction_by_threshold;

    // 统计对象与输出目录：
    // mgStats：写入 gem5 stats 系统
    // mg_stats_dir：simout 下创建的子目录（按粒度命名），用于输出额外的可读摘要文件
    MgStats mgStats;

    struct MgTraceEntry
    {
        enum class Op : uint8_t { Split, Merge, Eviction };
        Op op;
        Tick tick;               // 事件发生的 tick
 
        // 操作主体
        Addr parent_base;        // split: 父条目 base; merge: 合并后条目 base
        uint32_t parent_size;    // split: 父条目 size; merge: 合并后条目 size
        uint32_t target_size;    // split: 目标粒度;    merge: 子条目粒度
 
        // 冲突信息（仅 split 有效）
        Addr conflict_block;     // 触发冲突的 64B block 地址
        MachineID requestor;     // 触发者
        MachineID owner;         // 被打破的原 owner
        bool want_excl;          // 请求是否为独占
 
        // 子条目列表
        struct ChildInfo
        {
            Addr base;
            uint32_t size;
            bool is_conflict;    // 是否为冲突子区间
            bool is_sparse_keep; // 非冲突但因有私有块而保留
            MgState state;       // 创建后的状态
            std::optional<MachineID> owner;
            MgState prev_state = MgState::Shared;
            bool was_deleted = false;
        };
        std::vector<ChildInfo> children;
    };
 
    // 日志缓冲：攒够一定数量再批量 flush，减少 IO 开销
    std::vector<MgTraceEntry> mg_trace_buffer;
    static constexpr size_t MgTraceFlushThreshold = 256;
    std::ofstream mg_trace_file;
 
    // 追踪接口
    // 记录一次 split 事件到 trace 缓冲区。
    void mgTraceLogSplit(const MgTraceEntry &entry);
    // 记录一次 merge 事件到 trace 缓冲区。
    void mgTraceLogMerge(const MgTraceEntry &entry);
    // 记录一次 eviction 事件到 trace 缓冲区。
    void mgTraceLogEviction(const MgTraceEntry &entry);
    // 将 trace 缓冲区批量刷新到日志文件。
    void mgTraceFlush();
    // 初始化 trace 输出文件与相关目录。
    void mgTraceSetup();
    // 在析构阶段 flush trace 并写入结束摘要。
    void mgTraceFinalize();
 
    // 格式化一条追踪记录为可读文本
    std::string mgTraceFormatEntry(const MgTraceEntry &entry) const;


    OutputDirectory *mg_stats_dir = nullptr;
    std::string mg_stats_dir_name;

    /**
     * The address range for which the directory responds. Normally
     * this is all possible memory addresses.
     */
    const AddrRangeList addrRanges;
};

inline std::ostream&
operator<<(std::ostream& out, const DirectoryMemory& obj)
{
    obj.print(out);
    out << std::flush;
    return out;
}

} // namespace ruby
} // namespace gem5

#endif // __MEM_RUBY_STRUCTURES_DIRECTORYMEMORY_HH__
