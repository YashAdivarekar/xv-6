
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	3bc78793          	addi	a5,a5,956 # 80006420 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb77ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	fba78793          	addi	a5,a5,-70 # 80001068 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7c4080e7          	jalr	1988(ra) # 800028f0 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	c2a080e7          	jalr	-982(ra) # 80000dbe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	a0a080e7          	jalr	-1526(ra) # 80001bce <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	1ca080e7          	jalr	458(ra) # 8000239e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	68a080e7          	jalr	1674(ra) # 8000289a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	c46080e7          	jalr	-954(ra) # 80000e72 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	c30080e7          	jalr	-976(ra) # 80000e72 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	aea080e7          	jalr	-1302(ra) # 80000dbe <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	654080e7          	jalr	1620(ra) # 80002946 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b70080e7          	jalr	-1168(ra) # 80000e72 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	230080e7          	jalr	560(ra) # 80002676 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	8c6080e7          	jalr	-1850(ra) # 80000d2e <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	0b878793          	addi	a5,a5,184 # 80242530 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	bbc50513          	addi	a0,a0,-1092 # 80008128 <digits+0xe8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	7be080e7          	jalr	1982(ra) # 80000dbe <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	70e080e7          	jalr	1806(ra) # 80000e72 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	5a4080e7          	jalr	1444(ra) # 80000d2e <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	54e080e7          	jalr	1358(ra) # 80000d2e <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	576080e7          	jalr	1398(ra) # 80000d72 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	5e4080e7          	jalr	1508(ra) # 80000e12 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	dd6080e7          	jalr	-554(ra) # 80002676 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	4da080e7          	jalr	1242(ra) # 80000dbe <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a72080e7          	jalr	-1422(ra) # 8000239e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	50a080e7          	jalr	1290(ra) # 80000e72 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	3ea080e7          	jalr	1002(ra) # 80000dbe <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	48c080e7          	jalr	1164(ra) # 80000e72 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <inc_page_ref>:
  struct spinlock lock;
  int count[PGROUNDUP(PHYSTOP)>>12];
} page_ref;


void inc_page_ref(void*pa){
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	1000                	addi	s0,sp,32
    80000a02:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000a04:	00011517          	auipc	a0,0x11
    80000a08:	89c50513          	addi	a0,a0,-1892 # 800112a0 <page_ref>
    80000a0c:	00000097          	auipc	ra,0x0
    80000a10:	3b2080e7          	jalr	946(ra) # 80000dbe <acquire>
  if(page_ref.count[(uint64)pa>>12]<0){
    80000a14:	00c4d793          	srli	a5,s1,0xc
    80000a18:	00478713          	addi	a4,a5,4
    80000a1c:	00271693          	slli	a3,a4,0x2
    80000a20:	00011717          	auipc	a4,0x11
    80000a24:	88070713          	addi	a4,a4,-1920 # 800112a0 <page_ref>
    80000a28:	9736                	add	a4,a4,a3
    80000a2a:	4718                	lw	a4,8(a4)
    80000a2c:	02074463          	bltz	a4,80000a54 <inc_page_ref+0x5c>
    panic("inc_page_ref");
  }
  page_ref.count[(uint64)pa>>12]+=1;
    80000a30:	00011517          	auipc	a0,0x11
    80000a34:	87050513          	addi	a0,a0,-1936 # 800112a0 <page_ref>
    80000a38:	0791                	addi	a5,a5,4
    80000a3a:	078a                	slli	a5,a5,0x2
    80000a3c:	97aa                	add	a5,a5,a0
    80000a3e:	2705                	addiw	a4,a4,1
    80000a40:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000a42:	00000097          	auipc	ra,0x0
    80000a46:	430080e7          	jalr	1072(ra) # 80000e72 <release>
}
    80000a4a:	60e2                	ld	ra,24(sp)
    80000a4c:	6442                	ld	s0,16(sp)
    80000a4e:	64a2                	ld	s1,8(sp)
    80000a50:	6105                	addi	sp,sp,32
    80000a52:	8082                	ret
    panic("inc_page_ref");
    80000a54:	00007517          	auipc	a0,0x7
    80000a58:	60c50513          	addi	a0,a0,1548 # 80008060 <digits+0x20>
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>

0000000080000a64 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a64:	1101                	addi	sp,sp,-32
    80000a66:	ec06                	sd	ra,24(sp)
    80000a68:	e822                	sd	s0,16(sp)
    80000a6a:	e426                	sd	s1,8(sp)
    80000a6c:	e04a                	sd	s2,0(sp)
    80000a6e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a70:	03451793          	slli	a5,a0,0x34
    80000a74:	e7dd                	bnez	a5,80000b22 <kfree+0xbe>
    80000a76:	84aa                	mv	s1,a0
    80000a78:	00246797          	auipc	a5,0x246
    80000a7c:	58878793          	addi	a5,a5,1416 # 80247000 <end>
    80000a80:	0af56163          	bltu	a0,a5,80000b22 <kfree+0xbe>
    80000a84:	47c5                	li	a5,17
    80000a86:	07ee                	slli	a5,a5,0x1b
    80000a88:	08f57d63          	bgeu	a0,a5,80000b22 <kfree+0xbe>
    panic("kfree");

  acquire(&page_ref.lock);
    80000a8c:	00011517          	auipc	a0,0x11
    80000a90:	81450513          	addi	a0,a0,-2028 # 800112a0 <page_ref>
    80000a94:	00000097          	auipc	ra,0x0
    80000a98:	32a080e7          	jalr	810(ra) # 80000dbe <acquire>
  if(page_ref.count[(uint64)pa>>12]<=0){
    80000a9c:	00c4d793          	srli	a5,s1,0xc
    80000aa0:	00478713          	addi	a4,a5,4
    80000aa4:	00271693          	slli	a3,a4,0x2
    80000aa8:	00010717          	auipc	a4,0x10
    80000aac:	7f870713          	addi	a4,a4,2040 # 800112a0 <page_ref>
    80000ab0:	9736                	add	a4,a4,a3
    80000ab2:	4718                	lw	a4,8(a4)
    80000ab4:	06e05f63          	blez	a4,80000b32 <kfree+0xce>
    panic("page ref could not be decreased");
  }
  page_ref.count[(uint64)pa>>12]--;
    80000ab8:	377d                	addiw	a4,a4,-1
    80000aba:	0007061b          	sext.w	a2,a4
    80000abe:	0791                	addi	a5,a5,4
    80000ac0:	078a                	slli	a5,a5,0x2
    80000ac2:	00010697          	auipc	a3,0x10
    80000ac6:	7de68693          	addi	a3,a3,2014 # 800112a0 <page_ref>
    80000aca:	97b6                	add	a5,a5,a3
    80000acc:	c798                	sw	a4,8(a5)
  if(page_ref.count[(uint64)pa>>12]>0){
    80000ace:	06c04a63          	bgtz	a2,80000b42 <kfree+0xde>
    release(&page_ref.lock);
    return;
  }
  release(&page_ref.lock);
    80000ad2:	00010517          	auipc	a0,0x10
    80000ad6:	7ce50513          	addi	a0,a0,1998 # 800112a0 <page_ref>
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	398080e7          	jalr	920(ra) # 80000e72 <release>
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ae2:	6605                	lui	a2,0x1
    80000ae4:	4585                	li	a1,1
    80000ae6:	8526                	mv	a0,s1
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	3d2080e7          	jalr	978(ra) # 80000eba <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000af0:	00010917          	auipc	s2,0x10
    80000af4:	79090913          	addi	s2,s2,1936 # 80011280 <kmem>
    80000af8:	854a                	mv	a0,s2
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	2c4080e7          	jalr	708(ra) # 80000dbe <acquire>
  r->next = kmem.freelist;
    80000b02:	01893783          	ld	a5,24(s2)
    80000b06:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b08:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b0c:	854a                	mv	a0,s2
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	364080e7          	jalr	868(ra) # 80000e72 <release>
}
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6902                	ld	s2,0(sp)
    80000b1e:	6105                	addi	sp,sp,32
    80000b20:	8082                	ret
    panic("kfree");
    80000b22:	00007517          	auipc	a0,0x7
    80000b26:	54e50513          	addi	a0,a0,1358 # 80008070 <digits+0x30>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	a14080e7          	jalr	-1516(ra) # 8000053e <panic>
    panic("page ref could not be decreased");
    80000b32:	00007517          	auipc	a0,0x7
    80000b36:	54650513          	addi	a0,a0,1350 # 80008078 <digits+0x38>
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	a04080e7          	jalr	-1532(ra) # 8000053e <panic>
    release(&page_ref.lock);
    80000b42:	8536                	mv	a0,a3
    80000b44:	00000097          	auipc	ra,0x0
    80000b48:	32e080e7          	jalr	814(ra) # 80000e72 <release>
    return;
    80000b4c:	b7e9                	j	80000b16 <kfree+0xb2>

0000000080000b4e <freerange>:
{
    80000b4e:	7139                	addi	sp,sp,-64
    80000b50:	fc06                	sd	ra,56(sp)
    80000b52:	f822                	sd	s0,48(sp)
    80000b54:	f426                	sd	s1,40(sp)
    80000b56:	f04a                	sd	s2,32(sp)
    80000b58:	ec4e                	sd	s3,24(sp)
    80000b5a:	e852                	sd	s4,16(sp)
    80000b5c:	e456                	sd	s5,8(sp)
    80000b5e:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b60:	6785                	lui	a5,0x1
    80000b62:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b66:	9526                	add	a0,a0,s1
    80000b68:	74fd                	lui	s1,0xfffff
    80000b6a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b6c:	97a6                	add	a5,a5,s1
    80000b6e:	04f5ed63          	bltu	a1,a5,80000bc8 <freerange+0x7a>
    80000b72:	89ae                	mv	s3,a1
  acquire(&page_ref.lock);
    80000b74:	00010917          	auipc	s2,0x10
    80000b78:	72c90913          	addi	s2,s2,1836 # 800112a0 <page_ref>
    80000b7c:	6a85                	lui	s5,0x1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b7e:	6a09                	lui	s4,0x2
    80000b80:	a011                	j	80000b84 <freerange+0x36>
    80000b82:	84be                	mv	s1,a5
  acquire(&page_ref.lock);
    80000b84:	854a                	mv	a0,s2
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	238080e7          	jalr	568(ra) # 80000dbe <acquire>
  if(page_ref.count[(uint64)p>>12]<0)
    80000b8e:	00c4d793          	srli	a5,s1,0xc
    80000b92:	00478713          	addi	a4,a5,4
    80000b96:	070a                	slli	a4,a4,0x2
    80000b98:	974a                	add	a4,a4,s2
    80000b9a:	4718                	lw	a4,8(a4)
    80000b9c:	02074f63          	bltz	a4,80000bda <freerange+0x8c>
  page_ref.count[(uint64)p>>12]++;
    80000ba0:	0791                	addi	a5,a5,4
    80000ba2:	078a                	slli	a5,a5,0x2
    80000ba4:	97ca                	add	a5,a5,s2
    80000ba6:	2705                	addiw	a4,a4,1
    80000ba8:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000baa:	854a                	mv	a0,s2
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	2c6080e7          	jalr	710(ra) # 80000e72 <release>
    kfree(p);
    80000bb4:	8526                	mv	a0,s1
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	eae080e7          	jalr	-338(ra) # 80000a64 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000bbe:	015487b3          	add	a5,s1,s5
    80000bc2:	94d2                	add	s1,s1,s4
    80000bc4:	fa99ffe3          	bgeu	s3,s1,80000b82 <freerange+0x34>
}
    80000bc8:	70e2                	ld	ra,56(sp)
    80000bca:	7442                	ld	s0,48(sp)
    80000bcc:	74a2                	ld	s1,40(sp)
    80000bce:	7902                	ld	s2,32(sp)
    80000bd0:	69e2                	ld	s3,24(sp)
    80000bd2:	6a42                	ld	s4,16(sp)
    80000bd4:	6aa2                	ld	s5,8(sp)
    80000bd6:	6121                	addi	sp,sp,64
    80000bd8:	8082                	ret
    panic("page ref cannot be increased");
    80000bda:	00007517          	auipc	a0,0x7
    80000bde:	4be50513          	addi	a0,a0,1214 # 80008098 <digits+0x58>
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	95c080e7          	jalr	-1700(ra) # 8000053e <panic>

0000000080000bea <kinit>:
{
    80000bea:	1141                	addi	sp,sp,-16
    80000bec:	e406                	sd	ra,8(sp)
    80000bee:	e022                	sd	s0,0(sp)
    80000bf0:	0800                	addi	s0,sp,16
  initlock(&page_ref.lock, "page_ref");
    80000bf2:	00007597          	auipc	a1,0x7
    80000bf6:	4c658593          	addi	a1,a1,1222 # 800080b8 <digits+0x78>
    80000bfa:	00010517          	auipc	a0,0x10
    80000bfe:	6a650513          	addi	a0,a0,1702 # 800112a0 <page_ref>
    80000c02:	00000097          	auipc	ra,0x0
    80000c06:	12c080e7          	jalr	300(ra) # 80000d2e <initlock>
  acquire(&page_ref.lock);
    80000c0a:	00010517          	auipc	a0,0x10
    80000c0e:	69650513          	addi	a0,a0,1686 # 800112a0 <page_ref>
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	1ac080e7          	jalr	428(ra) # 80000dbe <acquire>
  for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
    80000c1a:	00010797          	auipc	a5,0x10
    80000c1e:	69e78793          	addi	a5,a5,1694 # 800112b8 <page_ref+0x18>
    80000c22:	00230717          	auipc	a4,0x230
    80000c26:	69670713          	addi	a4,a4,1686 # 802312b8 <pid_lock>
    page_ref.count[i]=0;
    80000c2a:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
    80000c2e:	0791                	addi	a5,a5,4
    80000c30:	fee79de3          	bne	a5,a4,80000c2a <kinit+0x40>
  release(&page_ref.lock);
    80000c34:	00010517          	auipc	a0,0x10
    80000c38:	66c50513          	addi	a0,a0,1644 # 800112a0 <page_ref>
    80000c3c:	00000097          	auipc	ra,0x0
    80000c40:	236080e7          	jalr	566(ra) # 80000e72 <release>
  initlock(&kmem.lock, "kmem");
    80000c44:	00007597          	auipc	a1,0x7
    80000c48:	48458593          	addi	a1,a1,1156 # 800080c8 <digits+0x88>
    80000c4c:	00010517          	auipc	a0,0x10
    80000c50:	63450513          	addi	a0,a0,1588 # 80011280 <kmem>
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	0da080e7          	jalr	218(ra) # 80000d2e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000c5c:	45c5                	li	a1,17
    80000c5e:	05ee                	slli	a1,a1,0x1b
    80000c60:	00246517          	auipc	a0,0x246
    80000c64:	3a050513          	addi	a0,a0,928 # 80247000 <end>
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	ee6080e7          	jalr	-282(ra) # 80000b4e <freerange>
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret

0000000080000c78 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c78:	1101                	addi	sp,sp,-32
    80000c7a:	ec06                	sd	ra,24(sp)
    80000c7c:	e822                	sd	s0,16(sp)
    80000c7e:	e426                	sd	s1,8(sp)
    80000c80:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c82:	00010497          	auipc	s1,0x10
    80000c86:	5fe48493          	addi	s1,s1,1534 # 80011280 <kmem>
    80000c8a:	8526                	mv	a0,s1
    80000c8c:	00000097          	auipc	ra,0x0
    80000c90:	132080e7          	jalr	306(ra) # 80000dbe <acquire>
  r = kmem.freelist;
    80000c94:	6c84                	ld	s1,24(s1)
  if(r)
    80000c96:	c0d9                	beqz	s1,80000d1c <kalloc+0xa4>
    kmem.freelist = r->next;
    80000c98:	609c                	ld	a5,0(s1)
    80000c9a:	00010517          	auipc	a0,0x10
    80000c9e:	5e650513          	addi	a0,a0,1510 # 80011280 <kmem>
    80000ca2:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	1ce080e7          	jalr	462(ra) # 80000e72 <release>

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000cac:	6605                	lui	a2,0x1
    80000cae:	4595                	li	a1,5
    80000cb0:	8526                	mv	a0,s1
    80000cb2:	00000097          	auipc	ra,0x0
    80000cb6:	208080e7          	jalr	520(ra) # 80000eba <memset>
    acquire(&page_ref.lock);
    80000cba:	00010517          	auipc	a0,0x10
    80000cbe:	5e650513          	addi	a0,a0,1510 # 800112a0 <page_ref>
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	0fc080e7          	jalr	252(ra) # 80000dbe <acquire>
  if(page_ref.count[(uint64)r>>12]<0)
    80000cca:	00c4d793          	srli	a5,s1,0xc
    80000cce:	00478713          	addi	a4,a5,4
    80000cd2:	00271693          	slli	a3,a4,0x2
    80000cd6:	00010717          	auipc	a4,0x10
    80000cda:	5ca70713          	addi	a4,a4,1482 # 800112a0 <page_ref>
    80000cde:	9736                	add	a4,a4,a3
    80000ce0:	4718                	lw	a4,8(a4)
    80000ce2:	02074563          	bltz	a4,80000d0c <kalloc+0x94>
  {
    panic("page ref cannot be increased");
  }
  page_ref.count[(uint64)r>>12]++;
    80000ce6:	00010517          	auipc	a0,0x10
    80000cea:	5ba50513          	addi	a0,a0,1466 # 800112a0 <page_ref>
    80000cee:	0791                	addi	a5,a5,4
    80000cf0:	078a                	slli	a5,a5,0x2
    80000cf2:	97aa                	add	a5,a5,a0
    80000cf4:	2705                	addiw	a4,a4,1
    80000cf6:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	17a080e7          	jalr	378(ra) # 80000e72 <release>
  }
  return (void*)r;
}
    80000d00:	8526                	mv	a0,s1
    80000d02:	60e2                	ld	ra,24(sp)
    80000d04:	6442                	ld	s0,16(sp)
    80000d06:	64a2                	ld	s1,8(sp)
    80000d08:	6105                	addi	sp,sp,32
    80000d0a:	8082                	ret
    panic("page ref cannot be increased");
    80000d0c:	00007517          	auipc	a0,0x7
    80000d10:	38c50513          	addi	a0,a0,908 # 80008098 <digits+0x58>
    80000d14:	00000097          	auipc	ra,0x0
    80000d18:	82a080e7          	jalr	-2006(ra) # 8000053e <panic>
  release(&kmem.lock);
    80000d1c:	00010517          	auipc	a0,0x10
    80000d20:	56450513          	addi	a0,a0,1380 # 80011280 <kmem>
    80000d24:	00000097          	auipc	ra,0x0
    80000d28:	14e080e7          	jalr	334(ra) # 80000e72 <release>
  if(r){
    80000d2c:	bfd1                	j	80000d00 <kalloc+0x88>

0000000080000d2e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d34:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d36:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d3a:	00053823          	sd	zero,16(a0)
}
    80000d3e:	6422                	ld	s0,8(sp)
    80000d40:	0141                	addi	sp,sp,16
    80000d42:	8082                	ret

0000000080000d44 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d44:	411c                	lw	a5,0(a0)
    80000d46:	e399                	bnez	a5,80000d4c <holding+0x8>
    80000d48:	4501                	li	a0,0
  return r;
}
    80000d4a:	8082                	ret
{
    80000d4c:	1101                	addi	sp,sp,-32
    80000d4e:	ec06                	sd	ra,24(sp)
    80000d50:	e822                	sd	s0,16(sp)
    80000d52:	e426                	sd	s1,8(sp)
    80000d54:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d56:	6904                	ld	s1,16(a0)
    80000d58:	00001097          	auipc	ra,0x1
    80000d5c:	e5a080e7          	jalr	-422(ra) # 80001bb2 <mycpu>
    80000d60:	40a48533          	sub	a0,s1,a0
    80000d64:	00153513          	seqz	a0,a0
}
    80000d68:	60e2                	ld	ra,24(sp)
    80000d6a:	6442                	ld	s0,16(sp)
    80000d6c:	64a2                	ld	s1,8(sp)
    80000d6e:	6105                	addi	sp,sp,32
    80000d70:	8082                	ret

0000000080000d72 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d72:	1101                	addi	sp,sp,-32
    80000d74:	ec06                	sd	ra,24(sp)
    80000d76:	e822                	sd	s0,16(sp)
    80000d78:	e426                	sd	s1,8(sp)
    80000d7a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d7c:	100024f3          	csrr	s1,sstatus
    80000d80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d84:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d86:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d8a:	00001097          	auipc	ra,0x1
    80000d8e:	e28080e7          	jalr	-472(ra) # 80001bb2 <mycpu>
    80000d92:	5d3c                	lw	a5,120(a0)
    80000d94:	cf89                	beqz	a5,80000dae <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d96:	00001097          	auipc	ra,0x1
    80000d9a:	e1c080e7          	jalr	-484(ra) # 80001bb2 <mycpu>
    80000d9e:	5d3c                	lw	a5,120(a0)
    80000da0:	2785                	addiw	a5,a5,1
    80000da2:	dd3c                	sw	a5,120(a0)
}
    80000da4:	60e2                	ld	ra,24(sp)
    80000da6:	6442                	ld	s0,16(sp)
    80000da8:	64a2                	ld	s1,8(sp)
    80000daa:	6105                	addi	sp,sp,32
    80000dac:	8082                	ret
    mycpu()->intena = old;
    80000dae:	00001097          	auipc	ra,0x1
    80000db2:	e04080e7          	jalr	-508(ra) # 80001bb2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000db6:	8085                	srli	s1,s1,0x1
    80000db8:	8885                	andi	s1,s1,1
    80000dba:	dd64                	sw	s1,124(a0)
    80000dbc:	bfe9                	j	80000d96 <push_off+0x24>

0000000080000dbe <acquire>:
{
    80000dbe:	1101                	addi	sp,sp,-32
    80000dc0:	ec06                	sd	ra,24(sp)
    80000dc2:	e822                	sd	s0,16(sp)
    80000dc4:	e426                	sd	s1,8(sp)
    80000dc6:	1000                	addi	s0,sp,32
    80000dc8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000dca:	00000097          	auipc	ra,0x0
    80000dce:	fa8080e7          	jalr	-88(ra) # 80000d72 <push_off>
  if(holding(lk))
    80000dd2:	8526                	mv	a0,s1
    80000dd4:	00000097          	auipc	ra,0x0
    80000dd8:	f70080e7          	jalr	-144(ra) # 80000d44 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ddc:	4705                	li	a4,1
  if(holding(lk))
    80000dde:	e115                	bnez	a0,80000e02 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000de0:	87ba                	mv	a5,a4
    80000de2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000de6:	2781                	sext.w	a5,a5
    80000de8:	ffe5                	bnez	a5,80000de0 <acquire+0x22>
  __sync_synchronize();
    80000dea:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dee:	00001097          	auipc	ra,0x1
    80000df2:	dc4080e7          	jalr	-572(ra) # 80001bb2 <mycpu>
    80000df6:	e888                	sd	a0,16(s1)
}
    80000df8:	60e2                	ld	ra,24(sp)
    80000dfa:	6442                	ld	s0,16(sp)
    80000dfc:	64a2                	ld	s1,8(sp)
    80000dfe:	6105                	addi	sp,sp,32
    80000e00:	8082                	ret
    panic("acquire");
    80000e02:	00007517          	auipc	a0,0x7
    80000e06:	2ce50513          	addi	a0,a0,718 # 800080d0 <digits+0x90>
    80000e0a:	fffff097          	auipc	ra,0xfffff
    80000e0e:	734080e7          	jalr	1844(ra) # 8000053e <panic>

0000000080000e12 <pop_off>:

void
pop_off(void)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e406                	sd	ra,8(sp)
    80000e16:	e022                	sd	s0,0(sp)
    80000e18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000e1a:	00001097          	auipc	ra,0x1
    80000e1e:	d98080e7          	jalr	-616(ra) # 80001bb2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e26:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e28:	e78d                	bnez	a5,80000e52 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e2a:	5d3c                	lw	a5,120(a0)
    80000e2c:	02f05b63          	blez	a5,80000e62 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e30:	37fd                	addiw	a5,a5,-1
    80000e32:	0007871b          	sext.w	a4,a5
    80000e36:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e38:	eb09                	bnez	a4,80000e4a <pop_off+0x38>
    80000e3a:	5d7c                	lw	a5,124(a0)
    80000e3c:	c799                	beqz	a5,80000e4a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e46:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e4a:	60a2                	ld	ra,8(sp)
    80000e4c:	6402                	ld	s0,0(sp)
    80000e4e:	0141                	addi	sp,sp,16
    80000e50:	8082                	ret
    panic("pop_off - interruptible");
    80000e52:	00007517          	auipc	a0,0x7
    80000e56:	28650513          	addi	a0,a0,646 # 800080d8 <digits+0x98>
    80000e5a:	fffff097          	auipc	ra,0xfffff
    80000e5e:	6e4080e7          	jalr	1764(ra) # 8000053e <panic>
    panic("pop_off");
    80000e62:	00007517          	auipc	a0,0x7
    80000e66:	28e50513          	addi	a0,a0,654 # 800080f0 <digits+0xb0>
    80000e6a:	fffff097          	auipc	ra,0xfffff
    80000e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>

0000000080000e72 <release>:
{
    80000e72:	1101                	addi	sp,sp,-32
    80000e74:	ec06                	sd	ra,24(sp)
    80000e76:	e822                	sd	s0,16(sp)
    80000e78:	e426                	sd	s1,8(sp)
    80000e7a:	1000                	addi	s0,sp,32
    80000e7c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e7e:	00000097          	auipc	ra,0x0
    80000e82:	ec6080e7          	jalr	-314(ra) # 80000d44 <holding>
    80000e86:	c115                	beqz	a0,80000eaa <release+0x38>
  lk->cpu = 0;
    80000e88:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e8c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e90:	0f50000f          	fence	iorw,ow
    80000e94:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e98:	00000097          	auipc	ra,0x0
    80000e9c:	f7a080e7          	jalr	-134(ra) # 80000e12 <pop_off>
}
    80000ea0:	60e2                	ld	ra,24(sp)
    80000ea2:	6442                	ld	s0,16(sp)
    80000ea4:	64a2                	ld	s1,8(sp)
    80000ea6:	6105                	addi	sp,sp,32
    80000ea8:	8082                	ret
    panic("release");
    80000eaa:	00007517          	auipc	a0,0x7
    80000eae:	24e50513          	addi	a0,a0,590 # 800080f8 <digits+0xb8>
    80000eb2:	fffff097          	auipc	ra,0xfffff
    80000eb6:	68c080e7          	jalr	1676(ra) # 8000053e <panic>

0000000080000eba <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000eba:	1141                	addi	sp,sp,-16
    80000ebc:	e422                	sd	s0,8(sp)
    80000ebe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ec0:	ce09                	beqz	a2,80000eda <memset+0x20>
    80000ec2:	87aa                	mv	a5,a0
    80000ec4:	fff6071b          	addiw	a4,a2,-1
    80000ec8:	1702                	slli	a4,a4,0x20
    80000eca:	9301                	srli	a4,a4,0x20
    80000ecc:	0705                	addi	a4,a4,1
    80000ece:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ed0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ed4:	0785                	addi	a5,a5,1
    80000ed6:	fee79de3          	bne	a5,a4,80000ed0 <memset+0x16>
  }
  return dst;
}
    80000eda:	6422                	ld	s0,8(sp)
    80000edc:	0141                	addi	sp,sp,16
    80000ede:	8082                	ret

0000000080000ee0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ee0:	1141                	addi	sp,sp,-16
    80000ee2:	e422                	sd	s0,8(sp)
    80000ee4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ee6:	ca05                	beqz	a2,80000f16 <memcmp+0x36>
    80000ee8:	fff6069b          	addiw	a3,a2,-1
    80000eec:	1682                	slli	a3,a3,0x20
    80000eee:	9281                	srli	a3,a3,0x20
    80000ef0:	0685                	addi	a3,a3,1
    80000ef2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ef4:	00054783          	lbu	a5,0(a0)
    80000ef8:	0005c703          	lbu	a4,0(a1)
    80000efc:	00e79863          	bne	a5,a4,80000f0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000f00:	0505                	addi	a0,a0,1
    80000f02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000f04:	fed518e3          	bne	a0,a3,80000ef4 <memcmp+0x14>
  }

  return 0;
    80000f08:	4501                	li	a0,0
    80000f0a:	a019                	j	80000f10 <memcmp+0x30>
      return *s1 - *s2;
    80000f0c:	40e7853b          	subw	a0,a5,a4
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret
  return 0;
    80000f16:	4501                	li	a0,0
    80000f18:	bfe5                	j	80000f10 <memcmp+0x30>

0000000080000f1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e422                	sd	s0,8(sp)
    80000f1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000f20:	ca0d                	beqz	a2,80000f52 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f22:	00a5f963          	bgeu	a1,a0,80000f34 <memmove+0x1a>
    80000f26:	02061693          	slli	a3,a2,0x20
    80000f2a:	9281                	srli	a3,a3,0x20
    80000f2c:	00d58733          	add	a4,a1,a3
    80000f30:	02e56463          	bltu	a0,a4,80000f58 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f34:	fff6079b          	addiw	a5,a2,-1
    80000f38:	1782                	slli	a5,a5,0x20
    80000f3a:	9381                	srli	a5,a5,0x20
    80000f3c:	0785                	addi	a5,a5,1
    80000f3e:	97ae                	add	a5,a5,a1
    80000f40:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f42:	0585                	addi	a1,a1,1
    80000f44:	0705                	addi	a4,a4,1
    80000f46:	fff5c683          	lbu	a3,-1(a1)
    80000f4a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f4e:	fef59ae3          	bne	a1,a5,80000f42 <memmove+0x28>

  return dst;
}
    80000f52:	6422                	ld	s0,8(sp)
    80000f54:	0141                	addi	sp,sp,16
    80000f56:	8082                	ret
    d += n;
    80000f58:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f5a:	fff6079b          	addiw	a5,a2,-1
    80000f5e:	1782                	slli	a5,a5,0x20
    80000f60:	9381                	srli	a5,a5,0x20
    80000f62:	fff7c793          	not	a5,a5
    80000f66:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f68:	177d                	addi	a4,a4,-1
    80000f6a:	16fd                	addi	a3,a3,-1
    80000f6c:	00074603          	lbu	a2,0(a4)
    80000f70:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f74:	fef71ae3          	bne	a4,a5,80000f68 <memmove+0x4e>
    80000f78:	bfe9                	j	80000f52 <memmove+0x38>

0000000080000f7a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f7a:	1141                	addi	sp,sp,-16
    80000f7c:	e406                	sd	ra,8(sp)
    80000f7e:	e022                	sd	s0,0(sp)
    80000f80:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	f98080e7          	jalr	-104(ra) # 80000f1a <memmove>
}
    80000f8a:	60a2                	ld	ra,8(sp)
    80000f8c:	6402                	ld	s0,0(sp)
    80000f8e:	0141                	addi	sp,sp,16
    80000f90:	8082                	ret

0000000080000f92 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f92:	1141                	addi	sp,sp,-16
    80000f94:	e422                	sd	s0,8(sp)
    80000f96:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f98:	ce11                	beqz	a2,80000fb4 <strncmp+0x22>
    80000f9a:	00054783          	lbu	a5,0(a0)
    80000f9e:	cf89                	beqz	a5,80000fb8 <strncmp+0x26>
    80000fa0:	0005c703          	lbu	a4,0(a1)
    80000fa4:	00f71a63          	bne	a4,a5,80000fb8 <strncmp+0x26>
    n--, p++, q++;
    80000fa8:	367d                	addiw	a2,a2,-1
    80000faa:	0505                	addi	a0,a0,1
    80000fac:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000fae:	f675                	bnez	a2,80000f9a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000fb0:	4501                	li	a0,0
    80000fb2:	a809                	j	80000fc4 <strncmp+0x32>
    80000fb4:	4501                	li	a0,0
    80000fb6:	a039                	j	80000fc4 <strncmp+0x32>
  if(n == 0)
    80000fb8:	ca09                	beqz	a2,80000fca <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000fba:	00054503          	lbu	a0,0(a0)
    80000fbe:	0005c783          	lbu	a5,0(a1)
    80000fc2:	9d1d                	subw	a0,a0,a5
}
    80000fc4:	6422                	ld	s0,8(sp)
    80000fc6:	0141                	addi	sp,sp,16
    80000fc8:	8082                	ret
    return 0;
    80000fca:	4501                	li	a0,0
    80000fcc:	bfe5                	j	80000fc4 <strncmp+0x32>

0000000080000fce <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fce:	1141                	addi	sp,sp,-16
    80000fd0:	e422                	sd	s0,8(sp)
    80000fd2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fd4:	872a                	mv	a4,a0
    80000fd6:	8832                	mv	a6,a2
    80000fd8:	367d                	addiw	a2,a2,-1
    80000fda:	01005963          	blez	a6,80000fec <strncpy+0x1e>
    80000fde:	0705                	addi	a4,a4,1
    80000fe0:	0005c783          	lbu	a5,0(a1)
    80000fe4:	fef70fa3          	sb	a5,-1(a4)
    80000fe8:	0585                	addi	a1,a1,1
    80000fea:	f7f5                	bnez	a5,80000fd6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fec:	00c05d63          	blez	a2,80001006 <strncpy+0x38>
    80000ff0:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ff2:	0685                	addi	a3,a3,1
    80000ff4:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ff8:	fff6c793          	not	a5,a3
    80000ffc:	9fb9                	addw	a5,a5,a4
    80000ffe:	010787bb          	addw	a5,a5,a6
    80001002:	fef048e3          	bgtz	a5,80000ff2 <strncpy+0x24>
  return os;
}
    80001006:	6422                	ld	s0,8(sp)
    80001008:	0141                	addi	sp,sp,16
    8000100a:	8082                	ret

000000008000100c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000100c:	1141                	addi	sp,sp,-16
    8000100e:	e422                	sd	s0,8(sp)
    80001010:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001012:	02c05363          	blez	a2,80001038 <safestrcpy+0x2c>
    80001016:	fff6069b          	addiw	a3,a2,-1
    8000101a:	1682                	slli	a3,a3,0x20
    8000101c:	9281                	srli	a3,a3,0x20
    8000101e:	96ae                	add	a3,a3,a1
    80001020:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001022:	00d58963          	beq	a1,a3,80001034 <safestrcpy+0x28>
    80001026:	0585                	addi	a1,a1,1
    80001028:	0785                	addi	a5,a5,1
    8000102a:	fff5c703          	lbu	a4,-1(a1)
    8000102e:	fee78fa3          	sb	a4,-1(a5)
    80001032:	fb65                	bnez	a4,80001022 <safestrcpy+0x16>
    ;
  *s = 0;
    80001034:	00078023          	sb	zero,0(a5)
  return os;
}
    80001038:	6422                	ld	s0,8(sp)
    8000103a:	0141                	addi	sp,sp,16
    8000103c:	8082                	ret

000000008000103e <strlen>:

int
strlen(const char *s)
{
    8000103e:	1141                	addi	sp,sp,-16
    80001040:	e422                	sd	s0,8(sp)
    80001042:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001044:	00054783          	lbu	a5,0(a0)
    80001048:	cf91                	beqz	a5,80001064 <strlen+0x26>
    8000104a:	0505                	addi	a0,a0,1
    8000104c:	87aa                	mv	a5,a0
    8000104e:	4685                	li	a3,1
    80001050:	9e89                	subw	a3,a3,a0
    80001052:	00f6853b          	addw	a0,a3,a5
    80001056:	0785                	addi	a5,a5,1
    80001058:	fff7c703          	lbu	a4,-1(a5)
    8000105c:	fb7d                	bnez	a4,80001052 <strlen+0x14>
    ;
  return n;
}
    8000105e:	6422                	ld	s0,8(sp)
    80001060:	0141                	addi	sp,sp,16
    80001062:	8082                	ret
  for(n = 0; s[n]; n++)
    80001064:	4501                	li	a0,0
    80001066:	bfe5                	j	8000105e <strlen+0x20>

0000000080001068 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001070:	00001097          	auipc	ra,0x1
    80001074:	b32080e7          	jalr	-1230(ra) # 80001ba2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001078:	00008717          	auipc	a4,0x8
    8000107c:	fa070713          	addi	a4,a4,-96 # 80009018 <started>
  if(cpuid() == 0){
    80001080:	c139                	beqz	a0,800010c6 <main+0x5e>
    while(started == 0)
    80001082:	431c                	lw	a5,0(a4)
    80001084:	2781                	sext.w	a5,a5
    80001086:	dff5                	beqz	a5,80001082 <main+0x1a>
      ;
    __sync_synchronize();
    80001088:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000108c:	00001097          	auipc	ra,0x1
    80001090:	b16080e7          	jalr	-1258(ra) # 80001ba2 <cpuid>
    80001094:	85aa                	mv	a1,a0
    80001096:	00007517          	auipc	a0,0x7
    8000109a:	08250513          	addi	a0,a0,130 # 80008118 <digits+0xd8>
    8000109e:	fffff097          	auipc	ra,0xfffff
    800010a2:	4ea080e7          	jalr	1258(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	0d8080e7          	jalr	216(ra) # 8000117e <kvminithart>
    trapinithart();   // install kernel trap vector
    800010ae:	00002097          	auipc	ra,0x2
    800010b2:	af2080e7          	jalr	-1294(ra) # 80002ba0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800010b6:	00005097          	auipc	ra,0x5
    800010ba:	3aa080e7          	jalr	938(ra) # 80006460 <plicinithart>
  }

  scheduler();        
    800010be:	00001097          	auipc	ra,0x1
    800010c2:	116080e7          	jalr	278(ra) # 800021d4 <scheduler>
    consoleinit();
    800010c6:	fffff097          	auipc	ra,0xfffff
    800010ca:	38a080e7          	jalr	906(ra) # 80000450 <consoleinit>
    printfinit();
    800010ce:	fffff097          	auipc	ra,0xfffff
    800010d2:	6a0080e7          	jalr	1696(ra) # 8000076e <printfinit>
    printf("\n");
    800010d6:	00007517          	auipc	a0,0x7
    800010da:	05250513          	addi	a0,a0,82 # 80008128 <digits+0xe8>
    800010de:	fffff097          	auipc	ra,0xfffff
    800010e2:	4aa080e7          	jalr	1194(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	01a50513          	addi	a0,a0,26 # 80008100 <digits+0xc0>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	49a080e7          	jalr	1178(ra) # 80000588 <printf>
    printf("\n");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	03250513          	addi	a0,a0,50 # 80008128 <digits+0xe8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	48a080e7          	jalr	1162(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001106:	00000097          	auipc	ra,0x0
    8000110a:	ae4080e7          	jalr	-1308(ra) # 80000bea <kinit>
    kvminit();       // create kernel page table
    8000110e:	00000097          	auipc	ra,0x0
    80001112:	322080e7          	jalr	802(ra) # 80001430 <kvminit>
    kvminithart();   // turn on paging
    80001116:	00000097          	auipc	ra,0x0
    8000111a:	068080e7          	jalr	104(ra) # 8000117e <kvminithart>
    procinit();      // process table
    8000111e:	00001097          	auipc	ra,0x1
    80001122:	9d0080e7          	jalr	-1584(ra) # 80001aee <procinit>
    trapinit();      // trap vectors
    80001126:	00002097          	auipc	ra,0x2
    8000112a:	a52080e7          	jalr	-1454(ra) # 80002b78 <trapinit>
    trapinithart();  // install kernel trap vector
    8000112e:	00002097          	auipc	ra,0x2
    80001132:	a72080e7          	jalr	-1422(ra) # 80002ba0 <trapinithart>
    plicinit();      // set up interrupt controller
    80001136:	00005097          	auipc	ra,0x5
    8000113a:	314080e7          	jalr	788(ra) # 8000644a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000113e:	00005097          	auipc	ra,0x5
    80001142:	322080e7          	jalr	802(ra) # 80006460 <plicinithart>
    binit();         // buffer cache
    80001146:	00002097          	auipc	ra,0x2
    8000114a:	500080e7          	jalr	1280(ra) # 80003646 <binit>
    iinit();         // inode table
    8000114e:	00003097          	auipc	ra,0x3
    80001152:	b90080e7          	jalr	-1136(ra) # 80003cde <iinit>
    fileinit();      // file table
    80001156:	00004097          	auipc	ra,0x4
    8000115a:	b3a080e7          	jalr	-1222(ra) # 80004c90 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000115e:	00005097          	auipc	ra,0x5
    80001162:	424080e7          	jalr	1060(ra) # 80006582 <virtio_disk_init>
    userinit();      // first user process
    80001166:	00001097          	auipc	ra,0x1
    8000116a:	dae080e7          	jalr	-594(ra) # 80001f14 <userinit>
    __sync_synchronize();
    8000116e:	0ff0000f          	fence
    started = 1;
    80001172:	4785                	li	a5,1
    80001174:	00008717          	auipc	a4,0x8
    80001178:	eaf72223          	sw	a5,-348(a4) # 80009018 <started>
    8000117c:	b789                	j	800010be <main+0x56>

000000008000117e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000117e:	1141                	addi	sp,sp,-16
    80001180:	e422                	sd	s0,8(sp)
    80001182:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001184:	00008797          	auipc	a5,0x8
    80001188:	e9c7b783          	ld	a5,-356(a5) # 80009020 <kernel_pagetable>
    8000118c:	83b1                	srli	a5,a5,0xc
    8000118e:	577d                	li	a4,-1
    80001190:	177e                	slli	a4,a4,0x3f
    80001192:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001194:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001198:	12000073          	sfence.vma
  sfence_vma();
}
    8000119c:	6422                	ld	s0,8(sp)
    8000119e:	0141                	addi	sp,sp,16
    800011a0:	8082                	ret

00000000800011a2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800011a2:	7139                	addi	sp,sp,-64
    800011a4:	fc06                	sd	ra,56(sp)
    800011a6:	f822                	sd	s0,48(sp)
    800011a8:	f426                	sd	s1,40(sp)
    800011aa:	f04a                	sd	s2,32(sp)
    800011ac:	ec4e                	sd	s3,24(sp)
    800011ae:	e852                	sd	s4,16(sp)
    800011b0:	e456                	sd	s5,8(sp)
    800011b2:	e05a                	sd	s6,0(sp)
    800011b4:	0080                	addi	s0,sp,64
    800011b6:	84aa                	mv	s1,a0
    800011b8:	89ae                	mv	s3,a1
    800011ba:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800011bc:	57fd                	li	a5,-1
    800011be:	83e9                	srli	a5,a5,0x1a
    800011c0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011c2:	4b31                	li	s6,12
  if(va >= MAXVA)
    800011c4:	04b7f263          	bgeu	a5,a1,80001208 <walk+0x66>
    panic("walk");
    800011c8:	00007517          	auipc	a0,0x7
    800011cc:	f6850513          	addi	a0,a0,-152 # 80008130 <digits+0xf0>
    800011d0:	fffff097          	auipc	ra,0xfffff
    800011d4:	36e080e7          	jalr	878(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011d8:	060a8663          	beqz	s5,80001244 <walk+0xa2>
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	a9c080e7          	jalr	-1380(ra) # 80000c78 <kalloc>
    800011e4:	84aa                	mv	s1,a0
    800011e6:	c529                	beqz	a0,80001230 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011e8:	6605                	lui	a2,0x1
    800011ea:	4581                	li	a1,0
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	cce080e7          	jalr	-818(ra) # 80000eba <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011f4:	00c4d793          	srli	a5,s1,0xc
    800011f8:	07aa                	slli	a5,a5,0xa
    800011fa:	0017e793          	ori	a5,a5,1
    800011fe:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001202:	3a5d                	addiw	s4,s4,-9
    80001204:	036a0063          	beq	s4,s6,80001224 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001208:	0149d933          	srl	s2,s3,s4
    8000120c:	1ff97913          	andi	s2,s2,511
    80001210:	090e                	slli	s2,s2,0x3
    80001212:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001214:	00093483          	ld	s1,0(s2)
    80001218:	0014f793          	andi	a5,s1,1
    8000121c:	dfd5                	beqz	a5,800011d8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000121e:	80a9                	srli	s1,s1,0xa
    80001220:	04b2                	slli	s1,s1,0xc
    80001222:	b7c5                	j	80001202 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001224:	00c9d513          	srli	a0,s3,0xc
    80001228:	1ff57513          	andi	a0,a0,511
    8000122c:	050e                	slli	a0,a0,0x3
    8000122e:	9526                	add	a0,a0,s1
}
    80001230:	70e2                	ld	ra,56(sp)
    80001232:	7442                	ld	s0,48(sp)
    80001234:	74a2                	ld	s1,40(sp)
    80001236:	7902                	ld	s2,32(sp)
    80001238:	69e2                	ld	s3,24(sp)
    8000123a:	6a42                	ld	s4,16(sp)
    8000123c:	6aa2                	ld	s5,8(sp)
    8000123e:	6b02                	ld	s6,0(sp)
    80001240:	6121                	addi	sp,sp,64
    80001242:	8082                	ret
        return 0;
    80001244:	4501                	li	a0,0
    80001246:	b7ed                	j	80001230 <walk+0x8e>

0000000080001248 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001248:	57fd                	li	a5,-1
    8000124a:	83e9                	srli	a5,a5,0x1a
    8000124c:	00b7f463          	bgeu	a5,a1,80001254 <walkaddr+0xc>
    return 0;
    80001250:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001252:	8082                	ret
{
    80001254:	1141                	addi	sp,sp,-16
    80001256:	e406                	sd	ra,8(sp)
    80001258:	e022                	sd	s0,0(sp)
    8000125a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000125c:	4601                	li	a2,0
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f44080e7          	jalr	-188(ra) # 800011a2 <walk>
  if(pte == 0)
    80001266:	c105                	beqz	a0,80001286 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001268:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000126a:	0117f693          	andi	a3,a5,17
    8000126e:	4745                	li	a4,17
    return 0;
    80001270:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001272:	00e68663          	beq	a3,a4,8000127e <walkaddr+0x36>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret
  pa = PTE2PA(*pte);
    8000127e:	00a7d513          	srli	a0,a5,0xa
    80001282:	0532                	slli	a0,a0,0xc
  return pa;
    80001284:	bfcd                	j	80001276 <walkaddr+0x2e>
    return 0;
    80001286:	4501                	li	a0,0
    80001288:	b7fd                	j	80001276 <walkaddr+0x2e>

000000008000128a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000128a:	715d                	addi	sp,sp,-80
    8000128c:	e486                	sd	ra,72(sp)
    8000128e:	e0a2                	sd	s0,64(sp)
    80001290:	fc26                	sd	s1,56(sp)
    80001292:	f84a                	sd	s2,48(sp)
    80001294:	f44e                	sd	s3,40(sp)
    80001296:	f052                	sd	s4,32(sp)
    80001298:	ec56                	sd	s5,24(sp)
    8000129a:	e85a                	sd	s6,16(sp)
    8000129c:	e45e                	sd	s7,8(sp)
    8000129e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800012a0:	c205                	beqz	a2,800012c0 <mappages+0x36>
    800012a2:	8aaa                	mv	s5,a0
    800012a4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800012a6:	77fd                	lui	a5,0xfffff
    800012a8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800012ac:	15fd                	addi	a1,a1,-1
    800012ae:	00c589b3          	add	s3,a1,a2
    800012b2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800012b6:	8952                	mv	s2,s4
    800012b8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012bc:	6b85                	lui	s7,0x1
    800012be:	a015                	j	800012e2 <mappages+0x58>
    panic("mappages: size");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e7850513          	addi	a0,a0,-392 # 80008138 <digits+0xf8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	276080e7          	jalr	630(ra) # 8000053e <panic>
      panic("mappages: remap");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7850513          	addi	a0,a0,-392 # 80008148 <digits+0x108>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	266080e7          	jalr	614(ra) # 8000053e <panic>
    a += PGSIZE;
    800012e0:	995e                	add	s2,s2,s7
  for(;;){
    800012e2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012e6:	4605                	li	a2,1
    800012e8:	85ca                	mv	a1,s2
    800012ea:	8556                	mv	a0,s5
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	eb6080e7          	jalr	-330(ra) # 800011a2 <walk>
    800012f4:	cd19                	beqz	a0,80001312 <mappages+0x88>
    if(*pte & PTE_V)
    800012f6:	611c                	ld	a5,0(a0)
    800012f8:	8b85                	andi	a5,a5,1
    800012fa:	fbf9                	bnez	a5,800012d0 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012fc:	80b1                	srli	s1,s1,0xc
    800012fe:	04aa                	slli	s1,s1,0xa
    80001300:	0164e4b3          	or	s1,s1,s6
    80001304:	0014e493          	ori	s1,s1,1
    80001308:	e104                	sd	s1,0(a0)
    if(a == last)
    8000130a:	fd391be3          	bne	s2,s3,800012e0 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000130e:	4501                	li	a0,0
    80001310:	a011                	j	80001314 <mappages+0x8a>
      return -1;
    80001312:	557d                	li	a0,-1
}
    80001314:	60a6                	ld	ra,72(sp)
    80001316:	6406                	ld	s0,64(sp)
    80001318:	74e2                	ld	s1,56(sp)
    8000131a:	7942                	ld	s2,48(sp)
    8000131c:	79a2                	ld	s3,40(sp)
    8000131e:	7a02                	ld	s4,32(sp)
    80001320:	6ae2                	ld	s5,24(sp)
    80001322:	6b42                	ld	s6,16(sp)
    80001324:	6ba2                	ld	s7,8(sp)
    80001326:	6161                	addi	sp,sp,80
    80001328:	8082                	ret

000000008000132a <kvmmap>:
{
    8000132a:	1141                	addi	sp,sp,-16
    8000132c:	e406                	sd	ra,8(sp)
    8000132e:	e022                	sd	s0,0(sp)
    80001330:	0800                	addi	s0,sp,16
    80001332:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001334:	86b2                	mv	a3,a2
    80001336:	863e                	mv	a2,a5
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	f52080e7          	jalr	-174(ra) # 8000128a <mappages>
    80001340:	e509                	bnez	a0,8000134a <kvmmap+0x20>
}
    80001342:	60a2                	ld	ra,8(sp)
    80001344:	6402                	ld	s0,0(sp)
    80001346:	0141                	addi	sp,sp,16
    80001348:	8082                	ret
    panic("kvmmap");
    8000134a:	00007517          	auipc	a0,0x7
    8000134e:	e0e50513          	addi	a0,a0,-498 # 80008158 <digits+0x118>
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	1ec080e7          	jalr	492(ra) # 8000053e <panic>

000000008000135a <kvmmake>:
{
    8000135a:	1101                	addi	sp,sp,-32
    8000135c:	ec06                	sd	ra,24(sp)
    8000135e:	e822                	sd	s0,16(sp)
    80001360:	e426                	sd	s1,8(sp)
    80001362:	e04a                	sd	s2,0(sp)
    80001364:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	912080e7          	jalr	-1774(ra) # 80000c78 <kalloc>
    8000136e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001370:	6605                	lui	a2,0x1
    80001372:	4581                	li	a1,0
    80001374:	00000097          	auipc	ra,0x0
    80001378:	b46080e7          	jalr	-1210(ra) # 80000eba <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000137c:	4719                	li	a4,6
    8000137e:	6685                	lui	a3,0x1
    80001380:	10000637          	lui	a2,0x10000
    80001384:	100005b7          	lui	a1,0x10000
    80001388:	8526                	mv	a0,s1
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	fa0080e7          	jalr	-96(ra) # 8000132a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001392:	4719                	li	a4,6
    80001394:	6685                	lui	a3,0x1
    80001396:	10001637          	lui	a2,0x10001
    8000139a:	100015b7          	lui	a1,0x10001
    8000139e:	8526                	mv	a0,s1
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	f8a080e7          	jalr	-118(ra) # 8000132a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013a8:	4719                	li	a4,6
    800013aa:	004006b7          	lui	a3,0x400
    800013ae:	0c000637          	lui	a2,0xc000
    800013b2:	0c0005b7          	lui	a1,0xc000
    800013b6:	8526                	mv	a0,s1
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	f72080e7          	jalr	-142(ra) # 8000132a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013c0:	00007917          	auipc	s2,0x7
    800013c4:	c4090913          	addi	s2,s2,-960 # 80008000 <etext>
    800013c8:	4729                	li	a4,10
    800013ca:	80007697          	auipc	a3,0x80007
    800013ce:	c3668693          	addi	a3,a3,-970 # 8000 <_entry-0x7fff8000>
    800013d2:	4605                	li	a2,1
    800013d4:	067e                	slli	a2,a2,0x1f
    800013d6:	85b2                	mv	a1,a2
    800013d8:	8526                	mv	a0,s1
    800013da:	00000097          	auipc	ra,0x0
    800013de:	f50080e7          	jalr	-176(ra) # 8000132a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013e2:	4719                	li	a4,6
    800013e4:	46c5                	li	a3,17
    800013e6:	06ee                	slli	a3,a3,0x1b
    800013e8:	412686b3          	sub	a3,a3,s2
    800013ec:	864a                	mv	a2,s2
    800013ee:	85ca                	mv	a1,s2
    800013f0:	8526                	mv	a0,s1
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	f38080e7          	jalr	-200(ra) # 8000132a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013fa:	4729                	li	a4,10
    800013fc:	6685                	lui	a3,0x1
    800013fe:	00006617          	auipc	a2,0x6
    80001402:	c0260613          	addi	a2,a2,-1022 # 80007000 <_trampoline>
    80001406:	040005b7          	lui	a1,0x4000
    8000140a:	15fd                	addi	a1,a1,-1
    8000140c:	05b2                	slli	a1,a1,0xc
    8000140e:	8526                	mv	a0,s1
    80001410:	00000097          	auipc	ra,0x0
    80001414:	f1a080e7          	jalr	-230(ra) # 8000132a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001418:	8526                	mv	a0,s1
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	63e080e7          	jalr	1598(ra) # 80001a58 <proc_mapstacks>
}
    80001422:	8526                	mv	a0,s1
    80001424:	60e2                	ld	ra,24(sp)
    80001426:	6442                	ld	s0,16(sp)
    80001428:	64a2                	ld	s1,8(sp)
    8000142a:	6902                	ld	s2,0(sp)
    8000142c:	6105                	addi	sp,sp,32
    8000142e:	8082                	ret

0000000080001430 <kvminit>:
{
    80001430:	1141                	addi	sp,sp,-16
    80001432:	e406                	sd	ra,8(sp)
    80001434:	e022                	sd	s0,0(sp)
    80001436:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	f22080e7          	jalr	-222(ra) # 8000135a <kvmmake>
    80001440:	00008797          	auipc	a5,0x8
    80001444:	bea7b023          	sd	a0,-1056(a5) # 80009020 <kernel_pagetable>
}
    80001448:	60a2                	ld	ra,8(sp)
    8000144a:	6402                	ld	s0,0(sp)
    8000144c:	0141                	addi	sp,sp,16
    8000144e:	8082                	ret

0000000080001450 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001450:	715d                	addi	sp,sp,-80
    80001452:	e486                	sd	ra,72(sp)
    80001454:	e0a2                	sd	s0,64(sp)
    80001456:	fc26                	sd	s1,56(sp)
    80001458:	f84a                	sd	s2,48(sp)
    8000145a:	f44e                	sd	s3,40(sp)
    8000145c:	f052                	sd	s4,32(sp)
    8000145e:	ec56                	sd	s5,24(sp)
    80001460:	e85a                	sd	s6,16(sp)
    80001462:	e45e                	sd	s7,8(sp)
    80001464:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001466:	03459793          	slli	a5,a1,0x34
    8000146a:	e795                	bnez	a5,80001496 <uvmunmap+0x46>
    8000146c:	8a2a                	mv	s4,a0
    8000146e:	892e                	mv	s2,a1
    80001470:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001472:	0632                	slli	a2,a2,0xc
    80001474:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001478:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000147a:	6b05                	lui	s6,0x1
    8000147c:	0735e863          	bltu	a1,s3,800014ec <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001480:	60a6                	ld	ra,72(sp)
    80001482:	6406                	ld	s0,64(sp)
    80001484:	74e2                	ld	s1,56(sp)
    80001486:	7942                	ld	s2,48(sp)
    80001488:	79a2                	ld	s3,40(sp)
    8000148a:	7a02                	ld	s4,32(sp)
    8000148c:	6ae2                	ld	s5,24(sp)
    8000148e:	6b42                	ld	s6,16(sp)
    80001490:	6ba2                	ld	s7,8(sp)
    80001492:	6161                	addi	sp,sp,80
    80001494:	8082                	ret
    panic("uvmunmap: not aligned");
    80001496:	00007517          	auipc	a0,0x7
    8000149a:	cca50513          	addi	a0,a0,-822 # 80008160 <digits+0x120>
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	0a0080e7          	jalr	160(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800014a6:	00007517          	auipc	a0,0x7
    800014aa:	cd250513          	addi	a0,a0,-814 # 80008178 <digits+0x138>
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	090080e7          	jalr	144(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800014b6:	00007517          	auipc	a0,0x7
    800014ba:	cd250513          	addi	a0,a0,-814 # 80008188 <digits+0x148>
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	080080e7          	jalr	128(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800014c6:	00007517          	auipc	a0,0x7
    800014ca:	cda50513          	addi	a0,a0,-806 # 800081a0 <digits+0x160>
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800014d6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014d8:	0532                	slli	a0,a0,0xc
    800014da:	fffff097          	auipc	ra,0xfffff
    800014de:	58a080e7          	jalr	1418(ra) # 80000a64 <kfree>
    *pte = 0;
    800014e2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014e6:	995a                	add	s2,s2,s6
    800014e8:	f9397ce3          	bgeu	s2,s3,80001480 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014ec:	4601                	li	a2,0
    800014ee:	85ca                	mv	a1,s2
    800014f0:	8552                	mv	a0,s4
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	cb0080e7          	jalr	-848(ra) # 800011a2 <walk>
    800014fa:	84aa                	mv	s1,a0
    800014fc:	d54d                	beqz	a0,800014a6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014fe:	6108                	ld	a0,0(a0)
    80001500:	00157793          	andi	a5,a0,1
    80001504:	dbcd                	beqz	a5,800014b6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001506:	3ff57793          	andi	a5,a0,1023
    8000150a:	fb778ee3          	beq	a5,s7,800014c6 <uvmunmap+0x76>
    if(do_free){
    8000150e:	fc0a8ae3          	beqz	s5,800014e2 <uvmunmap+0x92>
    80001512:	b7d1                	j	800014d6 <uvmunmap+0x86>

0000000080001514 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001514:	1101                	addi	sp,sp,-32
    80001516:	ec06                	sd	ra,24(sp)
    80001518:	e822                	sd	s0,16(sp)
    8000151a:	e426                	sd	s1,8(sp)
    8000151c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	75a080e7          	jalr	1882(ra) # 80000c78 <kalloc>
    80001526:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001528:	c519                	beqz	a0,80001536 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000152a:	6605                	lui	a2,0x1
    8000152c:	4581                	li	a1,0
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	98c080e7          	jalr	-1652(ra) # 80000eba <memset>
  return pagetable;
}
    80001536:	8526                	mv	a0,s1
    80001538:	60e2                	ld	ra,24(sp)
    8000153a:	6442                	ld	s0,16(sp)
    8000153c:	64a2                	ld	s1,8(sp)
    8000153e:	6105                	addi	sp,sp,32
    80001540:	8082                	ret

0000000080001542 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001542:	7179                	addi	sp,sp,-48
    80001544:	f406                	sd	ra,40(sp)
    80001546:	f022                	sd	s0,32(sp)
    80001548:	ec26                	sd	s1,24(sp)
    8000154a:	e84a                	sd	s2,16(sp)
    8000154c:	e44e                	sd	s3,8(sp)
    8000154e:	e052                	sd	s4,0(sp)
    80001550:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001552:	6785                	lui	a5,0x1
    80001554:	04f67863          	bgeu	a2,a5,800015a4 <uvminit+0x62>
    80001558:	8a2a                	mv	s4,a0
    8000155a:	89ae                	mv	s3,a1
    8000155c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000155e:	fffff097          	auipc	ra,0xfffff
    80001562:	71a080e7          	jalr	1818(ra) # 80000c78 <kalloc>
    80001566:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001568:	6605                	lui	a2,0x1
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	94e080e7          	jalr	-1714(ra) # 80000eba <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001574:	4779                	li	a4,30
    80001576:	86ca                	mv	a3,s2
    80001578:	6605                	lui	a2,0x1
    8000157a:	4581                	li	a1,0
    8000157c:	8552                	mv	a0,s4
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	d0c080e7          	jalr	-756(ra) # 8000128a <mappages>
  memmove(mem, src, sz);
    80001586:	8626                	mv	a2,s1
    80001588:	85ce                	mv	a1,s3
    8000158a:	854a                	mv	a0,s2
    8000158c:	00000097          	auipc	ra,0x0
    80001590:	98e080e7          	jalr	-1650(ra) # 80000f1a <memmove>
}
    80001594:	70a2                	ld	ra,40(sp)
    80001596:	7402                	ld	s0,32(sp)
    80001598:	64e2                	ld	s1,24(sp)
    8000159a:	6942                	ld	s2,16(sp)
    8000159c:	69a2                	ld	s3,8(sp)
    8000159e:	6a02                	ld	s4,0(sp)
    800015a0:	6145                	addi	sp,sp,48
    800015a2:	8082                	ret
    panic("inituvm: more than a page");
    800015a4:	00007517          	auipc	a0,0x7
    800015a8:	c1450513          	addi	a0,a0,-1004 # 800081b8 <digits+0x178>
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>

00000000800015b4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800015b4:	1101                	addi	sp,sp,-32
    800015b6:	ec06                	sd	ra,24(sp)
    800015b8:	e822                	sd	s0,16(sp)
    800015ba:	e426                	sd	s1,8(sp)
    800015bc:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800015be:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015c0:	00b67d63          	bgeu	a2,a1,800015da <uvmdealloc+0x26>
    800015c4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	17fd                	addi	a5,a5,-1
    800015ca:	00f60733          	add	a4,a2,a5
    800015ce:	767d                	lui	a2,0xfffff
    800015d0:	8f71                	and	a4,a4,a2
    800015d2:	97ae                	add	a5,a5,a1
    800015d4:	8ff1                	and	a5,a5,a2
    800015d6:	00f76863          	bltu	a4,a5,800015e6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015da:	8526                	mv	a0,s1
    800015dc:	60e2                	ld	ra,24(sp)
    800015de:	6442                	ld	s0,16(sp)
    800015e0:	64a2                	ld	s1,8(sp)
    800015e2:	6105                	addi	sp,sp,32
    800015e4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015e6:	8f99                	sub	a5,a5,a4
    800015e8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015ea:	4685                	li	a3,1
    800015ec:	0007861b          	sext.w	a2,a5
    800015f0:	85ba                	mv	a1,a4
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	e5e080e7          	jalr	-418(ra) # 80001450 <uvmunmap>
    800015fa:	b7c5                	j	800015da <uvmdealloc+0x26>

00000000800015fc <uvmalloc>:
  if(newsz < oldsz)
    800015fc:	0ab66163          	bltu	a2,a1,8000169e <uvmalloc+0xa2>
{
    80001600:	7139                	addi	sp,sp,-64
    80001602:	fc06                	sd	ra,56(sp)
    80001604:	f822                	sd	s0,48(sp)
    80001606:	f426                	sd	s1,40(sp)
    80001608:	f04a                	sd	s2,32(sp)
    8000160a:	ec4e                	sd	s3,24(sp)
    8000160c:	e852                	sd	s4,16(sp)
    8000160e:	e456                	sd	s5,8(sp)
    80001610:	0080                	addi	s0,sp,64
    80001612:	8aaa                	mv	s5,a0
    80001614:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001616:	6985                	lui	s3,0x1
    80001618:	19fd                	addi	s3,s3,-1
    8000161a:	95ce                	add	a1,a1,s3
    8000161c:	79fd                	lui	s3,0xfffff
    8000161e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001622:	08c9f063          	bgeu	s3,a2,800016a2 <uvmalloc+0xa6>
    80001626:	894e                	mv	s2,s3
    mem = kalloc();
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	650080e7          	jalr	1616(ra) # 80000c78 <kalloc>
    80001630:	84aa                	mv	s1,a0
    if(mem == 0){
    80001632:	c51d                	beqz	a0,80001660 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001634:	6605                	lui	a2,0x1
    80001636:	4581                	li	a1,0
    80001638:	00000097          	auipc	ra,0x0
    8000163c:	882080e7          	jalr	-1918(ra) # 80000eba <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001640:	4779                	li	a4,30
    80001642:	86a6                	mv	a3,s1
    80001644:	6605                	lui	a2,0x1
    80001646:	85ca                	mv	a1,s2
    80001648:	8556                	mv	a0,s5
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	c40080e7          	jalr	-960(ra) # 8000128a <mappages>
    80001652:	e905                	bnez	a0,80001682 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001654:	6785                	lui	a5,0x1
    80001656:	993e                	add	s2,s2,a5
    80001658:	fd4968e3          	bltu	s2,s4,80001628 <uvmalloc+0x2c>
  return newsz;
    8000165c:	8552                	mv	a0,s4
    8000165e:	a809                	j	80001670 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001660:	864e                	mv	a2,s3
    80001662:	85ca                	mv	a1,s2
    80001664:	8556                	mv	a0,s5
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	f4e080e7          	jalr	-178(ra) # 800015b4 <uvmdealloc>
      return 0;
    8000166e:	4501                	li	a0,0
}
    80001670:	70e2                	ld	ra,56(sp)
    80001672:	7442                	ld	s0,48(sp)
    80001674:	74a2                	ld	s1,40(sp)
    80001676:	7902                	ld	s2,32(sp)
    80001678:	69e2                	ld	s3,24(sp)
    8000167a:	6a42                	ld	s4,16(sp)
    8000167c:	6aa2                	ld	s5,8(sp)
    8000167e:	6121                	addi	sp,sp,64
    80001680:	8082                	ret
      kfree(mem);
    80001682:	8526                	mv	a0,s1
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	3e0080e7          	jalr	992(ra) # 80000a64 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000168c:	864e                	mv	a2,s3
    8000168e:	85ca                	mv	a1,s2
    80001690:	8556                	mv	a0,s5
    80001692:	00000097          	auipc	ra,0x0
    80001696:	f22080e7          	jalr	-222(ra) # 800015b4 <uvmdealloc>
      return 0;
    8000169a:	4501                	li	a0,0
    8000169c:	bfd1                	j	80001670 <uvmalloc+0x74>
    return oldsz;
    8000169e:	852e                	mv	a0,a1
}
    800016a0:	8082                	ret
  return newsz;
    800016a2:	8532                	mv	a0,a2
    800016a4:	b7f1                	j	80001670 <uvmalloc+0x74>

00000000800016a6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800016a6:	7179                	addi	sp,sp,-48
    800016a8:	f406                	sd	ra,40(sp)
    800016aa:	f022                	sd	s0,32(sp)
    800016ac:	ec26                	sd	s1,24(sp)
    800016ae:	e84a                	sd	s2,16(sp)
    800016b0:	e44e                	sd	s3,8(sp)
    800016b2:	e052                	sd	s4,0(sp)
    800016b4:	1800                	addi	s0,sp,48
    800016b6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800016b8:	84aa                	mv	s1,a0
    800016ba:	6905                	lui	s2,0x1
    800016bc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016be:	4985                	li	s3,1
    800016c0:	a821                	j	800016d8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016c2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016c4:	0532                	slli	a0,a0,0xc
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	fe0080e7          	jalr	-32(ra) # 800016a6 <freewalk>
      pagetable[i] = 0;
    800016ce:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016d2:	04a1                	addi	s1,s1,8
    800016d4:	03248163          	beq	s1,s2,800016f6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016d8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016da:	00f57793          	andi	a5,a0,15
    800016de:	ff3782e3          	beq	a5,s3,800016c2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016e2:	8905                	andi	a0,a0,1
    800016e4:	d57d                	beqz	a0,800016d2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	af250513          	addi	a0,a0,-1294 # 800081d8 <digits+0x198>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    800016f6:	8552                	mv	a0,s4
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	36c080e7          	jalr	876(ra) # 80000a64 <kfree>
}
    80001700:	70a2                	ld	ra,40(sp)
    80001702:	7402                	ld	s0,32(sp)
    80001704:	64e2                	ld	s1,24(sp)
    80001706:	6942                	ld	s2,16(sp)
    80001708:	69a2                	ld	s3,8(sp)
    8000170a:	6a02                	ld	s4,0(sp)
    8000170c:	6145                	addi	sp,sp,48
    8000170e:	8082                	ret

0000000080001710 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001710:	1101                	addi	sp,sp,-32
    80001712:	ec06                	sd	ra,24(sp)
    80001714:	e822                	sd	s0,16(sp)
    80001716:	e426                	sd	s1,8(sp)
    80001718:	1000                	addi	s0,sp,32
    8000171a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000171c:	e999                	bnez	a1,80001732 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000171e:	8526                	mv	a0,s1
    80001720:	00000097          	auipc	ra,0x0
    80001724:	f86080e7          	jalr	-122(ra) # 800016a6 <freewalk>
}
    80001728:	60e2                	ld	ra,24(sp)
    8000172a:	6442                	ld	s0,16(sp)
    8000172c:	64a2                	ld	s1,8(sp)
    8000172e:	6105                	addi	sp,sp,32
    80001730:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001732:	6605                	lui	a2,0x1
    80001734:	167d                	addi	a2,a2,-1
    80001736:	962e                	add	a2,a2,a1
    80001738:	4685                	li	a3,1
    8000173a:	8231                	srli	a2,a2,0xc
    8000173c:	4581                	li	a1,0
    8000173e:	00000097          	auipc	ra,0x0
    80001742:	d12080e7          	jalr	-750(ra) # 80001450 <uvmunmap>
    80001746:	bfe1                	j	8000171e <uvmfree+0xe>

0000000080001748 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001748:	715d                	addi	sp,sp,-80
    8000174a:	e486                	sd	ra,72(sp)
    8000174c:	e0a2                	sd	s0,64(sp)
    8000174e:	fc26                	sd	s1,56(sp)
    80001750:	f84a                	sd	s2,48(sp)
    80001752:	f44e                	sd	s3,40(sp)
    80001754:	f052                	sd	s4,32(sp)
    80001756:	ec56                	sd	s5,24(sp)
    80001758:	e85a                	sd	s6,16(sp)
    8000175a:	e45e                	sd	s7,8(sp)
    8000175c:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa = 0, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000175e:	c261                	beqz	a2,8000181e <uvmcopy+0xd6>
    80001760:	8aaa                	mv	s5,a0
    80001762:	8a2e                	mv	s4,a1
    80001764:	89b2                	mv	s3,a2
    80001766:	4481                	li	s1,0
    flags = PTE_FLAGS(*pte);
    pa = PTE2PA(*pte);

    if((flags & PTE_W) != 0){
      flags = (flags &(~PTE_W)) | PTE_C;
      *pte = PA2PTE(pa) | flags;
    80001768:	7b7d                	lui	s6,0xfffff
    8000176a:	002b5b13          	srli	s6,s6,0x2
    8000176e:	a0a1                	j	800017b6 <uvmcopy+0x6e>
      panic("uvmcopy: pte should exist");
    80001770:	00007517          	auipc	a0,0x7
    80001774:	a7850513          	addi	a0,a0,-1416 # 800081e8 <digits+0x1a8>
    80001778:	fffff097          	auipc	ra,0xfffff
    8000177c:	dc6080e7          	jalr	-570(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001780:	00007517          	auipc	a0,0x7
    80001784:	a8850513          	addi	a0,a0,-1400 # 80008208 <digits+0x1c8>
    80001788:	fffff097          	auipc	ra,0xfffff
    8000178c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>
    }
    if(mappages(new,i,PGSIZE,pa,flags))
    80001790:	86ca                	mv	a3,s2
    80001792:	6605                	lui	a2,0x1
    80001794:	85a6                	mv	a1,s1
    80001796:	8552                	mv	a0,s4
    80001798:	00000097          	auipc	ra,0x0
    8000179c:	af2080e7          	jalr	-1294(ra) # 8000128a <mappages>
    800017a0:	8baa                	mv	s7,a0
    800017a2:	e921                	bnez	a0,800017f2 <uvmcopy+0xaa>
    {
      goto err;
    }
    inc_page_ref((void *)pa);
    800017a4:	854a                	mv	a0,s2
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	252080e7          	jalr	594(ra) # 800009f8 <inc_page_ref>
  for(i = 0; i < sz; i += PGSIZE){
    800017ae:	6785                	lui	a5,0x1
    800017b0:	94be                	add	s1,s1,a5
    800017b2:	0534fa63          	bgeu	s1,s3,80001806 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800017b6:	4601                	li	a2,0
    800017b8:	85a6                	mv	a1,s1
    800017ba:	8556                	mv	a0,s5
    800017bc:	00000097          	auipc	ra,0x0
    800017c0:	9e6080e7          	jalr	-1562(ra) # 800011a2 <walk>
    800017c4:	d555                	beqz	a0,80001770 <uvmcopy+0x28>
    if((*pte & PTE_V) == 0)
    800017c6:	611c                	ld	a5,0(a0)
    800017c8:	0017f713          	andi	a4,a5,1
    800017cc:	db55                	beqz	a4,80001780 <uvmcopy+0x38>
    flags = PTE_FLAGS(*pte);
    800017ce:	0007869b          	sext.w	a3,a5
    800017d2:	3ff7f713          	andi	a4,a5,1023
    pa = PTE2PA(*pte);
    800017d6:	00a7d913          	srli	s2,a5,0xa
    800017da:	0932                	slli	s2,s2,0xc
    if((flags & PTE_W) != 0){
    800017dc:	8a91                	andi	a3,a3,4
    800017de:	dacd                	beqz	a3,80001790 <uvmcopy+0x48>
      flags = (flags &(~PTE_W)) | PTE_C;
    800017e0:	fdb77693          	andi	a3,a4,-37
    800017e4:	0206e713          	ori	a4,a3,32
      *pte = PA2PTE(pa) | flags;
    800017e8:	0167f7b3          	and	a5,a5,s6
    800017ec:	8fd9                	or	a5,a5,a4
    800017ee:	e11c                	sd	a5,0(a0)
    800017f0:	b745                	j	80001790 <uvmcopy+0x48>
  }
  
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017f2:	4685                	li	a3,1
    800017f4:	00c4d613          	srli	a2,s1,0xc
    800017f8:	4581                	li	a1,0
    800017fa:	8552                	mv	a0,s4
    800017fc:	00000097          	auipc	ra,0x0
    80001800:	c54080e7          	jalr	-940(ra) # 80001450 <uvmunmap>
  return -1;
    80001804:	5bfd                	li	s7,-1
}
    80001806:	855e                	mv	a0,s7
    80001808:	60a6                	ld	ra,72(sp)
    8000180a:	6406                	ld	s0,64(sp)
    8000180c:	74e2                	ld	s1,56(sp)
    8000180e:	7942                	ld	s2,48(sp)
    80001810:	79a2                	ld	s3,40(sp)
    80001812:	7a02                	ld	s4,32(sp)
    80001814:	6ae2                	ld	s5,24(sp)
    80001816:	6b42                	ld	s6,16(sp)
    80001818:	6ba2                	ld	s7,8(sp)
    8000181a:	6161                	addi	sp,sp,80
    8000181c:	8082                	ret
  return 0;
    8000181e:	4b81                	li	s7,0
    80001820:	b7dd                	j	80001806 <uvmcopy+0xbe>

0000000080001822 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001822:	1141                	addi	sp,sp,-16
    80001824:	e406                	sd	ra,8(sp)
    80001826:	e022                	sd	s0,0(sp)
    80001828:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000182a:	4601                	li	a2,0
    8000182c:	00000097          	auipc	ra,0x0
    80001830:	976080e7          	jalr	-1674(ra) # 800011a2 <walk>
  if(pte == 0)
    80001834:	c901                	beqz	a0,80001844 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001836:	611c                	ld	a5,0(a0)
    80001838:	9bbd                	andi	a5,a5,-17
    8000183a:	e11c                	sd	a5,0(a0)
}
    8000183c:	60a2                	ld	ra,8(sp)
    8000183e:	6402                	ld	s0,0(sp)
    80001840:	0141                	addi	sp,sp,16
    80001842:	8082                	ret
    panic("uvmclear");
    80001844:	00007517          	auipc	a0,0x7
    80001848:	9e450513          	addi	a0,a0,-1564 # 80008228 <digits+0x1e8>
    8000184c:	fffff097          	auipc	ra,0xfffff
    80001850:	cf2080e7          	jalr	-782(ra) # 8000053e <panic>

0000000080001854 <copyout>:
{
  uint64 n, va0, pa0,flags;

  pte_t *pte;

  for(;len > 0;)
    80001854:	c2d5                	beqz	a3,800018f8 <copyout+0xa4>
{
    80001856:	711d                	addi	sp,sp,-96
    80001858:	ec86                	sd	ra,88(sp)
    8000185a:	e8a2                	sd	s0,80(sp)
    8000185c:	e4a6                	sd	s1,72(sp)
    8000185e:	e0ca                	sd	s2,64(sp)
    80001860:	fc4e                	sd	s3,56(sp)
    80001862:	f852                	sd	s4,48(sp)
    80001864:	f456                	sd	s5,40(sp)
    80001866:	f05a                	sd	s6,32(sp)
    80001868:	ec5e                	sd	s7,24(sp)
    8000186a:	e862                	sd	s8,16(sp)
    8000186c:	e466                	sd	s9,8(sp)
    8000186e:	1080                	addi	s0,sp,96
    80001870:	8baa                	mv	s7,a0
    80001872:	89ae                	mv	s3,a1
    80001874:	8b32                	mv	s6,a2
    80001876:	8ab6                	mv	s5,a3
  {
    va0 = PGROUNDDOWN(dstva);
    80001878:	7cfd                	lui	s9,0xfffff
    {
      pagefaulthandler((void*)va0,pagetable);
      pa0 = walkaddr(pagetable,va0);
    }

    n = PGSIZE - (dstva - va0);
    8000187a:	6c05                	lui	s8,0x1
    8000187c:	a081                	j	800018bc <copyout+0x68>
      pagefaulthandler((void*)va0,pagetable);
    8000187e:	85de                	mv	a1,s7
    80001880:	854a                	mv	a0,s2
    80001882:	00001097          	auipc	ra,0x1
    80001886:	238080e7          	jalr	568(ra) # 80002aba <pagefaulthandler>
      pa0 = walkaddr(pagetable,va0);
    8000188a:	85ca                	mv	a1,s2
    8000188c:	855e                	mv	a0,s7
    8000188e:	00000097          	auipc	ra,0x0
    80001892:	9ba080e7          	jalr	-1606(ra) # 80001248 <walkaddr>
    80001896:	8a2a                	mv	s4,a0
    80001898:	a0b9                	j	800018e6 <copyout+0x92>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000189a:	41298533          	sub	a0,s3,s2
    8000189e:	0004861b          	sext.w	a2,s1
    800018a2:	85da                	mv	a1,s6
    800018a4:	9552                	add	a0,a0,s4
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	674080e7          	jalr	1652(ra) # 80000f1a <memmove>

    len -= n;
    800018ae:	409a8ab3          	sub	s5,s5,s1
    src += n;
    800018b2:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    800018b4:	018909b3          	add	s3,s2,s8
  for(;len > 0;)
    800018b8:	020a8e63          	beqz	s5,800018f4 <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    800018bc:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    800018c0:	85ca                	mv	a1,s2
    800018c2:	855e                	mv	a0,s7
    800018c4:	00000097          	auipc	ra,0x0
    800018c8:	984080e7          	jalr	-1660(ra) # 80001248 <walkaddr>
    800018cc:	8a2a                	mv	s4,a0
    if(pa0 == 0)
    800018ce:	c51d                	beqz	a0,800018fc <copyout+0xa8>
    pte = walk(pagetable,va0,0);
    800018d0:	4601                	li	a2,0
    800018d2:	85ca                	mv	a1,s2
    800018d4:	855e                	mv	a0,s7
    800018d6:	00000097          	auipc	ra,0x0
    800018da:	8cc080e7          	jalr	-1844(ra) # 800011a2 <walk>
    if(flags & PTE_C)
    800018de:	611c                	ld	a5,0(a0)
    800018e0:	0207f793          	andi	a5,a5,32
    800018e4:	ffc9                	bnez	a5,8000187e <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    800018e6:	413904b3          	sub	s1,s2,s3
    800018ea:	94e2                	add	s1,s1,s8
    if(n > len)
    800018ec:	fa9af7e3          	bgeu	s5,s1,8000189a <copyout+0x46>
    800018f0:	84d6                	mv	s1,s5
    800018f2:	b765                	j	8000189a <copyout+0x46>
  }
  return 0;
    800018f4:	4501                	li	a0,0
    800018f6:	a021                	j	800018fe <copyout+0xaa>
    800018f8:	4501                	li	a0,0
}
    800018fa:	8082                	ret
      return -1;
    800018fc:	557d                	li	a0,-1
}
    800018fe:	60e6                	ld	ra,88(sp)
    80001900:	6446                	ld	s0,80(sp)
    80001902:	64a6                	ld	s1,72(sp)
    80001904:	6906                	ld	s2,64(sp)
    80001906:	79e2                	ld	s3,56(sp)
    80001908:	7a42                	ld	s4,48(sp)
    8000190a:	7aa2                	ld	s5,40(sp)
    8000190c:	7b02                	ld	s6,32(sp)
    8000190e:	6be2                	ld	s7,24(sp)
    80001910:	6c42                	ld	s8,16(sp)
    80001912:	6ca2                	ld	s9,8(sp)
    80001914:	6125                	addi	sp,sp,96
    80001916:	8082                	ret

0000000080001918 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001918:	c6bd                	beqz	a3,80001986 <copyin+0x6e>
{
    8000191a:	715d                	addi	sp,sp,-80
    8000191c:	e486                	sd	ra,72(sp)
    8000191e:	e0a2                	sd	s0,64(sp)
    80001920:	fc26                	sd	s1,56(sp)
    80001922:	f84a                	sd	s2,48(sp)
    80001924:	f44e                	sd	s3,40(sp)
    80001926:	f052                	sd	s4,32(sp)
    80001928:	ec56                	sd	s5,24(sp)
    8000192a:	e85a                	sd	s6,16(sp)
    8000192c:	e45e                	sd	s7,8(sp)
    8000192e:	e062                	sd	s8,0(sp)
    80001930:	0880                	addi	s0,sp,80
    80001932:	8b2a                	mv	s6,a0
    80001934:	8a2e                	mv	s4,a1
    80001936:	8c32                	mv	s8,a2
    80001938:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000193a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000193c:	6a85                	lui	s5,0x1
    8000193e:	a015                	j	80001962 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001940:	9562                	add	a0,a0,s8
    80001942:	0004861b          	sext.w	a2,s1
    80001946:	412505b3          	sub	a1,a0,s2
    8000194a:	8552                	mv	a0,s4
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	5ce080e7          	jalr	1486(ra) # 80000f1a <memmove>

    len -= n;
    80001954:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001958:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000195a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000195e:	02098263          	beqz	s3,80001982 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001962:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001966:	85ca                	mv	a1,s2
    80001968:	855a                	mv	a0,s6
    8000196a:	00000097          	auipc	ra,0x0
    8000196e:	8de080e7          	jalr	-1826(ra) # 80001248 <walkaddr>
    if(pa0 == 0)
    80001972:	cd01                	beqz	a0,8000198a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001974:	418904b3          	sub	s1,s2,s8
    80001978:	94d6                	add	s1,s1,s5
    if(n > len)
    8000197a:	fc99f3e3          	bgeu	s3,s1,80001940 <copyin+0x28>
    8000197e:	84ce                	mv	s1,s3
    80001980:	b7c1                	j	80001940 <copyin+0x28>
  }
  return 0;
    80001982:	4501                	li	a0,0
    80001984:	a021                	j	8000198c <copyin+0x74>
    80001986:	4501                	li	a0,0
}
    80001988:	8082                	ret
      return -1;
    8000198a:	557d                	li	a0,-1
}
    8000198c:	60a6                	ld	ra,72(sp)
    8000198e:	6406                	ld	s0,64(sp)
    80001990:	74e2                	ld	s1,56(sp)
    80001992:	7942                	ld	s2,48(sp)
    80001994:	79a2                	ld	s3,40(sp)
    80001996:	7a02                	ld	s4,32(sp)
    80001998:	6ae2                	ld	s5,24(sp)
    8000199a:	6b42                	ld	s6,16(sp)
    8000199c:	6ba2                	ld	s7,8(sp)
    8000199e:	6c02                	ld	s8,0(sp)
    800019a0:	6161                	addi	sp,sp,80
    800019a2:	8082                	ret

00000000800019a4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019a4:	c6c5                	beqz	a3,80001a4c <copyinstr+0xa8>
{
    800019a6:	715d                	addi	sp,sp,-80
    800019a8:	e486                	sd	ra,72(sp)
    800019aa:	e0a2                	sd	s0,64(sp)
    800019ac:	fc26                	sd	s1,56(sp)
    800019ae:	f84a                	sd	s2,48(sp)
    800019b0:	f44e                	sd	s3,40(sp)
    800019b2:	f052                	sd	s4,32(sp)
    800019b4:	ec56                	sd	s5,24(sp)
    800019b6:	e85a                	sd	s6,16(sp)
    800019b8:	e45e                	sd	s7,8(sp)
    800019ba:	0880                	addi	s0,sp,80
    800019bc:	8a2a                	mv	s4,a0
    800019be:	8b2e                	mv	s6,a1
    800019c0:	8bb2                	mv	s7,a2
    800019c2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800019c4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019c6:	6985                	lui	s3,0x1
    800019c8:	a035                	j	800019f4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800019ca:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019ce:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019d0:	0017b793          	seqz	a5,a5
    800019d4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019d8:	60a6                	ld	ra,72(sp)
    800019da:	6406                	ld	s0,64(sp)
    800019dc:	74e2                	ld	s1,56(sp)
    800019de:	7942                	ld	s2,48(sp)
    800019e0:	79a2                	ld	s3,40(sp)
    800019e2:	7a02                	ld	s4,32(sp)
    800019e4:	6ae2                	ld	s5,24(sp)
    800019e6:	6b42                	ld	s6,16(sp)
    800019e8:	6ba2                	ld	s7,8(sp)
    800019ea:	6161                	addi	sp,sp,80
    800019ec:	8082                	ret
    srcva = va0 + PGSIZE;
    800019ee:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019f2:	c8a9                	beqz	s1,80001a44 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019f4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019f8:	85ca                	mv	a1,s2
    800019fa:	8552                	mv	a0,s4
    800019fc:	00000097          	auipc	ra,0x0
    80001a00:	84c080e7          	jalr	-1972(ra) # 80001248 <walkaddr>
    if(pa0 == 0)
    80001a04:	c131                	beqz	a0,80001a48 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001a06:	41790833          	sub	a6,s2,s7
    80001a0a:	984e                	add	a6,a6,s3
    if(n > max)
    80001a0c:	0104f363          	bgeu	s1,a6,80001a12 <copyinstr+0x6e>
    80001a10:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a12:	955e                	add	a0,a0,s7
    80001a14:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a18:	fc080be3          	beqz	a6,800019ee <copyinstr+0x4a>
    80001a1c:	985a                	add	a6,a6,s6
    80001a1e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a20:	41650633          	sub	a2,a0,s6
    80001a24:	14fd                	addi	s1,s1,-1
    80001a26:	9b26                	add	s6,s6,s1
    80001a28:	00f60733          	add	a4,a2,a5
    80001a2c:	00074703          	lbu	a4,0(a4)
    80001a30:	df49                	beqz	a4,800019ca <copyinstr+0x26>
        *dst = *p;
    80001a32:	00e78023          	sb	a4,0(a5)
      --max;
    80001a36:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a3a:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a3c:	ff0796e3          	bne	a5,a6,80001a28 <copyinstr+0x84>
      dst++;
    80001a40:	8b42                	mv	s6,a6
    80001a42:	b775                	j	800019ee <copyinstr+0x4a>
    80001a44:	4781                	li	a5,0
    80001a46:	b769                	j	800019d0 <copyinstr+0x2c>
      return -1;
    80001a48:	557d                	li	a0,-1
    80001a4a:	b779                	j	800019d8 <copyinstr+0x34>
  int got_null = 0;
    80001a4c:	4781                	li	a5,0
  if(got_null){
    80001a4e:	0017b793          	seqz	a5,a5
    80001a52:	40f00533          	neg	a0,a5
}
    80001a56:	8082                	ret

0000000080001a58 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a58:	7139                	addi	sp,sp,-64
    80001a5a:	fc06                	sd	ra,56(sp)
    80001a5c:	f822                	sd	s0,48(sp)
    80001a5e:	f426                	sd	s1,40(sp)
    80001a60:	f04a                	sd	s2,32(sp)
    80001a62:	ec4e                	sd	s3,24(sp)
    80001a64:	e852                	sd	s4,16(sp)
    80001a66:	e456                	sd	s5,8(sp)
    80001a68:	e05a                	sd	s6,0(sp)
    80001a6a:	0080                	addi	s0,sp,64
    80001a6c:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a6e:	00230497          	auipc	s1,0x230
    80001a72:	c7a48493          	addi	s1,s1,-902 # 802316e8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a76:	8b26                	mv	s6,s1
    80001a78:	00006a97          	auipc	s5,0x6
    80001a7c:	588a8a93          	addi	s5,s5,1416 # 80008000 <etext>
    80001a80:	04000937          	lui	s2,0x4000
    80001a84:	197d                	addi	s2,s2,-1
    80001a86:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a88:	00237a17          	auipc	s4,0x237
    80001a8c:	860a0a13          	addi	s4,s4,-1952 # 802382e8 <tickslock>
    char *pa = kalloc();
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	1e8080e7          	jalr	488(ra) # 80000c78 <kalloc>
    80001a98:	862a                	mv	a2,a0
    if (pa == 0)
    80001a9a:	c131                	beqz	a0,80001ade <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a9c:	416485b3          	sub	a1,s1,s6
    80001aa0:	8591                	srai	a1,a1,0x4
    80001aa2:	000ab783          	ld	a5,0(s5)
    80001aa6:	02f585b3          	mul	a1,a1,a5
    80001aaa:	2585                	addiw	a1,a1,1
    80001aac:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ab0:	4719                	li	a4,6
    80001ab2:	6685                	lui	a3,0x1
    80001ab4:	40b905b3          	sub	a1,s2,a1
    80001ab8:	854e                	mv	a0,s3
    80001aba:	00000097          	auipc	ra,0x0
    80001abe:	870080e7          	jalr	-1936(ra) # 8000132a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ac2:	1b048493          	addi	s1,s1,432
    80001ac6:	fd4495e3          	bne	s1,s4,80001a90 <proc_mapstacks+0x38>
  }
}
    80001aca:	70e2                	ld	ra,56(sp)
    80001acc:	7442                	ld	s0,48(sp)
    80001ace:	74a2                	ld	s1,40(sp)
    80001ad0:	7902                	ld	s2,32(sp)
    80001ad2:	69e2                	ld	s3,24(sp)
    80001ad4:	6a42                	ld	s4,16(sp)
    80001ad6:	6aa2                	ld	s5,8(sp)
    80001ad8:	6b02                	ld	s6,0(sp)
    80001ada:	6121                	addi	sp,sp,64
    80001adc:	8082                	ret
      panic("kalloc");
    80001ade:	00006517          	auipc	a0,0x6
    80001ae2:	75a50513          	addi	a0,a0,1882 # 80008238 <digits+0x1f8>
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	a58080e7          	jalr	-1448(ra) # 8000053e <panic>

0000000080001aee <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001aee:	7139                	addi	sp,sp,-64
    80001af0:	fc06                	sd	ra,56(sp)
    80001af2:	f822                	sd	s0,48(sp)
    80001af4:	f426                	sd	s1,40(sp)
    80001af6:	f04a                	sd	s2,32(sp)
    80001af8:	ec4e                	sd	s3,24(sp)
    80001afa:	e852                	sd	s4,16(sp)
    80001afc:	e456                	sd	s5,8(sp)
    80001afe:	e05a                	sd	s6,0(sp)
    80001b00:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b02:	00006597          	auipc	a1,0x6
    80001b06:	73e58593          	addi	a1,a1,1854 # 80008240 <digits+0x200>
    80001b0a:	0022f517          	auipc	a0,0x22f
    80001b0e:	7ae50513          	addi	a0,a0,1966 # 802312b8 <pid_lock>
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	21c080e7          	jalr	540(ra) # 80000d2e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b1a:	00006597          	auipc	a1,0x6
    80001b1e:	72e58593          	addi	a1,a1,1838 # 80008248 <digits+0x208>
    80001b22:	0022f517          	auipc	a0,0x22f
    80001b26:	7ae50513          	addi	a0,a0,1966 # 802312d0 <wait_lock>
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	204080e7          	jalr	516(ra) # 80000d2e <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b32:	00230497          	auipc	s1,0x230
    80001b36:	bb648493          	addi	s1,s1,-1098 # 802316e8 <proc>
  {
    initlock(&p->lock, "proc");
    80001b3a:	00006b17          	auipc	s6,0x6
    80001b3e:	71eb0b13          	addi	s6,s6,1822 # 80008258 <digits+0x218>
    p->trace_mask = 0;
    p->kstack = KSTACK((int)(p - proc));
    80001b42:	8aa6                	mv	s5,s1
    80001b44:	00006a17          	auipc	s4,0x6
    80001b48:	4bca0a13          	addi	s4,s4,1212 # 80008000 <etext>
    80001b4c:	04000937          	lui	s2,0x4000
    80001b50:	197d                	addi	s2,s2,-1
    80001b52:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b54:	00236997          	auipc	s3,0x236
    80001b58:	79498993          	addi	s3,s3,1940 # 802382e8 <tickslock>
    initlock(&p->lock, "proc");
    80001b5c:	85da                	mv	a1,s6
    80001b5e:	8526                	mv	a0,s1
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	1ce080e7          	jalr	462(ra) # 80000d2e <initlock>
    p->trace_mask = 0;
    80001b68:	1604a423          	sw	zero,360(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b6c:	415487b3          	sub	a5,s1,s5
    80001b70:	8791                	srai	a5,a5,0x4
    80001b72:	000a3703          	ld	a4,0(s4)
    80001b76:	02e787b3          	mul	a5,a5,a4
    80001b7a:	2785                	addiw	a5,a5,1
    80001b7c:	00d7979b          	slliw	a5,a5,0xd
    80001b80:	40f907b3          	sub	a5,s2,a5
    80001b84:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b86:	1b048493          	addi	s1,s1,432
    80001b8a:	fd3499e3          	bne	s1,s3,80001b5c <procinit+0x6e>
  }
}
    80001b8e:	70e2                	ld	ra,56(sp)
    80001b90:	7442                	ld	s0,48(sp)
    80001b92:	74a2                	ld	s1,40(sp)
    80001b94:	7902                	ld	s2,32(sp)
    80001b96:	69e2                	ld	s3,24(sp)
    80001b98:	6a42                	ld	s4,16(sp)
    80001b9a:	6aa2                	ld	s5,8(sp)
    80001b9c:	6b02                	ld	s6,0(sp)
    80001b9e:	6121                	addi	sp,sp,64
    80001ba0:	8082                	ret

0000000080001ba2 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001ba2:	1141                	addi	sp,sp,-16
    80001ba4:	e422                	sd	s0,8(sp)
    80001ba6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ba8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001baa:	2501                	sext.w	a0,a0
    80001bac:	6422                	ld	s0,8(sp)
    80001bae:	0141                	addi	sp,sp,16
    80001bb0:	8082                	ret

0000000080001bb2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001bb2:	1141                	addi	sp,sp,-16
    80001bb4:	e422                	sd	s0,8(sp)
    80001bb6:	0800                	addi	s0,sp,16
    80001bb8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bba:	2781                	sext.w	a5,a5
    80001bbc:	079e                	slli	a5,a5,0x7
  return c;
}
    80001bbe:	0022f517          	auipc	a0,0x22f
    80001bc2:	72a50513          	addi	a0,a0,1834 # 802312e8 <cpus>
    80001bc6:	953e                	add	a0,a0,a5
    80001bc8:	6422                	ld	s0,8(sp)
    80001bca:	0141                	addi	sp,sp,16
    80001bcc:	8082                	ret

0000000080001bce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001bce:	1101                	addi	sp,sp,-32
    80001bd0:	ec06                	sd	ra,24(sp)
    80001bd2:	e822                	sd	s0,16(sp)
    80001bd4:	e426                	sd	s1,8(sp)
    80001bd6:	1000                	addi	s0,sp,32
  push_off();
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	19a080e7          	jalr	410(ra) # 80000d72 <push_off>
    80001be0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001be2:	2781                	sext.w	a5,a5
    80001be4:	079e                	slli	a5,a5,0x7
    80001be6:	0022f717          	auipc	a4,0x22f
    80001bea:	6d270713          	addi	a4,a4,1746 # 802312b8 <pid_lock>
    80001bee:	97ba                	add	a5,a5,a4
    80001bf0:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	220080e7          	jalr	544(ra) # 80000e12 <pop_off>
  return p;
}
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	60e2                	ld	ra,24(sp)
    80001bfe:	6442                	ld	s0,16(sp)
    80001c00:	64a2                	ld	s1,8(sp)
    80001c02:	6105                	addi	sp,sp,32
    80001c04:	8082                	ret

0000000080001c06 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c06:	1141                	addi	sp,sp,-16
    80001c08:	e406                	sd	ra,8(sp)
    80001c0a:	e022                	sd	s0,0(sp)
    80001c0c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	fc0080e7          	jalr	-64(ra) # 80001bce <myproc>
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	25c080e7          	jalr	604(ra) # 80000e72 <release>

  if (first)
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	ee27a783          	lw	a5,-286(a5) # 80008b00 <first.1716>
    80001c26:	eb89                	bnez	a5,80001c38 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c28:	00001097          	auipc	ra,0x1
    80001c2c:	f90080e7          	jalr	-112(ra) # 80002bb8 <usertrapret>
}
    80001c30:	60a2                	ld	ra,8(sp)
    80001c32:	6402                	ld	s0,0(sp)
    80001c34:	0141                	addi	sp,sp,16
    80001c36:	8082                	ret
    first = 0;
    80001c38:	00007797          	auipc	a5,0x7
    80001c3c:	ec07a423          	sw	zero,-312(a5) # 80008b00 <first.1716>
    fsinit(ROOTDEV);
    80001c40:	4505                	li	a0,1
    80001c42:	00002097          	auipc	ra,0x2
    80001c46:	01c080e7          	jalr	28(ra) # 80003c5e <fsinit>
    80001c4a:	bff9                	j	80001c28 <forkret+0x22>

0000000080001c4c <allocpid>:
{
    80001c4c:	1101                	addi	sp,sp,-32
    80001c4e:	ec06                	sd	ra,24(sp)
    80001c50:	e822                	sd	s0,16(sp)
    80001c52:	e426                	sd	s1,8(sp)
    80001c54:	e04a                	sd	s2,0(sp)
    80001c56:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c58:	0022f917          	auipc	s2,0x22f
    80001c5c:	66090913          	addi	s2,s2,1632 # 802312b8 <pid_lock>
    80001c60:	854a                	mv	a0,s2
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	15c080e7          	jalr	348(ra) # 80000dbe <acquire>
  pid = nextpid;
    80001c6a:	00007797          	auipc	a5,0x7
    80001c6e:	e9a78793          	addi	a5,a5,-358 # 80008b04 <nextpid>
    80001c72:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c74:	0014871b          	addiw	a4,s1,1
    80001c78:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c7a:	854a                	mv	a0,s2
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	1f6080e7          	jalr	502(ra) # 80000e72 <release>
}
    80001c84:	8526                	mv	a0,s1
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6902                	ld	s2,0(sp)
    80001c8e:	6105                	addi	sp,sp,32
    80001c90:	8082                	ret

0000000080001c92 <proc_pagetable>:
{
    80001c92:	1101                	addi	sp,sp,-32
    80001c94:	ec06                	sd	ra,24(sp)
    80001c96:	e822                	sd	s0,16(sp)
    80001c98:	e426                	sd	s1,8(sp)
    80001c9a:	e04a                	sd	s2,0(sp)
    80001c9c:	1000                	addi	s0,sp,32
    80001c9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	874080e7          	jalr	-1932(ra) # 80001514 <uvmcreate>
    80001ca8:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001caa:	c121                	beqz	a0,80001cea <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cac:	4729                	li	a4,10
    80001cae:	00005697          	auipc	a3,0x5
    80001cb2:	35268693          	addi	a3,a3,850 # 80007000 <_trampoline>
    80001cb6:	6605                	lui	a2,0x1
    80001cb8:	040005b7          	lui	a1,0x4000
    80001cbc:	15fd                	addi	a1,a1,-1
    80001cbe:	05b2                	slli	a1,a1,0xc
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	5ca080e7          	jalr	1482(ra) # 8000128a <mappages>
    80001cc8:	02054863          	bltz	a0,80001cf8 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ccc:	4719                	li	a4,6
    80001cce:	05893683          	ld	a3,88(s2)
    80001cd2:	6605                	lui	a2,0x1
    80001cd4:	020005b7          	lui	a1,0x2000
    80001cd8:	15fd                	addi	a1,a1,-1
    80001cda:	05b6                	slli	a1,a1,0xd
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	5ac080e7          	jalr	1452(ra) # 8000128a <mappages>
    80001ce6:	02054163          	bltz	a0,80001d08 <proc_pagetable+0x76>
}
    80001cea:	8526                	mv	a0,s1
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6902                	ld	s2,0(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret
    uvmfree(pagetable, 0);
    80001cf8:	4581                	li	a1,0
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	a14080e7          	jalr	-1516(ra) # 80001710 <uvmfree>
    return 0;
    80001d04:	4481                	li	s1,0
    80001d06:	b7d5                	j	80001cea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d08:	4681                	li	a3,0
    80001d0a:	4605                	li	a2,1
    80001d0c:	040005b7          	lui	a1,0x4000
    80001d10:	15fd                	addi	a1,a1,-1
    80001d12:	05b2                	slli	a1,a1,0xc
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	73a080e7          	jalr	1850(ra) # 80001450 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d1e:	4581                	li	a1,0
    80001d20:	8526                	mv	a0,s1
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	9ee080e7          	jalr	-1554(ra) # 80001710 <uvmfree>
    return 0;
    80001d2a:	4481                	li	s1,0
    80001d2c:	bf7d                	j	80001cea <proc_pagetable+0x58>

0000000080001d2e <proc_freepagetable>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
    80001d3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d3e:	4681                	li	a3,0
    80001d40:	4605                	li	a2,1
    80001d42:	040005b7          	lui	a1,0x4000
    80001d46:	15fd                	addi	a1,a1,-1
    80001d48:	05b2                	slli	a1,a1,0xc
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	706080e7          	jalr	1798(ra) # 80001450 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d52:	4681                	li	a3,0
    80001d54:	4605                	li	a2,1
    80001d56:	020005b7          	lui	a1,0x2000
    80001d5a:	15fd                	addi	a1,a1,-1
    80001d5c:	05b6                	slli	a1,a1,0xd
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	6f0080e7          	jalr	1776(ra) # 80001450 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d68:	85ca                	mv	a1,s2
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	9a4080e7          	jalr	-1628(ra) # 80001710 <uvmfree>
}
    80001d74:	60e2                	ld	ra,24(sp)
    80001d76:	6442                	ld	s0,16(sp)
    80001d78:	64a2                	ld	s1,8(sp)
    80001d7a:	6902                	ld	s2,0(sp)
    80001d7c:	6105                	addi	sp,sp,32
    80001d7e:	8082                	ret

0000000080001d80 <freeproc>:
{
    80001d80:	1101                	addi	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	e426                	sd	s1,8(sp)
    80001d88:	1000                	addi	s0,sp,32
    80001d8a:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d8c:	6d28                	ld	a0,88(a0)
    80001d8e:	c509                	beqz	a0,80001d98 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	cd4080e7          	jalr	-812(ra) # 80000a64 <kfree>
  if (p->trapframe_copy)
    80001d98:	1a84b503          	ld	a0,424(s1)
    80001d9c:	c509                	beqz	a0,80001da6 <freeproc+0x26>
    kfree((void *)p->trapframe_copy);
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	cc6080e7          	jalr	-826(ra) # 80000a64 <kfree>
  p->trapframe = 0;
    80001da6:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001daa:	68a8                	ld	a0,80(s1)
    80001dac:	c511                	beqz	a0,80001db8 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80001dae:	64ac                	ld	a1,72(s1)
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	f7e080e7          	jalr	-130(ra) # 80001d2e <proc_freepagetable>
  p->pagetable = 0;
    80001db8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dbc:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001dc0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dc4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001dc8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001dcc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dd0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dd4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dd8:	0004ac23          	sw	zero,24(s1)
}
    80001ddc:	60e2                	ld	ra,24(sp)
    80001dde:	6442                	ld	s0,16(sp)
    80001de0:	64a2                	ld	s1,8(sp)
    80001de2:	6105                	addi	sp,sp,32
    80001de4:	8082                	ret

0000000080001de6 <allocproc>:
{
    80001de6:	1101                	addi	sp,sp,-32
    80001de8:	ec06                	sd	ra,24(sp)
    80001dea:	e822                	sd	s0,16(sp)
    80001dec:	e426                	sd	s1,8(sp)
    80001dee:	e04a                	sd	s2,0(sp)
    80001df0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001df2:	00230497          	auipc	s1,0x230
    80001df6:	8f648493          	addi	s1,s1,-1802 # 802316e8 <proc>
    80001dfa:	00236917          	auipc	s2,0x236
    80001dfe:	4ee90913          	addi	s2,s2,1262 # 802382e8 <tickslock>
    acquire(&p->lock);
    80001e02:	8526                	mv	a0,s1
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	fba080e7          	jalr	-70(ra) # 80000dbe <acquire>
    if (p->state == UNUSED)
    80001e0c:	4c9c                	lw	a5,24(s1)
    80001e0e:	cf81                	beqz	a5,80001e26 <allocproc+0x40>
      release(&p->lock);
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	060080e7          	jalr	96(ra) # 80000e72 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e1a:	1b048493          	addi	s1,s1,432
    80001e1e:	ff2492e3          	bne	s1,s2,80001e02 <allocproc+0x1c>
  return 0;
    80001e22:	4481                	li	s1,0
    80001e24:	a055                	j	80001ec8 <allocproc+0xe2>
  p->pid = allocpid();
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	e26080e7          	jalr	-474(ra) # 80001c4c <allocpid>
    80001e2e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e30:	4785                	li	a5,1
    80001e32:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	e44080e7          	jalr	-444(ra) # 80000c78 <kalloc>
    80001e3c:	892a                	mv	s2,a0
    80001e3e:	eca8                	sd	a0,88(s1)
    80001e40:	c959                	beqz	a0,80001ed6 <allocproc+0xf0>
  if ((p->trapframe_copy = (struct trapframe *)kalloc()) == 0)
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e36080e7          	jalr	-458(ra) # 80000c78 <kalloc>
    80001e4a:	892a                	mv	s2,a0
    80001e4c:	1aa4b423          	sd	a0,424(s1)
    80001e50:	cd59                	beqz	a0,80001eee <allocproc+0x108>
  p->is_sigalarm = 0;
    80001e52:	1804a823          	sw	zero,400(s1)
  p->ticks = 0;
    80001e56:	1804aa23          	sw	zero,404(s1)
  p->now_ticks = 0;
    80001e5a:	1804ac23          	sw	zero,408(s1)
  p->handler = 0;
    80001e5e:	1a04b023          	sd	zero,416(s1)
  p->pagetable = proc_pagetable(p);
    80001e62:	8526                	mv	a0,s1
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	e2e080e7          	jalr	-466(ra) # 80001c92 <proc_pagetable>
    80001e6c:	892a                	mv	s2,a0
    80001e6e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e70:	c551                	beqz	a0,80001efc <allocproc+0x116>
  memset(&p->context, 0, sizeof(p->context));
    80001e72:	07000613          	li	a2,112
    80001e76:	4581                	li	a1,0
    80001e78:	06048513          	addi	a0,s1,96
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	03e080e7          	jalr	62(ra) # 80000eba <memset>
  p->context.ra = (uint64)forkret;
    80001e84:	00000797          	auipc	a5,0x0
    80001e88:	d8278793          	addi	a5,a5,-638 # 80001c06 <forkret>
    80001e8c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e8e:	60bc                	ld	a5,64(s1)
    80001e90:	6705                	lui	a4,0x1
    80001e92:	97ba                	add	a5,a5,a4
    80001e94:	f4bc                	sd	a5,104(s1)
  p->ltime = 0;
    80001e96:	1604a623          	sw	zero,364(s1)
  p->rtime = 0;
    80001e9a:	1604a823          	sw	zero,368(s1)
  p->stime = 0;
    80001e9e:	1604ae23          	sw	zero,380(s1)
  p->ntime = 0;
    80001ea2:	1804a023          	sw	zero,384(s1)
  p->etime = 0;
    80001ea6:	1604ac23          	sw	zero,376(s1)
  p->ctime = ticks;
    80001eaa:	00007797          	auipc	a5,0x7
    80001eae:	1867a783          	lw	a5,390(a5) # 80009030 <ticks>
    80001eb2:	16f4aa23          	sw	a5,372(s1)
  p->nice = 5;
    80001eb6:	4795                	li	a5,5
    80001eb8:	18f4a423          	sw	a5,392(s1)
  p->stp = 60;
    80001ebc:	03c00793          	li	a5,60
    80001ec0:	18f4a623          	sw	a5,396(s1)
  p->nrun = 0;
    80001ec4:	1804a223          	sw	zero,388(s1)
}
    80001ec8:	8526                	mv	a0,s1
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6902                	ld	s2,0(sp)
    80001ed2:	6105                	addi	sp,sp,32
    80001ed4:	8082                	ret
    freeproc(p);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	ea8080e7          	jalr	-344(ra) # 80001d80 <freeproc>
    release(&p->lock);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	f90080e7          	jalr	-112(ra) # 80000e72 <release>
    return 0;
    80001eea:	84ca                	mv	s1,s2
    80001eec:	bff1                	j	80001ec8 <allocproc+0xe2>
    release(&p->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	f82080e7          	jalr	-126(ra) # 80000e72 <release>
    return 0;
    80001ef8:	84ca                	mv	s1,s2
    80001efa:	b7f9                	j	80001ec8 <allocproc+0xe2>
    freeproc(p);
    80001efc:	8526                	mv	a0,s1
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	e82080e7          	jalr	-382(ra) # 80001d80 <freeproc>
    release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	f6a080e7          	jalr	-150(ra) # 80000e72 <release>
    return 0;
    80001f10:	84ca                	mv	s1,s2
    80001f12:	bf5d                	j	80001ec8 <allocproc+0xe2>

0000000080001f14 <userinit>:
{
    80001f14:	1101                	addi	sp,sp,-32
    80001f16:	ec06                	sd	ra,24(sp)
    80001f18:	e822                	sd	s0,16(sp)
    80001f1a:	e426                	sd	s1,8(sp)
    80001f1c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	ec8080e7          	jalr	-312(ra) # 80001de6 <allocproc>
    80001f26:	84aa                	mv	s1,a0
  initproc = p;
    80001f28:	00007797          	auipc	a5,0x7
    80001f2c:	10a7b023          	sd	a0,256(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f30:	03400613          	li	a2,52
    80001f34:	00007597          	auipc	a1,0x7
    80001f38:	bdc58593          	addi	a1,a1,-1060 # 80008b10 <initcode>
    80001f3c:	6928                	ld	a0,80(a0)
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	604080e7          	jalr	1540(ra) # 80001542 <uvminit>
  p->sz = PGSIZE;
    80001f46:	6785                	lui	a5,0x1
    80001f48:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f4a:	6cb8                	ld	a4,88(s1)
    80001f4c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f50:	6cb8                	ld	a4,88(s1)
    80001f52:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f54:	4641                	li	a2,16
    80001f56:	00006597          	auipc	a1,0x6
    80001f5a:	30a58593          	addi	a1,a1,778 # 80008260 <digits+0x220>
    80001f5e:	15848513          	addi	a0,s1,344
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	0aa080e7          	jalr	170(ra) # 8000100c <safestrcpy>
  p->cwd = namei("/");
    80001f6a:	00006517          	auipc	a0,0x6
    80001f6e:	30650513          	addi	a0,a0,774 # 80008270 <digits+0x230>
    80001f72:	00002097          	auipc	ra,0x2
    80001f76:	71a080e7          	jalr	1818(ra) # 8000468c <namei>
    80001f7a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f7e:	478d                	li	a5,3
    80001f80:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	eee080e7          	jalr	-274(ra) # 80000e72 <release>
}
    80001f8c:	60e2                	ld	ra,24(sp)
    80001f8e:	6442                	ld	s0,16(sp)
    80001f90:	64a2                	ld	s1,8(sp)
    80001f92:	6105                	addi	sp,sp,32
    80001f94:	8082                	ret

0000000080001f96 <growproc>:
{
    80001f96:	1101                	addi	sp,sp,-32
    80001f98:	ec06                	sd	ra,24(sp)
    80001f9a:	e822                	sd	s0,16(sp)
    80001f9c:	e426                	sd	s1,8(sp)
    80001f9e:	e04a                	sd	s2,0(sp)
    80001fa0:	1000                	addi	s0,sp,32
    80001fa2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	c2a080e7          	jalr	-982(ra) # 80001bce <myproc>
    80001fac:	892a                	mv	s2,a0
  sz = p->sz;
    80001fae:	652c                	ld	a1,72(a0)
    80001fb0:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001fb4:	00904f63          	bgtz	s1,80001fd2 <growproc+0x3c>
  else if (n < 0)
    80001fb8:	0204cc63          	bltz	s1,80001ff0 <growproc+0x5a>
  p->sz = sz;
    80001fbc:	1602                	slli	a2,a2,0x20
    80001fbe:	9201                	srli	a2,a2,0x20
    80001fc0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001fc4:	4501                	li	a0,0
}
    80001fc6:	60e2                	ld	ra,24(sp)
    80001fc8:	6442                	ld	s0,16(sp)
    80001fca:	64a2                	ld	s1,8(sp)
    80001fcc:	6902                	ld	s2,0(sp)
    80001fce:	6105                	addi	sp,sp,32
    80001fd0:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001fd2:	9e25                	addw	a2,a2,s1
    80001fd4:	1602                	slli	a2,a2,0x20
    80001fd6:	9201                	srli	a2,a2,0x20
    80001fd8:	1582                	slli	a1,a1,0x20
    80001fda:	9181                	srli	a1,a1,0x20
    80001fdc:	6928                	ld	a0,80(a0)
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	61e080e7          	jalr	1566(ra) # 800015fc <uvmalloc>
    80001fe6:	0005061b          	sext.w	a2,a0
    80001fea:	fa69                	bnez	a2,80001fbc <growproc+0x26>
      return -1;
    80001fec:	557d                	li	a0,-1
    80001fee:	bfe1                	j	80001fc6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ff0:	9e25                	addw	a2,a2,s1
    80001ff2:	1602                	slli	a2,a2,0x20
    80001ff4:	9201                	srli	a2,a2,0x20
    80001ff6:	1582                	slli	a1,a1,0x20
    80001ff8:	9181                	srli	a1,a1,0x20
    80001ffa:	6928                	ld	a0,80(a0)
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	5b8080e7          	jalr	1464(ra) # 800015b4 <uvmdealloc>
    80002004:	0005061b          	sext.w	a2,a0
    80002008:	bf55                	j	80001fbc <growproc+0x26>

000000008000200a <fork>:
{
    8000200a:	7179                	addi	sp,sp,-48
    8000200c:	f406                	sd	ra,40(sp)
    8000200e:	f022                	sd	s0,32(sp)
    80002010:	ec26                	sd	s1,24(sp)
    80002012:	e84a                	sd	s2,16(sp)
    80002014:	e44e                	sd	s3,8(sp)
    80002016:	e052                	sd	s4,0(sp)
    80002018:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	bb4080e7          	jalr	-1100(ra) # 80001bce <myproc>
    80002022:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80002024:	00000097          	auipc	ra,0x0
    80002028:	dc2080e7          	jalr	-574(ra) # 80001de6 <allocproc>
    8000202c:	10050f63          	beqz	a0,8000214a <fork+0x140>
    80002030:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002032:	04893603          	ld	a2,72(s2)
    80002036:	692c                	ld	a1,80(a0)
    80002038:	05093503          	ld	a0,80(s2)
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	70c080e7          	jalr	1804(ra) # 80001748 <uvmcopy>
    80002044:	04054a63          	bltz	a0,80002098 <fork+0x8e>
  np->sz = p->sz;
    80002048:	04893783          	ld	a5,72(s2)
    8000204c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002050:	05893683          	ld	a3,88(s2)
    80002054:	87b6                	mv	a5,a3
    80002056:	0589b703          	ld	a4,88(s3)
    8000205a:	12068693          	addi	a3,a3,288
    8000205e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002062:	6788                	ld	a0,8(a5)
    80002064:	6b8c                	ld	a1,16(a5)
    80002066:	6f90                	ld	a2,24(a5)
    80002068:	01073023          	sd	a6,0(a4)
    8000206c:	e708                	sd	a0,8(a4)
    8000206e:	eb0c                	sd	a1,16(a4)
    80002070:	ef10                	sd	a2,24(a4)
    80002072:	02078793          	addi	a5,a5,32
    80002076:	02070713          	addi	a4,a4,32
    8000207a:	fed792e3          	bne	a5,a3,8000205e <fork+0x54>
  np->trace_mask = p->trace_mask;
    8000207e:	16892783          	lw	a5,360(s2)
    80002082:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80002086:	0589b783          	ld	a5,88(s3)
    8000208a:	0607b823          	sd	zero,112(a5)
    8000208e:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80002092:	15000a13          	li	s4,336
    80002096:	a03d                	j	800020c4 <fork+0xba>
    freeproc(np);
    80002098:	854e                	mv	a0,s3
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	ce6080e7          	jalr	-794(ra) # 80001d80 <freeproc>
    release(&np->lock);
    800020a2:	854e                	mv	a0,s3
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	dce080e7          	jalr	-562(ra) # 80000e72 <release>
    return -1;
    800020ac:	5a7d                	li	s4,-1
    800020ae:	a069                	j	80002138 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    800020b0:	00003097          	auipc	ra,0x3
    800020b4:	c72080e7          	jalr	-910(ra) # 80004d22 <filedup>
    800020b8:	009987b3          	add	a5,s3,s1
    800020bc:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    800020be:	04a1                	addi	s1,s1,8
    800020c0:	01448763          	beq	s1,s4,800020ce <fork+0xc4>
    if (p->ofile[i])
    800020c4:	009907b3          	add	a5,s2,s1
    800020c8:	6388                	ld	a0,0(a5)
    800020ca:	f17d                	bnez	a0,800020b0 <fork+0xa6>
    800020cc:	bfcd                	j	800020be <fork+0xb4>
  np->cwd = idup(p->cwd);
    800020ce:	15093503          	ld	a0,336(s2)
    800020d2:	00002097          	auipc	ra,0x2
    800020d6:	dc6080e7          	jalr	-570(ra) # 80003e98 <idup>
    800020da:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020de:	4641                	li	a2,16
    800020e0:	15890593          	addi	a1,s2,344
    800020e4:	15898513          	addi	a0,s3,344
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	f24080e7          	jalr	-220(ra) # 8000100c <safestrcpy>
  pid = np->pid;
    800020f0:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020f4:	854e                	mv	a0,s3
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	d7c080e7          	jalr	-644(ra) # 80000e72 <release>
  acquire(&wait_lock);
    800020fe:	0022f497          	auipc	s1,0x22f
    80002102:	1d248493          	addi	s1,s1,466 # 802312d0 <wait_lock>
    80002106:	8526                	mv	a0,s1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	cb6080e7          	jalr	-842(ra) # 80000dbe <acquire>
  np->parent = p;
    80002110:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	d5c080e7          	jalr	-676(ra) # 80000e72 <release>
  acquire(&np->lock);
    8000211e:	854e                	mv	a0,s3
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	c9e080e7          	jalr	-866(ra) # 80000dbe <acquire>
  np->state = RUNNABLE;
    80002128:	478d                	li	a5,3
    8000212a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000212e:	854e                	mv	a0,s3
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	d42080e7          	jalr	-702(ra) # 80000e72 <release>
}
    80002138:	8552                	mv	a0,s4
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6a02                	ld	s4,0(sp)
    80002146:	6145                	addi	sp,sp,48
    80002148:	8082                	ret
    return -1;
    8000214a:	5a7d                	li	s4,-1
    8000214c:	b7f5                	j	80002138 <fork+0x12e>

000000008000214e <update_time>:
{
    8000214e:	7179                	addi	sp,sp,-48
    80002150:	f406                	sd	ra,40(sp)
    80002152:	f022                	sd	s0,32(sp)
    80002154:	ec26                	sd	s1,24(sp)
    80002156:	e84a                	sd	s2,16(sp)
    80002158:	e44e                	sd	s3,8(sp)
    8000215a:	e052                	sd	s4,0(sp)
    8000215c:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    8000215e:	0022f497          	auipc	s1,0x22f
    80002162:	58a48493          	addi	s1,s1,1418 # 802316e8 <proc>
    if (p->state == RUNNING)
    80002166:	4991                	li	s3,4
    else if (p->state == SLEEPING)
    80002168:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    8000216a:	00236917          	auipc	s2,0x236
    8000216e:	17e90913          	addi	s2,s2,382 # 802382e8 <tickslock>
    80002172:	a839                	j	80002190 <update_time+0x42>
      p->rtime++;
    80002174:	1704a783          	lw	a5,368(s1)
    80002178:	2785                	addiw	a5,a5,1
    8000217a:	16f4a823          	sw	a5,368(s1)
    release(&p->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	cf2080e7          	jalr	-782(ra) # 80000e72 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002188:	1b048493          	addi	s1,s1,432
    8000218c:	03248c63          	beq	s1,s2,800021c4 <update_time+0x76>
    acquire(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	c2c080e7          	jalr	-980(ra) # 80000dbe <acquire>
    p->ltime++;
    8000219a:	16c4a783          	lw	a5,364(s1)
    8000219e:	2785                	addiw	a5,a5,1
    800021a0:	16f4a623          	sw	a5,364(s1)
    if (p->state == RUNNING)
    800021a4:	4c9c                	lw	a5,24(s1)
    800021a6:	fd3787e3          	beq	a5,s3,80002174 <update_time+0x26>
    else if (p->state == SLEEPING)
    800021aa:	fd479ae3          	bne	a5,s4,8000217e <update_time+0x30>
      p->stime++;
    800021ae:	17c4a783          	lw	a5,380(s1)
    800021b2:	2785                	addiw	a5,a5,1
    800021b4:	16f4ae23          	sw	a5,380(s1)
      p->ntime++;
    800021b8:	1804a783          	lw	a5,384(s1)
    800021bc:	2785                	addiw	a5,a5,1
    800021be:	18f4a023          	sw	a5,384(s1)
    800021c2:	bf75                	j	8000217e <update_time+0x30>
}
    800021c4:	70a2                	ld	ra,40(sp)
    800021c6:	7402                	ld	s0,32(sp)
    800021c8:	64e2                	ld	s1,24(sp)
    800021ca:	6942                	ld	s2,16(sp)
    800021cc:	69a2                	ld	s3,8(sp)
    800021ce:	6a02                	ld	s4,0(sp)
    800021d0:	6145                	addi	sp,sp,48
    800021d2:	8082                	ret

00000000800021d4 <scheduler>:
{
    800021d4:	7139                	addi	sp,sp,-64
    800021d6:	fc06                	sd	ra,56(sp)
    800021d8:	f822                	sd	s0,48(sp)
    800021da:	f426                	sd	s1,40(sp)
    800021dc:	f04a                	sd	s2,32(sp)
    800021de:	ec4e                	sd	s3,24(sp)
    800021e0:	e852                	sd	s4,16(sp)
    800021e2:	e456                	sd	s5,8(sp)
    800021e4:	e05a                	sd	s6,0(sp)
    800021e6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	9e6080e7          	jalr	-1562(ra) # 80001bce <myproc>
    800021f0:	8492                	mv	s1,tp
  int id = r_tp();
    800021f2:	2481                	sext.w	s1,s1
  c->proc = 0;
    800021f4:	00749a93          	slli	s5,s1,0x7
    800021f8:	0022f797          	auipc	a5,0x22f
    800021fc:	0c078793          	addi	a5,a5,192 # 802312b8 <pid_lock>
    80002200:	97d6                	add	a5,a5,s5
    80002202:	0207b823          	sd	zero,48(a5)
  printf("scheduler: RR\n"); // DEBUG
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	07250513          	addi	a0,a0,114 # 80008278 <digits+0x238>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	37a080e7          	jalr	890(ra) # 80000588 <printf>
        swtch(&c->context, &p->context);
    80002216:	0022f797          	auipc	a5,0x22f
    8000221a:	0da78793          	addi	a5,a5,218 # 802312f0 <cpus+0x8>
    8000221e:	9abe                	add	s5,s5,a5
      if (p->state == RUNNABLE)
    80002220:	498d                	li	s3,3
        p->state = RUNNING;
    80002222:	4b11                	li	s6,4
        c->proc = p;
    80002224:	049e                	slli	s1,s1,0x7
    80002226:	0022fa17          	auipc	s4,0x22f
    8000222a:	092a0a13          	addi	s4,s4,146 # 802312b8 <pid_lock>
    8000222e:	9a26                	add	s4,s4,s1
    for (p = proc; p < &proc[NPROC]; p++)
    80002230:	00236917          	auipc	s2,0x236
    80002234:	0b890913          	addi	s2,s2,184 # 802382e8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002238:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000223c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002240:	10079073          	csrw	sstatus,a5
    80002244:	0022f497          	auipc	s1,0x22f
    80002248:	4a448493          	addi	s1,s1,1188 # 802316e8 <proc>
    8000224c:	a03d                	j	8000227a <scheduler+0xa6>
        p->state = RUNNING;
    8000224e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002252:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002256:	06048593          	addi	a1,s1,96
    8000225a:	8556                	mv	a0,s5
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	7f4080e7          	jalr	2036(ra) # 80002a50 <swtch>
        c->proc = 0;
    80002264:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	c08080e7          	jalr	-1016(ra) # 80000e72 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002272:	1b048493          	addi	s1,s1,432
    80002276:	fd2481e3          	beq	s1,s2,80002238 <scheduler+0x64>
      acquire(&p->lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	b42080e7          	jalr	-1214(ra) # 80000dbe <acquire>
      if (p->state == RUNNABLE)
    80002284:	4c9c                	lw	a5,24(s1)
    80002286:	ff3791e3          	bne	a5,s3,80002268 <scheduler+0x94>
    8000228a:	b7d1                	j	8000224e <scheduler+0x7a>

000000008000228c <sched>:
{
    8000228c:	7179                	addi	sp,sp,-48
    8000228e:	f406                	sd	ra,40(sp)
    80002290:	f022                	sd	s0,32(sp)
    80002292:	ec26                	sd	s1,24(sp)
    80002294:	e84a                	sd	s2,16(sp)
    80002296:	e44e                	sd	s3,8(sp)
    80002298:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	934080e7          	jalr	-1740(ra) # 80001bce <myproc>
    800022a2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	aa0080e7          	jalr	-1376(ra) # 80000d44 <holding>
    800022ac:	c93d                	beqz	a0,80002322 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ae:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022b0:	2781                	sext.w	a5,a5
    800022b2:	079e                	slli	a5,a5,0x7
    800022b4:	0022f717          	auipc	a4,0x22f
    800022b8:	00470713          	addi	a4,a4,4 # 802312b8 <pid_lock>
    800022bc:	97ba                	add	a5,a5,a4
    800022be:	0a87a703          	lw	a4,168(a5)
    800022c2:	4785                	li	a5,1
    800022c4:	06f71763          	bne	a4,a5,80002332 <sched+0xa6>
  if (p->state == RUNNING)
    800022c8:	4c98                	lw	a4,24(s1)
    800022ca:	4791                	li	a5,4
    800022cc:	06f70b63          	beq	a4,a5,80002342 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022d4:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022d6:	efb5                	bnez	a5,80002352 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022da:	0022f917          	auipc	s2,0x22f
    800022de:	fde90913          	addi	s2,s2,-34 # 802312b8 <pid_lock>
    800022e2:	2781                	sext.w	a5,a5
    800022e4:	079e                	slli	a5,a5,0x7
    800022e6:	97ca                	add	a5,a5,s2
    800022e8:	0ac7a983          	lw	s3,172(a5)
    800022ec:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	0022f597          	auipc	a1,0x22f
    800022f6:	ffe58593          	addi	a1,a1,-2 # 802312f0 <cpus+0x8>
    800022fa:	95be                	add	a1,a1,a5
    800022fc:	06048513          	addi	a0,s1,96
    80002300:	00000097          	auipc	ra,0x0
    80002304:	750080e7          	jalr	1872(ra) # 80002a50 <swtch>
    80002308:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000230a:	2781                	sext.w	a5,a5
    8000230c:	079e                	slli	a5,a5,0x7
    8000230e:	97ca                	add	a5,a5,s2
    80002310:	0b37a623          	sw	s3,172(a5)
}
    80002314:	70a2                	ld	ra,40(sp)
    80002316:	7402                	ld	s0,32(sp)
    80002318:	64e2                	ld	s1,24(sp)
    8000231a:	6942                	ld	s2,16(sp)
    8000231c:	69a2                	ld	s3,8(sp)
    8000231e:	6145                	addi	sp,sp,48
    80002320:	8082                	ret
    panic("sched p->lock");
    80002322:	00006517          	auipc	a0,0x6
    80002326:	f6650513          	addi	a0,a0,-154 # 80008288 <digits+0x248>
    8000232a:	ffffe097          	auipc	ra,0xffffe
    8000232e:	214080e7          	jalr	532(ra) # 8000053e <panic>
    panic("sched locks");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f6650513          	addi	a0,a0,-154 # 80008298 <digits+0x258>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	204080e7          	jalr	516(ra) # 8000053e <panic>
    panic("sched running");
    80002342:	00006517          	auipc	a0,0x6
    80002346:	f6650513          	addi	a0,a0,-154 # 800082a8 <digits+0x268>
    8000234a:	ffffe097          	auipc	ra,0xffffe
    8000234e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002352:	00006517          	auipc	a0,0x6
    80002356:	f6650513          	addi	a0,a0,-154 # 800082b8 <digits+0x278>
    8000235a:	ffffe097          	auipc	ra,0xffffe
    8000235e:	1e4080e7          	jalr	484(ra) # 8000053e <panic>

0000000080002362 <yield>:
{
    80002362:	1101                	addi	sp,sp,-32
    80002364:	ec06                	sd	ra,24(sp)
    80002366:	e822                	sd	s0,16(sp)
    80002368:	e426                	sd	s1,8(sp)
    8000236a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	862080e7          	jalr	-1950(ra) # 80001bce <myproc>
    80002374:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	a48080e7          	jalr	-1464(ra) # 80000dbe <acquire>
  p->state = RUNNABLE;
    8000237e:	478d                	li	a5,3
    80002380:	cc9c                	sw	a5,24(s1)
  sched();
    80002382:	00000097          	auipc	ra,0x0
    80002386:	f0a080e7          	jalr	-246(ra) # 8000228c <sched>
  release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	ae6080e7          	jalr	-1306(ra) # 80000e72 <release>
}
    80002394:	60e2                	ld	ra,24(sp)
    80002396:	6442                	ld	s0,16(sp)
    80002398:	64a2                	ld	s1,8(sp)
    8000239a:	6105                	addi	sp,sp,32
    8000239c:	8082                	ret

000000008000239e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000239e:	7179                	addi	sp,sp,-48
    800023a0:	f406                	sd	ra,40(sp)
    800023a2:	f022                	sd	s0,32(sp)
    800023a4:	ec26                	sd	s1,24(sp)
    800023a6:	e84a                	sd	s2,16(sp)
    800023a8:	e44e                	sd	s3,8(sp)
    800023aa:	1800                	addi	s0,sp,48
    800023ac:	89aa                	mv	s3,a0
    800023ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	81e080e7          	jalr	-2018(ra) # 80001bce <myproc>
    800023b8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	a04080e7          	jalr	-1532(ra) # 80000dbe <acquire>
  release(lk);
    800023c2:	854a                	mv	a0,s2
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	aae080e7          	jalr	-1362(ra) # 80000e72 <release>

  // Go to sleep.
  p->chan = chan;
    800023cc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023d0:	4789                	li	a5,2
    800023d2:	cc9c                	sw	a5,24(s1)

  sched();
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	eb8080e7          	jalr	-328(ra) # 8000228c <sched>

  // Tidy up.
  p->chan = 0;
    800023dc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	a90080e7          	jalr	-1392(ra) # 80000e72 <release>
  acquire(lk);
    800023ea:	854a                	mv	a0,s2
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	9d2080e7          	jalr	-1582(ra) # 80000dbe <acquire>
}
    800023f4:	70a2                	ld	ra,40(sp)
    800023f6:	7402                	ld	s0,32(sp)
    800023f8:	64e2                	ld	s1,24(sp)
    800023fa:	6942                	ld	s2,16(sp)
    800023fc:	69a2                	ld	s3,8(sp)
    800023fe:	6145                	addi	sp,sp,48
    80002400:	8082                	ret

0000000080002402 <wait>:
{
    80002402:	715d                	addi	sp,sp,-80
    80002404:	e486                	sd	ra,72(sp)
    80002406:	e0a2                	sd	s0,64(sp)
    80002408:	fc26                	sd	s1,56(sp)
    8000240a:	f84a                	sd	s2,48(sp)
    8000240c:	f44e                	sd	s3,40(sp)
    8000240e:	f052                	sd	s4,32(sp)
    80002410:	ec56                	sd	s5,24(sp)
    80002412:	e85a                	sd	s6,16(sp)
    80002414:	e45e                	sd	s7,8(sp)
    80002416:	e062                	sd	s8,0(sp)
    80002418:	0880                	addi	s0,sp,80
    8000241a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	7b2080e7          	jalr	1970(ra) # 80001bce <myproc>
    80002424:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002426:	0022f517          	auipc	a0,0x22f
    8000242a:	eaa50513          	addi	a0,a0,-342 # 802312d0 <wait_lock>
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	990080e7          	jalr	-1648(ra) # 80000dbe <acquire>
    havekids = 0;
    80002436:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002438:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000243a:	00236997          	auipc	s3,0x236
    8000243e:	eae98993          	addi	s3,s3,-338 # 802382e8 <tickslock>
        havekids = 1;
    80002442:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002444:	0022fc17          	auipc	s8,0x22f
    80002448:	e8cc0c13          	addi	s8,s8,-372 # 802312d0 <wait_lock>
    havekids = 0;
    8000244c:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000244e:	0022f497          	auipc	s1,0x22f
    80002452:	29a48493          	addi	s1,s1,666 # 802316e8 <proc>
    80002456:	a0bd                	j	800024c4 <wait+0xc2>
          pid = np->pid;
    80002458:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000245c:	000b0e63          	beqz	s6,80002478 <wait+0x76>
    80002460:	4691                	li	a3,4
    80002462:	02c48613          	addi	a2,s1,44
    80002466:	85da                	mv	a1,s6
    80002468:	05093503          	ld	a0,80(s2)
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	3e8080e7          	jalr	1000(ra) # 80001854 <copyout>
    80002474:	02054563          	bltz	a0,8000249e <wait+0x9c>
          freeproc(np);
    80002478:	8526                	mv	a0,s1
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	906080e7          	jalr	-1786(ra) # 80001d80 <freeproc>
          release(&np->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	9ee080e7          	jalr	-1554(ra) # 80000e72 <release>
          release(&wait_lock);
    8000248c:	0022f517          	auipc	a0,0x22f
    80002490:	e4450513          	addi	a0,a0,-444 # 802312d0 <wait_lock>
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	9de080e7          	jalr	-1570(ra) # 80000e72 <release>
          return pid;
    8000249c:	a09d                	j	80002502 <wait+0x100>
            release(&np->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	9d2080e7          	jalr	-1582(ra) # 80000e72 <release>
            release(&wait_lock);
    800024a8:	0022f517          	auipc	a0,0x22f
    800024ac:	e2850513          	addi	a0,a0,-472 # 802312d0 <wait_lock>
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	9c2080e7          	jalr	-1598(ra) # 80000e72 <release>
            return -1;
    800024b8:	59fd                	li	s3,-1
    800024ba:	a0a1                	j	80002502 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800024bc:	1b048493          	addi	s1,s1,432
    800024c0:	03348463          	beq	s1,s3,800024e8 <wait+0xe6>
      if (np->parent == p)
    800024c4:	7c9c                	ld	a5,56(s1)
    800024c6:	ff279be3          	bne	a5,s2,800024bc <wait+0xba>
        acquire(&np->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	8f2080e7          	jalr	-1806(ra) # 80000dbe <acquire>
        if (np->state == ZOMBIE)
    800024d4:	4c9c                	lw	a5,24(s1)
    800024d6:	f94781e3          	beq	a5,s4,80002458 <wait+0x56>
        release(&np->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	996080e7          	jalr	-1642(ra) # 80000e72 <release>
        havekids = 1;
    800024e4:	8756                	mv	a4,s5
    800024e6:	bfd9                	j	800024bc <wait+0xba>
    if (!havekids || p->killed)
    800024e8:	c701                	beqz	a4,800024f0 <wait+0xee>
    800024ea:	02892783          	lw	a5,40(s2)
    800024ee:	c79d                	beqz	a5,8000251c <wait+0x11a>
      release(&wait_lock);
    800024f0:	0022f517          	auipc	a0,0x22f
    800024f4:	de050513          	addi	a0,a0,-544 # 802312d0 <wait_lock>
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	97a080e7          	jalr	-1670(ra) # 80000e72 <release>
      return -1;
    80002500:	59fd                	li	s3,-1
}
    80002502:	854e                	mv	a0,s3
    80002504:	60a6                	ld	ra,72(sp)
    80002506:	6406                	ld	s0,64(sp)
    80002508:	74e2                	ld	s1,56(sp)
    8000250a:	7942                	ld	s2,48(sp)
    8000250c:	79a2                	ld	s3,40(sp)
    8000250e:	7a02                	ld	s4,32(sp)
    80002510:	6ae2                	ld	s5,24(sp)
    80002512:	6b42                	ld	s6,16(sp)
    80002514:	6ba2                	ld	s7,8(sp)
    80002516:	6c02                	ld	s8,0(sp)
    80002518:	6161                	addi	sp,sp,80
    8000251a:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000251c:	85e2                	mv	a1,s8
    8000251e:	854a                	mv	a0,s2
    80002520:	00000097          	auipc	ra,0x0
    80002524:	e7e080e7          	jalr	-386(ra) # 8000239e <sleep>
    havekids = 0;
    80002528:	b715                	j	8000244c <wait+0x4a>

000000008000252a <waitx>:
{
    8000252a:	711d                	addi	sp,sp,-96
    8000252c:	ec86                	sd	ra,88(sp)
    8000252e:	e8a2                	sd	s0,80(sp)
    80002530:	e4a6                	sd	s1,72(sp)
    80002532:	e0ca                	sd	s2,64(sp)
    80002534:	fc4e                	sd	s3,56(sp)
    80002536:	f852                	sd	s4,48(sp)
    80002538:	f456                	sd	s5,40(sp)
    8000253a:	f05a                	sd	s6,32(sp)
    8000253c:	ec5e                	sd	s7,24(sp)
    8000253e:	e862                	sd	s8,16(sp)
    80002540:	e466                	sd	s9,8(sp)
    80002542:	e06a                	sd	s10,0(sp)
    80002544:	1080                	addi	s0,sp,96
    80002546:	8b2a                	mv	s6,a0
    80002548:	8c2e                	mv	s8,a1
    8000254a:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	682080e7          	jalr	1666(ra) # 80001bce <myproc>
    80002554:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002556:	0022f517          	auipc	a0,0x22f
    8000255a:	d7a50513          	addi	a0,a0,-646 # 802312d0 <wait_lock>
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	860080e7          	jalr	-1952(ra) # 80000dbe <acquire>
    havekids = 0;
    80002566:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    80002568:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000256a:	00236997          	auipc	s3,0x236
    8000256e:	d7e98993          	addi	s3,s3,-642 # 802382e8 <tickslock>
        havekids = 1;
    80002572:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002574:	0022fd17          	auipc	s10,0x22f
    80002578:	d5cd0d13          	addi	s10,s10,-676 # 802312d0 <wait_lock>
    havekids = 0;
    8000257c:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000257e:	0022f497          	auipc	s1,0x22f
    80002582:	16a48493          	addi	s1,s1,362 # 802316e8 <proc>
    80002586:	a059                	j	8000260c <waitx+0xe2>
          pid = np->pid;
    80002588:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000258c:	1704a703          	lw	a4,368(s1)
    80002590:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002594:	1744a783          	lw	a5,372(s1)
    80002598:	9f3d                	addw	a4,a4,a5
    8000259a:	1784a783          	lw	a5,376(s1)
    8000259e:	9f99                	subw	a5,a5,a4
    800025a0:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7fdb8000>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025a4:	000b0e63          	beqz	s6,800025c0 <waitx+0x96>
    800025a8:	4691                	li	a3,4
    800025aa:	02c48613          	addi	a2,s1,44
    800025ae:	85da                	mv	a1,s6
    800025b0:	05093503          	ld	a0,80(s2)
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	2a0080e7          	jalr	672(ra) # 80001854 <copyout>
    800025bc:	02054563          	bltz	a0,800025e6 <waitx+0xbc>
          freeproc(np);
    800025c0:	8526                	mv	a0,s1
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	7be080e7          	jalr	1982(ra) # 80001d80 <freeproc>
          release(&np->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	8a6080e7          	jalr	-1882(ra) # 80000e72 <release>
          release(&wait_lock);
    800025d4:	0022f517          	auipc	a0,0x22f
    800025d8:	cfc50513          	addi	a0,a0,-772 # 802312d0 <wait_lock>
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	896080e7          	jalr	-1898(ra) # 80000e72 <release>
          return pid;
    800025e4:	a09d                	j	8000264a <waitx+0x120>
            release(&np->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	88a080e7          	jalr	-1910(ra) # 80000e72 <release>
            release(&wait_lock);
    800025f0:	0022f517          	auipc	a0,0x22f
    800025f4:	ce050513          	addi	a0,a0,-800 # 802312d0 <wait_lock>
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	87a080e7          	jalr	-1926(ra) # 80000e72 <release>
            return -1;
    80002600:	59fd                	li	s3,-1
    80002602:	a0a1                	j	8000264a <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002604:	1b048493          	addi	s1,s1,432
    80002608:	03348463          	beq	s1,s3,80002630 <waitx+0x106>
      if (np->parent == p)
    8000260c:	7c9c                	ld	a5,56(s1)
    8000260e:	ff279be3          	bne	a5,s2,80002604 <waitx+0xda>
        acquire(&np->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	7aa080e7          	jalr	1962(ra) # 80000dbe <acquire>
        if (np->state == ZOMBIE)
    8000261c:	4c9c                	lw	a5,24(s1)
    8000261e:	f74785e3          	beq	a5,s4,80002588 <waitx+0x5e>
        release(&np->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	84e080e7          	jalr	-1970(ra) # 80000e72 <release>
        havekids = 1;
    8000262c:	8756                	mv	a4,s5
    8000262e:	bfd9                	j	80002604 <waitx+0xda>
    if (!havekids || p->killed)
    80002630:	c701                	beqz	a4,80002638 <waitx+0x10e>
    80002632:	02892783          	lw	a5,40(s2)
    80002636:	cb8d                	beqz	a5,80002668 <waitx+0x13e>
      release(&wait_lock);
    80002638:	0022f517          	auipc	a0,0x22f
    8000263c:	c9850513          	addi	a0,a0,-872 # 802312d0 <wait_lock>
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	832080e7          	jalr	-1998(ra) # 80000e72 <release>
      return -1;
    80002648:	59fd                	li	s3,-1
}
    8000264a:	854e                	mv	a0,s3
    8000264c:	60e6                	ld	ra,88(sp)
    8000264e:	6446                	ld	s0,80(sp)
    80002650:	64a6                	ld	s1,72(sp)
    80002652:	6906                	ld	s2,64(sp)
    80002654:	79e2                	ld	s3,56(sp)
    80002656:	7a42                	ld	s4,48(sp)
    80002658:	7aa2                	ld	s5,40(sp)
    8000265a:	7b02                	ld	s6,32(sp)
    8000265c:	6be2                	ld	s7,24(sp)
    8000265e:	6c42                	ld	s8,16(sp)
    80002660:	6ca2                	ld	s9,8(sp)
    80002662:	6d02                	ld	s10,0(sp)
    80002664:	6125                	addi	sp,sp,96
    80002666:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002668:	85ea                	mv	a1,s10
    8000266a:	854a                	mv	a0,s2
    8000266c:	00000097          	auipc	ra,0x0
    80002670:	d32080e7          	jalr	-718(ra) # 8000239e <sleep>
    havekids = 0;
    80002674:	b721                	j	8000257c <waitx+0x52>

0000000080002676 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002676:	7139                	addi	sp,sp,-64
    80002678:	fc06                	sd	ra,56(sp)
    8000267a:	f822                	sd	s0,48(sp)
    8000267c:	f426                	sd	s1,40(sp)
    8000267e:	f04a                	sd	s2,32(sp)
    80002680:	ec4e                	sd	s3,24(sp)
    80002682:	e852                	sd	s4,16(sp)
    80002684:	e456                	sd	s5,8(sp)
    80002686:	0080                	addi	s0,sp,64
    80002688:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000268a:	0022f497          	auipc	s1,0x22f
    8000268e:	05e48493          	addi	s1,s1,94 # 802316e8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002692:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002694:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002696:	00236917          	auipc	s2,0x236
    8000269a:	c5290913          	addi	s2,s2,-942 # 802382e8 <tickslock>
    8000269e:	a821                	j	800026b6 <wakeup+0x40>
        p->state = RUNNABLE;
    800026a0:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800026a4:	8526                	mv	a0,s1
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	7cc080e7          	jalr	1996(ra) # 80000e72 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ae:	1b048493          	addi	s1,s1,432
    800026b2:	03248463          	beq	s1,s2,800026da <wakeup+0x64>
    if (p != myproc())
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	518080e7          	jalr	1304(ra) # 80001bce <myproc>
    800026be:	fea488e3          	beq	s1,a0,800026ae <wakeup+0x38>
      acquire(&p->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	6fa080e7          	jalr	1786(ra) # 80000dbe <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800026cc:	4c9c                	lw	a5,24(s1)
    800026ce:	fd379be3          	bne	a5,s3,800026a4 <wakeup+0x2e>
    800026d2:	709c                	ld	a5,32(s1)
    800026d4:	fd4798e3          	bne	a5,s4,800026a4 <wakeup+0x2e>
    800026d8:	b7e1                	j	800026a0 <wakeup+0x2a>
    }
  }
}
    800026da:	70e2                	ld	ra,56(sp)
    800026dc:	7442                	ld	s0,48(sp)
    800026de:	74a2                	ld	s1,40(sp)
    800026e0:	7902                	ld	s2,32(sp)
    800026e2:	69e2                	ld	s3,24(sp)
    800026e4:	6a42                	ld	s4,16(sp)
    800026e6:	6aa2                	ld	s5,8(sp)
    800026e8:	6121                	addi	sp,sp,64
    800026ea:	8082                	ret

00000000800026ec <reparent>:
{
    800026ec:	7179                	addi	sp,sp,-48
    800026ee:	f406                	sd	ra,40(sp)
    800026f0:	f022                	sd	s0,32(sp)
    800026f2:	ec26                	sd	s1,24(sp)
    800026f4:	e84a                	sd	s2,16(sp)
    800026f6:	e44e                	sd	s3,8(sp)
    800026f8:	e052                	sd	s4,0(sp)
    800026fa:	1800                	addi	s0,sp,48
    800026fc:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026fe:	0022f497          	auipc	s1,0x22f
    80002702:	fea48493          	addi	s1,s1,-22 # 802316e8 <proc>
      pp->parent = initproc;
    80002706:	00007a17          	auipc	s4,0x7
    8000270a:	922a0a13          	addi	s4,s4,-1758 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000270e:	00236997          	auipc	s3,0x236
    80002712:	bda98993          	addi	s3,s3,-1062 # 802382e8 <tickslock>
    80002716:	a029                	j	80002720 <reparent+0x34>
    80002718:	1b048493          	addi	s1,s1,432
    8000271c:	01348d63          	beq	s1,s3,80002736 <reparent+0x4a>
    if (pp->parent == p)
    80002720:	7c9c                	ld	a5,56(s1)
    80002722:	ff279be3          	bne	a5,s2,80002718 <reparent+0x2c>
      pp->parent = initproc;
    80002726:	000a3503          	ld	a0,0(s4)
    8000272a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000272c:	00000097          	auipc	ra,0x0
    80002730:	f4a080e7          	jalr	-182(ra) # 80002676 <wakeup>
    80002734:	b7d5                	j	80002718 <reparent+0x2c>
}
    80002736:	70a2                	ld	ra,40(sp)
    80002738:	7402                	ld	s0,32(sp)
    8000273a:	64e2                	ld	s1,24(sp)
    8000273c:	6942                	ld	s2,16(sp)
    8000273e:	69a2                	ld	s3,8(sp)
    80002740:	6a02                	ld	s4,0(sp)
    80002742:	6145                	addi	sp,sp,48
    80002744:	8082                	ret

0000000080002746 <exit>:
{
    80002746:	7179                	addi	sp,sp,-48
    80002748:	f406                	sd	ra,40(sp)
    8000274a:	f022                	sd	s0,32(sp)
    8000274c:	ec26                	sd	s1,24(sp)
    8000274e:	e84a                	sd	s2,16(sp)
    80002750:	e44e                	sd	s3,8(sp)
    80002752:	e052                	sd	s4,0(sp)
    80002754:	1800                	addi	s0,sp,48
    80002756:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	476080e7          	jalr	1142(ra) # 80001bce <myproc>
    80002760:	89aa                	mv	s3,a0
  if (p == initproc)
    80002762:	00007797          	auipc	a5,0x7
    80002766:	8c67b783          	ld	a5,-1850(a5) # 80009028 <initproc>
    8000276a:	0d050493          	addi	s1,a0,208
    8000276e:	15050913          	addi	s2,a0,336
    80002772:	02a79363          	bne	a5,a0,80002798 <exit+0x52>
    panic("init exiting");
    80002776:	00006517          	auipc	a0,0x6
    8000277a:	b5a50513          	addi	a0,a0,-1190 # 800082d0 <digits+0x290>
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	dc0080e7          	jalr	-576(ra) # 8000053e <panic>
      fileclose(f);
    80002786:	00002097          	auipc	ra,0x2
    8000278a:	5ee080e7          	jalr	1518(ra) # 80004d74 <fileclose>
      p->ofile[fd] = 0;
    8000278e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002792:	04a1                	addi	s1,s1,8
    80002794:	01248563          	beq	s1,s2,8000279e <exit+0x58>
    if (p->ofile[fd])
    80002798:	6088                	ld	a0,0(s1)
    8000279a:	f575                	bnez	a0,80002786 <exit+0x40>
    8000279c:	bfdd                	j	80002792 <exit+0x4c>
  begin_op();
    8000279e:	00002097          	auipc	ra,0x2
    800027a2:	10a080e7          	jalr	266(ra) # 800048a8 <begin_op>
  iput(p->cwd);
    800027a6:	1509b503          	ld	a0,336(s3)
    800027aa:	00002097          	auipc	ra,0x2
    800027ae:	8e6080e7          	jalr	-1818(ra) # 80004090 <iput>
  end_op();
    800027b2:	00002097          	auipc	ra,0x2
    800027b6:	176080e7          	jalr	374(ra) # 80004928 <end_op>
  p->cwd = 0;
    800027ba:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800027be:	0022f497          	auipc	s1,0x22f
    800027c2:	b1248493          	addi	s1,s1,-1262 # 802312d0 <wait_lock>
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	5f6080e7          	jalr	1526(ra) # 80000dbe <acquire>
  reparent(p);
    800027d0:	854e                	mv	a0,s3
    800027d2:	00000097          	auipc	ra,0x0
    800027d6:	f1a080e7          	jalr	-230(ra) # 800026ec <reparent>
  wakeup(p->parent);
    800027da:	0389b503          	ld	a0,56(s3)
    800027de:	00000097          	auipc	ra,0x0
    800027e2:	e98080e7          	jalr	-360(ra) # 80002676 <wakeup>
  acquire(&p->lock);
    800027e6:	854e                	mv	a0,s3
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	5d6080e7          	jalr	1494(ra) # 80000dbe <acquire>
  p->xstate = status;
    800027f0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027f4:	4795                	li	a5,5
    800027f6:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800027fa:	00007797          	auipc	a5,0x7
    800027fe:	8367a783          	lw	a5,-1994(a5) # 80009030 <ticks>
    80002802:	16f9ac23          	sw	a5,376(s3)
  release(&wait_lock);
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	66a080e7          	jalr	1642(ra) # 80000e72 <release>
  sched();
    80002810:	00000097          	auipc	ra,0x0
    80002814:	a7c080e7          	jalr	-1412(ra) # 8000228c <sched>
  panic("zombie exit");
    80002818:	00006517          	auipc	a0,0x6
    8000281c:	ac850513          	addi	a0,a0,-1336 # 800082e0 <digits+0x2a0>
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	d1e080e7          	jalr	-738(ra) # 8000053e <panic>

0000000080002828 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002828:	7179                	addi	sp,sp,-48
    8000282a:	f406                	sd	ra,40(sp)
    8000282c:	f022                	sd	s0,32(sp)
    8000282e:	ec26                	sd	s1,24(sp)
    80002830:	e84a                	sd	s2,16(sp)
    80002832:	e44e                	sd	s3,8(sp)
    80002834:	1800                	addi	s0,sp,48
    80002836:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002838:	0022f497          	auipc	s1,0x22f
    8000283c:	eb048493          	addi	s1,s1,-336 # 802316e8 <proc>
    80002840:	00236997          	auipc	s3,0x236
    80002844:	aa898993          	addi	s3,s3,-1368 # 802382e8 <tickslock>
  {
    acquire(&p->lock);
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	574080e7          	jalr	1396(ra) # 80000dbe <acquire>
    if (p->pid == pid)
    80002852:	589c                	lw	a5,48(s1)
    80002854:	01278d63          	beq	a5,s2,8000286e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	618080e7          	jalr	1560(ra) # 80000e72 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002862:	1b048493          	addi	s1,s1,432
    80002866:	ff3491e3          	bne	s1,s3,80002848 <kill+0x20>
  }
  return -1;
    8000286a:	557d                	li	a0,-1
    8000286c:	a829                	j	80002886 <kill+0x5e>
      p->killed = 1;
    8000286e:	4785                	li	a5,1
    80002870:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002872:	4c98                	lw	a4,24(s1)
    80002874:	4789                	li	a5,2
    80002876:	00f70f63          	beq	a4,a5,80002894 <kill+0x6c>
      release(&p->lock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	5f6080e7          	jalr	1526(ra) # 80000e72 <release>
      return 0;
    80002884:	4501                	li	a0,0
}
    80002886:	70a2                	ld	ra,40(sp)
    80002888:	7402                	ld	s0,32(sp)
    8000288a:	64e2                	ld	s1,24(sp)
    8000288c:	6942                	ld	s2,16(sp)
    8000288e:	69a2                	ld	s3,8(sp)
    80002890:	6145                	addi	sp,sp,48
    80002892:	8082                	ret
        p->state = RUNNABLE;
    80002894:	478d                	li	a5,3
    80002896:	cc9c                	sw	a5,24(s1)
    80002898:	b7cd                	j	8000287a <kill+0x52>

000000008000289a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000289a:	7179                	addi	sp,sp,-48
    8000289c:	f406                	sd	ra,40(sp)
    8000289e:	f022                	sd	s0,32(sp)
    800028a0:	ec26                	sd	s1,24(sp)
    800028a2:	e84a                	sd	s2,16(sp)
    800028a4:	e44e                	sd	s3,8(sp)
    800028a6:	e052                	sd	s4,0(sp)
    800028a8:	1800                	addi	s0,sp,48
    800028aa:	84aa                	mv	s1,a0
    800028ac:	892e                	mv	s2,a1
    800028ae:	89b2                	mv	s3,a2
    800028b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	31c080e7          	jalr	796(ra) # 80001bce <myproc>
  if (user_dst)
    800028ba:	c08d                	beqz	s1,800028dc <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800028bc:	86d2                	mv	a3,s4
    800028be:	864e                	mv	a2,s3
    800028c0:	85ca                	mv	a1,s2
    800028c2:	6928                	ld	a0,80(a0)
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	f90080e7          	jalr	-112(ra) # 80001854 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028cc:	70a2                	ld	ra,40(sp)
    800028ce:	7402                	ld	s0,32(sp)
    800028d0:	64e2                	ld	s1,24(sp)
    800028d2:	6942                	ld	s2,16(sp)
    800028d4:	69a2                	ld	s3,8(sp)
    800028d6:	6a02                	ld	s4,0(sp)
    800028d8:	6145                	addi	sp,sp,48
    800028da:	8082                	ret
    memmove((char *)dst, src, len);
    800028dc:	000a061b          	sext.w	a2,s4
    800028e0:	85ce                	mv	a1,s3
    800028e2:	854a                	mv	a0,s2
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	636080e7          	jalr	1590(ra) # 80000f1a <memmove>
    return 0;
    800028ec:	8526                	mv	a0,s1
    800028ee:	bff9                	j	800028cc <either_copyout+0x32>

00000000800028f0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028f0:	7179                	addi	sp,sp,-48
    800028f2:	f406                	sd	ra,40(sp)
    800028f4:	f022                	sd	s0,32(sp)
    800028f6:	ec26                	sd	s1,24(sp)
    800028f8:	e84a                	sd	s2,16(sp)
    800028fa:	e44e                	sd	s3,8(sp)
    800028fc:	e052                	sd	s4,0(sp)
    800028fe:	1800                	addi	s0,sp,48
    80002900:	892a                	mv	s2,a0
    80002902:	84ae                	mv	s1,a1
    80002904:	89b2                	mv	s3,a2
    80002906:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	2c6080e7          	jalr	710(ra) # 80001bce <myproc>
  if (user_src)
    80002910:	c08d                	beqz	s1,80002932 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002912:	86d2                	mv	a3,s4
    80002914:	864e                	mv	a2,s3
    80002916:	85ca                	mv	a1,s2
    80002918:	6928                	ld	a0,80(a0)
    8000291a:	fffff097          	auipc	ra,0xfffff
    8000291e:	ffe080e7          	jalr	-2(ra) # 80001918 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002922:	70a2                	ld	ra,40(sp)
    80002924:	7402                	ld	s0,32(sp)
    80002926:	64e2                	ld	s1,24(sp)
    80002928:	6942                	ld	s2,16(sp)
    8000292a:	69a2                	ld	s3,8(sp)
    8000292c:	6a02                	ld	s4,0(sp)
    8000292e:	6145                	addi	sp,sp,48
    80002930:	8082                	ret
    memmove(dst, (char *)src, len);
    80002932:	000a061b          	sext.w	a2,s4
    80002936:	85ce                	mv	a1,s3
    80002938:	854a                	mv	a0,s2
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	5e0080e7          	jalr	1504(ra) # 80000f1a <memmove>
    return 0;
    80002942:	8526                	mv	a0,s1
    80002944:	bff9                	j	80002922 <either_copyin+0x32>

0000000080002946 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002946:	715d                	addi	sp,sp,-80
    80002948:	e486                	sd	ra,72(sp)
    8000294a:	e0a2                	sd	s0,64(sp)
    8000294c:	fc26                	sd	s1,56(sp)
    8000294e:	f84a                	sd	s2,48(sp)
    80002950:	f44e                	sd	s3,40(sp)
    80002952:	f052                	sd	s4,32(sp)
    80002954:	ec56                	sd	s5,24(sp)
    80002956:	e85a                	sd	s6,16(sp)
    80002958:	e45e                	sd	s7,8(sp)
    8000295a:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000295c:	00005517          	auipc	a0,0x5
    80002960:	7cc50513          	addi	a0,a0,1996 # 80008128 <digits+0xe8>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c24080e7          	jalr	-988(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000296c:	0022f497          	auipc	s1,0x22f
    80002970:	ed448493          	addi	s1,s1,-300 # 80231840 <proc+0x158>
    80002974:	00236917          	auipc	s2,0x236
    80002978:	acc90913          	addi	s2,s2,-1332 # 80238440 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000297c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000297e:	00006997          	auipc	s3,0x6
    80002982:	97298993          	addi	s3,s3,-1678 # 800082f0 <digits+0x2b0>
#ifdef PBS
    printf("%d %d %s %d %d %d", p->pid, max(0, min(p->stp - p->nice + 5, 100)), state, p->rtime, p->ltime - p->rtime - p->stime, p->nrun);
#else
    printf("%d %s %s", p->pid, state, p->name);
    80002986:	00006a97          	auipc	s5,0x6
    8000298a:	972a8a93          	addi	s5,s5,-1678 # 800082f8 <digits+0x2b8>
#endif
    printf("\n");
    8000298e:	00005a17          	auipc	s4,0x5
    80002992:	79aa0a13          	addi	s4,s4,1946 # 80008128 <digits+0xe8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002996:	00006b97          	auipc	s7,0x6
    8000299a:	99ab8b93          	addi	s7,s7,-1638 # 80008330 <states.1753>
    8000299e:	a00d                	j	800029c0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800029a0:	ed86a583          	lw	a1,-296(a3)
    800029a4:	8556                	mv	a0,s5
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	be2080e7          	jalr	-1054(ra) # 80000588 <printf>
    printf("\n");
    800029ae:	8552                	mv	a0,s4
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bd8080e7          	jalr	-1064(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029b8:	1b048493          	addi	s1,s1,432
    800029bc:	03248163          	beq	s1,s2,800029de <procdump+0x98>
    if (p->state == UNUSED)
    800029c0:	86a6                	mv	a3,s1
    800029c2:	ec04a783          	lw	a5,-320(s1)
    800029c6:	dbed                	beqz	a5,800029b8 <procdump+0x72>
      state = "???";
    800029c8:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ca:	fcfb6be3          	bltu	s6,a5,800029a0 <procdump+0x5a>
    800029ce:	1782                	slli	a5,a5,0x20
    800029d0:	9381                	srli	a5,a5,0x20
    800029d2:	078e                	slli	a5,a5,0x3
    800029d4:	97de                	add	a5,a5,s7
    800029d6:	6390                	ld	a2,0(a5)
    800029d8:	f661                	bnez	a2,800029a0 <procdump+0x5a>
      state = "???";
    800029da:	864e                	mv	a2,s3
    800029dc:	b7d1                	j	800029a0 <procdump+0x5a>
  }
}
    800029de:	60a6                	ld	ra,72(sp)
    800029e0:	6406                	ld	s0,64(sp)
    800029e2:	74e2                	ld	s1,56(sp)
    800029e4:	7942                	ld	s2,48(sp)
    800029e6:	79a2                	ld	s3,40(sp)
    800029e8:	7a02                	ld	s4,32(sp)
    800029ea:	6ae2                	ld	s5,24(sp)
    800029ec:	6b42                	ld	s6,16(sp)
    800029ee:	6ba2                	ld	s7,8(sp)
    800029f0:	6161                	addi	sp,sp,80
    800029f2:	8082                	ret

00000000800029f4 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    800029f4:	1101                	addi	sp,sp,-32
    800029f6:	ec06                	sd	ra,24(sp)
    800029f8:	e822                	sd	s0,16(sp)
    800029fa:	1000                	addi	s0,sp,32
  int ticks;

  uint64 handler;

  if(argint(0,&ticks) < 0)
    800029fc:	fec40593          	addi	a1,s0,-20
    80002a00:	4501                	li	a0,0
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	6c2080e7          	jalr	1730(ra) # 800030c4 <argint>
  {
    return -1;
    80002a0a:	57fd                	li	a5,-1
  if(argint(0,&ticks) < 0)
    80002a0c:	02054d63          	bltz	a0,80002a46 <sys_sigalarm+0x52>
  }

  if(argaddr(1,&handler) < 0)
    80002a10:	fe040593          	addi	a1,s0,-32
    80002a14:	4505                	li	a0,1
    80002a16:	00000097          	auipc	ra,0x0
    80002a1a:	6d0080e7          	jalr	1744(ra) # 800030e6 <argaddr>
  {
    return -1;
    80002a1e:	57fd                	li	a5,-1
  if(argaddr(1,&handler) < 0)
    80002a20:	02054363          	bltz	a0,80002a46 <sys_sigalarm+0x52>
  }

  struct proc* p = myproc();
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	1aa080e7          	jalr	426(ra) # 80001bce <myproc>
  
  p->is_sigalarm = 0;
    80002a2c:	18052823          	sw	zero,400(a0)
  p->ticks = ticks;
    80002a30:	fec42783          	lw	a5,-20(s0)
    80002a34:	18f52a23          	sw	a5,404(a0)
  p->now_ticks = 0;
    80002a38:	18052c23          	sw	zero,408(a0)
  p->handler = handler;
    80002a3c:	fe043783          	ld	a5,-32(s0)
    80002a40:	1af53023          	sd	a5,416(a0)

  return 0;
    80002a44:	4781                	li	a5,0
    80002a46:	853e                	mv	a0,a5
    80002a48:	60e2                	ld	ra,24(sp)
    80002a4a:	6442                	ld	s0,16(sp)
    80002a4c:	6105                	addi	sp,sp,32
    80002a4e:	8082                	ret

0000000080002a50 <swtch>:
    80002a50:	00153023          	sd	ra,0(a0)
    80002a54:	00253423          	sd	sp,8(a0)
    80002a58:	e900                	sd	s0,16(a0)
    80002a5a:	ed04                	sd	s1,24(a0)
    80002a5c:	03253023          	sd	s2,32(a0)
    80002a60:	03353423          	sd	s3,40(a0)
    80002a64:	03453823          	sd	s4,48(a0)
    80002a68:	03553c23          	sd	s5,56(a0)
    80002a6c:	05653023          	sd	s6,64(a0)
    80002a70:	05753423          	sd	s7,72(a0)
    80002a74:	05853823          	sd	s8,80(a0)
    80002a78:	05953c23          	sd	s9,88(a0)
    80002a7c:	07a53023          	sd	s10,96(a0)
    80002a80:	07b53423          	sd	s11,104(a0)
    80002a84:	0005b083          	ld	ra,0(a1)
    80002a88:	0085b103          	ld	sp,8(a1)
    80002a8c:	6980                	ld	s0,16(a1)
    80002a8e:	6d84                	ld	s1,24(a1)
    80002a90:	0205b903          	ld	s2,32(a1)
    80002a94:	0285b983          	ld	s3,40(a1)
    80002a98:	0305ba03          	ld	s4,48(a1)
    80002a9c:	0385ba83          	ld	s5,56(a1)
    80002aa0:	0405bb03          	ld	s6,64(a1)
    80002aa4:	0485bb83          	ld	s7,72(a1)
    80002aa8:	0505bc03          	ld	s8,80(a1)
    80002aac:	0585bc83          	ld	s9,88(a1)
    80002ab0:	0605bd03          	ld	s10,96(a1)
    80002ab4:	0685bd83          	ld	s11,104(a1)
    80002ab8:	8082                	ret

0000000080002aba <pagefaulthandler>:
void kernelvec();

extern int devintr();

int pagefaulthandler(void*va,pagetable_t pagetable)
{
    80002aba:	7179                	addi	sp,sp,-48
    80002abc:	f406                	sd	ra,40(sp)
    80002abe:	f022                	sd	s0,32(sp)
    80002ac0:	ec26                	sd	s1,24(sp)
    80002ac2:	e84a                	sd	s2,16(sp)
    80002ac4:	e44e                	sd	s3,8(sp)
    80002ac6:	e052                	sd	s4,0(sp)
    80002ac8:	1800                	addi	s0,sp,48
    80002aca:	84aa                	mv	s1,a0
    80002acc:	892e                	mv	s2,a1
  struct proc* p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	100080e7          	jalr	256(ra) # 80001bce <myproc>

  if((uint64)va>=MAXVA)
    80002ad6:	57fd                	li	a5,-1
    80002ad8:	83e9                	srli	a5,a5,0x1a
    80002ada:	0897e563          	bltu	a5,s1,80002b64 <pagefaulthandler+0xaa>
  {
    return -2;
  }

  if((uint64)va>=PGROUNDDOWN(p->trapframe->sp)-PGSIZE&&(uint64)va<=PGROUNDDOWN(p->trapframe->sp))
    80002ade:	6d38                	ld	a4,88(a0)
    80002ae0:	77fd                	lui	a5,0xfffff
    80002ae2:	7b18                	ld	a4,48(a4)
    80002ae4:	8f7d                	and	a4,a4,a5
    80002ae6:	97ba                	add	a5,a5,a4
    80002ae8:	00f4e463          	bltu	s1,a5,80002af0 <pagefaulthandler+0x36>
    80002aec:	06977e63          	bgeu	a4,s1,80002b68 <pagefaulthandler+0xae>
  }

  uint64 pa;

  va = (void*)PGROUNDDOWN((uint64)va);
  pte_t *pte = walk(pagetable,(uint64)va,0);
    80002af0:	4601                	li	a2,0
    80002af2:	75fd                	lui	a1,0xfffff
    80002af4:	8de5                	and	a1,a1,s1
    80002af6:	854a                	mv	a0,s2
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	6aa080e7          	jalr	1706(ra) # 800011a2 <walk>
    80002b00:	892a                	mv	s2,a0
  if(!pte)
    80002b02:	c52d                	beqz	a0,80002b6c <pagefaulthandler+0xb2>
  {
    return -1;
  }
  
  if(PTE2PA(*pte) == 0)
    80002b04:	611c                	ld	a5,0(a0)
    80002b06:	00a7d993          	srli	s3,a5,0xa
    80002b0a:	09b2                	slli	s3,s3,0xc
    80002b0c:	06098263          	beqz	s3,80002b70 <pagefaulthandler+0xb6>
  {
    return -1;
  }
  pa = PTE2PA(*pte);
  uint flags = PTE_FLAGS(*pte);
    80002b10:	2781                	sext.w	a5,a5

  if((flags & PTE_C) == 0)
    80002b12:	0207f713          	andi	a4,a5,32
  {
    return 0;
    80002b16:	4501                	li	a0,0
  if((flags & PTE_C) == 0)
    80002b18:	eb09                	bnez	a4,80002b2a <pagefaulthandler+0x70>
  }
  memmove(mem,(void*)pa,PGSIZE); 
  *pte = PA2PTE(mem)|flags;
  kfree((void*)pa);
  return 0;
}
    80002b1a:	70a2                	ld	ra,40(sp)
    80002b1c:	7402                	ld	s0,32(sp)
    80002b1e:	64e2                	ld	s1,24(sp)
    80002b20:	6942                	ld	s2,16(sp)
    80002b22:	69a2                	ld	s3,8(sp)
    80002b24:	6a02                	ld	s4,0(sp)
    80002b26:	6145                	addi	sp,sp,48
    80002b28:	8082                	ret
  flags = (flags|PTE_W)&(~PTE_C);
    80002b2a:	3df7f793          	andi	a5,a5,991
    80002b2e:	0047e493          	ori	s1,a5,4
  mem = kalloc();
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	146080e7          	jalr	326(ra) # 80000c78 <kalloc>
    80002b3a:	8a2a                	mv	s4,a0
  if(mem==0)
    80002b3c:	cd05                	beqz	a0,80002b74 <pagefaulthandler+0xba>
  memmove(mem,(void*)pa,PGSIZE); 
    80002b3e:	6605                	lui	a2,0x1
    80002b40:	85ce                	mv	a1,s3
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	3d8080e7          	jalr	984(ra) # 80000f1a <memmove>
  *pte = PA2PTE(mem)|flags;
    80002b4a:	00ca5793          	srli	a5,s4,0xc
    80002b4e:	07aa                	slli	a5,a5,0xa
    80002b50:	8fc5                	or	a5,a5,s1
    80002b52:	00f93023          	sd	a5,0(s2)
  kfree((void*)pa);
    80002b56:	854e                	mv	a0,s3
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	f0c080e7          	jalr	-244(ra) # 80000a64 <kfree>
  return 0;
    80002b60:	4501                	li	a0,0
    80002b62:	bf65                	j	80002b1a <pagefaulthandler+0x60>
    return -2;
    80002b64:	5579                	li	a0,-2
    80002b66:	bf55                	j	80002b1a <pagefaulthandler+0x60>
    return -2;
    80002b68:	5579                	li	a0,-2
    80002b6a:	bf45                	j	80002b1a <pagefaulthandler+0x60>
    return -1;
    80002b6c:	557d                	li	a0,-1
    80002b6e:	b775                	j	80002b1a <pagefaulthandler+0x60>
    return -1;
    80002b70:	557d                	li	a0,-1
    80002b72:	b765                	j	80002b1a <pagefaulthandler+0x60>
    return -1;
    80002b74:	557d                	li	a0,-1
    80002b76:	b755                	j	80002b1a <pagefaulthandler+0x60>

0000000080002b78 <trapinit>:

void trapinit(void)
{
    80002b78:	1141                	addi	sp,sp,-16
    80002b7a:	e406                	sd	ra,8(sp)
    80002b7c:	e022                	sd	s0,0(sp)
    80002b7e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b80:	00005597          	auipc	a1,0x5
    80002b84:	7e058593          	addi	a1,a1,2016 # 80008360 <states.1753+0x30>
    80002b88:	00235517          	auipc	a0,0x235
    80002b8c:	76050513          	addi	a0,a0,1888 # 802382e8 <tickslock>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	19e080e7          	jalr	414(ra) # 80000d2e <initlock>
}
    80002b98:	60a2                	ld	ra,8(sp)
    80002b9a:	6402                	ld	s0,0(sp)
    80002b9c:	0141                	addi	sp,sp,16
    80002b9e:	8082                	ret

0000000080002ba0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002ba0:	1141                	addi	sp,sp,-16
    80002ba2:	e422                	sd	s0,8(sp)
    80002ba4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba6:	00003797          	auipc	a5,0x3
    80002baa:	7ea78793          	addi	a5,a5,2026 # 80006390 <kernelvec>
    80002bae:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bb2:	6422                	ld	s0,8(sp)
    80002bb4:	0141                	addi	sp,sp,16
    80002bb6:	8082                	ret

0000000080002bb8 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002bb8:	1141                	addi	sp,sp,-16
    80002bba:	e406                	sd	ra,8(sp)
    80002bbc:	e022                	sd	s0,0(sp)
    80002bbe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	00e080e7          	jalr	14(ra) # 80001bce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bce:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bd2:	00004617          	auipc	a2,0x4
    80002bd6:	42e60613          	addi	a2,a2,1070 # 80007000 <_trampoline>
    80002bda:	00004697          	auipc	a3,0x4
    80002bde:	42668693          	addi	a3,a3,1062 # 80007000 <_trampoline>
    80002be2:	8e91                	sub	a3,a3,a2
    80002be4:	040007b7          	lui	a5,0x4000
    80002be8:	17fd                	addi	a5,a5,-1
    80002bea:	07b2                	slli	a5,a5,0xc
    80002bec:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bee:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bf2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bf4:	180026f3          	csrr	a3,satp
    80002bf8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bfa:	6d38                	ld	a4,88(a0)
    80002bfc:	6134                	ld	a3,64(a0)
    80002bfe:	6585                	lui	a1,0x1
    80002c00:	96ae                	add	a3,a3,a1
    80002c02:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c04:	6d38                	ld	a4,88(a0)
    80002c06:	00000697          	auipc	a3,0x0
    80002c0a:	14668693          	addi	a3,a3,326 # 80002d4c <usertrap>
    80002c0e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c10:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c12:	8692                	mv	a3,tp
    80002c14:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c16:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c1a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c1e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c22:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c26:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c28:	6f18                	ld	a4,24(a4)
    80002c2a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c2e:	692c                	ld	a1,80(a0)
    80002c30:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c32:	00004717          	auipc	a4,0x4
    80002c36:	45e70713          	addi	a4,a4,1118 # 80007090 <userret>
    80002c3a:	8f11                	sub	a4,a4,a2
    80002c3c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002c3e:	577d                	li	a4,-1
    80002c40:	177e                	slli	a4,a4,0x3f
    80002c42:	8dd9                	or	a1,a1,a4
    80002c44:	02000537          	lui	a0,0x2000
    80002c48:	157d                	addi	a0,a0,-1
    80002c4a:	0536                	slli	a0,a0,0xd
    80002c4c:	9782                	jalr	a5
}
    80002c4e:	60a2                	ld	ra,8(sp)
    80002c50:	6402                	ld	s0,0(sp)
    80002c52:	0141                	addi	sp,sp,16
    80002c54:	8082                	ret

0000000080002c56 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	e04a                	sd	s2,0(sp)
    80002c60:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c62:	00235917          	auipc	s2,0x235
    80002c66:	68690913          	addi	s2,s2,1670 # 802382e8 <tickslock>
    80002c6a:	854a                	mv	a0,s2
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	152080e7          	jalr	338(ra) # 80000dbe <acquire>
  ticks++;
    80002c74:	00006497          	auipc	s1,0x6
    80002c78:	3bc48493          	addi	s1,s1,956 # 80009030 <ticks>
    80002c7c:	409c                	lw	a5,0(s1)
    80002c7e:	2785                	addiw	a5,a5,1
    80002c80:	c09c                	sw	a5,0(s1)
  update_time();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	4cc080e7          	jalr	1228(ra) # 8000214e <update_time>
  wakeup(&ticks);
    80002c8a:	8526                	mv	a0,s1
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	9ea080e7          	jalr	-1558(ra) # 80002676 <wakeup>
  release(&tickslock);
    80002c94:	854a                	mv	a0,s2
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	1dc080e7          	jalr	476(ra) # 80000e72 <release>
}
    80002c9e:	60e2                	ld	ra,24(sp)
    80002ca0:	6442                	ld	s0,16(sp)
    80002ca2:	64a2                	ld	s1,8(sp)
    80002ca4:	6902                	ld	s2,0(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002cb8:	00074d63          	bltz	a4,80002cd2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002cbc:	57fd                	li	a5,-1
    80002cbe:	17fe                	slli	a5,a5,0x3f
    80002cc0:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002cc2:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002cc4:	06f70363          	beq	a4,a5,80002d2a <devintr+0x80>
  }
}
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	64a2                	ld	s1,8(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret
      (scause & 0xff) == 9)
    80002cd2:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002cd6:	46a5                	li	a3,9
    80002cd8:	fed792e3          	bne	a5,a3,80002cbc <devintr+0x12>
    int irq = plic_claim();
    80002cdc:	00003097          	auipc	ra,0x3
    80002ce0:	7bc080e7          	jalr	1980(ra) # 80006498 <plic_claim>
    80002ce4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ce6:	47a9                	li	a5,10
    80002ce8:	02f50763          	beq	a0,a5,80002d16 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002cec:	4785                	li	a5,1
    80002cee:	02f50963          	beq	a0,a5,80002d20 <devintr+0x76>
    return 1;
    80002cf2:	4505                	li	a0,1
    else if (irq)
    80002cf4:	d8f1                	beqz	s1,80002cc8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cf6:	85a6                	mv	a1,s1
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	67050513          	addi	a0,a0,1648 # 80008368 <states.1753+0x38>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	888080e7          	jalr	-1912(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d08:	8526                	mv	a0,s1
    80002d0a:	00003097          	auipc	ra,0x3
    80002d0e:	7b2080e7          	jalr	1970(ra) # 800064bc <plic_complete>
    return 1;
    80002d12:	4505                	li	a0,1
    80002d14:	bf55                	j	80002cc8 <devintr+0x1e>
      uartintr();
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	c92080e7          	jalr	-878(ra) # 800009a8 <uartintr>
    80002d1e:	b7ed                	j	80002d08 <devintr+0x5e>
      virtio_disk_intr();
    80002d20:	00004097          	auipc	ra,0x4
    80002d24:	c7c080e7          	jalr	-900(ra) # 8000699c <virtio_disk_intr>
    80002d28:	b7c5                	j	80002d08 <devintr+0x5e>
    if (cpuid() == 0)
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	e78080e7          	jalr	-392(ra) # 80001ba2 <cpuid>
    80002d32:	c901                	beqz	a0,80002d42 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d34:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d3a:	14479073          	csrw	sip,a5
    return 2;
    80002d3e:	4509                	li	a0,2
    80002d40:	b761                	j	80002cc8 <devintr+0x1e>
      clockintr();
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	f14080e7          	jalr	-236(ra) # 80002c56 <clockintr>
    80002d4a:	b7ed                	j	80002d34 <devintr+0x8a>

0000000080002d4c <usertrap>:
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	e426                	sd	s1,8(sp)
    80002d54:	e04a                	sd	s2,0(sp)
    80002d56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d58:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d5c:	1007f793          	andi	a5,a5,256
    80002d60:	e3b5                	bnez	a5,80002dc4 <usertrap+0x78>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d62:	00003797          	auipc	a5,0x3
    80002d66:	62e78793          	addi	a5,a5,1582 # 80006390 <kernelvec>
    80002d6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	e60080e7          	jalr	-416(ra) # 80001bce <myproc>
    80002d76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d78:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d7a:	14102773          	csrr	a4,sepc
    80002d7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d80:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d84:	47a1                	li	a5,8
    80002d86:	04f71d63          	bne	a4,a5,80002de0 <usertrap+0x94>
    if (p->killed)
    80002d8a:	551c                	lw	a5,40(a0)
    80002d8c:	e7a1                	bnez	a5,80002dd4 <usertrap+0x88>
    p->trapframe->epc += 4;
    80002d8e:	6cb8                	ld	a4,88(s1)
    80002d90:	6f1c                	ld	a5,24(a4)
    80002d92:	0791                	addi	a5,a5,4
    80002d94:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d9e:	10079073          	csrw	sstatus,a5
    syscall();
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	396080e7          	jalr	918(ra) # 80003138 <syscall>
  if (p->killed)
    80002daa:	549c                	lw	a5,40(s1)
    80002dac:	14079363          	bnez	a5,80002ef2 <usertrap+0x1a6>
  usertrapret();
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	e08080e7          	jalr	-504(ra) # 80002bb8 <usertrapret>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6902                	ld	s2,0(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret
    panic("usertrap: not from user mode");
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	5c450513          	addi	a0,a0,1476 # 80008388 <states.1753+0x58>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	772080e7          	jalr	1906(ra) # 8000053e <panic>
      exit(-1);
    80002dd4:	557d                	li	a0,-1
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	970080e7          	jalr	-1680(ra) # 80002746 <exit>
    80002dde:	bf45                	j	80002d8e <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	eca080e7          	jalr	-310(ra) # 80002caa <devintr>
    80002de8:	892a                	mv	s2,a0
    80002dea:	10051163          	bnez	a0,80002eec <usertrap+0x1a0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dee:	14202773          	csrr	a4,scause
  else if(r_scause()==15){
    80002df2:	47bd                	li	a5,15
    80002df4:	0af70c63          	beq	a4,a5,80002eac <usertrap+0x160>
    80002df8:	14202773          	csrr	a4,scause
  else if(r_scause()==13)
    80002dfc:	47b5                	li	a5,13
    80002dfe:	0cf70463          	beq	a4,a5,80002ec6 <usertrap+0x17a>
    80002e02:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e06:	5890                	lw	a2,48(s1)
    80002e08:	00005517          	auipc	a0,0x5
    80002e0c:	5a050513          	addi	a0,a0,1440 # 800083a8 <states.1753+0x78>
    80002e10:	ffffd097          	auipc	ra,0xffffd
    80002e14:	778080e7          	jalr	1912(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e18:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e1c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e20:	00005517          	auipc	a0,0x5
    80002e24:	5b850513          	addi	a0,a0,1464 # 800083d8 <states.1753+0xa8>
    80002e28:	ffffd097          	auipc	ra,0xffffd
    80002e2c:	760080e7          	jalr	1888(ra) # 80000588 <printf>
    p->killed = 1;
    80002e30:	4785                	li	a5,1
    80002e32:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e34:	557d                	li	a0,-1
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	910080e7          	jalr	-1776(ra) # 80002746 <exit>
  if(which_dev == 2)
    80002e3e:	4789                	li	a5,2
    80002e40:	f6f918e3          	bne	s2,a5,80002db0 <usertrap+0x64>
    p->now_ticks+=1;
    80002e44:	1984a783          	lw	a5,408(s1)
    80002e48:	2785                	addiw	a5,a5,1
    80002e4a:	0007871b          	sext.w	a4,a5
    80002e4e:	18f4ac23          	sw	a5,408(s1)
    if(p->ticks > 0 && p->now_ticks >= p->ticks && p->is_sigalarm == 0)
    80002e52:	1944a783          	lw	a5,404(s1)
    80002e56:	04f05663          	blez	a5,80002ea2 <usertrap+0x156>
    80002e5a:	04f74463          	blt	a4,a5,80002ea2 <usertrap+0x156>
    80002e5e:	1904a783          	lw	a5,400(s1)
    80002e62:	e3a1                	bnez	a5,80002ea2 <usertrap+0x156>
      p->is_sigalarm = 1;
    80002e64:	4785                	li	a5,1
    80002e66:	18f4a823          	sw	a5,400(s1)
      p->now_ticks = 0;
    80002e6a:	1804ac23          	sw	zero,408(s1)
      *(p->trapframe_copy) = *(p->trapframe);
    80002e6e:	6cb4                	ld	a3,88(s1)
    80002e70:	87b6                	mv	a5,a3
    80002e72:	1a84b703          	ld	a4,424(s1)
    80002e76:	12068693          	addi	a3,a3,288
    80002e7a:	0007b803          	ld	a6,0(a5)
    80002e7e:	6788                	ld	a0,8(a5)
    80002e80:	6b8c                	ld	a1,16(a5)
    80002e82:	6f90                	ld	a2,24(a5)
    80002e84:	01073023          	sd	a6,0(a4)
    80002e88:	e708                	sd	a0,8(a4)
    80002e8a:	eb0c                	sd	a1,16(a4)
    80002e8c:	ef10                	sd	a2,24(a4)
    80002e8e:	02078793          	addi	a5,a5,32
    80002e92:	02070713          	addi	a4,a4,32
    80002e96:	fed792e3          	bne	a5,a3,80002e7a <usertrap+0x12e>
      p->trapframe->epc = p->handler;
    80002e9a:	6cbc                	ld	a5,88(s1)
    80002e9c:	1a04b703          	ld	a4,416(s1)
    80002ea0:	ef98                	sd	a4,24(a5)
    yield();
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	4c0080e7          	jalr	1216(ra) # 80002362 <yield>
    80002eaa:	b719                	j	80002db0 <usertrap+0x64>
    80002eac:	14302573          	csrr	a0,stval
    int res = pagefaulthandler(temp_supervisor,p->pagetable);
    80002eb0:	68ac                	ld	a1,80(s1)
    80002eb2:	00000097          	auipc	ra,0x0
    80002eb6:	c08080e7          	jalr	-1016(ra) # 80002aba <pagefaulthandler>
    if(res == -1 || res==-2){
    80002eba:	2509                	addiw	a0,a0,2
    80002ebc:	4785                	li	a5,1
    80002ebe:	eea7e6e3          	bltu	a5,a0,80002daa <usertrap+0x5e>
      p->killed=1;
    80002ec2:	d49c                	sw	a5,40(s1)
    80002ec4:	bf85                	j	80002e34 <usertrap+0xe8>
    80002ec6:	14302573          	csrr	a0,stval
    int res = pagefaulthandler(temp_supervisor,p->pagetable);
    80002eca:	68ac                	ld	a1,80(s1)
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	bee080e7          	jalr	-1042(ra) # 80002aba <pagefaulthandler>
    if(res == -1 )
    80002ed4:	57fd                	li	a5,-1
    80002ed6:	00f50863          	beq	a0,a5,80002ee6 <usertrap+0x19a>
    if(res == -2)
    80002eda:	57f9                	li	a5,-2
    80002edc:	ecf517e3          	bne	a0,a5,80002daa <usertrap+0x5e>
      p->killed = 1;
    80002ee0:	4785                	li	a5,1
    80002ee2:	d49c                	sw	a5,40(s1)
    80002ee4:	bf81                	j	80002e34 <usertrap+0xe8>
      p->killed = 1;
    80002ee6:	4785                	li	a5,1
    80002ee8:	d49c                	sw	a5,40(s1)
  if (p->killed)
    80002eea:	b7a9                	j	80002e34 <usertrap+0xe8>
    80002eec:	549c                	lw	a5,40(s1)
    80002eee:	dba1                	beqz	a5,80002e3e <usertrap+0xf2>
    80002ef0:	b791                	j	80002e34 <usertrap+0xe8>
    80002ef2:	4901                	li	s2,0
    80002ef4:	b781                	j	80002e34 <usertrap+0xe8>

0000000080002ef6 <kerneltrap>:
{
    80002ef6:	7179                	addi	sp,sp,-48
    80002ef8:	f406                	sd	ra,40(sp)
    80002efa:	f022                	sd	s0,32(sp)
    80002efc:	ec26                	sd	s1,24(sp)
    80002efe:	e84a                	sd	s2,16(sp)
    80002f00:	e44e                	sd	s3,8(sp)
    80002f02:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f04:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f08:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f0c:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f10:	1004f793          	andi	a5,s1,256
    80002f14:	cb85                	beqz	a5,80002f44 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f16:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f1a:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002f1c:	ef85                	bnez	a5,80002f54 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	d8c080e7          	jalr	-628(ra) # 80002caa <devintr>
    80002f26:	cd1d                	beqz	a0,80002f64 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f28:	4789                	li	a5,2
    80002f2a:	06f50a63          	beq	a0,a5,80002f9e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f2e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f32:	10049073          	csrw	sstatus,s1
}
    80002f36:	70a2                	ld	ra,40(sp)
    80002f38:	7402                	ld	s0,32(sp)
    80002f3a:	64e2                	ld	s1,24(sp)
    80002f3c:	6942                	ld	s2,16(sp)
    80002f3e:	69a2                	ld	s3,8(sp)
    80002f40:	6145                	addi	sp,sp,48
    80002f42:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f44:	00005517          	auipc	a0,0x5
    80002f48:	4b450513          	addi	a0,a0,1204 # 800083f8 <states.1753+0xc8>
    80002f4c:	ffffd097          	auipc	ra,0xffffd
    80002f50:	5f2080e7          	jalr	1522(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f54:	00005517          	auipc	a0,0x5
    80002f58:	4cc50513          	addi	a0,a0,1228 # 80008420 <states.1753+0xf0>
    80002f5c:	ffffd097          	auipc	ra,0xffffd
    80002f60:	5e2080e7          	jalr	1506(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f64:	85ce                	mv	a1,s3
    80002f66:	00005517          	auipc	a0,0x5
    80002f6a:	4da50513          	addi	a0,a0,1242 # 80008440 <states.1753+0x110>
    80002f6e:	ffffd097          	auipc	ra,0xffffd
    80002f72:	61a080e7          	jalr	1562(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f76:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f7a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	4d250513          	addi	a0,a0,1234 # 80008450 <states.1753+0x120>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	602080e7          	jalr	1538(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f8e:	00005517          	auipc	a0,0x5
    80002f92:	4da50513          	addi	a0,a0,1242 # 80008468 <states.1753+0x138>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5a8080e7          	jalr	1448(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	c30080e7          	jalr	-976(ra) # 80001bce <myproc>
    80002fa6:	d541                	beqz	a0,80002f2e <kerneltrap+0x38>
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	c26080e7          	jalr	-986(ra) # 80001bce <myproc>
    80002fb0:	4d18                	lw	a4,24(a0)
    80002fb2:	4791                	li	a5,4
    80002fb4:	f6f71de3          	bne	a4,a5,80002f2e <kerneltrap+0x38>
    yield();
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	3aa080e7          	jalr	938(ra) # 80002362 <yield>
    80002fc0:	b7bd                	j	80002f2e <kerneltrap+0x38>

0000000080002fc2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fc2:	1101                	addi	sp,sp,-32
    80002fc4:	ec06                	sd	ra,24(sp)
    80002fc6:	e822                	sd	s0,16(sp)
    80002fc8:	e426                	sd	s1,8(sp)
    80002fca:	1000                	addi	s0,sp,32
    80002fcc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	c00080e7          	jalr	-1024(ra) # 80001bce <myproc>
  switch (n)
    80002fd6:	4795                	li	a5,5
    80002fd8:	0497e163          	bltu	a5,s1,8000301a <argraw+0x58>
    80002fdc:	048a                	slli	s1,s1,0x2
    80002fde:	00005717          	auipc	a4,0x5
    80002fe2:	5d270713          	addi	a4,a4,1490 # 800085b0 <states.1753+0x280>
    80002fe6:	94ba                	add	s1,s1,a4
    80002fe8:	409c                	lw	a5,0(s1)
    80002fea:	97ba                	add	a5,a5,a4
    80002fec:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002fee:	6d3c                	ld	a5,88(a0)
    80002ff0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ff2:	60e2                	ld	ra,24(sp)
    80002ff4:	6442                	ld	s0,16(sp)
    80002ff6:	64a2                	ld	s1,8(sp)
    80002ff8:	6105                	addi	sp,sp,32
    80002ffa:	8082                	ret
    return p->trapframe->a1;
    80002ffc:	6d3c                	ld	a5,88(a0)
    80002ffe:	7fa8                	ld	a0,120(a5)
    80003000:	bfcd                	j	80002ff2 <argraw+0x30>
    return p->trapframe->a2;
    80003002:	6d3c                	ld	a5,88(a0)
    80003004:	63c8                	ld	a0,128(a5)
    80003006:	b7f5                	j	80002ff2 <argraw+0x30>
    return p->trapframe->a3;
    80003008:	6d3c                	ld	a5,88(a0)
    8000300a:	67c8                	ld	a0,136(a5)
    8000300c:	b7dd                	j	80002ff2 <argraw+0x30>
    return p->trapframe->a4;
    8000300e:	6d3c                	ld	a5,88(a0)
    80003010:	6bc8                	ld	a0,144(a5)
    80003012:	b7c5                	j	80002ff2 <argraw+0x30>
    return p->trapframe->a5;
    80003014:	6d3c                	ld	a5,88(a0)
    80003016:	6fc8                	ld	a0,152(a5)
    80003018:	bfe9                	j	80002ff2 <argraw+0x30>
  panic("argraw");
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	45e50513          	addi	a0,a0,1118 # 80008478 <states.1753+0x148>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	51c080e7          	jalr	1308(ra) # 8000053e <panic>

000000008000302a <fetchaddr>:
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	e04a                	sd	s2,0(sp)
    80003034:	1000                	addi	s0,sp,32
    80003036:	84aa                	mv	s1,a0
    80003038:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	b94080e7          	jalr	-1132(ra) # 80001bce <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80003042:	653c                	ld	a5,72(a0)
    80003044:	02f4f863          	bgeu	s1,a5,80003074 <fetchaddr+0x4a>
    80003048:	00848713          	addi	a4,s1,8
    8000304c:	02e7e663          	bltu	a5,a4,80003078 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003050:	46a1                	li	a3,8
    80003052:	8626                	mv	a2,s1
    80003054:	85ca                	mv	a1,s2
    80003056:	6928                	ld	a0,80(a0)
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	8c0080e7          	jalr	-1856(ra) # 80001918 <copyin>
    80003060:	00a03533          	snez	a0,a0
    80003064:	40a00533          	neg	a0,a0
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6902                	ld	s2,0(sp)
    80003070:	6105                	addi	sp,sp,32
    80003072:	8082                	ret
    return -1;
    80003074:	557d                	li	a0,-1
    80003076:	bfcd                	j	80003068 <fetchaddr+0x3e>
    80003078:	557d                	li	a0,-1
    8000307a:	b7fd                	j	80003068 <fetchaddr+0x3e>

000000008000307c <fetchstr>:
{
    8000307c:	7179                	addi	sp,sp,-48
    8000307e:	f406                	sd	ra,40(sp)
    80003080:	f022                	sd	s0,32(sp)
    80003082:	ec26                	sd	s1,24(sp)
    80003084:	e84a                	sd	s2,16(sp)
    80003086:	e44e                	sd	s3,8(sp)
    80003088:	1800                	addi	s0,sp,48
    8000308a:	892a                	mv	s2,a0
    8000308c:	84ae                	mv	s1,a1
    8000308e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	b3e080e7          	jalr	-1218(ra) # 80001bce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003098:	86ce                	mv	a3,s3
    8000309a:	864a                	mv	a2,s2
    8000309c:	85a6                	mv	a1,s1
    8000309e:	6928                	ld	a0,80(a0)
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	904080e7          	jalr	-1788(ra) # 800019a4 <copyinstr>
  if (err < 0)
    800030a8:	00054763          	bltz	a0,800030b6 <fetchstr+0x3a>
  return strlen(buf);
    800030ac:	8526                	mv	a0,s1
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	f90080e7          	jalr	-112(ra) # 8000103e <strlen>
}
    800030b6:	70a2                	ld	ra,40(sp)
    800030b8:	7402                	ld	s0,32(sp)
    800030ba:	64e2                	ld	s1,24(sp)
    800030bc:	6942                	ld	s2,16(sp)
    800030be:	69a2                	ld	s3,8(sp)
    800030c0:	6145                	addi	sp,sp,48
    800030c2:	8082                	ret

00000000800030c4 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	e426                	sd	s1,8(sp)
    800030cc:	1000                	addi	s0,sp,32
    800030ce:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030d0:	00000097          	auipc	ra,0x0
    800030d4:	ef2080e7          	jalr	-270(ra) # 80002fc2 <argraw>
    800030d8:	c088                	sw	a0,0(s1)
  return 0;
}
    800030da:	4501                	li	a0,0
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	64a2                	ld	s1,8(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret

00000000800030e6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030f2:	00000097          	auipc	ra,0x0
    800030f6:	ed0080e7          	jalr	-304(ra) # 80002fc2 <argraw>
    800030fa:	e088                	sd	a0,0(s1)
  return 0;
}
    800030fc:	4501                	li	a0,0
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret

0000000080003108 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	e04a                	sd	s2,0(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84ae                	mv	s1,a1
    80003116:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	eaa080e7          	jalr	-342(ra) # 80002fc2 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003120:	864a                	mv	a2,s2
    80003122:	85a6                	mv	a1,s1
    80003124:	00000097          	auipc	ra,0x0
    80003128:	f58080e7          	jalr	-168(ra) # 8000307c <fetchstr>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6902                	ld	s2,0(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret

0000000080003138 <syscall>:

static char *syscallnames[]={"","fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","trace","waitx","set_priority","sigalarm","sigreturn"};
static int sysparameters[]={0,0,1,1,1,3,1,2,2,1,1,0,1,1,0,2,3,3,1,2,1,1,1,3,2,2,0};

void syscall(void)
{
    80003138:	715d                	addi	sp,sp,-80
    8000313a:	e486                	sd	ra,72(sp)
    8000313c:	e0a2                	sd	s0,64(sp)
    8000313e:	fc26                	sd	s1,56(sp)
    80003140:	f84a                	sd	s2,48(sp)
    80003142:	f44e                	sd	s3,40(sp)
    80003144:	f052                	sd	s4,32(sp)
    80003146:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    80003148:	fffff097          	auipc	ra,0xfffff
    8000314c:	a86080e7          	jalr	-1402(ra) # 80001bce <myproc>
    80003150:	89aa                	mv	s3,a0

  int parameterarr[]={p->trapframe->a0,p->trapframe->a1,p->trapframe->a2,p->trapframe->a3,p->trapframe->a4,p->trapframe->a5};
    80003152:	6d24                	ld	s1,88(a0)
    80003154:	78bc                	ld	a5,112(s1)
    80003156:	faf42c23          	sw	a5,-72(s0)
    8000315a:	7cbc                	ld	a5,120(s1)
    8000315c:	faf42e23          	sw	a5,-68(s0)
    80003160:	60dc                	ld	a5,128(s1)
    80003162:	fcf42023          	sw	a5,-64(s0)
    80003166:	64dc                	ld	a5,136(s1)
    80003168:	fcf42223          	sw	a5,-60(s0)
    8000316c:	68dc                	ld	a5,144(s1)
    8000316e:	fcf42423          	sw	a5,-56(s0)
    80003172:	6cdc                	ld	a5,152(s1)
    80003174:	fcf42623          	sw	a5,-52(s0)

  num = p->trapframe->a7;
    80003178:	74dc                	ld	a5,168(s1)
    8000317a:	0007891b          	sext.w	s2,a5

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000317e:	37fd                	addiw	a5,a5,-1
    80003180:	4765                	li	a4,25
    80003182:	0af76a63          	bltu	a4,a5,80003236 <syscall+0xfe>
    80003186:	00391713          	slli	a4,s2,0x3
    8000318a:	00005797          	auipc	a5,0x5
    8000318e:	43e78793          	addi	a5,a5,1086 # 800085c8 <syscalls>
    80003192:	97ba                	add	a5,a5,a4
    80003194:	639c                	ld	a5,0(a5)
    80003196:	c3c5                	beqz	a5,80003236 <syscall+0xfe>
  {
    p->trapframe->a0 = syscalls[num]();
    80003198:	9782                	jalr	a5
    8000319a:	f8a8                	sd	a0,112(s1)

    int divisor = 1;

    for(int i = 0 ; i < num ; i++)
    8000319c:	09205b63          	blez	s2,80003232 <syscall+0xfa>
    800031a0:	4781                	li	a5,0
    int divisor = 1;
    800031a2:	4705                	li	a4,1
    {
      divisor*=2;
    800031a4:	0017171b          	slliw	a4,a4,0x1
    for(int i = 0 ; i < num ; i++)
    800031a8:	2785                	addiw	a5,a5,1
    800031aa:	fef91de3          	bne	s2,a5,800031a4 <syscall+0x6c>
    }

    if ((((p->trace_mask)/divisor)&1)==1)
    800031ae:	1689a783          	lw	a5,360(s3)
    800031b2:	02e7c73b          	divw	a4,a5,a4
    800031b6:	8b05                	andi	a4,a4,1
    800031b8:	c345                	beqz	a4,80003258 <syscall+0x120>
    {
      // printf("mask= %d divisor= %d\n",p->mask,divisor);
      printf("%d: syscall %s ( ",p->pid,syscallnames[num]);
    800031ba:	00005497          	auipc	s1,0x5
    800031be:	40e48493          	addi	s1,s1,1038 # 800085c8 <syscalls>
    800031c2:	00391793          	slli	a5,s2,0x3
    800031c6:	97a6                	add	a5,a5,s1
    800031c8:	6ff0                	ld	a2,216(a5)
    800031ca:	0309a583          	lw	a1,48(s3)
    800031ce:	00005517          	auipc	a0,0x5
    800031d2:	2b250513          	addi	a0,a0,690 # 80008480 <states.1753+0x150>
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	3b2080e7          	jalr	946(ra) # 80000588 <printf>

      for (int i = 0; i < sysparameters[num]; i++)
    800031de:	090a                	slli	s2,s2,0x2
    800031e0:	94ca                	add	s1,s1,s2
    800031e2:	1b04a783          	lw	a5,432(s1)
    800031e6:	02f05a63          	blez	a5,8000321a <syscall+0xe2>
    800031ea:	fb840493          	addi	s1,s0,-72
    800031ee:	fff7891b          	addiw	s2,a5,-1
    800031f2:	1902                	slli	s2,s2,0x20
    800031f4:	02095913          	srli	s2,s2,0x20
    800031f8:	090a                	slli	s2,s2,0x2
    800031fa:	fbc40793          	addi	a5,s0,-68
    800031fe:	993e                	add	s2,s2,a5
      {
        printf("%d ",parameterarr[i]);
    80003200:	00005a17          	auipc	s4,0x5
    80003204:	298a0a13          	addi	s4,s4,664 # 80008498 <states.1753+0x168>
    80003208:	408c                	lw	a1,0(s1)
    8000320a:	8552                	mv	a0,s4
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	37c080e7          	jalr	892(ra) # 80000588 <printf>
      for (int i = 0; i < sysparameters[num]; i++)
    80003214:	0491                	addi	s1,s1,4
    80003216:	ff2499e3          	bne	s1,s2,80003208 <syscall+0xd0>
      }
      
      printf(") -> %d\n",p->trapframe->a0);
    8000321a:	0589b783          	ld	a5,88(s3)
    8000321e:	7bac                	ld	a1,112(a5)
    80003220:	00005517          	auipc	a0,0x5
    80003224:	28050513          	addi	a0,a0,640 # 800084a0 <states.1753+0x170>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	360080e7          	jalr	864(ra) # 80000588 <printf>
    80003230:	a025                	j	80003258 <syscall+0x120>
    int divisor = 1;
    80003232:	4705                	li	a4,1
    80003234:	bfad                	j	800031ae <syscall+0x76>
    }
    
    
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003236:	86ca                	mv	a3,s2
    80003238:	15898613          	addi	a2,s3,344
    8000323c:	0309a583          	lw	a1,48(s3)
    80003240:	00005517          	auipc	a0,0x5
    80003244:	27050513          	addi	a0,a0,624 # 800084b0 <states.1753+0x180>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	340080e7          	jalr	832(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003250:	0589b783          	ld	a5,88(s3)
    80003254:	577d                	li	a4,-1
    80003256:	fbb8                	sd	a4,112(a5)
  }
}
    80003258:	60a6                	ld	ra,72(sp)
    8000325a:	6406                	ld	s0,64(sp)
    8000325c:	74e2                	ld	s1,56(sp)
    8000325e:	7942                	ld	s2,48(sp)
    80003260:	79a2                	ld	s3,40(sp)
    80003262:	7a02                	ld	s4,32(sp)
    80003264:	6161                	addi	sp,sp,80
    80003266:	8082                	ret

0000000080003268 <sys_exit>:
#include "proc.h"
#include "syscall.h"

uint64
sys_exit(void)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80003270:	fec40593          	addi	a1,s0,-20
    80003274:	4501                	li	a0,0
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	e4e080e7          	jalr	-434(ra) # 800030c4 <argint>
    return -1;
    8000327e:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80003280:	00054963          	bltz	a0,80003292 <sys_exit+0x2a>
  exit(n);
    80003284:	fec42503          	lw	a0,-20(s0)
    80003288:	fffff097          	auipc	ra,0xfffff
    8000328c:	4be080e7          	jalr	1214(ra) # 80002746 <exit>
  return 0; // not reached
    80003290:	4781                	li	a5,0
}
    80003292:	853e                	mv	a0,a5
    80003294:	60e2                	ld	ra,24(sp)
    80003296:	6442                	ld	s0,16(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret

000000008000329c <sys_getpid>:

// const cinfo info_exit = {.name = "exit", .argc = 1};

uint64
sys_getpid(void)
{
    8000329c:	1141                	addi	sp,sp,-16
    8000329e:	e406                	sd	ra,8(sp)
    800032a0:	e022                	sd	s0,0(sp)
    800032a2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032a4:	fffff097          	auipc	ra,0xfffff
    800032a8:	92a080e7          	jalr	-1750(ra) # 80001bce <myproc>
}
    800032ac:	5908                	lw	a0,48(a0)
    800032ae:	60a2                	ld	ra,8(sp)
    800032b0:	6402                	ld	s0,0(sp)
    800032b2:	0141                	addi	sp,sp,16
    800032b4:	8082                	ret

00000000800032b6 <sys_fork>:

// const cinfo info_getpid = {.name = "getpid", .argc = 0};

uint64
sys_fork(void)
{
    800032b6:	1141                	addi	sp,sp,-16
    800032b8:	e406                	sd	ra,8(sp)
    800032ba:	e022                	sd	s0,0(sp)
    800032bc:	0800                	addi	s0,sp,16
  return fork();
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	d4c080e7          	jalr	-692(ra) # 8000200a <fork>
}
    800032c6:	60a2                	ld	ra,8(sp)
    800032c8:	6402                	ld	s0,0(sp)
    800032ca:	0141                	addi	sp,sp,16
    800032cc:	8082                	ret

00000000800032ce <sys_wait>:

// const cinfo info_fork = {.name = "fork", .argc = 0};

uint64
sys_wait(void)
{
    800032ce:	1101                	addi	sp,sp,-32
    800032d0:	ec06                	sd	ra,24(sp)
    800032d2:	e822                	sd	s0,16(sp)
    800032d4:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    800032d6:	fe840593          	addi	a1,s0,-24
    800032da:	4501                	li	a0,0
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	e0a080e7          	jalr	-502(ra) # 800030e6 <argaddr>
    800032e4:	87aa                	mv	a5,a0
    return -1;
    800032e6:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    800032e8:	0007c863          	bltz	a5,800032f8 <sys_wait+0x2a>
  return wait(p);
    800032ec:	fe843503          	ld	a0,-24(s0)
    800032f0:	fffff097          	auipc	ra,0xfffff
    800032f4:	112080e7          	jalr	274(ra) # 80002402 <wait>
}
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret

0000000080003300 <sys_sbrk>:

// const cinfo info_wait = {.name = "wait", .argc = 1};

uint64
sys_sbrk(void)
{
    80003300:	7179                	addi	sp,sp,-48
    80003302:	f406                	sd	ra,40(sp)
    80003304:	f022                	sd	s0,32(sp)
    80003306:	ec26                	sd	s1,24(sp)
    80003308:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    8000330a:	fdc40593          	addi	a1,s0,-36
    8000330e:	4501                	li	a0,0
    80003310:	00000097          	auipc	ra,0x0
    80003314:	db4080e7          	jalr	-588(ra) # 800030c4 <argint>
    80003318:	87aa                	mv	a5,a0
    return -1;
    8000331a:	557d                	li	a0,-1
  if (argint(0, &n) < 0)
    8000331c:	0207c063          	bltz	a5,8000333c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003320:	fffff097          	auipc	ra,0xfffff
    80003324:	8ae080e7          	jalr	-1874(ra) # 80001bce <myproc>
    80003328:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    8000332a:	fdc42503          	lw	a0,-36(s0)
    8000332e:	fffff097          	auipc	ra,0xfffff
    80003332:	c68080e7          	jalr	-920(ra) # 80001f96 <growproc>
    80003336:	00054863          	bltz	a0,80003346 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000333a:	8526                	mv	a0,s1
}
    8000333c:	70a2                	ld	ra,40(sp)
    8000333e:	7402                	ld	s0,32(sp)
    80003340:	64e2                	ld	s1,24(sp)
    80003342:	6145                	addi	sp,sp,48
    80003344:	8082                	ret
    return -1;
    80003346:	557d                	li	a0,-1
    80003348:	bfd5                	j	8000333c <sys_sbrk+0x3c>

000000008000334a <sys_sleep>:

// const cinfo info_sbrk = {.name = "sbrk", .argc = 1};

uint64
sys_sleep(void)
{
    8000334a:	7139                	addi	sp,sp,-64
    8000334c:	fc06                	sd	ra,56(sp)
    8000334e:	f822                	sd	s0,48(sp)
    80003350:	f426                	sd	s1,40(sp)
    80003352:	f04a                	sd	s2,32(sp)
    80003354:	ec4e                	sd	s3,24(sp)
    80003356:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80003358:	fcc40593          	addi	a1,s0,-52
    8000335c:	4501                	li	a0,0
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	d66080e7          	jalr	-666(ra) # 800030c4 <argint>
    return -1;
    80003366:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80003368:	06054563          	bltz	a0,800033d2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000336c:	00235517          	auipc	a0,0x235
    80003370:	f7c50513          	addi	a0,a0,-132 # 802382e8 <tickslock>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	a4a080e7          	jalr	-1462(ra) # 80000dbe <acquire>
  ticks0 = ticks;
    8000337c:	00006917          	auipc	s2,0x6
    80003380:	cb492903          	lw	s2,-844(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    80003384:	fcc42783          	lw	a5,-52(s0)
    80003388:	cf85                	beqz	a5,800033c0 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000338a:	00235997          	auipc	s3,0x235
    8000338e:	f5e98993          	addi	s3,s3,-162 # 802382e8 <tickslock>
    80003392:	00006497          	auipc	s1,0x6
    80003396:	c9e48493          	addi	s1,s1,-866 # 80009030 <ticks>
    if (myproc()->killed)
    8000339a:	fffff097          	auipc	ra,0xfffff
    8000339e:	834080e7          	jalr	-1996(ra) # 80001bce <myproc>
    800033a2:	551c                	lw	a5,40(a0)
    800033a4:	ef9d                	bnez	a5,800033e2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033a6:	85ce                	mv	a1,s3
    800033a8:	8526                	mv	a0,s1
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	ff4080e7          	jalr	-12(ra) # 8000239e <sleep>
  while (ticks - ticks0 < n)
    800033b2:	409c                	lw	a5,0(s1)
    800033b4:	412787bb          	subw	a5,a5,s2
    800033b8:	fcc42703          	lw	a4,-52(s0)
    800033bc:	fce7efe3          	bltu	a5,a4,8000339a <sys_sleep+0x50>
  }
  release(&tickslock);
    800033c0:	00235517          	auipc	a0,0x235
    800033c4:	f2850513          	addi	a0,a0,-216 # 802382e8 <tickslock>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	aaa080e7          	jalr	-1366(ra) # 80000e72 <release>
  return 0;
    800033d0:	4781                	li	a5,0
}
    800033d2:	853e                	mv	a0,a5
    800033d4:	70e2                	ld	ra,56(sp)
    800033d6:	7442                	ld	s0,48(sp)
    800033d8:	74a2                	ld	s1,40(sp)
    800033da:	7902                	ld	s2,32(sp)
    800033dc:	69e2                	ld	s3,24(sp)
    800033de:	6121                	addi	sp,sp,64
    800033e0:	8082                	ret
      release(&tickslock);
    800033e2:	00235517          	auipc	a0,0x235
    800033e6:	f0650513          	addi	a0,a0,-250 # 802382e8 <tickslock>
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	a88080e7          	jalr	-1400(ra) # 80000e72 <release>
      return -1;
    800033f2:	57fd                	li	a5,-1
    800033f4:	bff9                	j	800033d2 <sys_sleep+0x88>

00000000800033f6 <sys_kill>:

// const cinfo info_sleep = {.name = "sleep", .argc = 1};

uint64
sys_kill(void)
{
    800033f6:	1101                	addi	sp,sp,-32
    800033f8:	ec06                	sd	ra,24(sp)
    800033fa:	e822                	sd	s0,16(sp)
    800033fc:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    800033fe:	fec40593          	addi	a1,s0,-20
    80003402:	4501                	li	a0,0
    80003404:	00000097          	auipc	ra,0x0
    80003408:	cc0080e7          	jalr	-832(ra) # 800030c4 <argint>
    8000340c:	87aa                	mv	a5,a0
    return -1;
    8000340e:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80003410:	0007c863          	bltz	a5,80003420 <sys_kill+0x2a>
  return kill(pid);
    80003414:	fec42503          	lw	a0,-20(s0)
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	410080e7          	jalr	1040(ra) # 80002828 <kill>
}
    80003420:	60e2                	ld	ra,24(sp)
    80003422:	6442                	ld	s0,16(sp)
    80003424:	6105                	addi	sp,sp,32
    80003426:	8082                	ret

0000000080003428 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003428:	1101                	addi	sp,sp,-32
    8000342a:	ec06                	sd	ra,24(sp)
    8000342c:	e822                	sd	s0,16(sp)
    8000342e:	e426                	sd	s1,8(sp)
    80003430:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003432:	00235517          	auipc	a0,0x235
    80003436:	eb650513          	addi	a0,a0,-330 # 802382e8 <tickslock>
    8000343a:	ffffe097          	auipc	ra,0xffffe
    8000343e:	984080e7          	jalr	-1660(ra) # 80000dbe <acquire>
  xticks = ticks;
    80003442:	00006497          	auipc	s1,0x6
    80003446:	bee4a483          	lw	s1,-1042(s1) # 80009030 <ticks>
  release(&tickslock);
    8000344a:	00235517          	auipc	a0,0x235
    8000344e:	e9e50513          	addi	a0,a0,-354 # 802382e8 <tickslock>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	a20080e7          	jalr	-1504(ra) # 80000e72 <release>
  return xticks;
}
    8000345a:	02049513          	slli	a0,s1,0x20
    8000345e:	9101                	srli	a0,a0,0x20
    80003460:	60e2                	ld	ra,24(sp)
    80003462:	6442                	ld	s0,16(sp)
    80003464:	64a2                	ld	s1,8(sp)
    80003466:	6105                	addi	sp,sp,32
    80003468:	8082                	ret

000000008000346a <sys_trace>:

// const cinfo info_uptime = {.name = "uptime", .argc = 0};

uint64
sys_trace(void)
{
    8000346a:	1101                	addi	sp,sp,-32
    8000346c:	ec06                	sd	ra,24(sp)
    8000346e:	e822                	sd	s0,16(sp)
    80003470:	1000                	addi	s0,sp,32
  int a;

  int ret = argint(0,&a);
    80003472:	fec40593          	addi	a1,s0,-20
    80003476:	4501                	li	a0,0
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	c4c080e7          	jalr	-948(ra) # 800030c4 <argint>

  if(ret < 0 )
  {
    return -1;
    80003480:	57fd                	li	a5,-1
  if(ret < 0 )
    80003482:	00054b63          	bltz	a0,80003498 <sys_trace+0x2e>
  }

  myproc()->trace_mask = a;
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	748080e7          	jalr	1864(ra) # 80001bce <myproc>
    8000348e:	fec42783          	lw	a5,-20(s0)
    80003492:	16f52423          	sw	a5,360(a0)

  return 0;
    80003496:	4781                	li	a5,0
}
    80003498:	853e                	mv	a0,a5
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	6105                	addi	sp,sp,32
    800034a0:	8082                	ret

00000000800034a2 <sys_waitx>:

// const cinfo info_trace = {.name = "trace", .argc = 0};

uint64
sys_waitx(void)
{
    800034a2:	7139                	addi	sp,sp,-64
    800034a4:	fc06                	sd	ra,56(sp)
    800034a6:	f822                	sd	s0,48(sp)
    800034a8:	f426                	sd	s1,40(sp)
    800034aa:	f04a                	sd	s2,32(sp)
    800034ac:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if (argaddr(0, &addr) < 0)
    800034ae:	fd840593          	addi	a1,s0,-40
    800034b2:	4501                	li	a0,0
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	c32080e7          	jalr	-974(ra) # 800030e6 <argaddr>
    return -1;
    800034bc:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0)
    800034be:	08054063          	bltz	a0,8000353e <sys_waitx+0x9c>
  if (argaddr(1, &addr1) < 0) // user virtual memory
    800034c2:	fd040593          	addi	a1,s0,-48
    800034c6:	4505                	li	a0,1
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	c1e080e7          	jalr	-994(ra) # 800030e6 <argaddr>
    return -1;
    800034d0:	57fd                	li	a5,-1
  if (argaddr(1, &addr1) < 0) // user virtual memory
    800034d2:	06054663          	bltz	a0,8000353e <sys_waitx+0x9c>
  if (argaddr(2, &addr2) < 0)
    800034d6:	fc840593          	addi	a1,s0,-56
    800034da:	4509                	li	a0,2
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	c0a080e7          	jalr	-1014(ra) # 800030e6 <argaddr>
    return -1;
    800034e4:	57fd                	li	a5,-1
  if (argaddr(2, &addr2) < 0)
    800034e6:	04054c63          	bltz	a0,8000353e <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    800034ea:	fc040613          	addi	a2,s0,-64
    800034ee:	fc440593          	addi	a1,s0,-60
    800034f2:	fd843503          	ld	a0,-40(s0)
    800034f6:	fffff097          	auipc	ra,0xfffff
    800034fa:	034080e7          	jalr	52(ra) # 8000252a <waitx>
    800034fe:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003500:	ffffe097          	auipc	ra,0xffffe
    80003504:	6ce080e7          	jalr	1742(ra) # 80001bce <myproc>
    80003508:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000350a:	4691                	li	a3,4
    8000350c:	fc440613          	addi	a2,s0,-60
    80003510:	fd043583          	ld	a1,-48(s0)
    80003514:	6928                	ld	a0,80(a0)
    80003516:	ffffe097          	auipc	ra,0xffffe
    8000351a:	33e080e7          	jalr	830(ra) # 80001854 <copyout>
    return -1;
    8000351e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003520:	00054f63          	bltz	a0,8000353e <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003524:	4691                	li	a3,4
    80003526:	fc040613          	addi	a2,s0,-64
    8000352a:	fc843583          	ld	a1,-56(s0)
    8000352e:	68a8                	ld	a0,80(s1)
    80003530:	ffffe097          	auipc	ra,0xffffe
    80003534:	324080e7          	jalr	804(ra) # 80001854 <copyout>
    80003538:	00054a63          	bltz	a0,8000354c <sys_waitx+0xaa>
    return -1;
  return ret;
    8000353c:	87ca                	mv	a5,s2
}
    8000353e:	853e                	mv	a0,a5
    80003540:	70e2                	ld	ra,56(sp)
    80003542:	7442                	ld	s0,48(sp)
    80003544:	74a2                	ld	s1,40(sp)
    80003546:	7902                	ld	s2,32(sp)
    80003548:	6121                	addi	sp,sp,64
    8000354a:	8082                	ret
    return -1;
    8000354c:	57fd                	li	a5,-1
    8000354e:	bfc5                	j	8000353e <sys_waitx+0x9c>

0000000080003550 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003550:	1101                	addi	sp,sp,-32
    80003552:	ec06                	sd	ra,24(sp)
    80003554:	e822                	sd	s0,16(sp)
    80003556:	1000                	addi	s0,sp,32
  int np, pid, ret = -1;
  struct proc *p;
  extern struct proc proc[];

  if (argint(0, &np) < 0)
    80003558:	fec40593          	addi	a1,s0,-20
    8000355c:	4501                	li	a0,0
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	b66080e7          	jalr	-1178(ra) # 800030c4 <argint>
    80003566:	87aa                	mv	a5,a0
    return -1;
    80003568:	557d                	li	a0,-1
  if (argint(0, &np) < 0)
    8000356a:	0407cb63          	bltz	a5,800035c0 <sys_set_priority+0x70>
  if (argint(1, &pid) < 0)
    8000356e:	fe840593          	addi	a1,s0,-24
    80003572:	4505                	li	a0,1
    80003574:	00000097          	auipc	ra,0x0
    80003578:	b50080e7          	jalr	-1200(ra) # 800030c4 <argint>
    8000357c:	04054163          	bltz	a0,800035be <sys_set_priority+0x6e>
    return -1;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->pid == pid)
    80003580:	fe842603          	lw	a2,-24(s0)
    {
      ret = p->stp;
      p->nice = 5;
      p->ntime = 0;
      p->stp = np;
    80003584:	fec42803          	lw	a6,-20(s0)
  for (p = proc; p < &proc[NPROC]; p++)
    80003588:	0022e797          	auipc	a5,0x22e
    8000358c:	16078793          	addi	a5,a5,352 # 802316e8 <proc>
  int np, pid, ret = -1;
    80003590:	557d                	li	a0,-1
      p->nice = 5;
    80003592:	4595                	li	a1,5
  for (p = proc; p < &proc[NPROC]; p++)
    80003594:	00235697          	auipc	a3,0x235
    80003598:	d5468693          	addi	a3,a3,-684 # 802382e8 <tickslock>
    8000359c:	a029                	j	800035a6 <sys_set_priority+0x56>
    8000359e:	1b078793          	addi	a5,a5,432
    800035a2:	00d78f63          	beq	a5,a3,800035c0 <sys_set_priority+0x70>
    if (p->pid == pid)
    800035a6:	5b98                	lw	a4,48(a5)
    800035a8:	fec71be3          	bne	a4,a2,8000359e <sys_set_priority+0x4e>
      ret = p->stp;
    800035ac:	18c7a503          	lw	a0,396(a5)
      p->nice = 5;
    800035b0:	18b7a423          	sw	a1,392(a5)
      p->ntime = 0;
    800035b4:	1807a023          	sw	zero,384(a5)
      p->stp = np;
    800035b8:	1907a623          	sw	a6,396(a5)
    800035bc:	b7cd                	j	8000359e <sys_set_priority+0x4e>
    return -1;
    800035be:	557d                	li	a0,-1
    }
  }

  return ret;
}
    800035c0:	60e2                	ld	ra,24(sp)
    800035c2:	6442                	ld	s0,16(sp)
    800035c4:	6105                	addi	sp,sp,32
    800035c6:	8082                	ret

00000000800035c8 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    800035c8:	1141                	addi	sp,sp,-16
    800035ca:	e406                	sd	ra,8(sp)
    800035cc:	e022                	sd	s0,0(sp)
    800035ce:	0800                	addi	s0,sp,16
  struct proc*p = myproc();
    800035d0:	ffffe097          	auipc	ra,0xffffe
    800035d4:	5fe080e7          	jalr	1534(ra) # 80001bce <myproc>

  // Copy kernel
  p->trapframe_copy->kernel_hartid = p->trapframe->kernel_hartid;
    800035d8:	1a853783          	ld	a5,424(a0)
    800035dc:	6d38                	ld	a4,88(a0)
    800035de:	7318                	ld	a4,32(a4)
    800035e0:	f398                	sd	a4,32(a5)
  p->trapframe_copy->kernel_satp = p->trapframe->kernel_satp;
    800035e2:	1a853783          	ld	a5,424(a0)
    800035e6:	6d38                	ld	a4,88(a0)
    800035e8:	6318                	ld	a4,0(a4)
    800035ea:	e398                	sd	a4,0(a5)
  p->trapframe_copy->kernel_sp = p->trapframe->kernel_sp;
    800035ec:	1a853783          	ld	a5,424(a0)
    800035f0:	6d38                	ld	a4,88(a0)
    800035f2:	6718                	ld	a4,8(a4)
    800035f4:	e798                	sd	a4,8(a5)
  p->trapframe_copy->kernel_trap= p->trapframe->kernel_trap;
    800035f6:	1a853783          	ld	a5,424(a0)
    800035fa:	6d38                	ld	a4,88(a0)
    800035fc:	6b18                	ld	a4,16(a4)
    800035fe:	eb98                	sd	a4,16(a5)

  *(p->trapframe) = *(p->trapframe_copy);
    80003600:	1a853683          	ld	a3,424(a0)
    80003604:	87b6                	mv	a5,a3
    80003606:	6d38                	ld	a4,88(a0)
    80003608:	12068693          	addi	a3,a3,288
    8000360c:	0007b883          	ld	a7,0(a5)
    80003610:	0087b803          	ld	a6,8(a5)
    80003614:	6b8c                	ld	a1,16(a5)
    80003616:	6f90                	ld	a2,24(a5)
    80003618:	01173023          	sd	a7,0(a4)
    8000361c:	01073423          	sd	a6,8(a4)
    80003620:	eb0c                	sd	a1,16(a4)
    80003622:	ef10                	sd	a2,24(a4)
    80003624:	02078793          	addi	a5,a5,32
    80003628:	02070713          	addi	a4,a4,32
    8000362c:	fed790e3          	bne	a5,a3,8000360c <sys_sigreturn+0x44>

  p->is_sigalarm = 0;
    80003630:	18052823          	sw	zero,400(a0)

  usertrapret();
    80003634:	fffff097          	auipc	ra,0xfffff
    80003638:	584080e7          	jalr	1412(ra) # 80002bb8 <usertrapret>
  return 0;
    8000363c:	4501                	li	a0,0
    8000363e:	60a2                	ld	ra,8(sp)
    80003640:	6402                	ld	s0,0(sp)
    80003642:	0141                	addi	sp,sp,16
    80003644:	8082                	ret

0000000080003646 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003646:	7179                	addi	sp,sp,-48
    80003648:	f406                	sd	ra,40(sp)
    8000364a:	f022                	sd	s0,32(sp)
    8000364c:	ec26                	sd	s1,24(sp)
    8000364e:	e84a                	sd	s2,16(sp)
    80003650:	e44e                	sd	s3,8(sp)
    80003652:	e052                	sd	s4,0(sp)
    80003654:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003656:	00005597          	auipc	a1,0x5
    8000365a:	19258593          	addi	a1,a1,402 # 800087e8 <sysparameters+0x70>
    8000365e:	00235517          	auipc	a0,0x235
    80003662:	ca250513          	addi	a0,a0,-862 # 80238300 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	6c8080e7          	jalr	1736(ra) # 80000d2e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000366e:	0023d797          	auipc	a5,0x23d
    80003672:	c9278793          	addi	a5,a5,-878 # 80240300 <bcache+0x8000>
    80003676:	0023d717          	auipc	a4,0x23d
    8000367a:	ef270713          	addi	a4,a4,-270 # 80240568 <bcache+0x8268>
    8000367e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003682:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003686:	00235497          	auipc	s1,0x235
    8000368a:	c9248493          	addi	s1,s1,-878 # 80238318 <bcache+0x18>
    b->next = bcache.head.next;
    8000368e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003690:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003692:	00005a17          	auipc	s4,0x5
    80003696:	15ea0a13          	addi	s4,s4,350 # 800087f0 <sysparameters+0x78>
    b->next = bcache.head.next;
    8000369a:	2b893783          	ld	a5,696(s2)
    8000369e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036a0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036a4:	85d2                	mv	a1,s4
    800036a6:	01048513          	addi	a0,s1,16
    800036aa:	00001097          	auipc	ra,0x1
    800036ae:	4bc080e7          	jalr	1212(ra) # 80004b66 <initsleeplock>
    bcache.head.next->prev = b;
    800036b2:	2b893783          	ld	a5,696(s2)
    800036b6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036b8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036bc:	45848493          	addi	s1,s1,1112
    800036c0:	fd349de3          	bne	s1,s3,8000369a <binit+0x54>
  }
}
    800036c4:	70a2                	ld	ra,40(sp)
    800036c6:	7402                	ld	s0,32(sp)
    800036c8:	64e2                	ld	s1,24(sp)
    800036ca:	6942                	ld	s2,16(sp)
    800036cc:	69a2                	ld	s3,8(sp)
    800036ce:	6a02                	ld	s4,0(sp)
    800036d0:	6145                	addi	sp,sp,48
    800036d2:	8082                	ret

00000000800036d4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036d4:	7179                	addi	sp,sp,-48
    800036d6:	f406                	sd	ra,40(sp)
    800036d8:	f022                	sd	s0,32(sp)
    800036da:	ec26                	sd	s1,24(sp)
    800036dc:	e84a                	sd	s2,16(sp)
    800036de:	e44e                	sd	s3,8(sp)
    800036e0:	1800                	addi	s0,sp,48
    800036e2:	89aa                	mv	s3,a0
    800036e4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800036e6:	00235517          	auipc	a0,0x235
    800036ea:	c1a50513          	addi	a0,a0,-998 # 80238300 <bcache>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	6d0080e7          	jalr	1744(ra) # 80000dbe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036f6:	0023d497          	auipc	s1,0x23d
    800036fa:	ec24b483          	ld	s1,-318(s1) # 802405b8 <bcache+0x82b8>
    800036fe:	0023d797          	auipc	a5,0x23d
    80003702:	e6a78793          	addi	a5,a5,-406 # 80240568 <bcache+0x8268>
    80003706:	02f48f63          	beq	s1,a5,80003744 <bread+0x70>
    8000370a:	873e                	mv	a4,a5
    8000370c:	a021                	j	80003714 <bread+0x40>
    8000370e:	68a4                	ld	s1,80(s1)
    80003710:	02e48a63          	beq	s1,a4,80003744 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003714:	449c                	lw	a5,8(s1)
    80003716:	ff379ce3          	bne	a5,s3,8000370e <bread+0x3a>
    8000371a:	44dc                	lw	a5,12(s1)
    8000371c:	ff2799e3          	bne	a5,s2,8000370e <bread+0x3a>
      b->refcnt++;
    80003720:	40bc                	lw	a5,64(s1)
    80003722:	2785                	addiw	a5,a5,1
    80003724:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003726:	00235517          	auipc	a0,0x235
    8000372a:	bda50513          	addi	a0,a0,-1062 # 80238300 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	744080e7          	jalr	1860(ra) # 80000e72 <release>
      acquiresleep(&b->lock);
    80003736:	01048513          	addi	a0,s1,16
    8000373a:	00001097          	auipc	ra,0x1
    8000373e:	466080e7          	jalr	1126(ra) # 80004ba0 <acquiresleep>
      return b;
    80003742:	a8b9                	j	800037a0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003744:	0023d497          	auipc	s1,0x23d
    80003748:	e6c4b483          	ld	s1,-404(s1) # 802405b0 <bcache+0x82b0>
    8000374c:	0023d797          	auipc	a5,0x23d
    80003750:	e1c78793          	addi	a5,a5,-484 # 80240568 <bcache+0x8268>
    80003754:	00f48863          	beq	s1,a5,80003764 <bread+0x90>
    80003758:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000375a:	40bc                	lw	a5,64(s1)
    8000375c:	cf81                	beqz	a5,80003774 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000375e:	64a4                	ld	s1,72(s1)
    80003760:	fee49de3          	bne	s1,a4,8000375a <bread+0x86>
  panic("bget: no buffers");
    80003764:	00005517          	auipc	a0,0x5
    80003768:	09450513          	addi	a0,a0,148 # 800087f8 <sysparameters+0x80>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	dd2080e7          	jalr	-558(ra) # 8000053e <panic>
      b->dev = dev;
    80003774:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003778:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000377c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003780:	4785                	li	a5,1
    80003782:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003784:	00235517          	auipc	a0,0x235
    80003788:	b7c50513          	addi	a0,a0,-1156 # 80238300 <bcache>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	6e6080e7          	jalr	1766(ra) # 80000e72 <release>
      acquiresleep(&b->lock);
    80003794:	01048513          	addi	a0,s1,16
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	408080e7          	jalr	1032(ra) # 80004ba0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037a0:	409c                	lw	a5,0(s1)
    800037a2:	cb89                	beqz	a5,800037b4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037a4:	8526                	mv	a0,s1
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6145                	addi	sp,sp,48
    800037b2:	8082                	ret
    virtio_disk_rw(b, 0);
    800037b4:	4581                	li	a1,0
    800037b6:	8526                	mv	a0,s1
    800037b8:	00003097          	auipc	ra,0x3
    800037bc:	f0e080e7          	jalr	-242(ra) # 800066c6 <virtio_disk_rw>
    b->valid = 1;
    800037c0:	4785                	li	a5,1
    800037c2:	c09c                	sw	a5,0(s1)
  return b;
    800037c4:	b7c5                	j	800037a4 <bread+0xd0>

00000000800037c6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037c6:	1101                	addi	sp,sp,-32
    800037c8:	ec06                	sd	ra,24(sp)
    800037ca:	e822                	sd	s0,16(sp)
    800037cc:	e426                	sd	s1,8(sp)
    800037ce:	1000                	addi	s0,sp,32
    800037d0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037d2:	0541                	addi	a0,a0,16
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	466080e7          	jalr	1126(ra) # 80004c3a <holdingsleep>
    800037dc:	cd01                	beqz	a0,800037f4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037de:	4585                	li	a1,1
    800037e0:	8526                	mv	a0,s1
    800037e2:	00003097          	auipc	ra,0x3
    800037e6:	ee4080e7          	jalr	-284(ra) # 800066c6 <virtio_disk_rw>
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6105                	addi	sp,sp,32
    800037f2:	8082                	ret
    panic("bwrite");
    800037f4:	00005517          	auipc	a0,0x5
    800037f8:	01c50513          	addi	a0,a0,28 # 80008810 <sysparameters+0x98>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>

0000000080003804 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	e04a                	sd	s2,0(sp)
    8000380e:	1000                	addi	s0,sp,32
    80003810:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003812:	01050913          	addi	s2,a0,16
    80003816:	854a                	mv	a0,s2
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	422080e7          	jalr	1058(ra) # 80004c3a <holdingsleep>
    80003820:	c92d                	beqz	a0,80003892 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	3d2080e7          	jalr	978(ra) # 80004bf6 <releasesleep>

  acquire(&bcache.lock);
    8000382c:	00235517          	auipc	a0,0x235
    80003830:	ad450513          	addi	a0,a0,-1324 # 80238300 <bcache>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	58a080e7          	jalr	1418(ra) # 80000dbe <acquire>
  b->refcnt--;
    8000383c:	40bc                	lw	a5,64(s1)
    8000383e:	37fd                	addiw	a5,a5,-1
    80003840:	0007871b          	sext.w	a4,a5
    80003844:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003846:	eb05                	bnez	a4,80003876 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003848:	68bc                	ld	a5,80(s1)
    8000384a:	64b8                	ld	a4,72(s1)
    8000384c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000384e:	64bc                	ld	a5,72(s1)
    80003850:	68b8                	ld	a4,80(s1)
    80003852:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003854:	0023d797          	auipc	a5,0x23d
    80003858:	aac78793          	addi	a5,a5,-1364 # 80240300 <bcache+0x8000>
    8000385c:	2b87b703          	ld	a4,696(a5)
    80003860:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003862:	0023d717          	auipc	a4,0x23d
    80003866:	d0670713          	addi	a4,a4,-762 # 80240568 <bcache+0x8268>
    8000386a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000386c:	2b87b703          	ld	a4,696(a5)
    80003870:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003872:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003876:	00235517          	auipc	a0,0x235
    8000387a:	a8a50513          	addi	a0,a0,-1398 # 80238300 <bcache>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	5f4080e7          	jalr	1524(ra) # 80000e72 <release>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6902                	ld	s2,0(sp)
    8000388e:	6105                	addi	sp,sp,32
    80003890:	8082                	ret
    panic("brelse");
    80003892:	00005517          	auipc	a0,0x5
    80003896:	f8650513          	addi	a0,a0,-122 # 80008818 <sysparameters+0xa0>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	ca4080e7          	jalr	-860(ra) # 8000053e <panic>

00000000800038a2 <bpin>:

void
bpin(struct buf *b) {
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038ae:	00235517          	auipc	a0,0x235
    800038b2:	a5250513          	addi	a0,a0,-1454 # 80238300 <bcache>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	508080e7          	jalr	1288(ra) # 80000dbe <acquire>
  b->refcnt++;
    800038be:	40bc                	lw	a5,64(s1)
    800038c0:	2785                	addiw	a5,a5,1
    800038c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038c4:	00235517          	auipc	a0,0x235
    800038c8:	a3c50513          	addi	a0,a0,-1476 # 80238300 <bcache>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	5a6080e7          	jalr	1446(ra) # 80000e72 <release>
}
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6105                	addi	sp,sp,32
    800038dc:	8082                	ret

00000000800038de <bunpin>:

void
bunpin(struct buf *b) {
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	1000                	addi	s0,sp,32
    800038e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038ea:	00235517          	auipc	a0,0x235
    800038ee:	a1650513          	addi	a0,a0,-1514 # 80238300 <bcache>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	4cc080e7          	jalr	1228(ra) # 80000dbe <acquire>
  b->refcnt--;
    800038fa:	40bc                	lw	a5,64(s1)
    800038fc:	37fd                	addiw	a5,a5,-1
    800038fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003900:	00235517          	auipc	a0,0x235
    80003904:	a0050513          	addi	a0,a0,-1536 # 80238300 <bcache>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	56a080e7          	jalr	1386(ra) # 80000e72 <release>
}
    80003910:	60e2                	ld	ra,24(sp)
    80003912:	6442                	ld	s0,16(sp)
    80003914:	64a2                	ld	s1,8(sp)
    80003916:	6105                	addi	sp,sp,32
    80003918:	8082                	ret

000000008000391a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000391a:	1101                	addi	sp,sp,-32
    8000391c:	ec06                	sd	ra,24(sp)
    8000391e:	e822                	sd	s0,16(sp)
    80003920:	e426                	sd	s1,8(sp)
    80003922:	e04a                	sd	s2,0(sp)
    80003924:	1000                	addi	s0,sp,32
    80003926:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003928:	00d5d59b          	srliw	a1,a1,0xd
    8000392c:	0023d797          	auipc	a5,0x23d
    80003930:	0b07a783          	lw	a5,176(a5) # 802409dc <sb+0x1c>
    80003934:	9dbd                	addw	a1,a1,a5
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	d9e080e7          	jalr	-610(ra) # 800036d4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000393e:	0074f713          	andi	a4,s1,7
    80003942:	4785                	li	a5,1
    80003944:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003948:	14ce                	slli	s1,s1,0x33
    8000394a:	90d9                	srli	s1,s1,0x36
    8000394c:	00950733          	add	a4,a0,s1
    80003950:	05874703          	lbu	a4,88(a4)
    80003954:	00e7f6b3          	and	a3,a5,a4
    80003958:	c69d                	beqz	a3,80003986 <bfree+0x6c>
    8000395a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000395c:	94aa                	add	s1,s1,a0
    8000395e:	fff7c793          	not	a5,a5
    80003962:	8ff9                	and	a5,a5,a4
    80003964:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	118080e7          	jalr	280(ra) # 80004a80 <log_write>
  brelse(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00000097          	auipc	ra,0x0
    80003976:	e92080e7          	jalr	-366(ra) # 80003804 <brelse>
}
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6902                	ld	s2,0(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret
    panic("freeing free block");
    80003986:	00005517          	auipc	a0,0x5
    8000398a:	e9a50513          	addi	a0,a0,-358 # 80008820 <sysparameters+0xa8>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>

0000000080003996 <balloc>:
{
    80003996:	711d                	addi	sp,sp,-96
    80003998:	ec86                	sd	ra,88(sp)
    8000399a:	e8a2                	sd	s0,80(sp)
    8000399c:	e4a6                	sd	s1,72(sp)
    8000399e:	e0ca                	sd	s2,64(sp)
    800039a0:	fc4e                	sd	s3,56(sp)
    800039a2:	f852                	sd	s4,48(sp)
    800039a4:	f456                	sd	s5,40(sp)
    800039a6:	f05a                	sd	s6,32(sp)
    800039a8:	ec5e                	sd	s7,24(sp)
    800039aa:	e862                	sd	s8,16(sp)
    800039ac:	e466                	sd	s9,8(sp)
    800039ae:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039b0:	0023d797          	auipc	a5,0x23d
    800039b4:	0147a783          	lw	a5,20(a5) # 802409c4 <sb+0x4>
    800039b8:	cbd1                	beqz	a5,80003a4c <balloc+0xb6>
    800039ba:	8baa                	mv	s7,a0
    800039bc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039be:	0023db17          	auipc	s6,0x23d
    800039c2:	002b0b13          	addi	s6,s6,2 # 802409c0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039c8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039cc:	6c89                	lui	s9,0x2
    800039ce:	a831                	j	800039ea <balloc+0x54>
    brelse(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	e32080e7          	jalr	-462(ra) # 80003804 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039da:	015c87bb          	addw	a5,s9,s5
    800039de:	00078a9b          	sext.w	s5,a5
    800039e2:	004b2703          	lw	a4,4(s6)
    800039e6:	06eaf363          	bgeu	s5,a4,80003a4c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039ea:	41fad79b          	sraiw	a5,s5,0x1f
    800039ee:	0137d79b          	srliw	a5,a5,0x13
    800039f2:	015787bb          	addw	a5,a5,s5
    800039f6:	40d7d79b          	sraiw	a5,a5,0xd
    800039fa:	01cb2583          	lw	a1,28(s6)
    800039fe:	9dbd                	addw	a1,a1,a5
    80003a00:	855e                	mv	a0,s7
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	cd2080e7          	jalr	-814(ra) # 800036d4 <bread>
    80003a0a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a0c:	004b2503          	lw	a0,4(s6)
    80003a10:	000a849b          	sext.w	s1,s5
    80003a14:	8662                	mv	a2,s8
    80003a16:	faa4fde3          	bgeu	s1,a0,800039d0 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a1a:	41f6579b          	sraiw	a5,a2,0x1f
    80003a1e:	01d7d69b          	srliw	a3,a5,0x1d
    80003a22:	00c6873b          	addw	a4,a3,a2
    80003a26:	00777793          	andi	a5,a4,7
    80003a2a:	9f95                	subw	a5,a5,a3
    80003a2c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a30:	4037571b          	sraiw	a4,a4,0x3
    80003a34:	00e906b3          	add	a3,s2,a4
    80003a38:	0586c683          	lbu	a3,88(a3)
    80003a3c:	00d7f5b3          	and	a1,a5,a3
    80003a40:	cd91                	beqz	a1,80003a5c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a42:	2605                	addiw	a2,a2,1
    80003a44:	2485                	addiw	s1,s1,1
    80003a46:	fd4618e3          	bne	a2,s4,80003a16 <balloc+0x80>
    80003a4a:	b759                	j	800039d0 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a4c:	00005517          	auipc	a0,0x5
    80003a50:	dec50513          	addi	a0,a0,-532 # 80008838 <sysparameters+0xc0>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a5c:	974a                	add	a4,a4,s2
    80003a5e:	8fd5                	or	a5,a5,a3
    80003a60:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a64:	854a                	mv	a0,s2
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	01a080e7          	jalr	26(ra) # 80004a80 <log_write>
        brelse(bp);
    80003a6e:	854a                	mv	a0,s2
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	d94080e7          	jalr	-620(ra) # 80003804 <brelse>
  bp = bread(dev, bno);
    80003a78:	85a6                	mv	a1,s1
    80003a7a:	855e                	mv	a0,s7
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	c58080e7          	jalr	-936(ra) # 800036d4 <bread>
    80003a84:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a86:	40000613          	li	a2,1024
    80003a8a:	4581                	li	a1,0
    80003a8c:	05850513          	addi	a0,a0,88
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	42a080e7          	jalr	1066(ra) # 80000eba <memset>
  log_write(bp);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00001097          	auipc	ra,0x1
    80003a9e:	fe6080e7          	jalr	-26(ra) # 80004a80 <log_write>
  brelse(bp);
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	d60080e7          	jalr	-672(ra) # 80003804 <brelse>
}
    80003aac:	8526                	mv	a0,s1
    80003aae:	60e6                	ld	ra,88(sp)
    80003ab0:	6446                	ld	s0,80(sp)
    80003ab2:	64a6                	ld	s1,72(sp)
    80003ab4:	6906                	ld	s2,64(sp)
    80003ab6:	79e2                	ld	s3,56(sp)
    80003ab8:	7a42                	ld	s4,48(sp)
    80003aba:	7aa2                	ld	s5,40(sp)
    80003abc:	7b02                	ld	s6,32(sp)
    80003abe:	6be2                	ld	s7,24(sp)
    80003ac0:	6c42                	ld	s8,16(sp)
    80003ac2:	6ca2                	ld	s9,8(sp)
    80003ac4:	6125                	addi	sp,sp,96
    80003ac6:	8082                	ret

0000000080003ac8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ac8:	7179                	addi	sp,sp,-48
    80003aca:	f406                	sd	ra,40(sp)
    80003acc:	f022                	sd	s0,32(sp)
    80003ace:	ec26                	sd	s1,24(sp)
    80003ad0:	e84a                	sd	s2,16(sp)
    80003ad2:	e44e                	sd	s3,8(sp)
    80003ad4:	e052                	sd	s4,0(sp)
    80003ad6:	1800                	addi	s0,sp,48
    80003ad8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ada:	47ad                	li	a5,11
    80003adc:	04b7fe63          	bgeu	a5,a1,80003b38 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ae0:	ff45849b          	addiw	s1,a1,-12
    80003ae4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ae8:	0ff00793          	li	a5,255
    80003aec:	0ae7e363          	bltu	a5,a4,80003b92 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003af0:	08052583          	lw	a1,128(a0)
    80003af4:	c5ad                	beqz	a1,80003b5e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003af6:	00092503          	lw	a0,0(s2)
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	bda080e7          	jalr	-1062(ra) # 800036d4 <bread>
    80003b02:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b04:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b08:	02049593          	slli	a1,s1,0x20
    80003b0c:	9181                	srli	a1,a1,0x20
    80003b0e:	058a                	slli	a1,a1,0x2
    80003b10:	00b784b3          	add	s1,a5,a1
    80003b14:	0004a983          	lw	s3,0(s1)
    80003b18:	04098d63          	beqz	s3,80003b72 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b1c:	8552                	mv	a0,s4
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	ce6080e7          	jalr	-794(ra) # 80003804 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b26:	854e                	mv	a0,s3
    80003b28:	70a2                	ld	ra,40(sp)
    80003b2a:	7402                	ld	s0,32(sp)
    80003b2c:	64e2                	ld	s1,24(sp)
    80003b2e:	6942                	ld	s2,16(sp)
    80003b30:	69a2                	ld	s3,8(sp)
    80003b32:	6a02                	ld	s4,0(sp)
    80003b34:	6145                	addi	sp,sp,48
    80003b36:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b38:	02059493          	slli	s1,a1,0x20
    80003b3c:	9081                	srli	s1,s1,0x20
    80003b3e:	048a                	slli	s1,s1,0x2
    80003b40:	94aa                	add	s1,s1,a0
    80003b42:	0504a983          	lw	s3,80(s1)
    80003b46:	fe0990e3          	bnez	s3,80003b26 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b4a:	4108                	lw	a0,0(a0)
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	e4a080e7          	jalr	-438(ra) # 80003996 <balloc>
    80003b54:	0005099b          	sext.w	s3,a0
    80003b58:	0534a823          	sw	s3,80(s1)
    80003b5c:	b7e9                	j	80003b26 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b5e:	4108                	lw	a0,0(a0)
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	e36080e7          	jalr	-458(ra) # 80003996 <balloc>
    80003b68:	0005059b          	sext.w	a1,a0
    80003b6c:	08b92023          	sw	a1,128(s2)
    80003b70:	b759                	j	80003af6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b72:	00092503          	lw	a0,0(s2)
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	e20080e7          	jalr	-480(ra) # 80003996 <balloc>
    80003b7e:	0005099b          	sext.w	s3,a0
    80003b82:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b86:	8552                	mv	a0,s4
    80003b88:	00001097          	auipc	ra,0x1
    80003b8c:	ef8080e7          	jalr	-264(ra) # 80004a80 <log_write>
    80003b90:	b771                	j	80003b1c <bmap+0x54>
  panic("bmap: out of range");
    80003b92:	00005517          	auipc	a0,0x5
    80003b96:	cbe50513          	addi	a0,a0,-834 # 80008850 <sysparameters+0xd8>
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	9a4080e7          	jalr	-1628(ra) # 8000053e <panic>

0000000080003ba2 <iget>:
{
    80003ba2:	7179                	addi	sp,sp,-48
    80003ba4:	f406                	sd	ra,40(sp)
    80003ba6:	f022                	sd	s0,32(sp)
    80003ba8:	ec26                	sd	s1,24(sp)
    80003baa:	e84a                	sd	s2,16(sp)
    80003bac:	e44e                	sd	s3,8(sp)
    80003bae:	e052                	sd	s4,0(sp)
    80003bb0:	1800                	addi	s0,sp,48
    80003bb2:	89aa                	mv	s3,a0
    80003bb4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bb6:	0023d517          	auipc	a0,0x23d
    80003bba:	e2a50513          	addi	a0,a0,-470 # 802409e0 <itable>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	200080e7          	jalr	512(ra) # 80000dbe <acquire>
  empty = 0;
    80003bc6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bc8:	0023d497          	auipc	s1,0x23d
    80003bcc:	e3048493          	addi	s1,s1,-464 # 802409f8 <itable+0x18>
    80003bd0:	0023f697          	auipc	a3,0x23f
    80003bd4:	8b868693          	addi	a3,a3,-1864 # 80242488 <log>
    80003bd8:	a039                	j	80003be6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bda:	02090b63          	beqz	s2,80003c10 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bde:	08848493          	addi	s1,s1,136
    80003be2:	02d48a63          	beq	s1,a3,80003c16 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003be6:	449c                	lw	a5,8(s1)
    80003be8:	fef059e3          	blez	a5,80003bda <iget+0x38>
    80003bec:	4098                	lw	a4,0(s1)
    80003bee:	ff3716e3          	bne	a4,s3,80003bda <iget+0x38>
    80003bf2:	40d8                	lw	a4,4(s1)
    80003bf4:	ff4713e3          	bne	a4,s4,80003bda <iget+0x38>
      ip->ref++;
    80003bf8:	2785                	addiw	a5,a5,1
    80003bfa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bfc:	0023d517          	auipc	a0,0x23d
    80003c00:	de450513          	addi	a0,a0,-540 # 802409e0 <itable>
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	26e080e7          	jalr	622(ra) # 80000e72 <release>
      return ip;
    80003c0c:	8926                	mv	s2,s1
    80003c0e:	a03d                	j	80003c3c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c10:	f7f9                	bnez	a5,80003bde <iget+0x3c>
    80003c12:	8926                	mv	s2,s1
    80003c14:	b7e9                	j	80003bde <iget+0x3c>
  if(empty == 0)
    80003c16:	02090c63          	beqz	s2,80003c4e <iget+0xac>
  ip->dev = dev;
    80003c1a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c1e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c22:	4785                	li	a5,1
    80003c24:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c28:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c2c:	0023d517          	auipc	a0,0x23d
    80003c30:	db450513          	addi	a0,a0,-588 # 802409e0 <itable>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	23e080e7          	jalr	574(ra) # 80000e72 <release>
}
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	70a2                	ld	ra,40(sp)
    80003c40:	7402                	ld	s0,32(sp)
    80003c42:	64e2                	ld	s1,24(sp)
    80003c44:	6942                	ld	s2,16(sp)
    80003c46:	69a2                	ld	s3,8(sp)
    80003c48:	6a02                	ld	s4,0(sp)
    80003c4a:	6145                	addi	sp,sp,48
    80003c4c:	8082                	ret
    panic("iget: no inodes");
    80003c4e:	00005517          	auipc	a0,0x5
    80003c52:	c1a50513          	addi	a0,a0,-998 # 80008868 <sysparameters+0xf0>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	8e8080e7          	jalr	-1816(ra) # 8000053e <panic>

0000000080003c5e <fsinit>:
fsinit(int dev) {
    80003c5e:	7179                	addi	sp,sp,-48
    80003c60:	f406                	sd	ra,40(sp)
    80003c62:	f022                	sd	s0,32(sp)
    80003c64:	ec26                	sd	s1,24(sp)
    80003c66:	e84a                	sd	s2,16(sp)
    80003c68:	e44e                	sd	s3,8(sp)
    80003c6a:	1800                	addi	s0,sp,48
    80003c6c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c6e:	4585                	li	a1,1
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	a64080e7          	jalr	-1436(ra) # 800036d4 <bread>
    80003c78:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c7a:	0023d997          	auipc	s3,0x23d
    80003c7e:	d4698993          	addi	s3,s3,-698 # 802409c0 <sb>
    80003c82:	02000613          	li	a2,32
    80003c86:	05850593          	addi	a1,a0,88
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	28e080e7          	jalr	654(ra) # 80000f1a <memmove>
  brelse(bp);
    80003c94:	8526                	mv	a0,s1
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	b6e080e7          	jalr	-1170(ra) # 80003804 <brelse>
  if(sb.magic != FSMAGIC)
    80003c9e:	0009a703          	lw	a4,0(s3)
    80003ca2:	102037b7          	lui	a5,0x10203
    80003ca6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003caa:	02f71263          	bne	a4,a5,80003cce <fsinit+0x70>
  initlog(dev, &sb);
    80003cae:	0023d597          	auipc	a1,0x23d
    80003cb2:	d1258593          	addi	a1,a1,-750 # 802409c0 <sb>
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00001097          	auipc	ra,0x1
    80003cbc:	b4c080e7          	jalr	-1204(ra) # 80004804 <initlog>
}
    80003cc0:	70a2                	ld	ra,40(sp)
    80003cc2:	7402                	ld	s0,32(sp)
    80003cc4:	64e2                	ld	s1,24(sp)
    80003cc6:	6942                	ld	s2,16(sp)
    80003cc8:	69a2                	ld	s3,8(sp)
    80003cca:	6145                	addi	sp,sp,48
    80003ccc:	8082                	ret
    panic("invalid file system");
    80003cce:	00005517          	auipc	a0,0x5
    80003cd2:	baa50513          	addi	a0,a0,-1110 # 80008878 <sysparameters+0x100>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>

0000000080003cde <iinit>:
{
    80003cde:	7179                	addi	sp,sp,-48
    80003ce0:	f406                	sd	ra,40(sp)
    80003ce2:	f022                	sd	s0,32(sp)
    80003ce4:	ec26                	sd	s1,24(sp)
    80003ce6:	e84a                	sd	s2,16(sp)
    80003ce8:	e44e                	sd	s3,8(sp)
    80003cea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cec:	00005597          	auipc	a1,0x5
    80003cf0:	ba458593          	addi	a1,a1,-1116 # 80008890 <sysparameters+0x118>
    80003cf4:	0023d517          	auipc	a0,0x23d
    80003cf8:	cec50513          	addi	a0,a0,-788 # 802409e0 <itable>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	032080e7          	jalr	50(ra) # 80000d2e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d04:	0023d497          	auipc	s1,0x23d
    80003d08:	d0448493          	addi	s1,s1,-764 # 80240a08 <itable+0x28>
    80003d0c:	0023e997          	auipc	s3,0x23e
    80003d10:	78c98993          	addi	s3,s3,1932 # 80242498 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d14:	00005917          	auipc	s2,0x5
    80003d18:	b8490913          	addi	s2,s2,-1148 # 80008898 <sysparameters+0x120>
    80003d1c:	85ca                	mv	a1,s2
    80003d1e:	8526                	mv	a0,s1
    80003d20:	00001097          	auipc	ra,0x1
    80003d24:	e46080e7          	jalr	-442(ra) # 80004b66 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d28:	08848493          	addi	s1,s1,136
    80003d2c:	ff3498e3          	bne	s1,s3,80003d1c <iinit+0x3e>
}
    80003d30:	70a2                	ld	ra,40(sp)
    80003d32:	7402                	ld	s0,32(sp)
    80003d34:	64e2                	ld	s1,24(sp)
    80003d36:	6942                	ld	s2,16(sp)
    80003d38:	69a2                	ld	s3,8(sp)
    80003d3a:	6145                	addi	sp,sp,48
    80003d3c:	8082                	ret

0000000080003d3e <ialloc>:
{
    80003d3e:	715d                	addi	sp,sp,-80
    80003d40:	e486                	sd	ra,72(sp)
    80003d42:	e0a2                	sd	s0,64(sp)
    80003d44:	fc26                	sd	s1,56(sp)
    80003d46:	f84a                	sd	s2,48(sp)
    80003d48:	f44e                	sd	s3,40(sp)
    80003d4a:	f052                	sd	s4,32(sp)
    80003d4c:	ec56                	sd	s5,24(sp)
    80003d4e:	e85a                	sd	s6,16(sp)
    80003d50:	e45e                	sd	s7,8(sp)
    80003d52:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d54:	0023d717          	auipc	a4,0x23d
    80003d58:	c7872703          	lw	a4,-904(a4) # 802409cc <sb+0xc>
    80003d5c:	4785                	li	a5,1
    80003d5e:	04e7fa63          	bgeu	a5,a4,80003db2 <ialloc+0x74>
    80003d62:	8aaa                	mv	s5,a0
    80003d64:	8bae                	mv	s7,a1
    80003d66:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d68:	0023da17          	auipc	s4,0x23d
    80003d6c:	c58a0a13          	addi	s4,s4,-936 # 802409c0 <sb>
    80003d70:	00048b1b          	sext.w	s6,s1
    80003d74:	0044d593          	srli	a1,s1,0x4
    80003d78:	018a2783          	lw	a5,24(s4)
    80003d7c:	9dbd                	addw	a1,a1,a5
    80003d7e:	8556                	mv	a0,s5
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	954080e7          	jalr	-1708(ra) # 800036d4 <bread>
    80003d88:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d8a:	05850993          	addi	s3,a0,88
    80003d8e:	00f4f793          	andi	a5,s1,15
    80003d92:	079a                	slli	a5,a5,0x6
    80003d94:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d96:	00099783          	lh	a5,0(s3)
    80003d9a:	c785                	beqz	a5,80003dc2 <ialloc+0x84>
    brelse(bp);
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	a68080e7          	jalr	-1432(ra) # 80003804 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003da4:	0485                	addi	s1,s1,1
    80003da6:	00ca2703          	lw	a4,12(s4)
    80003daa:	0004879b          	sext.w	a5,s1
    80003dae:	fce7e1e3          	bltu	a5,a4,80003d70 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003db2:	00005517          	auipc	a0,0x5
    80003db6:	aee50513          	addi	a0,a0,-1298 # 800088a0 <sysparameters+0x128>
    80003dba:	ffffc097          	auipc	ra,0xffffc
    80003dbe:	784080e7          	jalr	1924(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003dc2:	04000613          	li	a2,64
    80003dc6:	4581                	li	a1,0
    80003dc8:	854e                	mv	a0,s3
    80003dca:	ffffd097          	auipc	ra,0xffffd
    80003dce:	0f0080e7          	jalr	240(ra) # 80000eba <memset>
      dip->type = type;
    80003dd2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00001097          	auipc	ra,0x1
    80003ddc:	ca8080e7          	jalr	-856(ra) # 80004a80 <log_write>
      brelse(bp);
    80003de0:	854a                	mv	a0,s2
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	a22080e7          	jalr	-1502(ra) # 80003804 <brelse>
      return iget(dev, inum);
    80003dea:	85da                	mv	a1,s6
    80003dec:	8556                	mv	a0,s5
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	db4080e7          	jalr	-588(ra) # 80003ba2 <iget>
}
    80003df6:	60a6                	ld	ra,72(sp)
    80003df8:	6406                	ld	s0,64(sp)
    80003dfa:	74e2                	ld	s1,56(sp)
    80003dfc:	7942                	ld	s2,48(sp)
    80003dfe:	79a2                	ld	s3,40(sp)
    80003e00:	7a02                	ld	s4,32(sp)
    80003e02:	6ae2                	ld	s5,24(sp)
    80003e04:	6b42                	ld	s6,16(sp)
    80003e06:	6ba2                	ld	s7,8(sp)
    80003e08:	6161                	addi	sp,sp,80
    80003e0a:	8082                	ret

0000000080003e0c <iupdate>:
{
    80003e0c:	1101                	addi	sp,sp,-32
    80003e0e:	ec06                	sd	ra,24(sp)
    80003e10:	e822                	sd	s0,16(sp)
    80003e12:	e426                	sd	s1,8(sp)
    80003e14:	e04a                	sd	s2,0(sp)
    80003e16:	1000                	addi	s0,sp,32
    80003e18:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e1a:	415c                	lw	a5,4(a0)
    80003e1c:	0047d79b          	srliw	a5,a5,0x4
    80003e20:	0023d597          	auipc	a1,0x23d
    80003e24:	bb85a583          	lw	a1,-1096(a1) # 802409d8 <sb+0x18>
    80003e28:	9dbd                	addw	a1,a1,a5
    80003e2a:	4108                	lw	a0,0(a0)
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	8a8080e7          	jalr	-1880(ra) # 800036d4 <bread>
    80003e34:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e36:	05850793          	addi	a5,a0,88
    80003e3a:	40c8                	lw	a0,4(s1)
    80003e3c:	893d                	andi	a0,a0,15
    80003e3e:	051a                	slli	a0,a0,0x6
    80003e40:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e42:	04449703          	lh	a4,68(s1)
    80003e46:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e4a:	04649703          	lh	a4,70(s1)
    80003e4e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e52:	04849703          	lh	a4,72(s1)
    80003e56:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e5a:	04a49703          	lh	a4,74(s1)
    80003e5e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e62:	44f8                	lw	a4,76(s1)
    80003e64:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e66:	03400613          	li	a2,52
    80003e6a:	05048593          	addi	a1,s1,80
    80003e6e:	0531                	addi	a0,a0,12
    80003e70:	ffffd097          	auipc	ra,0xffffd
    80003e74:	0aa080e7          	jalr	170(ra) # 80000f1a <memmove>
  log_write(bp);
    80003e78:	854a                	mv	a0,s2
    80003e7a:	00001097          	auipc	ra,0x1
    80003e7e:	c06080e7          	jalr	-1018(ra) # 80004a80 <log_write>
  brelse(bp);
    80003e82:	854a                	mv	a0,s2
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	980080e7          	jalr	-1664(ra) # 80003804 <brelse>
}
    80003e8c:	60e2                	ld	ra,24(sp)
    80003e8e:	6442                	ld	s0,16(sp)
    80003e90:	64a2                	ld	s1,8(sp)
    80003e92:	6902                	ld	s2,0(sp)
    80003e94:	6105                	addi	sp,sp,32
    80003e96:	8082                	ret

0000000080003e98 <idup>:
{
    80003e98:	1101                	addi	sp,sp,-32
    80003e9a:	ec06                	sd	ra,24(sp)
    80003e9c:	e822                	sd	s0,16(sp)
    80003e9e:	e426                	sd	s1,8(sp)
    80003ea0:	1000                	addi	s0,sp,32
    80003ea2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ea4:	0023d517          	auipc	a0,0x23d
    80003ea8:	b3c50513          	addi	a0,a0,-1220 # 802409e0 <itable>
    80003eac:	ffffd097          	auipc	ra,0xffffd
    80003eb0:	f12080e7          	jalr	-238(ra) # 80000dbe <acquire>
  ip->ref++;
    80003eb4:	449c                	lw	a5,8(s1)
    80003eb6:	2785                	addiw	a5,a5,1
    80003eb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eba:	0023d517          	auipc	a0,0x23d
    80003ebe:	b2650513          	addi	a0,a0,-1242 # 802409e0 <itable>
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	fb0080e7          	jalr	-80(ra) # 80000e72 <release>
}
    80003eca:	8526                	mv	a0,s1
    80003ecc:	60e2                	ld	ra,24(sp)
    80003ece:	6442                	ld	s0,16(sp)
    80003ed0:	64a2                	ld	s1,8(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <ilock>:
{
    80003ed6:	1101                	addi	sp,sp,-32
    80003ed8:	ec06                	sd	ra,24(sp)
    80003eda:	e822                	sd	s0,16(sp)
    80003edc:	e426                	sd	s1,8(sp)
    80003ede:	e04a                	sd	s2,0(sp)
    80003ee0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ee2:	c115                	beqz	a0,80003f06 <ilock+0x30>
    80003ee4:	84aa                	mv	s1,a0
    80003ee6:	451c                	lw	a5,8(a0)
    80003ee8:	00f05f63          	blez	a5,80003f06 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003eec:	0541                	addi	a0,a0,16
    80003eee:	00001097          	auipc	ra,0x1
    80003ef2:	cb2080e7          	jalr	-846(ra) # 80004ba0 <acquiresleep>
  if(ip->valid == 0){
    80003ef6:	40bc                	lw	a5,64(s1)
    80003ef8:	cf99                	beqz	a5,80003f16 <ilock+0x40>
}
    80003efa:	60e2                	ld	ra,24(sp)
    80003efc:	6442                	ld	s0,16(sp)
    80003efe:	64a2                	ld	s1,8(sp)
    80003f00:	6902                	ld	s2,0(sp)
    80003f02:	6105                	addi	sp,sp,32
    80003f04:	8082                	ret
    panic("ilock");
    80003f06:	00005517          	auipc	a0,0x5
    80003f0a:	9b250513          	addi	a0,a0,-1614 # 800088b8 <sysparameters+0x140>
    80003f0e:	ffffc097          	auipc	ra,0xffffc
    80003f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f16:	40dc                	lw	a5,4(s1)
    80003f18:	0047d79b          	srliw	a5,a5,0x4
    80003f1c:	0023d597          	auipc	a1,0x23d
    80003f20:	abc5a583          	lw	a1,-1348(a1) # 802409d8 <sb+0x18>
    80003f24:	9dbd                	addw	a1,a1,a5
    80003f26:	4088                	lw	a0,0(s1)
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	7ac080e7          	jalr	1964(ra) # 800036d4 <bread>
    80003f30:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f32:	05850593          	addi	a1,a0,88
    80003f36:	40dc                	lw	a5,4(s1)
    80003f38:	8bbd                	andi	a5,a5,15
    80003f3a:	079a                	slli	a5,a5,0x6
    80003f3c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f3e:	00059783          	lh	a5,0(a1)
    80003f42:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f46:	00259783          	lh	a5,2(a1)
    80003f4a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f4e:	00459783          	lh	a5,4(a1)
    80003f52:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f56:	00659783          	lh	a5,6(a1)
    80003f5a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f5e:	459c                	lw	a5,8(a1)
    80003f60:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f62:	03400613          	li	a2,52
    80003f66:	05b1                	addi	a1,a1,12
    80003f68:	05048513          	addi	a0,s1,80
    80003f6c:	ffffd097          	auipc	ra,0xffffd
    80003f70:	fae080e7          	jalr	-82(ra) # 80000f1a <memmove>
    brelse(bp);
    80003f74:	854a                	mv	a0,s2
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	88e080e7          	jalr	-1906(ra) # 80003804 <brelse>
    ip->valid = 1;
    80003f7e:	4785                	li	a5,1
    80003f80:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f82:	04449783          	lh	a5,68(s1)
    80003f86:	fbb5                	bnez	a5,80003efa <ilock+0x24>
      panic("ilock: no type");
    80003f88:	00005517          	auipc	a0,0x5
    80003f8c:	93850513          	addi	a0,a0,-1736 # 800088c0 <sysparameters+0x148>
    80003f90:	ffffc097          	auipc	ra,0xffffc
    80003f94:	5ae080e7          	jalr	1454(ra) # 8000053e <panic>

0000000080003f98 <iunlock>:
{
    80003f98:	1101                	addi	sp,sp,-32
    80003f9a:	ec06                	sd	ra,24(sp)
    80003f9c:	e822                	sd	s0,16(sp)
    80003f9e:	e426                	sd	s1,8(sp)
    80003fa0:	e04a                	sd	s2,0(sp)
    80003fa2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fa4:	c905                	beqz	a0,80003fd4 <iunlock+0x3c>
    80003fa6:	84aa                	mv	s1,a0
    80003fa8:	01050913          	addi	s2,a0,16
    80003fac:	854a                	mv	a0,s2
    80003fae:	00001097          	auipc	ra,0x1
    80003fb2:	c8c080e7          	jalr	-884(ra) # 80004c3a <holdingsleep>
    80003fb6:	cd19                	beqz	a0,80003fd4 <iunlock+0x3c>
    80003fb8:	449c                	lw	a5,8(s1)
    80003fba:	00f05d63          	blez	a5,80003fd4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	00001097          	auipc	ra,0x1
    80003fc4:	c36080e7          	jalr	-970(ra) # 80004bf6 <releasesleep>
}
    80003fc8:	60e2                	ld	ra,24(sp)
    80003fca:	6442                	ld	s0,16(sp)
    80003fcc:	64a2                	ld	s1,8(sp)
    80003fce:	6902                	ld	s2,0(sp)
    80003fd0:	6105                	addi	sp,sp,32
    80003fd2:	8082                	ret
    panic("iunlock");
    80003fd4:	00005517          	auipc	a0,0x5
    80003fd8:	8fc50513          	addi	a0,a0,-1796 # 800088d0 <sysparameters+0x158>
    80003fdc:	ffffc097          	auipc	ra,0xffffc
    80003fe0:	562080e7          	jalr	1378(ra) # 8000053e <panic>

0000000080003fe4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fe4:	7179                	addi	sp,sp,-48
    80003fe6:	f406                	sd	ra,40(sp)
    80003fe8:	f022                	sd	s0,32(sp)
    80003fea:	ec26                	sd	s1,24(sp)
    80003fec:	e84a                	sd	s2,16(sp)
    80003fee:	e44e                	sd	s3,8(sp)
    80003ff0:	e052                	sd	s4,0(sp)
    80003ff2:	1800                	addi	s0,sp,48
    80003ff4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ff6:	05050493          	addi	s1,a0,80
    80003ffa:	08050913          	addi	s2,a0,128
    80003ffe:	a021                	j	80004006 <itrunc+0x22>
    80004000:	0491                	addi	s1,s1,4
    80004002:	01248d63          	beq	s1,s2,8000401c <itrunc+0x38>
    if(ip->addrs[i]){
    80004006:	408c                	lw	a1,0(s1)
    80004008:	dde5                	beqz	a1,80004000 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000400a:	0009a503          	lw	a0,0(s3)
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	90c080e7          	jalr	-1780(ra) # 8000391a <bfree>
      ip->addrs[i] = 0;
    80004016:	0004a023          	sw	zero,0(s1)
    8000401a:	b7dd                	j	80004000 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000401c:	0809a583          	lw	a1,128(s3)
    80004020:	e185                	bnez	a1,80004040 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004022:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004026:	854e                	mv	a0,s3
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	de4080e7          	jalr	-540(ra) # 80003e0c <iupdate>
}
    80004030:	70a2                	ld	ra,40(sp)
    80004032:	7402                	ld	s0,32(sp)
    80004034:	64e2                	ld	s1,24(sp)
    80004036:	6942                	ld	s2,16(sp)
    80004038:	69a2                	ld	s3,8(sp)
    8000403a:	6a02                	ld	s4,0(sp)
    8000403c:	6145                	addi	sp,sp,48
    8000403e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004040:	0009a503          	lw	a0,0(s3)
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	690080e7          	jalr	1680(ra) # 800036d4 <bread>
    8000404c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000404e:	05850493          	addi	s1,a0,88
    80004052:	45850913          	addi	s2,a0,1112
    80004056:	a811                	j	8000406a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004058:	0009a503          	lw	a0,0(s3)
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	8be080e7          	jalr	-1858(ra) # 8000391a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004064:	0491                	addi	s1,s1,4
    80004066:	01248563          	beq	s1,s2,80004070 <itrunc+0x8c>
      if(a[j])
    8000406a:	408c                	lw	a1,0(s1)
    8000406c:	dde5                	beqz	a1,80004064 <itrunc+0x80>
    8000406e:	b7ed                	j	80004058 <itrunc+0x74>
    brelse(bp);
    80004070:	8552                	mv	a0,s4
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	792080e7          	jalr	1938(ra) # 80003804 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000407a:	0809a583          	lw	a1,128(s3)
    8000407e:	0009a503          	lw	a0,0(s3)
    80004082:	00000097          	auipc	ra,0x0
    80004086:	898080e7          	jalr	-1896(ra) # 8000391a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000408a:	0809a023          	sw	zero,128(s3)
    8000408e:	bf51                	j	80004022 <itrunc+0x3e>

0000000080004090 <iput>:
{
    80004090:	1101                	addi	sp,sp,-32
    80004092:	ec06                	sd	ra,24(sp)
    80004094:	e822                	sd	s0,16(sp)
    80004096:	e426                	sd	s1,8(sp)
    80004098:	e04a                	sd	s2,0(sp)
    8000409a:	1000                	addi	s0,sp,32
    8000409c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000409e:	0023d517          	auipc	a0,0x23d
    800040a2:	94250513          	addi	a0,a0,-1726 # 802409e0 <itable>
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	d18080e7          	jalr	-744(ra) # 80000dbe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ae:	4498                	lw	a4,8(s1)
    800040b0:	4785                	li	a5,1
    800040b2:	02f70363          	beq	a4,a5,800040d8 <iput+0x48>
  ip->ref--;
    800040b6:	449c                	lw	a5,8(s1)
    800040b8:	37fd                	addiw	a5,a5,-1
    800040ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040bc:	0023d517          	auipc	a0,0x23d
    800040c0:	92450513          	addi	a0,a0,-1756 # 802409e0 <itable>
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	dae080e7          	jalr	-594(ra) # 80000e72 <release>
}
    800040cc:	60e2                	ld	ra,24(sp)
    800040ce:	6442                	ld	s0,16(sp)
    800040d0:	64a2                	ld	s1,8(sp)
    800040d2:	6902                	ld	s2,0(sp)
    800040d4:	6105                	addi	sp,sp,32
    800040d6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d8:	40bc                	lw	a5,64(s1)
    800040da:	dff1                	beqz	a5,800040b6 <iput+0x26>
    800040dc:	04a49783          	lh	a5,74(s1)
    800040e0:	fbf9                	bnez	a5,800040b6 <iput+0x26>
    acquiresleep(&ip->lock);
    800040e2:	01048913          	addi	s2,s1,16
    800040e6:	854a                	mv	a0,s2
    800040e8:	00001097          	auipc	ra,0x1
    800040ec:	ab8080e7          	jalr	-1352(ra) # 80004ba0 <acquiresleep>
    release(&itable.lock);
    800040f0:	0023d517          	auipc	a0,0x23d
    800040f4:	8f050513          	addi	a0,a0,-1808 # 802409e0 <itable>
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	d7a080e7          	jalr	-646(ra) # 80000e72 <release>
    itrunc(ip);
    80004100:	8526                	mv	a0,s1
    80004102:	00000097          	auipc	ra,0x0
    80004106:	ee2080e7          	jalr	-286(ra) # 80003fe4 <itrunc>
    ip->type = 0;
    8000410a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000410e:	8526                	mv	a0,s1
    80004110:	00000097          	auipc	ra,0x0
    80004114:	cfc080e7          	jalr	-772(ra) # 80003e0c <iupdate>
    ip->valid = 0;
    80004118:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000411c:	854a                	mv	a0,s2
    8000411e:	00001097          	auipc	ra,0x1
    80004122:	ad8080e7          	jalr	-1320(ra) # 80004bf6 <releasesleep>
    acquire(&itable.lock);
    80004126:	0023d517          	auipc	a0,0x23d
    8000412a:	8ba50513          	addi	a0,a0,-1862 # 802409e0 <itable>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	c90080e7          	jalr	-880(ra) # 80000dbe <acquire>
    80004136:	b741                	j	800040b6 <iput+0x26>

0000000080004138 <iunlockput>:
{
    80004138:	1101                	addi	sp,sp,-32
    8000413a:	ec06                	sd	ra,24(sp)
    8000413c:	e822                	sd	s0,16(sp)
    8000413e:	e426                	sd	s1,8(sp)
    80004140:	1000                	addi	s0,sp,32
    80004142:	84aa                	mv	s1,a0
  iunlock(ip);
    80004144:	00000097          	auipc	ra,0x0
    80004148:	e54080e7          	jalr	-428(ra) # 80003f98 <iunlock>
  iput(ip);
    8000414c:	8526                	mv	a0,s1
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	f42080e7          	jalr	-190(ra) # 80004090 <iput>
}
    80004156:	60e2                	ld	ra,24(sp)
    80004158:	6442                	ld	s0,16(sp)
    8000415a:	64a2                	ld	s1,8(sp)
    8000415c:	6105                	addi	sp,sp,32
    8000415e:	8082                	ret

0000000080004160 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004160:	1141                	addi	sp,sp,-16
    80004162:	e422                	sd	s0,8(sp)
    80004164:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004166:	411c                	lw	a5,0(a0)
    80004168:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000416a:	415c                	lw	a5,4(a0)
    8000416c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000416e:	04451783          	lh	a5,68(a0)
    80004172:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004176:	04a51783          	lh	a5,74(a0)
    8000417a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000417e:	04c56783          	lwu	a5,76(a0)
    80004182:	e99c                	sd	a5,16(a1)
}
    80004184:	6422                	ld	s0,8(sp)
    80004186:	0141                	addi	sp,sp,16
    80004188:	8082                	ret

000000008000418a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000418a:	457c                	lw	a5,76(a0)
    8000418c:	0ed7e963          	bltu	a5,a3,8000427e <readi+0xf4>
{
    80004190:	7159                	addi	sp,sp,-112
    80004192:	f486                	sd	ra,104(sp)
    80004194:	f0a2                	sd	s0,96(sp)
    80004196:	eca6                	sd	s1,88(sp)
    80004198:	e8ca                	sd	s2,80(sp)
    8000419a:	e4ce                	sd	s3,72(sp)
    8000419c:	e0d2                	sd	s4,64(sp)
    8000419e:	fc56                	sd	s5,56(sp)
    800041a0:	f85a                	sd	s6,48(sp)
    800041a2:	f45e                	sd	s7,40(sp)
    800041a4:	f062                	sd	s8,32(sp)
    800041a6:	ec66                	sd	s9,24(sp)
    800041a8:	e86a                	sd	s10,16(sp)
    800041aa:	e46e                	sd	s11,8(sp)
    800041ac:	1880                	addi	s0,sp,112
    800041ae:	8baa                	mv	s7,a0
    800041b0:	8c2e                	mv	s8,a1
    800041b2:	8ab2                	mv	s5,a2
    800041b4:	84b6                	mv	s1,a3
    800041b6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041b8:	9f35                	addw	a4,a4,a3
    return 0;
    800041ba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041bc:	0ad76063          	bltu	a4,a3,8000425c <readi+0xd2>
  if(off + n > ip->size)
    800041c0:	00e7f463          	bgeu	a5,a4,800041c8 <readi+0x3e>
    n = ip->size - off;
    800041c4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041c8:	0a0b0963          	beqz	s6,8000427a <readi+0xf0>
    800041cc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ce:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041d2:	5cfd                	li	s9,-1
    800041d4:	a82d                	j	8000420e <readi+0x84>
    800041d6:	020a1d93          	slli	s11,s4,0x20
    800041da:	020ddd93          	srli	s11,s11,0x20
    800041de:	05890613          	addi	a2,s2,88
    800041e2:	86ee                	mv	a3,s11
    800041e4:	963a                	add	a2,a2,a4
    800041e6:	85d6                	mv	a1,s5
    800041e8:	8562                	mv	a0,s8
    800041ea:	ffffe097          	auipc	ra,0xffffe
    800041ee:	6b0080e7          	jalr	1712(ra) # 8000289a <either_copyout>
    800041f2:	05950d63          	beq	a0,s9,8000424c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041f6:	854a                	mv	a0,s2
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	60c080e7          	jalr	1548(ra) # 80003804 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004200:	013a09bb          	addw	s3,s4,s3
    80004204:	009a04bb          	addw	s1,s4,s1
    80004208:	9aee                	add	s5,s5,s11
    8000420a:	0569f763          	bgeu	s3,s6,80004258 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000420e:	000ba903          	lw	s2,0(s7)
    80004212:	00a4d59b          	srliw	a1,s1,0xa
    80004216:	855e                	mv	a0,s7
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	8b0080e7          	jalr	-1872(ra) # 80003ac8 <bmap>
    80004220:	0005059b          	sext.w	a1,a0
    80004224:	854a                	mv	a0,s2
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	4ae080e7          	jalr	1198(ra) # 800036d4 <bread>
    8000422e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004230:	3ff4f713          	andi	a4,s1,1023
    80004234:	40ed07bb          	subw	a5,s10,a4
    80004238:	413b06bb          	subw	a3,s6,s3
    8000423c:	8a3e                	mv	s4,a5
    8000423e:	2781                	sext.w	a5,a5
    80004240:	0006861b          	sext.w	a2,a3
    80004244:	f8f679e3          	bgeu	a2,a5,800041d6 <readi+0x4c>
    80004248:	8a36                	mv	s4,a3
    8000424a:	b771                	j	800041d6 <readi+0x4c>
      brelse(bp);
    8000424c:	854a                	mv	a0,s2
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	5b6080e7          	jalr	1462(ra) # 80003804 <brelse>
      tot = -1;
    80004256:	59fd                	li	s3,-1
  }
  return tot;
    80004258:	0009851b          	sext.w	a0,s3
}
    8000425c:	70a6                	ld	ra,104(sp)
    8000425e:	7406                	ld	s0,96(sp)
    80004260:	64e6                	ld	s1,88(sp)
    80004262:	6946                	ld	s2,80(sp)
    80004264:	69a6                	ld	s3,72(sp)
    80004266:	6a06                	ld	s4,64(sp)
    80004268:	7ae2                	ld	s5,56(sp)
    8000426a:	7b42                	ld	s6,48(sp)
    8000426c:	7ba2                	ld	s7,40(sp)
    8000426e:	7c02                	ld	s8,32(sp)
    80004270:	6ce2                	ld	s9,24(sp)
    80004272:	6d42                	ld	s10,16(sp)
    80004274:	6da2                	ld	s11,8(sp)
    80004276:	6165                	addi	sp,sp,112
    80004278:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000427a:	89da                	mv	s3,s6
    8000427c:	bff1                	j	80004258 <readi+0xce>
    return 0;
    8000427e:	4501                	li	a0,0
}
    80004280:	8082                	ret

0000000080004282 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004282:	457c                	lw	a5,76(a0)
    80004284:	10d7e863          	bltu	a5,a3,80004394 <writei+0x112>
{
    80004288:	7159                	addi	sp,sp,-112
    8000428a:	f486                	sd	ra,104(sp)
    8000428c:	f0a2                	sd	s0,96(sp)
    8000428e:	eca6                	sd	s1,88(sp)
    80004290:	e8ca                	sd	s2,80(sp)
    80004292:	e4ce                	sd	s3,72(sp)
    80004294:	e0d2                	sd	s4,64(sp)
    80004296:	fc56                	sd	s5,56(sp)
    80004298:	f85a                	sd	s6,48(sp)
    8000429a:	f45e                	sd	s7,40(sp)
    8000429c:	f062                	sd	s8,32(sp)
    8000429e:	ec66                	sd	s9,24(sp)
    800042a0:	e86a                	sd	s10,16(sp)
    800042a2:	e46e                	sd	s11,8(sp)
    800042a4:	1880                	addi	s0,sp,112
    800042a6:	8b2a                	mv	s6,a0
    800042a8:	8c2e                	mv	s8,a1
    800042aa:	8ab2                	mv	s5,a2
    800042ac:	8936                	mv	s2,a3
    800042ae:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042b0:	00e687bb          	addw	a5,a3,a4
    800042b4:	0ed7e263          	bltu	a5,a3,80004398 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042b8:	00043737          	lui	a4,0x43
    800042bc:	0ef76063          	bltu	a4,a5,8000439c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042c0:	0c0b8863          	beqz	s7,80004390 <writei+0x10e>
    800042c4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042c6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042ca:	5cfd                	li	s9,-1
    800042cc:	a091                	j	80004310 <writei+0x8e>
    800042ce:	02099d93          	slli	s11,s3,0x20
    800042d2:	020ddd93          	srli	s11,s11,0x20
    800042d6:	05848513          	addi	a0,s1,88
    800042da:	86ee                	mv	a3,s11
    800042dc:	8656                	mv	a2,s5
    800042de:	85e2                	mv	a1,s8
    800042e0:	953a                	add	a0,a0,a4
    800042e2:	ffffe097          	auipc	ra,0xffffe
    800042e6:	60e080e7          	jalr	1550(ra) # 800028f0 <either_copyin>
    800042ea:	07950263          	beq	a0,s9,8000434e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042ee:	8526                	mv	a0,s1
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	790080e7          	jalr	1936(ra) # 80004a80 <log_write>
    brelse(bp);
    800042f8:	8526                	mv	a0,s1
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	50a080e7          	jalr	1290(ra) # 80003804 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004302:	01498a3b          	addw	s4,s3,s4
    80004306:	0129893b          	addw	s2,s3,s2
    8000430a:	9aee                	add	s5,s5,s11
    8000430c:	057a7663          	bgeu	s4,s7,80004358 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004310:	000b2483          	lw	s1,0(s6)
    80004314:	00a9559b          	srliw	a1,s2,0xa
    80004318:	855a                	mv	a0,s6
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	7ae080e7          	jalr	1966(ra) # 80003ac8 <bmap>
    80004322:	0005059b          	sext.w	a1,a0
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	3ac080e7          	jalr	940(ra) # 800036d4 <bread>
    80004330:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004332:	3ff97713          	andi	a4,s2,1023
    80004336:	40ed07bb          	subw	a5,s10,a4
    8000433a:	414b86bb          	subw	a3,s7,s4
    8000433e:	89be                	mv	s3,a5
    80004340:	2781                	sext.w	a5,a5
    80004342:	0006861b          	sext.w	a2,a3
    80004346:	f8f674e3          	bgeu	a2,a5,800042ce <writei+0x4c>
    8000434a:	89b6                	mv	s3,a3
    8000434c:	b749                	j	800042ce <writei+0x4c>
      brelse(bp);
    8000434e:	8526                	mv	a0,s1
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	4b4080e7          	jalr	1204(ra) # 80003804 <brelse>
  }

  if(off > ip->size)
    80004358:	04cb2783          	lw	a5,76(s6)
    8000435c:	0127f463          	bgeu	a5,s2,80004364 <writei+0xe2>
    ip->size = off;
    80004360:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004364:	855a                	mv	a0,s6
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	aa6080e7          	jalr	-1370(ra) # 80003e0c <iupdate>

  return tot;
    8000436e:	000a051b          	sext.w	a0,s4
}
    80004372:	70a6                	ld	ra,104(sp)
    80004374:	7406                	ld	s0,96(sp)
    80004376:	64e6                	ld	s1,88(sp)
    80004378:	6946                	ld	s2,80(sp)
    8000437a:	69a6                	ld	s3,72(sp)
    8000437c:	6a06                	ld	s4,64(sp)
    8000437e:	7ae2                	ld	s5,56(sp)
    80004380:	7b42                	ld	s6,48(sp)
    80004382:	7ba2                	ld	s7,40(sp)
    80004384:	7c02                	ld	s8,32(sp)
    80004386:	6ce2                	ld	s9,24(sp)
    80004388:	6d42                	ld	s10,16(sp)
    8000438a:	6da2                	ld	s11,8(sp)
    8000438c:	6165                	addi	sp,sp,112
    8000438e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004390:	8a5e                	mv	s4,s7
    80004392:	bfc9                	j	80004364 <writei+0xe2>
    return -1;
    80004394:	557d                	li	a0,-1
}
    80004396:	8082                	ret
    return -1;
    80004398:	557d                	li	a0,-1
    8000439a:	bfe1                	j	80004372 <writei+0xf0>
    return -1;
    8000439c:	557d                	li	a0,-1
    8000439e:	bfd1                	j	80004372 <writei+0xf0>

00000000800043a0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043a0:	1141                	addi	sp,sp,-16
    800043a2:	e406                	sd	ra,8(sp)
    800043a4:	e022                	sd	s0,0(sp)
    800043a6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043a8:	4639                	li	a2,14
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	be8080e7          	jalr	-1048(ra) # 80000f92 <strncmp>
}
    800043b2:	60a2                	ld	ra,8(sp)
    800043b4:	6402                	ld	s0,0(sp)
    800043b6:	0141                	addi	sp,sp,16
    800043b8:	8082                	ret

00000000800043ba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043ba:	7139                	addi	sp,sp,-64
    800043bc:	fc06                	sd	ra,56(sp)
    800043be:	f822                	sd	s0,48(sp)
    800043c0:	f426                	sd	s1,40(sp)
    800043c2:	f04a                	sd	s2,32(sp)
    800043c4:	ec4e                	sd	s3,24(sp)
    800043c6:	e852                	sd	s4,16(sp)
    800043c8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043ca:	04451703          	lh	a4,68(a0)
    800043ce:	4785                	li	a5,1
    800043d0:	00f71a63          	bne	a4,a5,800043e4 <dirlookup+0x2a>
    800043d4:	892a                	mv	s2,a0
    800043d6:	89ae                	mv	s3,a1
    800043d8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043da:	457c                	lw	a5,76(a0)
    800043dc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043de:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e0:	e79d                	bnez	a5,8000440e <dirlookup+0x54>
    800043e2:	a8a5                	j	8000445a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	4f450513          	addi	a0,a0,1268 # 800088d8 <sysparameters+0x160>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
      panic("dirlookup read");
    800043f4:	00004517          	auipc	a0,0x4
    800043f8:	4fc50513          	addi	a0,a0,1276 # 800088f0 <sysparameters+0x178>
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	142080e7          	jalr	322(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	24c1                	addiw	s1,s1,16
    80004406:	04c92783          	lw	a5,76(s2)
    8000440a:	04f4f763          	bgeu	s1,a5,80004458 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440e:	4741                	li	a4,16
    80004410:	86a6                	mv	a3,s1
    80004412:	fc040613          	addi	a2,s0,-64
    80004416:	4581                	li	a1,0
    80004418:	854a                	mv	a0,s2
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	d70080e7          	jalr	-656(ra) # 8000418a <readi>
    80004422:	47c1                	li	a5,16
    80004424:	fcf518e3          	bne	a0,a5,800043f4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004428:	fc045783          	lhu	a5,-64(s0)
    8000442c:	dfe1                	beqz	a5,80004404 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000442e:	fc240593          	addi	a1,s0,-62
    80004432:	854e                	mv	a0,s3
    80004434:	00000097          	auipc	ra,0x0
    80004438:	f6c080e7          	jalr	-148(ra) # 800043a0 <namecmp>
    8000443c:	f561                	bnez	a0,80004404 <dirlookup+0x4a>
      if(poff)
    8000443e:	000a0463          	beqz	s4,80004446 <dirlookup+0x8c>
        *poff = off;
    80004442:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004446:	fc045583          	lhu	a1,-64(s0)
    8000444a:	00092503          	lw	a0,0(s2)
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	754080e7          	jalr	1876(ra) # 80003ba2 <iget>
    80004456:	a011                	j	8000445a <dirlookup+0xa0>
  return 0;
    80004458:	4501                	li	a0,0
}
    8000445a:	70e2                	ld	ra,56(sp)
    8000445c:	7442                	ld	s0,48(sp)
    8000445e:	74a2                	ld	s1,40(sp)
    80004460:	7902                	ld	s2,32(sp)
    80004462:	69e2                	ld	s3,24(sp)
    80004464:	6a42                	ld	s4,16(sp)
    80004466:	6121                	addi	sp,sp,64
    80004468:	8082                	ret

000000008000446a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000446a:	711d                	addi	sp,sp,-96
    8000446c:	ec86                	sd	ra,88(sp)
    8000446e:	e8a2                	sd	s0,80(sp)
    80004470:	e4a6                	sd	s1,72(sp)
    80004472:	e0ca                	sd	s2,64(sp)
    80004474:	fc4e                	sd	s3,56(sp)
    80004476:	f852                	sd	s4,48(sp)
    80004478:	f456                	sd	s5,40(sp)
    8000447a:	f05a                	sd	s6,32(sp)
    8000447c:	ec5e                	sd	s7,24(sp)
    8000447e:	e862                	sd	s8,16(sp)
    80004480:	e466                	sd	s9,8(sp)
    80004482:	1080                	addi	s0,sp,96
    80004484:	84aa                	mv	s1,a0
    80004486:	8b2e                	mv	s6,a1
    80004488:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000448a:	00054703          	lbu	a4,0(a0)
    8000448e:	02f00793          	li	a5,47
    80004492:	02f70363          	beq	a4,a5,800044b8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	738080e7          	jalr	1848(ra) # 80001bce <myproc>
    8000449e:	15053503          	ld	a0,336(a0)
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	9f6080e7          	jalr	-1546(ra) # 80003e98 <idup>
    800044aa:	89aa                	mv	s3,a0
  while(*path == '/')
    800044ac:	02f00913          	li	s2,47
  len = path - s;
    800044b0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800044b2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044b4:	4c05                	li	s8,1
    800044b6:	a865                	j	8000456e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044b8:	4585                	li	a1,1
    800044ba:	4505                	li	a0,1
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	6e6080e7          	jalr	1766(ra) # 80003ba2 <iget>
    800044c4:	89aa                	mv	s3,a0
    800044c6:	b7dd                	j	800044ac <namex+0x42>
      iunlockput(ip);
    800044c8:	854e                	mv	a0,s3
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	c6e080e7          	jalr	-914(ra) # 80004138 <iunlockput>
      return 0;
    800044d2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044d4:	854e                	mv	a0,s3
    800044d6:	60e6                	ld	ra,88(sp)
    800044d8:	6446                	ld	s0,80(sp)
    800044da:	64a6                	ld	s1,72(sp)
    800044dc:	6906                	ld	s2,64(sp)
    800044de:	79e2                	ld	s3,56(sp)
    800044e0:	7a42                	ld	s4,48(sp)
    800044e2:	7aa2                	ld	s5,40(sp)
    800044e4:	7b02                	ld	s6,32(sp)
    800044e6:	6be2                	ld	s7,24(sp)
    800044e8:	6c42                	ld	s8,16(sp)
    800044ea:	6ca2                	ld	s9,8(sp)
    800044ec:	6125                	addi	sp,sp,96
    800044ee:	8082                	ret
      iunlock(ip);
    800044f0:	854e                	mv	a0,s3
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	aa6080e7          	jalr	-1370(ra) # 80003f98 <iunlock>
      return ip;
    800044fa:	bfe9                	j	800044d4 <namex+0x6a>
      iunlockput(ip);
    800044fc:	854e                	mv	a0,s3
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	c3a080e7          	jalr	-966(ra) # 80004138 <iunlockput>
      return 0;
    80004506:	89d2                	mv	s3,s4
    80004508:	b7f1                	j	800044d4 <namex+0x6a>
  len = path - s;
    8000450a:	40b48633          	sub	a2,s1,a1
    8000450e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004512:	094cd463          	bge	s9,s4,8000459a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004516:	4639                	li	a2,14
    80004518:	8556                	mv	a0,s5
    8000451a:	ffffd097          	auipc	ra,0xffffd
    8000451e:	a00080e7          	jalr	-1536(ra) # 80000f1a <memmove>
  while(*path == '/')
    80004522:	0004c783          	lbu	a5,0(s1)
    80004526:	01279763          	bne	a5,s2,80004534 <namex+0xca>
    path++;
    8000452a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000452c:	0004c783          	lbu	a5,0(s1)
    80004530:	ff278de3          	beq	a5,s2,8000452a <namex+0xc0>
    ilock(ip);
    80004534:	854e                	mv	a0,s3
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	9a0080e7          	jalr	-1632(ra) # 80003ed6 <ilock>
    if(ip->type != T_DIR){
    8000453e:	04499783          	lh	a5,68(s3)
    80004542:	f98793e3          	bne	a5,s8,800044c8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004546:	000b0563          	beqz	s6,80004550 <namex+0xe6>
    8000454a:	0004c783          	lbu	a5,0(s1)
    8000454e:	d3cd                	beqz	a5,800044f0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004550:	865e                	mv	a2,s7
    80004552:	85d6                	mv	a1,s5
    80004554:	854e                	mv	a0,s3
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	e64080e7          	jalr	-412(ra) # 800043ba <dirlookup>
    8000455e:	8a2a                	mv	s4,a0
    80004560:	dd51                	beqz	a0,800044fc <namex+0x92>
    iunlockput(ip);
    80004562:	854e                	mv	a0,s3
    80004564:	00000097          	auipc	ra,0x0
    80004568:	bd4080e7          	jalr	-1068(ra) # 80004138 <iunlockput>
    ip = next;
    8000456c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000456e:	0004c783          	lbu	a5,0(s1)
    80004572:	05279763          	bne	a5,s2,800045c0 <namex+0x156>
    path++;
    80004576:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004578:	0004c783          	lbu	a5,0(s1)
    8000457c:	ff278de3          	beq	a5,s2,80004576 <namex+0x10c>
  if(*path == 0)
    80004580:	c79d                	beqz	a5,800045ae <namex+0x144>
    path++;
    80004582:	85a6                	mv	a1,s1
  len = path - s;
    80004584:	8a5e                	mv	s4,s7
    80004586:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004588:	01278963          	beq	a5,s2,8000459a <namex+0x130>
    8000458c:	dfbd                	beqz	a5,8000450a <namex+0xa0>
    path++;
    8000458e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004590:	0004c783          	lbu	a5,0(s1)
    80004594:	ff279ce3          	bne	a5,s2,8000458c <namex+0x122>
    80004598:	bf8d                	j	8000450a <namex+0xa0>
    memmove(name, s, len);
    8000459a:	2601                	sext.w	a2,a2
    8000459c:	8556                	mv	a0,s5
    8000459e:	ffffd097          	auipc	ra,0xffffd
    800045a2:	97c080e7          	jalr	-1668(ra) # 80000f1a <memmove>
    name[len] = 0;
    800045a6:	9a56                	add	s4,s4,s5
    800045a8:	000a0023          	sb	zero,0(s4)
    800045ac:	bf9d                	j	80004522 <namex+0xb8>
  if(nameiparent){
    800045ae:	f20b03e3          	beqz	s6,800044d4 <namex+0x6a>
    iput(ip);
    800045b2:	854e                	mv	a0,s3
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	adc080e7          	jalr	-1316(ra) # 80004090 <iput>
    return 0;
    800045bc:	4981                	li	s3,0
    800045be:	bf19                	j	800044d4 <namex+0x6a>
  if(*path == 0)
    800045c0:	d7fd                	beqz	a5,800045ae <namex+0x144>
  while(*path != '/' && *path != 0)
    800045c2:	0004c783          	lbu	a5,0(s1)
    800045c6:	85a6                	mv	a1,s1
    800045c8:	b7d1                	j	8000458c <namex+0x122>

00000000800045ca <dirlink>:
{
    800045ca:	7139                	addi	sp,sp,-64
    800045cc:	fc06                	sd	ra,56(sp)
    800045ce:	f822                	sd	s0,48(sp)
    800045d0:	f426                	sd	s1,40(sp)
    800045d2:	f04a                	sd	s2,32(sp)
    800045d4:	ec4e                	sd	s3,24(sp)
    800045d6:	e852                	sd	s4,16(sp)
    800045d8:	0080                	addi	s0,sp,64
    800045da:	892a                	mv	s2,a0
    800045dc:	8a2e                	mv	s4,a1
    800045de:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045e0:	4601                	li	a2,0
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	dd8080e7          	jalr	-552(ra) # 800043ba <dirlookup>
    800045ea:	e93d                	bnez	a0,80004660 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ec:	04c92483          	lw	s1,76(s2)
    800045f0:	c49d                	beqz	s1,8000461e <dirlink+0x54>
    800045f2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045f4:	4741                	li	a4,16
    800045f6:	86a6                	mv	a3,s1
    800045f8:	fc040613          	addi	a2,s0,-64
    800045fc:	4581                	li	a1,0
    800045fe:	854a                	mv	a0,s2
    80004600:	00000097          	auipc	ra,0x0
    80004604:	b8a080e7          	jalr	-1142(ra) # 8000418a <readi>
    80004608:	47c1                	li	a5,16
    8000460a:	06f51163          	bne	a0,a5,8000466c <dirlink+0xa2>
    if(de.inum == 0)
    8000460e:	fc045783          	lhu	a5,-64(s0)
    80004612:	c791                	beqz	a5,8000461e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004614:	24c1                	addiw	s1,s1,16
    80004616:	04c92783          	lw	a5,76(s2)
    8000461a:	fcf4ede3          	bltu	s1,a5,800045f4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000461e:	4639                	li	a2,14
    80004620:	85d2                	mv	a1,s4
    80004622:	fc240513          	addi	a0,s0,-62
    80004626:	ffffd097          	auipc	ra,0xffffd
    8000462a:	9a8080e7          	jalr	-1624(ra) # 80000fce <strncpy>
  de.inum = inum;
    8000462e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004632:	4741                	li	a4,16
    80004634:	86a6                	mv	a3,s1
    80004636:	fc040613          	addi	a2,s0,-64
    8000463a:	4581                	li	a1,0
    8000463c:	854a                	mv	a0,s2
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	c44080e7          	jalr	-956(ra) # 80004282 <writei>
    80004646:	872a                	mv	a4,a0
    80004648:	47c1                	li	a5,16
  return 0;
    8000464a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000464c:	02f71863          	bne	a4,a5,8000467c <dirlink+0xb2>
}
    80004650:	70e2                	ld	ra,56(sp)
    80004652:	7442                	ld	s0,48(sp)
    80004654:	74a2                	ld	s1,40(sp)
    80004656:	7902                	ld	s2,32(sp)
    80004658:	69e2                	ld	s3,24(sp)
    8000465a:	6a42                	ld	s4,16(sp)
    8000465c:	6121                	addi	sp,sp,64
    8000465e:	8082                	ret
    iput(ip);
    80004660:	00000097          	auipc	ra,0x0
    80004664:	a30080e7          	jalr	-1488(ra) # 80004090 <iput>
    return -1;
    80004668:	557d                	li	a0,-1
    8000466a:	b7dd                	j	80004650 <dirlink+0x86>
      panic("dirlink read");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	29450513          	addi	a0,a0,660 # 80008900 <sysparameters+0x188>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>
    panic("dirlink");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	38c50513          	addi	a0,a0,908 # 80008a08 <sysparameters+0x290>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>

000000008000468c <namei>:

struct inode*
namei(char *path)
{
    8000468c:	1101                	addi	sp,sp,-32
    8000468e:	ec06                	sd	ra,24(sp)
    80004690:	e822                	sd	s0,16(sp)
    80004692:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004694:	fe040613          	addi	a2,s0,-32
    80004698:	4581                	li	a1,0
    8000469a:	00000097          	auipc	ra,0x0
    8000469e:	dd0080e7          	jalr	-560(ra) # 8000446a <namex>
}
    800046a2:	60e2                	ld	ra,24(sp)
    800046a4:	6442                	ld	s0,16(sp)
    800046a6:	6105                	addi	sp,sp,32
    800046a8:	8082                	ret

00000000800046aa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046aa:	1141                	addi	sp,sp,-16
    800046ac:	e406                	sd	ra,8(sp)
    800046ae:	e022                	sd	s0,0(sp)
    800046b0:	0800                	addi	s0,sp,16
    800046b2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046b4:	4585                	li	a1,1
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	db4080e7          	jalr	-588(ra) # 8000446a <namex>
}
    800046be:	60a2                	ld	ra,8(sp)
    800046c0:	6402                	ld	s0,0(sp)
    800046c2:	0141                	addi	sp,sp,16
    800046c4:	8082                	ret

00000000800046c6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046c6:	1101                	addi	sp,sp,-32
    800046c8:	ec06                	sd	ra,24(sp)
    800046ca:	e822                	sd	s0,16(sp)
    800046cc:	e426                	sd	s1,8(sp)
    800046ce:	e04a                	sd	s2,0(sp)
    800046d0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046d2:	0023e917          	auipc	s2,0x23e
    800046d6:	db690913          	addi	s2,s2,-586 # 80242488 <log>
    800046da:	01892583          	lw	a1,24(s2)
    800046de:	02892503          	lw	a0,40(s2)
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	ff2080e7          	jalr	-14(ra) # 800036d4 <bread>
    800046ea:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046ec:	02c92683          	lw	a3,44(s2)
    800046f0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046f2:	02d05763          	blez	a3,80004720 <write_head+0x5a>
    800046f6:	0023e797          	auipc	a5,0x23e
    800046fa:	dc278793          	addi	a5,a5,-574 # 802424b8 <log+0x30>
    800046fe:	05c50713          	addi	a4,a0,92
    80004702:	36fd                	addiw	a3,a3,-1
    80004704:	1682                	slli	a3,a3,0x20
    80004706:	9281                	srli	a3,a3,0x20
    80004708:	068a                	slli	a3,a3,0x2
    8000470a:	0023e617          	auipc	a2,0x23e
    8000470e:	db260613          	addi	a2,a2,-590 # 802424bc <log+0x34>
    80004712:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004714:	4390                	lw	a2,0(a5)
    80004716:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004718:	0791                	addi	a5,a5,4
    8000471a:	0711                	addi	a4,a4,4
    8000471c:	fed79ce3          	bne	a5,a3,80004714 <write_head+0x4e>
  }
  bwrite(buf);
    80004720:	8526                	mv	a0,s1
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	0a4080e7          	jalr	164(ra) # 800037c6 <bwrite>
  brelse(buf);
    8000472a:	8526                	mv	a0,s1
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	0d8080e7          	jalr	216(ra) # 80003804 <brelse>
}
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	64a2                	ld	s1,8(sp)
    8000473a:	6902                	ld	s2,0(sp)
    8000473c:	6105                	addi	sp,sp,32
    8000473e:	8082                	ret

0000000080004740 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004740:	0023e797          	auipc	a5,0x23e
    80004744:	d747a783          	lw	a5,-652(a5) # 802424b4 <log+0x2c>
    80004748:	0af05d63          	blez	a5,80004802 <install_trans+0xc2>
{
    8000474c:	7139                	addi	sp,sp,-64
    8000474e:	fc06                	sd	ra,56(sp)
    80004750:	f822                	sd	s0,48(sp)
    80004752:	f426                	sd	s1,40(sp)
    80004754:	f04a                	sd	s2,32(sp)
    80004756:	ec4e                	sd	s3,24(sp)
    80004758:	e852                	sd	s4,16(sp)
    8000475a:	e456                	sd	s5,8(sp)
    8000475c:	e05a                	sd	s6,0(sp)
    8000475e:	0080                	addi	s0,sp,64
    80004760:	8b2a                	mv	s6,a0
    80004762:	0023ea97          	auipc	s5,0x23e
    80004766:	d56a8a93          	addi	s5,s5,-682 # 802424b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000476c:	0023e997          	auipc	s3,0x23e
    80004770:	d1c98993          	addi	s3,s3,-740 # 80242488 <log>
    80004774:	a035                	j	800047a0 <install_trans+0x60>
      bunpin(dbuf);
    80004776:	8526                	mv	a0,s1
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	166080e7          	jalr	358(ra) # 800038de <bunpin>
    brelse(lbuf);
    80004780:	854a                	mv	a0,s2
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	082080e7          	jalr	130(ra) # 80003804 <brelse>
    brelse(dbuf);
    8000478a:	8526                	mv	a0,s1
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	078080e7          	jalr	120(ra) # 80003804 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004794:	2a05                	addiw	s4,s4,1
    80004796:	0a91                	addi	s5,s5,4
    80004798:	02c9a783          	lw	a5,44(s3)
    8000479c:	04fa5963          	bge	s4,a5,800047ee <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047a0:	0189a583          	lw	a1,24(s3)
    800047a4:	014585bb          	addw	a1,a1,s4
    800047a8:	2585                	addiw	a1,a1,1
    800047aa:	0289a503          	lw	a0,40(s3)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	f26080e7          	jalr	-218(ra) # 800036d4 <bread>
    800047b6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047b8:	000aa583          	lw	a1,0(s5)
    800047bc:	0289a503          	lw	a0,40(s3)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	f14080e7          	jalr	-236(ra) # 800036d4 <bread>
    800047c8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047ca:	40000613          	li	a2,1024
    800047ce:	05890593          	addi	a1,s2,88
    800047d2:	05850513          	addi	a0,a0,88
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	744080e7          	jalr	1860(ra) # 80000f1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800047de:	8526                	mv	a0,s1
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	fe6080e7          	jalr	-26(ra) # 800037c6 <bwrite>
    if(recovering == 0)
    800047e8:	f80b1ce3          	bnez	s6,80004780 <install_trans+0x40>
    800047ec:	b769                	j	80004776 <install_trans+0x36>
}
    800047ee:	70e2                	ld	ra,56(sp)
    800047f0:	7442                	ld	s0,48(sp)
    800047f2:	74a2                	ld	s1,40(sp)
    800047f4:	7902                	ld	s2,32(sp)
    800047f6:	69e2                	ld	s3,24(sp)
    800047f8:	6a42                	ld	s4,16(sp)
    800047fa:	6aa2                	ld	s5,8(sp)
    800047fc:	6b02                	ld	s6,0(sp)
    800047fe:	6121                	addi	sp,sp,64
    80004800:	8082                	ret
    80004802:	8082                	ret

0000000080004804 <initlog>:
{
    80004804:	7179                	addi	sp,sp,-48
    80004806:	f406                	sd	ra,40(sp)
    80004808:	f022                	sd	s0,32(sp)
    8000480a:	ec26                	sd	s1,24(sp)
    8000480c:	e84a                	sd	s2,16(sp)
    8000480e:	e44e                	sd	s3,8(sp)
    80004810:	1800                	addi	s0,sp,48
    80004812:	892a                	mv	s2,a0
    80004814:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004816:	0023e497          	auipc	s1,0x23e
    8000481a:	c7248493          	addi	s1,s1,-910 # 80242488 <log>
    8000481e:	00004597          	auipc	a1,0x4
    80004822:	0f258593          	addi	a1,a1,242 # 80008910 <sysparameters+0x198>
    80004826:	8526                	mv	a0,s1
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	506080e7          	jalr	1286(ra) # 80000d2e <initlock>
  log.start = sb->logstart;
    80004830:	0149a583          	lw	a1,20(s3)
    80004834:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004836:	0109a783          	lw	a5,16(s3)
    8000483a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000483c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004840:	854a                	mv	a0,s2
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	e92080e7          	jalr	-366(ra) # 800036d4 <bread>
  log.lh.n = lh->n;
    8000484a:	4d3c                	lw	a5,88(a0)
    8000484c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000484e:	02f05563          	blez	a5,80004878 <initlog+0x74>
    80004852:	05c50713          	addi	a4,a0,92
    80004856:	0023e697          	auipc	a3,0x23e
    8000485a:	c6268693          	addi	a3,a3,-926 # 802424b8 <log+0x30>
    8000485e:	37fd                	addiw	a5,a5,-1
    80004860:	1782                	slli	a5,a5,0x20
    80004862:	9381                	srli	a5,a5,0x20
    80004864:	078a                	slli	a5,a5,0x2
    80004866:	06050613          	addi	a2,a0,96
    8000486a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000486c:	4310                	lw	a2,0(a4)
    8000486e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004870:	0711                	addi	a4,a4,4
    80004872:	0691                	addi	a3,a3,4
    80004874:	fef71ce3          	bne	a4,a5,8000486c <initlog+0x68>
  brelse(buf);
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	f8c080e7          	jalr	-116(ra) # 80003804 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004880:	4505                	li	a0,1
    80004882:	00000097          	auipc	ra,0x0
    80004886:	ebe080e7          	jalr	-322(ra) # 80004740 <install_trans>
  log.lh.n = 0;
    8000488a:	0023e797          	auipc	a5,0x23e
    8000488e:	c207a523          	sw	zero,-982(a5) # 802424b4 <log+0x2c>
  write_head(); // clear the log
    80004892:	00000097          	auipc	ra,0x0
    80004896:	e34080e7          	jalr	-460(ra) # 800046c6 <write_head>
}
    8000489a:	70a2                	ld	ra,40(sp)
    8000489c:	7402                	ld	s0,32(sp)
    8000489e:	64e2                	ld	s1,24(sp)
    800048a0:	6942                	ld	s2,16(sp)
    800048a2:	69a2                	ld	s3,8(sp)
    800048a4:	6145                	addi	sp,sp,48
    800048a6:	8082                	ret

00000000800048a8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048a8:	1101                	addi	sp,sp,-32
    800048aa:	ec06                	sd	ra,24(sp)
    800048ac:	e822                	sd	s0,16(sp)
    800048ae:	e426                	sd	s1,8(sp)
    800048b0:	e04a                	sd	s2,0(sp)
    800048b2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048b4:	0023e517          	auipc	a0,0x23e
    800048b8:	bd450513          	addi	a0,a0,-1068 # 80242488 <log>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	502080e7          	jalr	1282(ra) # 80000dbe <acquire>
  while(1){
    if(log.committing){
    800048c4:	0023e497          	auipc	s1,0x23e
    800048c8:	bc448493          	addi	s1,s1,-1084 # 80242488 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048cc:	4979                	li	s2,30
    800048ce:	a039                	j	800048dc <begin_op+0x34>
      sleep(&log, &log.lock);
    800048d0:	85a6                	mv	a1,s1
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffe097          	auipc	ra,0xffffe
    800048d8:	aca080e7          	jalr	-1334(ra) # 8000239e <sleep>
    if(log.committing){
    800048dc:	50dc                	lw	a5,36(s1)
    800048de:	fbed                	bnez	a5,800048d0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048e0:	509c                	lw	a5,32(s1)
    800048e2:	0017871b          	addiw	a4,a5,1
    800048e6:	0007069b          	sext.w	a3,a4
    800048ea:	0027179b          	slliw	a5,a4,0x2
    800048ee:	9fb9                	addw	a5,a5,a4
    800048f0:	0017979b          	slliw	a5,a5,0x1
    800048f4:	54d8                	lw	a4,44(s1)
    800048f6:	9fb9                	addw	a5,a5,a4
    800048f8:	00f95963          	bge	s2,a5,8000490a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048fc:	85a6                	mv	a1,s1
    800048fe:	8526                	mv	a0,s1
    80004900:	ffffe097          	auipc	ra,0xffffe
    80004904:	a9e080e7          	jalr	-1378(ra) # 8000239e <sleep>
    80004908:	bfd1                	j	800048dc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000490a:	0023e517          	auipc	a0,0x23e
    8000490e:	b7e50513          	addi	a0,a0,-1154 # 80242488 <log>
    80004912:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	55e080e7          	jalr	1374(ra) # 80000e72 <release>
      break;
    }
  }
}
    8000491c:	60e2                	ld	ra,24(sp)
    8000491e:	6442                	ld	s0,16(sp)
    80004920:	64a2                	ld	s1,8(sp)
    80004922:	6902                	ld	s2,0(sp)
    80004924:	6105                	addi	sp,sp,32
    80004926:	8082                	ret

0000000080004928 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004928:	7139                	addi	sp,sp,-64
    8000492a:	fc06                	sd	ra,56(sp)
    8000492c:	f822                	sd	s0,48(sp)
    8000492e:	f426                	sd	s1,40(sp)
    80004930:	f04a                	sd	s2,32(sp)
    80004932:	ec4e                	sd	s3,24(sp)
    80004934:	e852                	sd	s4,16(sp)
    80004936:	e456                	sd	s5,8(sp)
    80004938:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000493a:	0023e497          	auipc	s1,0x23e
    8000493e:	b4e48493          	addi	s1,s1,-1202 # 80242488 <log>
    80004942:	8526                	mv	a0,s1
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	47a080e7          	jalr	1146(ra) # 80000dbe <acquire>
  log.outstanding -= 1;
    8000494c:	509c                	lw	a5,32(s1)
    8000494e:	37fd                	addiw	a5,a5,-1
    80004950:	0007891b          	sext.w	s2,a5
    80004954:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004956:	50dc                	lw	a5,36(s1)
    80004958:	efb9                	bnez	a5,800049b6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000495a:	06091663          	bnez	s2,800049c6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000495e:	0023e497          	auipc	s1,0x23e
    80004962:	b2a48493          	addi	s1,s1,-1238 # 80242488 <log>
    80004966:	4785                	li	a5,1
    80004968:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000496a:	8526                	mv	a0,s1
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	506080e7          	jalr	1286(ra) # 80000e72 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004974:	54dc                	lw	a5,44(s1)
    80004976:	06f04763          	bgtz	a5,800049e4 <end_op+0xbc>
    acquire(&log.lock);
    8000497a:	0023e497          	auipc	s1,0x23e
    8000497e:	b0e48493          	addi	s1,s1,-1266 # 80242488 <log>
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	43a080e7          	jalr	1082(ra) # 80000dbe <acquire>
    log.committing = 0;
    8000498c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004990:	8526                	mv	a0,s1
    80004992:	ffffe097          	auipc	ra,0xffffe
    80004996:	ce4080e7          	jalr	-796(ra) # 80002676 <wakeup>
    release(&log.lock);
    8000499a:	8526                	mv	a0,s1
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	4d6080e7          	jalr	1238(ra) # 80000e72 <release>
}
    800049a4:	70e2                	ld	ra,56(sp)
    800049a6:	7442                	ld	s0,48(sp)
    800049a8:	74a2                	ld	s1,40(sp)
    800049aa:	7902                	ld	s2,32(sp)
    800049ac:	69e2                	ld	s3,24(sp)
    800049ae:	6a42                	ld	s4,16(sp)
    800049b0:	6aa2                	ld	s5,8(sp)
    800049b2:	6121                	addi	sp,sp,64
    800049b4:	8082                	ret
    panic("log.committing");
    800049b6:	00004517          	auipc	a0,0x4
    800049ba:	f6250513          	addi	a0,a0,-158 # 80008918 <sysparameters+0x1a0>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>
    wakeup(&log);
    800049c6:	0023e497          	auipc	s1,0x23e
    800049ca:	ac248493          	addi	s1,s1,-1342 # 80242488 <log>
    800049ce:	8526                	mv	a0,s1
    800049d0:	ffffe097          	auipc	ra,0xffffe
    800049d4:	ca6080e7          	jalr	-858(ra) # 80002676 <wakeup>
  release(&log.lock);
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	498080e7          	jalr	1176(ra) # 80000e72 <release>
  if(do_commit){
    800049e2:	b7c9                	j	800049a4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049e4:	0023ea97          	auipc	s5,0x23e
    800049e8:	ad4a8a93          	addi	s5,s5,-1324 # 802424b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049ec:	0023ea17          	auipc	s4,0x23e
    800049f0:	a9ca0a13          	addi	s4,s4,-1380 # 80242488 <log>
    800049f4:	018a2583          	lw	a1,24(s4)
    800049f8:	012585bb          	addw	a1,a1,s2
    800049fc:	2585                	addiw	a1,a1,1
    800049fe:	028a2503          	lw	a0,40(s4)
    80004a02:	fffff097          	auipc	ra,0xfffff
    80004a06:	cd2080e7          	jalr	-814(ra) # 800036d4 <bread>
    80004a0a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a0c:	000aa583          	lw	a1,0(s5)
    80004a10:	028a2503          	lw	a0,40(s4)
    80004a14:	fffff097          	auipc	ra,0xfffff
    80004a18:	cc0080e7          	jalr	-832(ra) # 800036d4 <bread>
    80004a1c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a1e:	40000613          	li	a2,1024
    80004a22:	05850593          	addi	a1,a0,88
    80004a26:	05848513          	addi	a0,s1,88
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	4f0080e7          	jalr	1264(ra) # 80000f1a <memmove>
    bwrite(to);  // write the log
    80004a32:	8526                	mv	a0,s1
    80004a34:	fffff097          	auipc	ra,0xfffff
    80004a38:	d92080e7          	jalr	-622(ra) # 800037c6 <bwrite>
    brelse(from);
    80004a3c:	854e                	mv	a0,s3
    80004a3e:	fffff097          	auipc	ra,0xfffff
    80004a42:	dc6080e7          	jalr	-570(ra) # 80003804 <brelse>
    brelse(to);
    80004a46:	8526                	mv	a0,s1
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	dbc080e7          	jalr	-580(ra) # 80003804 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a50:	2905                	addiw	s2,s2,1
    80004a52:	0a91                	addi	s5,s5,4
    80004a54:	02ca2783          	lw	a5,44(s4)
    80004a58:	f8f94ee3          	blt	s2,a5,800049f4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	c6a080e7          	jalr	-918(ra) # 800046c6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a64:	4501                	li	a0,0
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	cda080e7          	jalr	-806(ra) # 80004740 <install_trans>
    log.lh.n = 0;
    80004a6e:	0023e797          	auipc	a5,0x23e
    80004a72:	a407a323          	sw	zero,-1466(a5) # 802424b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a76:	00000097          	auipc	ra,0x0
    80004a7a:	c50080e7          	jalr	-944(ra) # 800046c6 <write_head>
    80004a7e:	bdf5                	j	8000497a <end_op+0x52>

0000000080004a80 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a80:	1101                	addi	sp,sp,-32
    80004a82:	ec06                	sd	ra,24(sp)
    80004a84:	e822                	sd	s0,16(sp)
    80004a86:	e426                	sd	s1,8(sp)
    80004a88:	e04a                	sd	s2,0(sp)
    80004a8a:	1000                	addi	s0,sp,32
    80004a8c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a8e:	0023e917          	auipc	s2,0x23e
    80004a92:	9fa90913          	addi	s2,s2,-1542 # 80242488 <log>
    80004a96:	854a                	mv	a0,s2
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	326080e7          	jalr	806(ra) # 80000dbe <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004aa0:	02c92603          	lw	a2,44(s2)
    80004aa4:	47f5                	li	a5,29
    80004aa6:	06c7c563          	blt	a5,a2,80004b10 <log_write+0x90>
    80004aaa:	0023e797          	auipc	a5,0x23e
    80004aae:	9fa7a783          	lw	a5,-1542(a5) # 802424a4 <log+0x1c>
    80004ab2:	37fd                	addiw	a5,a5,-1
    80004ab4:	04f65e63          	bge	a2,a5,80004b10 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ab8:	0023e797          	auipc	a5,0x23e
    80004abc:	9f07a783          	lw	a5,-1552(a5) # 802424a8 <log+0x20>
    80004ac0:	06f05063          	blez	a5,80004b20 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ac4:	4781                	li	a5,0
    80004ac6:	06c05563          	blez	a2,80004b30 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aca:	44cc                	lw	a1,12(s1)
    80004acc:	0023e717          	auipc	a4,0x23e
    80004ad0:	9ec70713          	addi	a4,a4,-1556 # 802424b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ad4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ad6:	4314                	lw	a3,0(a4)
    80004ad8:	04b68c63          	beq	a3,a1,80004b30 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004adc:	2785                	addiw	a5,a5,1
    80004ade:	0711                	addi	a4,a4,4
    80004ae0:	fef61be3          	bne	a2,a5,80004ad6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ae4:	0621                	addi	a2,a2,8
    80004ae6:	060a                	slli	a2,a2,0x2
    80004ae8:	0023e797          	auipc	a5,0x23e
    80004aec:	9a078793          	addi	a5,a5,-1632 # 80242488 <log>
    80004af0:	963e                	add	a2,a2,a5
    80004af2:	44dc                	lw	a5,12(s1)
    80004af4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004af6:	8526                	mv	a0,s1
    80004af8:	fffff097          	auipc	ra,0xfffff
    80004afc:	daa080e7          	jalr	-598(ra) # 800038a2 <bpin>
    log.lh.n++;
    80004b00:	0023e717          	auipc	a4,0x23e
    80004b04:	98870713          	addi	a4,a4,-1656 # 80242488 <log>
    80004b08:	575c                	lw	a5,44(a4)
    80004b0a:	2785                	addiw	a5,a5,1
    80004b0c:	d75c                	sw	a5,44(a4)
    80004b0e:	a835                	j	80004b4a <log_write+0xca>
    panic("too big a transaction");
    80004b10:	00004517          	auipc	a0,0x4
    80004b14:	e1850513          	addi	a0,a0,-488 # 80008928 <sysparameters+0x1b0>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	a26080e7          	jalr	-1498(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b20:	00004517          	auipc	a0,0x4
    80004b24:	e2050513          	addi	a0,a0,-480 # 80008940 <sysparameters+0x1c8>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	a16080e7          	jalr	-1514(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b30:	00878713          	addi	a4,a5,8
    80004b34:	00271693          	slli	a3,a4,0x2
    80004b38:	0023e717          	auipc	a4,0x23e
    80004b3c:	95070713          	addi	a4,a4,-1712 # 80242488 <log>
    80004b40:	9736                	add	a4,a4,a3
    80004b42:	44d4                	lw	a3,12(s1)
    80004b44:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b46:	faf608e3          	beq	a2,a5,80004af6 <log_write+0x76>
  }
  release(&log.lock);
    80004b4a:	0023e517          	auipc	a0,0x23e
    80004b4e:	93e50513          	addi	a0,a0,-1730 # 80242488 <log>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	320080e7          	jalr	800(ra) # 80000e72 <release>
}
    80004b5a:	60e2                	ld	ra,24(sp)
    80004b5c:	6442                	ld	s0,16(sp)
    80004b5e:	64a2                	ld	s1,8(sp)
    80004b60:	6902                	ld	s2,0(sp)
    80004b62:	6105                	addi	sp,sp,32
    80004b64:	8082                	ret

0000000080004b66 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b66:	1101                	addi	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	e426                	sd	s1,8(sp)
    80004b6e:	e04a                	sd	s2,0(sp)
    80004b70:	1000                	addi	s0,sp,32
    80004b72:	84aa                	mv	s1,a0
    80004b74:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b76:	00004597          	auipc	a1,0x4
    80004b7a:	dea58593          	addi	a1,a1,-534 # 80008960 <sysparameters+0x1e8>
    80004b7e:	0521                	addi	a0,a0,8
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	1ae080e7          	jalr	430(ra) # 80000d2e <initlock>
  lk->name = name;
    80004b88:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b8c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b90:	0204a423          	sw	zero,40(s1)
}
    80004b94:	60e2                	ld	ra,24(sp)
    80004b96:	6442                	ld	s0,16(sp)
    80004b98:	64a2                	ld	s1,8(sp)
    80004b9a:	6902                	ld	s2,0(sp)
    80004b9c:	6105                	addi	sp,sp,32
    80004b9e:	8082                	ret

0000000080004ba0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ba0:	1101                	addi	sp,sp,-32
    80004ba2:	ec06                	sd	ra,24(sp)
    80004ba4:	e822                	sd	s0,16(sp)
    80004ba6:	e426                	sd	s1,8(sp)
    80004ba8:	e04a                	sd	s2,0(sp)
    80004baa:	1000                	addi	s0,sp,32
    80004bac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bae:	00850913          	addi	s2,a0,8
    80004bb2:	854a                	mv	a0,s2
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	20a080e7          	jalr	522(ra) # 80000dbe <acquire>
  while (lk->locked) {
    80004bbc:	409c                	lw	a5,0(s1)
    80004bbe:	cb89                	beqz	a5,80004bd0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bc0:	85ca                	mv	a1,s2
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffd097          	auipc	ra,0xffffd
    80004bc8:	7da080e7          	jalr	2010(ra) # 8000239e <sleep>
  while (lk->locked) {
    80004bcc:	409c                	lw	a5,0(s1)
    80004bce:	fbed                	bnez	a5,80004bc0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bd0:	4785                	li	a5,1
    80004bd2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	ffa080e7          	jalr	-6(ra) # 80001bce <myproc>
    80004bdc:	591c                	lw	a5,48(a0)
    80004bde:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004be0:	854a                	mv	a0,s2
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	290080e7          	jalr	656(ra) # 80000e72 <release>
}
    80004bea:	60e2                	ld	ra,24(sp)
    80004bec:	6442                	ld	s0,16(sp)
    80004bee:	64a2                	ld	s1,8(sp)
    80004bf0:	6902                	ld	s2,0(sp)
    80004bf2:	6105                	addi	sp,sp,32
    80004bf4:	8082                	ret

0000000080004bf6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bf6:	1101                	addi	sp,sp,-32
    80004bf8:	ec06                	sd	ra,24(sp)
    80004bfa:	e822                	sd	s0,16(sp)
    80004bfc:	e426                	sd	s1,8(sp)
    80004bfe:	e04a                	sd	s2,0(sp)
    80004c00:	1000                	addi	s0,sp,32
    80004c02:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c04:	00850913          	addi	s2,a0,8
    80004c08:	854a                	mv	a0,s2
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	1b4080e7          	jalr	436(ra) # 80000dbe <acquire>
  lk->locked = 0;
    80004c12:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c16:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c1a:	8526                	mv	a0,s1
    80004c1c:	ffffe097          	auipc	ra,0xffffe
    80004c20:	a5a080e7          	jalr	-1446(ra) # 80002676 <wakeup>
  release(&lk->lk);
    80004c24:	854a                	mv	a0,s2
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	24c080e7          	jalr	588(ra) # 80000e72 <release>
}
    80004c2e:	60e2                	ld	ra,24(sp)
    80004c30:	6442                	ld	s0,16(sp)
    80004c32:	64a2                	ld	s1,8(sp)
    80004c34:	6902                	ld	s2,0(sp)
    80004c36:	6105                	addi	sp,sp,32
    80004c38:	8082                	ret

0000000080004c3a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c3a:	7179                	addi	sp,sp,-48
    80004c3c:	f406                	sd	ra,40(sp)
    80004c3e:	f022                	sd	s0,32(sp)
    80004c40:	ec26                	sd	s1,24(sp)
    80004c42:	e84a                	sd	s2,16(sp)
    80004c44:	e44e                	sd	s3,8(sp)
    80004c46:	1800                	addi	s0,sp,48
    80004c48:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c4a:	00850913          	addi	s2,a0,8
    80004c4e:	854a                	mv	a0,s2
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	16e080e7          	jalr	366(ra) # 80000dbe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c58:	409c                	lw	a5,0(s1)
    80004c5a:	ef99                	bnez	a5,80004c78 <holdingsleep+0x3e>
    80004c5c:	4481                	li	s1,0
  release(&lk->lk);
    80004c5e:	854a                	mv	a0,s2
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	212080e7          	jalr	530(ra) # 80000e72 <release>
  return r;
}
    80004c68:	8526                	mv	a0,s1
    80004c6a:	70a2                	ld	ra,40(sp)
    80004c6c:	7402                	ld	s0,32(sp)
    80004c6e:	64e2                	ld	s1,24(sp)
    80004c70:	6942                	ld	s2,16(sp)
    80004c72:	69a2                	ld	s3,8(sp)
    80004c74:	6145                	addi	sp,sp,48
    80004c76:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c78:	0284a983          	lw	s3,40(s1)
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	f52080e7          	jalr	-174(ra) # 80001bce <myproc>
    80004c84:	5904                	lw	s1,48(a0)
    80004c86:	413484b3          	sub	s1,s1,s3
    80004c8a:	0014b493          	seqz	s1,s1
    80004c8e:	bfc1                	j	80004c5e <holdingsleep+0x24>

0000000080004c90 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c90:	1141                	addi	sp,sp,-16
    80004c92:	e406                	sd	ra,8(sp)
    80004c94:	e022                	sd	s0,0(sp)
    80004c96:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c98:	00004597          	auipc	a1,0x4
    80004c9c:	cd858593          	addi	a1,a1,-808 # 80008970 <sysparameters+0x1f8>
    80004ca0:	0023e517          	auipc	a0,0x23e
    80004ca4:	93050513          	addi	a0,a0,-1744 # 802425d0 <ftable>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	086080e7          	jalr	134(ra) # 80000d2e <initlock>
}
    80004cb0:	60a2                	ld	ra,8(sp)
    80004cb2:	6402                	ld	s0,0(sp)
    80004cb4:	0141                	addi	sp,sp,16
    80004cb6:	8082                	ret

0000000080004cb8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cb8:	1101                	addi	sp,sp,-32
    80004cba:	ec06                	sd	ra,24(sp)
    80004cbc:	e822                	sd	s0,16(sp)
    80004cbe:	e426                	sd	s1,8(sp)
    80004cc0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cc2:	0023e517          	auipc	a0,0x23e
    80004cc6:	90e50513          	addi	a0,a0,-1778 # 802425d0 <ftable>
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	0f4080e7          	jalr	244(ra) # 80000dbe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cd2:	0023e497          	auipc	s1,0x23e
    80004cd6:	91648493          	addi	s1,s1,-1770 # 802425e8 <ftable+0x18>
    80004cda:	0023f717          	auipc	a4,0x23f
    80004cde:	8ae70713          	addi	a4,a4,-1874 # 80243588 <ftable+0xfb8>
    if(f->ref == 0){
    80004ce2:	40dc                	lw	a5,4(s1)
    80004ce4:	cf99                	beqz	a5,80004d02 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ce6:	02848493          	addi	s1,s1,40
    80004cea:	fee49ce3          	bne	s1,a4,80004ce2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cee:	0023e517          	auipc	a0,0x23e
    80004cf2:	8e250513          	addi	a0,a0,-1822 # 802425d0 <ftable>
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	17c080e7          	jalr	380(ra) # 80000e72 <release>
  return 0;
    80004cfe:	4481                	li	s1,0
    80004d00:	a819                	j	80004d16 <filealloc+0x5e>
      f->ref = 1;
    80004d02:	4785                	li	a5,1
    80004d04:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d06:	0023e517          	auipc	a0,0x23e
    80004d0a:	8ca50513          	addi	a0,a0,-1846 # 802425d0 <ftable>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	164080e7          	jalr	356(ra) # 80000e72 <release>
}
    80004d16:	8526                	mv	a0,s1
    80004d18:	60e2                	ld	ra,24(sp)
    80004d1a:	6442                	ld	s0,16(sp)
    80004d1c:	64a2                	ld	s1,8(sp)
    80004d1e:	6105                	addi	sp,sp,32
    80004d20:	8082                	ret

0000000080004d22 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d22:	1101                	addi	sp,sp,-32
    80004d24:	ec06                	sd	ra,24(sp)
    80004d26:	e822                	sd	s0,16(sp)
    80004d28:	e426                	sd	s1,8(sp)
    80004d2a:	1000                	addi	s0,sp,32
    80004d2c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d2e:	0023e517          	auipc	a0,0x23e
    80004d32:	8a250513          	addi	a0,a0,-1886 # 802425d0 <ftable>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	088080e7          	jalr	136(ra) # 80000dbe <acquire>
  if(f->ref < 1)
    80004d3e:	40dc                	lw	a5,4(s1)
    80004d40:	02f05263          	blez	a5,80004d64 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d44:	2785                	addiw	a5,a5,1
    80004d46:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d48:	0023e517          	auipc	a0,0x23e
    80004d4c:	88850513          	addi	a0,a0,-1912 # 802425d0 <ftable>
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	122080e7          	jalr	290(ra) # 80000e72 <release>
  return f;
}
    80004d58:	8526                	mv	a0,s1
    80004d5a:	60e2                	ld	ra,24(sp)
    80004d5c:	6442                	ld	s0,16(sp)
    80004d5e:	64a2                	ld	s1,8(sp)
    80004d60:	6105                	addi	sp,sp,32
    80004d62:	8082                	ret
    panic("filedup");
    80004d64:	00004517          	auipc	a0,0x4
    80004d68:	c1450513          	addi	a0,a0,-1004 # 80008978 <sysparameters+0x200>
    80004d6c:	ffffb097          	auipc	ra,0xffffb
    80004d70:	7d2080e7          	jalr	2002(ra) # 8000053e <panic>

0000000080004d74 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d74:	7139                	addi	sp,sp,-64
    80004d76:	fc06                	sd	ra,56(sp)
    80004d78:	f822                	sd	s0,48(sp)
    80004d7a:	f426                	sd	s1,40(sp)
    80004d7c:	f04a                	sd	s2,32(sp)
    80004d7e:	ec4e                	sd	s3,24(sp)
    80004d80:	e852                	sd	s4,16(sp)
    80004d82:	e456                	sd	s5,8(sp)
    80004d84:	0080                	addi	s0,sp,64
    80004d86:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d88:	0023e517          	auipc	a0,0x23e
    80004d8c:	84850513          	addi	a0,a0,-1976 # 802425d0 <ftable>
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	02e080e7          	jalr	46(ra) # 80000dbe <acquire>
  if(f->ref < 1)
    80004d98:	40dc                	lw	a5,4(s1)
    80004d9a:	06f05163          	blez	a5,80004dfc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d9e:	37fd                	addiw	a5,a5,-1
    80004da0:	0007871b          	sext.w	a4,a5
    80004da4:	c0dc                	sw	a5,4(s1)
    80004da6:	06e04363          	bgtz	a4,80004e0c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004daa:	0004a903          	lw	s2,0(s1)
    80004dae:	0094ca83          	lbu	s5,9(s1)
    80004db2:	0104ba03          	ld	s4,16(s1)
    80004db6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dbe:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004dc2:	0023e517          	auipc	a0,0x23e
    80004dc6:	80e50513          	addi	a0,a0,-2034 # 802425d0 <ftable>
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	0a8080e7          	jalr	168(ra) # 80000e72 <release>

  if(ff.type == FD_PIPE){
    80004dd2:	4785                	li	a5,1
    80004dd4:	04f90d63          	beq	s2,a5,80004e2e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dd8:	3979                	addiw	s2,s2,-2
    80004dda:	4785                	li	a5,1
    80004ddc:	0527e063          	bltu	a5,s2,80004e1c <fileclose+0xa8>
    begin_op();
    80004de0:	00000097          	auipc	ra,0x0
    80004de4:	ac8080e7          	jalr	-1336(ra) # 800048a8 <begin_op>
    iput(ff.ip);
    80004de8:	854e                	mv	a0,s3
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	2a6080e7          	jalr	678(ra) # 80004090 <iput>
    end_op();
    80004df2:	00000097          	auipc	ra,0x0
    80004df6:	b36080e7          	jalr	-1226(ra) # 80004928 <end_op>
    80004dfa:	a00d                	j	80004e1c <fileclose+0xa8>
    panic("fileclose");
    80004dfc:	00004517          	auipc	a0,0x4
    80004e00:	b8450513          	addi	a0,a0,-1148 # 80008980 <sysparameters+0x208>
    80004e04:	ffffb097          	auipc	ra,0xffffb
    80004e08:	73a080e7          	jalr	1850(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e0c:	0023d517          	auipc	a0,0x23d
    80004e10:	7c450513          	addi	a0,a0,1988 # 802425d0 <ftable>
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	05e080e7          	jalr	94(ra) # 80000e72 <release>
  }
}
    80004e1c:	70e2                	ld	ra,56(sp)
    80004e1e:	7442                	ld	s0,48(sp)
    80004e20:	74a2                	ld	s1,40(sp)
    80004e22:	7902                	ld	s2,32(sp)
    80004e24:	69e2                	ld	s3,24(sp)
    80004e26:	6a42                	ld	s4,16(sp)
    80004e28:	6aa2                	ld	s5,8(sp)
    80004e2a:	6121                	addi	sp,sp,64
    80004e2c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e2e:	85d6                	mv	a1,s5
    80004e30:	8552                	mv	a0,s4
    80004e32:	00000097          	auipc	ra,0x0
    80004e36:	34c080e7          	jalr	844(ra) # 8000517e <pipeclose>
    80004e3a:	b7cd                	j	80004e1c <fileclose+0xa8>

0000000080004e3c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e3c:	715d                	addi	sp,sp,-80
    80004e3e:	e486                	sd	ra,72(sp)
    80004e40:	e0a2                	sd	s0,64(sp)
    80004e42:	fc26                	sd	s1,56(sp)
    80004e44:	f84a                	sd	s2,48(sp)
    80004e46:	f44e                	sd	s3,40(sp)
    80004e48:	0880                	addi	s0,sp,80
    80004e4a:	84aa                	mv	s1,a0
    80004e4c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	d80080e7          	jalr	-640(ra) # 80001bce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e56:	409c                	lw	a5,0(s1)
    80004e58:	37f9                	addiw	a5,a5,-2
    80004e5a:	4705                	li	a4,1
    80004e5c:	04f76763          	bltu	a4,a5,80004eaa <filestat+0x6e>
    80004e60:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e62:	6c88                	ld	a0,24(s1)
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	072080e7          	jalr	114(ra) # 80003ed6 <ilock>
    stati(f->ip, &st);
    80004e6c:	fb840593          	addi	a1,s0,-72
    80004e70:	6c88                	ld	a0,24(s1)
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	2ee080e7          	jalr	750(ra) # 80004160 <stati>
    iunlock(f->ip);
    80004e7a:	6c88                	ld	a0,24(s1)
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	11c080e7          	jalr	284(ra) # 80003f98 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e84:	46e1                	li	a3,24
    80004e86:	fb840613          	addi	a2,s0,-72
    80004e8a:	85ce                	mv	a1,s3
    80004e8c:	05093503          	ld	a0,80(s2)
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	9c4080e7          	jalr	-1596(ra) # 80001854 <copyout>
    80004e98:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e9c:	60a6                	ld	ra,72(sp)
    80004e9e:	6406                	ld	s0,64(sp)
    80004ea0:	74e2                	ld	s1,56(sp)
    80004ea2:	7942                	ld	s2,48(sp)
    80004ea4:	79a2                	ld	s3,40(sp)
    80004ea6:	6161                	addi	sp,sp,80
    80004ea8:	8082                	ret
  return -1;
    80004eaa:	557d                	li	a0,-1
    80004eac:	bfc5                	j	80004e9c <filestat+0x60>

0000000080004eae <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004eae:	7179                	addi	sp,sp,-48
    80004eb0:	f406                	sd	ra,40(sp)
    80004eb2:	f022                	sd	s0,32(sp)
    80004eb4:	ec26                	sd	s1,24(sp)
    80004eb6:	e84a                	sd	s2,16(sp)
    80004eb8:	e44e                	sd	s3,8(sp)
    80004eba:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ebc:	00854783          	lbu	a5,8(a0)
    80004ec0:	c3d5                	beqz	a5,80004f64 <fileread+0xb6>
    80004ec2:	84aa                	mv	s1,a0
    80004ec4:	89ae                	mv	s3,a1
    80004ec6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ec8:	411c                	lw	a5,0(a0)
    80004eca:	4705                	li	a4,1
    80004ecc:	04e78963          	beq	a5,a4,80004f1e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ed0:	470d                	li	a4,3
    80004ed2:	04e78d63          	beq	a5,a4,80004f2c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ed6:	4709                	li	a4,2
    80004ed8:	06e79e63          	bne	a5,a4,80004f54 <fileread+0xa6>
    ilock(f->ip);
    80004edc:	6d08                	ld	a0,24(a0)
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	ff8080e7          	jalr	-8(ra) # 80003ed6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ee6:	874a                	mv	a4,s2
    80004ee8:	5094                	lw	a3,32(s1)
    80004eea:	864e                	mv	a2,s3
    80004eec:	4585                	li	a1,1
    80004eee:	6c88                	ld	a0,24(s1)
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	29a080e7          	jalr	666(ra) # 8000418a <readi>
    80004ef8:	892a                	mv	s2,a0
    80004efa:	00a05563          	blez	a0,80004f04 <fileread+0x56>
      f->off += r;
    80004efe:	509c                	lw	a5,32(s1)
    80004f00:	9fa9                	addw	a5,a5,a0
    80004f02:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f04:	6c88                	ld	a0,24(s1)
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	092080e7          	jalr	146(ra) # 80003f98 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f0e:	854a                	mv	a0,s2
    80004f10:	70a2                	ld	ra,40(sp)
    80004f12:	7402                	ld	s0,32(sp)
    80004f14:	64e2                	ld	s1,24(sp)
    80004f16:	6942                	ld	s2,16(sp)
    80004f18:	69a2                	ld	s3,8(sp)
    80004f1a:	6145                	addi	sp,sp,48
    80004f1c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f1e:	6908                	ld	a0,16(a0)
    80004f20:	00000097          	auipc	ra,0x0
    80004f24:	3c8080e7          	jalr	968(ra) # 800052e8 <piperead>
    80004f28:	892a                	mv	s2,a0
    80004f2a:	b7d5                	j	80004f0e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f2c:	02451783          	lh	a5,36(a0)
    80004f30:	03079693          	slli	a3,a5,0x30
    80004f34:	92c1                	srli	a3,a3,0x30
    80004f36:	4725                	li	a4,9
    80004f38:	02d76863          	bltu	a4,a3,80004f68 <fileread+0xba>
    80004f3c:	0792                	slli	a5,a5,0x4
    80004f3e:	0023d717          	auipc	a4,0x23d
    80004f42:	5f270713          	addi	a4,a4,1522 # 80242530 <devsw>
    80004f46:	97ba                	add	a5,a5,a4
    80004f48:	639c                	ld	a5,0(a5)
    80004f4a:	c38d                	beqz	a5,80004f6c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f4c:	4505                	li	a0,1
    80004f4e:	9782                	jalr	a5
    80004f50:	892a                	mv	s2,a0
    80004f52:	bf75                	j	80004f0e <fileread+0x60>
    panic("fileread");
    80004f54:	00004517          	auipc	a0,0x4
    80004f58:	a3c50513          	addi	a0,a0,-1476 # 80008990 <sysparameters+0x218>
    80004f5c:	ffffb097          	auipc	ra,0xffffb
    80004f60:	5e2080e7          	jalr	1506(ra) # 8000053e <panic>
    return -1;
    80004f64:	597d                	li	s2,-1
    80004f66:	b765                	j	80004f0e <fileread+0x60>
      return -1;
    80004f68:	597d                	li	s2,-1
    80004f6a:	b755                	j	80004f0e <fileread+0x60>
    80004f6c:	597d                	li	s2,-1
    80004f6e:	b745                	j	80004f0e <fileread+0x60>

0000000080004f70 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f70:	715d                	addi	sp,sp,-80
    80004f72:	e486                	sd	ra,72(sp)
    80004f74:	e0a2                	sd	s0,64(sp)
    80004f76:	fc26                	sd	s1,56(sp)
    80004f78:	f84a                	sd	s2,48(sp)
    80004f7a:	f44e                	sd	s3,40(sp)
    80004f7c:	f052                	sd	s4,32(sp)
    80004f7e:	ec56                	sd	s5,24(sp)
    80004f80:	e85a                	sd	s6,16(sp)
    80004f82:	e45e                	sd	s7,8(sp)
    80004f84:	e062                	sd	s8,0(sp)
    80004f86:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f88:	00954783          	lbu	a5,9(a0)
    80004f8c:	10078663          	beqz	a5,80005098 <filewrite+0x128>
    80004f90:	892a                	mv	s2,a0
    80004f92:	8aae                	mv	s5,a1
    80004f94:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f96:	411c                	lw	a5,0(a0)
    80004f98:	4705                	li	a4,1
    80004f9a:	02e78263          	beq	a5,a4,80004fbe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f9e:	470d                	li	a4,3
    80004fa0:	02e78663          	beq	a5,a4,80004fcc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fa4:	4709                	li	a4,2
    80004fa6:	0ee79163          	bne	a5,a4,80005088 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004faa:	0ac05d63          	blez	a2,80005064 <filewrite+0xf4>
    int i = 0;
    80004fae:	4981                	li	s3,0
    80004fb0:	6b05                	lui	s6,0x1
    80004fb2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fb6:	6b85                	lui	s7,0x1
    80004fb8:	c00b8b9b          	addiw	s7,s7,-1024
    80004fbc:	a861                	j	80005054 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fbe:	6908                	ld	a0,16(a0)
    80004fc0:	00000097          	auipc	ra,0x0
    80004fc4:	22e080e7          	jalr	558(ra) # 800051ee <pipewrite>
    80004fc8:	8a2a                	mv	s4,a0
    80004fca:	a045                	j	8000506a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fcc:	02451783          	lh	a5,36(a0)
    80004fd0:	03079693          	slli	a3,a5,0x30
    80004fd4:	92c1                	srli	a3,a3,0x30
    80004fd6:	4725                	li	a4,9
    80004fd8:	0cd76263          	bltu	a4,a3,8000509c <filewrite+0x12c>
    80004fdc:	0792                	slli	a5,a5,0x4
    80004fde:	0023d717          	auipc	a4,0x23d
    80004fe2:	55270713          	addi	a4,a4,1362 # 80242530 <devsw>
    80004fe6:	97ba                	add	a5,a5,a4
    80004fe8:	679c                	ld	a5,8(a5)
    80004fea:	cbdd                	beqz	a5,800050a0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fec:	4505                	li	a0,1
    80004fee:	9782                	jalr	a5
    80004ff0:	8a2a                	mv	s4,a0
    80004ff2:	a8a5                	j	8000506a <filewrite+0xfa>
    80004ff4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ff8:	00000097          	auipc	ra,0x0
    80004ffc:	8b0080e7          	jalr	-1872(ra) # 800048a8 <begin_op>
      ilock(f->ip);
    80005000:	01893503          	ld	a0,24(s2)
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	ed2080e7          	jalr	-302(ra) # 80003ed6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000500c:	8762                	mv	a4,s8
    8000500e:	02092683          	lw	a3,32(s2)
    80005012:	01598633          	add	a2,s3,s5
    80005016:	4585                	li	a1,1
    80005018:	01893503          	ld	a0,24(s2)
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	266080e7          	jalr	614(ra) # 80004282 <writei>
    80005024:	84aa                	mv	s1,a0
    80005026:	00a05763          	blez	a0,80005034 <filewrite+0xc4>
        f->off += r;
    8000502a:	02092783          	lw	a5,32(s2)
    8000502e:	9fa9                	addw	a5,a5,a0
    80005030:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005034:	01893503          	ld	a0,24(s2)
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	f60080e7          	jalr	-160(ra) # 80003f98 <iunlock>
      end_op();
    80005040:	00000097          	auipc	ra,0x0
    80005044:	8e8080e7          	jalr	-1816(ra) # 80004928 <end_op>

      if(r != n1){
    80005048:	009c1f63          	bne	s8,s1,80005066 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000504c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005050:	0149db63          	bge	s3,s4,80005066 <filewrite+0xf6>
      int n1 = n - i;
    80005054:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005058:	84be                	mv	s1,a5
    8000505a:	2781                	sext.w	a5,a5
    8000505c:	f8fb5ce3          	bge	s6,a5,80004ff4 <filewrite+0x84>
    80005060:	84de                	mv	s1,s7
    80005062:	bf49                	j	80004ff4 <filewrite+0x84>
    int i = 0;
    80005064:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005066:	013a1f63          	bne	s4,s3,80005084 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000506a:	8552                	mv	a0,s4
    8000506c:	60a6                	ld	ra,72(sp)
    8000506e:	6406                	ld	s0,64(sp)
    80005070:	74e2                	ld	s1,56(sp)
    80005072:	7942                	ld	s2,48(sp)
    80005074:	79a2                	ld	s3,40(sp)
    80005076:	7a02                	ld	s4,32(sp)
    80005078:	6ae2                	ld	s5,24(sp)
    8000507a:	6b42                	ld	s6,16(sp)
    8000507c:	6ba2                	ld	s7,8(sp)
    8000507e:	6c02                	ld	s8,0(sp)
    80005080:	6161                	addi	sp,sp,80
    80005082:	8082                	ret
    ret = (i == n ? n : -1);
    80005084:	5a7d                	li	s4,-1
    80005086:	b7d5                	j	8000506a <filewrite+0xfa>
    panic("filewrite");
    80005088:	00004517          	auipc	a0,0x4
    8000508c:	91850513          	addi	a0,a0,-1768 # 800089a0 <sysparameters+0x228>
    80005090:	ffffb097          	auipc	ra,0xffffb
    80005094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
    return -1;
    80005098:	5a7d                	li	s4,-1
    8000509a:	bfc1                	j	8000506a <filewrite+0xfa>
      return -1;
    8000509c:	5a7d                	li	s4,-1
    8000509e:	b7f1                	j	8000506a <filewrite+0xfa>
    800050a0:	5a7d                	li	s4,-1
    800050a2:	b7e1                	j	8000506a <filewrite+0xfa>

00000000800050a4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050a4:	7179                	addi	sp,sp,-48
    800050a6:	f406                	sd	ra,40(sp)
    800050a8:	f022                	sd	s0,32(sp)
    800050aa:	ec26                	sd	s1,24(sp)
    800050ac:	e84a                	sd	s2,16(sp)
    800050ae:	e44e                	sd	s3,8(sp)
    800050b0:	e052                	sd	s4,0(sp)
    800050b2:	1800                	addi	s0,sp,48
    800050b4:	84aa                	mv	s1,a0
    800050b6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050b8:	0005b023          	sd	zero,0(a1)
    800050bc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050c0:	00000097          	auipc	ra,0x0
    800050c4:	bf8080e7          	jalr	-1032(ra) # 80004cb8 <filealloc>
    800050c8:	e088                	sd	a0,0(s1)
    800050ca:	c551                	beqz	a0,80005156 <pipealloc+0xb2>
    800050cc:	00000097          	auipc	ra,0x0
    800050d0:	bec080e7          	jalr	-1044(ra) # 80004cb8 <filealloc>
    800050d4:	00aa3023          	sd	a0,0(s4)
    800050d8:	c92d                	beqz	a0,8000514a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050da:	ffffc097          	auipc	ra,0xffffc
    800050de:	b9e080e7          	jalr	-1122(ra) # 80000c78 <kalloc>
    800050e2:	892a                	mv	s2,a0
    800050e4:	c125                	beqz	a0,80005144 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050e6:	4985                	li	s3,1
    800050e8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050ec:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050f0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050f4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050f8:	00003597          	auipc	a1,0x3
    800050fc:	3f058593          	addi	a1,a1,1008 # 800084e8 <states.1753+0x1b8>
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	c2e080e7          	jalr	-978(ra) # 80000d2e <initlock>
  (*f0)->type = FD_PIPE;
    80005108:	609c                	ld	a5,0(s1)
    8000510a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000510e:	609c                	ld	a5,0(s1)
    80005110:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005114:	609c                	ld	a5,0(s1)
    80005116:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000511a:	609c                	ld	a5,0(s1)
    8000511c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005120:	000a3783          	ld	a5,0(s4)
    80005124:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005128:	000a3783          	ld	a5,0(s4)
    8000512c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005130:	000a3783          	ld	a5,0(s4)
    80005134:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005138:	000a3783          	ld	a5,0(s4)
    8000513c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005140:	4501                	li	a0,0
    80005142:	a025                	j	8000516a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005144:	6088                	ld	a0,0(s1)
    80005146:	e501                	bnez	a0,8000514e <pipealloc+0xaa>
    80005148:	a039                	j	80005156 <pipealloc+0xb2>
    8000514a:	6088                	ld	a0,0(s1)
    8000514c:	c51d                	beqz	a0,8000517a <pipealloc+0xd6>
    fileclose(*f0);
    8000514e:	00000097          	auipc	ra,0x0
    80005152:	c26080e7          	jalr	-986(ra) # 80004d74 <fileclose>
  if(*f1)
    80005156:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000515a:	557d                	li	a0,-1
  if(*f1)
    8000515c:	c799                	beqz	a5,8000516a <pipealloc+0xc6>
    fileclose(*f1);
    8000515e:	853e                	mv	a0,a5
    80005160:	00000097          	auipc	ra,0x0
    80005164:	c14080e7          	jalr	-1004(ra) # 80004d74 <fileclose>
  return -1;
    80005168:	557d                	li	a0,-1
}
    8000516a:	70a2                	ld	ra,40(sp)
    8000516c:	7402                	ld	s0,32(sp)
    8000516e:	64e2                	ld	s1,24(sp)
    80005170:	6942                	ld	s2,16(sp)
    80005172:	69a2                	ld	s3,8(sp)
    80005174:	6a02                	ld	s4,0(sp)
    80005176:	6145                	addi	sp,sp,48
    80005178:	8082                	ret
  return -1;
    8000517a:	557d                	li	a0,-1
    8000517c:	b7fd                	j	8000516a <pipealloc+0xc6>

000000008000517e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000517e:	1101                	addi	sp,sp,-32
    80005180:	ec06                	sd	ra,24(sp)
    80005182:	e822                	sd	s0,16(sp)
    80005184:	e426                	sd	s1,8(sp)
    80005186:	e04a                	sd	s2,0(sp)
    80005188:	1000                	addi	s0,sp,32
    8000518a:	84aa                	mv	s1,a0
    8000518c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	c30080e7          	jalr	-976(ra) # 80000dbe <acquire>
  if(writable){
    80005196:	02090d63          	beqz	s2,800051d0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000519a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000519e:	21848513          	addi	a0,s1,536
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	4d4080e7          	jalr	1236(ra) # 80002676 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051aa:	2204b783          	ld	a5,544(s1)
    800051ae:	eb95                	bnez	a5,800051e2 <pipeclose+0x64>
    release(&pi->lock);
    800051b0:	8526                	mv	a0,s1
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	cc0080e7          	jalr	-832(ra) # 80000e72 <release>
    kfree((char*)pi);
    800051ba:	8526                	mv	a0,s1
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	8a8080e7          	jalr	-1880(ra) # 80000a64 <kfree>
  } else
    release(&pi->lock);
}
    800051c4:	60e2                	ld	ra,24(sp)
    800051c6:	6442                	ld	s0,16(sp)
    800051c8:	64a2                	ld	s1,8(sp)
    800051ca:	6902                	ld	s2,0(sp)
    800051cc:	6105                	addi	sp,sp,32
    800051ce:	8082                	ret
    pi->readopen = 0;
    800051d0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051d4:	21c48513          	addi	a0,s1,540
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	49e080e7          	jalr	1182(ra) # 80002676 <wakeup>
    800051e0:	b7e9                	j	800051aa <pipeclose+0x2c>
    release(&pi->lock);
    800051e2:	8526                	mv	a0,s1
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	c8e080e7          	jalr	-882(ra) # 80000e72 <release>
}
    800051ec:	bfe1                	j	800051c4 <pipeclose+0x46>

00000000800051ee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051ee:	7159                	addi	sp,sp,-112
    800051f0:	f486                	sd	ra,104(sp)
    800051f2:	f0a2                	sd	s0,96(sp)
    800051f4:	eca6                	sd	s1,88(sp)
    800051f6:	e8ca                	sd	s2,80(sp)
    800051f8:	e4ce                	sd	s3,72(sp)
    800051fa:	e0d2                	sd	s4,64(sp)
    800051fc:	fc56                	sd	s5,56(sp)
    800051fe:	f85a                	sd	s6,48(sp)
    80005200:	f45e                	sd	s7,40(sp)
    80005202:	f062                	sd	s8,32(sp)
    80005204:	ec66                	sd	s9,24(sp)
    80005206:	1880                	addi	s0,sp,112
    80005208:	84aa                	mv	s1,a0
    8000520a:	8aae                	mv	s5,a1
    8000520c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000520e:	ffffd097          	auipc	ra,0xffffd
    80005212:	9c0080e7          	jalr	-1600(ra) # 80001bce <myproc>
    80005216:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	ba4080e7          	jalr	-1116(ra) # 80000dbe <acquire>
  while(i < n){
    80005222:	0d405163          	blez	s4,800052e4 <pipewrite+0xf6>
    80005226:	8ba6                	mv	s7,s1
  int i = 0;
    80005228:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000522a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000522c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005230:	21c48c13          	addi	s8,s1,540
    80005234:	a08d                	j	80005296 <pipewrite+0xa8>
      release(&pi->lock);
    80005236:	8526                	mv	a0,s1
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	c3a080e7          	jalr	-966(ra) # 80000e72 <release>
      return -1;
    80005240:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005242:	854a                	mv	a0,s2
    80005244:	70a6                	ld	ra,104(sp)
    80005246:	7406                	ld	s0,96(sp)
    80005248:	64e6                	ld	s1,88(sp)
    8000524a:	6946                	ld	s2,80(sp)
    8000524c:	69a6                	ld	s3,72(sp)
    8000524e:	6a06                	ld	s4,64(sp)
    80005250:	7ae2                	ld	s5,56(sp)
    80005252:	7b42                	ld	s6,48(sp)
    80005254:	7ba2                	ld	s7,40(sp)
    80005256:	7c02                	ld	s8,32(sp)
    80005258:	6ce2                	ld	s9,24(sp)
    8000525a:	6165                	addi	sp,sp,112
    8000525c:	8082                	ret
      wakeup(&pi->nread);
    8000525e:	8566                	mv	a0,s9
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	416080e7          	jalr	1046(ra) # 80002676 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005268:	85de                	mv	a1,s7
    8000526a:	8562                	mv	a0,s8
    8000526c:	ffffd097          	auipc	ra,0xffffd
    80005270:	132080e7          	jalr	306(ra) # 8000239e <sleep>
    80005274:	a839                	j	80005292 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005276:	21c4a783          	lw	a5,540(s1)
    8000527a:	0017871b          	addiw	a4,a5,1
    8000527e:	20e4ae23          	sw	a4,540(s1)
    80005282:	1ff7f793          	andi	a5,a5,511
    80005286:	97a6                	add	a5,a5,s1
    80005288:	f9f44703          	lbu	a4,-97(s0)
    8000528c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005290:	2905                	addiw	s2,s2,1
  while(i < n){
    80005292:	03495d63          	bge	s2,s4,800052cc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005296:	2204a783          	lw	a5,544(s1)
    8000529a:	dfd1                	beqz	a5,80005236 <pipewrite+0x48>
    8000529c:	0289a783          	lw	a5,40(s3)
    800052a0:	fbd9                	bnez	a5,80005236 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052a2:	2184a783          	lw	a5,536(s1)
    800052a6:	21c4a703          	lw	a4,540(s1)
    800052aa:	2007879b          	addiw	a5,a5,512
    800052ae:	faf708e3          	beq	a4,a5,8000525e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052b2:	4685                	li	a3,1
    800052b4:	01590633          	add	a2,s2,s5
    800052b8:	f9f40593          	addi	a1,s0,-97
    800052bc:	0509b503          	ld	a0,80(s3)
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	658080e7          	jalr	1624(ra) # 80001918 <copyin>
    800052c8:	fb6517e3          	bne	a0,s6,80005276 <pipewrite+0x88>
  wakeup(&pi->nread);
    800052cc:	21848513          	addi	a0,s1,536
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	3a6080e7          	jalr	934(ra) # 80002676 <wakeup>
  release(&pi->lock);
    800052d8:	8526                	mv	a0,s1
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	b98080e7          	jalr	-1128(ra) # 80000e72 <release>
  return i;
    800052e2:	b785                	j	80005242 <pipewrite+0x54>
  int i = 0;
    800052e4:	4901                	li	s2,0
    800052e6:	b7dd                	j	800052cc <pipewrite+0xde>

00000000800052e8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052e8:	715d                	addi	sp,sp,-80
    800052ea:	e486                	sd	ra,72(sp)
    800052ec:	e0a2                	sd	s0,64(sp)
    800052ee:	fc26                	sd	s1,56(sp)
    800052f0:	f84a                	sd	s2,48(sp)
    800052f2:	f44e                	sd	s3,40(sp)
    800052f4:	f052                	sd	s4,32(sp)
    800052f6:	ec56                	sd	s5,24(sp)
    800052f8:	e85a                	sd	s6,16(sp)
    800052fa:	0880                	addi	s0,sp,80
    800052fc:	84aa                	mv	s1,a0
    800052fe:	892e                	mv	s2,a1
    80005300:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005302:	ffffd097          	auipc	ra,0xffffd
    80005306:	8cc080e7          	jalr	-1844(ra) # 80001bce <myproc>
    8000530a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000530c:	8b26                	mv	s6,s1
    8000530e:	8526                	mv	a0,s1
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	aae080e7          	jalr	-1362(ra) # 80000dbe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005318:	2184a703          	lw	a4,536(s1)
    8000531c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005320:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005324:	02f71463          	bne	a4,a5,8000534c <piperead+0x64>
    80005328:	2244a783          	lw	a5,548(s1)
    8000532c:	c385                	beqz	a5,8000534c <piperead+0x64>
    if(pr->killed){
    8000532e:	028a2783          	lw	a5,40(s4)
    80005332:	ebc1                	bnez	a5,800053c2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005334:	85da                	mv	a1,s6
    80005336:	854e                	mv	a0,s3
    80005338:	ffffd097          	auipc	ra,0xffffd
    8000533c:	066080e7          	jalr	102(ra) # 8000239e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005340:	2184a703          	lw	a4,536(s1)
    80005344:	21c4a783          	lw	a5,540(s1)
    80005348:	fef700e3          	beq	a4,a5,80005328 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000534c:	09505263          	blez	s5,800053d0 <piperead+0xe8>
    80005350:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005352:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005354:	2184a783          	lw	a5,536(s1)
    80005358:	21c4a703          	lw	a4,540(s1)
    8000535c:	02f70d63          	beq	a4,a5,80005396 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005360:	0017871b          	addiw	a4,a5,1
    80005364:	20e4ac23          	sw	a4,536(s1)
    80005368:	1ff7f793          	andi	a5,a5,511
    8000536c:	97a6                	add	a5,a5,s1
    8000536e:	0187c783          	lbu	a5,24(a5)
    80005372:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005376:	4685                	li	a3,1
    80005378:	fbf40613          	addi	a2,s0,-65
    8000537c:	85ca                	mv	a1,s2
    8000537e:	050a3503          	ld	a0,80(s4)
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	4d2080e7          	jalr	1234(ra) # 80001854 <copyout>
    8000538a:	01650663          	beq	a0,s6,80005396 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000538e:	2985                	addiw	s3,s3,1
    80005390:	0905                	addi	s2,s2,1
    80005392:	fd3a91e3          	bne	s5,s3,80005354 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005396:	21c48513          	addi	a0,s1,540
    8000539a:	ffffd097          	auipc	ra,0xffffd
    8000539e:	2dc080e7          	jalr	732(ra) # 80002676 <wakeup>
  release(&pi->lock);
    800053a2:	8526                	mv	a0,s1
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	ace080e7          	jalr	-1330(ra) # 80000e72 <release>
  return i;
}
    800053ac:	854e                	mv	a0,s3
    800053ae:	60a6                	ld	ra,72(sp)
    800053b0:	6406                	ld	s0,64(sp)
    800053b2:	74e2                	ld	s1,56(sp)
    800053b4:	7942                	ld	s2,48(sp)
    800053b6:	79a2                	ld	s3,40(sp)
    800053b8:	7a02                	ld	s4,32(sp)
    800053ba:	6ae2                	ld	s5,24(sp)
    800053bc:	6b42                	ld	s6,16(sp)
    800053be:	6161                	addi	sp,sp,80
    800053c0:	8082                	ret
      release(&pi->lock);
    800053c2:	8526                	mv	a0,s1
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	aae080e7          	jalr	-1362(ra) # 80000e72 <release>
      return -1;
    800053cc:	59fd                	li	s3,-1
    800053ce:	bff9                	j	800053ac <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053d0:	4981                	li	s3,0
    800053d2:	b7d1                	j	80005396 <piperead+0xae>

00000000800053d4 <exec>:
#include "elf.h"

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int exec(char *path, char **argv)
{
    800053d4:	df010113          	addi	sp,sp,-528
    800053d8:	20113423          	sd	ra,520(sp)
    800053dc:	20813023          	sd	s0,512(sp)
    800053e0:	ffa6                	sd	s1,504(sp)
    800053e2:	fbca                	sd	s2,496(sp)
    800053e4:	f7ce                	sd	s3,488(sp)
    800053e6:	f3d2                	sd	s4,480(sp)
    800053e8:	efd6                	sd	s5,472(sp)
    800053ea:	ebda                	sd	s6,464(sp)
    800053ec:	e7de                	sd	s7,456(sp)
    800053ee:	e3e2                	sd	s8,448(sp)
    800053f0:	ff66                	sd	s9,440(sp)
    800053f2:	fb6a                	sd	s10,432(sp)
    800053f4:	f76e                	sd	s11,424(sp)
    800053f6:	0c00                	addi	s0,sp,528
    800053f8:	84aa                	mv	s1,a0
    800053fa:	dea43c23          	sd	a0,-520(s0)
    800053fe:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	7cc080e7          	jalr	1996(ra) # 80001bce <myproc>
    8000540a:	892a                	mv	s2,a0

  begin_op();
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	49c080e7          	jalr	1180(ra) # 800048a8 <begin_op>

  if ((ip = namei(path)) == 0)
    80005414:	8526                	mv	a0,s1
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	276080e7          	jalr	630(ra) # 8000468c <namei>
    8000541e:	c92d                	beqz	a0,80005490 <exec+0xbc>
    80005420:	84aa                	mv	s1,a0
  {
    end_op();
    return -1;
  }
  ilock(ip);
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	ab4080e7          	jalr	-1356(ra) # 80003ed6 <ilock>

  // Check ELF header
  if (readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000542a:	04000713          	li	a4,64
    8000542e:	4681                	li	a3,0
    80005430:	e5040613          	addi	a2,s0,-432
    80005434:	4581                	li	a1,0
    80005436:	8526                	mv	a0,s1
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	d52080e7          	jalr	-686(ra) # 8000418a <readi>
    80005440:	04000793          	li	a5,64
    80005444:	00f51a63          	bne	a0,a5,80005458 <exec+0x84>
    goto bad;
  if (elf.magic != ELF_MAGIC)
    80005448:	e5042703          	lw	a4,-432(s0)
    8000544c:	464c47b7          	lui	a5,0x464c4
    80005450:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005454:	04f70463          	beq	a4,a5,8000549c <exec+0xc8>
bad:
  if (pagetable)
    proc_freepagetable(pagetable, sz);
  if (ip)
  {
    iunlockput(ip);
    80005458:	8526                	mv	a0,s1
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	cde080e7          	jalr	-802(ra) # 80004138 <iunlockput>
    end_op();
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	4c6080e7          	jalr	1222(ra) # 80004928 <end_op>
  }
  return -1;
    8000546a:	557d                	li	a0,-1
}
    8000546c:	20813083          	ld	ra,520(sp)
    80005470:	20013403          	ld	s0,512(sp)
    80005474:	74fe                	ld	s1,504(sp)
    80005476:	795e                	ld	s2,496(sp)
    80005478:	79be                	ld	s3,488(sp)
    8000547a:	7a1e                	ld	s4,480(sp)
    8000547c:	6afe                	ld	s5,472(sp)
    8000547e:	6b5e                	ld	s6,464(sp)
    80005480:	6bbe                	ld	s7,456(sp)
    80005482:	6c1e                	ld	s8,448(sp)
    80005484:	7cfa                	ld	s9,440(sp)
    80005486:	7d5a                	ld	s10,432(sp)
    80005488:	7dba                	ld	s11,424(sp)
    8000548a:	21010113          	addi	sp,sp,528
    8000548e:	8082                	ret
    end_op();
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	498080e7          	jalr	1176(ra) # 80004928 <end_op>
    return -1;
    80005498:	557d                	li	a0,-1
    8000549a:	bfc9                	j	8000546c <exec+0x98>
  if ((pagetable = proc_pagetable(p)) == 0)
    8000549c:	854a                	mv	a0,s2
    8000549e:	ffffc097          	auipc	ra,0xffffc
    800054a2:	7f4080e7          	jalr	2036(ra) # 80001c92 <proc_pagetable>
    800054a6:	8baa                	mv	s7,a0
    800054a8:	d945                	beqz	a0,80005458 <exec+0x84>
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    800054aa:	e7042983          	lw	s3,-400(s0)
    800054ae:	e8845783          	lhu	a5,-376(s0)
    800054b2:	c7ad                	beqz	a5,8000551c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054b4:	4901                	li	s2,0
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    800054b6:	4b01                	li	s6,0
    if ((ph.vaddr % PGSIZE) != 0)
    800054b8:	6c85                	lui	s9,0x1
    800054ba:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800054be:	def43823          	sd	a5,-528(s0)
    800054c2:	a42d                	j	800056ec <exec+0x318>

  for (i = 0; i < sz; i += PGSIZE)
  {
    pa = walkaddr(pagetable, va + i);
    if (pa == 0)
      panic("loadseg: address should exist");
    800054c4:	00003517          	auipc	a0,0x3
    800054c8:	4ec50513          	addi	a0,a0,1260 # 800089b0 <sysparameters+0x238>
    800054cc:	ffffb097          	auipc	ra,0xffffb
    800054d0:	072080e7          	jalr	114(ra) # 8000053e <panic>
    if (sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if (readi(ip, 0, (uint64)pa, offset + i, n) != n)
    800054d4:	8756                	mv	a4,s5
    800054d6:	012d86bb          	addw	a3,s11,s2
    800054da:	4581                	li	a1,0
    800054dc:	8526                	mv	a0,s1
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	cac080e7          	jalr	-852(ra) # 8000418a <readi>
    800054e6:	2501                	sext.w	a0,a0
    800054e8:	1aaa9963          	bne	s5,a0,8000569a <exec+0x2c6>
  for (i = 0; i < sz; i += PGSIZE)
    800054ec:	6785                	lui	a5,0x1
    800054ee:	0127893b          	addw	s2,a5,s2
    800054f2:	77fd                	lui	a5,0xfffff
    800054f4:	01478a3b          	addw	s4,a5,s4
    800054f8:	1f897163          	bgeu	s2,s8,800056da <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800054fc:	02091593          	slli	a1,s2,0x20
    80005500:	9181                	srli	a1,a1,0x20
    80005502:	95ea                	add	a1,a1,s10
    80005504:	855e                	mv	a0,s7
    80005506:	ffffc097          	auipc	ra,0xffffc
    8000550a:	d42080e7          	jalr	-702(ra) # 80001248 <walkaddr>
    8000550e:	862a                	mv	a2,a0
    if (pa == 0)
    80005510:	d955                	beqz	a0,800054c4 <exec+0xf0>
      n = PGSIZE;
    80005512:	8ae6                	mv	s5,s9
    if (sz - i < PGSIZE)
    80005514:	fd9a70e3          	bgeu	s4,s9,800054d4 <exec+0x100>
      n = sz - i;
    80005518:	8ad2                	mv	s5,s4
    8000551a:	bf6d                	j	800054d4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000551c:	4901                	li	s2,0
  iunlockput(ip);
    8000551e:	8526                	mv	a0,s1
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	c18080e7          	jalr	-1000(ra) # 80004138 <iunlockput>
  end_op();
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	400080e7          	jalr	1024(ra) # 80004928 <end_op>
  p = myproc();
    80005530:	ffffc097          	auipc	ra,0xffffc
    80005534:	69e080e7          	jalr	1694(ra) # 80001bce <myproc>
    80005538:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000553a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000553e:	6785                	lui	a5,0x1
    80005540:	17fd                	addi	a5,a5,-1
    80005542:	993e                	add	s2,s2,a5
    80005544:	757d                	lui	a0,0xfffff
    80005546:	00a977b3          	and	a5,s2,a0
    8000554a:	e0f43423          	sd	a5,-504(s0)
  if ((sz1 = uvmalloc(pagetable, sz, sz + 2 * PGSIZE)) == 0)
    8000554e:	6609                	lui	a2,0x2
    80005550:	963e                	add	a2,a2,a5
    80005552:	85be                	mv	a1,a5
    80005554:	855e                	mv	a0,s7
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	0a6080e7          	jalr	166(ra) # 800015fc <uvmalloc>
    8000555e:	8b2a                	mv	s6,a0
  ip = 0;
    80005560:	4481                	li	s1,0
  if ((sz1 = uvmalloc(pagetable, sz, sz + 2 * PGSIZE)) == 0)
    80005562:	12050c63          	beqz	a0,8000569a <exec+0x2c6>
  uvmclear(pagetable, sz - 2 * PGSIZE);
    80005566:	75f9                	lui	a1,0xffffe
    80005568:	95aa                	add	a1,a1,a0
    8000556a:	855e                	mv	a0,s7
    8000556c:	ffffc097          	auipc	ra,0xffffc
    80005570:	2b6080e7          	jalr	694(ra) # 80001822 <uvmclear>
  stackbase = sp - PGSIZE;
    80005574:	7c7d                	lui	s8,0xfffff
    80005576:	9c5a                	add	s8,s8,s6
  for (argc = 0; argv[argc]; argc++)
    80005578:	e0043783          	ld	a5,-512(s0)
    8000557c:	6388                	ld	a0,0(a5)
    8000557e:	c535                	beqz	a0,800055ea <exec+0x216>
    80005580:	e9040993          	addi	s3,s0,-368
    80005584:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005588:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000558a:	ffffc097          	auipc	ra,0xffffc
    8000558e:	ab4080e7          	jalr	-1356(ra) # 8000103e <strlen>
    80005592:	2505                	addiw	a0,a0,1
    80005594:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005598:	ff097913          	andi	s2,s2,-16
    if (sp < stackbase)
    8000559c:	13896363          	bltu	s2,s8,800056c2 <exec+0x2ee>
    if (copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055a0:	e0043d83          	ld	s11,-512(s0)
    800055a4:	000dba03          	ld	s4,0(s11)
    800055a8:	8552                	mv	a0,s4
    800055aa:	ffffc097          	auipc	ra,0xffffc
    800055ae:	a94080e7          	jalr	-1388(ra) # 8000103e <strlen>
    800055b2:	0015069b          	addiw	a3,a0,1
    800055b6:	8652                	mv	a2,s4
    800055b8:	85ca                	mv	a1,s2
    800055ba:	855e                	mv	a0,s7
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	298080e7          	jalr	664(ra) # 80001854 <copyout>
    800055c4:	10054363          	bltz	a0,800056ca <exec+0x2f6>
    ustack[argc] = sp;
    800055c8:	0129b023          	sd	s2,0(s3)
  for (argc = 0; argv[argc]; argc++)
    800055cc:	0485                	addi	s1,s1,1
    800055ce:	008d8793          	addi	a5,s11,8
    800055d2:	e0f43023          	sd	a5,-512(s0)
    800055d6:	008db503          	ld	a0,8(s11)
    800055da:	c911                	beqz	a0,800055ee <exec+0x21a>
    if (argc >= MAXARG)
    800055dc:	09a1                	addi	s3,s3,8
    800055de:	fb3c96e3          	bne	s9,s3,8000558a <exec+0x1b6>
  sz = sz1;
    800055e2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e6:	4481                	li	s1,0
    800055e8:	a84d                	j	8000569a <exec+0x2c6>
  sp = sz;
    800055ea:	895a                	mv	s2,s6
  for (argc = 0; argv[argc]; argc++)
    800055ec:	4481                	li	s1,0
  ustack[argc] = 0;
    800055ee:	00349793          	slli	a5,s1,0x3
    800055f2:	f9040713          	addi	a4,s0,-112
    800055f6:	97ba                	add	a5,a5,a4
    800055f8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc + 1) * sizeof(uint64);
    800055fc:	00148693          	addi	a3,s1,1
    80005600:	068e                	slli	a3,a3,0x3
    80005602:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005606:	ff097913          	andi	s2,s2,-16
  if (sp < stackbase)
    8000560a:	01897663          	bgeu	s2,s8,80005616 <exec+0x242>
  sz = sz1;
    8000560e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005612:	4481                	li	s1,0
    80005614:	a059                	j	8000569a <exec+0x2c6>
  if (copyout(pagetable, sp, (char *)ustack, (argc + 1) * sizeof(uint64)) < 0)
    80005616:	e9040613          	addi	a2,s0,-368
    8000561a:	85ca                	mv	a1,s2
    8000561c:	855e                	mv	a0,s7
    8000561e:	ffffc097          	auipc	ra,0xffffc
    80005622:	236080e7          	jalr	566(ra) # 80001854 <copyout>
    80005626:	0a054663          	bltz	a0,800056d2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000562a:	058ab783          	ld	a5,88(s5)
    8000562e:	0727bc23          	sd	s2,120(a5)
  for (last = s = path; *s; s++)
    80005632:	df843783          	ld	a5,-520(s0)
    80005636:	0007c703          	lbu	a4,0(a5)
    8000563a:	cf11                	beqz	a4,80005656 <exec+0x282>
    8000563c:	0785                	addi	a5,a5,1
    if (*s == '/')
    8000563e:	02f00693          	li	a3,47
    80005642:	a039                	j	80005650 <exec+0x27c>
      last = s + 1;
    80005644:	def43c23          	sd	a5,-520(s0)
  for (last = s = path; *s; s++)
    80005648:	0785                	addi	a5,a5,1
    8000564a:	fff7c703          	lbu	a4,-1(a5)
    8000564e:	c701                	beqz	a4,80005656 <exec+0x282>
    if (*s == '/')
    80005650:	fed71ce3          	bne	a4,a3,80005648 <exec+0x274>
    80005654:	bfc5                	j	80005644 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005656:	4641                	li	a2,16
    80005658:	df843583          	ld	a1,-520(s0)
    8000565c:	158a8513          	addi	a0,s5,344
    80005660:	ffffc097          	auipc	ra,0xffffc
    80005664:	9ac080e7          	jalr	-1620(ra) # 8000100c <safestrcpy>
  oldpagetable = p->pagetable;
    80005668:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000566c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005670:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry; // initial program counter = main
    80005674:	058ab783          	ld	a5,88(s5)
    80005678:	e6843703          	ld	a4,-408(s0)
    8000567c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp;         // initial stack pointer
    8000567e:	058ab783          	ld	a5,88(s5)
    80005682:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005686:	85ea                	mv	a1,s10
    80005688:	ffffc097          	auipc	ra,0xffffc
    8000568c:	6a6080e7          	jalr	1702(ra) # 80001d2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005690:	0004851b          	sext.w	a0,s1
    80005694:	bbe1                	j	8000546c <exec+0x98>
    80005696:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000569a:	e0843583          	ld	a1,-504(s0)
    8000569e:	855e                	mv	a0,s7
    800056a0:	ffffc097          	auipc	ra,0xffffc
    800056a4:	68e080e7          	jalr	1678(ra) # 80001d2e <proc_freepagetable>
  if (ip)
    800056a8:	da0498e3          	bnez	s1,80005458 <exec+0x84>
  return -1;
    800056ac:	557d                	li	a0,-1
    800056ae:	bb7d                	j	8000546c <exec+0x98>
    800056b0:	e1243423          	sd	s2,-504(s0)
    800056b4:	b7dd                	j	8000569a <exec+0x2c6>
    800056b6:	e1243423          	sd	s2,-504(s0)
    800056ba:	b7c5                	j	8000569a <exec+0x2c6>
    800056bc:	e1243423          	sd	s2,-504(s0)
    800056c0:	bfe9                	j	8000569a <exec+0x2c6>
  sz = sz1;
    800056c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056c6:	4481                	li	s1,0
    800056c8:	bfc9                	j	8000569a <exec+0x2c6>
  sz = sz1;
    800056ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056ce:	4481                	li	s1,0
    800056d0:	b7e9                	j	8000569a <exec+0x2c6>
  sz = sz1;
    800056d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056d6:	4481                	li	s1,0
    800056d8:	b7c9                	j	8000569a <exec+0x2c6>
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056da:	e0843903          	ld	s2,-504(s0)
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    800056de:	2b05                	addiw	s6,s6,1
    800056e0:	0389899b          	addiw	s3,s3,56
    800056e4:	e8845783          	lhu	a5,-376(s0)
    800056e8:	e2fb5be3          	bge	s6,a5,8000551e <exec+0x14a>
    if (readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056ec:	2981                	sext.w	s3,s3
    800056ee:	03800713          	li	a4,56
    800056f2:	86ce                	mv	a3,s3
    800056f4:	e1840613          	addi	a2,s0,-488
    800056f8:	4581                	li	a1,0
    800056fa:	8526                	mv	a0,s1
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	a8e080e7          	jalr	-1394(ra) # 8000418a <readi>
    80005704:	03800793          	li	a5,56
    80005708:	f8f517e3          	bne	a0,a5,80005696 <exec+0x2c2>
    if (ph.type != ELF_PROG_LOAD)
    8000570c:	e1842783          	lw	a5,-488(s0)
    80005710:	4705                	li	a4,1
    80005712:	fce796e3          	bne	a5,a4,800056de <exec+0x30a>
    if (ph.memsz < ph.filesz)
    80005716:	e4043603          	ld	a2,-448(s0)
    8000571a:	e3843783          	ld	a5,-456(s0)
    8000571e:	f8f669e3          	bltu	a2,a5,800056b0 <exec+0x2dc>
    if (ph.vaddr + ph.memsz < ph.vaddr)
    80005722:	e2843783          	ld	a5,-472(s0)
    80005726:	963e                	add	a2,a2,a5
    80005728:	f8f667e3          	bltu	a2,a5,800056b6 <exec+0x2e2>
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000572c:	85ca                	mv	a1,s2
    8000572e:	855e                	mv	a0,s7
    80005730:	ffffc097          	auipc	ra,0xffffc
    80005734:	ecc080e7          	jalr	-308(ra) # 800015fc <uvmalloc>
    80005738:	e0a43423          	sd	a0,-504(s0)
    8000573c:	d141                	beqz	a0,800056bc <exec+0x2e8>
    if ((ph.vaddr % PGSIZE) != 0)
    8000573e:	e2843d03          	ld	s10,-472(s0)
    80005742:	df043783          	ld	a5,-528(s0)
    80005746:	00fd77b3          	and	a5,s10,a5
    8000574a:	fba1                	bnez	a5,8000569a <exec+0x2c6>
    if (loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000574c:	e2042d83          	lw	s11,-480(s0)
    80005750:	e3842c03          	lw	s8,-456(s0)
  for (i = 0; i < sz; i += PGSIZE)
    80005754:	f80c03e3          	beqz	s8,800056da <exec+0x306>
    80005758:	8a62                	mv	s4,s8
    8000575a:	4901                	li	s2,0
    8000575c:	b345                	j	800054fc <exec+0x128>

000000008000575e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000575e:	7179                	addi	sp,sp,-48
    80005760:	f406                	sd	ra,40(sp)
    80005762:	f022                	sd	s0,32(sp)
    80005764:	ec26                	sd	s1,24(sp)
    80005766:	e84a                	sd	s2,16(sp)
    80005768:	1800                	addi	s0,sp,48
    8000576a:	892e                	mv	s2,a1
    8000576c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if (argint(n, &fd) < 0)
    8000576e:	fdc40593          	addi	a1,s0,-36
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	952080e7          	jalr	-1710(ra) # 800030c4 <argint>
    8000577a:	04054063          	bltz	a0,800057ba <argfd+0x5c>
    return -1;
  if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    8000577e:	fdc42703          	lw	a4,-36(s0)
    80005782:	47bd                	li	a5,15
    80005784:	02e7ed63          	bltu	a5,a4,800057be <argfd+0x60>
    80005788:	ffffc097          	auipc	ra,0xffffc
    8000578c:	446080e7          	jalr	1094(ra) # 80001bce <myproc>
    80005790:	fdc42703          	lw	a4,-36(s0)
    80005794:	01a70793          	addi	a5,a4,26
    80005798:	078e                	slli	a5,a5,0x3
    8000579a:	953e                	add	a0,a0,a5
    8000579c:	611c                	ld	a5,0(a0)
    8000579e:	c395                	beqz	a5,800057c2 <argfd+0x64>
    return -1;
  if (pfd)
    800057a0:	00090463          	beqz	s2,800057a8 <argfd+0x4a>
    *pfd = fd;
    800057a4:	00e92023          	sw	a4,0(s2)
  if (pf)
    *pf = f;
  return 0;
    800057a8:	4501                	li	a0,0
  if (pf)
    800057aa:	c091                	beqz	s1,800057ae <argfd+0x50>
    *pf = f;
    800057ac:	e09c                	sd	a5,0(s1)
}
    800057ae:	70a2                	ld	ra,40(sp)
    800057b0:	7402                	ld	s0,32(sp)
    800057b2:	64e2                	ld	s1,24(sp)
    800057b4:	6942                	ld	s2,16(sp)
    800057b6:	6145                	addi	sp,sp,48
    800057b8:	8082                	ret
    return -1;
    800057ba:	557d                	li	a0,-1
    800057bc:	bfcd                	j	800057ae <argfd+0x50>
    return -1;
    800057be:	557d                	li	a0,-1
    800057c0:	b7fd                	j	800057ae <argfd+0x50>
    800057c2:	557d                	li	a0,-1
    800057c4:	b7ed                	j	800057ae <argfd+0x50>

00000000800057c6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057c6:	1101                	addi	sp,sp,-32
    800057c8:	ec06                	sd	ra,24(sp)
    800057ca:	e822                	sd	s0,16(sp)
    800057cc:	e426                	sd	s1,8(sp)
    800057ce:	1000                	addi	s0,sp,32
    800057d0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057d2:	ffffc097          	auipc	ra,0xffffc
    800057d6:	3fc080e7          	jalr	1020(ra) # 80001bce <myproc>
    800057da:	862a                	mv	a2,a0

  for (fd = 0; fd < NOFILE; fd++)
    800057dc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7fdb80d0>
    800057e0:	4501                	li	a0,0
    800057e2:	46c1                	li	a3,16
  {
    if (p->ofile[fd] == 0)
    800057e4:	6398                	ld	a4,0(a5)
    800057e6:	cb19                	beqz	a4,800057fc <fdalloc+0x36>
  for (fd = 0; fd < NOFILE; fd++)
    800057e8:	2505                	addiw	a0,a0,1
    800057ea:	07a1                	addi	a5,a5,8
    800057ec:	fed51ce3          	bne	a0,a3,800057e4 <fdalloc+0x1e>
    {
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057f0:	557d                	li	a0,-1
}
    800057f2:	60e2                	ld	ra,24(sp)
    800057f4:	6442                	ld	s0,16(sp)
    800057f6:	64a2                	ld	s1,8(sp)
    800057f8:	6105                	addi	sp,sp,32
    800057fa:	8082                	ret
      p->ofile[fd] = f;
    800057fc:	01a50793          	addi	a5,a0,26
    80005800:	078e                	slli	a5,a5,0x3
    80005802:	963e                	add	a2,a2,a5
    80005804:	e204                	sd	s1,0(a2)
      return fd;
    80005806:	b7f5                	j	800057f2 <fdalloc+0x2c>

0000000080005808 <create>:

// const cinfo info_unlink = {.name = "unlink", .argc = 1};

static struct inode *
create(char *path, short type, short major, short minor)
{
    80005808:	715d                	addi	sp,sp,-80
    8000580a:	e486                	sd	ra,72(sp)
    8000580c:	e0a2                	sd	s0,64(sp)
    8000580e:	fc26                	sd	s1,56(sp)
    80005810:	f84a                	sd	s2,48(sp)
    80005812:	f44e                	sd	s3,40(sp)
    80005814:	f052                	sd	s4,32(sp)
    80005816:	ec56                	sd	s5,24(sp)
    80005818:	0880                	addi	s0,sp,80
    8000581a:	89ae                	mv	s3,a1
    8000581c:	8ab2                	mv	s5,a2
    8000581e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if ((dp = nameiparent(path, name)) == 0)
    80005820:	fb040593          	addi	a1,s0,-80
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	e86080e7          	jalr	-378(ra) # 800046aa <nameiparent>
    8000582c:	892a                	mv	s2,a0
    8000582e:	12050f63          	beqz	a0,8000596c <create+0x164>
    return 0;

  ilock(dp);
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	6a4080e7          	jalr	1700(ra) # 80003ed6 <ilock>

  if ((ip = dirlookup(dp, name, 0)) != 0)
    8000583a:	4601                	li	a2,0
    8000583c:	fb040593          	addi	a1,s0,-80
    80005840:	854a                	mv	a0,s2
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	b78080e7          	jalr	-1160(ra) # 800043ba <dirlookup>
    8000584a:	84aa                	mv	s1,a0
    8000584c:	c921                	beqz	a0,8000589c <create+0x94>
  {
    iunlockput(dp);
    8000584e:	854a                	mv	a0,s2
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	8e8080e7          	jalr	-1816(ra) # 80004138 <iunlockput>
    ilock(ip);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	67c080e7          	jalr	1660(ra) # 80003ed6 <ilock>
    if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005862:	2981                	sext.w	s3,s3
    80005864:	4789                	li	a5,2
    80005866:	02f99463          	bne	s3,a5,8000588e <create+0x86>
    8000586a:	0444d783          	lhu	a5,68(s1)
    8000586e:	37f9                	addiw	a5,a5,-2
    80005870:	17c2                	slli	a5,a5,0x30
    80005872:	93c1                	srli	a5,a5,0x30
    80005874:	4705                	li	a4,1
    80005876:	00f76c63          	bltu	a4,a5,8000588e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000587a:	8526                	mv	a0,s1
    8000587c:	60a6                	ld	ra,72(sp)
    8000587e:	6406                	ld	s0,64(sp)
    80005880:	74e2                	ld	s1,56(sp)
    80005882:	7942                	ld	s2,48(sp)
    80005884:	79a2                	ld	s3,40(sp)
    80005886:	7a02                	ld	s4,32(sp)
    80005888:	6ae2                	ld	s5,24(sp)
    8000588a:	6161                	addi	sp,sp,80
    8000588c:	8082                	ret
    iunlockput(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	8a8080e7          	jalr	-1880(ra) # 80004138 <iunlockput>
    return 0;
    80005898:	4481                	li	s1,0
    8000589a:	b7c5                	j	8000587a <create+0x72>
  if ((ip = ialloc(dp->dev, type)) == 0)
    8000589c:	85ce                	mv	a1,s3
    8000589e:	00092503          	lw	a0,0(s2)
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	49c080e7          	jalr	1180(ra) # 80003d3e <ialloc>
    800058aa:	84aa                	mv	s1,a0
    800058ac:	c529                	beqz	a0,800058f6 <create+0xee>
  ilock(ip);
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	628080e7          	jalr	1576(ra) # 80003ed6 <ilock>
  ip->major = major;
    800058b6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058ba:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800058be:	4785                	li	a5,1
    800058c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	546080e7          	jalr	1350(ra) # 80003e0c <iupdate>
  if (type == T_DIR)
    800058ce:	2981                	sext.w	s3,s3
    800058d0:	4785                	li	a5,1
    800058d2:	02f98a63          	beq	s3,a5,80005906 <create+0xfe>
  if (dirlink(dp, name, ip->inum) < 0)
    800058d6:	40d0                	lw	a2,4(s1)
    800058d8:	fb040593          	addi	a1,s0,-80
    800058dc:	854a                	mv	a0,s2
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	cec080e7          	jalr	-788(ra) # 800045ca <dirlink>
    800058e6:	06054b63          	bltz	a0,8000595c <create+0x154>
  iunlockput(dp);
    800058ea:	854a                	mv	a0,s2
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	84c080e7          	jalr	-1972(ra) # 80004138 <iunlockput>
  return ip;
    800058f4:	b759                	j	8000587a <create+0x72>
    panic("create: ialloc");
    800058f6:	00003517          	auipc	a0,0x3
    800058fa:	0da50513          	addi	a0,a0,218 # 800089d0 <sysparameters+0x258>
    800058fe:	ffffb097          	auipc	ra,0xffffb
    80005902:	c40080e7          	jalr	-960(ra) # 8000053e <panic>
    dp->nlink++; // for ".."
    80005906:	04a95783          	lhu	a5,74(s2)
    8000590a:	2785                	addiw	a5,a5,1
    8000590c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005910:	854a                	mv	a0,s2
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	4fa080e7          	jalr	1274(ra) # 80003e0c <iupdate>
    if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000591a:	40d0                	lw	a2,4(s1)
    8000591c:	00003597          	auipc	a1,0x3
    80005920:	0c458593          	addi	a1,a1,196 # 800089e0 <sysparameters+0x268>
    80005924:	8526                	mv	a0,s1
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	ca4080e7          	jalr	-860(ra) # 800045ca <dirlink>
    8000592e:	00054f63          	bltz	a0,8000594c <create+0x144>
    80005932:	00492603          	lw	a2,4(s2)
    80005936:	00003597          	auipc	a1,0x3
    8000593a:	0b258593          	addi	a1,a1,178 # 800089e8 <sysparameters+0x270>
    8000593e:	8526                	mv	a0,s1
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	c8a080e7          	jalr	-886(ra) # 800045ca <dirlink>
    80005948:	f80557e3          	bgez	a0,800058d6 <create+0xce>
      panic("create dots");
    8000594c:	00003517          	auipc	a0,0x3
    80005950:	0a450513          	addi	a0,a0,164 # 800089f0 <sysparameters+0x278>
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	bea080e7          	jalr	-1046(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000595c:	00003517          	auipc	a0,0x3
    80005960:	0a450513          	addi	a0,a0,164 # 80008a00 <sysparameters+0x288>
    80005964:	ffffb097          	auipc	ra,0xffffb
    80005968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
    return 0;
    8000596c:	84aa                	mv	s1,a0
    8000596e:	b731                	j	8000587a <create+0x72>

0000000080005970 <sys_dup>:
{
    80005970:	7179                	addi	sp,sp,-48
    80005972:	f406                	sd	ra,40(sp)
    80005974:	f022                	sd	s0,32(sp)
    80005976:	ec26                	sd	s1,24(sp)
    80005978:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0)
    8000597a:	fd840613          	addi	a2,s0,-40
    8000597e:	4581                	li	a1,0
    80005980:	4501                	li	a0,0
    80005982:	00000097          	auipc	ra,0x0
    80005986:	ddc080e7          	jalr	-548(ra) # 8000575e <argfd>
    return -1;
    8000598a:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0)
    8000598c:	02054363          	bltz	a0,800059b2 <sys_dup+0x42>
  if ((fd = fdalloc(f)) < 0)
    80005990:	fd843503          	ld	a0,-40(s0)
    80005994:	00000097          	auipc	ra,0x0
    80005998:	e32080e7          	jalr	-462(ra) # 800057c6 <fdalloc>
    8000599c:	84aa                	mv	s1,a0
    return -1;
    8000599e:	57fd                	li	a5,-1
  if ((fd = fdalloc(f)) < 0)
    800059a0:	00054963          	bltz	a0,800059b2 <sys_dup+0x42>
  filedup(f);
    800059a4:	fd843503          	ld	a0,-40(s0)
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	37a080e7          	jalr	890(ra) # 80004d22 <filedup>
  return fd;
    800059b0:	87a6                	mv	a5,s1
}
    800059b2:	853e                	mv	a0,a5
    800059b4:	70a2                	ld	ra,40(sp)
    800059b6:	7402                	ld	s0,32(sp)
    800059b8:	64e2                	ld	s1,24(sp)
    800059ba:	6145                	addi	sp,sp,48
    800059bc:	8082                	ret

00000000800059be <sys_read>:
{
    800059be:	7179                	addi	sp,sp,-48
    800059c0:	f406                	sd	ra,40(sp)
    800059c2:	f022                	sd	s0,32(sp)
    800059c4:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c6:	fe840613          	addi	a2,s0,-24
    800059ca:	4581                	li	a1,0
    800059cc:	4501                	li	a0,0
    800059ce:	00000097          	auipc	ra,0x0
    800059d2:	d90080e7          	jalr	-624(ra) # 8000575e <argfd>
    return -1;
    800059d6:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059d8:	04054163          	bltz	a0,80005a1a <sys_read+0x5c>
    800059dc:	fe440593          	addi	a1,s0,-28
    800059e0:	4509                	li	a0,2
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	6e2080e7          	jalr	1762(ra) # 800030c4 <argint>
    return -1;
    800059ea:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059ec:	02054763          	bltz	a0,80005a1a <sys_read+0x5c>
    800059f0:	fd840593          	addi	a1,s0,-40
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	6f0080e7          	jalr	1776(ra) # 800030e6 <argaddr>
    return -1;
    800059fe:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a00:	00054d63          	bltz	a0,80005a1a <sys_read+0x5c>
  return fileread(f, p, n);
    80005a04:	fe442603          	lw	a2,-28(s0)
    80005a08:	fd843583          	ld	a1,-40(s0)
    80005a0c:	fe843503          	ld	a0,-24(s0)
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	49e080e7          	jalr	1182(ra) # 80004eae <fileread>
    80005a18:	87aa                	mv	a5,a0
}
    80005a1a:	853e                	mv	a0,a5
    80005a1c:	70a2                	ld	ra,40(sp)
    80005a1e:	7402                	ld	s0,32(sp)
    80005a20:	6145                	addi	sp,sp,48
    80005a22:	8082                	ret

0000000080005a24 <sys_write>:
{
    80005a24:	7179                	addi	sp,sp,-48
    80005a26:	f406                	sd	ra,40(sp)
    80005a28:	f022                	sd	s0,32(sp)
    80005a2a:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a2c:	fe840613          	addi	a2,s0,-24
    80005a30:	4581                	li	a1,0
    80005a32:	4501                	li	a0,0
    80005a34:	00000097          	auipc	ra,0x0
    80005a38:	d2a080e7          	jalr	-726(ra) # 8000575e <argfd>
    return -1;
    80005a3c:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a3e:	04054163          	bltz	a0,80005a80 <sys_write+0x5c>
    80005a42:	fe440593          	addi	a1,s0,-28
    80005a46:	4509                	li	a0,2
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	67c080e7          	jalr	1660(ra) # 800030c4 <argint>
    return -1;
    80005a50:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a52:	02054763          	bltz	a0,80005a80 <sys_write+0x5c>
    80005a56:	fd840593          	addi	a1,s0,-40
    80005a5a:	4505                	li	a0,1
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	68a080e7          	jalr	1674(ra) # 800030e6 <argaddr>
    return -1;
    80005a64:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a66:	00054d63          	bltz	a0,80005a80 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005a6a:	fe442603          	lw	a2,-28(s0)
    80005a6e:	fd843583          	ld	a1,-40(s0)
    80005a72:	fe843503          	ld	a0,-24(s0)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	4fa080e7          	jalr	1274(ra) # 80004f70 <filewrite>
    80005a7e:	87aa                	mv	a5,a0
}
    80005a80:	853e                	mv	a0,a5
    80005a82:	70a2                	ld	ra,40(sp)
    80005a84:	7402                	ld	s0,32(sp)
    80005a86:	6145                	addi	sp,sp,48
    80005a88:	8082                	ret

0000000080005a8a <sys_close>:
{
    80005a8a:	1101                	addi	sp,sp,-32
    80005a8c:	ec06                	sd	ra,24(sp)
    80005a8e:	e822                	sd	s0,16(sp)
    80005a90:	1000                	addi	s0,sp,32
  if (argfd(0, &fd, &f) < 0)
    80005a92:	fe040613          	addi	a2,s0,-32
    80005a96:	fec40593          	addi	a1,s0,-20
    80005a9a:	4501                	li	a0,0
    80005a9c:	00000097          	auipc	ra,0x0
    80005aa0:	cc2080e7          	jalr	-830(ra) # 8000575e <argfd>
    return -1;
    80005aa4:	57fd                	li	a5,-1
  if (argfd(0, &fd, &f) < 0)
    80005aa6:	02054463          	bltz	a0,80005ace <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005aaa:	ffffc097          	auipc	ra,0xffffc
    80005aae:	124080e7          	jalr	292(ra) # 80001bce <myproc>
    80005ab2:	fec42783          	lw	a5,-20(s0)
    80005ab6:	07e9                	addi	a5,a5,26
    80005ab8:	078e                	slli	a5,a5,0x3
    80005aba:	97aa                	add	a5,a5,a0
    80005abc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005ac0:	fe043503          	ld	a0,-32(s0)
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	2b0080e7          	jalr	688(ra) # 80004d74 <fileclose>
  return 0;
    80005acc:	4781                	li	a5,0
}
    80005ace:	853e                	mv	a0,a5
    80005ad0:	60e2                	ld	ra,24(sp)
    80005ad2:	6442                	ld	s0,16(sp)
    80005ad4:	6105                	addi	sp,sp,32
    80005ad6:	8082                	ret

0000000080005ad8 <sys_fstat>:
{
    80005ad8:	1101                	addi	sp,sp,-32
    80005ada:	ec06                	sd	ra,24(sp)
    80005adc:	e822                	sd	s0,16(sp)
    80005ade:	1000                	addi	s0,sp,32
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ae0:	fe840613          	addi	a2,s0,-24
    80005ae4:	4581                	li	a1,0
    80005ae6:	4501                	li	a0,0
    80005ae8:	00000097          	auipc	ra,0x0
    80005aec:	c76080e7          	jalr	-906(ra) # 8000575e <argfd>
    return -1;
    80005af0:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005af2:	02054563          	bltz	a0,80005b1c <sys_fstat+0x44>
    80005af6:	fe040593          	addi	a1,s0,-32
    80005afa:	4505                	li	a0,1
    80005afc:	ffffd097          	auipc	ra,0xffffd
    80005b00:	5ea080e7          	jalr	1514(ra) # 800030e6 <argaddr>
    return -1;
    80005b04:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b06:	00054b63          	bltz	a0,80005b1c <sys_fstat+0x44>
  return filestat(f, st);
    80005b0a:	fe043583          	ld	a1,-32(s0)
    80005b0e:	fe843503          	ld	a0,-24(s0)
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	32a080e7          	jalr	810(ra) # 80004e3c <filestat>
    80005b1a:	87aa                	mv	a5,a0
}
    80005b1c:	853e                	mv	a0,a5
    80005b1e:	60e2                	ld	ra,24(sp)
    80005b20:	6442                	ld	s0,16(sp)
    80005b22:	6105                	addi	sp,sp,32
    80005b24:	8082                	ret

0000000080005b26 <sys_link>:
{
    80005b26:	7169                	addi	sp,sp,-304
    80005b28:	f606                	sd	ra,296(sp)
    80005b2a:	f222                	sd	s0,288(sp)
    80005b2c:	ee26                	sd	s1,280(sp)
    80005b2e:	ea4a                	sd	s2,272(sp)
    80005b30:	1a00                	addi	s0,sp,304
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b32:	08000613          	li	a2,128
    80005b36:	ed040593          	addi	a1,s0,-304
    80005b3a:	4501                	li	a0,0
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	5cc080e7          	jalr	1484(ra) # 80003108 <argstr>
    return -1;
    80005b44:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b46:	10054e63          	bltz	a0,80005c62 <sys_link+0x13c>
    80005b4a:	08000613          	li	a2,128
    80005b4e:	f5040593          	addi	a1,s0,-176
    80005b52:	4505                	li	a0,1
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	5b4080e7          	jalr	1460(ra) # 80003108 <argstr>
    return -1;
    80005b5c:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b5e:	10054263          	bltz	a0,80005c62 <sys_link+0x13c>
  begin_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	d46080e7          	jalr	-698(ra) # 800048a8 <begin_op>
  if ((ip = namei(old)) == 0)
    80005b6a:	ed040513          	addi	a0,s0,-304
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	b1e080e7          	jalr	-1250(ra) # 8000468c <namei>
    80005b76:	84aa                	mv	s1,a0
    80005b78:	c551                	beqz	a0,80005c04 <sys_link+0xde>
  ilock(ip);
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	35c080e7          	jalr	860(ra) # 80003ed6 <ilock>
  if (ip->type == T_DIR)
    80005b82:	04449703          	lh	a4,68(s1)
    80005b86:	4785                	li	a5,1
    80005b88:	08f70463          	beq	a4,a5,80005c10 <sys_link+0xea>
  ip->nlink++;
    80005b8c:	04a4d783          	lhu	a5,74(s1)
    80005b90:	2785                	addiw	a5,a5,1
    80005b92:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	274080e7          	jalr	628(ra) # 80003e0c <iupdate>
  iunlock(ip);
    80005ba0:	8526                	mv	a0,s1
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	3f6080e7          	jalr	1014(ra) # 80003f98 <iunlock>
  if ((dp = nameiparent(new, name)) == 0)
    80005baa:	fd040593          	addi	a1,s0,-48
    80005bae:	f5040513          	addi	a0,s0,-176
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	af8080e7          	jalr	-1288(ra) # 800046aa <nameiparent>
    80005bba:	892a                	mv	s2,a0
    80005bbc:	c935                	beqz	a0,80005c30 <sys_link+0x10a>
  ilock(dp);
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	318080e7          	jalr	792(ra) # 80003ed6 <ilock>
  if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0)
    80005bc6:	00092703          	lw	a4,0(s2)
    80005bca:	409c                	lw	a5,0(s1)
    80005bcc:	04f71d63          	bne	a4,a5,80005c26 <sys_link+0x100>
    80005bd0:	40d0                	lw	a2,4(s1)
    80005bd2:	fd040593          	addi	a1,s0,-48
    80005bd6:	854a                	mv	a0,s2
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	9f2080e7          	jalr	-1550(ra) # 800045ca <dirlink>
    80005be0:	04054363          	bltz	a0,80005c26 <sys_link+0x100>
  iunlockput(dp);
    80005be4:	854a                	mv	a0,s2
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	552080e7          	jalr	1362(ra) # 80004138 <iunlockput>
  iput(ip);
    80005bee:	8526                	mv	a0,s1
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	4a0080e7          	jalr	1184(ra) # 80004090 <iput>
  end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	d30080e7          	jalr	-720(ra) # 80004928 <end_op>
  return 0;
    80005c00:	4781                	li	a5,0
    80005c02:	a085                	j	80005c62 <sys_link+0x13c>
    end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	d24080e7          	jalr	-732(ra) # 80004928 <end_op>
    return -1;
    80005c0c:	57fd                	li	a5,-1
    80005c0e:	a891                	j	80005c62 <sys_link+0x13c>
    iunlockput(ip);
    80005c10:	8526                	mv	a0,s1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	526080e7          	jalr	1318(ra) # 80004138 <iunlockput>
    end_op();
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	d0e080e7          	jalr	-754(ra) # 80004928 <end_op>
    return -1;
    80005c22:	57fd                	li	a5,-1
    80005c24:	a83d                	j	80005c62 <sys_link+0x13c>
    iunlockput(dp);
    80005c26:	854a                	mv	a0,s2
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	510080e7          	jalr	1296(ra) # 80004138 <iunlockput>
  ilock(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	2a4080e7          	jalr	676(ra) # 80003ed6 <ilock>
  ip->nlink--;
    80005c3a:	04a4d783          	lhu	a5,74(s1)
    80005c3e:	37fd                	addiw	a5,a5,-1
    80005c40:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c44:	8526                	mv	a0,s1
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	1c6080e7          	jalr	454(ra) # 80003e0c <iupdate>
  iunlockput(ip);
    80005c4e:	8526                	mv	a0,s1
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	4e8080e7          	jalr	1256(ra) # 80004138 <iunlockput>
  end_op();
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	cd0080e7          	jalr	-816(ra) # 80004928 <end_op>
  return -1;
    80005c60:	57fd                	li	a5,-1
}
    80005c62:	853e                	mv	a0,a5
    80005c64:	70b2                	ld	ra,296(sp)
    80005c66:	7412                	ld	s0,288(sp)
    80005c68:	64f2                	ld	s1,280(sp)
    80005c6a:	6952                	ld	s2,272(sp)
    80005c6c:	6155                	addi	sp,sp,304
    80005c6e:	8082                	ret

0000000080005c70 <sys_unlink>:
{
    80005c70:	7151                	addi	sp,sp,-240
    80005c72:	f586                	sd	ra,232(sp)
    80005c74:	f1a2                	sd	s0,224(sp)
    80005c76:	eda6                	sd	s1,216(sp)
    80005c78:	e9ca                	sd	s2,208(sp)
    80005c7a:	e5ce                	sd	s3,200(sp)
    80005c7c:	1980                	addi	s0,sp,240
  if (argstr(0, path, MAXPATH) < 0)
    80005c7e:	08000613          	li	a2,128
    80005c82:	f3040593          	addi	a1,s0,-208
    80005c86:	4501                	li	a0,0
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	480080e7          	jalr	1152(ra) # 80003108 <argstr>
    80005c90:	18054163          	bltz	a0,80005e12 <sys_unlink+0x1a2>
  begin_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	c14080e7          	jalr	-1004(ra) # 800048a8 <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    80005c9c:	fb040593          	addi	a1,s0,-80
    80005ca0:	f3040513          	addi	a0,s0,-208
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	a06080e7          	jalr	-1530(ra) # 800046aa <nameiparent>
    80005cac:	84aa                	mv	s1,a0
    80005cae:	c979                	beqz	a0,80005d84 <sys_unlink+0x114>
  ilock(dp);
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	226080e7          	jalr	550(ra) # 80003ed6 <ilock>
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cb8:	00003597          	auipc	a1,0x3
    80005cbc:	d2858593          	addi	a1,a1,-728 # 800089e0 <sysparameters+0x268>
    80005cc0:	fb040513          	addi	a0,s0,-80
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	6dc080e7          	jalr	1756(ra) # 800043a0 <namecmp>
    80005ccc:	14050a63          	beqz	a0,80005e20 <sys_unlink+0x1b0>
    80005cd0:	00003597          	auipc	a1,0x3
    80005cd4:	d1858593          	addi	a1,a1,-744 # 800089e8 <sysparameters+0x270>
    80005cd8:	fb040513          	addi	a0,s0,-80
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	6c4080e7          	jalr	1732(ra) # 800043a0 <namecmp>
    80005ce4:	12050e63          	beqz	a0,80005e20 <sys_unlink+0x1b0>
  if ((ip = dirlookup(dp, name, &off)) == 0)
    80005ce8:	f2c40613          	addi	a2,s0,-212
    80005cec:	fb040593          	addi	a1,s0,-80
    80005cf0:	8526                	mv	a0,s1
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	6c8080e7          	jalr	1736(ra) # 800043ba <dirlookup>
    80005cfa:	892a                	mv	s2,a0
    80005cfc:	12050263          	beqz	a0,80005e20 <sys_unlink+0x1b0>
  ilock(ip);
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	1d6080e7          	jalr	470(ra) # 80003ed6 <ilock>
  if (ip->nlink < 1)
    80005d08:	04a91783          	lh	a5,74(s2)
    80005d0c:	08f05263          	blez	a5,80005d90 <sys_unlink+0x120>
  if (ip->type == T_DIR && !isdirempty(ip))
    80005d10:	04491703          	lh	a4,68(s2)
    80005d14:	4785                	li	a5,1
    80005d16:	08f70563          	beq	a4,a5,80005da0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d1a:	4641                	li	a2,16
    80005d1c:	4581                	li	a1,0
    80005d1e:	fc040513          	addi	a0,s0,-64
    80005d22:	ffffb097          	auipc	ra,0xffffb
    80005d26:	198080e7          	jalr	408(ra) # 80000eba <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d2a:	4741                	li	a4,16
    80005d2c:	f2c42683          	lw	a3,-212(s0)
    80005d30:	fc040613          	addi	a2,s0,-64
    80005d34:	4581                	li	a1,0
    80005d36:	8526                	mv	a0,s1
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	54a080e7          	jalr	1354(ra) # 80004282 <writei>
    80005d40:	47c1                	li	a5,16
    80005d42:	0af51563          	bne	a0,a5,80005dec <sys_unlink+0x17c>
  if (ip->type == T_DIR)
    80005d46:	04491703          	lh	a4,68(s2)
    80005d4a:	4785                	li	a5,1
    80005d4c:	0af70863          	beq	a4,a5,80005dfc <sys_unlink+0x18c>
  iunlockput(dp);
    80005d50:	8526                	mv	a0,s1
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	3e6080e7          	jalr	998(ra) # 80004138 <iunlockput>
  ip->nlink--;
    80005d5a:	04a95783          	lhu	a5,74(s2)
    80005d5e:	37fd                	addiw	a5,a5,-1
    80005d60:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d64:	854a                	mv	a0,s2
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	0a6080e7          	jalr	166(ra) # 80003e0c <iupdate>
  iunlockput(ip);
    80005d6e:	854a                	mv	a0,s2
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	3c8080e7          	jalr	968(ra) # 80004138 <iunlockput>
  end_op();
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	bb0080e7          	jalr	-1104(ra) # 80004928 <end_op>
  return 0;
    80005d80:	4501                	li	a0,0
    80005d82:	a84d                	j	80005e34 <sys_unlink+0x1c4>
    end_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	ba4080e7          	jalr	-1116(ra) # 80004928 <end_op>
    return -1;
    80005d8c:	557d                	li	a0,-1
    80005d8e:	a05d                	j	80005e34 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d90:	00003517          	auipc	a0,0x3
    80005d94:	c8050513          	addi	a0,a0,-896 # 80008a10 <sysparameters+0x298>
    80005d98:	ffffa097          	auipc	ra,0xffffa
    80005d9c:	7a6080e7          	jalr	1958(ra) # 8000053e <panic>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005da0:	04c92703          	lw	a4,76(s2)
    80005da4:	02000793          	li	a5,32
    80005da8:	f6e7f9e3          	bgeu	a5,a4,80005d1a <sys_unlink+0xaa>
    80005dac:	02000993          	li	s3,32
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005db0:	4741                	li	a4,16
    80005db2:	86ce                	mv	a3,s3
    80005db4:	f1840613          	addi	a2,s0,-232
    80005db8:	4581                	li	a1,0
    80005dba:	854a                	mv	a0,s2
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	3ce080e7          	jalr	974(ra) # 8000418a <readi>
    80005dc4:	47c1                	li	a5,16
    80005dc6:	00f51b63          	bne	a0,a5,80005ddc <sys_unlink+0x16c>
    if (de.inum != 0)
    80005dca:	f1845783          	lhu	a5,-232(s0)
    80005dce:	e7a1                	bnez	a5,80005e16 <sys_unlink+0x1a6>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005dd0:	29c1                	addiw	s3,s3,16
    80005dd2:	04c92783          	lw	a5,76(s2)
    80005dd6:	fcf9ede3          	bltu	s3,a5,80005db0 <sys_unlink+0x140>
    80005dda:	b781                	j	80005d1a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ddc:	00003517          	auipc	a0,0x3
    80005de0:	c4c50513          	addi	a0,a0,-948 # 80008a28 <sysparameters+0x2b0>
    80005de4:	ffffa097          	auipc	ra,0xffffa
    80005de8:	75a080e7          	jalr	1882(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005dec:	00003517          	auipc	a0,0x3
    80005df0:	c5450513          	addi	a0,a0,-940 # 80008a40 <sysparameters+0x2c8>
    80005df4:	ffffa097          	auipc	ra,0xffffa
    80005df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
    dp->nlink--;
    80005dfc:	04a4d783          	lhu	a5,74(s1)
    80005e00:	37fd                	addiw	a5,a5,-1
    80005e02:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e06:	8526                	mv	a0,s1
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	004080e7          	jalr	4(ra) # 80003e0c <iupdate>
    80005e10:	b781                	j	80005d50 <sys_unlink+0xe0>
    return -1;
    80005e12:	557d                	li	a0,-1
    80005e14:	a005                	j	80005e34 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e16:	854a                	mv	a0,s2
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	320080e7          	jalr	800(ra) # 80004138 <iunlockput>
  iunlockput(dp);
    80005e20:	8526                	mv	a0,s1
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	316080e7          	jalr	790(ra) # 80004138 <iunlockput>
  end_op();
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	afe080e7          	jalr	-1282(ra) # 80004928 <end_op>
  return -1;
    80005e32:	557d                	li	a0,-1
}
    80005e34:	70ae                	ld	ra,232(sp)
    80005e36:	740e                	ld	s0,224(sp)
    80005e38:	64ee                	ld	s1,216(sp)
    80005e3a:	694e                	ld	s2,208(sp)
    80005e3c:	69ae                	ld	s3,200(sp)
    80005e3e:	616d                	addi	sp,sp,240
    80005e40:	8082                	ret

0000000080005e42 <sys_open>:

uint64
sys_open(void)
{
    80005e42:	7131                	addi	sp,sp,-192
    80005e44:	fd06                	sd	ra,184(sp)
    80005e46:	f922                	sd	s0,176(sp)
    80005e48:	f526                	sd	s1,168(sp)
    80005e4a:	f14a                	sd	s2,160(sp)
    80005e4c:	ed4e                	sd	s3,152(sp)
    80005e4e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if ((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e50:	08000613          	li	a2,128
    80005e54:	f5040593          	addi	a1,s0,-176
    80005e58:	4501                	li	a0,0
    80005e5a:	ffffd097          	auipc	ra,0xffffd
    80005e5e:	2ae080e7          	jalr	686(ra) # 80003108 <argstr>
    return -1;
    80005e62:	54fd                	li	s1,-1
  if ((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e64:	0c054163          	bltz	a0,80005f26 <sys_open+0xe4>
    80005e68:	f4c40593          	addi	a1,s0,-180
    80005e6c:	4505                	li	a0,1
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	256080e7          	jalr	598(ra) # 800030c4 <argint>
    80005e76:	0a054863          	bltz	a0,80005f26 <sys_open+0xe4>

  begin_op();
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	a2e080e7          	jalr	-1490(ra) # 800048a8 <begin_op>

  if (omode & O_CREATE)
    80005e82:	f4c42783          	lw	a5,-180(s0)
    80005e86:	2007f793          	andi	a5,a5,512
    80005e8a:	cbdd                	beqz	a5,80005f40 <sys_open+0xfe>
  {
    ip = create(path, T_FILE, 0, 0);
    80005e8c:	4681                	li	a3,0
    80005e8e:	4601                	li	a2,0
    80005e90:	4589                	li	a1,2
    80005e92:	f5040513          	addi	a0,s0,-176
    80005e96:	00000097          	auipc	ra,0x0
    80005e9a:	972080e7          	jalr	-1678(ra) # 80005808 <create>
    80005e9e:	892a                	mv	s2,a0
    if (ip == 0)
    80005ea0:	c959                	beqz	a0,80005f36 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if (ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV))
    80005ea2:	04491703          	lh	a4,68(s2)
    80005ea6:	478d                	li	a5,3
    80005ea8:	00f71763          	bne	a4,a5,80005eb6 <sys_open+0x74>
    80005eac:	04695703          	lhu	a4,70(s2)
    80005eb0:	47a5                	li	a5,9
    80005eb2:	0ce7ec63          	bltu	a5,a4,80005f8a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if ((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	e02080e7          	jalr	-510(ra) # 80004cb8 <filealloc>
    80005ebe:	89aa                	mv	s3,a0
    80005ec0:	10050263          	beqz	a0,80005fc4 <sys_open+0x182>
    80005ec4:	00000097          	auipc	ra,0x0
    80005ec8:	902080e7          	jalr	-1790(ra) # 800057c6 <fdalloc>
    80005ecc:	84aa                	mv	s1,a0
    80005ece:	0e054663          	bltz	a0,80005fba <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if (ip->type == T_DEVICE)
    80005ed2:	04491703          	lh	a4,68(s2)
    80005ed6:	478d                	li	a5,3
    80005ed8:	0cf70463          	beq	a4,a5,80005fa0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  }
  else
  {
    f->type = FD_INODE;
    80005edc:	4789                	li	a5,2
    80005ede:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ee2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ee6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005eea:	f4c42783          	lw	a5,-180(s0)
    80005eee:	0017c713          	xori	a4,a5,1
    80005ef2:	8b05                	andi	a4,a4,1
    80005ef4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ef8:	0037f713          	andi	a4,a5,3
    80005efc:	00e03733          	snez	a4,a4
    80005f00:	00e984a3          	sb	a4,9(s3)

  if ((omode & O_TRUNC) && ip->type == T_FILE)
    80005f04:	4007f793          	andi	a5,a5,1024
    80005f08:	c791                	beqz	a5,80005f14 <sys_open+0xd2>
    80005f0a:	04491703          	lh	a4,68(s2)
    80005f0e:	4789                	li	a5,2
    80005f10:	08f70f63          	beq	a4,a5,80005fae <sys_open+0x16c>
  {
    itrunc(ip);
  }

  iunlock(ip);
    80005f14:	854a                	mv	a0,s2
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	082080e7          	jalr	130(ra) # 80003f98 <iunlock>
  end_op();
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	a0a080e7          	jalr	-1526(ra) # 80004928 <end_op>

  return fd;
}
    80005f26:	8526                	mv	a0,s1
    80005f28:	70ea                	ld	ra,184(sp)
    80005f2a:	744a                	ld	s0,176(sp)
    80005f2c:	74aa                	ld	s1,168(sp)
    80005f2e:	790a                	ld	s2,160(sp)
    80005f30:	69ea                	ld	s3,152(sp)
    80005f32:	6129                	addi	sp,sp,192
    80005f34:	8082                	ret
      end_op();
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	9f2080e7          	jalr	-1550(ra) # 80004928 <end_op>
      return -1;
    80005f3e:	b7e5                	j	80005f26 <sys_open+0xe4>
    if ((ip = namei(path)) == 0)
    80005f40:	f5040513          	addi	a0,s0,-176
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	748080e7          	jalr	1864(ra) # 8000468c <namei>
    80005f4c:	892a                	mv	s2,a0
    80005f4e:	c905                	beqz	a0,80005f7e <sys_open+0x13c>
    ilock(ip);
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	f86080e7          	jalr	-122(ra) # 80003ed6 <ilock>
    if (ip->type == T_DIR && omode != O_RDONLY)
    80005f58:	04491703          	lh	a4,68(s2)
    80005f5c:	4785                	li	a5,1
    80005f5e:	f4f712e3          	bne	a4,a5,80005ea2 <sys_open+0x60>
    80005f62:	f4c42783          	lw	a5,-180(s0)
    80005f66:	dba1                	beqz	a5,80005eb6 <sys_open+0x74>
      iunlockput(ip);
    80005f68:	854a                	mv	a0,s2
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	1ce080e7          	jalr	462(ra) # 80004138 <iunlockput>
      end_op();
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	9b6080e7          	jalr	-1610(ra) # 80004928 <end_op>
      return -1;
    80005f7a:	54fd                	li	s1,-1
    80005f7c:	b76d                	j	80005f26 <sys_open+0xe4>
      end_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	9aa080e7          	jalr	-1622(ra) # 80004928 <end_op>
      return -1;
    80005f86:	54fd                	li	s1,-1
    80005f88:	bf79                	j	80005f26 <sys_open+0xe4>
    iunlockput(ip);
    80005f8a:	854a                	mv	a0,s2
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	1ac080e7          	jalr	428(ra) # 80004138 <iunlockput>
    end_op();
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	994080e7          	jalr	-1644(ra) # 80004928 <end_op>
    return -1;
    80005f9c:	54fd                	li	s1,-1
    80005f9e:	b761                	j	80005f26 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fa0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fa4:	04691783          	lh	a5,70(s2)
    80005fa8:	02f99223          	sh	a5,36(s3)
    80005fac:	bf2d                	j	80005ee6 <sys_open+0xa4>
    itrunc(ip);
    80005fae:	854a                	mv	a0,s2
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	034080e7          	jalr	52(ra) # 80003fe4 <itrunc>
    80005fb8:	bfb1                	j	80005f14 <sys_open+0xd2>
      fileclose(f);
    80005fba:	854e                	mv	a0,s3
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	db8080e7          	jalr	-584(ra) # 80004d74 <fileclose>
    iunlockput(ip);
    80005fc4:	854a                	mv	a0,s2
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	172080e7          	jalr	370(ra) # 80004138 <iunlockput>
    end_op();
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	95a080e7          	jalr	-1702(ra) # 80004928 <end_op>
    return -1;
    80005fd6:	54fd                	li	s1,-1
    80005fd8:	b7b9                	j	80005f26 <sys_open+0xe4>

0000000080005fda <sys_mkdir>:

// const cinfo info_open = {.name = "open", .argc = 2};

uint64
sys_mkdir(void)
{
    80005fda:	7175                	addi	sp,sp,-144
    80005fdc:	e506                	sd	ra,136(sp)
    80005fde:	e122                	sd	s0,128(sp)
    80005fe0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	8c6080e7          	jalr	-1850(ra) # 800048a8 <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
    80005fea:	08000613          	li	a2,128
    80005fee:	f7040593          	addi	a1,s0,-144
    80005ff2:	4501                	li	a0,0
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	114080e7          	jalr	276(ra) # 80003108 <argstr>
    80005ffc:	02054963          	bltz	a0,8000602e <sys_mkdir+0x54>
    80006000:	4681                	li	a3,0
    80006002:	4601                	li	a2,0
    80006004:	4585                	li	a1,1
    80006006:	f7040513          	addi	a0,s0,-144
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	7fe080e7          	jalr	2046(ra) # 80005808 <create>
    80006012:	cd11                	beqz	a0,8000602e <sys_mkdir+0x54>
  {
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	124080e7          	jalr	292(ra) # 80004138 <iunlockput>
  end_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	90c080e7          	jalr	-1780(ra) # 80004928 <end_op>
  return 0;
    80006024:	4501                	li	a0,0
}
    80006026:	60aa                	ld	ra,136(sp)
    80006028:	640a                	ld	s0,128(sp)
    8000602a:	6149                	addi	sp,sp,144
    8000602c:	8082                	ret
    end_op();
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	8fa080e7          	jalr	-1798(ra) # 80004928 <end_op>
    return -1;
    80006036:	557d                	li	a0,-1
    80006038:	b7fd                	j	80006026 <sys_mkdir+0x4c>

000000008000603a <sys_mknod>:

// const cinfo info_mkdir = {.name = "mkdir", .argc = 2};

uint64
sys_mknod(void)
{
    8000603a:	7135                	addi	sp,sp,-160
    8000603c:	ed06                	sd	ra,152(sp)
    8000603e:	e922                	sd	s0,144(sp)
    80006040:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006042:	fffff097          	auipc	ra,0xfffff
    80006046:	866080e7          	jalr	-1946(ra) # 800048a8 <begin_op>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    8000604a:	08000613          	li	a2,128
    8000604e:	f7040593          	addi	a1,s0,-144
    80006052:	4501                	li	a0,0
    80006054:	ffffd097          	auipc	ra,0xffffd
    80006058:	0b4080e7          	jalr	180(ra) # 80003108 <argstr>
    8000605c:	04054a63          	bltz	a0,800060b0 <sys_mknod+0x76>
      argint(1, &major) < 0 ||
    80006060:	f6c40593          	addi	a1,s0,-148
    80006064:	4505                	li	a0,1
    80006066:	ffffd097          	auipc	ra,0xffffd
    8000606a:	05e080e7          	jalr	94(ra) # 800030c4 <argint>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    8000606e:	04054163          	bltz	a0,800060b0 <sys_mknod+0x76>
      argint(2, &minor) < 0 ||
    80006072:	f6840593          	addi	a1,s0,-152
    80006076:	4509                	li	a0,2
    80006078:	ffffd097          	auipc	ra,0xffffd
    8000607c:	04c080e7          	jalr	76(ra) # 800030c4 <argint>
      argint(1, &major) < 0 ||
    80006080:	02054863          	bltz	a0,800060b0 <sys_mknod+0x76>
      (ip = create(path, T_DEVICE, major, minor)) == 0)
    80006084:	f6841683          	lh	a3,-152(s0)
    80006088:	f6c41603          	lh	a2,-148(s0)
    8000608c:	458d                	li	a1,3
    8000608e:	f7040513          	addi	a0,s0,-144
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	776080e7          	jalr	1910(ra) # 80005808 <create>
      argint(2, &minor) < 0 ||
    8000609a:	c919                	beqz	a0,800060b0 <sys_mknod+0x76>
  {
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	09c080e7          	jalr	156(ra) # 80004138 <iunlockput>
  end_op();
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	884080e7          	jalr	-1916(ra) # 80004928 <end_op>
  return 0;
    800060ac:	4501                	li	a0,0
    800060ae:	a031                	j	800060ba <sys_mknod+0x80>
    end_op();
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	878080e7          	jalr	-1928(ra) # 80004928 <end_op>
    return -1;
    800060b8:	557d                	li	a0,-1
}
    800060ba:	60ea                	ld	ra,152(sp)
    800060bc:	644a                	ld	s0,144(sp)
    800060be:	610d                	addi	sp,sp,160
    800060c0:	8082                	ret

00000000800060c2 <sys_chdir>:

// const cinfo info_mknod = {.name = "mknod", .argc = 1};

uint64
sys_chdir(void)
{
    800060c2:	7135                	addi	sp,sp,-160
    800060c4:	ed06                	sd	ra,152(sp)
    800060c6:	e922                	sd	s0,144(sp)
    800060c8:	e526                	sd	s1,136(sp)
    800060ca:	e14a                	sd	s2,128(sp)
    800060cc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060ce:	ffffc097          	auipc	ra,0xffffc
    800060d2:	b00080e7          	jalr	-1280(ra) # 80001bce <myproc>
    800060d6:	892a                	mv	s2,a0

  begin_op();
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	7d0080e7          	jalr	2000(ra) # 800048a8 <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0)
    800060e0:	08000613          	li	a2,128
    800060e4:	f6040593          	addi	a1,s0,-160
    800060e8:	4501                	li	a0,0
    800060ea:	ffffd097          	auipc	ra,0xffffd
    800060ee:	01e080e7          	jalr	30(ra) # 80003108 <argstr>
    800060f2:	04054b63          	bltz	a0,80006148 <sys_chdir+0x86>
    800060f6:	f6040513          	addi	a0,s0,-160
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	592080e7          	jalr	1426(ra) # 8000468c <namei>
    80006102:	84aa                	mv	s1,a0
    80006104:	c131                	beqz	a0,80006148 <sys_chdir+0x86>
  {
    end_op();
    return -1;
  }
  ilock(ip);
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	dd0080e7          	jalr	-560(ra) # 80003ed6 <ilock>
  if (ip->type != T_DIR)
    8000610e:	04449703          	lh	a4,68(s1)
    80006112:	4785                	li	a5,1
    80006114:	04f71063          	bne	a4,a5,80006154 <sys_chdir+0x92>
  {
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006118:	8526                	mv	a0,s1
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	e7e080e7          	jalr	-386(ra) # 80003f98 <iunlock>
  iput(p->cwd);
    80006122:	15093503          	ld	a0,336(s2)
    80006126:	ffffe097          	auipc	ra,0xffffe
    8000612a:	f6a080e7          	jalr	-150(ra) # 80004090 <iput>
  end_op();
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	7fa080e7          	jalr	2042(ra) # 80004928 <end_op>
  p->cwd = ip;
    80006136:	14993823          	sd	s1,336(s2)
  return 0;
    8000613a:	4501                	li	a0,0
}
    8000613c:	60ea                	ld	ra,152(sp)
    8000613e:	644a                	ld	s0,144(sp)
    80006140:	64aa                	ld	s1,136(sp)
    80006142:	690a                	ld	s2,128(sp)
    80006144:	610d                	addi	sp,sp,160
    80006146:	8082                	ret
    end_op();
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	7e0080e7          	jalr	2016(ra) # 80004928 <end_op>
    return -1;
    80006150:	557d                	li	a0,-1
    80006152:	b7ed                	j	8000613c <sys_chdir+0x7a>
    iunlockput(ip);
    80006154:	8526                	mv	a0,s1
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	fe2080e7          	jalr	-30(ra) # 80004138 <iunlockput>
    end_op();
    8000615e:	ffffe097          	auipc	ra,0xffffe
    80006162:	7ca080e7          	jalr	1994(ra) # 80004928 <end_op>
    return -1;
    80006166:	557d                	li	a0,-1
    80006168:	bfd1                	j	8000613c <sys_chdir+0x7a>

000000008000616a <sys_exec>:

// const cinfo info_chdir = {.name = "chdir", .argc = 1};

uint64
sys_exec(void)
{
    8000616a:	7145                	addi	sp,sp,-464
    8000616c:	e786                	sd	ra,456(sp)
    8000616e:	e3a2                	sd	s0,448(sp)
    80006170:	ff26                	sd	s1,440(sp)
    80006172:	fb4a                	sd	s2,432(sp)
    80006174:	f74e                	sd	s3,424(sp)
    80006176:	f352                	sd	s4,416(sp)
    80006178:	ef56                	sd	s5,408(sp)
    8000617a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if (argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0)
    8000617c:	08000613          	li	a2,128
    80006180:	f4040593          	addi	a1,s0,-192
    80006184:	4501                	li	a0,0
    80006186:	ffffd097          	auipc	ra,0xffffd
    8000618a:	f82080e7          	jalr	-126(ra) # 80003108 <argstr>
  {
    return -1;
    8000618e:	597d                	li	s2,-1
  if (argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0)
    80006190:	0c054a63          	bltz	a0,80006264 <sys_exec+0xfa>
    80006194:	e3840593          	addi	a1,s0,-456
    80006198:	4505                	li	a0,1
    8000619a:	ffffd097          	auipc	ra,0xffffd
    8000619e:	f4c080e7          	jalr	-180(ra) # 800030e6 <argaddr>
    800061a2:	0c054163          	bltz	a0,80006264 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061a6:	10000613          	li	a2,256
    800061aa:	4581                	li	a1,0
    800061ac:	e4040513          	addi	a0,s0,-448
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	d0a080e7          	jalr	-758(ra) # 80000eba <memset>
  for (i = 0;; i++)
  {
    if (i >= NELEM(argv))
    800061b8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061bc:	89a6                	mv	s3,s1
    800061be:	4901                	li	s2,0
    if (i >= NELEM(argv))
    800061c0:	02000a13          	li	s4,32
    800061c4:	00090a9b          	sext.w	s5,s2
    {
      goto bad;
    }
    if (fetchaddr(uargv + sizeof(uint64) * i, (uint64 *)&uarg) < 0)
    800061c8:	00391513          	slli	a0,s2,0x3
    800061cc:	e3040593          	addi	a1,s0,-464
    800061d0:	e3843783          	ld	a5,-456(s0)
    800061d4:	953e                	add	a0,a0,a5
    800061d6:	ffffd097          	auipc	ra,0xffffd
    800061da:	e54080e7          	jalr	-428(ra) # 8000302a <fetchaddr>
    800061de:	02054a63          	bltz	a0,80006212 <sys_exec+0xa8>
    {
      goto bad;
    }
    if (uarg == 0)
    800061e2:	e3043783          	ld	a5,-464(s0)
    800061e6:	c3b9                	beqz	a5,8000622c <sys_exec+0xc2>
    {
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	a90080e7          	jalr	-1392(ra) # 80000c78 <kalloc>
    800061f0:	85aa                	mv	a1,a0
    800061f2:	00a9b023          	sd	a0,0(s3)
    if (argv[i] == 0)
    800061f6:	cd11                	beqz	a0,80006212 <sys_exec+0xa8>
      goto bad;
    if (fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061f8:	6605                	lui	a2,0x1
    800061fa:	e3043503          	ld	a0,-464(s0)
    800061fe:	ffffd097          	auipc	ra,0xffffd
    80006202:	e7e080e7          	jalr	-386(ra) # 8000307c <fetchstr>
    80006206:	00054663          	bltz	a0,80006212 <sys_exec+0xa8>
    if (i >= NELEM(argv))
    8000620a:	0905                	addi	s2,s2,1
    8000620c:	09a1                	addi	s3,s3,8
    8000620e:	fb491be3          	bne	s2,s4,800061c4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

bad:
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006212:	10048913          	addi	s2,s1,256
    80006216:	6088                	ld	a0,0(s1)
    80006218:	c529                	beqz	a0,80006262 <sys_exec+0xf8>
    kfree(argv[i]);
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	84a080e7          	jalr	-1974(ra) # 80000a64 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006222:	04a1                	addi	s1,s1,8
    80006224:	ff2499e3          	bne	s1,s2,80006216 <sys_exec+0xac>
  return -1;
    80006228:	597d                	li	s2,-1
    8000622a:	a82d                	j	80006264 <sys_exec+0xfa>
      argv[i] = 0;
    8000622c:	0a8e                	slli	s5,s5,0x3
    8000622e:	fc040793          	addi	a5,s0,-64
    80006232:	9abe                	add	s5,s5,a5
    80006234:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006238:	e4040593          	addi	a1,s0,-448
    8000623c:	f4040513          	addi	a0,s0,-192
    80006240:	fffff097          	auipc	ra,0xfffff
    80006244:	194080e7          	jalr	404(ra) # 800053d4 <exec>
    80006248:	892a                	mv	s2,a0
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000624a:	10048993          	addi	s3,s1,256
    8000624e:	6088                	ld	a0,0(s1)
    80006250:	c911                	beqz	a0,80006264 <sys_exec+0xfa>
    kfree(argv[i]);
    80006252:	ffffb097          	auipc	ra,0xffffb
    80006256:	812080e7          	jalr	-2030(ra) # 80000a64 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000625a:	04a1                	addi	s1,s1,8
    8000625c:	ff3499e3          	bne	s1,s3,8000624e <sys_exec+0xe4>
    80006260:	a011                	j	80006264 <sys_exec+0xfa>
  return -1;
    80006262:	597d                	li	s2,-1
}
    80006264:	854a                	mv	a0,s2
    80006266:	60be                	ld	ra,456(sp)
    80006268:	641e                	ld	s0,448(sp)
    8000626a:	74fa                	ld	s1,440(sp)
    8000626c:	795a                	ld	s2,432(sp)
    8000626e:	79ba                	ld	s3,424(sp)
    80006270:	7a1a                	ld	s4,416(sp)
    80006272:	6afa                	ld	s5,408(sp)
    80006274:	6179                	addi	sp,sp,464
    80006276:	8082                	ret

0000000080006278 <sys_pipe>:

// const cinfo info_exec = {.name = "exec", .argc = 2};

uint64
sys_pipe(void)
{
    80006278:	7139                	addi	sp,sp,-64
    8000627a:	fc06                	sd	ra,56(sp)
    8000627c:	f822                	sd	s0,48(sp)
    8000627e:	f426                	sd	s1,40(sp)
    80006280:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006282:	ffffc097          	auipc	ra,0xffffc
    80006286:	94c080e7          	jalr	-1716(ra) # 80001bce <myproc>
    8000628a:	84aa                	mv	s1,a0

  if (argaddr(0, &fdarray) < 0)
    8000628c:	fd840593          	addi	a1,s0,-40
    80006290:	4501                	li	a0,0
    80006292:	ffffd097          	auipc	ra,0xffffd
    80006296:	e54080e7          	jalr	-428(ra) # 800030e6 <argaddr>
    return -1;
    8000629a:	57fd                	li	a5,-1
  if (argaddr(0, &fdarray) < 0)
    8000629c:	0e054063          	bltz	a0,8000637c <sys_pipe+0x104>
  if (pipealloc(&rf, &wf) < 0)
    800062a0:	fc840593          	addi	a1,s0,-56
    800062a4:	fd040513          	addi	a0,s0,-48
    800062a8:	fffff097          	auipc	ra,0xfffff
    800062ac:	dfc080e7          	jalr	-516(ra) # 800050a4 <pipealloc>
    return -1;
    800062b0:	57fd                	li	a5,-1
  if (pipealloc(&rf, &wf) < 0)
    800062b2:	0c054563          	bltz	a0,8000637c <sys_pipe+0x104>
  fd0 = -1;
    800062b6:	fcf42223          	sw	a5,-60(s0)
  if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0)
    800062ba:	fd043503          	ld	a0,-48(s0)
    800062be:	fffff097          	auipc	ra,0xfffff
    800062c2:	508080e7          	jalr	1288(ra) # 800057c6 <fdalloc>
    800062c6:	fca42223          	sw	a0,-60(s0)
    800062ca:	08054c63          	bltz	a0,80006362 <sys_pipe+0xea>
    800062ce:	fc843503          	ld	a0,-56(s0)
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	4f4080e7          	jalr	1268(ra) # 800057c6 <fdalloc>
    800062da:	fca42023          	sw	a0,-64(s0)
    800062de:	06054863          	bltz	a0,8000634e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    800062e2:	4691                	li	a3,4
    800062e4:	fc440613          	addi	a2,s0,-60
    800062e8:	fd843583          	ld	a1,-40(s0)
    800062ec:	68a8                	ld	a0,80(s1)
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	566080e7          	jalr	1382(ra) # 80001854 <copyout>
    800062f6:	02054063          	bltz	a0,80006316 <sys_pipe+0x9e>
      copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0)
    800062fa:	4691                	li	a3,4
    800062fc:	fc040613          	addi	a2,s0,-64
    80006300:	fd843583          	ld	a1,-40(s0)
    80006304:	0591                	addi	a1,a1,4
    80006306:	68a8                	ld	a0,80(s1)
    80006308:	ffffb097          	auipc	ra,0xffffb
    8000630c:	54c080e7          	jalr	1356(ra) # 80001854 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006310:	4781                	li	a5,0
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80006312:	06055563          	bgez	a0,8000637c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006316:	fc442783          	lw	a5,-60(s0)
    8000631a:	07e9                	addi	a5,a5,26
    8000631c:	078e                	slli	a5,a5,0x3
    8000631e:	97a6                	add	a5,a5,s1
    80006320:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006324:	fc042503          	lw	a0,-64(s0)
    80006328:	0569                	addi	a0,a0,26
    8000632a:	050e                	slli	a0,a0,0x3
    8000632c:	9526                	add	a0,a0,s1
    8000632e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006332:	fd043503          	ld	a0,-48(s0)
    80006336:	fffff097          	auipc	ra,0xfffff
    8000633a:	a3e080e7          	jalr	-1474(ra) # 80004d74 <fileclose>
    fileclose(wf);
    8000633e:	fc843503          	ld	a0,-56(s0)
    80006342:	fffff097          	auipc	ra,0xfffff
    80006346:	a32080e7          	jalr	-1486(ra) # 80004d74 <fileclose>
    return -1;
    8000634a:	57fd                	li	a5,-1
    8000634c:	a805                	j	8000637c <sys_pipe+0x104>
    if (fd0 >= 0)
    8000634e:	fc442783          	lw	a5,-60(s0)
    80006352:	0007c863          	bltz	a5,80006362 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006356:	01a78513          	addi	a0,a5,26
    8000635a:	050e                	slli	a0,a0,0x3
    8000635c:	9526                	add	a0,a0,s1
    8000635e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006362:	fd043503          	ld	a0,-48(s0)
    80006366:	fffff097          	auipc	ra,0xfffff
    8000636a:	a0e080e7          	jalr	-1522(ra) # 80004d74 <fileclose>
    fileclose(wf);
    8000636e:	fc843503          	ld	a0,-56(s0)
    80006372:	fffff097          	auipc	ra,0xfffff
    80006376:	a02080e7          	jalr	-1534(ra) # 80004d74 <fileclose>
    return -1;
    8000637a:	57fd                	li	a5,-1
}
    8000637c:	853e                	mv	a0,a5
    8000637e:	70e2                	ld	ra,56(sp)
    80006380:	7442                	ld	s0,48(sp)
    80006382:	74a2                	ld	s1,40(sp)
    80006384:	6121                	addi	sp,sp,64
    80006386:	8082                	ret
	...

0000000080006390 <kernelvec>:
    80006390:	7111                	addi	sp,sp,-256
    80006392:	e006                	sd	ra,0(sp)
    80006394:	e40a                	sd	sp,8(sp)
    80006396:	e80e                	sd	gp,16(sp)
    80006398:	ec12                	sd	tp,24(sp)
    8000639a:	f016                	sd	t0,32(sp)
    8000639c:	f41a                	sd	t1,40(sp)
    8000639e:	f81e                	sd	t2,48(sp)
    800063a0:	fc22                	sd	s0,56(sp)
    800063a2:	e0a6                	sd	s1,64(sp)
    800063a4:	e4aa                	sd	a0,72(sp)
    800063a6:	e8ae                	sd	a1,80(sp)
    800063a8:	ecb2                	sd	a2,88(sp)
    800063aa:	f0b6                	sd	a3,96(sp)
    800063ac:	f4ba                	sd	a4,104(sp)
    800063ae:	f8be                	sd	a5,112(sp)
    800063b0:	fcc2                	sd	a6,120(sp)
    800063b2:	e146                	sd	a7,128(sp)
    800063b4:	e54a                	sd	s2,136(sp)
    800063b6:	e94e                	sd	s3,144(sp)
    800063b8:	ed52                	sd	s4,152(sp)
    800063ba:	f156                	sd	s5,160(sp)
    800063bc:	f55a                	sd	s6,168(sp)
    800063be:	f95e                	sd	s7,176(sp)
    800063c0:	fd62                	sd	s8,184(sp)
    800063c2:	e1e6                	sd	s9,192(sp)
    800063c4:	e5ea                	sd	s10,200(sp)
    800063c6:	e9ee                	sd	s11,208(sp)
    800063c8:	edf2                	sd	t3,216(sp)
    800063ca:	f1f6                	sd	t4,224(sp)
    800063cc:	f5fa                	sd	t5,232(sp)
    800063ce:	f9fe                	sd	t6,240(sp)
    800063d0:	b27fc0ef          	jal	ra,80002ef6 <kerneltrap>
    800063d4:	6082                	ld	ra,0(sp)
    800063d6:	6122                	ld	sp,8(sp)
    800063d8:	61c2                	ld	gp,16(sp)
    800063da:	7282                	ld	t0,32(sp)
    800063dc:	7322                	ld	t1,40(sp)
    800063de:	73c2                	ld	t2,48(sp)
    800063e0:	7462                	ld	s0,56(sp)
    800063e2:	6486                	ld	s1,64(sp)
    800063e4:	6526                	ld	a0,72(sp)
    800063e6:	65c6                	ld	a1,80(sp)
    800063e8:	6666                	ld	a2,88(sp)
    800063ea:	7686                	ld	a3,96(sp)
    800063ec:	7726                	ld	a4,104(sp)
    800063ee:	77c6                	ld	a5,112(sp)
    800063f0:	7866                	ld	a6,120(sp)
    800063f2:	688a                	ld	a7,128(sp)
    800063f4:	692a                	ld	s2,136(sp)
    800063f6:	69ca                	ld	s3,144(sp)
    800063f8:	6a6a                	ld	s4,152(sp)
    800063fa:	7a8a                	ld	s5,160(sp)
    800063fc:	7b2a                	ld	s6,168(sp)
    800063fe:	7bca                	ld	s7,176(sp)
    80006400:	7c6a                	ld	s8,184(sp)
    80006402:	6c8e                	ld	s9,192(sp)
    80006404:	6d2e                	ld	s10,200(sp)
    80006406:	6dce                	ld	s11,208(sp)
    80006408:	6e6e                	ld	t3,216(sp)
    8000640a:	7e8e                	ld	t4,224(sp)
    8000640c:	7f2e                	ld	t5,232(sp)
    8000640e:	7fce                	ld	t6,240(sp)
    80006410:	6111                	addi	sp,sp,256
    80006412:	10200073          	sret
    80006416:	00000013          	nop
    8000641a:	00000013          	nop
    8000641e:	0001                	nop

0000000080006420 <timervec>:
    80006420:	34051573          	csrrw	a0,mscratch,a0
    80006424:	e10c                	sd	a1,0(a0)
    80006426:	e510                	sd	a2,8(a0)
    80006428:	e914                	sd	a3,16(a0)
    8000642a:	6d0c                	ld	a1,24(a0)
    8000642c:	7110                	ld	a2,32(a0)
    8000642e:	6194                	ld	a3,0(a1)
    80006430:	96b2                	add	a3,a3,a2
    80006432:	e194                	sd	a3,0(a1)
    80006434:	4589                	li	a1,2
    80006436:	14459073          	csrw	sip,a1
    8000643a:	6914                	ld	a3,16(a0)
    8000643c:	6510                	ld	a2,8(a0)
    8000643e:	610c                	ld	a1,0(a0)
    80006440:	34051573          	csrrw	a0,mscratch,a0
    80006444:	30200073          	mret
	...

000000008000644a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000644a:	1141                	addi	sp,sp,-16
    8000644c:	e422                	sd	s0,8(sp)
    8000644e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006450:	0c0007b7          	lui	a5,0xc000
    80006454:	4705                	li	a4,1
    80006456:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006458:	c3d8                	sw	a4,4(a5)
}
    8000645a:	6422                	ld	s0,8(sp)
    8000645c:	0141                	addi	sp,sp,16
    8000645e:	8082                	ret

0000000080006460 <plicinithart>:

void
plicinithart(void)
{
    80006460:	1141                	addi	sp,sp,-16
    80006462:	e406                	sd	ra,8(sp)
    80006464:	e022                	sd	s0,0(sp)
    80006466:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006468:	ffffb097          	auipc	ra,0xffffb
    8000646c:	73a080e7          	jalr	1850(ra) # 80001ba2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006470:	0085171b          	slliw	a4,a0,0x8
    80006474:	0c0027b7          	lui	a5,0xc002
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	40200713          	li	a4,1026
    8000647e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006482:	00d5151b          	slliw	a0,a0,0xd
    80006486:	0c2017b7          	lui	a5,0xc201
    8000648a:	953e                	add	a0,a0,a5
    8000648c:	00052023          	sw	zero,0(a0)
}
    80006490:	60a2                	ld	ra,8(sp)
    80006492:	6402                	ld	s0,0(sp)
    80006494:	0141                	addi	sp,sp,16
    80006496:	8082                	ret

0000000080006498 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006498:	1141                	addi	sp,sp,-16
    8000649a:	e406                	sd	ra,8(sp)
    8000649c:	e022                	sd	s0,0(sp)
    8000649e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064a0:	ffffb097          	auipc	ra,0xffffb
    800064a4:	702080e7          	jalr	1794(ra) # 80001ba2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064a8:	00d5179b          	slliw	a5,a0,0xd
    800064ac:	0c201537          	lui	a0,0xc201
    800064b0:	953e                	add	a0,a0,a5
  return irq;
}
    800064b2:	4148                	lw	a0,4(a0)
    800064b4:	60a2                	ld	ra,8(sp)
    800064b6:	6402                	ld	s0,0(sp)
    800064b8:	0141                	addi	sp,sp,16
    800064ba:	8082                	ret

00000000800064bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064bc:	1101                	addi	sp,sp,-32
    800064be:	ec06                	sd	ra,24(sp)
    800064c0:	e822                	sd	s0,16(sp)
    800064c2:	e426                	sd	s1,8(sp)
    800064c4:	1000                	addi	s0,sp,32
    800064c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064c8:	ffffb097          	auipc	ra,0xffffb
    800064cc:	6da080e7          	jalr	1754(ra) # 80001ba2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064d0:	00d5151b          	slliw	a0,a0,0xd
    800064d4:	0c2017b7          	lui	a5,0xc201
    800064d8:	97aa                	add	a5,a5,a0
    800064da:	c3c4                	sw	s1,4(a5)
}
    800064dc:	60e2                	ld	ra,24(sp)
    800064de:	6442                	ld	s0,16(sp)
    800064e0:	64a2                	ld	s1,8(sp)
    800064e2:	6105                	addi	sp,sp,32
    800064e4:	8082                	ret

00000000800064e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064e6:	1141                	addi	sp,sp,-16
    800064e8:	e406                	sd	ra,8(sp)
    800064ea:	e022                	sd	s0,0(sp)
    800064ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064ee:	479d                	li	a5,7
    800064f0:	06a7c963          	blt	a5,a0,80006562 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800064f4:	0023e797          	auipc	a5,0x23e
    800064f8:	b0c78793          	addi	a5,a5,-1268 # 80244000 <disk>
    800064fc:	00a78733          	add	a4,a5,a0
    80006500:	6789                	lui	a5,0x2
    80006502:	97ba                	add	a5,a5,a4
    80006504:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006508:	e7ad                	bnez	a5,80006572 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000650a:	00451793          	slli	a5,a0,0x4
    8000650e:	00240717          	auipc	a4,0x240
    80006512:	af270713          	addi	a4,a4,-1294 # 80246000 <disk+0x2000>
    80006516:	6314                	ld	a3,0(a4)
    80006518:	96be                	add	a3,a3,a5
    8000651a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000651e:	6314                	ld	a3,0(a4)
    80006520:	96be                	add	a3,a3,a5
    80006522:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006526:	6314                	ld	a3,0(a4)
    80006528:	96be                	add	a3,a3,a5
    8000652a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000652e:	6318                	ld	a4,0(a4)
    80006530:	97ba                	add	a5,a5,a4
    80006532:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006536:	0023e797          	auipc	a5,0x23e
    8000653a:	aca78793          	addi	a5,a5,-1334 # 80244000 <disk>
    8000653e:	97aa                	add	a5,a5,a0
    80006540:	6509                	lui	a0,0x2
    80006542:	953e                	add	a0,a0,a5
    80006544:	4785                	li	a5,1
    80006546:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000654a:	00240517          	auipc	a0,0x240
    8000654e:	ace50513          	addi	a0,a0,-1330 # 80246018 <disk+0x2018>
    80006552:	ffffc097          	auipc	ra,0xffffc
    80006556:	124080e7          	jalr	292(ra) # 80002676 <wakeup>
}
    8000655a:	60a2                	ld	ra,8(sp)
    8000655c:	6402                	ld	s0,0(sp)
    8000655e:	0141                	addi	sp,sp,16
    80006560:	8082                	ret
    panic("free_desc 1");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	4ee50513          	addi	a0,a0,1262 # 80008a50 <sysparameters+0x2d8>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	4ee50513          	addi	a0,a0,1262 # 80008a60 <sysparameters+0x2e8>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>

0000000080006582 <virtio_disk_init>:
{
    80006582:	1101                	addi	sp,sp,-32
    80006584:	ec06                	sd	ra,24(sp)
    80006586:	e822                	sd	s0,16(sp)
    80006588:	e426                	sd	s1,8(sp)
    8000658a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000658c:	00002597          	auipc	a1,0x2
    80006590:	4e458593          	addi	a1,a1,1252 # 80008a70 <sysparameters+0x2f8>
    80006594:	00240517          	auipc	a0,0x240
    80006598:	b9450513          	addi	a0,a0,-1132 # 80246128 <disk+0x2128>
    8000659c:	ffffa097          	auipc	ra,0xffffa
    800065a0:	792080e7          	jalr	1938(ra) # 80000d2e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065a4:	100017b7          	lui	a5,0x10001
    800065a8:	4398                	lw	a4,0(a5)
    800065aa:	2701                	sext.w	a4,a4
    800065ac:	747277b7          	lui	a5,0x74727
    800065b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065b4:	0ef71163          	bne	a4,a5,80006696 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065b8:	100017b7          	lui	a5,0x10001
    800065bc:	43dc                	lw	a5,4(a5)
    800065be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065c0:	4705                	li	a4,1
    800065c2:	0ce79a63          	bne	a5,a4,80006696 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065c6:	100017b7          	lui	a5,0x10001
    800065ca:	479c                	lw	a5,8(a5)
    800065cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065ce:	4709                	li	a4,2
    800065d0:	0ce79363          	bne	a5,a4,80006696 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065d4:	100017b7          	lui	a5,0x10001
    800065d8:	47d8                	lw	a4,12(a5)
    800065da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065dc:	554d47b7          	lui	a5,0x554d4
    800065e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065e4:	0af71963          	bne	a4,a5,80006696 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e8:	100017b7          	lui	a5,0x10001
    800065ec:	4705                	li	a4,1
    800065ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f0:	470d                	li	a4,3
    800065f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800065f6:	c7ffe737          	lui	a4,0xc7ffe
    800065fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db775f>
    800065fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006600:	2701                	sext.w	a4,a4
    80006602:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006604:	472d                	li	a4,11
    80006606:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006608:	473d                	li	a4,15
    8000660a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000660c:	6705                	lui	a4,0x1
    8000660e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006610:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006614:	5bdc                	lw	a5,52(a5)
    80006616:	2781                	sext.w	a5,a5
  if(max == 0)
    80006618:	c7d9                	beqz	a5,800066a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000661a:	471d                	li	a4,7
    8000661c:	08f77d63          	bgeu	a4,a5,800066b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006620:	100014b7          	lui	s1,0x10001
    80006624:	47a1                	li	a5,8
    80006626:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006628:	6609                	lui	a2,0x2
    8000662a:	4581                	li	a1,0
    8000662c:	0023e517          	auipc	a0,0x23e
    80006630:	9d450513          	addi	a0,a0,-1580 # 80244000 <disk>
    80006634:	ffffb097          	auipc	ra,0xffffb
    80006638:	886080e7          	jalr	-1914(ra) # 80000eba <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000663c:	0023e717          	auipc	a4,0x23e
    80006640:	9c470713          	addi	a4,a4,-1596 # 80244000 <disk>
    80006644:	00c75793          	srli	a5,a4,0xc
    80006648:	2781                	sext.w	a5,a5
    8000664a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000664c:	00240797          	auipc	a5,0x240
    80006650:	9b478793          	addi	a5,a5,-1612 # 80246000 <disk+0x2000>
    80006654:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006656:	0023e717          	auipc	a4,0x23e
    8000665a:	a2a70713          	addi	a4,a4,-1494 # 80244080 <disk+0x80>
    8000665e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006660:	0023f717          	auipc	a4,0x23f
    80006664:	9a070713          	addi	a4,a4,-1632 # 80245000 <disk+0x1000>
    80006668:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000666a:	4705                	li	a4,1
    8000666c:	00e78c23          	sb	a4,24(a5)
    80006670:	00e78ca3          	sb	a4,25(a5)
    80006674:	00e78d23          	sb	a4,26(a5)
    80006678:	00e78da3          	sb	a4,27(a5)
    8000667c:	00e78e23          	sb	a4,28(a5)
    80006680:	00e78ea3          	sb	a4,29(a5)
    80006684:	00e78f23          	sb	a4,30(a5)
    80006688:	00e78fa3          	sb	a4,31(a5)
}
    8000668c:	60e2                	ld	ra,24(sp)
    8000668e:	6442                	ld	s0,16(sp)
    80006690:	64a2                	ld	s1,8(sp)
    80006692:	6105                	addi	sp,sp,32
    80006694:	8082                	ret
    panic("could not find virtio disk");
    80006696:	00002517          	auipc	a0,0x2
    8000669a:	3ea50513          	addi	a0,a0,1002 # 80008a80 <sysparameters+0x308>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800066a6:	00002517          	auipc	a0,0x2
    800066aa:	3fa50513          	addi	a0,a0,1018 # 80008aa0 <sysparameters+0x328>
    800066ae:	ffffa097          	auipc	ra,0xffffa
    800066b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800066b6:	00002517          	auipc	a0,0x2
    800066ba:	40a50513          	addi	a0,a0,1034 # 80008ac0 <sysparameters+0x348>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	e80080e7          	jalr	-384(ra) # 8000053e <panic>

00000000800066c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066c6:	7159                	addi	sp,sp,-112
    800066c8:	f486                	sd	ra,104(sp)
    800066ca:	f0a2                	sd	s0,96(sp)
    800066cc:	eca6                	sd	s1,88(sp)
    800066ce:	e8ca                	sd	s2,80(sp)
    800066d0:	e4ce                	sd	s3,72(sp)
    800066d2:	e0d2                	sd	s4,64(sp)
    800066d4:	fc56                	sd	s5,56(sp)
    800066d6:	f85a                	sd	s6,48(sp)
    800066d8:	f45e                	sd	s7,40(sp)
    800066da:	f062                	sd	s8,32(sp)
    800066dc:	ec66                	sd	s9,24(sp)
    800066de:	e86a                	sd	s10,16(sp)
    800066e0:	1880                	addi	s0,sp,112
    800066e2:	892a                	mv	s2,a0
    800066e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066e6:	00c52c83          	lw	s9,12(a0)
    800066ea:	001c9c9b          	slliw	s9,s9,0x1
    800066ee:	1c82                	slli	s9,s9,0x20
    800066f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066f4:	00240517          	auipc	a0,0x240
    800066f8:	a3450513          	addi	a0,a0,-1484 # 80246128 <disk+0x2128>
    800066fc:	ffffa097          	auipc	ra,0xffffa
    80006700:	6c2080e7          	jalr	1730(ra) # 80000dbe <acquire>
  for(int i = 0; i < 3; i++){
    80006704:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006706:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006708:	0023eb97          	auipc	s7,0x23e
    8000670c:	8f8b8b93          	addi	s7,s7,-1800 # 80244000 <disk>
    80006710:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006712:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006714:	8a4e                	mv	s4,s3
    80006716:	a051                	j	8000679a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006718:	00fb86b3          	add	a3,s7,a5
    8000671c:	96da                	add	a3,a3,s6
    8000671e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006722:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006724:	0207c563          	bltz	a5,8000674e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006728:	2485                	addiw	s1,s1,1
    8000672a:	0711                	addi	a4,a4,4
    8000672c:	25548063          	beq	s1,s5,8000696c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006730:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006732:	00240697          	auipc	a3,0x240
    80006736:	8e668693          	addi	a3,a3,-1818 # 80246018 <disk+0x2018>
    8000673a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000673c:	0006c583          	lbu	a1,0(a3)
    80006740:	fde1                	bnez	a1,80006718 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006742:	2785                	addiw	a5,a5,1
    80006744:	0685                	addi	a3,a3,1
    80006746:	ff879be3          	bne	a5,s8,8000673c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000674a:	57fd                	li	a5,-1
    8000674c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000674e:	02905a63          	blez	s1,80006782 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006752:	f9042503          	lw	a0,-112(s0)
    80006756:	00000097          	auipc	ra,0x0
    8000675a:	d90080e7          	jalr	-624(ra) # 800064e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000675e:	4785                	li	a5,1
    80006760:	0297d163          	bge	a5,s1,80006782 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006764:	f9442503          	lw	a0,-108(s0)
    80006768:	00000097          	auipc	ra,0x0
    8000676c:	d7e080e7          	jalr	-642(ra) # 800064e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006770:	4789                	li	a5,2
    80006772:	0097d863          	bge	a5,s1,80006782 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006776:	f9842503          	lw	a0,-104(s0)
    8000677a:	00000097          	auipc	ra,0x0
    8000677e:	d6c080e7          	jalr	-660(ra) # 800064e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006782:	00240597          	auipc	a1,0x240
    80006786:	9a658593          	addi	a1,a1,-1626 # 80246128 <disk+0x2128>
    8000678a:	00240517          	auipc	a0,0x240
    8000678e:	88e50513          	addi	a0,a0,-1906 # 80246018 <disk+0x2018>
    80006792:	ffffc097          	auipc	ra,0xffffc
    80006796:	c0c080e7          	jalr	-1012(ra) # 8000239e <sleep>
  for(int i = 0; i < 3; i++){
    8000679a:	f9040713          	addi	a4,s0,-112
    8000679e:	84ce                	mv	s1,s3
    800067a0:	bf41                	j	80006730 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800067a2:	20058713          	addi	a4,a1,512
    800067a6:	00471693          	slli	a3,a4,0x4
    800067aa:	0023e717          	auipc	a4,0x23e
    800067ae:	85670713          	addi	a4,a4,-1962 # 80244000 <disk>
    800067b2:	9736                	add	a4,a4,a3
    800067b4:	4685                	li	a3,1
    800067b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067ba:	20058713          	addi	a4,a1,512
    800067be:	00471693          	slli	a3,a4,0x4
    800067c2:	0023e717          	auipc	a4,0x23e
    800067c6:	83e70713          	addi	a4,a4,-1986 # 80244000 <disk>
    800067ca:	9736                	add	a4,a4,a3
    800067cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800067d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067d4:	7679                	lui	a2,0xffffe
    800067d6:	963e                	add	a2,a2,a5
    800067d8:	00240697          	auipc	a3,0x240
    800067dc:	82868693          	addi	a3,a3,-2008 # 80246000 <disk+0x2000>
    800067e0:	6298                	ld	a4,0(a3)
    800067e2:	9732                	add	a4,a4,a2
    800067e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067e6:	6298                	ld	a4,0(a3)
    800067e8:	9732                	add	a4,a4,a2
    800067ea:	4541                	li	a0,16
    800067ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067ee:	6298                	ld	a4,0(a3)
    800067f0:	9732                	add	a4,a4,a2
    800067f2:	4505                	li	a0,1
    800067f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800067f8:	f9442703          	lw	a4,-108(s0)
    800067fc:	6288                	ld	a0,0(a3)
    800067fe:	962a                	add	a2,a2,a0
    80006800:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7fdb700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006804:	0712                	slli	a4,a4,0x4
    80006806:	6290                	ld	a2,0(a3)
    80006808:	963a                	add	a2,a2,a4
    8000680a:	05890513          	addi	a0,s2,88
    8000680e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006810:	6294                	ld	a3,0(a3)
    80006812:	96ba                	add	a3,a3,a4
    80006814:	40000613          	li	a2,1024
    80006818:	c690                	sw	a2,8(a3)
  if(write)
    8000681a:	140d0063          	beqz	s10,8000695a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000681e:	0023f697          	auipc	a3,0x23f
    80006822:	7e26b683          	ld	a3,2018(a3) # 80246000 <disk+0x2000>
    80006826:	96ba                	add	a3,a3,a4
    80006828:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000682c:	0023d817          	auipc	a6,0x23d
    80006830:	7d480813          	addi	a6,a6,2004 # 80244000 <disk>
    80006834:	0023f517          	auipc	a0,0x23f
    80006838:	7cc50513          	addi	a0,a0,1996 # 80246000 <disk+0x2000>
    8000683c:	6114                	ld	a3,0(a0)
    8000683e:	96ba                	add	a3,a3,a4
    80006840:	00c6d603          	lhu	a2,12(a3)
    80006844:	00166613          	ori	a2,a2,1
    80006848:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000684c:	f9842683          	lw	a3,-104(s0)
    80006850:	6110                	ld	a2,0(a0)
    80006852:	9732                	add	a4,a4,a2
    80006854:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006858:	20058613          	addi	a2,a1,512
    8000685c:	0612                	slli	a2,a2,0x4
    8000685e:	9642                	add	a2,a2,a6
    80006860:	577d                	li	a4,-1
    80006862:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006866:	00469713          	slli	a4,a3,0x4
    8000686a:	6114                	ld	a3,0(a0)
    8000686c:	96ba                	add	a3,a3,a4
    8000686e:	03078793          	addi	a5,a5,48
    80006872:	97c2                	add	a5,a5,a6
    80006874:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006876:	611c                	ld	a5,0(a0)
    80006878:	97ba                	add	a5,a5,a4
    8000687a:	4685                	li	a3,1
    8000687c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000687e:	611c                	ld	a5,0(a0)
    80006880:	97ba                	add	a5,a5,a4
    80006882:	4809                	li	a6,2
    80006884:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006888:	611c                	ld	a5,0(a0)
    8000688a:	973e                	add	a4,a4,a5
    8000688c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006890:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006894:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006898:	6518                	ld	a4,8(a0)
    8000689a:	00275783          	lhu	a5,2(a4)
    8000689e:	8b9d                	andi	a5,a5,7
    800068a0:	0786                	slli	a5,a5,0x1
    800068a2:	97ba                	add	a5,a5,a4
    800068a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800068a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068ac:	6518                	ld	a4,8(a0)
    800068ae:	00275783          	lhu	a5,2(a4)
    800068b2:	2785                	addiw	a5,a5,1
    800068b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068bc:	100017b7          	lui	a5,0x10001
    800068c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068c4:	00492703          	lw	a4,4(s2)
    800068c8:	4785                	li	a5,1
    800068ca:	02f71163          	bne	a4,a5,800068ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800068ce:	00240997          	auipc	s3,0x240
    800068d2:	85a98993          	addi	s3,s3,-1958 # 80246128 <disk+0x2128>
  while(b->disk == 1) {
    800068d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068d8:	85ce                	mv	a1,s3
    800068da:	854a                	mv	a0,s2
    800068dc:	ffffc097          	auipc	ra,0xffffc
    800068e0:	ac2080e7          	jalr	-1342(ra) # 8000239e <sleep>
  while(b->disk == 1) {
    800068e4:	00492783          	lw	a5,4(s2)
    800068e8:	fe9788e3          	beq	a5,s1,800068d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800068ec:	f9042903          	lw	s2,-112(s0)
    800068f0:	20090793          	addi	a5,s2,512
    800068f4:	00479713          	slli	a4,a5,0x4
    800068f8:	0023d797          	auipc	a5,0x23d
    800068fc:	70878793          	addi	a5,a5,1800 # 80244000 <disk>
    80006900:	97ba                	add	a5,a5,a4
    80006902:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006906:	0023f997          	auipc	s3,0x23f
    8000690a:	6fa98993          	addi	s3,s3,1786 # 80246000 <disk+0x2000>
    8000690e:	00491713          	slli	a4,s2,0x4
    80006912:	0009b783          	ld	a5,0(s3)
    80006916:	97ba                	add	a5,a5,a4
    80006918:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000691c:	854a                	mv	a0,s2
    8000691e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006922:	00000097          	auipc	ra,0x0
    80006926:	bc4080e7          	jalr	-1084(ra) # 800064e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000692a:	8885                	andi	s1,s1,1
    8000692c:	f0ed                	bnez	s1,8000690e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000692e:	0023f517          	auipc	a0,0x23f
    80006932:	7fa50513          	addi	a0,a0,2042 # 80246128 <disk+0x2128>
    80006936:	ffffa097          	auipc	ra,0xffffa
    8000693a:	53c080e7          	jalr	1340(ra) # 80000e72 <release>
}
    8000693e:	70a6                	ld	ra,104(sp)
    80006940:	7406                	ld	s0,96(sp)
    80006942:	64e6                	ld	s1,88(sp)
    80006944:	6946                	ld	s2,80(sp)
    80006946:	69a6                	ld	s3,72(sp)
    80006948:	6a06                	ld	s4,64(sp)
    8000694a:	7ae2                	ld	s5,56(sp)
    8000694c:	7b42                	ld	s6,48(sp)
    8000694e:	7ba2                	ld	s7,40(sp)
    80006950:	7c02                	ld	s8,32(sp)
    80006952:	6ce2                	ld	s9,24(sp)
    80006954:	6d42                	ld	s10,16(sp)
    80006956:	6165                	addi	sp,sp,112
    80006958:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000695a:	0023f697          	auipc	a3,0x23f
    8000695e:	6a66b683          	ld	a3,1702(a3) # 80246000 <disk+0x2000>
    80006962:	96ba                	add	a3,a3,a4
    80006964:	4609                	li	a2,2
    80006966:	00c69623          	sh	a2,12(a3)
    8000696a:	b5c9                	j	8000682c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000696c:	f9042583          	lw	a1,-112(s0)
    80006970:	20058793          	addi	a5,a1,512
    80006974:	0792                	slli	a5,a5,0x4
    80006976:	0023d517          	auipc	a0,0x23d
    8000697a:	73250513          	addi	a0,a0,1842 # 802440a8 <disk+0xa8>
    8000697e:	953e                	add	a0,a0,a5
  if(write)
    80006980:	e20d11e3          	bnez	s10,800067a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006984:	20058713          	addi	a4,a1,512
    80006988:	00471693          	slli	a3,a4,0x4
    8000698c:	0023d717          	auipc	a4,0x23d
    80006990:	67470713          	addi	a4,a4,1652 # 80244000 <disk>
    80006994:	9736                	add	a4,a4,a3
    80006996:	0a072423          	sw	zero,168(a4)
    8000699a:	b505                	j	800067ba <virtio_disk_rw+0xf4>

000000008000699c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000699c:	1101                	addi	sp,sp,-32
    8000699e:	ec06                	sd	ra,24(sp)
    800069a0:	e822                	sd	s0,16(sp)
    800069a2:	e426                	sd	s1,8(sp)
    800069a4:	e04a                	sd	s2,0(sp)
    800069a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069a8:	0023f517          	auipc	a0,0x23f
    800069ac:	78050513          	addi	a0,a0,1920 # 80246128 <disk+0x2128>
    800069b0:	ffffa097          	auipc	ra,0xffffa
    800069b4:	40e080e7          	jalr	1038(ra) # 80000dbe <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069b8:	10001737          	lui	a4,0x10001
    800069bc:	533c                	lw	a5,96(a4)
    800069be:	8b8d                	andi	a5,a5,3
    800069c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069c6:	0023f797          	auipc	a5,0x23f
    800069ca:	63a78793          	addi	a5,a5,1594 # 80246000 <disk+0x2000>
    800069ce:	6b94                	ld	a3,16(a5)
    800069d0:	0207d703          	lhu	a4,32(a5)
    800069d4:	0026d783          	lhu	a5,2(a3)
    800069d8:	06f70163          	beq	a4,a5,80006a3a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069dc:	0023d917          	auipc	s2,0x23d
    800069e0:	62490913          	addi	s2,s2,1572 # 80244000 <disk>
    800069e4:	0023f497          	auipc	s1,0x23f
    800069e8:	61c48493          	addi	s1,s1,1564 # 80246000 <disk+0x2000>
    __sync_synchronize();
    800069ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069f0:	6898                	ld	a4,16(s1)
    800069f2:	0204d783          	lhu	a5,32(s1)
    800069f6:	8b9d                	andi	a5,a5,7
    800069f8:	078e                	slli	a5,a5,0x3
    800069fa:	97ba                	add	a5,a5,a4
    800069fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069fe:	20078713          	addi	a4,a5,512
    80006a02:	0712                	slli	a4,a4,0x4
    80006a04:	974a                	add	a4,a4,s2
    80006a06:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a0a:	e731                	bnez	a4,80006a56 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a0c:	20078793          	addi	a5,a5,512
    80006a10:	0792                	slli	a5,a5,0x4
    80006a12:	97ca                	add	a5,a5,s2
    80006a14:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a16:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a1a:	ffffc097          	auipc	ra,0xffffc
    80006a1e:	c5c080e7          	jalr	-932(ra) # 80002676 <wakeup>

    disk.used_idx += 1;
    80006a22:	0204d783          	lhu	a5,32(s1)
    80006a26:	2785                	addiw	a5,a5,1
    80006a28:	17c2                	slli	a5,a5,0x30
    80006a2a:	93c1                	srli	a5,a5,0x30
    80006a2c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a30:	6898                	ld	a4,16(s1)
    80006a32:	00275703          	lhu	a4,2(a4)
    80006a36:	faf71be3          	bne	a4,a5,800069ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a3a:	0023f517          	auipc	a0,0x23f
    80006a3e:	6ee50513          	addi	a0,a0,1774 # 80246128 <disk+0x2128>
    80006a42:	ffffa097          	auipc	ra,0xffffa
    80006a46:	430080e7          	jalr	1072(ra) # 80000e72 <release>
}
    80006a4a:	60e2                	ld	ra,24(sp)
    80006a4c:	6442                	ld	s0,16(sp)
    80006a4e:	64a2                	ld	s1,8(sp)
    80006a50:	6902                	ld	s2,0(sp)
    80006a52:	6105                	addi	sp,sp,32
    80006a54:	8082                	ret
      panic("virtio_disk_intr status");
    80006a56:	00002517          	auipc	a0,0x2
    80006a5a:	08a50513          	addi	a0,a0,138 # 80008ae0 <sysparameters+0x368>
    80006a5e:	ffffa097          	auipc	ra,0xffffa
    80006a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
