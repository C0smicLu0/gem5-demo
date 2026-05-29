#makefile

include ../../common/make.config

CC := $(ROCM_PATH)/bin/hipcc


all: float
# naive 
naive: ex_particle_CUDA_naive_seq.cu
	$(CC)  -g -lm -O3 -use_fast_math ex_particle_CUDA_naive_seq.cu -o particlefilter_naive -lpthread
	
float: ex_particle_CUDA_float_seq.cu
	$(CC)  -g -lm -O3 -use_fast_math ex_particle_CUDA_float_seq.cu -o particlefilter_float -lpthread

clean:
	rm -f particlefilter_naive particlefilter_float
