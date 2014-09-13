all: clean gpuPlotGenerator 

gpuPlotGenerator: 
	g++ -pthread -ansi -pedantic -W -Wall -std=c++0x *.cpp -lOpenCL -o gpuPlotGenerator

clean:
	rm -f gpuPlotGenerator

test: gpuPlotGenerator
	./gpuPlotGenerator generate 0 0 ./plots/ 0 10 10000 1000 20 76
