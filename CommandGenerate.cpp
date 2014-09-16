/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#include <future>
#include <assert.h>
#include <iostream>
#include <string>
#include <cstdlib>
#include <sstream>
#include <stdexcept>
#include <fstream>
#include <streambuf>
#include <ctime>
#include <CL/cl.h>

#include "CommandGenerate.h"
#include "OpenclError.h"

#define HASH_SIZE			32
#define HASHES_PER_SCOOP	2
#define SCOOP_SIZE			(HASHES_PER_SCOOP * HASH_SIZE)
#define SCOOPS_PER_PLOT		4096
#define PLOT_SIZE			(SCOOPS_PER_PLOT * SCOOP_SIZE)
#define HASH_CAP			4096
#define OUT_CAP				100000000
#define GEN_SIZE			(PLOT_SIZE + 16)

CommandGenerate::CommandGenerate()
: Command("Plot generation.") {
}

CommandGenerate::CommandGenerate(const CommandGenerate& p_command)
: Command(p_command.m_description) {
}

CommandGenerate::~CommandGenerate() throw () {
}

void CommandGenerate::help() const {
	std::cerr << "Usage: ./gpuPlotGenerator generate ";
	std::cerr << "<platformId> <deviceId> <staggerSize> <threadsNumber> ";
	std::cerr << "<hashesNumber> <path> <address> <startNonce> <noncesNumber> ";
	std::cerr << "[<path> <address> <startNonce> <noncesNumber> ...]" << std::endl;
	std::cerr << "    - platformId: Id of the OpenCL platform to use (see [list] command)." << std::endl;
	std::cerr << "    - deviceId: Id of the OpenCL device to use (see [list] command)." << std::endl;
	std::cerr << "    - staggerSize: Stagger size." << std::endl;
	std::cerr << "    - threadsNumber: Number of parallel threads for each work group." << std::endl;
	std::cerr << "    - hashesNumber: Number of hashes to compute for each step2 kernel calls." << std::endl;
	std::cerr << "    - path: Path to the plots directory." << std::endl;
	std::cerr << "    - address: Burst numerical address." << std::endl;
	std::cerr << "    - startNonce: First nonce of the plot generation." << std::endl;
	std::cerr << "    - noncesNumber: Number of nonces to generate." << std::endl;
	std::cerr << "With multiple [<path> <address> <startNonce> <noncesNumber>] arguments " << std::endl;
	std::cerr << "GPU calculation iterates through a stagger for each job and the results are " << std::endl;
	std::cerr << "saved asynchronously.  This is intended to be used for plotting multiple " << std::endl;
	std::cerr << "mechanical drives simultaneously in order to max out GPU bandwidth." << std::endl;
}

void save_nonces(unsigned int nonceSize, std::ofstream *out, unsigned char *bufferCpu) {
  assert(out->good());
  for(unsigned long int offset = 0 ; offset < nonceSize ; offset += OUT_CAP) {
    unsigned long int size = nonceSize - offset;
    if(size > OUT_CAP) {
      size = OUT_CAP;
    }
    out->write((const char*)(bufferCpu + offset), size);
    out->flush();
  }
}

int CommandGenerate::execute(const std::vector<std::string>& p_args) {
	if(p_args.size() < 10) {
		help();
		return -1;
	}

	unsigned int platformId = atol(p_args[1].c_str());
	unsigned int deviceId = atol(p_args[2].c_str());
	unsigned int staggerSize = atol(p_args[3].c_str());
	unsigned int threadsNumber = atol(p_args[4].c_str());
	unsigned int hashesNumber = atol(p_args[5].c_str());
	unsigned int nonceSize = PLOT_SIZE * staggerSize;

	std::cerr << "Threads number: " << threadsNumber << std::endl;
	std::cerr << "Hashes number: " << hashesNumber << std::endl;

	unsigned int numjobs = (p_args.size() - 5)/4;
	std::cerr << numjobs << " plot(s) to do." << std::endl;
	unsigned int staggerMbSize = staggerSize / 4;
	std::cerr << "Non-GPU memory usage: " << staggerMbSize*numjobs << "MB" << std::endl;
	
	std::vector<std::string> paths(numjobs);
	std::vector<std::ofstream *> out_files(numjobs);
	std::vector<unsigned long long> addresses(numjobs);
	std::vector<unsigned long long> startNonces(numjobs);
	std::vector<unsigned long long> endNonces(numjobs);
	std::vector<unsigned int> noncesNumbers(numjobs);
	std::vector<unsigned char*> buffersCpu(numjobs);
	std::vector<bool> saving_thread_flags(numjobs);
	std::vector<std::future<void>> save_threads(numjobs);
	unsigned long long maxNonceNumber = 0;
	unsigned long long totalNonces = 0;

	int returnCode = 0;

	try {
		for (unsigned int i = 0; i < numjobs; i++) {
			std::cerr << "----" << std::endl;
			std::cerr << "Job number " << i << std::endl;
			unsigned int argstart = 5 + i*4;
			paths[i] = std::string(p_args[argstart]);
			addresses[i] = strtoull(p_args[argstart+1].c_str(), NULL, 10);
			startNonces[i] = strtoull(p_args[argstart+2].c_str(), NULL, 10);
			noncesNumbers[i] = atol(p_args[argstart+3].c_str());
			maxNonceNumber = std::max(maxNonceNumber, (long long unsigned int)noncesNumbers[i]);
			totalNonces += noncesNumbers[i];

			std::ostringstream outFile;
			outFile << paths[i] << "/" << addresses[i] << "_" << startNonces[i] << "_" << \
				noncesNumbers[i] << "_" << staggerSize;
			std::ios_base::openmode file_mode = std::ios::out | std::ios::binary | std::ios::trunc;
			out_files[i] = new std::ofstream(outFile.str(), file_mode);
			assert(out_files[i]);

			if(noncesNumbers[i] % staggerSize != 0) {
				noncesNumbers[i] -= noncesNumbers[i] % staggerSize;
				noncesNumbers[i] += staggerSize;
			}

			endNonces[i] = startNonces[i] + noncesNumbers[i];
			unsigned int noncesGbSize = noncesNumbers[i] / 4 / 1024;
			std::cerr << "Path: " << outFile.str() << std::endl;
			std::cerr << "Nonces: " << startNonces[i] << " to " << endNonces[i] << " (" << noncesGbSize << " GB)" << std::endl;
			std::cerr << "Creating CPU buffer" << std::endl;
			buffersCpu[i] = new unsigned char[nonceSize];
			if(!buffersCpu[i]) {
				throw std::runtime_error("Unable to create the CPU buffer (probably out of host memory.)");
			}
			saving_thread_flags[i] = false;
			std::cerr << "----" << std::endl;
		}

		cl_platform_id platforms[4];
		cl_uint platformsNumber;
		cl_device_id devices[32];
		cl_uint devicesNumber;
		cl_context context = 0;
		cl_command_queue commandQueue = 0;
		cl_mem bufferGpuGen = 0;
		cl_mem bufferGpuScoops = 0;
		cl_program program = 0;
		cl_kernel kernelStep1 = 0;
		cl_kernel kernelStep2 = 0;
		cl_kernel kernelStep3 = 0;

		int error;

		std::cerr << "Retrieving OpenCL platforms" << std::endl;
		error = clGetPlatformIDs(4, platforms, &platformsNumber);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to retrieve the OpenCL platforms");
		}

		if(platformId >= platformsNumber) {
			throw std::runtime_error("No platform found with the provided id");
		}

		std::cerr << "Retrieving OpenCL GPU devices" << std::endl;
		error = clGetDeviceIDs(platforms[platformId], CL_DEVICE_TYPE_CPU | CL_DEVICE_TYPE_GPU, 32, devices, &devicesNumber);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to retrieve the OpenCL devices");
		}

		if(deviceId >= devicesNumber) {
			throw std::runtime_error("No device found with the provided id");
		}

		std::cerr << "Creating OpenCL context" << std::endl;
		context = clCreateContext(0, 1, &devices[deviceId], NULL, NULL, &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL context");
		}

		std::cerr << "Creating OpenCL command queue" << std::endl;
		commandQueue = clCreateCommandQueue(context, devices[deviceId], 0, &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL command queue");
		}

		std::cerr << "Creating OpenCL GPU generation buffer" << std::endl;
		bufferGpuGen = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uchar) * GEN_SIZE * staggerSize, 0, &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL GPU generation buffer");
		}

		std::cerr << "Creating OpenCL GPU scoops buffer" << std::endl;
		bufferGpuScoops = clCreateBuffer(context, CL_MEM_WRITE_ONLY, sizeof(cl_uchar) * nonceSize, 0, &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL GPU scoops buffer");
		}

		std::cerr << "Creating OpenCL program" << std::endl;
		std::string source = loadSource("kernel/nonce.cl");
		const char* sources[] = {source.c_str()};
		size_t sourcesLength[] = {source.length()};
		program = clCreateProgramWithSource(context, 1, sources, sourcesLength, &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL program");
		}

		std::cerr << "Building OpenCL program" << std::endl;
		error = clBuildProgram(program, 1, &devices[deviceId], "-I kernel", 0, 0);
		if(error != CL_SUCCESS) {
			size_t logSize;
			clGetProgramBuildInfo(program, devices[deviceId], CL_PROGRAM_BUILD_LOG, 0, 0, &logSize);

			char* log = new char[logSize];
			clGetProgramBuildInfo(program, devices[deviceId], CL_PROGRAM_BUILD_LOG, logSize, (void*)log, 0);
			std::cerr << log << std::endl;
			delete[] log;

			throw OpenclError(error, "Unable to build the OpenCL program");
		}

		std::cerr << "Creating OpenCL step1 kernel" << std::endl;
		kernelStep1 = clCreateKernel(program, "nonce_step1", &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL kernel");
		}

		std::cerr << "Setting OpenCL step1 kernel static arguments" << std::endl;
		error = clSetKernelArg(kernelStep1, 2, sizeof(cl_mem), (void*)&bufferGpuGen);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to set the OpenCL kernel arguments");
		}

		std::cerr << "Creating OpenCL step2 kernel" << std::endl;
		kernelStep2 = clCreateKernel(program, "nonce_step2", &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL kernel");
		}

		std::cerr << "Setting OpenCL step2 kernel static arguments" << std::endl;
		error = clSetKernelArg(kernelStep2, 1, sizeof(cl_mem), (void*)&bufferGpuGen);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to set the OpenCL kernel arguments");
		}

		std::cerr << "Creating OpenCL step3 kernel" << std::endl;
		kernelStep3 = clCreateKernel(program, "nonce_step3", &error);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to create the OpenCL kernel");
		}

		std::cerr << "Setting OpenCL step3 kernel static arguments" << std::endl;
		error = clSetKernelArg(kernelStep3, 0, sizeof(cl_uint), (void*)&staggerSize);
		error = clSetKernelArg(kernelStep3, 1, sizeof(cl_mem), (void*)&bufferGpuGen);
		error = clSetKernelArg(kernelStep3, 2, sizeof(cl_mem), (void*)&bufferGpuScoops);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to set the OpenCL kernel arguments");
		}

		size_t globalWorkSize = staggerSize;
		size_t localWorkSize = (staggerSize < threadsNumber) ? staggerSize : threadsNumber;
		time_t startTime = time(0);
		unsigned int totalNoncesCompleted = 0;
		for (unsigned long long nonce_ordinal = 0; nonce_ordinal < maxNonceNumber; nonce_ordinal += staggerSize) {
			for (unsigned int jobnum = 0; jobnum < paths.size(); jobnum += 1) {
				unsigned long long nonce = startNonces[jobnum] + nonce_ordinal;

				// Is a cl_ulong always an unsigned long long?
				error = clSetKernelArg(kernelStep1, 1, sizeof(cl_ulong), (void*)&nonce);
				if(error != CL_SUCCESS) {
					throw OpenclError(error, "Unable to set the OpenCL step1 kernel arguments");
				}

				error = clEnqueueNDRangeKernel(commandQueue, kernelStep1, 1, 0, &globalWorkSize, &localWorkSize, 0, 0, 0);
				if(error != CL_SUCCESS) {
					throw OpenclError(error, "Error in step1 kernel launch");
				}

				unsigned int hashesSize = hashesNumber * HASH_SIZE;
				for(int hashesOffset = PLOT_SIZE ; hashesOffset > 0 ; hashesOffset -= hashesSize) {
					error = clSetKernelArg(kernelStep1, 0, sizeof(cl_ulong), (void*)&addresses[jobnum]);
					error = clSetKernelArg(kernelStep2, 0, sizeof(cl_ulong), (void*)&nonce);
					error = clSetKernelArg(kernelStep2, 2, sizeof(cl_uint), (void*)&hashesOffset);
					error = clSetKernelArg(kernelStep2, 3, sizeof(cl_uint), (void*)&hashesNumber);
					if(error != CL_SUCCESS) {
						throw OpenclError(error, "Unable to set the OpenCL step2 kernel arguments");
					}

					error = clEnqueueNDRangeKernel(commandQueue, kernelStep2, 1, 0, &globalWorkSize, &localWorkSize, 0, 0, 0);
					if(error != CL_SUCCESS) {
						throw OpenclError(error, "Error in step2 kernel launch");
					}

					error = clFinish(commandQueue);
					if(error != CL_SUCCESS) {
						throw OpenclError(error, "Error in step2 kernel finish");
					}
				}

				totalNoncesCompleted += staggerSize;
				double percent = 100.0 * (double)totalNoncesCompleted / totalNonces;
				time_t currentTime = time(0);
				double speed = (double)totalNoncesCompleted / difftime(currentTime, startTime) * 60.0;
				double estimatedTime = (double)(totalNonces - totalNoncesCompleted) / speed;
				std::cerr << "\r" << percent << "% (" << totalNoncesCompleted << "/" << totalNonces << " nonces)";
				std::cerr << ", " << speed << " nonces/minutes";
				std::cerr << ", ETA: " << ((int)estimatedTime / 60) << "h" << ((int)estimatedTime % 60) << "m" << ((int)(estimatedTime * 60.0) % 60) << "s";
				std::cerr << "...                    ";

				error = clEnqueueNDRangeKernel(commandQueue, kernelStep3, 1, 0, &globalWorkSize, &localWorkSize, 0, 0, 0);
				if(error != CL_SUCCESS) {
					throw OpenclError(error, "Error in step3 kernel launch");
				}

				if (saving_thread_flags[jobnum]) {
					save_threads[jobnum].wait(); // Wait for last job to finish
					saving_thread_flags[jobnum] = false;
				}

				error = clEnqueueReadBuffer(commandQueue, bufferGpuScoops, CL_TRUE, 0, sizeof(cl_uchar) * nonceSize, buffersCpu[jobnum], 0, 0, 0);
				if(error != CL_SUCCESS) {
					throw OpenclError(error, "Error in synchronous read");
				}
				saving_thread_flags[jobnum] = true;
				save_threads[jobnum] = std::async(save_nonces, nonceSize, out_files[jobnum], buffersCpu[jobnum]);
			}

			//Clean up
			for (unsigned int i = 0; i < paths.size(); i += 1) {
				if (saving_thread_flags[i]) {
					std::cerr << "waiting for final save to " << paths[i] << " to finish" << std::endl;
					save_threads[i].wait();
					saving_thread_flags[i] = false;
					std::cerr << "done waiting for final save" << std::endl;
					if (buffersCpu[i]) {
						delete[] buffersCpu[i];
					}
					if (out_files[i]) {
						delete[] out_files[i];
					}
				}
			}

			if(kernelStep3) { clReleaseKernel(kernelStep3); }
			if(kernelStep2) { clReleaseKernel(kernelStep2); }
			if(kernelStep1) { clReleaseKernel(kernelStep1); }
			if(program) { clReleaseProgram(program); }
			if(bufferGpuGen) { clReleaseMemObject(bufferGpuGen); }
			if(bufferGpuScoops) { clReleaseMemObject(bufferGpuScoops); }
			if(commandQueue) { clReleaseCommandQueue(commandQueue); }
			if(context) { clReleaseContext(context); }
		}

		time_t currentTime = time(0);
		double elapsedTime = difftime(currentTime, startTime) / 60.0;
		double speed = (double)totalNonces / elapsedTime;
		std::cerr << "\r100% (" << totalNonces << "/" << totalNonces << " nonces)";
		std::cerr << ", " << speed << " nonces/minutes";
		std::cerr << ", " << ((int)elapsedTime / 60) << "h" << ((int)elapsedTime % 60) << "m" << ((int)(elapsedTime * 60.0) % 60) << "s";
		std::cerr << "                    " << std::endl;
	} catch(const OpenclError& ex) {
		std::cerr << "[ERROR] [" << ex.getCode() << "] " << ex.what() << std::endl;
		returnCode = -1;
	} catch(const std::exception& ex) {
		std::cerr << "[ERROR] " << ex.what() << std::endl;
		returnCode = -1;
	}
	return returnCode;
}

std::string CommandGenerate::loadSource(const std::string& p_file) throw (std::exception) {
	std::ifstream stream(p_file, std::ios::in);
	if(stream.fail()) {
		throw std::runtime_error("Unable to open the source file");
	}

	std::string str;

	stream.seekg(0, std::ios::end);
	str.reserve(stream.tellg());
	stream.seekg(0, std::ios::beg);

	str.assign(std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>());

	return str;
}
