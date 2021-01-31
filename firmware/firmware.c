#include <stdint.h>
#include <stdbool.h>
//#include "bk2461_prog.h"

//#define DEBUG 1
// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)

// glitcher hardware block
#define reg_glitch_ctrl     (*(volatile uint8_t*) 0x02000010)
#define reg_glitch_delay    (*(volatile uint32_t*)0x02000014)
#define reg_glitch_duration (*(volatile uint32_t*)0x02000020)
#define reg_glitch_status   (*(volatile uint32_t*)0x02000024)

#define reg_leds (*(volatile uint32_t*)0x03000000)

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss,_heap_start;


uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);

int putchar(int c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
	if (v >= 1000) {
		print(">=1000");
		return;
	}

	if      (v >= 900) { putchar('9'); v -= 900; }
	else if (v >= 800) { putchar('8'); v -= 800; }
	else if (v >= 700) { putchar('7'); v -= 700; }
	else if (v >= 600) { putchar('6'); v -= 600; }
	else if (v >= 500) { putchar('5'); v -= 500; }
	else if (v >= 400) { putchar('4'); v -= 400; }
	else if (v >= 300) { putchar('3'); v -= 300; }
	else if (v >= 200) { putchar('2'); v -= 200; }
	else if (v >= 100) { putchar('1'); v -= 100; }

	if      (v >= 90) { putchar('9'); v -= 90; }
	else if (v >= 80) { putchar('8'); v -= 80; }
	else if (v >= 70) { putchar('7'); v -= 70; }
	else if (v >= 60) { putchar('6'); v -= 60; }
	else if (v >= 50) { putchar('5'); v -= 50; }
	else if (v >= 40) { putchar('4'); v -= 40; }
	else if (v >= 30) { putchar('3'); v -= 30; }
	else if (v >= 20) { putchar('2'); v -= 20; }
	else if (v >= 10) { putchar('1'); v -= 10; }

	if      (v >= 9) { putchar('9'); v -= 9; }
	else if (v >= 8) { putchar('8'); v -= 8; }
	else if (v >= 7) { putchar('7'); v -= 7; }
	else if (v >= 6) { putchar('6'); v -= 6; }
	else if (v >= 5) { putchar('5'); v -= 5; }
	else if (v >= 4) { putchar('4'); v -= 4; }
	else if (v >= 3) { putchar('3'); v -= 3; }
	else if (v >= 2) { putchar('2'); v -= 2; }
	else if (v >= 1) { putchar('1'); v -= 1; }
	else putchar('0');
}

char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	if (prompt)
		print(prompt);

	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 12000000) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
		}
		c = reg_uart_data;
	}
	return c;
}

char getchar()
{
	return getchar_prompt(0);
}

void banner(){
  print("\n");
  print("  ____  _          ____         ____\n");
  print(" |  _ \\(_) ___ ___/ ___|  ___  / ___|\n");
  print(" | |_) | |/ __/ _ \\___ \\ / _ \\| |\n");
  print(" |  __/| | (_| (_) |__) | (_) | |___\n");
  print(" |_|   |_|\\___\\___/____/ \\___/ \\____|\n");
  print("\n");
}


void main() {
    char sc;
	char single_shot=0;
	char mode=0x1;	  // enabled
	char trigger=0x1; // positive
	uint32_t delay=15000000;
    uint32_t duration=200000;
    reg_uart_clkdiv = 139;  // 16000000 (clk)/115200 (baud)

    set_irq_mask(0xff);

    // zero out .bss section
    for (uint32_t *dest = &_sbss; dest < &_ebss;) {
        *dest++ = 0;
    }

    // switch to dual IO mode
    reg_spictrl = (reg_spictrl & ~0x007F0000) | 0x00400000;

    // blink the user LED
    uint32_t led_timer = 0;
    banner();   
    while (1)
    {
      //print("running...\n");     
	  sc = reg_uart_data;
	  if (sc == 'y') mode=0x0;
	  if (sc == 'x') mode=0x1;
	  if (sc == 'p') trigger=0x1;
	  if (sc == 'n') trigger=0x0;
	  if (sc == 's') { single_shot=0x1; }
      if (sc == '+') { duration+=10000; };
      if (sc == '-') { duration-=10000; };
	  if (sc == '6') { delay+=10000; };            
      if (sc == '9') { delay+=10000; };        

	  reg_glitch_delay = delay;
      reg_glitch_duration = duration;
	  		
	  if (single_shot)
	  {
		print("===single===\n");				  
      	reg_glitch_ctrl = mode|(trigger<<1);    
		while ((reg_glitch_status>>7)&1) { print("?"); } // wait for trigger event
		while (!(reg_glitch_status>>7)&1) { print("^"); } // pulse is currently happening
		print("!\n"); // pulse complete, waiting for next single shot event		
		single_shot=0;
	  }

/*	  	  
	  if (reg_glitch_status&1)
	  {				
	  	while (!((reg_glitch_status>>7)&1)) { print("."); };	// wait until trigger + pulse happend
	  }
*/


	  //print_dec((reg_glitch_status>>7)&1);    
	  //print(" ");
    }
}
