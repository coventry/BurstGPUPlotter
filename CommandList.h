/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#ifndef GPU_PLOT_GENERATOR_COMMAND_LIST_H
#define GPU_PLOT_GENERATOR_COMMAND_LIST_H

#include <string>
#include <vector>
#include <map>
#include <functional>

#include "Command.h"

class CommandList : public Command {
	private:
		typedef std::map<std::string, std::function<int (CommandList*, const std::vector<std::string>&)>> TypesMap;
		TypesMap m_types;

	public:
		CommandList();
		CommandList(const CommandList& p_command);
		virtual ~CommandList() throw ();

		virtual void help() const;
		virtual int execute(const std::vector<std::string>& p_args);

	private:
		int listPlatforms(const std::vector<std::string>& p_args);
		int listDevices(const std::vector<std::string>& p_args);
};


#endif
