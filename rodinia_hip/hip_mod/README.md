# hip_mod Directory Layout

`hip_mod` is the single source-of-truth tree for modified Rodinia HIP workloads.

- `hip_mod/`: all modified workloads (build from here)
- `hip_mod/bfs/bfs_mt_random.cu`: reference BFS multithreaded variant

Removed duplicate nested tree during reorganization:

- `hip_mod/hip`

## Build

Use project-level Docker compile helper from repo root:

```bash
./docker_compile.sh hip_mod
```
