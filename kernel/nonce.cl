/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

typedef unsigned int sph_u32;
 
#define SPH_C32(x)    ((sph_u32)(x ## U))
#define SPH_T32(x) (as_uint(x))
#define SPH_ROTL32(x, n) rotate(as_uint(x), as_uint(n))
#define SPH_ROTR32(x, n)   SPH_ROTL32(x, (32 - (n)))

#define SPH_C64(x)    ((sph_u64)(x ## UL))
#define SPH_T64(x) (as_ulong(x))
#define SPH_ROTL64(x, n) rotate(as_ulong(x), (n) & 0xFFFFFFFFFFFFFFFFUL)
#define SPH_ROTR64(x, n)   SPH_ROTL64(x, (64 - (n)))

#include "util.cl"
#include "shabal.cl"
#include "shabalalt.cl"

#define HASH_SIZE			32
#define HASHES_PER_SCOOP	2
#define SCOOP_SIZE			(HASHES_PER_SCOOP * HASH_SIZE)
#define SCOOPS_PER_PLOT		4096
#define PLOT_SIZE			(SCOOPS_PER_PLOT * SCOOP_SIZE)
#define HASH_CAP			4096
#define GEN_SIZE			(PLOT_SIZE + 16)

__kernel void nonce_step1(unsigned long p_address, unsigned long p_startNonce, __global unsigned char* p_gen) {
	size_t id = get_global_id(0);
	unsigned long currentNonce = p_startNonce + id;
	unsigned int genOffset = GEN_SIZE * id;

	encodeLongBEGlobal(p_gen, genOffset + PLOT_SIZE, p_address);
	encodeLongBEGlobal(p_gen, genOffset + PLOT_SIZE + 8, currentNonce);
}

__kernel void nonce_step2(unsigned long p_startNonce, __global unsigned char* p_gen, unsigned int p_hashesOffset, unsigned int p_hashesNumber) {
	size_t id = get_global_id(0);
	unsigned long currentNonce = p_startNonce + id;
	unsigned int genOffset = GEN_SIZE * id;
	unsigned char hash[HASH_SIZE];

	shabal_context_t context;
	__local unsigned int numHashes;
	numHashes = p_hashesNumber;
	if(p_hashesNumber * HASH_SIZE > p_hashesOffset) {
		numHashes = p_hashesOffset / HASH_SIZE;
	}
	unsigned int len = GEN_SIZE - p_hashesOffset;
	if(len > HASH_CAP) {
		len = HASH_CAP;
	}
	for(unsigned int i = 0 ; i < numHashes ; ++i) {
		sph_u32 A00 = A_init_256[0], A01 = A_init_256[1], A02 = A_init_256[2], A03 = A_init_256[3], A04 = A_init_256[4], A05 = A_init_256[5], A06 = A_init_256[6], A07 = A_init_256[7],
			A08 = A_init_256[8], A09 = A_init_256[9], A0A = A_init_256[10], A0B = A_init_256[11];
		sph_u32 B0 = B_init_256[0], B1 = B_init_256[1], B2 = B_init_256[2], B3 = B_init_256[3], B4 = B_init_256[4], B5 = B_init_256[5], B6 = B_init_256[6], B7 = B_init_256[7],
			B8 = B_init_256[8], B9 = B_init_256[9], BA = B_init_256[10], BB = B_init_256[11], BC = B_init_256[12], BD = B_init_256[13], BE = B_init_256[14], BF = B_init_256[15];
		sph_u32 C0 = C_init_256[0], C1 = C_init_256[1], C2 = C_init_256[2], C3 = C_init_256[3], C4 = C_init_256[4], C5 = C_init_256[5], C6 = C_init_256[6], C7 = C_init_256[7],
			C8 = C_init_256[8], C9 = C_init_256[9], CA = C_init_256[10], CB = C_init_256[11], CC = C_init_256[12], CD = C_init_256[13], CE = C_init_256[14], CF = C_init_256[15];
		sph_u32 M0, M1, M2, M3, M4, M5, M6, M7, M8, M9, MA, MB, MC, MD, ME, MF;
		sph_u32 Wlow = 1, Whigh = 0;
		
		unsigned int numFullRounds = len >> 6;
		unsigned int numRemaining = len & 63;
		
		for(unsigned int j = 0; j < numFullRounds; j++) {
			unsigned long base = (p_hashesOffset / 4) + (genOffset / 4) + (j * 16);
			M0 = ((__global unsigned int*)p_gen)[base];
			M1 = ((__global unsigned int*)p_gen)[base + 1];
			M2 = ((__global unsigned int*)p_gen)[base + 2];
			M3 = ((__global unsigned int*)p_gen)[base + 3];
			M4 = ((__global unsigned int*)p_gen)[base + 4];
			M5 = ((__global unsigned int*)p_gen)[base + 5];
			M6 = ((__global unsigned int*)p_gen)[base + 6];
			M7 = ((__global unsigned int*)p_gen)[base + 7];
			M8 = ((__global unsigned int*)p_gen)[base + 8];
			M9 = ((__global unsigned int*)p_gen)[base + 9];
			MA = ((__global unsigned int*)p_gen)[base + 10];
			MB = ((__global unsigned int*)p_gen)[base + 11];
			MC = ((__global unsigned int*)p_gen)[base + 12];
			MD = ((__global unsigned int*)p_gen)[base + 13];
			ME = ((__global unsigned int*)p_gen)[base + 14];
			MF = ((__global unsigned int*)p_gen)[base + 15];
			
			INPUT_BLOCK_ADD;
			XOR_W;
			APPLY_P;
			INPUT_BLOCK_SUB;
			SWAP_BC;
			INCR_W;
		}
		
		if(numRemaining == 0) {
			M0 = 0x80;
			M1 = M2 = M3 = M4 = M5 = M6 = M7 = M8 = M9 = MA = MB = MC = MD = ME = MF = 0;
			INPUT_BLOCK_ADD;
			XOR_W;
			APPLY_P;
			for (unsigned i = 0; i < 3; i ++) {
				SWAP_BC;
				XOR_W;
				APPLY_P;
			}
		}
		else if(numRemaining == 16) {
			unsigned long base = (p_hashesOffset / 4) + (genOffset / 4) + (numFullRounds * 16);
			M0 = ((__global unsigned int*)p_gen)[base];
			M1 = ((__global unsigned int*)p_gen)[base + 1];
			M2 = ((__global unsigned int*)p_gen)[base + 2];
			M3 = ((__global unsigned int*)p_gen)[base + 3];
			M4 = 0x80;
			M5 = M6 = M7 = M8 = M9 = MA = MB = MC = MD = ME = MF = 0;
			INPUT_BLOCK_ADD;
			XOR_W;
			APPLY_P;
			for (unsigned i = 0; i < 3; i ++) {
				SWAP_BC;
				XOR_W;
				APPLY_P;
			}
		}
		else {
			unsigned long base = (p_hashesOffset / 4) + (genOffset / 4) + (numFullRounds * 16);
			M0 = ((__global unsigned int*)p_gen)[base];
			M1 = ((__global unsigned int*)p_gen)[base + 1];
			M2 = ((__global unsigned int*)p_gen)[base + 2];
			M3 = ((__global unsigned int*)p_gen)[base + 3];
			M4 = ((__global unsigned int*)p_gen)[base + 4];
			M5 = ((__global unsigned int*)p_gen)[base + 5];
			M6 = ((__global unsigned int*)p_gen)[base + 6];
			M7 = ((__global unsigned int*)p_gen)[base + 7];
			M8 = ((__global unsigned int*)p_gen)[base + 8];
			M9 = ((__global unsigned int*)p_gen)[base + 9];
			MA = ((__global unsigned int*)p_gen)[base + 10];
			MB = ((__global unsigned int*)p_gen)[base + 11];
			MC = 0x80;
			MD = ME = MF = 0;
			INPUT_BLOCK_ADD;
			XOR_W;
			APPLY_P;
			for (unsigned i = 0; i < 3; i ++) {
				SWAP_BC;
				XOR_W;
				APPLY_P;
			}
		}
		
		unsigned int outBuffer[8];
		outBuffer[0] = B8;
		outBuffer[1] = B9;
		outBuffer[2] = BA;
		outBuffer[3] = BB;
		outBuffer[4] = BC;
		outBuffer[5] = BD;
		outBuffer[6] = BE;
		outBuffer[7] = BF;
		barrier(CLK_LOCAL_MEM_FENCE);
		memcpyToGlobal((unsigned char*)outBuffer, 0, p_gen, genOffset + p_hashesOffset - HASH_SIZE, 32);

		p_hashesOffset -= HASH_SIZE;
		len += HASH_SIZE;
		len &= ((len >> 12)*48)^8191;
		barrier(CLK_LOCAL_MEM_FENCE);
	}
}

__kernel void nonce_step3(unsigned int p_staggerSize, __global unsigned char* p_gen, __global unsigned char* p_scoops) {
	size_t id = get_global_id(0);
	unsigned int genOffset = GEN_SIZE * id;
	unsigned char hash[HASH_SIZE];

	shabal_context_t context;
	shabal_init(&context);
	shabal_update(&context, p_gen, genOffset, GEN_SIZE);
	shabal_digest(&context, hash, 0, HASH_SIZE);

	for(unsigned int i = 0 ; i < PLOT_SIZE ; ++i) {
		p_gen[genOffset + i] ^= hash[i % HASH_SIZE];
	}

	for(unsigned int i = 0 ; i < SCOOPS_PER_PLOT ; ++i) {
		memcpyGlobal(p_gen, genOffset + i * SCOOP_SIZE, p_scoops, i * SCOOP_SIZE * p_staggerSize + id * SCOOP_SIZE, SCOOP_SIZE);
	}
}