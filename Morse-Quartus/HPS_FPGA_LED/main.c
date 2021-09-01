/*
This program demonstrate how to use hps communicate with FPGA through light AXI Bridge.
uses should program the FPGA by GHRD project before executing the program
refer to user manual chapter 7 for details about the demo
*/


#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

// compare 2 strings: to detect input commands
int strcmp(char string1[], char string2[])
{
    int i;
	for (i = 0; ; i++)
    {
        if (string1[i] != string2[i])
        {
            return string1[i] < string2[i] ? -1 : 1;
        }

        if (string1[i] == '\0')
        {
            return 0;
        }
    }
}

int main() {

	void *virtual_base;
	int fd;

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	
	// decoder pointers
	void *decoder_ptr;		// base 
	char *ready_flag;		// ready flag (register[0])
	char *received;			// received char (register[1])
	decoder_ptr = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + MORSEDECODER_0_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	ready_flag = (char *)decoder_ptr;
	received = (char *)decoder_ptr;
	received++;
	
	// encoder pointers
	void * encoder_ptr;		// base
	char * busy_flag;		// busy or start flag (register[0])
	char * encoder_idx;		// index (to fill buffer)
	encoder_ptr = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + MORSEENCODER_0_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	busy_flag = (char *) encoder_ptr;
	encoder_idx = (char *) encoder_ptr;
	encoder_idx++;
	
	// to detect user inputs (max 31 as this is the max chars to write in encoder buffer) 
	char command[31];
	char message[31];
	
	// to use in for loops
	int i;
	
	while (1){
		printf("Select use mode (decoder,encoder):\n\r");
		scanf("%s",command);
		if (strcmp(command,"decoder") == 0){
			printf("Ready to receive...\n\r");
			while (1){
				if ((*ready_flag) == 1){
					*ready_flag = 0;
					printf("Received char: %c\n\r", (*received));
				}
			}
		}
		else if (strcmp(command,"encoder") == 0){
			while (1){
				printf("Input a message to transmit (use caps, no spaces):\n\r");
				scanf("%s",message);
				i = 0;
				while (message[i] != '\0'){
					*encoder_idx = message[i];
					i++;
					encoder_idx++;
					if (i == 31){			// avoid overwriting internal encoder buffer
						break;
					}
				}
				printf("Starting Morse transmission (LEDs should be blinking)\n\r");
				*busy_flag = (char) 1;		// send start
				while(1){					// poll done
					if ((*busy_flag) == 0){
						printf("Done\n\r");
						break;
					}
				}
				encoder_idx = (char *) encoder_ptr;		// reset this pointer to initial state
				encoder_idx++;
			}
		}
		else {
			printf("Mode not found\n\r");
		}
	}
	
	
	
	
	
	
	/*void * encoder_ptr;
	char * ptr;
	encoder_ptr = virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + MORSEENCODER_0_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	ptr = (char *) encoder_ptr;
	
	printf("Starting program...\n\r");
	printf("\n\rWriting S in reg 1");
	ptr++;
	*ptr = 'S';
	printf("\n\rWriting O in reg 2");
	ptr++;
	*ptr = 'O';
	printf("\n\rWriting S in reg 3");
	ptr++;
	*ptr = 'S';
	printf("\n\rWriting 1 in reg 0 (go)");
	ptr = (char *) encoder_ptr;
	*ptr = (char) 1;
	
	while(1){
		if ((*ptr) == 0){
			printf("Done\n\r");
			break;
		}
	}*/
	
	/*printf("\n\rStarting program...");
	printf("\n\rInitial memory map...");
			
	printf("\n\rReady_flag: %d", (*ready_flag));		
	ready_flag++;
	printf("\n\rChar: %c", (*ready_flag));
	ready_flag++;
	printf("\n\rBuffer: %d", (*ready_flag));
	ready_flag++;
	printf("\n\rCounter: %d", (*ready_flag));
	
	ready_flag = (char *)decoder_ptr;*/
	

	
	
	/*while(1){
		printf("\n\rCurrent char: %c", (*received));
		usleep( 1000*1000 );
	}*/
	
	
	/*while(1){
		printf("\r\nCommand pls: \r\n");
		scanf("%s",input);
		if(strcmp(input,"show")==0) {
			ready_flag = (char *)decoder_ptr;
			printf("\n\rReady_flag: %d", (*ready_flag));
			ready_flag++;
			printf("\n\rChar: %c", (*ready_flag));
			ready_flag++;
			printf("\n\rBuffer: %d", (*ready_flag));
			ready_flag++;
			printf("\n\rCounter: %d", (*ready_flag));
		}
	}*/
	
	
	//printf("\n\rInitial value of ready_flag: %d", (*ready_flag));
	//printf("\n\rInitial value of received char: %c", (*received));
	//printf("Yes");
	
	/*while(1){
		printf("\n\rCurrent char: %c", (*received));
		usleep( 1000*1000 );
	}*/
	
	
	/*while(1){
		if ((*ready_flag)==((char)1)){
			printf("\n\rReceived char: %c", (*received));
			printf("\n\rFlag: %d", (*ready_flag));
			*ready_flag = 0;
			printf("\n\rFlag: %d", (*ready_flag));
		}
	}*/	
	
	/*while(1){
		printf("\n\rCurrent value of ready_flag: %d", (*ready_flag));
		printf("\n\rCurrent value of received char: %c", (*received));
		usleep( 1000*1000 );
	}*/
	
	/*reg_addr = (char *) decoder_ptr;
	for (j = 0; j < 2; j++){
		printf("In address %p, we have char: %c \r\n", reg_addr , (*reg_addr));
		reg_addr++;
	}
	
	reg_addr = (char *) decoder_ptr;
	for (j = 0; j < 2; j++){
		*reg_addr = 'x';
		reg_addr++;
	}

	reg_addr = (char *) decoder_ptr;
	for (j = 0; j < 2; j++){
		printf("In address %p, we have char: %c \r\n", reg_addr , (*reg_addr));
		reg_addr++;
	}*/
	
	/*while(1){
		printf("\r\nCommand pls: \r\n");
		scanf("%s",input);
		if(strcmp(input,"go")==0) {
			reg_addr = (char *) decoder_ptr;
			for (j = 0; j < 16; j++){
			printf("In address %p, we have char: %c \r\n", reg_addr , (*reg_addr));
			reg_addr++;
			}
		}
	}*/
	
	
	/*if((*ready_flag)==(char)1){
		printf("\n\rReceived: %c", (*received));
	}*/

	
	// clean up our memory mapping and exit
	
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );

	return( 0 );
}
