/*
	GPU plot generator for Burst coin.
	Author: Cryo
	Bitcoin: 138gMBhCrNkbaiTCmUhP9HLU9xwn5QKZgD
	Burst: BURST-YA29-QCEW-QXC3-BKXDL

	Based on the code of the official miner and dcct's plotgen.
*/

#ifndef SHABAL_CL
#define SHABAL_CL

#include "util.cl"

typedef struct {
	unsigned int A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, AA, AB;
	unsigned int B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, BA, BB, BC, BD, BE, BF;
	unsigned int C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, CA, CB, CC, CD, CE, CF;
	unsigned long W;
	unsigned int ptr;
	unsigned char buffer[64];
} shabal_context_t;

__constant static const unsigned int A_init_256[] = {
	0x52F84552, 0xE54B7999, 0x2D8EE3EC, 0xB9645191,
	0xE0078B86, 0xBB7C44C9, 0xD2B5C1CA, 0xB0D2EB8C,
	0x14CE5A45, 0x22AF50DC, 0xEFFDBC6B, 0xEB21B74A
};

__constant static const unsigned int B_init_256[] = {
	0xB555C6EE, 0x3E710596, 0xA72A652F, 0x9301515F,
	0xDA28C1FA, 0x696FD868, 0x9CB6BF72, 0x0AFE4002,
	0xA6E03615, 0x5138C1D4, 0xBE216306, 0xB38B8890,
	0x3EA8B96B, 0x3299ACE4, 0x30924DD4, 0x55CB34A5
};

__constant static const unsigned int C_init_256[] = {
	0xB405F031, 0xC4233EBA, 0xB3733979, 0xC0DD9D55,
	0xC51C28AE, 0xA327B8E1, 0x56C56167, 0xED614433,
	0x88B59D60, 0x60E2CEBA, 0x758B4B8B, 0x83E82A7F,
	0xBC968828, 0xE6E00BF7, 0xBA839E55, 0x9B491C60
};

void shabal_init(shabal_context_t* p_context) {
	p_context->A0 = A_init_256[0];
	p_context->A1 = A_init_256[1];
	p_context->A2 = A_init_256[2];
	p_context->A3 = A_init_256[3];
	p_context->A4 = A_init_256[4];
	p_context->A5 = A_init_256[5];
	p_context->A6 = A_init_256[6];
	p_context->A7 = A_init_256[7];
	p_context->A8 = A_init_256[8];
	p_context->A9 = A_init_256[9];
	p_context->AA = A_init_256[10];
	p_context->AB = A_init_256[11];

	p_context->B0 = B_init_256[0];
	p_context->B1 = B_init_256[1];
	p_context->B2 = B_init_256[2];
	p_context->B3 = B_init_256[3];
	p_context->B4 = B_init_256[4];
	p_context->B5 = B_init_256[5];
	p_context->B6 = B_init_256[6];
	p_context->B7 = B_init_256[7];
	p_context->B8 = B_init_256[8];
	p_context->B9 = B_init_256[9];
	p_context->BA = B_init_256[10];
	p_context->BB = B_init_256[11];
	p_context->BC = B_init_256[12];
	p_context->BD = B_init_256[13];
	p_context->BE = B_init_256[14];
	p_context->BF = B_init_256[15];

	p_context->C0 = C_init_256[0];
	p_context->C1 = C_init_256[1];
	p_context->C2 = C_init_256[2];
	p_context->C3 = C_init_256[3];
	p_context->C4 = C_init_256[4];
	p_context->C5 = C_init_256[5];
	p_context->C6 = C_init_256[6];
	p_context->C7 = C_init_256[7];
	p_context->C8 = C_init_256[8];
	p_context->C9 = C_init_256[9];
	p_context->CA = C_init_256[10];
	p_context->CB = C_init_256[11];
	p_context->CC = C_init_256[12];
	p_context->CD = C_init_256[13];
	p_context->CE = C_init_256[14];
	p_context->CF = C_init_256[15];

	p_context->W = 1;
	p_context->ptr = 0;
}

void shabal_core(shabal_context_t* p_context, unsigned char* p_data, unsigned int p_offset) {
	unsigned int M0 = decodeIntLE(p_data, p_offset);
	p_context->B0 += M0;
	p_context->B0 = (p_context->B0 << 17) | (p_context->B0 >> 15);
	unsigned int M1 = decodeIntLE(p_data, p_offset + 4);
	p_context->B1 += M1;
	p_context->B1 = (p_context->B1 << 17) | (p_context->B1 >> 15);
	unsigned int M2 = decodeIntLE(p_data, p_offset + 8);
	p_context->B2 += M2;
	p_context->B2 = (p_context->B2 << 17) | (p_context->B2 >> 15);
	unsigned int M3 = decodeIntLE(p_data, p_offset + 12);
	p_context->B3 += M3;
	p_context->B3 = (p_context->B3 << 17) | (p_context->B3 >> 15);
	unsigned int M4 = decodeIntLE(p_data, p_offset + 16);
	p_context->B4 += M4;
	p_context->B4 = (p_context->B4 << 17) | (p_context->B4 >> 15);
	unsigned int M5 = decodeIntLE(p_data, p_offset + 20);
	p_context->B5 += M5;
	p_context->B5 = (p_context->B5 << 17) | (p_context->B5 >> 15);
	unsigned int M6 = decodeIntLE(p_data, p_offset + 24);
	p_context->B6 += M6;
	p_context->B6 = (p_context->B6 << 17) | (p_context->B6 >> 15);
	unsigned int M7 = decodeIntLE(p_data, p_offset + 28);
	p_context->B7 += M7;
	p_context->B7 = (p_context->B7 << 17) | (p_context->B7 >> 15);
	unsigned int M8 = decodeIntLE(p_data, p_offset + 32);
	p_context->B8 += M8;
	p_context->B8 = (p_context->B8 << 17) | (p_context->B8 >> 15);
	unsigned int M9 = decodeIntLE(p_data, p_offset + 36);
	p_context->B9 += M9;
	p_context->B9 = (p_context->B9 << 17) | (p_context->B9 >> 15);
	unsigned int MA = decodeIntLE(p_data, p_offset + 40);
	p_context->BA += MA;
	p_context->BA = (p_context->BA << 17) | (p_context->BA >> 15);
	unsigned int MB = decodeIntLE(p_data, p_offset + 44);
	p_context->BB += MB;
	p_context->BB = (p_context->BB << 17) | (p_context->BB >> 15);
	unsigned int MC = decodeIntLE(p_data, p_offset + 48);
	p_context->BC += MC;
	p_context->BC = (p_context->BC << 17) | (p_context->BC >> 15);
	unsigned int MD = decodeIntLE(p_data, p_offset + 52);
	p_context->BD += MD;
	p_context->BD = (p_context->BD << 17) | (p_context->BD >> 15);
	unsigned int ME = decodeIntLE(p_data, p_offset + 56);
	p_context->BE += ME;
	p_context->BE = (p_context->BE << 17) | (p_context->BE >> 15);
	unsigned int MF = decodeIntLE(p_data, p_offset + 60);
	p_context->BF += MF;
	p_context->BF = (p_context->BF << 17) | (p_context->BF >> 15);

	p_context->A0 ^= (unsigned int)p_context->W;
	p_context->A1 ^= (unsigned int)(p_context->W >> 32);
	++p_context->W;

	p_context->A0 = ((p_context->A0 ^ (((p_context->AB << 15) | (p_context->AB >> 17)) * 5) ^ p_context->C8) * 3) ^ p_context->BD ^ (p_context->B9 & ~p_context->B6) ^ M0;
	p_context->B0 = ~((p_context->B0 << 1) | (p_context->B0 >> 31)) ^ p_context->A0;
	p_context->A1 = ((p_context->A1 ^ (((p_context->A0 << 15) | (p_context->A0 >> 17)) * 5) ^ p_context->C7) * 3) ^ p_context->BE ^ (p_context->BA & ~p_context->B7) ^ M1;
	p_context->B1 = ~((p_context->B1 << 1) | (p_context->B1 >> 31)) ^ p_context->A1;
	p_context->A2 = ((p_context->A2 ^ (((p_context->A1 << 15) | (p_context->A1 >> 17)) * 5) ^ p_context->C6) * 3) ^ p_context->BF ^ (p_context->BB & ~p_context->B8) ^ M2;
	p_context->B2 = ~((p_context->B2 << 1) | (p_context->B2 >> 31)) ^ p_context->A2;
	p_context->A3 = ((p_context->A3 ^ (((p_context->A2 << 15) | (p_context->A2 >> 17)) * 5) ^ p_context->C5) * 3) ^ p_context->B0 ^ (p_context->BC & ~p_context->B9) ^ M3;
	p_context->B3 = ~((p_context->B3 << 1) | (p_context->B3 >> 31)) ^ p_context->A3;
	p_context->A4 = ((p_context->A4 ^ (((p_context->A3 << 15) | (p_context->A3 >> 17)) * 5) ^ p_context->C4) * 3) ^ p_context->B1 ^ (p_context->BD & ~p_context->BA) ^ M4;
	p_context->B4 = ~((p_context->B4 << 1) | (p_context->B4 >> 31)) ^ p_context->A4;
	p_context->A5 = ((p_context->A5 ^ (((p_context->A4 << 15) | (p_context->A4 >> 17)) * 5) ^ p_context->C3) * 3) ^ p_context->B2 ^ (p_context->BE & ~p_context->BB) ^ M5;
	p_context->B5 = ~((p_context->B5 << 1) | (p_context->B5 >> 31)) ^ p_context->A5;
	p_context->A6 = ((p_context->A6 ^ (((p_context->A5 << 15) | (p_context->A5 >> 17)) * 5) ^ p_context->C2) * 3) ^ p_context->B3 ^ (p_context->BF & ~p_context->BC) ^ M6;
	p_context->B6 = ~((p_context->B6 << 1) | (p_context->B6 >> 31)) ^ p_context->A6;
	p_context->A7 = ((p_context->A7 ^ (((p_context->A6 << 15) | (p_context->A6 >> 17)) * 5) ^ p_context->C1) * 3) ^ p_context->B4 ^ (p_context->B0 & ~p_context->BD) ^ M7;
	p_context->B7 = ~((p_context->B7 << 1) | (p_context->B7 >> 31)) ^ p_context->A7;
	p_context->A8 = ((p_context->A8 ^ (((p_context->A7 << 15) | (p_context->A7 >> 17)) * 5) ^ p_context->C0) * 3) ^ p_context->B5 ^ (p_context->B1 & ~p_context->BE) ^ M8;
	p_context->B8 = ~((p_context->B8 << 1) | (p_context->B8 >> 31)) ^ p_context->A8;
	p_context->A9 = ((p_context->A9 ^ (((p_context->A8 << 15) | (p_context->A8 >> 17)) * 5) ^ p_context->CF) * 3) ^ p_context->B6 ^ (p_context->B2 & ~p_context->BF) ^ M9;
	p_context->B9 = ~((p_context->B9 << 1) | (p_context->B9 >> 31)) ^ p_context->A9;
	p_context->AA = ((p_context->AA ^ (((p_context->A9 << 15) | (p_context->A9 >> 17)) * 5) ^ p_context->CE) * 3) ^ p_context->B7 ^ (p_context->B3 & ~p_context->B0) ^ MA;
	p_context->BA = ~((p_context->BA << 1) | (p_context->BA >> 31)) ^ p_context->AA;
	p_context->AB = ((p_context->AB ^ (((p_context->AA << 15) | (p_context->AA >> 17)) * 5) ^ p_context->CD) * 3) ^ p_context->B8 ^ (p_context->B4 & ~p_context->B1) ^ MB;
	p_context->BB = ~((p_context->BB << 1) | (p_context->BB >> 31)) ^ p_context->AB;
	p_context->A0 = ((p_context->A0 ^ (((p_context->AB << 15) | (p_context->AB >> 17)) * 5) ^ p_context->CC) * 3) ^ p_context->B9 ^ (p_context->B5 & ~p_context->B2) ^ MC;
	p_context->BC = ~((p_context->BC << 1) | (p_context->BC >> 31)) ^ p_context->A0;
	p_context->A1 = ((p_context->A1 ^ (((p_context->A0 << 15) | (p_context->A0 >> 17)) * 5) ^ p_context->CB) * 3) ^ p_context->BA ^ (p_context->B6 & ~p_context->B3) ^ MD;
	p_context->BD = ~((p_context->BD << 1) | (p_context->BD >> 31)) ^ p_context->A1;
	p_context->A2 = ((p_context->A2 ^ (((p_context->A1 << 15) | (p_context->A1 >> 17)) * 5) ^ p_context->CA) * 3) ^ p_context->BB ^ (p_context->B7 & ~p_context->B4) ^ ME;
	p_context->BE = ~((p_context->BE << 1) | (p_context->BE >> 31)) ^ p_context->A2;
	p_context->A3 = ((p_context->A3 ^ (((p_context->A2 << 15) | (p_context->A2 >> 17)) * 5) ^ p_context->C9) * 3) ^ p_context->BC ^ (p_context->B8 & ~p_context->B5) ^ MF;
	p_context->BF = ~((p_context->BF << 1) | (p_context->BF >> 31)) ^ p_context->A3;
	p_context->A4 = ((p_context->A4 ^ (((p_context->A3 << 15) | (p_context->A3 >> 17)) * 5) ^ p_context->C8) * 3) ^ p_context->BD ^ (p_context->B9 & ~p_context->B6) ^ M0;
	p_context->B0 = ~((p_context->B0 << 1) | (p_context->B0 >> 31)) ^ p_context->A4;
	p_context->A5 = ((p_context->A5 ^ (((p_context->A4 << 15) | (p_context->A4 >> 17)) * 5) ^ p_context->C7) * 3) ^ p_context->BE ^ (p_context->BA & ~p_context->B7) ^ M1;
	p_context->B1 = ~((p_context->B1 << 1) | (p_context->B1 >> 31)) ^ p_context->A5;
	p_context->A6 = ((p_context->A6 ^ (((p_context->A5 << 15) | (p_context->A5 >> 17)) * 5) ^ p_context->C6) * 3) ^ p_context->BF ^ (p_context->BB & ~p_context->B8) ^ M2;
	p_context->B2 = ~((p_context->B2 << 1) | (p_context->B2 >> 31)) ^ p_context->A6;
	p_context->A7 = ((p_context->A7 ^ (((p_context->A6 << 15) | (p_context->A6 >> 17)) * 5) ^ p_context->C5) * 3) ^ p_context->B0 ^ (p_context->BC & ~p_context->B9) ^ M3;
	p_context->B3 = ~((p_context->B3 << 1) | (p_context->B3 >> 31)) ^ p_context->A7;
	p_context->A8 = ((p_context->A8 ^ (((p_context->A7 << 15) | (p_context->A7 >> 17)) * 5) ^ p_context->C4) * 3) ^ p_context->B1 ^ (p_context->BD & ~p_context->BA) ^ M4;
	p_context->B4 = ~((p_context->B4 << 1) | (p_context->B4 >> 31)) ^ p_context->A8;
	p_context->A9 = ((p_context->A9 ^ (((p_context->A8 << 15) | (p_context->A8 >> 17)) * 5) ^ p_context->C3) * 3) ^ p_context->B2 ^ (p_context->BE & ~p_context->BB) ^ M5;
	p_context->B5 = ~((p_context->B5 << 1) | (p_context->B5 >> 31)) ^ p_context->A9;
	p_context->AA = ((p_context->AA ^ (((p_context->A9 << 15) | (p_context->A9 >> 17)) * 5) ^ p_context->C2) * 3) ^ p_context->B3 ^ (p_context->BF & ~p_context->BC) ^ M6;
	p_context->B6 = ~((p_context->B6 << 1) | (p_context->B6 >> 31)) ^ p_context->AA;
	p_context->AB = ((p_context->AB ^ (((p_context->AA << 15) | (p_context->AA >> 17)) * 5) ^ p_context->C1) * 3) ^ p_context->B4 ^ (p_context->B0 & ~p_context->BD) ^ M7;
	p_context->B7 = ~((p_context->B7 << 1) | (p_context->B7 >> 31)) ^ p_context->AB;
	p_context->A0 = ((p_context->A0 ^ (((p_context->AB << 15) | (p_context->AB >> 17)) * 5) ^ p_context->C0) * 3) ^ p_context->B5 ^ (p_context->B1 & ~p_context->BE) ^ M8;
	p_context->B8 = ~((p_context->B8 << 1) | (p_context->B8 >> 31)) ^ p_context->A0;
	p_context->A1 = ((p_context->A1 ^ (((p_context->A0 << 15) | (p_context->A0 >> 17)) * 5) ^ p_context->CF) * 3) ^ p_context->B6 ^ (p_context->B2 & ~p_context->BF) ^ M9;
	p_context->B9 = ~((p_context->B9 << 1) | (p_context->B9 >> 31)) ^ p_context->A1;
	p_context->A2 = ((p_context->A2 ^ (((p_context->A1 << 15) | (p_context->A1 >> 17)) * 5) ^ p_context->CE) * 3) ^ p_context->B7 ^ (p_context->B3 & ~p_context->B0) ^ MA;
	p_context->BA = ~((p_context->BA << 1) | (p_context->BA >> 31)) ^ p_context->A2;
	p_context->A3 = ((p_context->A3 ^ (((p_context->A2 << 15) | (p_context->A2 >> 17)) * 5) ^ p_context->CD) * 3) ^ p_context->B8 ^ (p_context->B4 & ~p_context->B1) ^ MB;
	p_context->BB = ~((p_context->BB << 1) | (p_context->BB >> 31)) ^ p_context->A3;
	p_context->A4 = ((p_context->A4 ^ (((p_context->A3 << 15) | (p_context->A3 >> 17)) * 5) ^ p_context->CC) * 3) ^ p_context->B9 ^ (p_context->B5 & ~p_context->B2) ^ MC;
	p_context->BC = ~((p_context->BC << 1) | (p_context->BC >> 31)) ^ p_context->A4;
	p_context->A5 = ((p_context->A5 ^ (((p_context->A4 << 15) | (p_context->A4 >> 17)) * 5) ^ p_context->CB) * 3) ^ p_context->BA ^ (p_context->B6 & ~p_context->B3) ^ MD;
	p_context->BD = ~((p_context->BD << 1) | (p_context->BD >> 31)) ^ p_context->A5;
	p_context->A6 = ((p_context->A6 ^ (((p_context->A5 << 15) | (p_context->A5 >> 17)) * 5) ^ p_context->CA) * 3) ^ p_context->BB ^ (p_context->B7 & ~p_context->B4) ^ ME;
	p_context->BE = ~((p_context->BE << 1) | (p_context->BE >> 31)) ^ p_context->A6;
	p_context->A7 = ((p_context->A7 ^ (((p_context->A6 << 15) | (p_context->A6 >> 17)) * 5) ^ p_context->C9) * 3) ^ p_context->BC ^ (p_context->B8 & ~p_context->B5) ^ MF;
	p_context->BF = ~((p_context->BF << 1) | (p_context->BF >> 31)) ^ p_context->A7;
	p_context->A8 = ((p_context->A8 ^ (((p_context->A7 << 15) | (p_context->A7 >> 17)) * 5) ^ p_context->C8) * 3) ^ p_context->BD ^ (p_context->B9 & ~p_context->B6) ^ M0;
	p_context->B0 = ~((p_context->B0 << 1) | (p_context->B0 >> 31)) ^ p_context->A8;
	p_context->A9 = ((p_context->A9 ^ (((p_context->A8 << 15) | (p_context->A8 >> 17)) * 5) ^ p_context->C7) * 3) ^ p_context->BE ^ (p_context->BA & ~p_context->B7) ^ M1;
	p_context->B1 = ~((p_context->B1 << 1) | (p_context->B1 >> 31)) ^ p_context->A9;
	p_context->AA = ((p_context->AA ^ (((p_context->A9 << 15) | (p_context->A9 >> 17)) * 5) ^ p_context->C6) * 3) ^ p_context->BF ^ (p_context->BB & ~p_context->B8) ^ M2;
	p_context->B2 = ~((p_context->B2 << 1) | (p_context->B2 >> 31)) ^ p_context->AA;
	p_context->AB = ((p_context->AB ^ (((p_context->AA << 15) | (p_context->AA >> 17)) * 5) ^ p_context->C5) * 3) ^ p_context->B0 ^ (p_context->BC & ~p_context->B9) ^ M3;
	p_context->B3 = ~((p_context->B3 << 1) | (p_context->B3 >> 31)) ^ p_context->AB;
	p_context->A0 = ((p_context->A0 ^ (((p_context->AB << 15) | (p_context->AB >> 17)) * 5) ^ p_context->C4) * 3) ^ p_context->B1 ^ (p_context->BD & ~p_context->BA) ^ M4;
	p_context->B4 = ~((p_context->B4 << 1) | (p_context->B4 >> 31)) ^ p_context->A0;
	p_context->A1 = ((p_context->A1 ^ (((p_context->A0 << 15) | (p_context->A0 >> 17)) * 5) ^ p_context->C3) * 3) ^ p_context->B2 ^ (p_context->BE & ~p_context->BB) ^ M5;
	p_context->B5 = ~((p_context->B5 << 1) | (p_context->B5 >> 31)) ^ p_context->A1;
	p_context->A2 = ((p_context->A2 ^ (((p_context->A1 << 15) | (p_context->A1 >> 17)) * 5) ^ p_context->C2) * 3) ^ p_context->B3 ^ (p_context->BF & ~p_context->BC) ^ M6;
	p_context->B6 = ~((p_context->B6 << 1) | (p_context->B6 >> 31)) ^ p_context->A2;
	p_context->A3 = ((p_context->A3 ^ (((p_context->A2 << 15) | (p_context->A2 >> 17)) * 5) ^ p_context->C1) * 3) ^ p_context->B4 ^ (p_context->B0 & ~p_context->BD) ^ M7;
	p_context->B7 = ~((p_context->B7 << 1) | (p_context->B7 >> 31)) ^ p_context->A3;
	p_context->A4 = ((p_context->A4 ^ (((p_context->A3 << 15) | (p_context->A3 >> 17)) * 5) ^ p_context->C0) * 3) ^ p_context->B5 ^ (p_context->B1 & ~p_context->BE) ^ M8;
	p_context->B8 = ~((p_context->B8 << 1) | (p_context->B8 >> 31)) ^ p_context->A4;
	p_context->A5 = ((p_context->A5 ^ (((p_context->A4 << 15) | (p_context->A4 >> 17)) * 5) ^ p_context->CF) * 3) ^ p_context->B6 ^ (p_context->B2 & ~p_context->BF) ^ M9;
	p_context->B9 = ~((p_context->B9 << 1) | (p_context->B9 >> 31)) ^ p_context->A5;
	p_context->A6 = ((p_context->A6 ^ (((p_context->A5 << 15) | (p_context->A5 >> 17)) * 5) ^ p_context->CE) * 3) ^ p_context->B7 ^ (p_context->B3 & ~p_context->B0) ^ MA;
	p_context->BA = ~((p_context->BA << 1) | (p_context->BA >> 31)) ^ p_context->A6;
	p_context->A7 = ((p_context->A7 ^ (((p_context->A6 << 15) | (p_context->A6 >> 17)) * 5) ^ p_context->CD) * 3) ^ p_context->B8 ^ (p_context->B4 & ~p_context->B1) ^ MB;
	p_context->BB = ~((p_context->BB << 1) | (p_context->BB >> 31)) ^ p_context->A7;
	p_context->A8 = ((p_context->A8 ^ (((p_context->A7 << 15) | (p_context->A7 >> 17)) * 5) ^ p_context->CC) * 3) ^ p_context->B9 ^ (p_context->B5 & ~p_context->B2) ^ MC;
	p_context->BC = ~((p_context->BC << 1) | (p_context->BC >> 31)) ^ p_context->A8;
	p_context->A9 = ((p_context->A9 ^ (((p_context->A8 << 15) | (p_context->A8 >> 17)) * 5) ^ p_context->CB) * 3) ^ p_context->BA ^ (p_context->B6 & ~p_context->B3) ^ MD;
	p_context->BD = ~((p_context->BD << 1) | (p_context->BD >> 31)) ^ p_context->A9;
	p_context->AA = ((p_context->AA ^ (((p_context->A9 << 15) | (p_context->A9 >> 17)) * 5) ^ p_context->CA) * 3) ^ p_context->BB ^ (p_context->B7 & ~p_context->B4) ^ ME;
	p_context->BE = ~((p_context->BE << 1) | (p_context->BE >> 31)) ^ p_context->AA;
	p_context->AB = ((p_context->AB ^ (((p_context->AA << 15) | (p_context->AA >> 17)) * 5) ^ p_context->C9) * 3) ^ p_context->BC ^ (p_context->B8 & ~p_context->B5) ^ MF;
	p_context->BF = ~((p_context->BF << 1) | (p_context->BF >> 31)) ^ p_context->AB;

	p_context->AB += p_context->C6 + p_context->CA + p_context->CE;
	p_context->AA += p_context->C5 + p_context->C9 + p_context->CD;
	p_context->A9 += p_context->C4 + p_context->C8 + p_context->CC;
	p_context->A8 += p_context->C3 + p_context->C7 + p_context->CB;
	p_context->A7 += p_context->C2 + p_context->C6 + p_context->CA;
	p_context->A6 += p_context->C1 + p_context->C5 + p_context->C9;
	p_context->A5 += p_context->C0 + p_context->C4 + p_context->C8;
	p_context->A4 += p_context->CF + p_context->C3 + p_context->C7;
	p_context->A3 += p_context->CE + p_context->C2 + p_context->C6;
	p_context->A2 += p_context->CD + p_context->C1 + p_context->C5;
	p_context->A1 += p_context->CC + p_context->C0 + p_context->C4;
	p_context->A0 += p_context->CB + p_context->CF + p_context->C3;

	unsigned int tmp;
	tmp = p_context->B0;
	p_context->B0 = p_context->C0 - M0;
	p_context->C0 = tmp;
	tmp = p_context->B1;
	p_context->B1 = p_context->C1 - M1;
	p_context->C1 = tmp;
	tmp = p_context->B2;
	p_context->B2 = p_context->C2 - M2;
	p_context->C2 = tmp;
	tmp = p_context->B3;
	p_context->B3 = p_context->C3 - M3;
	p_context->C3 = tmp;
	tmp = p_context->B4;
	p_context->B4 = p_context->C4 - M4;
	p_context->C4 = tmp;
	tmp = p_context->B5;
	p_context->B5 = p_context->C5 - M5;
	p_context->C5 = tmp;
	tmp = p_context->B6;
	p_context->B6 = p_context->C6 - M6;
	p_context->C6 = tmp;
	tmp = p_context->B7;
	p_context->B7 = p_context->C7 - M7;
	p_context->C7 = tmp;
	tmp = p_context->B8;
	p_context->B8 = p_context->C8 - M8;
	p_context->C8 = tmp;
	tmp = p_context->B9;
	p_context->B9 = p_context->C9 - M9;
	p_context->C9 = tmp;
	tmp = p_context->BA;
	p_context->BA = p_context->CA - MA;
	p_context->CA = tmp;
	tmp = p_context->BB;
	p_context->BB = p_context->CB - MB;
	p_context->CB = tmp;
	tmp = p_context->BC;
	p_context->BC = p_context->CC - MC;
	p_context->CC = tmp;
	tmp = p_context->BD;
	p_context->BD = p_context->CD - MD;
	p_context->CD = tmp;
	tmp = p_context->BE;
	p_context->BE = p_context->CE - ME;
	p_context->CE = tmp;
	tmp = p_context->BF;
	p_context->BF = p_context->CF - MF;
	p_context->CF = tmp;
}

void shabal_update(shabal_context_t* p_context, __global unsigned char* p_data, unsigned int p_offset, unsigned int p_length) {
	if(p_context->ptr != 0) {
		unsigned int rlen = 64 - p_context->ptr;
		if(p_length < rlen) {
			memcpyFromGlobal(p_data, p_offset, p_context->buffer, p_context->ptr, p_length);
			p_context->ptr += p_length;
			return;
		} else {
			memcpyFromGlobal(p_data, p_offset, p_context->buffer, p_context->ptr, rlen);
			p_offset += rlen;
			p_length -= rlen;
		}
	}

	unsigned int num = p_length >> 6;
	unsigned char chunk[64];
	for(unsigned int i = 0 ; i < num ; ++i) {
		memcpyFromGlobal(p_data, p_offset, chunk, 0, 64);
		shabal_core(p_context, chunk, 0);
		p_offset += 64;
	}

	p_context->ptr = p_length % 64;
	memcpyFromGlobal(p_data, p_offset, p_context->buffer, 0, p_context->ptr);
}

void shabal_digest(shabal_context_t* p_context, unsigned char* p_out, unsigned int p_offset, unsigned int p_length) {
	if(p_length > 32) {
		p_length = 32;
	}

	p_context->buffer[p_context->ptr++] = 0x80;

	for(unsigned int i = p_context->ptr ; i < 64 ; ++i) {
		p_context->buffer[i] = 0;
	}

	for(unsigned int i = 0 ; i < 4 ; ++i) {
		shabal_core(p_context, p_context->buffer, 0);
		--p_context->W;
	}

	unsigned int state[32 >> 2];
	state[0] = p_context->C8;
	state[1] = p_context->C9;
	state[2] = p_context->CA;
	state[3] = p_context->CB;
	state[4] = p_context->CC;
	state[5] = p_context->CD;
	state[6] = p_context->CE;
	state[7] = p_context->CF;

	unsigned int j = 0;
	unsigned int w = 0;
	for(unsigned int i = 0 ; i < p_length ; ++i) {
		if(i % 4 == 0) {
			w = state[j++];
		}

		p_out[p_offset + i] = w & 0x0ff;
		w >>= 8;
	}

	shabal_init(p_context);
}

#endif