/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#include <iostream>
#include <string>
#include <vector>

#include "CommandHelp.h"
#include "CommandList.h"
#include "CommandGenerate.h"

int main(int p_argc, char* p_argv[]) {
	std::cerr << "-------------------------" << std::endl;
	std::cerr << "GPU plot generator v2.0.1" << std::endl;
	std::cerr << "-------------------------" << std::endl;
	std::cerr << "Author:   Cryo" << std::endl;
	std::cerr << "Bitcoin:  138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD" << std::endl;
	std::cerr << "Burst:    BURST-YA29-QCEW-QXC3-BKXDL" << std::endl;
	std::cerr << "----" << std::endl;

	typedef std::map<std::string, Command*> CommandsMap;
	CommandsMap commands;
	commands.insert(CommandsMap::value_type("help", new CommandHelp(commands)));
	commands.insert(CommandsMap::value_type("list", new CommandList()));
	commands.insert(CommandsMap::value_type("generate", new CommandGenerate()));

	std::vector<std::string> args(p_argv + 1, p_argv + p_argc);
	if(args.size() == 0) {
		commands.at("help")->help();
		return -1;
	}

	std::string command(args[0]);
	if(commands.find(command) == commands.end()) {
		std::cerr << "[ERROR] Unknown [" << command << "] command" << std::endl;
		std::cerr << "----" << std::endl;

		commands.at("help")->help();
		return -1;
	}

	int returnCode = commands.at(command)->execute(args);
	for(CommandsMap::iterator it(commands.begin()) ; it != commands.end() ; ++it) {
		delete it->second;
	}

	return returnCode;
}
