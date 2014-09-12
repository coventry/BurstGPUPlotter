/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#include "OpenclError.h"

OpenclError::OpenclError(int p_code, const std::string& p_message)
: std::runtime_error(p_message), m_code(p_code) {
}

OpenclError::OpenclError(int p_code, const char* p_message)
: std::runtime_error(p_message), m_code(p_code) {
}

OpenclError::~OpenclError() throw () {}
