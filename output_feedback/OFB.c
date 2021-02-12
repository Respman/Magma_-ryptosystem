#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

int k;
uint32_t *key;

/* Нелинейное биективное преобразование по ГОСТ Р 34.12-2015 */
const uint8_t sbox[8][16] = {
	{12, 4, 6, 2, 10, 5, 11, 9, 14, 8, 13, 7, 0, 3, 15, 1},
	{6, 8, 2, 3, 9, 10, 5, 12, 1, 14, 4, 7, 11, 13, 0, 15},
	{11, 3, 5, 8, 2, 15, 10, 13, 14, 1, 7, 4, 12, 9, 6, 0},   
	{12, 8, 2, 1, 13, 4, 15, 6, 7, 0, 10, 5, 3, 14, 9, 11},
	{7, 15, 5, 10, 8, 1, 6, 13, 0, 9, 3, 14, 11, 4, 2, 12},
	{5, 13, 15, 6, 9, 2, 12, 10, 11, 7, 8, 1, 4, 3, 14, 0}, 
	{8, 14, 2, 5, 6, 9, 1, 12, 15, 4, 11, 0, 13, 10, 3, 7},     
	{1, 7, 14, 13, 0, 5, 8, 3, 4, 15, 10, 6, 9, 12, 11, 2}
};



void padding (uint8_t* block, int size){
	int i;
	for (i = size; i < 7; i++) block[i] = 0;
	block[7] = 8 - size;
}

uint64_t encrypt (uint64_t block){
	int i;
	uint32_t right_block = (uint32_t)((block & 0xffffffff) + 
					key[(k<24) ? (k++)%8 : 31-(k++)]);
	uint64_t block_enc = (block & 0xffffffff)<<32;

	for (i = 7; i >= 0; i--) 
			block_enc += ((uint64_t)(sbox[i][(right_block & (0xf<<4*i))>>4*i])<<4*i);
	
	block_enc = (block_enc & 0xffffffff00000000) | 
				(((((uint32_t)(block_enc & 0xffffffff))>>21) | 
				 (((uint32_t)(block_enc & 0xffffffff))<<11))^ 
				((block & 0xffffffff00000000)>>32));
	
	return block_enc;
}

int main (int argc, char** argv){
	FILE *filein, *fileout;
	int size_block; 
	uint8_t *block_mas;
	uint64_t block;
	int i, j, N;
	uint64_t *R;

	if (argc == 5) {

		key = (uint32_t *)malloc(8*sizeof(uint32_t));

		for (i = 0; i < 8; i++){
			key[i] = 0;
			for (j = 8*i; j < 8*(i+1); j++){
				key[i] += (((uint32_t)((argv[3][j] >= 97)?(argv[3][j]-87):(argv[3][j]-48)))<<((8-j+8*i-1)*4));
			}
		}

		N = (int)(strlen(argv[4])/16);

		R = (uint64_t *)malloc(N*sizeof(uint64_t));

		for (i = 0; i < N; i++){
			R[i] = 0;
			for (j = 16*i; j < 16*(i+1); j++){
				R[i] += (((uint64_t)((argv[4][j] >= 97)?(argv[4][j]-87):(argv[4][j]-48)))<<((16-j+16*i-1)*4));
			}
		}
	
		filein = fopen(argv[1], "rb");
		fileout = fopen(argv[2], "wb");
		while ((size_block = fread((uint8_t*)(&block), 1, 8, filein)) != 0){
			if (size_block < 8) padding((uint8_t*)(&block), size_block);
			block_mas = (uint8_t*)(&block);
			for (i = 0; i < 4; i++){
				block_mas[i] ^= block_mas[7-i];
				block_mas[7-i] ^= block_mas[i];
				block_mas[i] ^= block_mas[7-i];
			}
			
			k = 0;
			for (i = 0; i < 31; i++) {
				R[0] = encrypt(R[0]);
			}
			R[0] = (R[0] & 0xffffffff) + ((encrypt(R[0]) & 0xffffffff)<<32);

			block ^= R[0];

			for (i = 0; i < (N-1); i++){
				R[i] ^= R[i+1];
				R[i+1] ^= R[i];
				R[i] ^= R[i+1];
			}
	
			for (i = 0; i < 4; i++){
				block_mas[i] ^= block_mas[7-i];
				block_mas[7-i] ^= block_mas[i];
				block_mas[i] ^= block_mas[7-i];
			}
			fwrite(&block, 8, 1, fileout);
		}
	}
	else printf("wrong amount of parametrs\n");
	return(0);
}
