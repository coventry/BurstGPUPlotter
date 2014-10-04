/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#ifndef GPU_PLOT_GENERATOR_COMMAND_GENERATE_H
#define GPU_PLOT_GENERATOR_COMMAND_GENERATE_H

#include <string>
#include <vector>
#include <exception>

#include "Command.h"

class CommandGenerate : public Command {
	public:
		CommandGenerate();
		CommandGenerate(const CommandGenerate& p_command);
		virtual ~CommandGenerate() throw ();

		virtual void help() const;
		virtual int execute(const std::vector<std::string>& p_args);

	private:
		std::string loadSource(const std::string& p_file) throw (std::exception);
};

#endif
