include ../../common/make.config

CC := $(ROCM_PATH)/bin/hipcc

INCLUDE := $(CUDA_DIR)/include

SRC = bfs_mt_random.cu

EXE = bfs.out

release: $(SRC)
	$(CC) $(SRC) -o $(EXE) -I$(INCLUDE) -I../util $(GEM5_INCLUDE) $(GEM5_DEFS) -L$(CUDA_LIB_DIR) $(GEM5_LDFLAGS) -DTIMING -DDEBUG_BFS -lpthread

clang: $(SRC)
	clang++ $(SRC) -o $(EXE) -I../util --cuda-gpu-arch=sm_20 \
		-L/usr/local/cuda/lib64  -ldl -lrt -pthread -DTIMING -DDEBUG_BFS

enum: $(SRC)
	$(CC) -deviceemu $(SRC) -o $(EXE) -I$(INCLUDE) -L$(CUDA_LIB_DIR) 

debug: $(SRC)
	$(CC) -g $(SRC) -o $(EXE) -I$(INCLUDE) -I../util $(GEM5_INCLUDE) $(GEM5_DEFS) -L$(CUDA_LIB_DIR) $(GEM5_LDFLAGS) -DDEBUG_BFS -lpthread

debugenum: $(SRC)
	$(CC) -g -deviceemu $(SRC) -o $(EXE) -I$(INCLUDE) -L$(CUDA_LIB_DIR) 

clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo result.txt