OPENCL_INCLUDE = ../_opencl/include
OPENCL_LIB = ../_opencl/lib/win/x86
CC = g++
CC_FLAGS = -ansi -pedantic -W -Wall -std=c++0x -O3 -I$(OPENCL_INCLUDE)
LD = g++
LD_FLAGS = -fPIC -L$(OPENCL_LIB) -static-libgcc -static-libstdc++ -lOpenCL
ECHO = echo
MKDIR = mkdir
CP = cp
RM = rm

SRC = $(wildcard *.cpp)
OBJ = $(SRC:.cpp=.o)
EXEC = bin/gpuPlotGenerator.exe

all: $(EXEC)

dist: all
	@$(ECHO) Generating distribution
	@$(MKDIR) -p bin/kernel
	@$(CP) kernel/util.cl bin/kernel
	@$(CP) kernel/shabal.cl bin/kernel
	@$(CP) kernel/nonce.cl bin/kernel
	@$(CP) README bin/README

rebuild: distclean all

$(EXEC): $(OBJ)
	@$(ECHO) Linking [$@]
	@$(LD) -o $@ $^ $(LD_FLAGS)

%.o: %.cpp
	@$(ECHO) Compiling [$<]
	@$(CC) -o $@ -c $< $(CC_FLAGS)

clean:
	@$(ECHO) Cleaning project
	@$(RM) -f *.o

distclean: clean
	@$(ECHO) Dist cleaning project
	@$(RM) -f $(EXEC)
	@$(RM) -Rf bin/kernel
	@$(RM) -f bin/README