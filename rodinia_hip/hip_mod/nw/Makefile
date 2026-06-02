include ../../common/make.config

CC := $(ROCM_PATH)/bin/hipcc

SRC = needle.cu

EXE = needle

release: $(SRC)
	$(CC) ${KERNEL_DIM} $(SRC) -o $(EXE)  -lpthread -DTIMING -I../util $(GEM5_INCLUDE) $(GEM5_DEFS) $(GEM5_LDFLAGS)

clang: $(SRC)
	clang++ $(SRC) -o $(EXE) -I../util $(GEM5_INCLUDE) $(GEM5_DEFS) $(GEM5_LDFLAGS) \
		  -ldl -lrt -pthread -DTIMING

enum: $(SRC)
	$(CC) ${KERNEL_DIM} -deviceemu $(SRC) -o $(EXE) -I$(INCLUDE) -I../util -L$(CUDA_LIB_DIR) $(GEM5_INCLUDE) $(GEM5_DEFS) $(GEM5_LDFLAGS)

debug: $(SRC)
	$(CC) ${KERNEL_DIM} -g $(SRC) -o $(EXE) -I$(INCLUDE) -I../util -L$(CUDA_LIB_DIR) $(GEM5_INCLUDE) $(GEM5_DEFS) $(GEM5_LDFLAGS)

debugenum: $(SRC)
	$(CC) ${KERNEL_DIM} -g -deviceemu $(SRC) -o $(EXE) -I$(INCLUDE) -I../util -L$(CUDA_LIB_DIR) $(GEM5_INCLUDE) $(GEM5_DEFS) $(GEM5_LDFLAGS)

clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo result.txt
