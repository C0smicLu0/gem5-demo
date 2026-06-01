include ../../common/make.config

# Example
# target: dependencies
	# command 1
	# command 2
          # .
          # .
          # .
	# command n
ifdef OUTPUT
override OUTPUT = -DOUTPUT
endif

C_C = $(ROCM_PATH)/bin/hipcc
# OMP_LIB = -lgomp
OMP_FLAG = -fopenmp

CUD_C = $(ROCM_PATH)/bin/hipcc
# HIP platform selection for ROCm 4.x
# 原来：未显式指定平台宏，ROCm 4.x 会报 __HIP_PLATFORM_* 未定义
# 现在：增加 __HIP_PLATFORM_HCC__/__HIP_PLATFORM_AMD__ 便于 hipcc 正确编译
HIP_PLATFORM_FLAGS = -D__HIP_PLATFORM_HCC__ -D__HIP_PLATFORM_AMD__
# OMP_FLAG = 	-Xcompiler paste_one_here
# CUDA_FLAG = -arch sm_13

# link objects (binaries) together
a.out:		main.o \
			./kernel/kernel_gpu_cuda_wrapper.o \
			./util/num/num.o \
			./util/timer/timer.o \
			./util/device/device.o
	$(C_C)	$(KERNEL_DIM) main.o \
			./kernel/kernel_gpu_cuda_wrapper.o \
			./util/num/num.o \
			./util/timer/timer.o \
			./util/device/device.o \
			-lm \
			$(OMP_LIB) \
			-o lavaMD

# compile function files into objects (binaries)
main.o:		main.h \
			main.c \
			./kernel/kernel_gpu_cuda_wrapper.h \
			./kernel/kernel_gpu_cuda_wrapper.cu \
			./util/num/num.h \
			./util/num/num.c \
			./util/timer/timer.h \
			./util/timer/timer.c \
			./util/device/device.h \
			./util/device/device.cu
	$(C_C)	$(KERNEL_DIM) $(OUTPUT) main.c \
			-c \
			-o main.o \
			-O3 \
			$(HIP_PLATFORM_FLAGS) \
			$(GEM5_INCLUDE) \
			$(GEM5_DEFS)

./kernel/kernel_gpu_cuda_wrapper.o:	./kernel/kernel_gpu_cuda_wrapper.h \
									./kernel/kernel_gpu_cuda_wrapper.cu
	$(CUD_C) $(KERNEL_DIM)						./kernel/kernel_gpu_cuda_wrapper.cu \
									-c \
									-o ./kernel/kernel_gpu_cuda_wrapper.o \
									-O3 \
									$(HIP_PLATFORM_FLAGS) \
									$(GEM5_DEFS) \
									$(CUDA_FLAG)

./util/num/num.o:	./util/num/num.h \
					./util/num/num.c
	$(C_C)			./util/num/num.c \
					-c \
					-o ./util/num/num.o \
					-O3

./util/timer/timer.o:	./util/timer/timer.h \
						./util/timer/timer.c
	$(C_C)				./util/timer/timer.c \
						-c \
						-o ./util/timer/timer.o \
						-O3

./util/device/device.o:	./util/device/device.h \
						./util/device/device.cu
	$(CUD_C)			./util/device/device.cu \
						-c \
						-o ./util/device/device.o \
						-O3

# delete all object and executable files
clean:
	rm	*.o \
		./kernel/*.o \
		./util/num/*.o \
		./util/timer/*.o \
		./util/device/*.o \
		lavaMD
