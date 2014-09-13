/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#include <iostream>
#include <cstdlib>
#include <CL/cl.h>

#include "CommandList.h"
#include "OpenclError.h"

CommandList::CommandList()
: Command("List the OpenCL resources.") {
	m_types.insert(TypesMap::value_type("platforms", &CommandList::listPlatforms));
	m_types.insert(TypesMap::value_type("devices", &CommandList::listDevices));
}

CommandList::CommandList(const CommandList& p_command)
: Command(p_command.m_description), m_types(p_command.m_types) {
}

CommandList::~CommandList() throw () {
}

void CommandList::help() const {
	std::cout << "Usage: ./gpuPlotGenerator list platforms" << std::endl;
	std::cout << "Usage: ./gpuPlotGenerator list devices <platformId>" << std::endl;
	std::cout << "    - platformId: The platform id to scan." << std::endl;
}

int CommandList::execute(const std::vector<std::string>& p_args) {
	if(p_args.size() < 2) {
		help();
		return -1;
	}

	std::string type(p_args[1]);
	if(m_types.find(type) == m_types.end()) {
		std::cout << "[ERROR] Unknown [" << type << "] type" << std::endl;
		std::cout << "----" << std::endl;

		help();
		return -1;
	}

	return m_types.at(type)(this, p_args);
}

int CommandList::listPlatforms(const std::vector<std::string>& p_args) {
	cl_platform_id platforms[4];
	cl_uint platformsNumber;
	(void)p_args; // Shut compiler up about unused parameter
	try {
		int error;

		error = clGetPlatformIDs(4, platforms, &platformsNumber);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to retrieve the OpenCL platforms");
		}

		std::cout << "Platforms number: " << platformsNumber << std::endl;
		for(unsigned int i = 0 ; i < platformsNumber ; ++i) {
			std::cout << "----" << std::endl;
			std::cout << "Id:       " << i << std::endl;

			size_t size;
			char* buffer;

			clGetPlatformInfo(platforms[i], CL_PLATFORM_NAME, 0, 0, &size);
			buffer = new char[size];
			clGetPlatformInfo(platforms[i], CL_PLATFORM_NAME, size, (void*)buffer, 0);
			std::cout << "Name:     " << buffer << std::endl;
			delete[] buffer;

			clGetPlatformInfo(platforms[i], CL_PLATFORM_VENDOR, 0, 0, &size);
			buffer = new char[size];
			clGetPlatformInfo(platforms[i], CL_PLATFORM_VENDOR, size, (void*)buffer, 0);
			std::cout << "Vendor:   " << buffer << std::endl;
			delete[] buffer;

			clGetPlatformInfo(platforms[i], CL_PLATFORM_VERSION, 0, 0, &size);
			buffer = new char[size];
			clGetPlatformInfo(platforms[i], CL_PLATFORM_VERSION, size, (void*)buffer, 0);
			std::cout << "Version:  " << buffer << std::endl;
			delete[] buffer;
		}
	} catch(const OpenclError& ex) {
		std::cout << "[ERROR] An OpenCL error occured in the generation process, aborting..." << std::endl;
		std::cout << "[ERROR] [" << ex.getCode() << "] " << ex.what() << std::endl;
		return -1;
	} catch(const std::exception& ex) {
		std::cout << "[ERROR] An error occured in the generation process, aborting..." << std::endl;
		std::cout << "[ERROR] " << ex.what() << std::endl;
		return -1;
	}

	return 0;
}

int CommandList::listDevices(const std::vector<std::string>& p_args) {
	if(p_args.size() < 3) {
		help();
		return -1;
	}

	unsigned int platformId = atol(p_args[2].c_str());

	cl_platform_id platforms[4];
	cl_uint platformsNumber;
	cl_device_id devices[32];
	cl_uint devicesNumber;

	try {
		int error;

		error = clGetPlatformIDs(4, platforms, &platformsNumber);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to retrieve the OpenCL platforms");
		}

		if(platformId >= platformsNumber) {
			throw std::runtime_error("No platform found with the provided id");
		}

		error = clGetDeviceIDs(platforms[platformId], CL_DEVICE_TYPE_CPU | CL_DEVICE_TYPE_GPU, 32, devices, &devicesNumber);
		if(error != CL_SUCCESS) {
			throw OpenclError(error, "Unable to retrieve the OpenCL devices");
		}

		std::cout << "Devices number: " << devicesNumber << std::endl;
		for(unsigned int i = 0 ; i < devicesNumber ; ++i) {
			std::cout << "----" << std::endl;
			std::cout << "Id:                      " << i << std::endl;

			size_t size;
			char* buffer;

			cl_device_type type;
			clGetDeviceInfo(devices[i], CL_DEVICE_TYPE, sizeof(cl_device_type), (void*)&type, 0);
			std::cout << "Type:                    ";
			if(type & CL_DEVICE_TYPE_CPU) {
				std::cout << "CPU";
			} else if(type & CL_DEVICE_TYPE_GPU) {
				std::cout << "GPU";
			}
			std::cout << std::endl;

			clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 0, 0, &size);
			buffer = new char[size];
			clGetDeviceInfo(devices[i], CL_DEVICE_NAME, size, (void*)buffer, 0);
			std::cout << "Name:                    " << buffer << std::endl;
			delete[] buffer;

			clGetDeviceInfo(devices[i], CL_DEVICE_VENDOR, 0, 0, &size);
			buffer = new char[size];
			clGetDeviceInfo(devices[i], CL_DEVICE_VENDOR, size, (void*)buffer, 0);
			std::cout << "Vendor:                  " << buffer << std::endl;
			delete[] buffer;

			clGetDeviceInfo(devices[i], CL_DEVICE_VERSION, 0, 0, &size);
			buffer = new char[size];
			clGetDeviceInfo(devices[i], CL_DEVICE_VERSION, size, (void*)buffer, 0);
			std::cout << "Version:                 " << buffer << std::endl;
			delete[] buffer;

			clGetDeviceInfo(devices[i], CL_DRIVER_VERSION, 0, 0, &size);
			buffer = new char[size];
			clGetDeviceInfo(devices[i], CL_DRIVER_VERSION, size, (void*)buffer, 0);
			std::cout << "Driver version:          " << buffer << std::endl;
			delete[] buffer;

			cl_ulong maxGlobalMemSize;
			clGetDeviceInfo(devices[i], CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), (void*)&maxGlobalMemSize, 0);
			std::cout << "Max global memory size:  " << (maxGlobalMemSize >> 20) << " MB" << std::endl;

			cl_ulong maxLocalMemSize;
			clGetDeviceInfo(devices[i], CL_DEVICE_LOCAL_MEM_SIZE, sizeof(cl_ulong), (void*)&maxLocalMemSize, 0);
			std::cout << "Max local memory size:   " << (maxLocalMemSize >> 10) << " KB" << std::endl;

			size_t maxWorkGroupSize;
			clGetDeviceInfo(devices[i], CL_DEVICE_MAX_WORK_GROUP_SIZE , sizeof(size_t), (void*)&maxWorkGroupSize, 0);
			std::cout << "Max work group size:     " << maxWorkGroupSize << std::endl;
		}
	} catch(const OpenclError& ex) {
		std::cout << "[ERROR] [" << ex.getCode() << "] " << ex.what() << std::endl;
		return -1;
	} catch(const std::exception& ex) {
		std::cout << "[ERROR] " << ex.what() << std::endl;
		return -1;
	}

	return 0;
}
