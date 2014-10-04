/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#ifndef GPU_PLOT_GENERATOR_OPENCL_ERROR_H
#define GPU_PLOT_GENERATOR_OPENCL_ERROR_H

#include <string>
#include <stdexcept>

class OpenclError : public std::runtime_error {
	private:
		int m_code;

	public:
		OpenclError(int p_code, const std::string& p_message);
		OpenclError(int p_code, const char* p_message);

		virtual ~OpenclError() throw ();

		inline int getCode() const;
};

inline int OpenclError::getCode() const {
	return m_code;
}

#endif
