
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	b3c78793          	addi	a5,a5,-1220 # 80005ba0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    80000130:	37e080e7          	jalr	894(ra) # 800024aa <either_copyin>
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
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
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
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e7e080e7          	jalr	-386(ra) # 80002052 <sleep>
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
    80000214:	244080e7          	jalr	580(ra) # 80002454 <either_copyout>
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
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
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
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	20e080e7          	jalr	526(ra) # 80002500 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    8000044a:	d98080e7          	jalr	-616(ra) # 800021de <wakeup>
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
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
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
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
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
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
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
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
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
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

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
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
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
    800008a4:	93e080e7          	jalr	-1730(ra) # 800021de <wakeup>
    
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
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
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
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	726080e7          	jalr	1830(ra) # 80002052 <sleep>
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
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
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
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    80000cf6:	00b78023          	sb	a1,0(a5)
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
    80000d32:	40e7853b          	subw	a0,a5,a4
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    80000d7e:	96aa                	add	a3,a3,a0
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    80000e5a:	00078023          	sb	zero,0(a5)
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	76c080e7          	jalr	1900(ra) # 80002640 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	d04080e7          	jalr	-764(ra) # 80005be0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fbc080e7          	jalr	-68(ra) # 80001ea0 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	6cc080e7          	jalr	1740(ra) # 80002618 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	6ec080e7          	jalr	1772(ra) # 80002640 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	c6e080e7          	jalr	-914(ra) # 80005bca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	c7c080e7          	jalr	-900(ra) # 80005be0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	e60080e7          	jalr	-416(ra) # 80002dcc <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	4f0080e7          	jalr	1264(ra) # 80003464 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	49a080e7          	jalr	1178(ra) # 80004416 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	d7e080e7          	jalr	-642(ra) # 80005d02 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e107a783          	lw	a5,-496(a5) # 80008810 <first.1676>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	c4e080e7          	jalr	-946(ra) # 80002658 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	de07ab23          	sw	zero,-522(a5) # 80008810 <first.1676>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	9c0080e7          	jalr	-1600(ra) # 800033e4 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	dc878793          	addi	a5,a5,-568 # 80008814 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	50290913          	addi	s2,s2,1282 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	b7858593          	addi	a1,a1,-1160 # 80008820 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	12c080e7          	jalr	300(ra) # 80003e12 <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d24:	01204c63          	bgtz	s2,80001d3c <growproc+0x32>
  } else if(n < 0){
    80001d28:	02094563          	bltz	s2,80001d52 <growproc+0x48>
  p->sz = sz;
    80001d2c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2e:	4501                	li	a0,0
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6902                	ld	s2,0(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d3c:	00b90633          	add	a2,s2,a1
    80001d40:	6928                	ld	a0,80(a0)
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	6e0080e7          	jalr	1760(ra) # 80001422 <uvmalloc>
    80001d4a:	85aa                	mv	a1,a0
    80001d4c:	f165                	bnez	a0,80001d2c <growproc+0x22>
      return -1;
    80001d4e:	557d                	li	a0,-1
    80001d50:	b7c5                	j	80001d30 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d52:	00b90633          	add	a2,s2,a1
    80001d56:	6928                	ld	a0,80(a0)
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	682080e7          	jalr	1666(ra) # 800013da <uvmdealloc>
    80001d60:	85aa                	mv	a1,a0
    80001d62:	b7e9                	j	80001d2c <growproc+0x22>

0000000080001d64 <fork>:
{
    80001d64:	7179                	addi	sp,sp,-48
    80001d66:	f406                	sd	ra,40(sp)
    80001d68:	f022                	sd	s0,32(sp)
    80001d6a:	ec26                	sd	s1,24(sp)
    80001d6c:	e84a                	sd	s2,16(sp)
    80001d6e:	e44e                	sd	s3,8(sp)
    80001d70:	e052                	sd	s4,0(sp)
    80001d72:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c3c080e7          	jalr	-964(ra) # 800019b0 <myproc>
    80001d7c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e3c080e7          	jalr	-452(ra) # 80001bba <allocproc>
    80001d86:	10050b63          	beqz	a0,80001e9c <fork+0x138>
    80001d8a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	04893603          	ld	a2,72(s2)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	05093503          	ld	a0,80(s2)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d8080e7          	jalr	2008(ra) # 8000156e <uvmcopy>
    80001d9e:	04054663          	bltz	a0,80001dea <fork+0x86>
  np->sz = p->sz;
    80001da2:	04893783          	ld	a5,72(s2)
    80001da6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	05893683          	ld	a3,88(s2)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	0589b703          	ld	a4,88(s3)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x54>
  np->trapframe->a0 = 0;
    80001dd8:	0589b783          	ld	a5,88(s3)
    80001ddc:	0607b823          	sd	zero,112(a5)
    80001de0:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001de4:	15000a13          	li	s4,336
    80001de8:	a03d                	j	80001e16 <fork+0xb2>
    freeproc(np);
    80001dea:	854e                	mv	a0,s3
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	d76080e7          	jalr	-650(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001df4:	854e                	mv	a0,s3
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	ea2080e7          	jalr	-350(ra) # 80000c98 <release>
    return -1;
    80001dfe:	5a7d                	li	s4,-1
    80001e00:	a069                	j	80001e8a <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e02:	00002097          	auipc	ra,0x2
    80001e06:	6a6080e7          	jalr	1702(ra) # 800044a8 <filedup>
    80001e0a:	009987b3          	add	a5,s3,s1
    80001e0e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e10:	04a1                	addi	s1,s1,8
    80001e12:	01448763          	beq	s1,s4,80001e20 <fork+0xbc>
    if(p->ofile[i])
    80001e16:	009907b3          	add	a5,s2,s1
    80001e1a:	6388                	ld	a0,0(a5)
    80001e1c:	f17d                	bnez	a0,80001e02 <fork+0x9e>
    80001e1e:	bfcd                	j	80001e10 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e20:	15093503          	ld	a0,336(s2)
    80001e24:	00001097          	auipc	ra,0x1
    80001e28:	7fa080e7          	jalr	2042(ra) # 8000361e <idup>
    80001e2c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	15890593          	addi	a1,s2,344
    80001e36:	15898513          	addi	a0,s3,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	ff8080e7          	jalr	-8(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e42:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e46:	854e                	mv	a0,s3
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	46848493          	addi	s1,s1,1128 # 800112b8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d8a080e7          	jalr	-630(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e62:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e30080e7          	jalr	-464(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e70:	854e                	mv	a0,s3
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d72080e7          	jalr	-654(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e80:	854e                	mv	a0,s3
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
}
    80001e8a:	8552                	mv	a0,s4
    80001e8c:	70a2                	ld	ra,40(sp)
    80001e8e:	7402                	ld	s0,32(sp)
    80001e90:	64e2                	ld	s1,24(sp)
    80001e92:	6942                	ld	s2,16(sp)
    80001e94:	69a2                	ld	s3,8(sp)
    80001e96:	6a02                	ld	s4,0(sp)
    80001e98:	6145                	addi	sp,sp,48
    80001e9a:	8082                	ret
    return -1;
    80001e9c:	5a7d                	li	s4,-1
    80001e9e:	b7f5                	j	80001e8a <fork+0x126>

0000000080001ea0 <scheduler>:
{
    80001ea0:	7139                	addi	sp,sp,-64
    80001ea2:	fc06                	sd	ra,56(sp)
    80001ea4:	f822                	sd	s0,48(sp)
    80001ea6:	f426                	sd	s1,40(sp)
    80001ea8:	f04a                	sd	s2,32(sp)
    80001eaa:	ec4e                	sd	s3,24(sp)
    80001eac:	e852                	sd	s4,16(sp)
    80001eae:	e456                	sd	s5,8(sp)
    80001eb0:	e05a                	sd	s6,0(sp)
    80001eb2:	0080                	addi	s0,sp,64
    80001eb4:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb8:	00779a93          	slli	s5,a5,0x7
    80001ebc:	0000f717          	auipc	a4,0xf
    80001ec0:	3e470713          	addi	a4,a4,996 # 800112a0 <pid_lock>
    80001ec4:	9756                	add	a4,a4,s5
    80001ec6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eca:	0000f717          	auipc	a4,0xf
    80001ece:	40e70713          	addi	a4,a4,1038 # 800112d8 <cpus+0x8>
    80001ed2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed6:	4b11                	li	s6,4
        c->proc = p;
    80001ed8:	079e                	slli	a5,a5,0x7
    80001eda:	0000fa17          	auipc	s4,0xf
    80001ede:	3c6a0a13          	addi	s4,s4,966 # 800112a0 <pid_lock>
    80001ee2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee4:	00015917          	auipc	s2,0x15
    80001ee8:	1ec90913          	addi	s2,s2,492 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef4:	10079073          	csrw	sstatus,a5
    80001ef8:	0000f497          	auipc	s1,0xf
    80001efc:	7d848493          	addi	s1,s1,2008 # 800116d0 <proc>
    80001f00:	a03d                	j	80001f2e <scheduler+0x8e>
        p->state = RUNNING;
    80001f02:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f06:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f0a:	06048593          	addi	a1,s1,96
    80001f0e:	8556                	mv	a0,s5
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	69e080e7          	jalr	1694(ra) # 800025ae <swtch>
        c->proc = 0;
    80001f18:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d7a080e7          	jalr	-646(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f26:	16848493          	addi	s1,s1,360
    80001f2a:	fd2481e3          	beq	s1,s2,80001eec <scheduler+0x4c>
      acquire(&p->lock);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	cb4080e7          	jalr	-844(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f38:	4c9c                	lw	a5,24(s1)
    80001f3a:	ff3791e3          	bne	a5,s3,80001f1c <scheduler+0x7c>
    80001f3e:	b7d1                	j	80001f02 <scheduler+0x62>

0000000080001f40 <sched>:
{
    80001f40:	7179                	addi	sp,sp,-48
    80001f42:	f406                	sd	ra,40(sp)
    80001f44:	f022                	sd	s0,32(sp)
    80001f46:	ec26                	sd	s1,24(sp)
    80001f48:	e84a                	sd	s2,16(sp)
    80001f4a:	e44e                	sd	s3,8(sp)
    80001f4c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	a62080e7          	jalr	-1438(ra) # 800019b0 <myproc>
    80001f56:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	c12080e7          	jalr	-1006(ra) # 80000b6a <holding>
    80001f60:	c93d                	beqz	a0,80001fd6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f62:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f64:	2781                	sext.w	a5,a5
    80001f66:	079e                	slli	a5,a5,0x7
    80001f68:	0000f717          	auipc	a4,0xf
    80001f6c:	33870713          	addi	a4,a4,824 # 800112a0 <pid_lock>
    80001f70:	97ba                	add	a5,a5,a4
    80001f72:	0a87a703          	lw	a4,168(a5)
    80001f76:	4785                	li	a5,1
    80001f78:	06f71763          	bne	a4,a5,80001fe6 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7c:	4c98                	lw	a4,24(s1)
    80001f7e:	4791                	li	a5,4
    80001f80:	06f70b63          	beq	a4,a5,80001ff6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f88:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8a:	efb5                	bnez	a5,80002006 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f8e:	0000f917          	auipc	s2,0xf
    80001f92:	31290913          	addi	s2,s2,786 # 800112a0 <pid_lock>
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	97ca                	add	a5,a5,s2
    80001f9c:	0ac7a983          	lw	s3,172(a5)
    80001fa0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa2:	2781                	sext.w	a5,a5
    80001fa4:	079e                	slli	a5,a5,0x7
    80001fa6:	0000f597          	auipc	a1,0xf
    80001faa:	33258593          	addi	a1,a1,818 # 800112d8 <cpus+0x8>
    80001fae:	95be                	add	a1,a1,a5
    80001fb0:	06048513          	addi	a0,s1,96
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	5fa080e7          	jalr	1530(ra) # 800025ae <swtch>
    80001fbc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fbe:	2781                	sext.w	a5,a5
    80001fc0:	079e                	slli	a5,a5,0x7
    80001fc2:	97ca                	add	a5,a5,s2
    80001fc4:	0b37a623          	sw	s3,172(a5)
}
    80001fc8:	70a2                	ld	ra,40(sp)
    80001fca:	7402                	ld	s0,32(sp)
    80001fcc:	64e2                	ld	s1,24(sp)
    80001fce:	6942                	ld	s2,16(sp)
    80001fd0:	69a2                	ld	s3,8(sp)
    80001fd2:	6145                	addi	sp,sp,48
    80001fd4:	8082                	ret
    panic("sched p->lock");
    80001fd6:	00006517          	auipc	a0,0x6
    80001fda:	24250513          	addi	a0,a0,578 # 80008218 <digits+0x1d8>
    80001fde:	ffffe097          	auipc	ra,0xffffe
    80001fe2:	560080e7          	jalr	1376(ra) # 8000053e <panic>
    panic("sched locks");
    80001fe6:	00006517          	auipc	a0,0x6
    80001fea:	24250513          	addi	a0,a0,578 # 80008228 <digits+0x1e8>
    80001fee:	ffffe097          	auipc	ra,0xffffe
    80001ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    panic("sched running");
    80001ff6:	00006517          	auipc	a0,0x6
    80001ffa:	24250513          	addi	a0,a0,578 # 80008238 <digits+0x1f8>
    80001ffe:	ffffe097          	auipc	ra,0xffffe
    80002002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002006:	00006517          	auipc	a0,0x6
    8000200a:	24250513          	addi	a0,a0,578 # 80008248 <digits+0x208>
    8000200e:	ffffe097          	auipc	ra,0xffffe
    80002012:	530080e7          	jalr	1328(ra) # 8000053e <panic>

0000000080002016 <yield>:
{
    80002016:	1101                	addi	sp,sp,-32
    80002018:	ec06                	sd	ra,24(sp)
    8000201a:	e822                	sd	s0,16(sp)
    8000201c:	e426                	sd	s1,8(sp)
    8000201e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002020:	00000097          	auipc	ra,0x0
    80002024:	990080e7          	jalr	-1648(ra) # 800019b0 <myproc>
    80002028:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	bba080e7          	jalr	-1094(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002032:	478d                	li	a5,3
    80002034:	cc9c                	sw	a5,24(s1)
  sched();
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	f0a080e7          	jalr	-246(ra) # 80001f40 <sched>
  release(&p->lock);
    8000203e:	8526                	mv	a0,s1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	c58080e7          	jalr	-936(ra) # 80000c98 <release>
}
    80002048:	60e2                	ld	ra,24(sp)
    8000204a:	6442                	ld	s0,16(sp)
    8000204c:	64a2                	ld	s1,8(sp)
    8000204e:	6105                	addi	sp,sp,32
    80002050:	8082                	ret

0000000080002052 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002052:	7179                	addi	sp,sp,-48
    80002054:	f406                	sd	ra,40(sp)
    80002056:	f022                	sd	s0,32(sp)
    80002058:	ec26                	sd	s1,24(sp)
    8000205a:	e84a                	sd	s2,16(sp)
    8000205c:	e44e                	sd	s3,8(sp)
    8000205e:	1800                	addi	s0,sp,48
    80002060:	89aa                	mv	s3,a0
    80002062:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002064:	00000097          	auipc	ra,0x0
    80002068:	94c080e7          	jalr	-1716(ra) # 800019b0 <myproc>
    8000206c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	b76080e7          	jalr	-1162(ra) # 80000be4 <acquire>
  release(lk);
    80002076:	854a                	mv	a0,s2
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c20080e7          	jalr	-992(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002080:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002084:	4789                	li	a5,2
    80002086:	cc9c                	sw	a5,24(s1)

  sched();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	eb8080e7          	jalr	-328(ra) # 80001f40 <sched>

  // Tidy up.
  p->chan = 0;
    80002090:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002094:	8526                	mv	a0,s1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	c02080e7          	jalr	-1022(ra) # 80000c98 <release>
  acquire(lk);
    8000209e:	854a                	mv	a0,s2
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b44080e7          	jalr	-1212(ra) # 80000be4 <acquire>
}
    800020a8:	70a2                	ld	ra,40(sp)
    800020aa:	7402                	ld	s0,32(sp)
    800020ac:	64e2                	ld	s1,24(sp)
    800020ae:	6942                	ld	s2,16(sp)
    800020b0:	69a2                	ld	s3,8(sp)
    800020b2:	6145                	addi	sp,sp,48
    800020b4:	8082                	ret

00000000800020b6 <wait>:
{
    800020b6:	715d                	addi	sp,sp,-80
    800020b8:	e486                	sd	ra,72(sp)
    800020ba:	e0a2                	sd	s0,64(sp)
    800020bc:	fc26                	sd	s1,56(sp)
    800020be:	f84a                	sd	s2,48(sp)
    800020c0:	f44e                	sd	s3,40(sp)
    800020c2:	f052                	sd	s4,32(sp)
    800020c4:	ec56                	sd	s5,24(sp)
    800020c6:	e85a                	sd	s6,16(sp)
    800020c8:	e45e                	sd	s7,8(sp)
    800020ca:	e062                	sd	s8,0(sp)
    800020cc:	0880                	addi	s0,sp,80
    800020ce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	8e0080e7          	jalr	-1824(ra) # 800019b0 <myproc>
    800020d8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020da:	0000f517          	auipc	a0,0xf
    800020de:	1de50513          	addi	a0,a0,478 # 800112b8 <wait_lock>
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
    havekids = 0;
    800020ea:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020ec:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800020ee:	00015997          	auipc	s3,0x15
    800020f2:	fe298993          	addi	s3,s3,-30 # 800170d0 <tickslock>
        havekids = 1;
    800020f6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020f8:	0000fc17          	auipc	s8,0xf
    800020fc:	1c0c0c13          	addi	s8,s8,448 # 800112b8 <wait_lock>
    havekids = 0;
    80002100:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002102:	0000f497          	auipc	s1,0xf
    80002106:	5ce48493          	addi	s1,s1,1486 # 800116d0 <proc>
    8000210a:	a0bd                	j	80002178 <wait+0xc2>
          pid = np->pid;
    8000210c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002110:	000b0e63          	beqz	s6,8000212c <wait+0x76>
    80002114:	4691                	li	a3,4
    80002116:	02c48613          	addi	a2,s1,44
    8000211a:	85da                	mv	a1,s6
    8000211c:	05093503          	ld	a0,80(s2)
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	552080e7          	jalr	1362(ra) # 80001672 <copyout>
    80002128:	02054563          	bltz	a0,80002152 <wait+0x9c>
          freeproc(np);
    8000212c:	8526                	mv	a0,s1
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	a34080e7          	jalr	-1484(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b60080e7          	jalr	-1184(ra) # 80000c98 <release>
          release(&wait_lock);
    80002140:	0000f517          	auipc	a0,0xf
    80002144:	17850513          	addi	a0,a0,376 # 800112b8 <wait_lock>
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
          return pid;
    80002150:	a09d                	j	800021b6 <wait+0x100>
            release(&np->lock);
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	b44080e7          	jalr	-1212(ra) # 80000c98 <release>
            release(&wait_lock);
    8000215c:	0000f517          	auipc	a0,0xf
    80002160:	15c50513          	addi	a0,a0,348 # 800112b8 <wait_lock>
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b34080e7          	jalr	-1228(ra) # 80000c98 <release>
            return -1;
    8000216c:	59fd                	li	s3,-1
    8000216e:	a0a1                	j	800021b6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002170:	16848493          	addi	s1,s1,360
    80002174:	03348463          	beq	s1,s3,8000219c <wait+0xe6>
      if(np->parent == p){
    80002178:	7c9c                	ld	a5,56(s1)
    8000217a:	ff279be3          	bne	a5,s2,80002170 <wait+0xba>
        acquire(&np->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a64080e7          	jalr	-1436(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002188:	4c9c                	lw	a5,24(s1)
    8000218a:	f94781e3          	beq	a5,s4,8000210c <wait+0x56>
        release(&np->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
        havekids = 1;
    80002198:	8756                	mv	a4,s5
    8000219a:	bfd9                	j	80002170 <wait+0xba>
    if(!havekids || p->killed){
    8000219c:	c701                	beqz	a4,800021a4 <wait+0xee>
    8000219e:	02892783          	lw	a5,40(s2)
    800021a2:	c79d                	beqz	a5,800021d0 <wait+0x11a>
      release(&wait_lock);
    800021a4:	0000f517          	auipc	a0,0xf
    800021a8:	11450513          	addi	a0,a0,276 # 800112b8 <wait_lock>
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	aec080e7          	jalr	-1300(ra) # 80000c98 <release>
      return -1;
    800021b4:	59fd                	li	s3,-1
}
    800021b6:	854e                	mv	a0,s3
    800021b8:	60a6                	ld	ra,72(sp)
    800021ba:	6406                	ld	s0,64(sp)
    800021bc:	74e2                	ld	s1,56(sp)
    800021be:	7942                	ld	s2,48(sp)
    800021c0:	79a2                	ld	s3,40(sp)
    800021c2:	7a02                	ld	s4,32(sp)
    800021c4:	6ae2                	ld	s5,24(sp)
    800021c6:	6b42                	ld	s6,16(sp)
    800021c8:	6ba2                	ld	s7,8(sp)
    800021ca:	6c02                	ld	s8,0(sp)
    800021cc:	6161                	addi	sp,sp,80
    800021ce:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d0:	85e2                	mv	a1,s8
    800021d2:	854a                	mv	a0,s2
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	e7e080e7          	jalr	-386(ra) # 80002052 <sleep>
    havekids = 0;
    800021dc:	b715                	j	80002100 <wait+0x4a>

00000000800021de <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021de:	7139                	addi	sp,sp,-64
    800021e0:	fc06                	sd	ra,56(sp)
    800021e2:	f822                	sd	s0,48(sp)
    800021e4:	f426                	sd	s1,40(sp)
    800021e6:	f04a                	sd	s2,32(sp)
    800021e8:	ec4e                	sd	s3,24(sp)
    800021ea:	e852                	sd	s4,16(sp)
    800021ec:	e456                	sd	s5,8(sp)
    800021ee:	0080                	addi	s0,sp,64
    800021f0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f2:	0000f497          	auipc	s1,0xf
    800021f6:	4de48493          	addi	s1,s1,1246 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021fa:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021fc:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021fe:	00015917          	auipc	s2,0x15
    80002202:	ed290913          	addi	s2,s2,-302 # 800170d0 <tickslock>
    80002206:	a821                	j	8000221e <wakeup+0x40>
        p->state = RUNNABLE;
    80002208:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002216:	16848493          	addi	s1,s1,360
    8000221a:	03248463          	beq	s1,s2,80002242 <wakeup+0x64>
    if(p != myproc()){
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	792080e7          	jalr	1938(ra) # 800019b0 <myproc>
    80002226:	fea488e3          	beq	s1,a0,80002216 <wakeup+0x38>
      acquire(&p->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9b8080e7          	jalr	-1608(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002234:	4c9c                	lw	a5,24(s1)
    80002236:	fd379be3          	bne	a5,s3,8000220c <wakeup+0x2e>
    8000223a:	709c                	ld	a5,32(s1)
    8000223c:	fd4798e3          	bne	a5,s4,8000220c <wakeup+0x2e>
    80002240:	b7e1                	j	80002208 <wakeup+0x2a>
    }
  }
}
    80002242:	70e2                	ld	ra,56(sp)
    80002244:	7442                	ld	s0,48(sp)
    80002246:	74a2                	ld	s1,40(sp)
    80002248:	7902                	ld	s2,32(sp)
    8000224a:	69e2                	ld	s3,24(sp)
    8000224c:	6a42                	ld	s4,16(sp)
    8000224e:	6aa2                	ld	s5,8(sp)
    80002250:	6121                	addi	sp,sp,64
    80002252:	8082                	ret

0000000080002254 <reparent>:
{
    80002254:	7179                	addi	sp,sp,-48
    80002256:	f406                	sd	ra,40(sp)
    80002258:	f022                	sd	s0,32(sp)
    8000225a:	ec26                	sd	s1,24(sp)
    8000225c:	e84a                	sd	s2,16(sp)
    8000225e:	e44e                	sd	s3,8(sp)
    80002260:	e052                	sd	s4,0(sp)
    80002262:	1800                	addi	s0,sp,48
    80002264:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002266:	0000f497          	auipc	s1,0xf
    8000226a:	46a48493          	addi	s1,s1,1130 # 800116d0 <proc>
      pp->parent = initproc;
    8000226e:	00007a17          	auipc	s4,0x7
    80002272:	dbaa0a13          	addi	s4,s4,-582 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002276:	00015997          	auipc	s3,0x15
    8000227a:	e5a98993          	addi	s3,s3,-422 # 800170d0 <tickslock>
    8000227e:	a029                	j	80002288 <reparent+0x34>
    80002280:	16848493          	addi	s1,s1,360
    80002284:	01348d63          	beq	s1,s3,8000229e <reparent+0x4a>
    if(pp->parent == p){
    80002288:	7c9c                	ld	a5,56(s1)
    8000228a:	ff279be3          	bne	a5,s2,80002280 <reparent+0x2c>
      pp->parent = initproc;
    8000228e:	000a3503          	ld	a0,0(s4)
    80002292:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002294:	00000097          	auipc	ra,0x0
    80002298:	f4a080e7          	jalr	-182(ra) # 800021de <wakeup>
    8000229c:	b7d5                	j	80002280 <reparent+0x2c>
}
    8000229e:	70a2                	ld	ra,40(sp)
    800022a0:	7402                	ld	s0,32(sp)
    800022a2:	64e2                	ld	s1,24(sp)
    800022a4:	6942                	ld	s2,16(sp)
    800022a6:	69a2                	ld	s3,8(sp)
    800022a8:	6a02                	ld	s4,0(sp)
    800022aa:	6145                	addi	sp,sp,48
    800022ac:	8082                	ret

00000000800022ae <exit>:
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	e052                	sd	s4,0(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	6f0080e7          	jalr	1776(ra) # 800019b0 <myproc>
    800022c8:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ca:	00007797          	auipc	a5,0x7
    800022ce:	d5e7b783          	ld	a5,-674(a5) # 80009028 <initproc>
    800022d2:	0d050493          	addi	s1,a0,208
    800022d6:	15050913          	addi	s2,a0,336
    800022da:	02a79363          	bne	a5,a0,80002300 <exit+0x52>
    panic("init exiting");
    800022de:	00006517          	auipc	a0,0x6
    800022e2:	f8250513          	addi	a0,a0,-126 # 80008260 <digits+0x220>
    800022e6:	ffffe097          	auipc	ra,0xffffe
    800022ea:	258080e7          	jalr	600(ra) # 8000053e <panic>
      fileclose(f);
    800022ee:	00002097          	auipc	ra,0x2
    800022f2:	20c080e7          	jalr	524(ra) # 800044fa <fileclose>
      p->ofile[fd] = 0;
    800022f6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022fa:	04a1                	addi	s1,s1,8
    800022fc:	01248563          	beq	s1,s2,80002306 <exit+0x58>
    if(p->ofile[fd]){
    80002300:	6088                	ld	a0,0(s1)
    80002302:	f575                	bnez	a0,800022ee <exit+0x40>
    80002304:	bfdd                	j	800022fa <exit+0x4c>
  begin_op();
    80002306:	00002097          	auipc	ra,0x2
    8000230a:	d28080e7          	jalr	-728(ra) # 8000402e <begin_op>
  iput(p->cwd);
    8000230e:	1509b503          	ld	a0,336(s3)
    80002312:	00001097          	auipc	ra,0x1
    80002316:	504080e7          	jalr	1284(ra) # 80003816 <iput>
  end_op();
    8000231a:	00002097          	auipc	ra,0x2
    8000231e:	d94080e7          	jalr	-620(ra) # 800040ae <end_op>
  p->cwd = 0;
    80002322:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002326:	0000f497          	auipc	s1,0xf
    8000232a:	f9248493          	addi	s1,s1,-110 # 800112b8 <wait_lock>
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  reparent(p);
    80002338:	854e                	mv	a0,s3
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	f1a080e7          	jalr	-230(ra) # 80002254 <reparent>
  wakeup(p->parent);
    80002342:	0389b503          	ld	a0,56(s3)
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	e98080e7          	jalr	-360(ra) # 800021de <wakeup>
  acquire(&p->lock);
    8000234e:	854e                	mv	a0,s3
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002358:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000235c:	4795                	li	a5,5
    8000235e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
  sched();
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	bd4080e7          	jalr	-1068(ra) # 80001f40 <sched>
  panic("zombie exit");
    80002374:	00006517          	auipc	a0,0x6
    80002378:	efc50513          	addi	a0,a0,-260 # 80008270 <digits+0x230>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>

0000000080002384 <pause_system>:

// Pause all user's processes for specified seconds
int
pause_system(int seconds)
{
    80002384:	1141                	addi	sp,sp,-16
    80002386:	e422                	sd	s0,8(sp)
    80002388:	0800                	addi	s0,sp,16
  return 0;
}
    8000238a:	4501                	li	a0,0
    8000238c:	6422                	ld	s0,8(sp)
    8000238e:	0141                	addi	sp,sp,16
    80002390:	8082                	ret

0000000080002392 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002392:	7179                	addi	sp,sp,-48
    80002394:	f406                	sd	ra,40(sp)
    80002396:	f022                	sd	s0,32(sp)
    80002398:	ec26                	sd	s1,24(sp)
    8000239a:	e84a                	sd	s2,16(sp)
    8000239c:	e44e                	sd	s3,8(sp)
    8000239e:	1800                	addi	s0,sp,48
    800023a0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023a2:	0000f497          	auipc	s1,0xf
    800023a6:	32e48493          	addi	s1,s1,814 # 800116d0 <proc>
    800023aa:	00015997          	auipc	s3,0x15
    800023ae:	d2698993          	addi	s3,s3,-730 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800023bc:	589c                	lw	a5,48(s1)
    800023be:	01278d63          	beq	a5,s2,800023d8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023cc:	16848493          	addi	s1,s1,360
    800023d0:	ff3491e3          	bne	s1,s3,800023b2 <kill+0x20>
  }
  return -1;
    800023d4:	557d                	li	a0,-1
    800023d6:	a829                	j	800023f0 <kill+0x5e>
      p->killed = 1;
    800023d8:	4785                	li	a5,1
    800023da:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023dc:	4c98                	lw	a4,24(s1)
    800023de:	4789                	li	a5,2
    800023e0:	00f70f63          	beq	a4,a5,800023fe <kill+0x6c>
      release(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
      return 0;
    800023ee:	4501                	li	a0,0
}
    800023f0:	70a2                	ld	ra,40(sp)
    800023f2:	7402                	ld	s0,32(sp)
    800023f4:	64e2                	ld	s1,24(sp)
    800023f6:	6942                	ld	s2,16(sp)
    800023f8:	69a2                	ld	s3,8(sp)
    800023fa:	6145                	addi	sp,sp,48
    800023fc:	8082                	ret
        p->state = RUNNABLE;
    800023fe:	478d                	li	a5,3
    80002400:	cc9c                	sw	a5,24(s1)
    80002402:	b7cd                	j	800023e4 <kill+0x52>

0000000080002404 <kill_system>:
{
    80002404:	1101                	addi	sp,sp,-32
    80002406:	ec06                	sd	ra,24(sp)
    80002408:	e822                	sd	s0,16(sp)
    8000240a:	e426                	sd	s1,8(sp)
    8000240c:	e04a                	sd	s2,0(sp)
    8000240e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++){
    80002410:	0000f497          	auipc	s1,0xf
    80002414:	2c048493          	addi	s1,s1,704 # 800116d0 <proc>
    80002418:	00015917          	auipc	s2,0x15
    8000241c:	cb890913          	addi	s2,s2,-840 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7c2080e7          	jalr	1986(ra) # 80000be4 <acquire>
      release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
      kill(p->pid);
    80002434:	5888                	lw	a0,48(s1)
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	f5c080e7          	jalr	-164(ra) # 80002392 <kill>
  for(p = proc; p < &proc[NPROC]; p++){
    8000243e:	16848493          	addi	s1,s1,360
    80002442:	fd249fe3          	bne	s1,s2,80002420 <kill_system+0x1c>
}
    80002446:	557d                	li	a0,-1
    80002448:	60e2                	ld	ra,24(sp)
    8000244a:	6442                	ld	s0,16(sp)
    8000244c:	64a2                	ld	s1,8(sp)
    8000244e:	6902                	ld	s2,0(sp)
    80002450:	6105                	addi	sp,sp,32
    80002452:	8082                	ret

0000000080002454 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	84aa                	mv	s1,a0
    80002466:	892e                	mv	s2,a1
    80002468:	89b2                	mv	s3,a2
    8000246a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	544080e7          	jalr	1348(ra) # 800019b0 <myproc>
  if(user_dst){
    80002474:	c08d                	beqz	s1,80002496 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	1f4080e7          	jalr	500(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6a02                	ld	s4,0(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
    memmove((char *)dst, src, len);
    80002496:	000a061b          	sext.w	a2,s4
    8000249a:	85ce                	mv	a1,s3
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	8a2080e7          	jalr	-1886(ra) # 80000d40 <memmove>
    return 0;
    800024a6:	8526                	mv	a0,s1
    800024a8:	bff9                	j	80002486 <either_copyout+0x32>

00000000800024aa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	892a                	mv	s2,a0
    800024bc:	84ae                	mv	s1,a1
    800024be:	89b2                	mv	s3,a2
    800024c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	4ee080e7          	jalr	1262(ra) # 800019b0 <myproc>
  if(user_src){
    800024ca:	c08d                	beqz	s1,800024ec <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024cc:	86d2                	mv	a3,s4
    800024ce:	864e                	mv	a2,s3
    800024d0:	85ca                	mv	a1,s2
    800024d2:	6928                	ld	a0,80(a0)
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	22a080e7          	jalr	554(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024dc:	70a2                	ld	ra,40(sp)
    800024de:	7402                	ld	s0,32(sp)
    800024e0:	64e2                	ld	s1,24(sp)
    800024e2:	6942                	ld	s2,16(sp)
    800024e4:	69a2                	ld	s3,8(sp)
    800024e6:	6a02                	ld	s4,0(sp)
    800024e8:	6145                	addi	sp,sp,48
    800024ea:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ec:	000a061b          	sext.w	a2,s4
    800024f0:	85ce                	mv	a1,s3
    800024f2:	854a                	mv	a0,s2
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	84c080e7          	jalr	-1972(ra) # 80000d40 <memmove>
    return 0;
    800024fc:	8526                	mv	a0,s1
    800024fe:	bff9                	j	800024dc <either_copyin+0x32>

0000000080002500 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002500:	715d                	addi	sp,sp,-80
    80002502:	e486                	sd	ra,72(sp)
    80002504:	e0a2                	sd	s0,64(sp)
    80002506:	fc26                	sd	s1,56(sp)
    80002508:	f84a                	sd	s2,48(sp)
    8000250a:	f44e                	sd	s3,40(sp)
    8000250c:	f052                	sd	s4,32(sp)
    8000250e:	ec56                	sd	s5,24(sp)
    80002510:	e85a                	sd	s6,16(sp)
    80002512:	e45e                	sd	s7,8(sp)
    80002514:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002516:	00006517          	auipc	a0,0x6
    8000251a:	bb250513          	addi	a0,a0,-1102 # 800080c8 <digits+0x88>
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	06a080e7          	jalr	106(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002526:	0000f497          	auipc	s1,0xf
    8000252a:	30248493          	addi	s1,s1,770 # 80011828 <proc+0x158>
    8000252e:	00015917          	auipc	s2,0x15
    80002532:	cfa90913          	addi	s2,s2,-774 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002536:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002538:	00006997          	auipc	s3,0x6
    8000253c:	d4898993          	addi	s3,s3,-696 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002540:	00006a97          	auipc	s5,0x6
    80002544:	d48a8a93          	addi	s5,s5,-696 # 80008288 <digits+0x248>
    printf("\n");
    80002548:	00006a17          	auipc	s4,0x6
    8000254c:	b80a0a13          	addi	s4,s4,-1152 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002550:	00006b97          	auipc	s7,0x6
    80002554:	d70b8b93          	addi	s7,s7,-656 # 800082c0 <states.1723>
    80002558:	a00d                	j	8000257a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255a:	ed86a583          	lw	a1,-296(a3)
    8000255e:	8556                	mv	a0,s5
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	028080e7          	jalr	40(ra) # 80000588 <printf>
    printf("\n");
    80002568:	8552                	mv	a0,s4
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	01e080e7          	jalr	30(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002572:	16848493          	addi	s1,s1,360
    80002576:	03248163          	beq	s1,s2,80002598 <procdump+0x98>
    if(p->state == UNUSED)
    8000257a:	86a6                	mv	a3,s1
    8000257c:	ec04a783          	lw	a5,-320(s1)
    80002580:	dbed                	beqz	a5,80002572 <procdump+0x72>
      state = "???";
    80002582:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002584:	fcfb6be3          	bltu	s6,a5,8000255a <procdump+0x5a>
    80002588:	1782                	slli	a5,a5,0x20
    8000258a:	9381                	srli	a5,a5,0x20
    8000258c:	078e                	slli	a5,a5,0x3
    8000258e:	97de                	add	a5,a5,s7
    80002590:	6390                	ld	a2,0(a5)
    80002592:	f661                	bnez	a2,8000255a <procdump+0x5a>
      state = "???";
    80002594:	864e                	mv	a2,s3
    80002596:	b7d1                	j	8000255a <procdump+0x5a>
  }
}
    80002598:	60a6                	ld	ra,72(sp)
    8000259a:	6406                	ld	s0,64(sp)
    8000259c:	74e2                	ld	s1,56(sp)
    8000259e:	7942                	ld	s2,48(sp)
    800025a0:	79a2                	ld	s3,40(sp)
    800025a2:	7a02                	ld	s4,32(sp)
    800025a4:	6ae2                	ld	s5,24(sp)
    800025a6:	6b42                	ld	s6,16(sp)
    800025a8:	6ba2                	ld	s7,8(sp)
    800025aa:	6161                	addi	sp,sp,80
    800025ac:	8082                	ret

00000000800025ae <swtch>:
    800025ae:	00153023          	sd	ra,0(a0)
    800025b2:	00253423          	sd	sp,8(a0)
    800025b6:	e900                	sd	s0,16(a0)
    800025b8:	ed04                	sd	s1,24(a0)
    800025ba:	03253023          	sd	s2,32(a0)
    800025be:	03353423          	sd	s3,40(a0)
    800025c2:	03453823          	sd	s4,48(a0)
    800025c6:	03553c23          	sd	s5,56(a0)
    800025ca:	05653023          	sd	s6,64(a0)
    800025ce:	05753423          	sd	s7,72(a0)
    800025d2:	05853823          	sd	s8,80(a0)
    800025d6:	05953c23          	sd	s9,88(a0)
    800025da:	07a53023          	sd	s10,96(a0)
    800025de:	07b53423          	sd	s11,104(a0)
    800025e2:	0005b083          	ld	ra,0(a1)
    800025e6:	0085b103          	ld	sp,8(a1)
    800025ea:	6980                	ld	s0,16(a1)
    800025ec:	6d84                	ld	s1,24(a1)
    800025ee:	0205b903          	ld	s2,32(a1)
    800025f2:	0285b983          	ld	s3,40(a1)
    800025f6:	0305ba03          	ld	s4,48(a1)
    800025fa:	0385ba83          	ld	s5,56(a1)
    800025fe:	0405bb03          	ld	s6,64(a1)
    80002602:	0485bb83          	ld	s7,72(a1)
    80002606:	0505bc03          	ld	s8,80(a1)
    8000260a:	0585bc83          	ld	s9,88(a1)
    8000260e:	0605bd03          	ld	s10,96(a1)
    80002612:	0685bd83          	ld	s11,104(a1)
    80002616:	8082                	ret

0000000080002618 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002618:	1141                	addi	sp,sp,-16
    8000261a:	e406                	sd	ra,8(sp)
    8000261c:	e022                	sd	s0,0(sp)
    8000261e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002620:	00006597          	auipc	a1,0x6
    80002624:	cd058593          	addi	a1,a1,-816 # 800082f0 <states.1723+0x30>
    80002628:	00015517          	auipc	a0,0x15
    8000262c:	aa850513          	addi	a0,a0,-1368 # 800170d0 <tickslock>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	524080e7          	jalr	1316(ra) # 80000b54 <initlock>
}
    80002638:	60a2                	ld	ra,8(sp)
    8000263a:	6402                	ld	s0,0(sp)
    8000263c:	0141                	addi	sp,sp,16
    8000263e:	8082                	ret

0000000080002640 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002640:	1141                	addi	sp,sp,-16
    80002642:	e422                	sd	s0,8(sp)
    80002644:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002646:	00003797          	auipc	a5,0x3
    8000264a:	4ca78793          	addi	a5,a5,1226 # 80005b10 <kernelvec>
    8000264e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002652:	6422                	ld	s0,8(sp)
    80002654:	0141                	addi	sp,sp,16
    80002656:	8082                	ret

0000000080002658 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002658:	1141                	addi	sp,sp,-16
    8000265a:	e406                	sd	ra,8(sp)
    8000265c:	e022                	sd	s0,0(sp)
    8000265e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	350080e7          	jalr	848(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002668:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000266c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002672:	00005617          	auipc	a2,0x5
    80002676:	98e60613          	addi	a2,a2,-1650 # 80007000 <_trampoline>
    8000267a:	00005697          	auipc	a3,0x5
    8000267e:	98668693          	addi	a3,a3,-1658 # 80007000 <_trampoline>
    80002682:	8e91                	sub	a3,a3,a2
    80002684:	040007b7          	lui	a5,0x4000
    80002688:	17fd                	addi	a5,a5,-1
    8000268a:	07b2                	slli	a5,a5,0xc
    8000268c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002692:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002694:	180026f3          	csrr	a3,satp
    80002698:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000269a:	6d38                	ld	a4,88(a0)
    8000269c:	6134                	ld	a3,64(a0)
    8000269e:	6585                	lui	a1,0x1
    800026a0:	96ae                	add	a3,a3,a1
    800026a2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a4:	6d38                	ld	a4,88(a0)
    800026a6:	00000697          	auipc	a3,0x0
    800026aa:	13868693          	addi	a3,a3,312 # 800027de <usertrap>
    800026ae:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026b0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b2:	8692                	mv	a3,tp
    800026b4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ba:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026be:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026c8:	6f18                	ld	a4,24(a4)
    800026ca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ce:	692c                	ld	a1,80(a0)
    800026d0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026d2:	00005717          	auipc	a4,0x5
    800026d6:	9be70713          	addi	a4,a4,-1602 # 80007090 <userret>
    800026da:	8f11                	sub	a4,a4,a2
    800026dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026de:	577d                	li	a4,-1
    800026e0:	177e                	slli	a4,a4,0x3f
    800026e2:	8dd9                	or	a1,a1,a4
    800026e4:	02000537          	lui	a0,0x2000
    800026e8:	157d                	addi	a0,a0,-1
    800026ea:	0536                	slli	a0,a0,0xd
    800026ec:	9782                	jalr	a5
}
    800026ee:	60a2                	ld	ra,8(sp)
    800026f0:	6402                	ld	s0,0(sp)
    800026f2:	0141                	addi	sp,sp,16
    800026f4:	8082                	ret

00000000800026f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f6:	1101                	addi	sp,sp,-32
    800026f8:	ec06                	sd	ra,24(sp)
    800026fa:	e822                	sd	s0,16(sp)
    800026fc:	e426                	sd	s1,8(sp)
    800026fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002700:	00015497          	auipc	s1,0x15
    80002704:	9d048493          	addi	s1,s1,-1584 # 800170d0 <tickslock>
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
  ticks++;
    80002712:	00007517          	auipc	a0,0x7
    80002716:	91e50513          	addi	a0,a0,-1762 # 80009030 <ticks>
    8000271a:	411c                	lw	a5,0(a0)
    8000271c:	2785                	addiw	a5,a5,1
    8000271e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002720:	00000097          	auipc	ra,0x0
    80002724:	abe080e7          	jalr	-1346(ra) # 800021de <wakeup>
  release(&tickslock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	56e080e7          	jalr	1390(ra) # 80000c98 <release>
}
    80002732:	60e2                	ld	ra,24(sp)
    80002734:	6442                	ld	s0,16(sp)
    80002736:	64a2                	ld	s1,8(sp)
    80002738:	6105                	addi	sp,sp,32
    8000273a:	8082                	ret

000000008000273c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000273c:	1101                	addi	sp,sp,-32
    8000273e:	ec06                	sd	ra,24(sp)
    80002740:	e822                	sd	s0,16(sp)
    80002742:	e426                	sd	s1,8(sp)
    80002744:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002746:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000274a:	00074d63          	bltz	a4,80002764 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000274e:	57fd                	li	a5,-1
    80002750:	17fe                	slli	a5,a5,0x3f
    80002752:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002754:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002756:	06f70363          	beq	a4,a5,800027bc <devintr+0x80>
  }
}
    8000275a:	60e2                	ld	ra,24(sp)
    8000275c:	6442                	ld	s0,16(sp)
    8000275e:	64a2                	ld	s1,8(sp)
    80002760:	6105                	addi	sp,sp,32
    80002762:	8082                	ret
     (scause & 0xff) == 9){
    80002764:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002768:	46a5                	li	a3,9
    8000276a:	fed792e3          	bne	a5,a3,8000274e <devintr+0x12>
    int irq = plic_claim();
    8000276e:	00003097          	auipc	ra,0x3
    80002772:	4aa080e7          	jalr	1194(ra) # 80005c18 <plic_claim>
    80002776:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002778:	47a9                	li	a5,10
    8000277a:	02f50763          	beq	a0,a5,800027a8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000277e:	4785                	li	a5,1
    80002780:	02f50963          	beq	a0,a5,800027b2 <devintr+0x76>
    return 1;
    80002784:	4505                	li	a0,1
    } else if(irq){
    80002786:	d8f1                	beqz	s1,8000275a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002788:	85a6                	mv	a1,s1
    8000278a:	00006517          	auipc	a0,0x6
    8000278e:	b6e50513          	addi	a0,a0,-1170 # 800082f8 <states.1723+0x38>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
      plic_complete(irq);
    8000279a:	8526                	mv	a0,s1
    8000279c:	00003097          	auipc	ra,0x3
    800027a0:	4a0080e7          	jalr	1184(ra) # 80005c3c <plic_complete>
    return 1;
    800027a4:	4505                	li	a0,1
    800027a6:	bf55                	j	8000275a <devintr+0x1e>
      uartintr();
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	200080e7          	jalr	512(ra) # 800009a8 <uartintr>
    800027b0:	b7ed                	j	8000279a <devintr+0x5e>
      virtio_disk_intr();
    800027b2:	00004097          	auipc	ra,0x4
    800027b6:	96a080e7          	jalr	-1686(ra) # 8000611c <virtio_disk_intr>
    800027ba:	b7c5                	j	8000279a <devintr+0x5e>
    if(cpuid() == 0){
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	1c8080e7          	jalr	456(ra) # 80001984 <cpuid>
    800027c4:	c901                	beqz	a0,800027d4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027cc:	14479073          	csrw	sip,a5
    return 2;
    800027d0:	4509                	li	a0,2
    800027d2:	b761                	j	8000275a <devintr+0x1e>
      clockintr();
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	f22080e7          	jalr	-222(ra) # 800026f6 <clockintr>
    800027dc:	b7ed                	j	800027c6 <devintr+0x8a>

00000000800027de <usertrap>:
{
    800027de:	1101                	addi	sp,sp,-32
    800027e0:	ec06                	sd	ra,24(sp)
    800027e2:	e822                	sd	s0,16(sp)
    800027e4:	e426                	sd	s1,8(sp)
    800027e6:	e04a                	sd	s2,0(sp)
    800027e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ee:	1007f793          	andi	a5,a5,256
    800027f2:	e3ad                	bnez	a5,80002854 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f4:	00003797          	auipc	a5,0x3
    800027f8:	31c78793          	addi	a5,a5,796 # 80005b10 <kernelvec>
    800027fc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	1b0080e7          	jalr	432(ra) # 800019b0 <myproc>
    80002808:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000280a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280c:	14102773          	csrr	a4,sepc
    80002810:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002812:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002816:	47a1                	li	a5,8
    80002818:	04f71c63          	bne	a4,a5,80002870 <usertrap+0x92>
    if(p->killed)
    8000281c:	551c                	lw	a5,40(a0)
    8000281e:	e3b9                	bnez	a5,80002864 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002820:	6cb8                	ld	a4,88(s1)
    80002822:	6f1c                	ld	a5,24(a4)
    80002824:	0791                	addi	a5,a5,4
    80002826:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002828:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000282c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002830:	10079073          	csrw	sstatus,a5
    syscall();
    80002834:	00000097          	auipc	ra,0x0
    80002838:	2e0080e7          	jalr	736(ra) # 80002b14 <syscall>
  if(p->killed)
    8000283c:	549c                	lw	a5,40(s1)
    8000283e:	ebc1                	bnez	a5,800028ce <usertrap+0xf0>
  usertrapret();
    80002840:	00000097          	auipc	ra,0x0
    80002844:	e18080e7          	jalr	-488(ra) # 80002658 <usertrapret>
}
    80002848:	60e2                	ld	ra,24(sp)
    8000284a:	6442                	ld	s0,16(sp)
    8000284c:	64a2                	ld	s1,8(sp)
    8000284e:	6902                	ld	s2,0(sp)
    80002850:	6105                	addi	sp,sp,32
    80002852:	8082                	ret
    panic("usertrap: not from user mode");
    80002854:	00006517          	auipc	a0,0x6
    80002858:	ac450513          	addi	a0,a0,-1340 # 80008318 <states.1723+0x58>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
      exit(-1);
    80002864:	557d                	li	a0,-1
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	a48080e7          	jalr	-1464(ra) # 800022ae <exit>
    8000286e:	bf4d                	j	80002820 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002870:	00000097          	auipc	ra,0x0
    80002874:	ecc080e7          	jalr	-308(ra) # 8000273c <devintr>
    80002878:	892a                	mv	s2,a0
    8000287a:	c501                	beqz	a0,80002882 <usertrap+0xa4>
  if(p->killed)
    8000287c:	549c                	lw	a5,40(s1)
    8000287e:	c3a1                	beqz	a5,800028be <usertrap+0xe0>
    80002880:	a815                	j	800028b4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002882:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002886:	5890                	lw	a2,48(s1)
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	ab050513          	addi	a0,a0,-1360 # 80008338 <states.1723+0x78>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cf8080e7          	jalr	-776(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002898:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000289c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	ac850513          	addi	a0,a0,-1336 # 80008368 <states.1723+0xa8>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	ce0080e7          	jalr	-800(ra) # 80000588 <printf>
    p->killed = 1;
    800028b0:	4785                	li	a5,1
    800028b2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028b4:	557d                	li	a0,-1
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	9f8080e7          	jalr	-1544(ra) # 800022ae <exit>
  if(which_dev == 2)
    800028be:	4789                	li	a5,2
    800028c0:	f8f910e3          	bne	s2,a5,80002840 <usertrap+0x62>
    yield();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	752080e7          	jalr	1874(ra) # 80002016 <yield>
    800028cc:	bf95                	j	80002840 <usertrap+0x62>
  int which_dev = 0;
    800028ce:	4901                	li	s2,0
    800028d0:	b7d5                	j	800028b4 <usertrap+0xd6>

00000000800028d2 <kerneltrap>:
{
    800028d2:	7179                	addi	sp,sp,-48
    800028d4:	f406                	sd	ra,40(sp)
    800028d6:	f022                	sd	s0,32(sp)
    800028d8:	ec26                	sd	s1,24(sp)
    800028da:	e84a                	sd	s2,16(sp)
    800028dc:	e44e                	sd	s3,8(sp)
    800028de:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ec:	1004f793          	andi	a5,s1,256
    800028f0:	cb85                	beqz	a5,80002920 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f8:	ef85                	bnez	a5,80002930 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	e42080e7          	jalr	-446(ra) # 8000273c <devintr>
    80002902:	cd1d                	beqz	a0,80002940 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002904:	4789                	li	a5,2
    80002906:	06f50a63          	beq	a0,a5,8000297a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000290a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290e:	10049073          	csrw	sstatus,s1
}
    80002912:	70a2                	ld	ra,40(sp)
    80002914:	7402                	ld	s0,32(sp)
    80002916:	64e2                	ld	s1,24(sp)
    80002918:	6942                	ld	s2,16(sp)
    8000291a:	69a2                	ld	s3,8(sp)
    8000291c:	6145                	addi	sp,sp,48
    8000291e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002920:	00006517          	auipc	a0,0x6
    80002924:	a6850513          	addi	a0,a0,-1432 # 80008388 <states.1723+0xc8>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c16080e7          	jalr	-1002(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002930:	00006517          	auipc	a0,0x6
    80002934:	a8050513          	addi	a0,a0,-1408 # 800083b0 <states.1723+0xf0>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c06080e7          	jalr	-1018(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002940:	85ce                	mv	a1,s3
    80002942:	00006517          	auipc	a0,0x6
    80002946:	a8e50513          	addi	a0,a0,-1394 # 800083d0 <states.1723+0x110>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c3e080e7          	jalr	-962(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002952:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002956:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000295a:	00006517          	auipc	a0,0x6
    8000295e:	a8650513          	addi	a0,a0,-1402 # 800083e0 <states.1723+0x120>
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	c26080e7          	jalr	-986(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	a8e50513          	addi	a0,a0,-1394 # 800083f8 <states.1723+0x138>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	bcc080e7          	jalr	-1076(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	036080e7          	jalr	54(ra) # 800019b0 <myproc>
    80002982:	d541                	beqz	a0,8000290a <kerneltrap+0x38>
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	02c080e7          	jalr	44(ra) # 800019b0 <myproc>
    8000298c:	4d18                	lw	a4,24(a0)
    8000298e:	4791                	li	a5,4
    80002990:	f6f71de3          	bne	a4,a5,8000290a <kerneltrap+0x38>
    yield();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	682080e7          	jalr	1666(ra) # 80002016 <yield>
    8000299c:	b7bd                	j	8000290a <kerneltrap+0x38>

000000008000299e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000299e:	1101                	addi	sp,sp,-32
    800029a0:	ec06                	sd	ra,24(sp)
    800029a2:	e822                	sd	s0,16(sp)
    800029a4:	e426                	sd	s1,8(sp)
    800029a6:	1000                	addi	s0,sp,32
    800029a8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	006080e7          	jalr	6(ra) # 800019b0 <myproc>
  switch (n) {
    800029b2:	4795                	li	a5,5
    800029b4:	0497e163          	bltu	a5,s1,800029f6 <argraw+0x58>
    800029b8:	048a                	slli	s1,s1,0x2
    800029ba:	00006717          	auipc	a4,0x6
    800029be:	a7670713          	addi	a4,a4,-1418 # 80008430 <states.1723+0x170>
    800029c2:	94ba                	add	s1,s1,a4
    800029c4:	409c                	lw	a5,0(s1)
    800029c6:	97ba                	add	a5,a5,a4
    800029c8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029ca:	6d3c                	ld	a5,88(a0)
    800029cc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ce:	60e2                	ld	ra,24(sp)
    800029d0:	6442                	ld	s0,16(sp)
    800029d2:	64a2                	ld	s1,8(sp)
    800029d4:	6105                	addi	sp,sp,32
    800029d6:	8082                	ret
    return p->trapframe->a1;
    800029d8:	6d3c                	ld	a5,88(a0)
    800029da:	7fa8                	ld	a0,120(a5)
    800029dc:	bfcd                	j	800029ce <argraw+0x30>
    return p->trapframe->a2;
    800029de:	6d3c                	ld	a5,88(a0)
    800029e0:	63c8                	ld	a0,128(a5)
    800029e2:	b7f5                	j	800029ce <argraw+0x30>
    return p->trapframe->a3;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	67c8                	ld	a0,136(a5)
    800029e8:	b7dd                	j	800029ce <argraw+0x30>
    return p->trapframe->a4;
    800029ea:	6d3c                	ld	a5,88(a0)
    800029ec:	6bc8                	ld	a0,144(a5)
    800029ee:	b7c5                	j	800029ce <argraw+0x30>
    return p->trapframe->a5;
    800029f0:	6d3c                	ld	a5,88(a0)
    800029f2:	6fc8                	ld	a0,152(a5)
    800029f4:	bfe9                	j	800029ce <argraw+0x30>
  panic("argraw");
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	a1250513          	addi	a0,a0,-1518 # 80008408 <states.1723+0x148>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>

0000000080002a06 <fetchaddr>:
{
    80002a06:	1101                	addi	sp,sp,-32
    80002a08:	ec06                	sd	ra,24(sp)
    80002a0a:	e822                	sd	s0,16(sp)
    80002a0c:	e426                	sd	s1,8(sp)
    80002a0e:	e04a                	sd	s2,0(sp)
    80002a10:	1000                	addi	s0,sp,32
    80002a12:	84aa                	mv	s1,a0
    80002a14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	f9a080e7          	jalr	-102(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a1e:	653c                	ld	a5,72(a0)
    80002a20:	02f4f863          	bgeu	s1,a5,80002a50 <fetchaddr+0x4a>
    80002a24:	00848713          	addi	a4,s1,8
    80002a28:	02e7e663          	bltu	a5,a4,80002a54 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a2c:	46a1                	li	a3,8
    80002a2e:	8626                	mv	a2,s1
    80002a30:	85ca                	mv	a1,s2
    80002a32:	6928                	ld	a0,80(a0)
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	cca080e7          	jalr	-822(ra) # 800016fe <copyin>
    80002a3c:	00a03533          	snez	a0,a0
    80002a40:	40a00533          	neg	a0,a0
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6902                	ld	s2,0(sp)
    80002a4c:	6105                	addi	sp,sp,32
    80002a4e:	8082                	ret
    return -1;
    80002a50:	557d                	li	a0,-1
    80002a52:	bfcd                	j	80002a44 <fetchaddr+0x3e>
    80002a54:	557d                	li	a0,-1
    80002a56:	b7fd                	j	80002a44 <fetchaddr+0x3e>

0000000080002a58 <fetchstr>:
{
    80002a58:	7179                	addi	sp,sp,-48
    80002a5a:	f406                	sd	ra,40(sp)
    80002a5c:	f022                	sd	s0,32(sp)
    80002a5e:	ec26                	sd	s1,24(sp)
    80002a60:	e84a                	sd	s2,16(sp)
    80002a62:	e44e                	sd	s3,8(sp)
    80002a64:	1800                	addi	s0,sp,48
    80002a66:	892a                	mv	s2,a0
    80002a68:	84ae                	mv	s1,a1
    80002a6a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	f44080e7          	jalr	-188(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a74:	86ce                	mv	a3,s3
    80002a76:	864a                	mv	a2,s2
    80002a78:	85a6                	mv	a1,s1
    80002a7a:	6928                	ld	a0,80(a0)
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	d0e080e7          	jalr	-754(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a84:	00054763          	bltz	a0,80002a92 <fetchstr+0x3a>
  return strlen(buf);
    80002a88:	8526                	mv	a0,s1
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	3da080e7          	jalr	986(ra) # 80000e64 <strlen>
}
    80002a92:	70a2                	ld	ra,40(sp)
    80002a94:	7402                	ld	s0,32(sp)
    80002a96:	64e2                	ld	s1,24(sp)
    80002a98:	6942                	ld	s2,16(sp)
    80002a9a:	69a2                	ld	s3,8(sp)
    80002a9c:	6145                	addi	sp,sp,48
    80002a9e:	8082                	ret

0000000080002aa0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	1000                	addi	s0,sp,32
    80002aaa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	ef2080e7          	jalr	-270(ra) # 8000299e <argraw>
    80002ab4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab6:	4501                	li	a0,0
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	64a2                	ld	s1,8(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret

0000000080002ac2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ac2:	1101                	addi	sp,sp,-32
    80002ac4:	ec06                	sd	ra,24(sp)
    80002ac6:	e822                	sd	s0,16(sp)
    80002ac8:	e426                	sd	s1,8(sp)
    80002aca:	1000                	addi	s0,sp,32
    80002acc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	ed0080e7          	jalr	-304(ra) # 8000299e <argraw>
    80002ad6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ad8:	4501                	li	a0,0
    80002ada:	60e2                	ld	ra,24(sp)
    80002adc:	6442                	ld	s0,16(sp)
    80002ade:	64a2                	ld	s1,8(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret

0000000080002ae4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	e04a                	sd	s2,0(sp)
    80002aee:	1000                	addi	s0,sp,32
    80002af0:	84ae                	mv	s1,a1
    80002af2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	eaa080e7          	jalr	-342(ra) # 8000299e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002afc:	864a                	mv	a2,s2
    80002afe:	85a6                	mv	a1,s1
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	f58080e7          	jalr	-168(ra) # 80002a58 <fetchstr>
}
    80002b08:	60e2                	ld	ra,24(sp)
    80002b0a:	6442                	ld	s0,16(sp)
    80002b0c:	64a2                	ld	s1,8(sp)
    80002b0e:	6902                	ld	s2,0(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret

0000000080002b14 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b14:	1101                	addi	sp,sp,-32
    80002b16:	ec06                	sd	ra,24(sp)
    80002b18:	e822                	sd	s0,16(sp)
    80002b1a:	e426                	sd	s1,8(sp)
    80002b1c:	e04a                	sd	s2,0(sp)
    80002b1e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	e90080e7          	jalr	-368(ra) # 800019b0 <myproc>
    80002b28:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b2a:	05853903          	ld	s2,88(a0)
    80002b2e:	0a893783          	ld	a5,168(s2)
    80002b32:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b36:	37fd                	addiw	a5,a5,-1
    80002b38:	4751                	li	a4,20
    80002b3a:	00f76f63          	bltu	a4,a5,80002b58 <syscall+0x44>
    80002b3e:	00369713          	slli	a4,a3,0x3
    80002b42:	00006797          	auipc	a5,0x6
    80002b46:	90678793          	addi	a5,a5,-1786 # 80008448 <syscalls>
    80002b4a:	97ba                	add	a5,a5,a4
    80002b4c:	639c                	ld	a5,0(a5)
    80002b4e:	c789                	beqz	a5,80002b58 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b50:	9782                	jalr	a5
    80002b52:	06a93823          	sd	a0,112(s2)
    80002b56:	a839                	j	80002b74 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b58:	15848613          	addi	a2,s1,344
    80002b5c:	588c                	lw	a1,48(s1)
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	8b250513          	addi	a0,a0,-1870 # 80008410 <states.1723+0x150>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	a22080e7          	jalr	-1502(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b6e:	6cbc                	ld	a5,88(s1)
    80002b70:	577d                	li	a4,-1
    80002b72:	fbb8                	sd	a4,112(a5)
  }
}
    80002b74:	60e2                	ld	ra,24(sp)
    80002b76:	6442                	ld	s0,16(sp)
    80002b78:	64a2                	ld	s1,8(sp)
    80002b7a:	6902                	ld	s2,0(sp)
    80002b7c:	6105                	addi	sp,sp,32
    80002b7e:	8082                	ret

0000000080002b80 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b88:	fec40593          	addi	a1,s0,-20
    80002b8c:	4501                	li	a0,0
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	f12080e7          	jalr	-238(ra) # 80002aa0 <argint>
    return -1;
    80002b96:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b98:	00054963          	bltz	a0,80002baa <sys_exit+0x2a>
  exit(n);
    80002b9c:	fec42503          	lw	a0,-20(s0)
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	70e080e7          	jalr	1806(ra) # 800022ae <exit>
  return 0;  // not reached
    80002ba8:	4781                	li	a5,0
}
    80002baa:	853e                	mv	a0,a5
    80002bac:	60e2                	ld	ra,24(sp)
    80002bae:	6442                	ld	s0,16(sp)
    80002bb0:	6105                	addi	sp,sp,32
    80002bb2:	8082                	ret

0000000080002bb4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bb4:	1141                	addi	sp,sp,-16
    80002bb6:	e406                	sd	ra,8(sp)
    80002bb8:	e022                	sd	s0,0(sp)
    80002bba:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	df4080e7          	jalr	-524(ra) # 800019b0 <myproc>
}
    80002bc4:	5908                	lw	a0,48(a0)
    80002bc6:	60a2                	ld	ra,8(sp)
    80002bc8:	6402                	ld	s0,0(sp)
    80002bca:	0141                	addi	sp,sp,16
    80002bcc:	8082                	ret

0000000080002bce <sys_fork>:

uint64
sys_fork(void)
{
    80002bce:	1141                	addi	sp,sp,-16
    80002bd0:	e406                	sd	ra,8(sp)
    80002bd2:	e022                	sd	s0,0(sp)
    80002bd4:	0800                	addi	s0,sp,16
  return fork();
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	18e080e7          	jalr	398(ra) # 80001d64 <fork>
}
    80002bde:	60a2                	ld	ra,8(sp)
    80002be0:	6402                	ld	s0,0(sp)
    80002be2:	0141                	addi	sp,sp,16
    80002be4:	8082                	ret

0000000080002be6 <sys_wait>:

uint64
sys_wait(void)
{
    80002be6:	1101                	addi	sp,sp,-32
    80002be8:	ec06                	sd	ra,24(sp)
    80002bea:	e822                	sd	s0,16(sp)
    80002bec:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bee:	fe840593          	addi	a1,s0,-24
    80002bf2:	4501                	li	a0,0
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	ece080e7          	jalr	-306(ra) # 80002ac2 <argaddr>
    80002bfc:	87aa                	mv	a5,a0
    return -1;
    80002bfe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c00:	0007c863          	bltz	a5,80002c10 <sys_wait+0x2a>
  return wait(p);
    80002c04:	fe843503          	ld	a0,-24(s0)
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	4ae080e7          	jalr	1198(ra) # 800020b6 <wait>
}
    80002c10:	60e2                	ld	ra,24(sp)
    80002c12:	6442                	ld	s0,16(sp)
    80002c14:	6105                	addi	sp,sp,32
    80002c16:	8082                	ret

0000000080002c18 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c18:	7179                	addi	sp,sp,-48
    80002c1a:	f406                	sd	ra,40(sp)
    80002c1c:	f022                	sd	s0,32(sp)
    80002c1e:	ec26                	sd	s1,24(sp)
    80002c20:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c22:	fdc40593          	addi	a1,s0,-36
    80002c26:	4501                	li	a0,0
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	e78080e7          	jalr	-392(ra) # 80002aa0 <argint>
    80002c30:	87aa                	mv	a5,a0
    return -1;
    80002c32:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c34:	0207c063          	bltz	a5,80002c54 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	d78080e7          	jalr	-648(ra) # 800019b0 <myproc>
    80002c40:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c42:	fdc42503          	lw	a0,-36(s0)
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	0c4080e7          	jalr	196(ra) # 80001d0a <growproc>
    80002c4e:	00054863          	bltz	a0,80002c5e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c52:	8526                	mv	a0,s1
}
    80002c54:	70a2                	ld	ra,40(sp)
    80002c56:	7402                	ld	s0,32(sp)
    80002c58:	64e2                	ld	s1,24(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret
    return -1;
    80002c5e:	557d                	li	a0,-1
    80002c60:	bfd5                	j	80002c54 <sys_sbrk+0x3c>

0000000080002c62 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c62:	7139                	addi	sp,sp,-64
    80002c64:	fc06                	sd	ra,56(sp)
    80002c66:	f822                	sd	s0,48(sp)
    80002c68:	f426                	sd	s1,40(sp)
    80002c6a:	f04a                	sd	s2,32(sp)
    80002c6c:	ec4e                	sd	s3,24(sp)
    80002c6e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c70:	fcc40593          	addi	a1,s0,-52
    80002c74:	4501                	li	a0,0
    80002c76:	00000097          	auipc	ra,0x0
    80002c7a:	e2a080e7          	jalr	-470(ra) # 80002aa0 <argint>
    return -1;
    80002c7e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c80:	06054563          	bltz	a0,80002cea <sys_sleep+0x88>
  acquire(&tickslock);
    80002c84:	00014517          	auipc	a0,0x14
    80002c88:	44c50513          	addi	a0,a0,1100 # 800170d0 <tickslock>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	f58080e7          	jalr	-168(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002c94:	00006917          	auipc	s2,0x6
    80002c98:	39c92903          	lw	s2,924(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c9c:	fcc42783          	lw	a5,-52(s0)
    80002ca0:	cf85                	beqz	a5,80002cd8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ca2:	00014997          	auipc	s3,0x14
    80002ca6:	42e98993          	addi	s3,s3,1070 # 800170d0 <tickslock>
    80002caa:	00006497          	auipc	s1,0x6
    80002cae:	38648493          	addi	s1,s1,902 # 80009030 <ticks>
    if(myproc()->killed){
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	cfe080e7          	jalr	-770(ra) # 800019b0 <myproc>
    80002cba:	551c                	lw	a5,40(a0)
    80002cbc:	ef9d                	bnez	a5,80002cfa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cbe:	85ce                	mv	a1,s3
    80002cc0:	8526                	mv	a0,s1
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	390080e7          	jalr	912(ra) # 80002052 <sleep>
  while(ticks - ticks0 < n){
    80002cca:	409c                	lw	a5,0(s1)
    80002ccc:	412787bb          	subw	a5,a5,s2
    80002cd0:	fcc42703          	lw	a4,-52(s0)
    80002cd4:	fce7efe3          	bltu	a5,a4,80002cb2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cd8:	00014517          	auipc	a0,0x14
    80002cdc:	3f850513          	addi	a0,a0,1016 # 800170d0 <tickslock>
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	fb8080e7          	jalr	-72(ra) # 80000c98 <release>
  return 0;
    80002ce8:	4781                	li	a5,0
}
    80002cea:	853e                	mv	a0,a5
    80002cec:	70e2                	ld	ra,56(sp)
    80002cee:	7442                	ld	s0,48(sp)
    80002cf0:	74a2                	ld	s1,40(sp)
    80002cf2:	7902                	ld	s2,32(sp)
    80002cf4:	69e2                	ld	s3,24(sp)
    80002cf6:	6121                	addi	sp,sp,64
    80002cf8:	8082                	ret
      release(&tickslock);
    80002cfa:	00014517          	auipc	a0,0x14
    80002cfe:	3d650513          	addi	a0,a0,982 # 800170d0 <tickslock>
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	f96080e7          	jalr	-106(ra) # 80000c98 <release>
      return -1;
    80002d0a:	57fd                	li	a5,-1
    80002d0c:	bff9                	j	80002cea <sys_sleep+0x88>

0000000080002d0e <sys_pause_system>:


uint64
sys_pause_system(void)
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	1000                	addi	s0,sp,32
  int seconds;
  
  if(argint(0, &seconds) < 0)
    80002d16:	fec40593          	addi	a1,s0,-20
    80002d1a:	4501                	li	a0,0
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	d84080e7          	jalr	-636(ra) # 80002aa0 <argint>
    80002d24:	87aa                	mv	a5,a0
    return -1;
    80002d26:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80002d28:	0007c863          	bltz	a5,80002d38 <sys_pause_system+0x2a>
  return pause_system(seconds);
    80002d2c:	fec42503          	lw	a0,-20(s0)
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	654080e7          	jalr	1620(ra) # 80002384 <pause_system>
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002d40:	1141                	addi	sp,sp,-16
    80002d42:	e406                	sd	ra,8(sp)
    80002d44:	e022                	sd	s0,0(sp)
    80002d46:	0800                	addi	s0,sp,16
  return kill_system();
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	6bc080e7          	jalr	1724(ra) # 80002404 <kill_system>
}
    80002d50:	60a2                	ld	ra,8(sp)
    80002d52:	6402                	ld	s0,0(sp)
    80002d54:	0141                	addi	sp,sp,16
    80002d56:	8082                	ret

0000000080002d58 <sys_kill>:


uint64
sys_kill(void)
{
    80002d58:	1101                	addi	sp,sp,-32
    80002d5a:	ec06                	sd	ra,24(sp)
    80002d5c:	e822                	sd	s0,16(sp)
    80002d5e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d60:	fec40593          	addi	a1,s0,-20
    80002d64:	4501                	li	a0,0
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	d3a080e7          	jalr	-710(ra) # 80002aa0 <argint>
    80002d6e:	87aa                	mv	a5,a0
    return -1;
    80002d70:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d72:	0007c863          	bltz	a5,80002d82 <sys_kill+0x2a>
  return kill(pid);
    80002d76:	fec42503          	lw	a0,-20(s0)
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	618080e7          	jalr	1560(ra) # 80002392 <kill>
}
    80002d82:	60e2                	ld	ra,24(sp)
    80002d84:	6442                	ld	s0,16(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret

0000000080002d8a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	e426                	sd	s1,8(sp)
    80002d92:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d94:	00014517          	auipc	a0,0x14
    80002d98:	33c50513          	addi	a0,a0,828 # 800170d0 <tickslock>
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	e48080e7          	jalr	-440(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002da4:	00006497          	auipc	s1,0x6
    80002da8:	28c4a483          	lw	s1,652(s1) # 80009030 <ticks>
  release(&tickslock);
    80002dac:	00014517          	auipc	a0,0x14
    80002db0:	32450513          	addi	a0,a0,804 # 800170d0 <tickslock>
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	ee4080e7          	jalr	-284(ra) # 80000c98 <release>
  return xticks;
}
    80002dbc:	02049513          	slli	a0,s1,0x20
    80002dc0:	9101                	srli	a0,a0,0x20
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dcc:	7179                	addi	sp,sp,-48
    80002dce:	f406                	sd	ra,40(sp)
    80002dd0:	f022                	sd	s0,32(sp)
    80002dd2:	ec26                	sd	s1,24(sp)
    80002dd4:	e84a                	sd	s2,16(sp)
    80002dd6:	e44e                	sd	s3,8(sp)
    80002dd8:	e052                	sd	s4,0(sp)
    80002dda:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ddc:	00005597          	auipc	a1,0x5
    80002de0:	71c58593          	addi	a1,a1,1820 # 800084f8 <syscalls+0xb0>
    80002de4:	00014517          	auipc	a0,0x14
    80002de8:	30450513          	addi	a0,a0,772 # 800170e8 <bcache>
    80002dec:	ffffe097          	auipc	ra,0xffffe
    80002df0:	d68080e7          	jalr	-664(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002df4:	0001c797          	auipc	a5,0x1c
    80002df8:	2f478793          	addi	a5,a5,756 # 8001f0e8 <bcache+0x8000>
    80002dfc:	0001c717          	auipc	a4,0x1c
    80002e00:	55470713          	addi	a4,a4,1364 # 8001f350 <bcache+0x8268>
    80002e04:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e08:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e0c:	00014497          	auipc	s1,0x14
    80002e10:	2f448493          	addi	s1,s1,756 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e14:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e16:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e18:	00005a17          	auipc	s4,0x5
    80002e1c:	6e8a0a13          	addi	s4,s4,1768 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002e20:	2b893783          	ld	a5,696(s2)
    80002e24:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e26:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e2a:	85d2                	mv	a1,s4
    80002e2c:	01048513          	addi	a0,s1,16
    80002e30:	00001097          	auipc	ra,0x1
    80002e34:	4bc080e7          	jalr	1212(ra) # 800042ec <initsleeplock>
    bcache.head.next->prev = b;
    80002e38:	2b893783          	ld	a5,696(s2)
    80002e3c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e3e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e42:	45848493          	addi	s1,s1,1112
    80002e46:	fd349de3          	bne	s1,s3,80002e20 <binit+0x54>
  }
}
    80002e4a:	70a2                	ld	ra,40(sp)
    80002e4c:	7402                	ld	s0,32(sp)
    80002e4e:	64e2                	ld	s1,24(sp)
    80002e50:	6942                	ld	s2,16(sp)
    80002e52:	69a2                	ld	s3,8(sp)
    80002e54:	6a02                	ld	s4,0(sp)
    80002e56:	6145                	addi	sp,sp,48
    80002e58:	8082                	ret

0000000080002e5a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e5a:	7179                	addi	sp,sp,-48
    80002e5c:	f406                	sd	ra,40(sp)
    80002e5e:	f022                	sd	s0,32(sp)
    80002e60:	ec26                	sd	s1,24(sp)
    80002e62:	e84a                	sd	s2,16(sp)
    80002e64:	e44e                	sd	s3,8(sp)
    80002e66:	1800                	addi	s0,sp,48
    80002e68:	89aa                	mv	s3,a0
    80002e6a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e6c:	00014517          	auipc	a0,0x14
    80002e70:	27c50513          	addi	a0,a0,636 # 800170e8 <bcache>
    80002e74:	ffffe097          	auipc	ra,0xffffe
    80002e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e7c:	0001c497          	auipc	s1,0x1c
    80002e80:	5244b483          	ld	s1,1316(s1) # 8001f3a0 <bcache+0x82b8>
    80002e84:	0001c797          	auipc	a5,0x1c
    80002e88:	4cc78793          	addi	a5,a5,1228 # 8001f350 <bcache+0x8268>
    80002e8c:	02f48f63          	beq	s1,a5,80002eca <bread+0x70>
    80002e90:	873e                	mv	a4,a5
    80002e92:	a021                	j	80002e9a <bread+0x40>
    80002e94:	68a4                	ld	s1,80(s1)
    80002e96:	02e48a63          	beq	s1,a4,80002eca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e9a:	449c                	lw	a5,8(s1)
    80002e9c:	ff379ce3          	bne	a5,s3,80002e94 <bread+0x3a>
    80002ea0:	44dc                	lw	a5,12(s1)
    80002ea2:	ff2799e3          	bne	a5,s2,80002e94 <bread+0x3a>
      b->refcnt++;
    80002ea6:	40bc                	lw	a5,64(s1)
    80002ea8:	2785                	addiw	a5,a5,1
    80002eaa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eac:	00014517          	auipc	a0,0x14
    80002eb0:	23c50513          	addi	a0,a0,572 # 800170e8 <bcache>
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	de4080e7          	jalr	-540(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ebc:	01048513          	addi	a0,s1,16
    80002ec0:	00001097          	auipc	ra,0x1
    80002ec4:	466080e7          	jalr	1126(ra) # 80004326 <acquiresleep>
      return b;
    80002ec8:	a8b9                	j	80002f26 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eca:	0001c497          	auipc	s1,0x1c
    80002ece:	4ce4b483          	ld	s1,1230(s1) # 8001f398 <bcache+0x82b0>
    80002ed2:	0001c797          	auipc	a5,0x1c
    80002ed6:	47e78793          	addi	a5,a5,1150 # 8001f350 <bcache+0x8268>
    80002eda:	00f48863          	beq	s1,a5,80002eea <bread+0x90>
    80002ede:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ee0:	40bc                	lw	a5,64(s1)
    80002ee2:	cf81                	beqz	a5,80002efa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ee4:	64a4                	ld	s1,72(s1)
    80002ee6:	fee49de3          	bne	s1,a4,80002ee0 <bread+0x86>
  panic("bget: no buffers");
    80002eea:	00005517          	auipc	a0,0x5
    80002eee:	61e50513          	addi	a0,a0,1566 # 80008508 <syscalls+0xc0>
    80002ef2:	ffffd097          	auipc	ra,0xffffd
    80002ef6:	64c080e7          	jalr	1612(ra) # 8000053e <panic>
      b->dev = dev;
    80002efa:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002efe:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f02:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f06:	4785                	li	a5,1
    80002f08:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f0a:	00014517          	auipc	a0,0x14
    80002f0e:	1de50513          	addi	a0,a0,478 # 800170e8 <bcache>
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f1a:	01048513          	addi	a0,s1,16
    80002f1e:	00001097          	auipc	ra,0x1
    80002f22:	408080e7          	jalr	1032(ra) # 80004326 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f26:	409c                	lw	a5,0(s1)
    80002f28:	cb89                	beqz	a5,80002f3a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f2a:	8526                	mv	a0,s1
    80002f2c:	70a2                	ld	ra,40(sp)
    80002f2e:	7402                	ld	s0,32(sp)
    80002f30:	64e2                	ld	s1,24(sp)
    80002f32:	6942                	ld	s2,16(sp)
    80002f34:	69a2                	ld	s3,8(sp)
    80002f36:	6145                	addi	sp,sp,48
    80002f38:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f3a:	4581                	li	a1,0
    80002f3c:	8526                	mv	a0,s1
    80002f3e:	00003097          	auipc	ra,0x3
    80002f42:	f08080e7          	jalr	-248(ra) # 80005e46 <virtio_disk_rw>
    b->valid = 1;
    80002f46:	4785                	li	a5,1
    80002f48:	c09c                	sw	a5,0(s1)
  return b;
    80002f4a:	b7c5                	j	80002f2a <bread+0xd0>

0000000080002f4c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f4c:	1101                	addi	sp,sp,-32
    80002f4e:	ec06                	sd	ra,24(sp)
    80002f50:	e822                	sd	s0,16(sp)
    80002f52:	e426                	sd	s1,8(sp)
    80002f54:	1000                	addi	s0,sp,32
    80002f56:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f58:	0541                	addi	a0,a0,16
    80002f5a:	00001097          	auipc	ra,0x1
    80002f5e:	466080e7          	jalr	1126(ra) # 800043c0 <holdingsleep>
    80002f62:	cd01                	beqz	a0,80002f7a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f64:	4585                	li	a1,1
    80002f66:	8526                	mv	a0,s1
    80002f68:	00003097          	auipc	ra,0x3
    80002f6c:	ede080e7          	jalr	-290(ra) # 80005e46 <virtio_disk_rw>
}
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	64a2                	ld	s1,8(sp)
    80002f76:	6105                	addi	sp,sp,32
    80002f78:	8082                	ret
    panic("bwrite");
    80002f7a:	00005517          	auipc	a0,0x5
    80002f7e:	5a650513          	addi	a0,a0,1446 # 80008520 <syscalls+0xd8>
    80002f82:	ffffd097          	auipc	ra,0xffffd
    80002f86:	5bc080e7          	jalr	1468(ra) # 8000053e <panic>

0000000080002f8a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	e426                	sd	s1,8(sp)
    80002f92:	e04a                	sd	s2,0(sp)
    80002f94:	1000                	addi	s0,sp,32
    80002f96:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f98:	01050913          	addi	s2,a0,16
    80002f9c:	854a                	mv	a0,s2
    80002f9e:	00001097          	auipc	ra,0x1
    80002fa2:	422080e7          	jalr	1058(ra) # 800043c0 <holdingsleep>
    80002fa6:	c92d                	beqz	a0,80003018 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fa8:	854a                	mv	a0,s2
    80002faa:	00001097          	auipc	ra,0x1
    80002fae:	3d2080e7          	jalr	978(ra) # 8000437c <releasesleep>

  acquire(&bcache.lock);
    80002fb2:	00014517          	auipc	a0,0x14
    80002fb6:	13650513          	addi	a0,a0,310 # 800170e8 <bcache>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	c2a080e7          	jalr	-982(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002fc2:	40bc                	lw	a5,64(s1)
    80002fc4:	37fd                	addiw	a5,a5,-1
    80002fc6:	0007871b          	sext.w	a4,a5
    80002fca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fcc:	eb05                	bnez	a4,80002ffc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fce:	68bc                	ld	a5,80(s1)
    80002fd0:	64b8                	ld	a4,72(s1)
    80002fd2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fd4:	64bc                	ld	a5,72(s1)
    80002fd6:	68b8                	ld	a4,80(s1)
    80002fd8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fda:	0001c797          	auipc	a5,0x1c
    80002fde:	10e78793          	addi	a5,a5,270 # 8001f0e8 <bcache+0x8000>
    80002fe2:	2b87b703          	ld	a4,696(a5)
    80002fe6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fe8:	0001c717          	auipc	a4,0x1c
    80002fec:	36870713          	addi	a4,a4,872 # 8001f350 <bcache+0x8268>
    80002ff0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ff2:	2b87b703          	ld	a4,696(a5)
    80002ff6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002ff8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	0ec50513          	addi	a0,a0,236 # 800170e8 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	c94080e7          	jalr	-876(ra) # 80000c98 <release>
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6902                	ld	s2,0(sp)
    80003014:	6105                	addi	sp,sp,32
    80003016:	8082                	ret
    panic("brelse");
    80003018:	00005517          	auipc	a0,0x5
    8000301c:	51050513          	addi	a0,a0,1296 # 80008528 <syscalls+0xe0>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>

0000000080003028 <bpin>:

void
bpin(struct buf *b) {
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	addi	s0,sp,32
    80003032:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003034:	00014517          	auipc	a0,0x14
    80003038:	0b450513          	addi	a0,a0,180 # 800170e8 <bcache>
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	ba8080e7          	jalr	-1112(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003044:	40bc                	lw	a5,64(s1)
    80003046:	2785                	addiw	a5,a5,1
    80003048:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000304a:	00014517          	auipc	a0,0x14
    8000304e:	09e50513          	addi	a0,a0,158 # 800170e8 <bcache>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	c46080e7          	jalr	-954(ra) # 80000c98 <release>
}
    8000305a:	60e2                	ld	ra,24(sp)
    8000305c:	6442                	ld	s0,16(sp)
    8000305e:	64a2                	ld	s1,8(sp)
    80003060:	6105                	addi	sp,sp,32
    80003062:	8082                	ret

0000000080003064 <bunpin>:

void
bunpin(struct buf *b) {
    80003064:	1101                	addi	sp,sp,-32
    80003066:	ec06                	sd	ra,24(sp)
    80003068:	e822                	sd	s0,16(sp)
    8000306a:	e426                	sd	s1,8(sp)
    8000306c:	1000                	addi	s0,sp,32
    8000306e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	07850513          	addi	a0,a0,120 # 800170e8 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	b6c080e7          	jalr	-1172(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003080:	40bc                	lw	a5,64(s1)
    80003082:	37fd                	addiw	a5,a5,-1
    80003084:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003086:	00014517          	auipc	a0,0x14
    8000308a:	06250513          	addi	a0,a0,98 # 800170e8 <bcache>
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	c0a080e7          	jalr	-1014(ra) # 80000c98 <release>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret

00000000800030a0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	e04a                	sd	s2,0(sp)
    800030aa:	1000                	addi	s0,sp,32
    800030ac:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030ae:	00d5d59b          	srliw	a1,a1,0xd
    800030b2:	0001c797          	auipc	a5,0x1c
    800030b6:	7127a783          	lw	a5,1810(a5) # 8001f7c4 <sb+0x1c>
    800030ba:	9dbd                	addw	a1,a1,a5
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	d9e080e7          	jalr	-610(ra) # 80002e5a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030c4:	0074f713          	andi	a4,s1,7
    800030c8:	4785                	li	a5,1
    800030ca:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030ce:	14ce                	slli	s1,s1,0x33
    800030d0:	90d9                	srli	s1,s1,0x36
    800030d2:	00950733          	add	a4,a0,s1
    800030d6:	05874703          	lbu	a4,88(a4)
    800030da:	00e7f6b3          	and	a3,a5,a4
    800030de:	c69d                	beqz	a3,8000310c <bfree+0x6c>
    800030e0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030e2:	94aa                	add	s1,s1,a0
    800030e4:	fff7c793          	not	a5,a5
    800030e8:	8ff9                	and	a5,a5,a4
    800030ea:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030ee:	00001097          	auipc	ra,0x1
    800030f2:	118080e7          	jalr	280(ra) # 80004206 <log_write>
  brelse(bp);
    800030f6:	854a                	mv	a0,s2
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	e92080e7          	jalr	-366(ra) # 80002f8a <brelse>
}
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	64a2                	ld	s1,8(sp)
    80003106:	6902                	ld	s2,0(sp)
    80003108:	6105                	addi	sp,sp,32
    8000310a:	8082                	ret
    panic("freeing free block");
    8000310c:	00005517          	auipc	a0,0x5
    80003110:	42450513          	addi	a0,a0,1060 # 80008530 <syscalls+0xe8>
    80003114:	ffffd097          	auipc	ra,0xffffd
    80003118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>

000000008000311c <balloc>:
{
    8000311c:	711d                	addi	sp,sp,-96
    8000311e:	ec86                	sd	ra,88(sp)
    80003120:	e8a2                	sd	s0,80(sp)
    80003122:	e4a6                	sd	s1,72(sp)
    80003124:	e0ca                	sd	s2,64(sp)
    80003126:	fc4e                	sd	s3,56(sp)
    80003128:	f852                	sd	s4,48(sp)
    8000312a:	f456                	sd	s5,40(sp)
    8000312c:	f05a                	sd	s6,32(sp)
    8000312e:	ec5e                	sd	s7,24(sp)
    80003130:	e862                	sd	s8,16(sp)
    80003132:	e466                	sd	s9,8(sp)
    80003134:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003136:	0001c797          	auipc	a5,0x1c
    8000313a:	6767a783          	lw	a5,1654(a5) # 8001f7ac <sb+0x4>
    8000313e:	cbd1                	beqz	a5,800031d2 <balloc+0xb6>
    80003140:	8baa                	mv	s7,a0
    80003142:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003144:	0001cb17          	auipc	s6,0x1c
    80003148:	664b0b13          	addi	s6,s6,1636 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000314c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000314e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003150:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003152:	6c89                	lui	s9,0x2
    80003154:	a831                	j	80003170 <balloc+0x54>
    brelse(bp);
    80003156:	854a                	mv	a0,s2
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	e32080e7          	jalr	-462(ra) # 80002f8a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003160:	015c87bb          	addw	a5,s9,s5
    80003164:	00078a9b          	sext.w	s5,a5
    80003168:	004b2703          	lw	a4,4(s6)
    8000316c:	06eaf363          	bgeu	s5,a4,800031d2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003170:	41fad79b          	sraiw	a5,s5,0x1f
    80003174:	0137d79b          	srliw	a5,a5,0x13
    80003178:	015787bb          	addw	a5,a5,s5
    8000317c:	40d7d79b          	sraiw	a5,a5,0xd
    80003180:	01cb2583          	lw	a1,28(s6)
    80003184:	9dbd                	addw	a1,a1,a5
    80003186:	855e                	mv	a0,s7
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	cd2080e7          	jalr	-814(ra) # 80002e5a <bread>
    80003190:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003192:	004b2503          	lw	a0,4(s6)
    80003196:	000a849b          	sext.w	s1,s5
    8000319a:	8662                	mv	a2,s8
    8000319c:	faa4fde3          	bgeu	s1,a0,80003156 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031a0:	41f6579b          	sraiw	a5,a2,0x1f
    800031a4:	01d7d69b          	srliw	a3,a5,0x1d
    800031a8:	00c6873b          	addw	a4,a3,a2
    800031ac:	00777793          	andi	a5,a4,7
    800031b0:	9f95                	subw	a5,a5,a3
    800031b2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031b6:	4037571b          	sraiw	a4,a4,0x3
    800031ba:	00e906b3          	add	a3,s2,a4
    800031be:	0586c683          	lbu	a3,88(a3)
    800031c2:	00d7f5b3          	and	a1,a5,a3
    800031c6:	cd91                	beqz	a1,800031e2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c8:	2605                	addiw	a2,a2,1
    800031ca:	2485                	addiw	s1,s1,1
    800031cc:	fd4618e3          	bne	a2,s4,8000319c <balloc+0x80>
    800031d0:	b759                	j	80003156 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031d2:	00005517          	auipc	a0,0x5
    800031d6:	37650513          	addi	a0,a0,886 # 80008548 <syscalls+0x100>
    800031da:	ffffd097          	auipc	ra,0xffffd
    800031de:	364080e7          	jalr	868(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031e2:	974a                	add	a4,a4,s2
    800031e4:	8fd5                	or	a5,a5,a3
    800031e6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031ea:	854a                	mv	a0,s2
    800031ec:	00001097          	auipc	ra,0x1
    800031f0:	01a080e7          	jalr	26(ra) # 80004206 <log_write>
        brelse(bp);
    800031f4:	854a                	mv	a0,s2
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	d94080e7          	jalr	-620(ra) # 80002f8a <brelse>
  bp = bread(dev, bno);
    800031fe:	85a6                	mv	a1,s1
    80003200:	855e                	mv	a0,s7
    80003202:	00000097          	auipc	ra,0x0
    80003206:	c58080e7          	jalr	-936(ra) # 80002e5a <bread>
    8000320a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000320c:	40000613          	li	a2,1024
    80003210:	4581                	li	a1,0
    80003212:	05850513          	addi	a0,a0,88
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	aca080e7          	jalr	-1334(ra) # 80000ce0 <memset>
  log_write(bp);
    8000321e:	854a                	mv	a0,s2
    80003220:	00001097          	auipc	ra,0x1
    80003224:	fe6080e7          	jalr	-26(ra) # 80004206 <log_write>
  brelse(bp);
    80003228:	854a                	mv	a0,s2
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	d60080e7          	jalr	-672(ra) # 80002f8a <brelse>
}
    80003232:	8526                	mv	a0,s1
    80003234:	60e6                	ld	ra,88(sp)
    80003236:	6446                	ld	s0,80(sp)
    80003238:	64a6                	ld	s1,72(sp)
    8000323a:	6906                	ld	s2,64(sp)
    8000323c:	79e2                	ld	s3,56(sp)
    8000323e:	7a42                	ld	s4,48(sp)
    80003240:	7aa2                	ld	s5,40(sp)
    80003242:	7b02                	ld	s6,32(sp)
    80003244:	6be2                	ld	s7,24(sp)
    80003246:	6c42                	ld	s8,16(sp)
    80003248:	6ca2                	ld	s9,8(sp)
    8000324a:	6125                	addi	sp,sp,96
    8000324c:	8082                	ret

000000008000324e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000324e:	7179                	addi	sp,sp,-48
    80003250:	f406                	sd	ra,40(sp)
    80003252:	f022                	sd	s0,32(sp)
    80003254:	ec26                	sd	s1,24(sp)
    80003256:	e84a                	sd	s2,16(sp)
    80003258:	e44e                	sd	s3,8(sp)
    8000325a:	e052                	sd	s4,0(sp)
    8000325c:	1800                	addi	s0,sp,48
    8000325e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003260:	47ad                	li	a5,11
    80003262:	04b7fe63          	bgeu	a5,a1,800032be <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003266:	ff45849b          	addiw	s1,a1,-12
    8000326a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000326e:	0ff00793          	li	a5,255
    80003272:	0ae7e363          	bltu	a5,a4,80003318 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003276:	08052583          	lw	a1,128(a0)
    8000327a:	c5ad                	beqz	a1,800032e4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000327c:	00092503          	lw	a0,0(s2)
    80003280:	00000097          	auipc	ra,0x0
    80003284:	bda080e7          	jalr	-1062(ra) # 80002e5a <bread>
    80003288:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000328a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000328e:	02049593          	slli	a1,s1,0x20
    80003292:	9181                	srli	a1,a1,0x20
    80003294:	058a                	slli	a1,a1,0x2
    80003296:	00b784b3          	add	s1,a5,a1
    8000329a:	0004a983          	lw	s3,0(s1)
    8000329e:	04098d63          	beqz	s3,800032f8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032a2:	8552                	mv	a0,s4
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	ce6080e7          	jalr	-794(ra) # 80002f8a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032ac:	854e                	mv	a0,s3
    800032ae:	70a2                	ld	ra,40(sp)
    800032b0:	7402                	ld	s0,32(sp)
    800032b2:	64e2                	ld	s1,24(sp)
    800032b4:	6942                	ld	s2,16(sp)
    800032b6:	69a2                	ld	s3,8(sp)
    800032b8:	6a02                	ld	s4,0(sp)
    800032ba:	6145                	addi	sp,sp,48
    800032bc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032be:	02059493          	slli	s1,a1,0x20
    800032c2:	9081                	srli	s1,s1,0x20
    800032c4:	048a                	slli	s1,s1,0x2
    800032c6:	94aa                	add	s1,s1,a0
    800032c8:	0504a983          	lw	s3,80(s1)
    800032cc:	fe0990e3          	bnez	s3,800032ac <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032d0:	4108                	lw	a0,0(a0)
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	e4a080e7          	jalr	-438(ra) # 8000311c <balloc>
    800032da:	0005099b          	sext.w	s3,a0
    800032de:	0534a823          	sw	s3,80(s1)
    800032e2:	b7e9                	j	800032ac <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032e4:	4108                	lw	a0,0(a0)
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	e36080e7          	jalr	-458(ra) # 8000311c <balloc>
    800032ee:	0005059b          	sext.w	a1,a0
    800032f2:	08b92023          	sw	a1,128(s2)
    800032f6:	b759                	j	8000327c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032f8:	00092503          	lw	a0,0(s2)
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	e20080e7          	jalr	-480(ra) # 8000311c <balloc>
    80003304:	0005099b          	sext.w	s3,a0
    80003308:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000330c:	8552                	mv	a0,s4
    8000330e:	00001097          	auipc	ra,0x1
    80003312:	ef8080e7          	jalr	-264(ra) # 80004206 <log_write>
    80003316:	b771                	j	800032a2 <bmap+0x54>
  panic("bmap: out of range");
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	24850513          	addi	a0,a0,584 # 80008560 <syscalls+0x118>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	21e080e7          	jalr	542(ra) # 8000053e <panic>

0000000080003328 <iget>:
{
    80003328:	7179                	addi	sp,sp,-48
    8000332a:	f406                	sd	ra,40(sp)
    8000332c:	f022                	sd	s0,32(sp)
    8000332e:	ec26                	sd	s1,24(sp)
    80003330:	e84a                	sd	s2,16(sp)
    80003332:	e44e                	sd	s3,8(sp)
    80003334:	e052                	sd	s4,0(sp)
    80003336:	1800                	addi	s0,sp,48
    80003338:	89aa                	mv	s3,a0
    8000333a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000333c:	0001c517          	auipc	a0,0x1c
    80003340:	48c50513          	addi	a0,a0,1164 # 8001f7c8 <itable>
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	8a0080e7          	jalr	-1888(ra) # 80000be4 <acquire>
  empty = 0;
    8000334c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000334e:	0001c497          	auipc	s1,0x1c
    80003352:	49248493          	addi	s1,s1,1170 # 8001f7e0 <itable+0x18>
    80003356:	0001e697          	auipc	a3,0x1e
    8000335a:	f1a68693          	addi	a3,a3,-230 # 80021270 <log>
    8000335e:	a039                	j	8000336c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003360:	02090b63          	beqz	s2,80003396 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003364:	08848493          	addi	s1,s1,136
    80003368:	02d48a63          	beq	s1,a3,8000339c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000336c:	449c                	lw	a5,8(s1)
    8000336e:	fef059e3          	blez	a5,80003360 <iget+0x38>
    80003372:	4098                	lw	a4,0(s1)
    80003374:	ff3716e3          	bne	a4,s3,80003360 <iget+0x38>
    80003378:	40d8                	lw	a4,4(s1)
    8000337a:	ff4713e3          	bne	a4,s4,80003360 <iget+0x38>
      ip->ref++;
    8000337e:	2785                	addiw	a5,a5,1
    80003380:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003382:	0001c517          	auipc	a0,0x1c
    80003386:	44650513          	addi	a0,a0,1094 # 8001f7c8 <itable>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	90e080e7          	jalr	-1778(ra) # 80000c98 <release>
      return ip;
    80003392:	8926                	mv	s2,s1
    80003394:	a03d                	j	800033c2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003396:	f7f9                	bnez	a5,80003364 <iget+0x3c>
    80003398:	8926                	mv	s2,s1
    8000339a:	b7e9                	j	80003364 <iget+0x3c>
  if(empty == 0)
    8000339c:	02090c63          	beqz	s2,800033d4 <iget+0xac>
  ip->dev = dev;
    800033a0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033a4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033a8:	4785                	li	a5,1
    800033aa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033ae:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033b2:	0001c517          	auipc	a0,0x1c
    800033b6:	41650513          	addi	a0,a0,1046 # 8001f7c8 <itable>
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	8de080e7          	jalr	-1826(ra) # 80000c98 <release>
}
    800033c2:	854a                	mv	a0,s2
    800033c4:	70a2                	ld	ra,40(sp)
    800033c6:	7402                	ld	s0,32(sp)
    800033c8:	64e2                	ld	s1,24(sp)
    800033ca:	6942                	ld	s2,16(sp)
    800033cc:	69a2                	ld	s3,8(sp)
    800033ce:	6a02                	ld	s4,0(sp)
    800033d0:	6145                	addi	sp,sp,48
    800033d2:	8082                	ret
    panic("iget: no inodes");
    800033d4:	00005517          	auipc	a0,0x5
    800033d8:	1a450513          	addi	a0,a0,420 # 80008578 <syscalls+0x130>
    800033dc:	ffffd097          	auipc	ra,0xffffd
    800033e0:	162080e7          	jalr	354(ra) # 8000053e <panic>

00000000800033e4 <fsinit>:
fsinit(int dev) {
    800033e4:	7179                	addi	sp,sp,-48
    800033e6:	f406                	sd	ra,40(sp)
    800033e8:	f022                	sd	s0,32(sp)
    800033ea:	ec26                	sd	s1,24(sp)
    800033ec:	e84a                	sd	s2,16(sp)
    800033ee:	e44e                	sd	s3,8(sp)
    800033f0:	1800                	addi	s0,sp,48
    800033f2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033f4:	4585                	li	a1,1
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	a64080e7          	jalr	-1436(ra) # 80002e5a <bread>
    800033fe:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003400:	0001c997          	auipc	s3,0x1c
    80003404:	3a898993          	addi	s3,s3,936 # 8001f7a8 <sb>
    80003408:	02000613          	li	a2,32
    8000340c:	05850593          	addi	a1,a0,88
    80003410:	854e                	mv	a0,s3
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	92e080e7          	jalr	-1746(ra) # 80000d40 <memmove>
  brelse(bp);
    8000341a:	8526                	mv	a0,s1
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	b6e080e7          	jalr	-1170(ra) # 80002f8a <brelse>
  if(sb.magic != FSMAGIC)
    80003424:	0009a703          	lw	a4,0(s3)
    80003428:	102037b7          	lui	a5,0x10203
    8000342c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003430:	02f71263          	bne	a4,a5,80003454 <fsinit+0x70>
  initlog(dev, &sb);
    80003434:	0001c597          	auipc	a1,0x1c
    80003438:	37458593          	addi	a1,a1,884 # 8001f7a8 <sb>
    8000343c:	854a                	mv	a0,s2
    8000343e:	00001097          	auipc	ra,0x1
    80003442:	b4c080e7          	jalr	-1204(ra) # 80003f8a <initlog>
}
    80003446:	70a2                	ld	ra,40(sp)
    80003448:	7402                	ld	s0,32(sp)
    8000344a:	64e2                	ld	s1,24(sp)
    8000344c:	6942                	ld	s2,16(sp)
    8000344e:	69a2                	ld	s3,8(sp)
    80003450:	6145                	addi	sp,sp,48
    80003452:	8082                	ret
    panic("invalid file system");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	13450513          	addi	a0,a0,308 # 80008588 <syscalls+0x140>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>

0000000080003464 <iinit>:
{
    80003464:	7179                	addi	sp,sp,-48
    80003466:	f406                	sd	ra,40(sp)
    80003468:	f022                	sd	s0,32(sp)
    8000346a:	ec26                	sd	s1,24(sp)
    8000346c:	e84a                	sd	s2,16(sp)
    8000346e:	e44e                	sd	s3,8(sp)
    80003470:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003472:	00005597          	auipc	a1,0x5
    80003476:	12e58593          	addi	a1,a1,302 # 800085a0 <syscalls+0x158>
    8000347a:	0001c517          	auipc	a0,0x1c
    8000347e:	34e50513          	addi	a0,a0,846 # 8001f7c8 <itable>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	6d2080e7          	jalr	1746(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000348a:	0001c497          	auipc	s1,0x1c
    8000348e:	36648493          	addi	s1,s1,870 # 8001f7f0 <itable+0x28>
    80003492:	0001e997          	auipc	s3,0x1e
    80003496:	dee98993          	addi	s3,s3,-530 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000349a:	00005917          	auipc	s2,0x5
    8000349e:	10e90913          	addi	s2,s2,270 # 800085a8 <syscalls+0x160>
    800034a2:	85ca                	mv	a1,s2
    800034a4:	8526                	mv	a0,s1
    800034a6:	00001097          	auipc	ra,0x1
    800034aa:	e46080e7          	jalr	-442(ra) # 800042ec <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034ae:	08848493          	addi	s1,s1,136
    800034b2:	ff3498e3          	bne	s1,s3,800034a2 <iinit+0x3e>
}
    800034b6:	70a2                	ld	ra,40(sp)
    800034b8:	7402                	ld	s0,32(sp)
    800034ba:	64e2                	ld	s1,24(sp)
    800034bc:	6942                	ld	s2,16(sp)
    800034be:	69a2                	ld	s3,8(sp)
    800034c0:	6145                	addi	sp,sp,48
    800034c2:	8082                	ret

00000000800034c4 <ialloc>:
{
    800034c4:	715d                	addi	sp,sp,-80
    800034c6:	e486                	sd	ra,72(sp)
    800034c8:	e0a2                	sd	s0,64(sp)
    800034ca:	fc26                	sd	s1,56(sp)
    800034cc:	f84a                	sd	s2,48(sp)
    800034ce:	f44e                	sd	s3,40(sp)
    800034d0:	f052                	sd	s4,32(sp)
    800034d2:	ec56                	sd	s5,24(sp)
    800034d4:	e85a                	sd	s6,16(sp)
    800034d6:	e45e                	sd	s7,8(sp)
    800034d8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034da:	0001c717          	auipc	a4,0x1c
    800034de:	2da72703          	lw	a4,730(a4) # 8001f7b4 <sb+0xc>
    800034e2:	4785                	li	a5,1
    800034e4:	04e7fa63          	bgeu	a5,a4,80003538 <ialloc+0x74>
    800034e8:	8aaa                	mv	s5,a0
    800034ea:	8bae                	mv	s7,a1
    800034ec:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034ee:	0001ca17          	auipc	s4,0x1c
    800034f2:	2baa0a13          	addi	s4,s4,698 # 8001f7a8 <sb>
    800034f6:	00048b1b          	sext.w	s6,s1
    800034fa:	0044d593          	srli	a1,s1,0x4
    800034fe:	018a2783          	lw	a5,24(s4)
    80003502:	9dbd                	addw	a1,a1,a5
    80003504:	8556                	mv	a0,s5
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	954080e7          	jalr	-1708(ra) # 80002e5a <bread>
    8000350e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003510:	05850993          	addi	s3,a0,88
    80003514:	00f4f793          	andi	a5,s1,15
    80003518:	079a                	slli	a5,a5,0x6
    8000351a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000351c:	00099783          	lh	a5,0(s3)
    80003520:	c785                	beqz	a5,80003548 <ialloc+0x84>
    brelse(bp);
    80003522:	00000097          	auipc	ra,0x0
    80003526:	a68080e7          	jalr	-1432(ra) # 80002f8a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000352a:	0485                	addi	s1,s1,1
    8000352c:	00ca2703          	lw	a4,12(s4)
    80003530:	0004879b          	sext.w	a5,s1
    80003534:	fce7e1e3          	bltu	a5,a4,800034f6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003538:	00005517          	auipc	a0,0x5
    8000353c:	07850513          	addi	a0,a0,120 # 800085b0 <syscalls+0x168>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003548:	04000613          	li	a2,64
    8000354c:	4581                	li	a1,0
    8000354e:	854e                	mv	a0,s3
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	790080e7          	jalr	1936(ra) # 80000ce0 <memset>
      dip->type = type;
    80003558:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000355c:	854a                	mv	a0,s2
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	ca8080e7          	jalr	-856(ra) # 80004206 <log_write>
      brelse(bp);
    80003566:	854a                	mv	a0,s2
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	a22080e7          	jalr	-1502(ra) # 80002f8a <brelse>
      return iget(dev, inum);
    80003570:	85da                	mv	a1,s6
    80003572:	8556                	mv	a0,s5
    80003574:	00000097          	auipc	ra,0x0
    80003578:	db4080e7          	jalr	-588(ra) # 80003328 <iget>
}
    8000357c:	60a6                	ld	ra,72(sp)
    8000357e:	6406                	ld	s0,64(sp)
    80003580:	74e2                	ld	s1,56(sp)
    80003582:	7942                	ld	s2,48(sp)
    80003584:	79a2                	ld	s3,40(sp)
    80003586:	7a02                	ld	s4,32(sp)
    80003588:	6ae2                	ld	s5,24(sp)
    8000358a:	6b42                	ld	s6,16(sp)
    8000358c:	6ba2                	ld	s7,8(sp)
    8000358e:	6161                	addi	sp,sp,80
    80003590:	8082                	ret

0000000080003592 <iupdate>:
{
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	e426                	sd	s1,8(sp)
    8000359a:	e04a                	sd	s2,0(sp)
    8000359c:	1000                	addi	s0,sp,32
    8000359e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035a0:	415c                	lw	a5,4(a0)
    800035a2:	0047d79b          	srliw	a5,a5,0x4
    800035a6:	0001c597          	auipc	a1,0x1c
    800035aa:	21a5a583          	lw	a1,538(a1) # 8001f7c0 <sb+0x18>
    800035ae:	9dbd                	addw	a1,a1,a5
    800035b0:	4108                	lw	a0,0(a0)
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	8a8080e7          	jalr	-1880(ra) # 80002e5a <bread>
    800035ba:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035bc:	05850793          	addi	a5,a0,88
    800035c0:	40c8                	lw	a0,4(s1)
    800035c2:	893d                	andi	a0,a0,15
    800035c4:	051a                	slli	a0,a0,0x6
    800035c6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035c8:	04449703          	lh	a4,68(s1)
    800035cc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035d0:	04649703          	lh	a4,70(s1)
    800035d4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035d8:	04849703          	lh	a4,72(s1)
    800035dc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035e0:	04a49703          	lh	a4,74(s1)
    800035e4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035e8:	44f8                	lw	a4,76(s1)
    800035ea:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035ec:	03400613          	li	a2,52
    800035f0:	05048593          	addi	a1,s1,80
    800035f4:	0531                	addi	a0,a0,12
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	74a080e7          	jalr	1866(ra) # 80000d40 <memmove>
  log_write(bp);
    800035fe:	854a                	mv	a0,s2
    80003600:	00001097          	auipc	ra,0x1
    80003604:	c06080e7          	jalr	-1018(ra) # 80004206 <log_write>
  brelse(bp);
    80003608:	854a                	mv	a0,s2
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	980080e7          	jalr	-1664(ra) # 80002f8a <brelse>
}
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6902                	ld	s2,0(sp)
    8000361a:	6105                	addi	sp,sp,32
    8000361c:	8082                	ret

000000008000361e <idup>:
{
    8000361e:	1101                	addi	sp,sp,-32
    80003620:	ec06                	sd	ra,24(sp)
    80003622:	e822                	sd	s0,16(sp)
    80003624:	e426                	sd	s1,8(sp)
    80003626:	1000                	addi	s0,sp,32
    80003628:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000362a:	0001c517          	auipc	a0,0x1c
    8000362e:	19e50513          	addi	a0,a0,414 # 8001f7c8 <itable>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	5b2080e7          	jalr	1458(ra) # 80000be4 <acquire>
  ip->ref++;
    8000363a:	449c                	lw	a5,8(s1)
    8000363c:	2785                	addiw	a5,a5,1
    8000363e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003640:	0001c517          	auipc	a0,0x1c
    80003644:	18850513          	addi	a0,a0,392 # 8001f7c8 <itable>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	650080e7          	jalr	1616(ra) # 80000c98 <release>
}
    80003650:	8526                	mv	a0,s1
    80003652:	60e2                	ld	ra,24(sp)
    80003654:	6442                	ld	s0,16(sp)
    80003656:	64a2                	ld	s1,8(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret

000000008000365c <ilock>:
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	e04a                	sd	s2,0(sp)
    80003666:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003668:	c115                	beqz	a0,8000368c <ilock+0x30>
    8000366a:	84aa                	mv	s1,a0
    8000366c:	451c                	lw	a5,8(a0)
    8000366e:	00f05f63          	blez	a5,8000368c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003672:	0541                	addi	a0,a0,16
    80003674:	00001097          	auipc	ra,0x1
    80003678:	cb2080e7          	jalr	-846(ra) # 80004326 <acquiresleep>
  if(ip->valid == 0){
    8000367c:	40bc                	lw	a5,64(s1)
    8000367e:	cf99                	beqz	a5,8000369c <ilock+0x40>
}
    80003680:	60e2                	ld	ra,24(sp)
    80003682:	6442                	ld	s0,16(sp)
    80003684:	64a2                	ld	s1,8(sp)
    80003686:	6902                	ld	s2,0(sp)
    80003688:	6105                	addi	sp,sp,32
    8000368a:	8082                	ret
    panic("ilock");
    8000368c:	00005517          	auipc	a0,0x5
    80003690:	f3c50513          	addi	a0,a0,-196 # 800085c8 <syscalls+0x180>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	eaa080e7          	jalr	-342(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000369c:	40dc                	lw	a5,4(s1)
    8000369e:	0047d79b          	srliw	a5,a5,0x4
    800036a2:	0001c597          	auipc	a1,0x1c
    800036a6:	11e5a583          	lw	a1,286(a1) # 8001f7c0 <sb+0x18>
    800036aa:	9dbd                	addw	a1,a1,a5
    800036ac:	4088                	lw	a0,0(s1)
    800036ae:	fffff097          	auipc	ra,0xfffff
    800036b2:	7ac080e7          	jalr	1964(ra) # 80002e5a <bread>
    800036b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b8:	05850593          	addi	a1,a0,88
    800036bc:	40dc                	lw	a5,4(s1)
    800036be:	8bbd                	andi	a5,a5,15
    800036c0:	079a                	slli	a5,a5,0x6
    800036c2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036c4:	00059783          	lh	a5,0(a1)
    800036c8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036cc:	00259783          	lh	a5,2(a1)
    800036d0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036d4:	00459783          	lh	a5,4(a1)
    800036d8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036dc:	00659783          	lh	a5,6(a1)
    800036e0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036e4:	459c                	lw	a5,8(a1)
    800036e6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036e8:	03400613          	li	a2,52
    800036ec:	05b1                	addi	a1,a1,12
    800036ee:	05048513          	addi	a0,s1,80
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	64e080e7          	jalr	1614(ra) # 80000d40 <memmove>
    brelse(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	88e080e7          	jalr	-1906(ra) # 80002f8a <brelse>
    ip->valid = 1;
    80003704:	4785                	li	a5,1
    80003706:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003708:	04449783          	lh	a5,68(s1)
    8000370c:	fbb5                	bnez	a5,80003680 <ilock+0x24>
      panic("ilock: no type");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	ec250513          	addi	a0,a0,-318 # 800085d0 <syscalls+0x188>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>

000000008000371e <iunlock>:
{
    8000371e:	1101                	addi	sp,sp,-32
    80003720:	ec06                	sd	ra,24(sp)
    80003722:	e822                	sd	s0,16(sp)
    80003724:	e426                	sd	s1,8(sp)
    80003726:	e04a                	sd	s2,0(sp)
    80003728:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000372a:	c905                	beqz	a0,8000375a <iunlock+0x3c>
    8000372c:	84aa                	mv	s1,a0
    8000372e:	01050913          	addi	s2,a0,16
    80003732:	854a                	mv	a0,s2
    80003734:	00001097          	auipc	ra,0x1
    80003738:	c8c080e7          	jalr	-884(ra) # 800043c0 <holdingsleep>
    8000373c:	cd19                	beqz	a0,8000375a <iunlock+0x3c>
    8000373e:	449c                	lw	a5,8(s1)
    80003740:	00f05d63          	blez	a5,8000375a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003744:	854a                	mv	a0,s2
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	c36080e7          	jalr	-970(ra) # 8000437c <releasesleep>
}
    8000374e:	60e2                	ld	ra,24(sp)
    80003750:	6442                	ld	s0,16(sp)
    80003752:	64a2                	ld	s1,8(sp)
    80003754:	6902                	ld	s2,0(sp)
    80003756:	6105                	addi	sp,sp,32
    80003758:	8082                	ret
    panic("iunlock");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	e8650513          	addi	a0,a0,-378 # 800085e0 <syscalls+0x198>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	ddc080e7          	jalr	-548(ra) # 8000053e <panic>

000000008000376a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000376a:	7179                	addi	sp,sp,-48
    8000376c:	f406                	sd	ra,40(sp)
    8000376e:	f022                	sd	s0,32(sp)
    80003770:	ec26                	sd	s1,24(sp)
    80003772:	e84a                	sd	s2,16(sp)
    80003774:	e44e                	sd	s3,8(sp)
    80003776:	e052                	sd	s4,0(sp)
    80003778:	1800                	addi	s0,sp,48
    8000377a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000377c:	05050493          	addi	s1,a0,80
    80003780:	08050913          	addi	s2,a0,128
    80003784:	a021                	j	8000378c <itrunc+0x22>
    80003786:	0491                	addi	s1,s1,4
    80003788:	01248d63          	beq	s1,s2,800037a2 <itrunc+0x38>
    if(ip->addrs[i]){
    8000378c:	408c                	lw	a1,0(s1)
    8000378e:	dde5                	beqz	a1,80003786 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003790:	0009a503          	lw	a0,0(s3)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	90c080e7          	jalr	-1780(ra) # 800030a0 <bfree>
      ip->addrs[i] = 0;
    8000379c:	0004a023          	sw	zero,0(s1)
    800037a0:	b7dd                	j	80003786 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037a2:	0809a583          	lw	a1,128(s3)
    800037a6:	e185                	bnez	a1,800037c6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037a8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037ac:	854e                	mv	a0,s3
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	de4080e7          	jalr	-540(ra) # 80003592 <iupdate>
}
    800037b6:	70a2                	ld	ra,40(sp)
    800037b8:	7402                	ld	s0,32(sp)
    800037ba:	64e2                	ld	s1,24(sp)
    800037bc:	6942                	ld	s2,16(sp)
    800037be:	69a2                	ld	s3,8(sp)
    800037c0:	6a02                	ld	s4,0(sp)
    800037c2:	6145                	addi	sp,sp,48
    800037c4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037c6:	0009a503          	lw	a0,0(s3)
    800037ca:	fffff097          	auipc	ra,0xfffff
    800037ce:	690080e7          	jalr	1680(ra) # 80002e5a <bread>
    800037d2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037d4:	05850493          	addi	s1,a0,88
    800037d8:	45850913          	addi	s2,a0,1112
    800037dc:	a811                	j	800037f0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037de:	0009a503          	lw	a0,0(s3)
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	8be080e7          	jalr	-1858(ra) # 800030a0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037ea:	0491                	addi	s1,s1,4
    800037ec:	01248563          	beq	s1,s2,800037f6 <itrunc+0x8c>
      if(a[j])
    800037f0:	408c                	lw	a1,0(s1)
    800037f2:	dde5                	beqz	a1,800037ea <itrunc+0x80>
    800037f4:	b7ed                	j	800037de <itrunc+0x74>
    brelse(bp);
    800037f6:	8552                	mv	a0,s4
    800037f8:	fffff097          	auipc	ra,0xfffff
    800037fc:	792080e7          	jalr	1938(ra) # 80002f8a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003800:	0809a583          	lw	a1,128(s3)
    80003804:	0009a503          	lw	a0,0(s3)
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	898080e7          	jalr	-1896(ra) # 800030a0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003810:	0809a023          	sw	zero,128(s3)
    80003814:	bf51                	j	800037a8 <itrunc+0x3e>

0000000080003816 <iput>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	e04a                	sd	s2,0(sp)
    80003820:	1000                	addi	s0,sp,32
    80003822:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	fa450513          	addi	a0,a0,-92 # 8001f7c8 <itable>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	3b8080e7          	jalr	952(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003834:	4498                	lw	a4,8(s1)
    80003836:	4785                	li	a5,1
    80003838:	02f70363          	beq	a4,a5,8000385e <iput+0x48>
  ip->ref--;
    8000383c:	449c                	lw	a5,8(s1)
    8000383e:	37fd                	addiw	a5,a5,-1
    80003840:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003842:	0001c517          	auipc	a0,0x1c
    80003846:	f8650513          	addi	a0,a0,-122 # 8001f7c8 <itable>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	44e080e7          	jalr	1102(ra) # 80000c98 <release>
}
    80003852:	60e2                	ld	ra,24(sp)
    80003854:	6442                	ld	s0,16(sp)
    80003856:	64a2                	ld	s1,8(sp)
    80003858:	6902                	ld	s2,0(sp)
    8000385a:	6105                	addi	sp,sp,32
    8000385c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000385e:	40bc                	lw	a5,64(s1)
    80003860:	dff1                	beqz	a5,8000383c <iput+0x26>
    80003862:	04a49783          	lh	a5,74(s1)
    80003866:	fbf9                	bnez	a5,8000383c <iput+0x26>
    acquiresleep(&ip->lock);
    80003868:	01048913          	addi	s2,s1,16
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	ab8080e7          	jalr	-1352(ra) # 80004326 <acquiresleep>
    release(&itable.lock);
    80003876:	0001c517          	auipc	a0,0x1c
    8000387a:	f5250513          	addi	a0,a0,-174 # 8001f7c8 <itable>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	41a080e7          	jalr	1050(ra) # 80000c98 <release>
    itrunc(ip);
    80003886:	8526                	mv	a0,s1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	ee2080e7          	jalr	-286(ra) # 8000376a <itrunc>
    ip->type = 0;
    80003890:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003894:	8526                	mv	a0,s1
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	cfc080e7          	jalr	-772(ra) # 80003592 <iupdate>
    ip->valid = 0;
    8000389e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	ad8080e7          	jalr	-1320(ra) # 8000437c <releasesleep>
    acquire(&itable.lock);
    800038ac:	0001c517          	auipc	a0,0x1c
    800038b0:	f1c50513          	addi	a0,a0,-228 # 8001f7c8 <itable>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	330080e7          	jalr	816(ra) # 80000be4 <acquire>
    800038bc:	b741                	j	8000383c <iput+0x26>

00000000800038be <iunlockput>:
{
    800038be:	1101                	addi	sp,sp,-32
    800038c0:	ec06                	sd	ra,24(sp)
    800038c2:	e822                	sd	s0,16(sp)
    800038c4:	e426                	sd	s1,8(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  iunlock(ip);
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	e54080e7          	jalr	-428(ra) # 8000371e <iunlock>
  iput(ip);
    800038d2:	8526                	mv	a0,s1
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	f42080e7          	jalr	-190(ra) # 80003816 <iput>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret

00000000800038e6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038e6:	1141                	addi	sp,sp,-16
    800038e8:	e422                	sd	s0,8(sp)
    800038ea:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038ec:	411c                	lw	a5,0(a0)
    800038ee:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038f0:	415c                	lw	a5,4(a0)
    800038f2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038f4:	04451783          	lh	a5,68(a0)
    800038f8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038fc:	04a51783          	lh	a5,74(a0)
    80003900:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003904:	04c56783          	lwu	a5,76(a0)
    80003908:	e99c                	sd	a5,16(a1)
}
    8000390a:	6422                	ld	s0,8(sp)
    8000390c:	0141                	addi	sp,sp,16
    8000390e:	8082                	ret

0000000080003910 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003910:	457c                	lw	a5,76(a0)
    80003912:	0ed7e963          	bltu	a5,a3,80003a04 <readi+0xf4>
{
    80003916:	7159                	addi	sp,sp,-112
    80003918:	f486                	sd	ra,104(sp)
    8000391a:	f0a2                	sd	s0,96(sp)
    8000391c:	eca6                	sd	s1,88(sp)
    8000391e:	e8ca                	sd	s2,80(sp)
    80003920:	e4ce                	sd	s3,72(sp)
    80003922:	e0d2                	sd	s4,64(sp)
    80003924:	fc56                	sd	s5,56(sp)
    80003926:	f85a                	sd	s6,48(sp)
    80003928:	f45e                	sd	s7,40(sp)
    8000392a:	f062                	sd	s8,32(sp)
    8000392c:	ec66                	sd	s9,24(sp)
    8000392e:	e86a                	sd	s10,16(sp)
    80003930:	e46e                	sd	s11,8(sp)
    80003932:	1880                	addi	s0,sp,112
    80003934:	8baa                	mv	s7,a0
    80003936:	8c2e                	mv	s8,a1
    80003938:	8ab2                	mv	s5,a2
    8000393a:	84b6                	mv	s1,a3
    8000393c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000393e:	9f35                	addw	a4,a4,a3
    return 0;
    80003940:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003942:	0ad76063          	bltu	a4,a3,800039e2 <readi+0xd2>
  if(off + n > ip->size)
    80003946:	00e7f463          	bgeu	a5,a4,8000394e <readi+0x3e>
    n = ip->size - off;
    8000394a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000394e:	0a0b0963          	beqz	s6,80003a00 <readi+0xf0>
    80003952:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003954:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003958:	5cfd                	li	s9,-1
    8000395a:	a82d                	j	80003994 <readi+0x84>
    8000395c:	020a1d93          	slli	s11,s4,0x20
    80003960:	020ddd93          	srli	s11,s11,0x20
    80003964:	05890613          	addi	a2,s2,88
    80003968:	86ee                	mv	a3,s11
    8000396a:	963a                	add	a2,a2,a4
    8000396c:	85d6                	mv	a1,s5
    8000396e:	8562                	mv	a0,s8
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	ae4080e7          	jalr	-1308(ra) # 80002454 <either_copyout>
    80003978:	05950d63          	beq	a0,s9,800039d2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000397c:	854a                	mv	a0,s2
    8000397e:	fffff097          	auipc	ra,0xfffff
    80003982:	60c080e7          	jalr	1548(ra) # 80002f8a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003986:	013a09bb          	addw	s3,s4,s3
    8000398a:	009a04bb          	addw	s1,s4,s1
    8000398e:	9aee                	add	s5,s5,s11
    80003990:	0569f763          	bgeu	s3,s6,800039de <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003994:	000ba903          	lw	s2,0(s7)
    80003998:	00a4d59b          	srliw	a1,s1,0xa
    8000399c:	855e                	mv	a0,s7
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	8b0080e7          	jalr	-1872(ra) # 8000324e <bmap>
    800039a6:	0005059b          	sext.w	a1,a0
    800039aa:	854a                	mv	a0,s2
    800039ac:	fffff097          	auipc	ra,0xfffff
    800039b0:	4ae080e7          	jalr	1198(ra) # 80002e5a <bread>
    800039b4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039b6:	3ff4f713          	andi	a4,s1,1023
    800039ba:	40ed07bb          	subw	a5,s10,a4
    800039be:	413b06bb          	subw	a3,s6,s3
    800039c2:	8a3e                	mv	s4,a5
    800039c4:	2781                	sext.w	a5,a5
    800039c6:	0006861b          	sext.w	a2,a3
    800039ca:	f8f679e3          	bgeu	a2,a5,8000395c <readi+0x4c>
    800039ce:	8a36                	mv	s4,a3
    800039d0:	b771                	j	8000395c <readi+0x4c>
      brelse(bp);
    800039d2:	854a                	mv	a0,s2
    800039d4:	fffff097          	auipc	ra,0xfffff
    800039d8:	5b6080e7          	jalr	1462(ra) # 80002f8a <brelse>
      tot = -1;
    800039dc:	59fd                	li	s3,-1
  }
  return tot;
    800039de:	0009851b          	sext.w	a0,s3
}
    800039e2:	70a6                	ld	ra,104(sp)
    800039e4:	7406                	ld	s0,96(sp)
    800039e6:	64e6                	ld	s1,88(sp)
    800039e8:	6946                	ld	s2,80(sp)
    800039ea:	69a6                	ld	s3,72(sp)
    800039ec:	6a06                	ld	s4,64(sp)
    800039ee:	7ae2                	ld	s5,56(sp)
    800039f0:	7b42                	ld	s6,48(sp)
    800039f2:	7ba2                	ld	s7,40(sp)
    800039f4:	7c02                	ld	s8,32(sp)
    800039f6:	6ce2                	ld	s9,24(sp)
    800039f8:	6d42                	ld	s10,16(sp)
    800039fa:	6da2                	ld	s11,8(sp)
    800039fc:	6165                	addi	sp,sp,112
    800039fe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a00:	89da                	mv	s3,s6
    80003a02:	bff1                	j	800039de <readi+0xce>
    return 0;
    80003a04:	4501                	li	a0,0
}
    80003a06:	8082                	ret

0000000080003a08 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a08:	457c                	lw	a5,76(a0)
    80003a0a:	10d7e863          	bltu	a5,a3,80003b1a <writei+0x112>
{
    80003a0e:	7159                	addi	sp,sp,-112
    80003a10:	f486                	sd	ra,104(sp)
    80003a12:	f0a2                	sd	s0,96(sp)
    80003a14:	eca6                	sd	s1,88(sp)
    80003a16:	e8ca                	sd	s2,80(sp)
    80003a18:	e4ce                	sd	s3,72(sp)
    80003a1a:	e0d2                	sd	s4,64(sp)
    80003a1c:	fc56                	sd	s5,56(sp)
    80003a1e:	f85a                	sd	s6,48(sp)
    80003a20:	f45e                	sd	s7,40(sp)
    80003a22:	f062                	sd	s8,32(sp)
    80003a24:	ec66                	sd	s9,24(sp)
    80003a26:	e86a                	sd	s10,16(sp)
    80003a28:	e46e                	sd	s11,8(sp)
    80003a2a:	1880                	addi	s0,sp,112
    80003a2c:	8b2a                	mv	s6,a0
    80003a2e:	8c2e                	mv	s8,a1
    80003a30:	8ab2                	mv	s5,a2
    80003a32:	8936                	mv	s2,a3
    80003a34:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a36:	00e687bb          	addw	a5,a3,a4
    80003a3a:	0ed7e263          	bltu	a5,a3,80003b1e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a3e:	00043737          	lui	a4,0x43
    80003a42:	0ef76063          	bltu	a4,a5,80003b22 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a46:	0c0b8863          	beqz	s7,80003b16 <writei+0x10e>
    80003a4a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a4c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a50:	5cfd                	li	s9,-1
    80003a52:	a091                	j	80003a96 <writei+0x8e>
    80003a54:	02099d93          	slli	s11,s3,0x20
    80003a58:	020ddd93          	srli	s11,s11,0x20
    80003a5c:	05848513          	addi	a0,s1,88
    80003a60:	86ee                	mv	a3,s11
    80003a62:	8656                	mv	a2,s5
    80003a64:	85e2                	mv	a1,s8
    80003a66:	953a                	add	a0,a0,a4
    80003a68:	fffff097          	auipc	ra,0xfffff
    80003a6c:	a42080e7          	jalr	-1470(ra) # 800024aa <either_copyin>
    80003a70:	07950263          	beq	a0,s9,80003ad4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a74:	8526                	mv	a0,s1
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	790080e7          	jalr	1936(ra) # 80004206 <log_write>
    brelse(bp);
    80003a7e:	8526                	mv	a0,s1
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	50a080e7          	jalr	1290(ra) # 80002f8a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a88:	01498a3b          	addw	s4,s3,s4
    80003a8c:	0129893b          	addw	s2,s3,s2
    80003a90:	9aee                	add	s5,s5,s11
    80003a92:	057a7663          	bgeu	s4,s7,80003ade <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a96:	000b2483          	lw	s1,0(s6)
    80003a9a:	00a9559b          	srliw	a1,s2,0xa
    80003a9e:	855a                	mv	a0,s6
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	7ae080e7          	jalr	1966(ra) # 8000324e <bmap>
    80003aa8:	0005059b          	sext.w	a1,a0
    80003aac:	8526                	mv	a0,s1
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	3ac080e7          	jalr	940(ra) # 80002e5a <bread>
    80003ab6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab8:	3ff97713          	andi	a4,s2,1023
    80003abc:	40ed07bb          	subw	a5,s10,a4
    80003ac0:	414b86bb          	subw	a3,s7,s4
    80003ac4:	89be                	mv	s3,a5
    80003ac6:	2781                	sext.w	a5,a5
    80003ac8:	0006861b          	sext.w	a2,a3
    80003acc:	f8f674e3          	bgeu	a2,a5,80003a54 <writei+0x4c>
    80003ad0:	89b6                	mv	s3,a3
    80003ad2:	b749                	j	80003a54 <writei+0x4c>
      brelse(bp);
    80003ad4:	8526                	mv	a0,s1
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	4b4080e7          	jalr	1204(ra) # 80002f8a <brelse>
  }

  if(off > ip->size)
    80003ade:	04cb2783          	lw	a5,76(s6)
    80003ae2:	0127f463          	bgeu	a5,s2,80003aea <writei+0xe2>
    ip->size = off;
    80003ae6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003aea:	855a                	mv	a0,s6
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	aa6080e7          	jalr	-1370(ra) # 80003592 <iupdate>

  return tot;
    80003af4:	000a051b          	sext.w	a0,s4
}
    80003af8:	70a6                	ld	ra,104(sp)
    80003afa:	7406                	ld	s0,96(sp)
    80003afc:	64e6                	ld	s1,88(sp)
    80003afe:	6946                	ld	s2,80(sp)
    80003b00:	69a6                	ld	s3,72(sp)
    80003b02:	6a06                	ld	s4,64(sp)
    80003b04:	7ae2                	ld	s5,56(sp)
    80003b06:	7b42                	ld	s6,48(sp)
    80003b08:	7ba2                	ld	s7,40(sp)
    80003b0a:	7c02                	ld	s8,32(sp)
    80003b0c:	6ce2                	ld	s9,24(sp)
    80003b0e:	6d42                	ld	s10,16(sp)
    80003b10:	6da2                	ld	s11,8(sp)
    80003b12:	6165                	addi	sp,sp,112
    80003b14:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b16:	8a5e                	mv	s4,s7
    80003b18:	bfc9                	j	80003aea <writei+0xe2>
    return -1;
    80003b1a:	557d                	li	a0,-1
}
    80003b1c:	8082                	ret
    return -1;
    80003b1e:	557d                	li	a0,-1
    80003b20:	bfe1                	j	80003af8 <writei+0xf0>
    return -1;
    80003b22:	557d                	li	a0,-1
    80003b24:	bfd1                	j	80003af8 <writei+0xf0>

0000000080003b26 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b26:	1141                	addi	sp,sp,-16
    80003b28:	e406                	sd	ra,8(sp)
    80003b2a:	e022                	sd	s0,0(sp)
    80003b2c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b2e:	4639                	li	a2,14
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	288080e7          	jalr	648(ra) # 80000db8 <strncmp>
}
    80003b38:	60a2                	ld	ra,8(sp)
    80003b3a:	6402                	ld	s0,0(sp)
    80003b3c:	0141                	addi	sp,sp,16
    80003b3e:	8082                	ret

0000000080003b40 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b40:	7139                	addi	sp,sp,-64
    80003b42:	fc06                	sd	ra,56(sp)
    80003b44:	f822                	sd	s0,48(sp)
    80003b46:	f426                	sd	s1,40(sp)
    80003b48:	f04a                	sd	s2,32(sp)
    80003b4a:	ec4e                	sd	s3,24(sp)
    80003b4c:	e852                	sd	s4,16(sp)
    80003b4e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b50:	04451703          	lh	a4,68(a0)
    80003b54:	4785                	li	a5,1
    80003b56:	00f71a63          	bne	a4,a5,80003b6a <dirlookup+0x2a>
    80003b5a:	892a                	mv	s2,a0
    80003b5c:	89ae                	mv	s3,a1
    80003b5e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b60:	457c                	lw	a5,76(a0)
    80003b62:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b64:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b66:	e79d                	bnez	a5,80003b94 <dirlookup+0x54>
    80003b68:	a8a5                	j	80003be0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b6a:	00005517          	auipc	a0,0x5
    80003b6e:	a7e50513          	addi	a0,a0,-1410 # 800085e8 <syscalls+0x1a0>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	9cc080e7          	jalr	-1588(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b7a:	00005517          	auipc	a0,0x5
    80003b7e:	a8650513          	addi	a0,a0,-1402 # 80008600 <syscalls+0x1b8>
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b8a:	24c1                	addiw	s1,s1,16
    80003b8c:	04c92783          	lw	a5,76(s2)
    80003b90:	04f4f763          	bgeu	s1,a5,80003bde <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b94:	4741                	li	a4,16
    80003b96:	86a6                	mv	a3,s1
    80003b98:	fc040613          	addi	a2,s0,-64
    80003b9c:	4581                	li	a1,0
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	d70080e7          	jalr	-656(ra) # 80003910 <readi>
    80003ba8:	47c1                	li	a5,16
    80003baa:	fcf518e3          	bne	a0,a5,80003b7a <dirlookup+0x3a>
    if(de.inum == 0)
    80003bae:	fc045783          	lhu	a5,-64(s0)
    80003bb2:	dfe1                	beqz	a5,80003b8a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bb4:	fc240593          	addi	a1,s0,-62
    80003bb8:	854e                	mv	a0,s3
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	f6c080e7          	jalr	-148(ra) # 80003b26 <namecmp>
    80003bc2:	f561                	bnez	a0,80003b8a <dirlookup+0x4a>
      if(poff)
    80003bc4:	000a0463          	beqz	s4,80003bcc <dirlookup+0x8c>
        *poff = off;
    80003bc8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bcc:	fc045583          	lhu	a1,-64(s0)
    80003bd0:	00092503          	lw	a0,0(s2)
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	754080e7          	jalr	1876(ra) # 80003328 <iget>
    80003bdc:	a011                	j	80003be0 <dirlookup+0xa0>
  return 0;
    80003bde:	4501                	li	a0,0
}
    80003be0:	70e2                	ld	ra,56(sp)
    80003be2:	7442                	ld	s0,48(sp)
    80003be4:	74a2                	ld	s1,40(sp)
    80003be6:	7902                	ld	s2,32(sp)
    80003be8:	69e2                	ld	s3,24(sp)
    80003bea:	6a42                	ld	s4,16(sp)
    80003bec:	6121                	addi	sp,sp,64
    80003bee:	8082                	ret

0000000080003bf0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bf0:	711d                	addi	sp,sp,-96
    80003bf2:	ec86                	sd	ra,88(sp)
    80003bf4:	e8a2                	sd	s0,80(sp)
    80003bf6:	e4a6                	sd	s1,72(sp)
    80003bf8:	e0ca                	sd	s2,64(sp)
    80003bfa:	fc4e                	sd	s3,56(sp)
    80003bfc:	f852                	sd	s4,48(sp)
    80003bfe:	f456                	sd	s5,40(sp)
    80003c00:	f05a                	sd	s6,32(sp)
    80003c02:	ec5e                	sd	s7,24(sp)
    80003c04:	e862                	sd	s8,16(sp)
    80003c06:	e466                	sd	s9,8(sp)
    80003c08:	1080                	addi	s0,sp,96
    80003c0a:	84aa                	mv	s1,a0
    80003c0c:	8b2e                	mv	s6,a1
    80003c0e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c10:	00054703          	lbu	a4,0(a0)
    80003c14:	02f00793          	li	a5,47
    80003c18:	02f70363          	beq	a4,a5,80003c3e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c1c:	ffffe097          	auipc	ra,0xffffe
    80003c20:	d94080e7          	jalr	-620(ra) # 800019b0 <myproc>
    80003c24:	15053503          	ld	a0,336(a0)
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	9f6080e7          	jalr	-1546(ra) # 8000361e <idup>
    80003c30:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c32:	02f00913          	li	s2,47
  len = path - s;
    80003c36:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c38:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c3a:	4c05                	li	s8,1
    80003c3c:	a865                	j	80003cf4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c3e:	4585                	li	a1,1
    80003c40:	4505                	li	a0,1
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	6e6080e7          	jalr	1766(ra) # 80003328 <iget>
    80003c4a:	89aa                	mv	s3,a0
    80003c4c:	b7dd                	j	80003c32 <namex+0x42>
      iunlockput(ip);
    80003c4e:	854e                	mv	a0,s3
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	c6e080e7          	jalr	-914(ra) # 800038be <iunlockput>
      return 0;
    80003c58:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c5a:	854e                	mv	a0,s3
    80003c5c:	60e6                	ld	ra,88(sp)
    80003c5e:	6446                	ld	s0,80(sp)
    80003c60:	64a6                	ld	s1,72(sp)
    80003c62:	6906                	ld	s2,64(sp)
    80003c64:	79e2                	ld	s3,56(sp)
    80003c66:	7a42                	ld	s4,48(sp)
    80003c68:	7aa2                	ld	s5,40(sp)
    80003c6a:	7b02                	ld	s6,32(sp)
    80003c6c:	6be2                	ld	s7,24(sp)
    80003c6e:	6c42                	ld	s8,16(sp)
    80003c70:	6ca2                	ld	s9,8(sp)
    80003c72:	6125                	addi	sp,sp,96
    80003c74:	8082                	ret
      iunlock(ip);
    80003c76:	854e                	mv	a0,s3
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	aa6080e7          	jalr	-1370(ra) # 8000371e <iunlock>
      return ip;
    80003c80:	bfe9                	j	80003c5a <namex+0x6a>
      iunlockput(ip);
    80003c82:	854e                	mv	a0,s3
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	c3a080e7          	jalr	-966(ra) # 800038be <iunlockput>
      return 0;
    80003c8c:	89d2                	mv	s3,s4
    80003c8e:	b7f1                	j	80003c5a <namex+0x6a>
  len = path - s;
    80003c90:	40b48633          	sub	a2,s1,a1
    80003c94:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c98:	094cd463          	bge	s9,s4,80003d20 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c9c:	4639                	li	a2,14
    80003c9e:	8556                	mv	a0,s5
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	0a0080e7          	jalr	160(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ca8:	0004c783          	lbu	a5,0(s1)
    80003cac:	01279763          	bne	a5,s2,80003cba <namex+0xca>
    path++;
    80003cb0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cb2:	0004c783          	lbu	a5,0(s1)
    80003cb6:	ff278de3          	beq	a5,s2,80003cb0 <namex+0xc0>
    ilock(ip);
    80003cba:	854e                	mv	a0,s3
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	9a0080e7          	jalr	-1632(ra) # 8000365c <ilock>
    if(ip->type != T_DIR){
    80003cc4:	04499783          	lh	a5,68(s3)
    80003cc8:	f98793e3          	bne	a5,s8,80003c4e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ccc:	000b0563          	beqz	s6,80003cd6 <namex+0xe6>
    80003cd0:	0004c783          	lbu	a5,0(s1)
    80003cd4:	d3cd                	beqz	a5,80003c76 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cd6:	865e                	mv	a2,s7
    80003cd8:	85d6                	mv	a1,s5
    80003cda:	854e                	mv	a0,s3
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	e64080e7          	jalr	-412(ra) # 80003b40 <dirlookup>
    80003ce4:	8a2a                	mv	s4,a0
    80003ce6:	dd51                	beqz	a0,80003c82 <namex+0x92>
    iunlockput(ip);
    80003ce8:	854e                	mv	a0,s3
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	bd4080e7          	jalr	-1068(ra) # 800038be <iunlockput>
    ip = next;
    80003cf2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003cf4:	0004c783          	lbu	a5,0(s1)
    80003cf8:	05279763          	bne	a5,s2,80003d46 <namex+0x156>
    path++;
    80003cfc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cfe:	0004c783          	lbu	a5,0(s1)
    80003d02:	ff278de3          	beq	a5,s2,80003cfc <namex+0x10c>
  if(*path == 0)
    80003d06:	c79d                	beqz	a5,80003d34 <namex+0x144>
    path++;
    80003d08:	85a6                	mv	a1,s1
  len = path - s;
    80003d0a:	8a5e                	mv	s4,s7
    80003d0c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0e:	01278963          	beq	a5,s2,80003d20 <namex+0x130>
    80003d12:	dfbd                	beqz	a5,80003c90 <namex+0xa0>
    path++;
    80003d14:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d16:	0004c783          	lbu	a5,0(s1)
    80003d1a:	ff279ce3          	bne	a5,s2,80003d12 <namex+0x122>
    80003d1e:	bf8d                	j	80003c90 <namex+0xa0>
    memmove(name, s, len);
    80003d20:	2601                	sext.w	a2,a2
    80003d22:	8556                	mv	a0,s5
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	01c080e7          	jalr	28(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d2c:	9a56                	add	s4,s4,s5
    80003d2e:	000a0023          	sb	zero,0(s4)
    80003d32:	bf9d                	j	80003ca8 <namex+0xb8>
  if(nameiparent){
    80003d34:	f20b03e3          	beqz	s6,80003c5a <namex+0x6a>
    iput(ip);
    80003d38:	854e                	mv	a0,s3
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	adc080e7          	jalr	-1316(ra) # 80003816 <iput>
    return 0;
    80003d42:	4981                	li	s3,0
    80003d44:	bf19                	j	80003c5a <namex+0x6a>
  if(*path == 0)
    80003d46:	d7fd                	beqz	a5,80003d34 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d48:	0004c783          	lbu	a5,0(s1)
    80003d4c:	85a6                	mv	a1,s1
    80003d4e:	b7d1                	j	80003d12 <namex+0x122>

0000000080003d50 <dirlink>:
{
    80003d50:	7139                	addi	sp,sp,-64
    80003d52:	fc06                	sd	ra,56(sp)
    80003d54:	f822                	sd	s0,48(sp)
    80003d56:	f426                	sd	s1,40(sp)
    80003d58:	f04a                	sd	s2,32(sp)
    80003d5a:	ec4e                	sd	s3,24(sp)
    80003d5c:	e852                	sd	s4,16(sp)
    80003d5e:	0080                	addi	s0,sp,64
    80003d60:	892a                	mv	s2,a0
    80003d62:	8a2e                	mv	s4,a1
    80003d64:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d66:	4601                	li	a2,0
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	dd8080e7          	jalr	-552(ra) # 80003b40 <dirlookup>
    80003d70:	e93d                	bnez	a0,80003de6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d72:	04c92483          	lw	s1,76(s2)
    80003d76:	c49d                	beqz	s1,80003da4 <dirlink+0x54>
    80003d78:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d7a:	4741                	li	a4,16
    80003d7c:	86a6                	mv	a3,s1
    80003d7e:	fc040613          	addi	a2,s0,-64
    80003d82:	4581                	li	a1,0
    80003d84:	854a                	mv	a0,s2
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	b8a080e7          	jalr	-1142(ra) # 80003910 <readi>
    80003d8e:	47c1                	li	a5,16
    80003d90:	06f51163          	bne	a0,a5,80003df2 <dirlink+0xa2>
    if(de.inum == 0)
    80003d94:	fc045783          	lhu	a5,-64(s0)
    80003d98:	c791                	beqz	a5,80003da4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9a:	24c1                	addiw	s1,s1,16
    80003d9c:	04c92783          	lw	a5,76(s2)
    80003da0:	fcf4ede3          	bltu	s1,a5,80003d7a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003da4:	4639                	li	a2,14
    80003da6:	85d2                	mv	a1,s4
    80003da8:	fc240513          	addi	a0,s0,-62
    80003dac:	ffffd097          	auipc	ra,0xffffd
    80003db0:	048080e7          	jalr	72(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003db4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db8:	4741                	li	a4,16
    80003dba:	86a6                	mv	a3,s1
    80003dbc:	fc040613          	addi	a2,s0,-64
    80003dc0:	4581                	li	a1,0
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	c44080e7          	jalr	-956(ra) # 80003a08 <writei>
    80003dcc:	872a                	mv	a4,a0
    80003dce:	47c1                	li	a5,16
  return 0;
    80003dd0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd2:	02f71863          	bne	a4,a5,80003e02 <dirlink+0xb2>
}
    80003dd6:	70e2                	ld	ra,56(sp)
    80003dd8:	7442                	ld	s0,48(sp)
    80003dda:	74a2                	ld	s1,40(sp)
    80003ddc:	7902                	ld	s2,32(sp)
    80003dde:	69e2                	ld	s3,24(sp)
    80003de0:	6a42                	ld	s4,16(sp)
    80003de2:	6121                	addi	sp,sp,64
    80003de4:	8082                	ret
    iput(ip);
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	a30080e7          	jalr	-1488(ra) # 80003816 <iput>
    return -1;
    80003dee:	557d                	li	a0,-1
    80003df0:	b7dd                	j	80003dd6 <dirlink+0x86>
      panic("dirlink read");
    80003df2:	00005517          	auipc	a0,0x5
    80003df6:	81e50513          	addi	a0,a0,-2018 # 80008610 <syscalls+0x1c8>
    80003dfa:	ffffc097          	auipc	ra,0xffffc
    80003dfe:	744080e7          	jalr	1860(ra) # 8000053e <panic>
    panic("dirlink");
    80003e02:	00005517          	auipc	a0,0x5
    80003e06:	91e50513          	addi	a0,a0,-1762 # 80008720 <syscalls+0x2d8>
    80003e0a:	ffffc097          	auipc	ra,0xffffc
    80003e0e:	734080e7          	jalr	1844(ra) # 8000053e <panic>

0000000080003e12 <namei>:

struct inode*
namei(char *path)
{
    80003e12:	1101                	addi	sp,sp,-32
    80003e14:	ec06                	sd	ra,24(sp)
    80003e16:	e822                	sd	s0,16(sp)
    80003e18:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e1a:	fe040613          	addi	a2,s0,-32
    80003e1e:	4581                	li	a1,0
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	dd0080e7          	jalr	-560(ra) # 80003bf0 <namex>
}
    80003e28:	60e2                	ld	ra,24(sp)
    80003e2a:	6442                	ld	s0,16(sp)
    80003e2c:	6105                	addi	sp,sp,32
    80003e2e:	8082                	ret

0000000080003e30 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e30:	1141                	addi	sp,sp,-16
    80003e32:	e406                	sd	ra,8(sp)
    80003e34:	e022                	sd	s0,0(sp)
    80003e36:	0800                	addi	s0,sp,16
    80003e38:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e3a:	4585                	li	a1,1
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	db4080e7          	jalr	-588(ra) # 80003bf0 <namex>
}
    80003e44:	60a2                	ld	ra,8(sp)
    80003e46:	6402                	ld	s0,0(sp)
    80003e48:	0141                	addi	sp,sp,16
    80003e4a:	8082                	ret

0000000080003e4c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e4c:	1101                	addi	sp,sp,-32
    80003e4e:	ec06                	sd	ra,24(sp)
    80003e50:	e822                	sd	s0,16(sp)
    80003e52:	e426                	sd	s1,8(sp)
    80003e54:	e04a                	sd	s2,0(sp)
    80003e56:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e58:	0001d917          	auipc	s2,0x1d
    80003e5c:	41890913          	addi	s2,s2,1048 # 80021270 <log>
    80003e60:	01892583          	lw	a1,24(s2)
    80003e64:	02892503          	lw	a0,40(s2)
    80003e68:	fffff097          	auipc	ra,0xfffff
    80003e6c:	ff2080e7          	jalr	-14(ra) # 80002e5a <bread>
    80003e70:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e72:	02c92683          	lw	a3,44(s2)
    80003e76:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e78:	02d05763          	blez	a3,80003ea6 <write_head+0x5a>
    80003e7c:	0001d797          	auipc	a5,0x1d
    80003e80:	42478793          	addi	a5,a5,1060 # 800212a0 <log+0x30>
    80003e84:	05c50713          	addi	a4,a0,92
    80003e88:	36fd                	addiw	a3,a3,-1
    80003e8a:	1682                	slli	a3,a3,0x20
    80003e8c:	9281                	srli	a3,a3,0x20
    80003e8e:	068a                	slli	a3,a3,0x2
    80003e90:	0001d617          	auipc	a2,0x1d
    80003e94:	41460613          	addi	a2,a2,1044 # 800212a4 <log+0x34>
    80003e98:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e9a:	4390                	lw	a2,0(a5)
    80003e9c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e9e:	0791                	addi	a5,a5,4
    80003ea0:	0711                	addi	a4,a4,4
    80003ea2:	fed79ce3          	bne	a5,a3,80003e9a <write_head+0x4e>
  }
  bwrite(buf);
    80003ea6:	8526                	mv	a0,s1
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	0a4080e7          	jalr	164(ra) # 80002f4c <bwrite>
  brelse(buf);
    80003eb0:	8526                	mv	a0,s1
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	0d8080e7          	jalr	216(ra) # 80002f8a <brelse>
}
    80003eba:	60e2                	ld	ra,24(sp)
    80003ebc:	6442                	ld	s0,16(sp)
    80003ebe:	64a2                	ld	s1,8(sp)
    80003ec0:	6902                	ld	s2,0(sp)
    80003ec2:	6105                	addi	sp,sp,32
    80003ec4:	8082                	ret

0000000080003ec6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ec6:	0001d797          	auipc	a5,0x1d
    80003eca:	3d67a783          	lw	a5,982(a5) # 8002129c <log+0x2c>
    80003ece:	0af05d63          	blez	a5,80003f88 <install_trans+0xc2>
{
    80003ed2:	7139                	addi	sp,sp,-64
    80003ed4:	fc06                	sd	ra,56(sp)
    80003ed6:	f822                	sd	s0,48(sp)
    80003ed8:	f426                	sd	s1,40(sp)
    80003eda:	f04a                	sd	s2,32(sp)
    80003edc:	ec4e                	sd	s3,24(sp)
    80003ede:	e852                	sd	s4,16(sp)
    80003ee0:	e456                	sd	s5,8(sp)
    80003ee2:	e05a                	sd	s6,0(sp)
    80003ee4:	0080                	addi	s0,sp,64
    80003ee6:	8b2a                	mv	s6,a0
    80003ee8:	0001da97          	auipc	s5,0x1d
    80003eec:	3b8a8a93          	addi	s5,s5,952 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ef0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ef2:	0001d997          	auipc	s3,0x1d
    80003ef6:	37e98993          	addi	s3,s3,894 # 80021270 <log>
    80003efa:	a035                	j	80003f26 <install_trans+0x60>
      bunpin(dbuf);
    80003efc:	8526                	mv	a0,s1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	166080e7          	jalr	358(ra) # 80003064 <bunpin>
    brelse(lbuf);
    80003f06:	854a                	mv	a0,s2
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	082080e7          	jalr	130(ra) # 80002f8a <brelse>
    brelse(dbuf);
    80003f10:	8526                	mv	a0,s1
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	078080e7          	jalr	120(ra) # 80002f8a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f1a:	2a05                	addiw	s4,s4,1
    80003f1c:	0a91                	addi	s5,s5,4
    80003f1e:	02c9a783          	lw	a5,44(s3)
    80003f22:	04fa5963          	bge	s4,a5,80003f74 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f26:	0189a583          	lw	a1,24(s3)
    80003f2a:	014585bb          	addw	a1,a1,s4
    80003f2e:	2585                	addiw	a1,a1,1
    80003f30:	0289a503          	lw	a0,40(s3)
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	f26080e7          	jalr	-218(ra) # 80002e5a <bread>
    80003f3c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f3e:	000aa583          	lw	a1,0(s5)
    80003f42:	0289a503          	lw	a0,40(s3)
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	f14080e7          	jalr	-236(ra) # 80002e5a <bread>
    80003f4e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f50:	40000613          	li	a2,1024
    80003f54:	05890593          	addi	a1,s2,88
    80003f58:	05850513          	addi	a0,a0,88
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	de4080e7          	jalr	-540(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f64:	8526                	mv	a0,s1
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	fe6080e7          	jalr	-26(ra) # 80002f4c <bwrite>
    if(recovering == 0)
    80003f6e:	f80b1ce3          	bnez	s6,80003f06 <install_trans+0x40>
    80003f72:	b769                	j	80003efc <install_trans+0x36>
}
    80003f74:	70e2                	ld	ra,56(sp)
    80003f76:	7442                	ld	s0,48(sp)
    80003f78:	74a2                	ld	s1,40(sp)
    80003f7a:	7902                	ld	s2,32(sp)
    80003f7c:	69e2                	ld	s3,24(sp)
    80003f7e:	6a42                	ld	s4,16(sp)
    80003f80:	6aa2                	ld	s5,8(sp)
    80003f82:	6b02                	ld	s6,0(sp)
    80003f84:	6121                	addi	sp,sp,64
    80003f86:	8082                	ret
    80003f88:	8082                	ret

0000000080003f8a <initlog>:
{
    80003f8a:	7179                	addi	sp,sp,-48
    80003f8c:	f406                	sd	ra,40(sp)
    80003f8e:	f022                	sd	s0,32(sp)
    80003f90:	ec26                	sd	s1,24(sp)
    80003f92:	e84a                	sd	s2,16(sp)
    80003f94:	e44e                	sd	s3,8(sp)
    80003f96:	1800                	addi	s0,sp,48
    80003f98:	892a                	mv	s2,a0
    80003f9a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f9c:	0001d497          	auipc	s1,0x1d
    80003fa0:	2d448493          	addi	s1,s1,724 # 80021270 <log>
    80003fa4:	00004597          	auipc	a1,0x4
    80003fa8:	67c58593          	addi	a1,a1,1660 # 80008620 <syscalls+0x1d8>
    80003fac:	8526                	mv	a0,s1
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	ba6080e7          	jalr	-1114(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003fb6:	0149a583          	lw	a1,20(s3)
    80003fba:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fbc:	0109a783          	lw	a5,16(s3)
    80003fc0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fc2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	e92080e7          	jalr	-366(ra) # 80002e5a <bread>
  log.lh.n = lh->n;
    80003fd0:	4d3c                	lw	a5,88(a0)
    80003fd2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fd4:	02f05563          	blez	a5,80003ffe <initlog+0x74>
    80003fd8:	05c50713          	addi	a4,a0,92
    80003fdc:	0001d697          	auipc	a3,0x1d
    80003fe0:	2c468693          	addi	a3,a3,708 # 800212a0 <log+0x30>
    80003fe4:	37fd                	addiw	a5,a5,-1
    80003fe6:	1782                	slli	a5,a5,0x20
    80003fe8:	9381                	srli	a5,a5,0x20
    80003fea:	078a                	slli	a5,a5,0x2
    80003fec:	06050613          	addi	a2,a0,96
    80003ff0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003ff2:	4310                	lw	a2,0(a4)
    80003ff4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003ff6:	0711                	addi	a4,a4,4
    80003ff8:	0691                	addi	a3,a3,4
    80003ffa:	fef71ce3          	bne	a4,a5,80003ff2 <initlog+0x68>
  brelse(buf);
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	f8c080e7          	jalr	-116(ra) # 80002f8a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004006:	4505                	li	a0,1
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	ebe080e7          	jalr	-322(ra) # 80003ec6 <install_trans>
  log.lh.n = 0;
    80004010:	0001d797          	auipc	a5,0x1d
    80004014:	2807a623          	sw	zero,652(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	e34080e7          	jalr	-460(ra) # 80003e4c <write_head>
}
    80004020:	70a2                	ld	ra,40(sp)
    80004022:	7402                	ld	s0,32(sp)
    80004024:	64e2                	ld	s1,24(sp)
    80004026:	6942                	ld	s2,16(sp)
    80004028:	69a2                	ld	s3,8(sp)
    8000402a:	6145                	addi	sp,sp,48
    8000402c:	8082                	ret

000000008000402e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000402e:	1101                	addi	sp,sp,-32
    80004030:	ec06                	sd	ra,24(sp)
    80004032:	e822                	sd	s0,16(sp)
    80004034:	e426                	sd	s1,8(sp)
    80004036:	e04a                	sd	s2,0(sp)
    80004038:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000403a:	0001d517          	auipc	a0,0x1d
    8000403e:	23650513          	addi	a0,a0,566 # 80021270 <log>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	ba2080e7          	jalr	-1118(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000404a:	0001d497          	auipc	s1,0x1d
    8000404e:	22648493          	addi	s1,s1,550 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004052:	4979                	li	s2,30
    80004054:	a039                	j	80004062 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004056:	85a6                	mv	a1,s1
    80004058:	8526                	mv	a0,s1
    8000405a:	ffffe097          	auipc	ra,0xffffe
    8000405e:	ff8080e7          	jalr	-8(ra) # 80002052 <sleep>
    if(log.committing){
    80004062:	50dc                	lw	a5,36(s1)
    80004064:	fbed                	bnez	a5,80004056 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004066:	509c                	lw	a5,32(s1)
    80004068:	0017871b          	addiw	a4,a5,1
    8000406c:	0007069b          	sext.w	a3,a4
    80004070:	0027179b          	slliw	a5,a4,0x2
    80004074:	9fb9                	addw	a5,a5,a4
    80004076:	0017979b          	slliw	a5,a5,0x1
    8000407a:	54d8                	lw	a4,44(s1)
    8000407c:	9fb9                	addw	a5,a5,a4
    8000407e:	00f95963          	bge	s2,a5,80004090 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004082:	85a6                	mv	a1,s1
    80004084:	8526                	mv	a0,s1
    80004086:	ffffe097          	auipc	ra,0xffffe
    8000408a:	fcc080e7          	jalr	-52(ra) # 80002052 <sleep>
    8000408e:	bfd1                	j	80004062 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004090:	0001d517          	auipc	a0,0x1d
    80004094:	1e050513          	addi	a0,a0,480 # 80021270 <log>
    80004098:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
      break;
    }
  }
}
    800040a2:	60e2                	ld	ra,24(sp)
    800040a4:	6442                	ld	s0,16(sp)
    800040a6:	64a2                	ld	s1,8(sp)
    800040a8:	6902                	ld	s2,0(sp)
    800040aa:	6105                	addi	sp,sp,32
    800040ac:	8082                	ret

00000000800040ae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ae:	7139                	addi	sp,sp,-64
    800040b0:	fc06                	sd	ra,56(sp)
    800040b2:	f822                	sd	s0,48(sp)
    800040b4:	f426                	sd	s1,40(sp)
    800040b6:	f04a                	sd	s2,32(sp)
    800040b8:	ec4e                	sd	s3,24(sp)
    800040ba:	e852                	sd	s4,16(sp)
    800040bc:	e456                	sd	s5,8(sp)
    800040be:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040c0:	0001d497          	auipc	s1,0x1d
    800040c4:	1b048493          	addi	s1,s1,432 # 80021270 <log>
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800040d2:	509c                	lw	a5,32(s1)
    800040d4:	37fd                	addiw	a5,a5,-1
    800040d6:	0007891b          	sext.w	s2,a5
    800040da:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040dc:	50dc                	lw	a5,36(s1)
    800040de:	efb9                	bnez	a5,8000413c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040e0:	06091663          	bnez	s2,8000414c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040e4:	0001d497          	auipc	s1,0x1d
    800040e8:	18c48493          	addi	s1,s1,396 # 80021270 <log>
    800040ec:	4785                	li	a5,1
    800040ee:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	ba6080e7          	jalr	-1114(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040fa:	54dc                	lw	a5,44(s1)
    800040fc:	06f04763          	bgtz	a5,8000416a <end_op+0xbc>
    acquire(&log.lock);
    80004100:	0001d497          	auipc	s1,0x1d
    80004104:	17048493          	addi	s1,s1,368 # 80021270 <log>
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004112:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004116:	8526                	mv	a0,s1
    80004118:	ffffe097          	auipc	ra,0xffffe
    8000411c:	0c6080e7          	jalr	198(ra) # 800021de <wakeup>
    release(&log.lock);
    80004120:	8526                	mv	a0,s1
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	b76080e7          	jalr	-1162(ra) # 80000c98 <release>
}
    8000412a:	70e2                	ld	ra,56(sp)
    8000412c:	7442                	ld	s0,48(sp)
    8000412e:	74a2                	ld	s1,40(sp)
    80004130:	7902                	ld	s2,32(sp)
    80004132:	69e2                	ld	s3,24(sp)
    80004134:	6a42                	ld	s4,16(sp)
    80004136:	6aa2                	ld	s5,8(sp)
    80004138:	6121                	addi	sp,sp,64
    8000413a:	8082                	ret
    panic("log.committing");
    8000413c:	00004517          	auipc	a0,0x4
    80004140:	4ec50513          	addi	a0,a0,1260 # 80008628 <syscalls+0x1e0>
    80004144:	ffffc097          	auipc	ra,0xffffc
    80004148:	3fa080e7          	jalr	1018(ra) # 8000053e <panic>
    wakeup(&log);
    8000414c:	0001d497          	auipc	s1,0x1d
    80004150:	12448493          	addi	s1,s1,292 # 80021270 <log>
    80004154:	8526                	mv	a0,s1
    80004156:	ffffe097          	auipc	ra,0xffffe
    8000415a:	088080e7          	jalr	136(ra) # 800021de <wakeup>
  release(&log.lock);
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
  if(do_commit){
    80004168:	b7c9                	j	8000412a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	0001da97          	auipc	s5,0x1d
    8000416e:	136a8a93          	addi	s5,s5,310 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004172:	0001da17          	auipc	s4,0x1d
    80004176:	0fea0a13          	addi	s4,s4,254 # 80021270 <log>
    8000417a:	018a2583          	lw	a1,24(s4)
    8000417e:	012585bb          	addw	a1,a1,s2
    80004182:	2585                	addiw	a1,a1,1
    80004184:	028a2503          	lw	a0,40(s4)
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	cd2080e7          	jalr	-814(ra) # 80002e5a <bread>
    80004190:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004192:	000aa583          	lw	a1,0(s5)
    80004196:	028a2503          	lw	a0,40(s4)
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	cc0080e7          	jalr	-832(ra) # 80002e5a <bread>
    800041a2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041a4:	40000613          	li	a2,1024
    800041a8:	05850593          	addi	a1,a0,88
    800041ac:	05848513          	addi	a0,s1,88
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	b90080e7          	jalr	-1136(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041b8:	8526                	mv	a0,s1
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	d92080e7          	jalr	-622(ra) # 80002f4c <bwrite>
    brelse(from);
    800041c2:	854e                	mv	a0,s3
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	dc6080e7          	jalr	-570(ra) # 80002f8a <brelse>
    brelse(to);
    800041cc:	8526                	mv	a0,s1
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	dbc080e7          	jalr	-580(ra) # 80002f8a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d6:	2905                	addiw	s2,s2,1
    800041d8:	0a91                	addi	s5,s5,4
    800041da:	02ca2783          	lw	a5,44(s4)
    800041de:	f8f94ee3          	blt	s2,a5,8000417a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	c6a080e7          	jalr	-918(ra) # 80003e4c <write_head>
    install_trans(0); // Now install writes to home locations
    800041ea:	4501                	li	a0,0
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	cda080e7          	jalr	-806(ra) # 80003ec6 <install_trans>
    log.lh.n = 0;
    800041f4:	0001d797          	auipc	a5,0x1d
    800041f8:	0a07a423          	sw	zero,168(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	c50080e7          	jalr	-944(ra) # 80003e4c <write_head>
    80004204:	bdf5                	j	80004100 <end_op+0x52>

0000000080004206 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004206:	1101                	addi	sp,sp,-32
    80004208:	ec06                	sd	ra,24(sp)
    8000420a:	e822                	sd	s0,16(sp)
    8000420c:	e426                	sd	s1,8(sp)
    8000420e:	e04a                	sd	s2,0(sp)
    80004210:	1000                	addi	s0,sp,32
    80004212:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004214:	0001d917          	auipc	s2,0x1d
    80004218:	05c90913          	addi	s2,s2,92 # 80021270 <log>
    8000421c:	854a                	mv	a0,s2
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004226:	02c92603          	lw	a2,44(s2)
    8000422a:	47f5                	li	a5,29
    8000422c:	06c7c563          	blt	a5,a2,80004296 <log_write+0x90>
    80004230:	0001d797          	auipc	a5,0x1d
    80004234:	05c7a783          	lw	a5,92(a5) # 8002128c <log+0x1c>
    80004238:	37fd                	addiw	a5,a5,-1
    8000423a:	04f65e63          	bge	a2,a5,80004296 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000423e:	0001d797          	auipc	a5,0x1d
    80004242:	0527a783          	lw	a5,82(a5) # 80021290 <log+0x20>
    80004246:	06f05063          	blez	a5,800042a6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000424a:	4781                	li	a5,0
    8000424c:	06c05563          	blez	a2,800042b6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004250:	44cc                	lw	a1,12(s1)
    80004252:	0001d717          	auipc	a4,0x1d
    80004256:	04e70713          	addi	a4,a4,78 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000425a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000425c:	4314                	lw	a3,0(a4)
    8000425e:	04b68c63          	beq	a3,a1,800042b6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004262:	2785                	addiw	a5,a5,1
    80004264:	0711                	addi	a4,a4,4
    80004266:	fef61be3          	bne	a2,a5,8000425c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000426a:	0621                	addi	a2,a2,8
    8000426c:	060a                	slli	a2,a2,0x2
    8000426e:	0001d797          	auipc	a5,0x1d
    80004272:	00278793          	addi	a5,a5,2 # 80021270 <log>
    80004276:	963e                	add	a2,a2,a5
    80004278:	44dc                	lw	a5,12(s1)
    8000427a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	daa080e7          	jalr	-598(ra) # 80003028 <bpin>
    log.lh.n++;
    80004286:	0001d717          	auipc	a4,0x1d
    8000428a:	fea70713          	addi	a4,a4,-22 # 80021270 <log>
    8000428e:	575c                	lw	a5,44(a4)
    80004290:	2785                	addiw	a5,a5,1
    80004292:	d75c                	sw	a5,44(a4)
    80004294:	a835                	j	800042d0 <log_write+0xca>
    panic("too big a transaction");
    80004296:	00004517          	auipc	a0,0x4
    8000429a:	3a250513          	addi	a0,a0,930 # 80008638 <syscalls+0x1f0>
    8000429e:	ffffc097          	auipc	ra,0xffffc
    800042a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800042a6:	00004517          	auipc	a0,0x4
    800042aa:	3aa50513          	addi	a0,a0,938 # 80008650 <syscalls+0x208>
    800042ae:	ffffc097          	auipc	ra,0xffffc
    800042b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042b6:	00878713          	addi	a4,a5,8
    800042ba:	00271693          	slli	a3,a4,0x2
    800042be:	0001d717          	auipc	a4,0x1d
    800042c2:	fb270713          	addi	a4,a4,-78 # 80021270 <log>
    800042c6:	9736                	add	a4,a4,a3
    800042c8:	44d4                	lw	a3,12(s1)
    800042ca:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042cc:	faf608e3          	beq	a2,a5,8000427c <log_write+0x76>
  }
  release(&log.lock);
    800042d0:	0001d517          	auipc	a0,0x1d
    800042d4:	fa050513          	addi	a0,a0,-96 # 80021270 <log>
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
}
    800042e0:	60e2                	ld	ra,24(sp)
    800042e2:	6442                	ld	s0,16(sp)
    800042e4:	64a2                	ld	s1,8(sp)
    800042e6:	6902                	ld	s2,0(sp)
    800042e8:	6105                	addi	sp,sp,32
    800042ea:	8082                	ret

00000000800042ec <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042ec:	1101                	addi	sp,sp,-32
    800042ee:	ec06                	sd	ra,24(sp)
    800042f0:	e822                	sd	s0,16(sp)
    800042f2:	e426                	sd	s1,8(sp)
    800042f4:	e04a                	sd	s2,0(sp)
    800042f6:	1000                	addi	s0,sp,32
    800042f8:	84aa                	mv	s1,a0
    800042fa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042fc:	00004597          	auipc	a1,0x4
    80004300:	37458593          	addi	a1,a1,884 # 80008670 <syscalls+0x228>
    80004304:	0521                	addi	a0,a0,8
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	84e080e7          	jalr	-1970(ra) # 80000b54 <initlock>
  lk->name = name;
    8000430e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004312:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004316:	0204a423          	sw	zero,40(s1)
}
    8000431a:	60e2                	ld	ra,24(sp)
    8000431c:	6442                	ld	s0,16(sp)
    8000431e:	64a2                	ld	s1,8(sp)
    80004320:	6902                	ld	s2,0(sp)
    80004322:	6105                	addi	sp,sp,32
    80004324:	8082                	ret

0000000080004326 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004326:	1101                	addi	sp,sp,-32
    80004328:	ec06                	sd	ra,24(sp)
    8000432a:	e822                	sd	s0,16(sp)
    8000432c:	e426                	sd	s1,8(sp)
    8000432e:	e04a                	sd	s2,0(sp)
    80004330:	1000                	addi	s0,sp,32
    80004332:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004334:	00850913          	addi	s2,a0,8
    80004338:	854a                	mv	a0,s2
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	8aa080e7          	jalr	-1878(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004342:	409c                	lw	a5,0(s1)
    80004344:	cb89                	beqz	a5,80004356 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004346:	85ca                	mv	a1,s2
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffe097          	auipc	ra,0xffffe
    8000434e:	d08080e7          	jalr	-760(ra) # 80002052 <sleep>
  while (lk->locked) {
    80004352:	409c                	lw	a5,0(s1)
    80004354:	fbed                	bnez	a5,80004346 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004356:	4785                	li	a5,1
    80004358:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	656080e7          	jalr	1622(ra) # 800019b0 <myproc>
    80004362:	591c                	lw	a5,48(a0)
    80004364:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004366:	854a                	mv	a0,s2
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	930080e7          	jalr	-1744(ra) # 80000c98 <release>
}
    80004370:	60e2                	ld	ra,24(sp)
    80004372:	6442                	ld	s0,16(sp)
    80004374:	64a2                	ld	s1,8(sp)
    80004376:	6902                	ld	s2,0(sp)
    80004378:	6105                	addi	sp,sp,32
    8000437a:	8082                	ret

000000008000437c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000437c:	1101                	addi	sp,sp,-32
    8000437e:	ec06                	sd	ra,24(sp)
    80004380:	e822                	sd	s0,16(sp)
    80004382:	e426                	sd	s1,8(sp)
    80004384:	e04a                	sd	s2,0(sp)
    80004386:	1000                	addi	s0,sp,32
    80004388:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000438a:	00850913          	addi	s2,a0,8
    8000438e:	854a                	mv	a0,s2
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	854080e7          	jalr	-1964(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004398:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000439c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043a0:	8526                	mv	a0,s1
    800043a2:	ffffe097          	auipc	ra,0xffffe
    800043a6:	e3c080e7          	jalr	-452(ra) # 800021de <wakeup>
  release(&lk->lk);
    800043aa:	854a                	mv	a0,s2
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	8ec080e7          	jalr	-1812(ra) # 80000c98 <release>
}
    800043b4:	60e2                	ld	ra,24(sp)
    800043b6:	6442                	ld	s0,16(sp)
    800043b8:	64a2                	ld	s1,8(sp)
    800043ba:	6902                	ld	s2,0(sp)
    800043bc:	6105                	addi	sp,sp,32
    800043be:	8082                	ret

00000000800043c0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043c0:	7179                	addi	sp,sp,-48
    800043c2:	f406                	sd	ra,40(sp)
    800043c4:	f022                	sd	s0,32(sp)
    800043c6:	ec26                	sd	s1,24(sp)
    800043c8:	e84a                	sd	s2,16(sp)
    800043ca:	e44e                	sd	s3,8(sp)
    800043cc:	1800                	addi	s0,sp,48
    800043ce:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043d0:	00850913          	addi	s2,a0,8
    800043d4:	854a                	mv	a0,s2
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	80e080e7          	jalr	-2034(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043de:	409c                	lw	a5,0(s1)
    800043e0:	ef99                	bnez	a5,800043fe <holdingsleep+0x3e>
    800043e2:	4481                	li	s1,0
  release(&lk->lk);
    800043e4:	854a                	mv	a0,s2
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
  return r;
}
    800043ee:	8526                	mv	a0,s1
    800043f0:	70a2                	ld	ra,40(sp)
    800043f2:	7402                	ld	s0,32(sp)
    800043f4:	64e2                	ld	s1,24(sp)
    800043f6:	6942                	ld	s2,16(sp)
    800043f8:	69a2                	ld	s3,8(sp)
    800043fa:	6145                	addi	sp,sp,48
    800043fc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043fe:	0284a983          	lw	s3,40(s1)
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	5ae080e7          	jalr	1454(ra) # 800019b0 <myproc>
    8000440a:	5904                	lw	s1,48(a0)
    8000440c:	413484b3          	sub	s1,s1,s3
    80004410:	0014b493          	seqz	s1,s1
    80004414:	bfc1                	j	800043e4 <holdingsleep+0x24>

0000000080004416 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004416:	1141                	addi	sp,sp,-16
    80004418:	e406                	sd	ra,8(sp)
    8000441a:	e022                	sd	s0,0(sp)
    8000441c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000441e:	00004597          	auipc	a1,0x4
    80004422:	26258593          	addi	a1,a1,610 # 80008680 <syscalls+0x238>
    80004426:	0001d517          	auipc	a0,0x1d
    8000442a:	f9250513          	addi	a0,a0,-110 # 800213b8 <ftable>
    8000442e:	ffffc097          	auipc	ra,0xffffc
    80004432:	726080e7          	jalr	1830(ra) # 80000b54 <initlock>
}
    80004436:	60a2                	ld	ra,8(sp)
    80004438:	6402                	ld	s0,0(sp)
    8000443a:	0141                	addi	sp,sp,16
    8000443c:	8082                	ret

000000008000443e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000443e:	1101                	addi	sp,sp,-32
    80004440:	ec06                	sd	ra,24(sp)
    80004442:	e822                	sd	s0,16(sp)
    80004444:	e426                	sd	s1,8(sp)
    80004446:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004448:	0001d517          	auipc	a0,0x1d
    8000444c:	f7050513          	addi	a0,a0,-144 # 800213b8 <ftable>
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004458:	0001d497          	auipc	s1,0x1d
    8000445c:	f7848493          	addi	s1,s1,-136 # 800213d0 <ftable+0x18>
    80004460:	0001e717          	auipc	a4,0x1e
    80004464:	f1070713          	addi	a4,a4,-240 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004468:	40dc                	lw	a5,4(s1)
    8000446a:	cf99                	beqz	a5,80004488 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000446c:	02848493          	addi	s1,s1,40
    80004470:	fee49ce3          	bne	s1,a4,80004468 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004474:	0001d517          	auipc	a0,0x1d
    80004478:	f4450513          	addi	a0,a0,-188 # 800213b8 <ftable>
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	81c080e7          	jalr	-2020(ra) # 80000c98 <release>
  return 0;
    80004484:	4481                	li	s1,0
    80004486:	a819                	j	8000449c <filealloc+0x5e>
      f->ref = 1;
    80004488:	4785                	li	a5,1
    8000448a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000448c:	0001d517          	auipc	a0,0x1d
    80004490:	f2c50513          	addi	a0,a0,-212 # 800213b8 <ftable>
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
}
    8000449c:	8526                	mv	a0,s1
    8000449e:	60e2                	ld	ra,24(sp)
    800044a0:	6442                	ld	s0,16(sp)
    800044a2:	64a2                	ld	s1,8(sp)
    800044a4:	6105                	addi	sp,sp,32
    800044a6:	8082                	ret

00000000800044a8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044a8:	1101                	addi	sp,sp,-32
    800044aa:	ec06                	sd	ra,24(sp)
    800044ac:	e822                	sd	s0,16(sp)
    800044ae:	e426                	sd	s1,8(sp)
    800044b0:	1000                	addi	s0,sp,32
    800044b2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044b4:	0001d517          	auipc	a0,0x1d
    800044b8:	f0450513          	addi	a0,a0,-252 # 800213b8 <ftable>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	728080e7          	jalr	1832(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800044c4:	40dc                	lw	a5,4(s1)
    800044c6:	02f05263          	blez	a5,800044ea <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044ca:	2785                	addiw	a5,a5,1
    800044cc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044ce:	0001d517          	auipc	a0,0x1d
    800044d2:	eea50513          	addi	a0,a0,-278 # 800213b8 <ftable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7c2080e7          	jalr	1986(ra) # 80000c98 <release>
  return f;
}
    800044de:	8526                	mv	a0,s1
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	64a2                	ld	s1,8(sp)
    800044e6:	6105                	addi	sp,sp,32
    800044e8:	8082                	ret
    panic("filedup");
    800044ea:	00004517          	auipc	a0,0x4
    800044ee:	19e50513          	addi	a0,a0,414 # 80008688 <syscalls+0x240>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	04c080e7          	jalr	76(ra) # 8000053e <panic>

00000000800044fa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044fa:	7139                	addi	sp,sp,-64
    800044fc:	fc06                	sd	ra,56(sp)
    800044fe:	f822                	sd	s0,48(sp)
    80004500:	f426                	sd	s1,40(sp)
    80004502:	f04a                	sd	s2,32(sp)
    80004504:	ec4e                	sd	s3,24(sp)
    80004506:	e852                	sd	s4,16(sp)
    80004508:	e456                	sd	s5,8(sp)
    8000450a:	0080                	addi	s0,sp,64
    8000450c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000450e:	0001d517          	auipc	a0,0x1d
    80004512:	eaa50513          	addi	a0,a0,-342 # 800213b8 <ftable>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	6ce080e7          	jalr	1742(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000451e:	40dc                	lw	a5,4(s1)
    80004520:	06f05163          	blez	a5,80004582 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004524:	37fd                	addiw	a5,a5,-1
    80004526:	0007871b          	sext.w	a4,a5
    8000452a:	c0dc                	sw	a5,4(s1)
    8000452c:	06e04363          	bgtz	a4,80004592 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004530:	0004a903          	lw	s2,0(s1)
    80004534:	0094ca83          	lbu	s5,9(s1)
    80004538:	0104ba03          	ld	s4,16(s1)
    8000453c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004540:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004544:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	e7050513          	addi	a0,a0,-400 # 800213b8 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	748080e7          	jalr	1864(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004558:	4785                	li	a5,1
    8000455a:	04f90d63          	beq	s2,a5,800045b4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000455e:	3979                	addiw	s2,s2,-2
    80004560:	4785                	li	a5,1
    80004562:	0527e063          	bltu	a5,s2,800045a2 <fileclose+0xa8>
    begin_op();
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	ac8080e7          	jalr	-1336(ra) # 8000402e <begin_op>
    iput(ff.ip);
    8000456e:	854e                	mv	a0,s3
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	2a6080e7          	jalr	678(ra) # 80003816 <iput>
    end_op();
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	b36080e7          	jalr	-1226(ra) # 800040ae <end_op>
    80004580:	a00d                	j	800045a2 <fileclose+0xa8>
    panic("fileclose");
    80004582:	00004517          	auipc	a0,0x4
    80004586:	10e50513          	addi	a0,a0,270 # 80008690 <syscalls+0x248>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004592:	0001d517          	auipc	a0,0x1d
    80004596:	e2650513          	addi	a0,a0,-474 # 800213b8 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
  }
}
    800045a2:	70e2                	ld	ra,56(sp)
    800045a4:	7442                	ld	s0,48(sp)
    800045a6:	74a2                	ld	s1,40(sp)
    800045a8:	7902                	ld	s2,32(sp)
    800045aa:	69e2                	ld	s3,24(sp)
    800045ac:	6a42                	ld	s4,16(sp)
    800045ae:	6aa2                	ld	s5,8(sp)
    800045b0:	6121                	addi	sp,sp,64
    800045b2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045b4:	85d6                	mv	a1,s5
    800045b6:	8552                	mv	a0,s4
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	34c080e7          	jalr	844(ra) # 80004904 <pipeclose>
    800045c0:	b7cd                	j	800045a2 <fileclose+0xa8>

00000000800045c2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045c2:	715d                	addi	sp,sp,-80
    800045c4:	e486                	sd	ra,72(sp)
    800045c6:	e0a2                	sd	s0,64(sp)
    800045c8:	fc26                	sd	s1,56(sp)
    800045ca:	f84a                	sd	s2,48(sp)
    800045cc:	f44e                	sd	s3,40(sp)
    800045ce:	0880                	addi	s0,sp,80
    800045d0:	84aa                	mv	s1,a0
    800045d2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045d4:	ffffd097          	auipc	ra,0xffffd
    800045d8:	3dc080e7          	jalr	988(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045dc:	409c                	lw	a5,0(s1)
    800045de:	37f9                	addiw	a5,a5,-2
    800045e0:	4705                	li	a4,1
    800045e2:	04f76763          	bltu	a4,a5,80004630 <filestat+0x6e>
    800045e6:	892a                	mv	s2,a0
    ilock(f->ip);
    800045e8:	6c88                	ld	a0,24(s1)
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	072080e7          	jalr	114(ra) # 8000365c <ilock>
    stati(f->ip, &st);
    800045f2:	fb840593          	addi	a1,s0,-72
    800045f6:	6c88                	ld	a0,24(s1)
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	2ee080e7          	jalr	750(ra) # 800038e6 <stati>
    iunlock(f->ip);
    80004600:	6c88                	ld	a0,24(s1)
    80004602:	fffff097          	auipc	ra,0xfffff
    80004606:	11c080e7          	jalr	284(ra) # 8000371e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000460a:	46e1                	li	a3,24
    8000460c:	fb840613          	addi	a2,s0,-72
    80004610:	85ce                	mv	a1,s3
    80004612:	05093503          	ld	a0,80(s2)
    80004616:	ffffd097          	auipc	ra,0xffffd
    8000461a:	05c080e7          	jalr	92(ra) # 80001672 <copyout>
    8000461e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004622:	60a6                	ld	ra,72(sp)
    80004624:	6406                	ld	s0,64(sp)
    80004626:	74e2                	ld	s1,56(sp)
    80004628:	7942                	ld	s2,48(sp)
    8000462a:	79a2                	ld	s3,40(sp)
    8000462c:	6161                	addi	sp,sp,80
    8000462e:	8082                	ret
  return -1;
    80004630:	557d                	li	a0,-1
    80004632:	bfc5                	j	80004622 <filestat+0x60>

0000000080004634 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004634:	7179                	addi	sp,sp,-48
    80004636:	f406                	sd	ra,40(sp)
    80004638:	f022                	sd	s0,32(sp)
    8000463a:	ec26                	sd	s1,24(sp)
    8000463c:	e84a                	sd	s2,16(sp)
    8000463e:	e44e                	sd	s3,8(sp)
    80004640:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004642:	00854783          	lbu	a5,8(a0)
    80004646:	c3d5                	beqz	a5,800046ea <fileread+0xb6>
    80004648:	84aa                	mv	s1,a0
    8000464a:	89ae                	mv	s3,a1
    8000464c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000464e:	411c                	lw	a5,0(a0)
    80004650:	4705                	li	a4,1
    80004652:	04e78963          	beq	a5,a4,800046a4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004656:	470d                	li	a4,3
    80004658:	04e78d63          	beq	a5,a4,800046b2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000465c:	4709                	li	a4,2
    8000465e:	06e79e63          	bne	a5,a4,800046da <fileread+0xa6>
    ilock(f->ip);
    80004662:	6d08                	ld	a0,24(a0)
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	ff8080e7          	jalr	-8(ra) # 8000365c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000466c:	874a                	mv	a4,s2
    8000466e:	5094                	lw	a3,32(s1)
    80004670:	864e                	mv	a2,s3
    80004672:	4585                	li	a1,1
    80004674:	6c88                	ld	a0,24(s1)
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	29a080e7          	jalr	666(ra) # 80003910 <readi>
    8000467e:	892a                	mv	s2,a0
    80004680:	00a05563          	blez	a0,8000468a <fileread+0x56>
      f->off += r;
    80004684:	509c                	lw	a5,32(s1)
    80004686:	9fa9                	addw	a5,a5,a0
    80004688:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000468a:	6c88                	ld	a0,24(s1)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	092080e7          	jalr	146(ra) # 8000371e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004694:	854a                	mv	a0,s2
    80004696:	70a2                	ld	ra,40(sp)
    80004698:	7402                	ld	s0,32(sp)
    8000469a:	64e2                	ld	s1,24(sp)
    8000469c:	6942                	ld	s2,16(sp)
    8000469e:	69a2                	ld	s3,8(sp)
    800046a0:	6145                	addi	sp,sp,48
    800046a2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046a4:	6908                	ld	a0,16(a0)
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	3c8080e7          	jalr	968(ra) # 80004a6e <piperead>
    800046ae:	892a                	mv	s2,a0
    800046b0:	b7d5                	j	80004694 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046b2:	02451783          	lh	a5,36(a0)
    800046b6:	03079693          	slli	a3,a5,0x30
    800046ba:	92c1                	srli	a3,a3,0x30
    800046bc:	4725                	li	a4,9
    800046be:	02d76863          	bltu	a4,a3,800046ee <fileread+0xba>
    800046c2:	0792                	slli	a5,a5,0x4
    800046c4:	0001d717          	auipc	a4,0x1d
    800046c8:	c5470713          	addi	a4,a4,-940 # 80021318 <devsw>
    800046cc:	97ba                	add	a5,a5,a4
    800046ce:	639c                	ld	a5,0(a5)
    800046d0:	c38d                	beqz	a5,800046f2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046d2:	4505                	li	a0,1
    800046d4:	9782                	jalr	a5
    800046d6:	892a                	mv	s2,a0
    800046d8:	bf75                	j	80004694 <fileread+0x60>
    panic("fileread");
    800046da:	00004517          	auipc	a0,0x4
    800046de:	fc650513          	addi	a0,a0,-58 # 800086a0 <syscalls+0x258>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	e5c080e7          	jalr	-420(ra) # 8000053e <panic>
    return -1;
    800046ea:	597d                	li	s2,-1
    800046ec:	b765                	j	80004694 <fileread+0x60>
      return -1;
    800046ee:	597d                	li	s2,-1
    800046f0:	b755                	j	80004694 <fileread+0x60>
    800046f2:	597d                	li	s2,-1
    800046f4:	b745                	j	80004694 <fileread+0x60>

00000000800046f6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046f6:	715d                	addi	sp,sp,-80
    800046f8:	e486                	sd	ra,72(sp)
    800046fa:	e0a2                	sd	s0,64(sp)
    800046fc:	fc26                	sd	s1,56(sp)
    800046fe:	f84a                	sd	s2,48(sp)
    80004700:	f44e                	sd	s3,40(sp)
    80004702:	f052                	sd	s4,32(sp)
    80004704:	ec56                	sd	s5,24(sp)
    80004706:	e85a                	sd	s6,16(sp)
    80004708:	e45e                	sd	s7,8(sp)
    8000470a:	e062                	sd	s8,0(sp)
    8000470c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000470e:	00954783          	lbu	a5,9(a0)
    80004712:	10078663          	beqz	a5,8000481e <filewrite+0x128>
    80004716:	892a                	mv	s2,a0
    80004718:	8aae                	mv	s5,a1
    8000471a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000471c:	411c                	lw	a5,0(a0)
    8000471e:	4705                	li	a4,1
    80004720:	02e78263          	beq	a5,a4,80004744 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004724:	470d                	li	a4,3
    80004726:	02e78663          	beq	a5,a4,80004752 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000472a:	4709                	li	a4,2
    8000472c:	0ee79163          	bne	a5,a4,8000480e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004730:	0ac05d63          	blez	a2,800047ea <filewrite+0xf4>
    int i = 0;
    80004734:	4981                	li	s3,0
    80004736:	6b05                	lui	s6,0x1
    80004738:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000473c:	6b85                	lui	s7,0x1
    8000473e:	c00b8b9b          	addiw	s7,s7,-1024
    80004742:	a861                	j	800047da <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004744:	6908                	ld	a0,16(a0)
    80004746:	00000097          	auipc	ra,0x0
    8000474a:	22e080e7          	jalr	558(ra) # 80004974 <pipewrite>
    8000474e:	8a2a                	mv	s4,a0
    80004750:	a045                	j	800047f0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004752:	02451783          	lh	a5,36(a0)
    80004756:	03079693          	slli	a3,a5,0x30
    8000475a:	92c1                	srli	a3,a3,0x30
    8000475c:	4725                	li	a4,9
    8000475e:	0cd76263          	bltu	a4,a3,80004822 <filewrite+0x12c>
    80004762:	0792                	slli	a5,a5,0x4
    80004764:	0001d717          	auipc	a4,0x1d
    80004768:	bb470713          	addi	a4,a4,-1100 # 80021318 <devsw>
    8000476c:	97ba                	add	a5,a5,a4
    8000476e:	679c                	ld	a5,8(a5)
    80004770:	cbdd                	beqz	a5,80004826 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004772:	4505                	li	a0,1
    80004774:	9782                	jalr	a5
    80004776:	8a2a                	mv	s4,a0
    80004778:	a8a5                	j	800047f0 <filewrite+0xfa>
    8000477a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000477e:	00000097          	auipc	ra,0x0
    80004782:	8b0080e7          	jalr	-1872(ra) # 8000402e <begin_op>
      ilock(f->ip);
    80004786:	01893503          	ld	a0,24(s2)
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	ed2080e7          	jalr	-302(ra) # 8000365c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004792:	8762                	mv	a4,s8
    80004794:	02092683          	lw	a3,32(s2)
    80004798:	01598633          	add	a2,s3,s5
    8000479c:	4585                	li	a1,1
    8000479e:	01893503          	ld	a0,24(s2)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	266080e7          	jalr	614(ra) # 80003a08 <writei>
    800047aa:	84aa                	mv	s1,a0
    800047ac:	00a05763          	blez	a0,800047ba <filewrite+0xc4>
        f->off += r;
    800047b0:	02092783          	lw	a5,32(s2)
    800047b4:	9fa9                	addw	a5,a5,a0
    800047b6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047ba:	01893503          	ld	a0,24(s2)
    800047be:	fffff097          	auipc	ra,0xfffff
    800047c2:	f60080e7          	jalr	-160(ra) # 8000371e <iunlock>
      end_op();
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	8e8080e7          	jalr	-1816(ra) # 800040ae <end_op>

      if(r != n1){
    800047ce:	009c1f63          	bne	s8,s1,800047ec <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047d2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047d6:	0149db63          	bge	s3,s4,800047ec <filewrite+0xf6>
      int n1 = n - i;
    800047da:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047de:	84be                	mv	s1,a5
    800047e0:	2781                	sext.w	a5,a5
    800047e2:	f8fb5ce3          	bge	s6,a5,8000477a <filewrite+0x84>
    800047e6:	84de                	mv	s1,s7
    800047e8:	bf49                	j	8000477a <filewrite+0x84>
    int i = 0;
    800047ea:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047ec:	013a1f63          	bne	s4,s3,8000480a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047f0:	8552                	mv	a0,s4
    800047f2:	60a6                	ld	ra,72(sp)
    800047f4:	6406                	ld	s0,64(sp)
    800047f6:	74e2                	ld	s1,56(sp)
    800047f8:	7942                	ld	s2,48(sp)
    800047fa:	79a2                	ld	s3,40(sp)
    800047fc:	7a02                	ld	s4,32(sp)
    800047fe:	6ae2                	ld	s5,24(sp)
    80004800:	6b42                	ld	s6,16(sp)
    80004802:	6ba2                	ld	s7,8(sp)
    80004804:	6c02                	ld	s8,0(sp)
    80004806:	6161                	addi	sp,sp,80
    80004808:	8082                	ret
    ret = (i == n ? n : -1);
    8000480a:	5a7d                	li	s4,-1
    8000480c:	b7d5                	j	800047f0 <filewrite+0xfa>
    panic("filewrite");
    8000480e:	00004517          	auipc	a0,0x4
    80004812:	ea250513          	addi	a0,a0,-350 # 800086b0 <syscalls+0x268>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	d28080e7          	jalr	-728(ra) # 8000053e <panic>
    return -1;
    8000481e:	5a7d                	li	s4,-1
    80004820:	bfc1                	j	800047f0 <filewrite+0xfa>
      return -1;
    80004822:	5a7d                	li	s4,-1
    80004824:	b7f1                	j	800047f0 <filewrite+0xfa>
    80004826:	5a7d                	li	s4,-1
    80004828:	b7e1                	j	800047f0 <filewrite+0xfa>

000000008000482a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000482a:	7179                	addi	sp,sp,-48
    8000482c:	f406                	sd	ra,40(sp)
    8000482e:	f022                	sd	s0,32(sp)
    80004830:	ec26                	sd	s1,24(sp)
    80004832:	e84a                	sd	s2,16(sp)
    80004834:	e44e                	sd	s3,8(sp)
    80004836:	e052                	sd	s4,0(sp)
    80004838:	1800                	addi	s0,sp,48
    8000483a:	84aa                	mv	s1,a0
    8000483c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000483e:	0005b023          	sd	zero,0(a1)
    80004842:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	bf8080e7          	jalr	-1032(ra) # 8000443e <filealloc>
    8000484e:	e088                	sd	a0,0(s1)
    80004850:	c551                	beqz	a0,800048dc <pipealloc+0xb2>
    80004852:	00000097          	auipc	ra,0x0
    80004856:	bec080e7          	jalr	-1044(ra) # 8000443e <filealloc>
    8000485a:	00aa3023          	sd	a0,0(s4)
    8000485e:	c92d                	beqz	a0,800048d0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	294080e7          	jalr	660(ra) # 80000af4 <kalloc>
    80004868:	892a                	mv	s2,a0
    8000486a:	c125                	beqz	a0,800048ca <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000486c:	4985                	li	s3,1
    8000486e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004872:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004876:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000487a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000487e:	00004597          	auipc	a1,0x4
    80004882:	e4258593          	addi	a1,a1,-446 # 800086c0 <syscalls+0x278>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	2ce080e7          	jalr	718(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000488e:	609c                	ld	a5,0(s1)
    80004890:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004894:	609c                	ld	a5,0(s1)
    80004896:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000489a:	609c                	ld	a5,0(s1)
    8000489c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048a0:	609c                	ld	a5,0(s1)
    800048a2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048a6:	000a3783          	ld	a5,0(s4)
    800048aa:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048ae:	000a3783          	ld	a5,0(s4)
    800048b2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048b6:	000a3783          	ld	a5,0(s4)
    800048ba:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048be:	000a3783          	ld	a5,0(s4)
    800048c2:	0127b823          	sd	s2,16(a5)
  return 0;
    800048c6:	4501                	li	a0,0
    800048c8:	a025                	j	800048f0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048ca:	6088                	ld	a0,0(s1)
    800048cc:	e501                	bnez	a0,800048d4 <pipealloc+0xaa>
    800048ce:	a039                	j	800048dc <pipealloc+0xb2>
    800048d0:	6088                	ld	a0,0(s1)
    800048d2:	c51d                	beqz	a0,80004900 <pipealloc+0xd6>
    fileclose(*f0);
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	c26080e7          	jalr	-986(ra) # 800044fa <fileclose>
  if(*f1)
    800048dc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048e0:	557d                	li	a0,-1
  if(*f1)
    800048e2:	c799                	beqz	a5,800048f0 <pipealloc+0xc6>
    fileclose(*f1);
    800048e4:	853e                	mv	a0,a5
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	c14080e7          	jalr	-1004(ra) # 800044fa <fileclose>
  return -1;
    800048ee:	557d                	li	a0,-1
}
    800048f0:	70a2                	ld	ra,40(sp)
    800048f2:	7402                	ld	s0,32(sp)
    800048f4:	64e2                	ld	s1,24(sp)
    800048f6:	6942                	ld	s2,16(sp)
    800048f8:	69a2                	ld	s3,8(sp)
    800048fa:	6a02                	ld	s4,0(sp)
    800048fc:	6145                	addi	sp,sp,48
    800048fe:	8082                	ret
  return -1;
    80004900:	557d                	li	a0,-1
    80004902:	b7fd                	j	800048f0 <pipealloc+0xc6>

0000000080004904 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004904:	1101                	addi	sp,sp,-32
    80004906:	ec06                	sd	ra,24(sp)
    80004908:	e822                	sd	s0,16(sp)
    8000490a:	e426                	sd	s1,8(sp)
    8000490c:	e04a                	sd	s2,0(sp)
    8000490e:	1000                	addi	s0,sp,32
    80004910:	84aa                	mv	s1,a0
    80004912:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	2d0080e7          	jalr	720(ra) # 80000be4 <acquire>
  if(writable){
    8000491c:	02090d63          	beqz	s2,80004956 <pipeclose+0x52>
    pi->writeopen = 0;
    80004920:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004924:	21848513          	addi	a0,s1,536
    80004928:	ffffe097          	auipc	ra,0xffffe
    8000492c:	8b6080e7          	jalr	-1866(ra) # 800021de <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004930:	2204b783          	ld	a5,544(s1)
    80004934:	eb95                	bnez	a5,80004968 <pipeclose+0x64>
    release(&pi->lock);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	360080e7          	jalr	864(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004940:	8526                	mv	a0,s1
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	0b6080e7          	jalr	182(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000494a:	60e2                	ld	ra,24(sp)
    8000494c:	6442                	ld	s0,16(sp)
    8000494e:	64a2                	ld	s1,8(sp)
    80004950:	6902                	ld	s2,0(sp)
    80004952:	6105                	addi	sp,sp,32
    80004954:	8082                	ret
    pi->readopen = 0;
    80004956:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000495a:	21c48513          	addi	a0,s1,540
    8000495e:	ffffe097          	auipc	ra,0xffffe
    80004962:	880080e7          	jalr	-1920(ra) # 800021de <wakeup>
    80004966:	b7e9                	j	80004930 <pipeclose+0x2c>
    release(&pi->lock);
    80004968:	8526                	mv	a0,s1
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	32e080e7          	jalr	814(ra) # 80000c98 <release>
}
    80004972:	bfe1                	j	8000494a <pipeclose+0x46>

0000000080004974 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004974:	7159                	addi	sp,sp,-112
    80004976:	f486                	sd	ra,104(sp)
    80004978:	f0a2                	sd	s0,96(sp)
    8000497a:	eca6                	sd	s1,88(sp)
    8000497c:	e8ca                	sd	s2,80(sp)
    8000497e:	e4ce                	sd	s3,72(sp)
    80004980:	e0d2                	sd	s4,64(sp)
    80004982:	fc56                	sd	s5,56(sp)
    80004984:	f85a                	sd	s6,48(sp)
    80004986:	f45e                	sd	s7,40(sp)
    80004988:	f062                	sd	s8,32(sp)
    8000498a:	ec66                	sd	s9,24(sp)
    8000498c:	1880                	addi	s0,sp,112
    8000498e:	84aa                	mv	s1,a0
    80004990:	8aae                	mv	s5,a1
    80004992:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004994:	ffffd097          	auipc	ra,0xffffd
    80004998:	01c080e7          	jalr	28(ra) # 800019b0 <myproc>
    8000499c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000499e:	8526                	mv	a0,s1
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	244080e7          	jalr	580(ra) # 80000be4 <acquire>
  while(i < n){
    800049a8:	0d405163          	blez	s4,80004a6a <pipewrite+0xf6>
    800049ac:	8ba6                	mv	s7,s1
  int i = 0;
    800049ae:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049b0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049b2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049b6:	21c48c13          	addi	s8,s1,540
    800049ba:	a08d                	j	80004a1c <pipewrite+0xa8>
      release(&pi->lock);
    800049bc:	8526                	mv	a0,s1
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	2da080e7          	jalr	730(ra) # 80000c98 <release>
      return -1;
    800049c6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049c8:	854a                	mv	a0,s2
    800049ca:	70a6                	ld	ra,104(sp)
    800049cc:	7406                	ld	s0,96(sp)
    800049ce:	64e6                	ld	s1,88(sp)
    800049d0:	6946                	ld	s2,80(sp)
    800049d2:	69a6                	ld	s3,72(sp)
    800049d4:	6a06                	ld	s4,64(sp)
    800049d6:	7ae2                	ld	s5,56(sp)
    800049d8:	7b42                	ld	s6,48(sp)
    800049da:	7ba2                	ld	s7,40(sp)
    800049dc:	7c02                	ld	s8,32(sp)
    800049de:	6ce2                	ld	s9,24(sp)
    800049e0:	6165                	addi	sp,sp,112
    800049e2:	8082                	ret
      wakeup(&pi->nread);
    800049e4:	8566                	mv	a0,s9
    800049e6:	ffffd097          	auipc	ra,0xffffd
    800049ea:	7f8080e7          	jalr	2040(ra) # 800021de <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049ee:	85de                	mv	a1,s7
    800049f0:	8562                	mv	a0,s8
    800049f2:	ffffd097          	auipc	ra,0xffffd
    800049f6:	660080e7          	jalr	1632(ra) # 80002052 <sleep>
    800049fa:	a839                	j	80004a18 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049fc:	21c4a783          	lw	a5,540(s1)
    80004a00:	0017871b          	addiw	a4,a5,1
    80004a04:	20e4ae23          	sw	a4,540(s1)
    80004a08:	1ff7f793          	andi	a5,a5,511
    80004a0c:	97a6                	add	a5,a5,s1
    80004a0e:	f9f44703          	lbu	a4,-97(s0)
    80004a12:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a16:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a18:	03495d63          	bge	s2,s4,80004a52 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a1c:	2204a783          	lw	a5,544(s1)
    80004a20:	dfd1                	beqz	a5,800049bc <pipewrite+0x48>
    80004a22:	0289a783          	lw	a5,40(s3)
    80004a26:	fbd9                	bnez	a5,800049bc <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a28:	2184a783          	lw	a5,536(s1)
    80004a2c:	21c4a703          	lw	a4,540(s1)
    80004a30:	2007879b          	addiw	a5,a5,512
    80004a34:	faf708e3          	beq	a4,a5,800049e4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a38:	4685                	li	a3,1
    80004a3a:	01590633          	add	a2,s2,s5
    80004a3e:	f9f40593          	addi	a1,s0,-97
    80004a42:	0509b503          	ld	a0,80(s3)
    80004a46:	ffffd097          	auipc	ra,0xffffd
    80004a4a:	cb8080e7          	jalr	-840(ra) # 800016fe <copyin>
    80004a4e:	fb6517e3          	bne	a0,s6,800049fc <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a52:	21848513          	addi	a0,s1,536
    80004a56:	ffffd097          	auipc	ra,0xffffd
    80004a5a:	788080e7          	jalr	1928(ra) # 800021de <wakeup>
  release(&pi->lock);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	238080e7          	jalr	568(ra) # 80000c98 <release>
  return i;
    80004a68:	b785                	j	800049c8 <pipewrite+0x54>
  int i = 0;
    80004a6a:	4901                	li	s2,0
    80004a6c:	b7dd                	j	80004a52 <pipewrite+0xde>

0000000080004a6e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a6e:	715d                	addi	sp,sp,-80
    80004a70:	e486                	sd	ra,72(sp)
    80004a72:	e0a2                	sd	s0,64(sp)
    80004a74:	fc26                	sd	s1,56(sp)
    80004a76:	f84a                	sd	s2,48(sp)
    80004a78:	f44e                	sd	s3,40(sp)
    80004a7a:	f052                	sd	s4,32(sp)
    80004a7c:	ec56                	sd	s5,24(sp)
    80004a7e:	e85a                	sd	s6,16(sp)
    80004a80:	0880                	addi	s0,sp,80
    80004a82:	84aa                	mv	s1,a0
    80004a84:	892e                	mv	s2,a1
    80004a86:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a88:	ffffd097          	auipc	ra,0xffffd
    80004a8c:	f28080e7          	jalr	-216(ra) # 800019b0 <myproc>
    80004a90:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a92:	8b26                	mv	s6,s1
    80004a94:	8526                	mv	a0,s1
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	14e080e7          	jalr	334(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a9e:	2184a703          	lw	a4,536(s1)
    80004aa2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aaa:	02f71463          	bne	a4,a5,80004ad2 <piperead+0x64>
    80004aae:	2244a783          	lw	a5,548(s1)
    80004ab2:	c385                	beqz	a5,80004ad2 <piperead+0x64>
    if(pr->killed){
    80004ab4:	028a2783          	lw	a5,40(s4)
    80004ab8:	ebc1                	bnez	a5,80004b48 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aba:	85da                	mv	a1,s6
    80004abc:	854e                	mv	a0,s3
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	594080e7          	jalr	1428(ra) # 80002052 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ac6:	2184a703          	lw	a4,536(s1)
    80004aca:	21c4a783          	lw	a5,540(s1)
    80004ace:	fef700e3          	beq	a4,a5,80004aae <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ad2:	09505263          	blez	s5,80004b56 <piperead+0xe8>
    80004ad6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ad8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ada:	2184a783          	lw	a5,536(s1)
    80004ade:	21c4a703          	lw	a4,540(s1)
    80004ae2:	02f70d63          	beq	a4,a5,80004b1c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ae6:	0017871b          	addiw	a4,a5,1
    80004aea:	20e4ac23          	sw	a4,536(s1)
    80004aee:	1ff7f793          	andi	a5,a5,511
    80004af2:	97a6                	add	a5,a5,s1
    80004af4:	0187c783          	lbu	a5,24(a5)
    80004af8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004afc:	4685                	li	a3,1
    80004afe:	fbf40613          	addi	a2,s0,-65
    80004b02:	85ca                	mv	a1,s2
    80004b04:	050a3503          	ld	a0,80(s4)
    80004b08:	ffffd097          	auipc	ra,0xffffd
    80004b0c:	b6a080e7          	jalr	-1174(ra) # 80001672 <copyout>
    80004b10:	01650663          	beq	a0,s6,80004b1c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b14:	2985                	addiw	s3,s3,1
    80004b16:	0905                	addi	s2,s2,1
    80004b18:	fd3a91e3          	bne	s5,s3,80004ada <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b1c:	21c48513          	addi	a0,s1,540
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	6be080e7          	jalr	1726(ra) # 800021de <wakeup>
  release(&pi->lock);
    80004b28:	8526                	mv	a0,s1
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	16e080e7          	jalr	366(ra) # 80000c98 <release>
  return i;
}
    80004b32:	854e                	mv	a0,s3
    80004b34:	60a6                	ld	ra,72(sp)
    80004b36:	6406                	ld	s0,64(sp)
    80004b38:	74e2                	ld	s1,56(sp)
    80004b3a:	7942                	ld	s2,48(sp)
    80004b3c:	79a2                	ld	s3,40(sp)
    80004b3e:	7a02                	ld	s4,32(sp)
    80004b40:	6ae2                	ld	s5,24(sp)
    80004b42:	6b42                	ld	s6,16(sp)
    80004b44:	6161                	addi	sp,sp,80
    80004b46:	8082                	ret
      release(&pi->lock);
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
      return -1;
    80004b52:	59fd                	li	s3,-1
    80004b54:	bff9                	j	80004b32 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b56:	4981                	li	s3,0
    80004b58:	b7d1                	j	80004b1c <piperead+0xae>

0000000080004b5a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b5a:	df010113          	addi	sp,sp,-528
    80004b5e:	20113423          	sd	ra,520(sp)
    80004b62:	20813023          	sd	s0,512(sp)
    80004b66:	ffa6                	sd	s1,504(sp)
    80004b68:	fbca                	sd	s2,496(sp)
    80004b6a:	f7ce                	sd	s3,488(sp)
    80004b6c:	f3d2                	sd	s4,480(sp)
    80004b6e:	efd6                	sd	s5,472(sp)
    80004b70:	ebda                	sd	s6,464(sp)
    80004b72:	e7de                	sd	s7,456(sp)
    80004b74:	e3e2                	sd	s8,448(sp)
    80004b76:	ff66                	sd	s9,440(sp)
    80004b78:	fb6a                	sd	s10,432(sp)
    80004b7a:	f76e                	sd	s11,424(sp)
    80004b7c:	0c00                	addi	s0,sp,528
    80004b7e:	84aa                	mv	s1,a0
    80004b80:	dea43c23          	sd	a0,-520(s0)
    80004b84:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	e28080e7          	jalr	-472(ra) # 800019b0 <myproc>
    80004b90:	892a                	mv	s2,a0

  begin_op();
    80004b92:	fffff097          	auipc	ra,0xfffff
    80004b96:	49c080e7          	jalr	1180(ra) # 8000402e <begin_op>

  if((ip = namei(path)) == 0){
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	276080e7          	jalr	630(ra) # 80003e12 <namei>
    80004ba4:	c92d                	beqz	a0,80004c16 <exec+0xbc>
    80004ba6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	ab4080e7          	jalr	-1356(ra) # 8000365c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bb0:	04000713          	li	a4,64
    80004bb4:	4681                	li	a3,0
    80004bb6:	e5040613          	addi	a2,s0,-432
    80004bba:	4581                	li	a1,0
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	d52080e7          	jalr	-686(ra) # 80003910 <readi>
    80004bc6:	04000793          	li	a5,64
    80004bca:	00f51a63          	bne	a0,a5,80004bde <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004bce:	e5042703          	lw	a4,-432(s0)
    80004bd2:	464c47b7          	lui	a5,0x464c4
    80004bd6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bda:	04f70463          	beq	a4,a5,80004c22 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bde:	8526                	mv	a0,s1
    80004be0:	fffff097          	auipc	ra,0xfffff
    80004be4:	cde080e7          	jalr	-802(ra) # 800038be <iunlockput>
    end_op();
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	4c6080e7          	jalr	1222(ra) # 800040ae <end_op>
  }
  return -1;
    80004bf0:	557d                	li	a0,-1
}
    80004bf2:	20813083          	ld	ra,520(sp)
    80004bf6:	20013403          	ld	s0,512(sp)
    80004bfa:	74fe                	ld	s1,504(sp)
    80004bfc:	795e                	ld	s2,496(sp)
    80004bfe:	79be                	ld	s3,488(sp)
    80004c00:	7a1e                	ld	s4,480(sp)
    80004c02:	6afe                	ld	s5,472(sp)
    80004c04:	6b5e                	ld	s6,464(sp)
    80004c06:	6bbe                	ld	s7,456(sp)
    80004c08:	6c1e                	ld	s8,448(sp)
    80004c0a:	7cfa                	ld	s9,440(sp)
    80004c0c:	7d5a                	ld	s10,432(sp)
    80004c0e:	7dba                	ld	s11,424(sp)
    80004c10:	21010113          	addi	sp,sp,528
    80004c14:	8082                	ret
    end_op();
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	498080e7          	jalr	1176(ra) # 800040ae <end_op>
    return -1;
    80004c1e:	557d                	li	a0,-1
    80004c20:	bfc9                	j	80004bf2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c22:	854a                	mv	a0,s2
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	e50080e7          	jalr	-432(ra) # 80001a74 <proc_pagetable>
    80004c2c:	8baa                	mv	s7,a0
    80004c2e:	d945                	beqz	a0,80004bde <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c30:	e7042983          	lw	s3,-400(s0)
    80004c34:	e8845783          	lhu	a5,-376(s0)
    80004c38:	c7ad                	beqz	a5,80004ca2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c3a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c3c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004c3e:	6c85                	lui	s9,0x1
    80004c40:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c44:	def43823          	sd	a5,-528(s0)
    80004c48:	a42d                	j	80004e72 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c4a:	00004517          	auipc	a0,0x4
    80004c4e:	a7e50513          	addi	a0,a0,-1410 # 800086c8 <syscalls+0x280>
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c5a:	8756                	mv	a4,s5
    80004c5c:	012d86bb          	addw	a3,s11,s2
    80004c60:	4581                	li	a1,0
    80004c62:	8526                	mv	a0,s1
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	cac080e7          	jalr	-852(ra) # 80003910 <readi>
    80004c6c:	2501                	sext.w	a0,a0
    80004c6e:	1aaa9963          	bne	s5,a0,80004e20 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c72:	6785                	lui	a5,0x1
    80004c74:	0127893b          	addw	s2,a5,s2
    80004c78:	77fd                	lui	a5,0xfffff
    80004c7a:	01478a3b          	addw	s4,a5,s4
    80004c7e:	1f897163          	bgeu	s2,s8,80004e60 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c82:	02091593          	slli	a1,s2,0x20
    80004c86:	9181                	srli	a1,a1,0x20
    80004c88:	95ea                	add	a1,a1,s10
    80004c8a:	855e                	mv	a0,s7
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	3e2080e7          	jalr	994(ra) # 8000106e <walkaddr>
    80004c94:	862a                	mv	a2,a0
    if(pa == 0)
    80004c96:	d955                	beqz	a0,80004c4a <exec+0xf0>
      n = PGSIZE;
    80004c98:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c9a:	fd9a70e3          	bgeu	s4,s9,80004c5a <exec+0x100>
      n = sz - i;
    80004c9e:	8ad2                	mv	s5,s4
    80004ca0:	bf6d                	j	80004c5a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ca2:	4901                	li	s2,0
  iunlockput(ip);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	c18080e7          	jalr	-1000(ra) # 800038be <iunlockput>
  end_op();
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	400080e7          	jalr	1024(ra) # 800040ae <end_op>
  p = myproc();
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	cfa080e7          	jalr	-774(ra) # 800019b0 <myproc>
    80004cbe:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004cc0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cc4:	6785                	lui	a5,0x1
    80004cc6:	17fd                	addi	a5,a5,-1
    80004cc8:	993e                	add	s2,s2,a5
    80004cca:	757d                	lui	a0,0xfffff
    80004ccc:	00a977b3          	and	a5,s2,a0
    80004cd0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cd4:	6609                	lui	a2,0x2
    80004cd6:	963e                	add	a2,a2,a5
    80004cd8:	85be                	mv	a1,a5
    80004cda:	855e                	mv	a0,s7
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	746080e7          	jalr	1862(ra) # 80001422 <uvmalloc>
    80004ce4:	8b2a                	mv	s6,a0
  ip = 0;
    80004ce6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ce8:	12050c63          	beqz	a0,80004e20 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cec:	75f9                	lui	a1,0xffffe
    80004cee:	95aa                	add	a1,a1,a0
    80004cf0:	855e                	mv	a0,s7
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	94e080e7          	jalr	-1714(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004cfa:	7c7d                	lui	s8,0xfffff
    80004cfc:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004cfe:	e0043783          	ld	a5,-512(s0)
    80004d02:	6388                	ld	a0,0(a5)
    80004d04:	c535                	beqz	a0,80004d70 <exec+0x216>
    80004d06:	e9040993          	addi	s3,s0,-368
    80004d0a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d0e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	154080e7          	jalr	340(ra) # 80000e64 <strlen>
    80004d18:	2505                	addiw	a0,a0,1
    80004d1a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d1e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d22:	13896363          	bltu	s2,s8,80004e48 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d26:	e0043d83          	ld	s11,-512(s0)
    80004d2a:	000dba03          	ld	s4,0(s11)
    80004d2e:	8552                	mv	a0,s4
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	134080e7          	jalr	308(ra) # 80000e64 <strlen>
    80004d38:	0015069b          	addiw	a3,a0,1
    80004d3c:	8652                	mv	a2,s4
    80004d3e:	85ca                	mv	a1,s2
    80004d40:	855e                	mv	a0,s7
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	930080e7          	jalr	-1744(ra) # 80001672 <copyout>
    80004d4a:	10054363          	bltz	a0,80004e50 <exec+0x2f6>
    ustack[argc] = sp;
    80004d4e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d52:	0485                	addi	s1,s1,1
    80004d54:	008d8793          	addi	a5,s11,8
    80004d58:	e0f43023          	sd	a5,-512(s0)
    80004d5c:	008db503          	ld	a0,8(s11)
    80004d60:	c911                	beqz	a0,80004d74 <exec+0x21a>
    if(argc >= MAXARG)
    80004d62:	09a1                	addi	s3,s3,8
    80004d64:	fb3c96e3          	bne	s9,s3,80004d10 <exec+0x1b6>
  sz = sz1;
    80004d68:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d6c:	4481                	li	s1,0
    80004d6e:	a84d                	j	80004e20 <exec+0x2c6>
  sp = sz;
    80004d70:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d72:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d74:	00349793          	slli	a5,s1,0x3
    80004d78:	f9040713          	addi	a4,s0,-112
    80004d7c:	97ba                	add	a5,a5,a4
    80004d7e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004d82:	00148693          	addi	a3,s1,1
    80004d86:	068e                	slli	a3,a3,0x3
    80004d88:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d8c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d90:	01897663          	bgeu	s2,s8,80004d9c <exec+0x242>
  sz = sz1;
    80004d94:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d98:	4481                	li	s1,0
    80004d9a:	a059                	j	80004e20 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d9c:	e9040613          	addi	a2,s0,-368
    80004da0:	85ca                	mv	a1,s2
    80004da2:	855e                	mv	a0,s7
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	8ce080e7          	jalr	-1842(ra) # 80001672 <copyout>
    80004dac:	0a054663          	bltz	a0,80004e58 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004db0:	058ab783          	ld	a5,88(s5)
    80004db4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004db8:	df843783          	ld	a5,-520(s0)
    80004dbc:	0007c703          	lbu	a4,0(a5)
    80004dc0:	cf11                	beqz	a4,80004ddc <exec+0x282>
    80004dc2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dc4:	02f00693          	li	a3,47
    80004dc8:	a039                	j	80004dd6 <exec+0x27c>
      last = s+1;
    80004dca:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004dce:	0785                	addi	a5,a5,1
    80004dd0:	fff7c703          	lbu	a4,-1(a5)
    80004dd4:	c701                	beqz	a4,80004ddc <exec+0x282>
    if(*s == '/')
    80004dd6:	fed71ce3          	bne	a4,a3,80004dce <exec+0x274>
    80004dda:	bfc5                	j	80004dca <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ddc:	4641                	li	a2,16
    80004dde:	df843583          	ld	a1,-520(s0)
    80004de2:	158a8513          	addi	a0,s5,344
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	04c080e7          	jalr	76(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004dee:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004df2:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004df6:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004dfa:	058ab783          	ld	a5,88(s5)
    80004dfe:	e6843703          	ld	a4,-408(s0)
    80004e02:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e04:	058ab783          	ld	a5,88(s5)
    80004e08:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e0c:	85ea                	mv	a1,s10
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	d02080e7          	jalr	-766(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e16:	0004851b          	sext.w	a0,s1
    80004e1a:	bbe1                	j	80004bf2 <exec+0x98>
    80004e1c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e20:	e0843583          	ld	a1,-504(s0)
    80004e24:	855e                	mv	a0,s7
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	cea080e7          	jalr	-790(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004e2e:	da0498e3          	bnez	s1,80004bde <exec+0x84>
  return -1;
    80004e32:	557d                	li	a0,-1
    80004e34:	bb7d                	j	80004bf2 <exec+0x98>
    80004e36:	e1243423          	sd	s2,-504(s0)
    80004e3a:	b7dd                	j	80004e20 <exec+0x2c6>
    80004e3c:	e1243423          	sd	s2,-504(s0)
    80004e40:	b7c5                	j	80004e20 <exec+0x2c6>
    80004e42:	e1243423          	sd	s2,-504(s0)
    80004e46:	bfe9                	j	80004e20 <exec+0x2c6>
  sz = sz1;
    80004e48:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e4c:	4481                	li	s1,0
    80004e4e:	bfc9                	j	80004e20 <exec+0x2c6>
  sz = sz1;
    80004e50:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e54:	4481                	li	s1,0
    80004e56:	b7e9                	j	80004e20 <exec+0x2c6>
  sz = sz1;
    80004e58:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e5c:	4481                	li	s1,0
    80004e5e:	b7c9                	j	80004e20 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e60:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e64:	2b05                	addiw	s6,s6,1
    80004e66:	0389899b          	addiw	s3,s3,56
    80004e6a:	e8845783          	lhu	a5,-376(s0)
    80004e6e:	e2fb5be3          	bge	s6,a5,80004ca4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e72:	2981                	sext.w	s3,s3
    80004e74:	03800713          	li	a4,56
    80004e78:	86ce                	mv	a3,s3
    80004e7a:	e1840613          	addi	a2,s0,-488
    80004e7e:	4581                	li	a1,0
    80004e80:	8526                	mv	a0,s1
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	a8e080e7          	jalr	-1394(ra) # 80003910 <readi>
    80004e8a:	03800793          	li	a5,56
    80004e8e:	f8f517e3          	bne	a0,a5,80004e1c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e92:	e1842783          	lw	a5,-488(s0)
    80004e96:	4705                	li	a4,1
    80004e98:	fce796e3          	bne	a5,a4,80004e64 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e9c:	e4043603          	ld	a2,-448(s0)
    80004ea0:	e3843783          	ld	a5,-456(s0)
    80004ea4:	f8f669e3          	bltu	a2,a5,80004e36 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ea8:	e2843783          	ld	a5,-472(s0)
    80004eac:	963e                	add	a2,a2,a5
    80004eae:	f8f667e3          	bltu	a2,a5,80004e3c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eb2:	85ca                	mv	a1,s2
    80004eb4:	855e                	mv	a0,s7
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	56c080e7          	jalr	1388(ra) # 80001422 <uvmalloc>
    80004ebe:	e0a43423          	sd	a0,-504(s0)
    80004ec2:	d141                	beqz	a0,80004e42 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004ec4:	e2843d03          	ld	s10,-472(s0)
    80004ec8:	df043783          	ld	a5,-528(s0)
    80004ecc:	00fd77b3          	and	a5,s10,a5
    80004ed0:	fba1                	bnez	a5,80004e20 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ed2:	e2042d83          	lw	s11,-480(s0)
    80004ed6:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004eda:	f80c03e3          	beqz	s8,80004e60 <exec+0x306>
    80004ede:	8a62                	mv	s4,s8
    80004ee0:	4901                	li	s2,0
    80004ee2:	b345                	j	80004c82 <exec+0x128>

0000000080004ee4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ee4:	7179                	addi	sp,sp,-48
    80004ee6:	f406                	sd	ra,40(sp)
    80004ee8:	f022                	sd	s0,32(sp)
    80004eea:	ec26                	sd	s1,24(sp)
    80004eec:	e84a                	sd	s2,16(sp)
    80004eee:	1800                	addi	s0,sp,48
    80004ef0:	892e                	mv	s2,a1
    80004ef2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ef4:	fdc40593          	addi	a1,s0,-36
    80004ef8:	ffffe097          	auipc	ra,0xffffe
    80004efc:	ba8080e7          	jalr	-1112(ra) # 80002aa0 <argint>
    80004f00:	04054063          	bltz	a0,80004f40 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f04:	fdc42703          	lw	a4,-36(s0)
    80004f08:	47bd                	li	a5,15
    80004f0a:	02e7ed63          	bltu	a5,a4,80004f44 <argfd+0x60>
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	aa2080e7          	jalr	-1374(ra) # 800019b0 <myproc>
    80004f16:	fdc42703          	lw	a4,-36(s0)
    80004f1a:	01a70793          	addi	a5,a4,26
    80004f1e:	078e                	slli	a5,a5,0x3
    80004f20:	953e                	add	a0,a0,a5
    80004f22:	611c                	ld	a5,0(a0)
    80004f24:	c395                	beqz	a5,80004f48 <argfd+0x64>
    return -1;
  if(pfd)
    80004f26:	00090463          	beqz	s2,80004f2e <argfd+0x4a>
    *pfd = fd;
    80004f2a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f2e:	4501                	li	a0,0
  if(pf)
    80004f30:	c091                	beqz	s1,80004f34 <argfd+0x50>
    *pf = f;
    80004f32:	e09c                	sd	a5,0(s1)
}
    80004f34:	70a2                	ld	ra,40(sp)
    80004f36:	7402                	ld	s0,32(sp)
    80004f38:	64e2                	ld	s1,24(sp)
    80004f3a:	6942                	ld	s2,16(sp)
    80004f3c:	6145                	addi	sp,sp,48
    80004f3e:	8082                	ret
    return -1;
    80004f40:	557d                	li	a0,-1
    80004f42:	bfcd                	j	80004f34 <argfd+0x50>
    return -1;
    80004f44:	557d                	li	a0,-1
    80004f46:	b7fd                	j	80004f34 <argfd+0x50>
    80004f48:	557d                	li	a0,-1
    80004f4a:	b7ed                	j	80004f34 <argfd+0x50>

0000000080004f4c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f4c:	1101                	addi	sp,sp,-32
    80004f4e:	ec06                	sd	ra,24(sp)
    80004f50:	e822                	sd	s0,16(sp)
    80004f52:	e426                	sd	s1,8(sp)
    80004f54:	1000                	addi	s0,sp,32
    80004f56:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	a58080e7          	jalr	-1448(ra) # 800019b0 <myproc>
    80004f60:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f62:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004f66:	4501                	li	a0,0
    80004f68:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f6a:	6398                	ld	a4,0(a5)
    80004f6c:	cb19                	beqz	a4,80004f82 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f6e:	2505                	addiw	a0,a0,1
    80004f70:	07a1                	addi	a5,a5,8
    80004f72:	fed51ce3          	bne	a0,a3,80004f6a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f76:	557d                	li	a0,-1
}
    80004f78:	60e2                	ld	ra,24(sp)
    80004f7a:	6442                	ld	s0,16(sp)
    80004f7c:	64a2                	ld	s1,8(sp)
    80004f7e:	6105                	addi	sp,sp,32
    80004f80:	8082                	ret
      p->ofile[fd] = f;
    80004f82:	01a50793          	addi	a5,a0,26
    80004f86:	078e                	slli	a5,a5,0x3
    80004f88:	963e                	add	a2,a2,a5
    80004f8a:	e204                	sd	s1,0(a2)
      return fd;
    80004f8c:	b7f5                	j	80004f78 <fdalloc+0x2c>

0000000080004f8e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f8e:	715d                	addi	sp,sp,-80
    80004f90:	e486                	sd	ra,72(sp)
    80004f92:	e0a2                	sd	s0,64(sp)
    80004f94:	fc26                	sd	s1,56(sp)
    80004f96:	f84a                	sd	s2,48(sp)
    80004f98:	f44e                	sd	s3,40(sp)
    80004f9a:	f052                	sd	s4,32(sp)
    80004f9c:	ec56                	sd	s5,24(sp)
    80004f9e:	0880                	addi	s0,sp,80
    80004fa0:	89ae                	mv	s3,a1
    80004fa2:	8ab2                	mv	s5,a2
    80004fa4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fa6:	fb040593          	addi	a1,s0,-80
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	e86080e7          	jalr	-378(ra) # 80003e30 <nameiparent>
    80004fb2:	892a                	mv	s2,a0
    80004fb4:	12050f63          	beqz	a0,800050f2 <create+0x164>
    return 0;

  ilock(dp);
    80004fb8:	ffffe097          	auipc	ra,0xffffe
    80004fbc:	6a4080e7          	jalr	1700(ra) # 8000365c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fc0:	4601                	li	a2,0
    80004fc2:	fb040593          	addi	a1,s0,-80
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	fffff097          	auipc	ra,0xfffff
    80004fcc:	b78080e7          	jalr	-1160(ra) # 80003b40 <dirlookup>
    80004fd0:	84aa                	mv	s1,a0
    80004fd2:	c921                	beqz	a0,80005022 <create+0x94>
    iunlockput(dp);
    80004fd4:	854a                	mv	a0,s2
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	8e8080e7          	jalr	-1816(ra) # 800038be <iunlockput>
    ilock(ip);
    80004fde:	8526                	mv	a0,s1
    80004fe0:	ffffe097          	auipc	ra,0xffffe
    80004fe4:	67c080e7          	jalr	1660(ra) # 8000365c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fe8:	2981                	sext.w	s3,s3
    80004fea:	4789                	li	a5,2
    80004fec:	02f99463          	bne	s3,a5,80005014 <create+0x86>
    80004ff0:	0444d783          	lhu	a5,68(s1)
    80004ff4:	37f9                	addiw	a5,a5,-2
    80004ff6:	17c2                	slli	a5,a5,0x30
    80004ff8:	93c1                	srli	a5,a5,0x30
    80004ffa:	4705                	li	a4,1
    80004ffc:	00f76c63          	bltu	a4,a5,80005014 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005000:	8526                	mv	a0,s1
    80005002:	60a6                	ld	ra,72(sp)
    80005004:	6406                	ld	s0,64(sp)
    80005006:	74e2                	ld	s1,56(sp)
    80005008:	7942                	ld	s2,48(sp)
    8000500a:	79a2                	ld	s3,40(sp)
    8000500c:	7a02                	ld	s4,32(sp)
    8000500e:	6ae2                	ld	s5,24(sp)
    80005010:	6161                	addi	sp,sp,80
    80005012:	8082                	ret
    iunlockput(ip);
    80005014:	8526                	mv	a0,s1
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	8a8080e7          	jalr	-1880(ra) # 800038be <iunlockput>
    return 0;
    8000501e:	4481                	li	s1,0
    80005020:	b7c5                	j	80005000 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005022:	85ce                	mv	a1,s3
    80005024:	00092503          	lw	a0,0(s2)
    80005028:	ffffe097          	auipc	ra,0xffffe
    8000502c:	49c080e7          	jalr	1180(ra) # 800034c4 <ialloc>
    80005030:	84aa                	mv	s1,a0
    80005032:	c529                	beqz	a0,8000507c <create+0xee>
  ilock(ip);
    80005034:	ffffe097          	auipc	ra,0xffffe
    80005038:	628080e7          	jalr	1576(ra) # 8000365c <ilock>
  ip->major = major;
    8000503c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005040:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005044:	4785                	li	a5,1
    80005046:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000504a:	8526                	mv	a0,s1
    8000504c:	ffffe097          	auipc	ra,0xffffe
    80005050:	546080e7          	jalr	1350(ra) # 80003592 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005054:	2981                	sext.w	s3,s3
    80005056:	4785                	li	a5,1
    80005058:	02f98a63          	beq	s3,a5,8000508c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000505c:	40d0                	lw	a2,4(s1)
    8000505e:	fb040593          	addi	a1,s0,-80
    80005062:	854a                	mv	a0,s2
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	cec080e7          	jalr	-788(ra) # 80003d50 <dirlink>
    8000506c:	06054b63          	bltz	a0,800050e2 <create+0x154>
  iunlockput(dp);
    80005070:	854a                	mv	a0,s2
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	84c080e7          	jalr	-1972(ra) # 800038be <iunlockput>
  return ip;
    8000507a:	b759                	j	80005000 <create+0x72>
    panic("create: ialloc");
    8000507c:	00003517          	auipc	a0,0x3
    80005080:	66c50513          	addi	a0,a0,1644 # 800086e8 <syscalls+0x2a0>
    80005084:	ffffb097          	auipc	ra,0xffffb
    80005088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000508c:	04a95783          	lhu	a5,74(s2)
    80005090:	2785                	addiw	a5,a5,1
    80005092:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005096:	854a                	mv	a0,s2
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	4fa080e7          	jalr	1274(ra) # 80003592 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050a0:	40d0                	lw	a2,4(s1)
    800050a2:	00003597          	auipc	a1,0x3
    800050a6:	65658593          	addi	a1,a1,1622 # 800086f8 <syscalls+0x2b0>
    800050aa:	8526                	mv	a0,s1
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	ca4080e7          	jalr	-860(ra) # 80003d50 <dirlink>
    800050b4:	00054f63          	bltz	a0,800050d2 <create+0x144>
    800050b8:	00492603          	lw	a2,4(s2)
    800050bc:	00003597          	auipc	a1,0x3
    800050c0:	64458593          	addi	a1,a1,1604 # 80008700 <syscalls+0x2b8>
    800050c4:	8526                	mv	a0,s1
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	c8a080e7          	jalr	-886(ra) # 80003d50 <dirlink>
    800050ce:	f80557e3          	bgez	a0,8000505c <create+0xce>
      panic("create dots");
    800050d2:	00003517          	auipc	a0,0x3
    800050d6:	63650513          	addi	a0,a0,1590 # 80008708 <syscalls+0x2c0>
    800050da:	ffffb097          	auipc	ra,0xffffb
    800050de:	464080e7          	jalr	1124(ra) # 8000053e <panic>
    panic("create: dirlink");
    800050e2:	00003517          	auipc	a0,0x3
    800050e6:	63650513          	addi	a0,a0,1590 # 80008718 <syscalls+0x2d0>
    800050ea:	ffffb097          	auipc	ra,0xffffb
    800050ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>
    return 0;
    800050f2:	84aa                	mv	s1,a0
    800050f4:	b731                	j	80005000 <create+0x72>

00000000800050f6 <sys_dup>:
{
    800050f6:	7179                	addi	sp,sp,-48
    800050f8:	f406                	sd	ra,40(sp)
    800050fa:	f022                	sd	s0,32(sp)
    800050fc:	ec26                	sd	s1,24(sp)
    800050fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005100:	fd840613          	addi	a2,s0,-40
    80005104:	4581                	li	a1,0
    80005106:	4501                	li	a0,0
    80005108:	00000097          	auipc	ra,0x0
    8000510c:	ddc080e7          	jalr	-548(ra) # 80004ee4 <argfd>
    return -1;
    80005110:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005112:	02054363          	bltz	a0,80005138 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005116:	fd843503          	ld	a0,-40(s0)
    8000511a:	00000097          	auipc	ra,0x0
    8000511e:	e32080e7          	jalr	-462(ra) # 80004f4c <fdalloc>
    80005122:	84aa                	mv	s1,a0
    return -1;
    80005124:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005126:	00054963          	bltz	a0,80005138 <sys_dup+0x42>
  filedup(f);
    8000512a:	fd843503          	ld	a0,-40(s0)
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	37a080e7          	jalr	890(ra) # 800044a8 <filedup>
  return fd;
    80005136:	87a6                	mv	a5,s1
}
    80005138:	853e                	mv	a0,a5
    8000513a:	70a2                	ld	ra,40(sp)
    8000513c:	7402                	ld	s0,32(sp)
    8000513e:	64e2                	ld	s1,24(sp)
    80005140:	6145                	addi	sp,sp,48
    80005142:	8082                	ret

0000000080005144 <sys_read>:
{
    80005144:	7179                	addi	sp,sp,-48
    80005146:	f406                	sd	ra,40(sp)
    80005148:	f022                	sd	s0,32(sp)
    8000514a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000514c:	fe840613          	addi	a2,s0,-24
    80005150:	4581                	li	a1,0
    80005152:	4501                	li	a0,0
    80005154:	00000097          	auipc	ra,0x0
    80005158:	d90080e7          	jalr	-624(ra) # 80004ee4 <argfd>
    return -1;
    8000515c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515e:	04054163          	bltz	a0,800051a0 <sys_read+0x5c>
    80005162:	fe440593          	addi	a1,s0,-28
    80005166:	4509                	li	a0,2
    80005168:	ffffe097          	auipc	ra,0xffffe
    8000516c:	938080e7          	jalr	-1736(ra) # 80002aa0 <argint>
    return -1;
    80005170:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005172:	02054763          	bltz	a0,800051a0 <sys_read+0x5c>
    80005176:	fd840593          	addi	a1,s0,-40
    8000517a:	4505                	li	a0,1
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	946080e7          	jalr	-1722(ra) # 80002ac2 <argaddr>
    return -1;
    80005184:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005186:	00054d63          	bltz	a0,800051a0 <sys_read+0x5c>
  return fileread(f, p, n);
    8000518a:	fe442603          	lw	a2,-28(s0)
    8000518e:	fd843583          	ld	a1,-40(s0)
    80005192:	fe843503          	ld	a0,-24(s0)
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	49e080e7          	jalr	1182(ra) # 80004634 <fileread>
    8000519e:	87aa                	mv	a5,a0
}
    800051a0:	853e                	mv	a0,a5
    800051a2:	70a2                	ld	ra,40(sp)
    800051a4:	7402                	ld	s0,32(sp)
    800051a6:	6145                	addi	sp,sp,48
    800051a8:	8082                	ret

00000000800051aa <sys_write>:
{
    800051aa:	7179                	addi	sp,sp,-48
    800051ac:	f406                	sd	ra,40(sp)
    800051ae:	f022                	sd	s0,32(sp)
    800051b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b2:	fe840613          	addi	a2,s0,-24
    800051b6:	4581                	li	a1,0
    800051b8:	4501                	li	a0,0
    800051ba:	00000097          	auipc	ra,0x0
    800051be:	d2a080e7          	jalr	-726(ra) # 80004ee4 <argfd>
    return -1;
    800051c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c4:	04054163          	bltz	a0,80005206 <sys_write+0x5c>
    800051c8:	fe440593          	addi	a1,s0,-28
    800051cc:	4509                	li	a0,2
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	8d2080e7          	jalr	-1838(ra) # 80002aa0 <argint>
    return -1;
    800051d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d8:	02054763          	bltz	a0,80005206 <sys_write+0x5c>
    800051dc:	fd840593          	addi	a1,s0,-40
    800051e0:	4505                	li	a0,1
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	8e0080e7          	jalr	-1824(ra) # 80002ac2 <argaddr>
    return -1;
    800051ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ec:	00054d63          	bltz	a0,80005206 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051f0:	fe442603          	lw	a2,-28(s0)
    800051f4:	fd843583          	ld	a1,-40(s0)
    800051f8:	fe843503          	ld	a0,-24(s0)
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	4fa080e7          	jalr	1274(ra) # 800046f6 <filewrite>
    80005204:	87aa                	mv	a5,a0
}
    80005206:	853e                	mv	a0,a5
    80005208:	70a2                	ld	ra,40(sp)
    8000520a:	7402                	ld	s0,32(sp)
    8000520c:	6145                	addi	sp,sp,48
    8000520e:	8082                	ret

0000000080005210 <sys_close>:
{
    80005210:	1101                	addi	sp,sp,-32
    80005212:	ec06                	sd	ra,24(sp)
    80005214:	e822                	sd	s0,16(sp)
    80005216:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005218:	fe040613          	addi	a2,s0,-32
    8000521c:	fec40593          	addi	a1,s0,-20
    80005220:	4501                	li	a0,0
    80005222:	00000097          	auipc	ra,0x0
    80005226:	cc2080e7          	jalr	-830(ra) # 80004ee4 <argfd>
    return -1;
    8000522a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000522c:	02054463          	bltz	a0,80005254 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	780080e7          	jalr	1920(ra) # 800019b0 <myproc>
    80005238:	fec42783          	lw	a5,-20(s0)
    8000523c:	07e9                	addi	a5,a5,26
    8000523e:	078e                	slli	a5,a5,0x3
    80005240:	97aa                	add	a5,a5,a0
    80005242:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005246:	fe043503          	ld	a0,-32(s0)
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	2b0080e7          	jalr	688(ra) # 800044fa <fileclose>
  return 0;
    80005252:	4781                	li	a5,0
}
    80005254:	853e                	mv	a0,a5
    80005256:	60e2                	ld	ra,24(sp)
    80005258:	6442                	ld	s0,16(sp)
    8000525a:	6105                	addi	sp,sp,32
    8000525c:	8082                	ret

000000008000525e <sys_fstat>:
{
    8000525e:	1101                	addi	sp,sp,-32
    80005260:	ec06                	sd	ra,24(sp)
    80005262:	e822                	sd	s0,16(sp)
    80005264:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005266:	fe840613          	addi	a2,s0,-24
    8000526a:	4581                	li	a1,0
    8000526c:	4501                	li	a0,0
    8000526e:	00000097          	auipc	ra,0x0
    80005272:	c76080e7          	jalr	-906(ra) # 80004ee4 <argfd>
    return -1;
    80005276:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005278:	02054563          	bltz	a0,800052a2 <sys_fstat+0x44>
    8000527c:	fe040593          	addi	a1,s0,-32
    80005280:	4505                	li	a0,1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	840080e7          	jalr	-1984(ra) # 80002ac2 <argaddr>
    return -1;
    8000528a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000528c:	00054b63          	bltz	a0,800052a2 <sys_fstat+0x44>
  return filestat(f, st);
    80005290:	fe043583          	ld	a1,-32(s0)
    80005294:	fe843503          	ld	a0,-24(s0)
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	32a080e7          	jalr	810(ra) # 800045c2 <filestat>
    800052a0:	87aa                	mv	a5,a0
}
    800052a2:	853e                	mv	a0,a5
    800052a4:	60e2                	ld	ra,24(sp)
    800052a6:	6442                	ld	s0,16(sp)
    800052a8:	6105                	addi	sp,sp,32
    800052aa:	8082                	ret

00000000800052ac <sys_link>:
{
    800052ac:	7169                	addi	sp,sp,-304
    800052ae:	f606                	sd	ra,296(sp)
    800052b0:	f222                	sd	s0,288(sp)
    800052b2:	ee26                	sd	s1,280(sp)
    800052b4:	ea4a                	sd	s2,272(sp)
    800052b6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052b8:	08000613          	li	a2,128
    800052bc:	ed040593          	addi	a1,s0,-304
    800052c0:	4501                	li	a0,0
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	822080e7          	jalr	-2014(ra) # 80002ae4 <argstr>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052cc:	10054e63          	bltz	a0,800053e8 <sys_link+0x13c>
    800052d0:	08000613          	li	a2,128
    800052d4:	f5040593          	addi	a1,s0,-176
    800052d8:	4505                	li	a0,1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	80a080e7          	jalr	-2038(ra) # 80002ae4 <argstr>
    return -1;
    800052e2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052e4:	10054263          	bltz	a0,800053e8 <sys_link+0x13c>
  begin_op();
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	d46080e7          	jalr	-698(ra) # 8000402e <begin_op>
  if((ip = namei(old)) == 0){
    800052f0:	ed040513          	addi	a0,s0,-304
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	b1e080e7          	jalr	-1250(ra) # 80003e12 <namei>
    800052fc:	84aa                	mv	s1,a0
    800052fe:	c551                	beqz	a0,8000538a <sys_link+0xde>
  ilock(ip);
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	35c080e7          	jalr	860(ra) # 8000365c <ilock>
  if(ip->type == T_DIR){
    80005308:	04449703          	lh	a4,68(s1)
    8000530c:	4785                	li	a5,1
    8000530e:	08f70463          	beq	a4,a5,80005396 <sys_link+0xea>
  ip->nlink++;
    80005312:	04a4d783          	lhu	a5,74(s1)
    80005316:	2785                	addiw	a5,a5,1
    80005318:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000531c:	8526                	mv	a0,s1
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	274080e7          	jalr	628(ra) # 80003592 <iupdate>
  iunlock(ip);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	3f6080e7          	jalr	1014(ra) # 8000371e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005330:	fd040593          	addi	a1,s0,-48
    80005334:	f5040513          	addi	a0,s0,-176
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	af8080e7          	jalr	-1288(ra) # 80003e30 <nameiparent>
    80005340:	892a                	mv	s2,a0
    80005342:	c935                	beqz	a0,800053b6 <sys_link+0x10a>
  ilock(dp);
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	318080e7          	jalr	792(ra) # 8000365c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000534c:	00092703          	lw	a4,0(s2)
    80005350:	409c                	lw	a5,0(s1)
    80005352:	04f71d63          	bne	a4,a5,800053ac <sys_link+0x100>
    80005356:	40d0                	lw	a2,4(s1)
    80005358:	fd040593          	addi	a1,s0,-48
    8000535c:	854a                	mv	a0,s2
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	9f2080e7          	jalr	-1550(ra) # 80003d50 <dirlink>
    80005366:	04054363          	bltz	a0,800053ac <sys_link+0x100>
  iunlockput(dp);
    8000536a:	854a                	mv	a0,s2
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	552080e7          	jalr	1362(ra) # 800038be <iunlockput>
  iput(ip);
    80005374:	8526                	mv	a0,s1
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	4a0080e7          	jalr	1184(ra) # 80003816 <iput>
  end_op();
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	d30080e7          	jalr	-720(ra) # 800040ae <end_op>
  return 0;
    80005386:	4781                	li	a5,0
    80005388:	a085                	j	800053e8 <sys_link+0x13c>
    end_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	d24080e7          	jalr	-732(ra) # 800040ae <end_op>
    return -1;
    80005392:	57fd                	li	a5,-1
    80005394:	a891                	j	800053e8 <sys_link+0x13c>
    iunlockput(ip);
    80005396:	8526                	mv	a0,s1
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	526080e7          	jalr	1318(ra) # 800038be <iunlockput>
    end_op();
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	d0e080e7          	jalr	-754(ra) # 800040ae <end_op>
    return -1;
    800053a8:	57fd                	li	a5,-1
    800053aa:	a83d                	j	800053e8 <sys_link+0x13c>
    iunlockput(dp);
    800053ac:	854a                	mv	a0,s2
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	510080e7          	jalr	1296(ra) # 800038be <iunlockput>
  ilock(ip);
    800053b6:	8526                	mv	a0,s1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	2a4080e7          	jalr	676(ra) # 8000365c <ilock>
  ip->nlink--;
    800053c0:	04a4d783          	lhu	a5,74(s1)
    800053c4:	37fd                	addiw	a5,a5,-1
    800053c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ca:	8526                	mv	a0,s1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	1c6080e7          	jalr	454(ra) # 80003592 <iupdate>
  iunlockput(ip);
    800053d4:	8526                	mv	a0,s1
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	4e8080e7          	jalr	1256(ra) # 800038be <iunlockput>
  end_op();
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	cd0080e7          	jalr	-816(ra) # 800040ae <end_op>
  return -1;
    800053e6:	57fd                	li	a5,-1
}
    800053e8:	853e                	mv	a0,a5
    800053ea:	70b2                	ld	ra,296(sp)
    800053ec:	7412                	ld	s0,288(sp)
    800053ee:	64f2                	ld	s1,280(sp)
    800053f0:	6952                	ld	s2,272(sp)
    800053f2:	6155                	addi	sp,sp,304
    800053f4:	8082                	ret

00000000800053f6 <sys_unlink>:
{
    800053f6:	7151                	addi	sp,sp,-240
    800053f8:	f586                	sd	ra,232(sp)
    800053fa:	f1a2                	sd	s0,224(sp)
    800053fc:	eda6                	sd	s1,216(sp)
    800053fe:	e9ca                	sd	s2,208(sp)
    80005400:	e5ce                	sd	s3,200(sp)
    80005402:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005404:	08000613          	li	a2,128
    80005408:	f3040593          	addi	a1,s0,-208
    8000540c:	4501                	li	a0,0
    8000540e:	ffffd097          	auipc	ra,0xffffd
    80005412:	6d6080e7          	jalr	1750(ra) # 80002ae4 <argstr>
    80005416:	18054163          	bltz	a0,80005598 <sys_unlink+0x1a2>
  begin_op();
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	c14080e7          	jalr	-1004(ra) # 8000402e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005422:	fb040593          	addi	a1,s0,-80
    80005426:	f3040513          	addi	a0,s0,-208
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	a06080e7          	jalr	-1530(ra) # 80003e30 <nameiparent>
    80005432:	84aa                	mv	s1,a0
    80005434:	c979                	beqz	a0,8000550a <sys_unlink+0x114>
  ilock(dp);
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	226080e7          	jalr	550(ra) # 8000365c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000543e:	00003597          	auipc	a1,0x3
    80005442:	2ba58593          	addi	a1,a1,698 # 800086f8 <syscalls+0x2b0>
    80005446:	fb040513          	addi	a0,s0,-80
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	6dc080e7          	jalr	1756(ra) # 80003b26 <namecmp>
    80005452:	14050a63          	beqz	a0,800055a6 <sys_unlink+0x1b0>
    80005456:	00003597          	auipc	a1,0x3
    8000545a:	2aa58593          	addi	a1,a1,682 # 80008700 <syscalls+0x2b8>
    8000545e:	fb040513          	addi	a0,s0,-80
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	6c4080e7          	jalr	1732(ra) # 80003b26 <namecmp>
    8000546a:	12050e63          	beqz	a0,800055a6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000546e:	f2c40613          	addi	a2,s0,-212
    80005472:	fb040593          	addi	a1,s0,-80
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	6c8080e7          	jalr	1736(ra) # 80003b40 <dirlookup>
    80005480:	892a                	mv	s2,a0
    80005482:	12050263          	beqz	a0,800055a6 <sys_unlink+0x1b0>
  ilock(ip);
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	1d6080e7          	jalr	470(ra) # 8000365c <ilock>
  if(ip->nlink < 1)
    8000548e:	04a91783          	lh	a5,74(s2)
    80005492:	08f05263          	blez	a5,80005516 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005496:	04491703          	lh	a4,68(s2)
    8000549a:	4785                	li	a5,1
    8000549c:	08f70563          	beq	a4,a5,80005526 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054a0:	4641                	li	a2,16
    800054a2:	4581                	li	a1,0
    800054a4:	fc040513          	addi	a0,s0,-64
    800054a8:	ffffc097          	auipc	ra,0xffffc
    800054ac:	838080e7          	jalr	-1992(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054b0:	4741                	li	a4,16
    800054b2:	f2c42683          	lw	a3,-212(s0)
    800054b6:	fc040613          	addi	a2,s0,-64
    800054ba:	4581                	li	a1,0
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	54a080e7          	jalr	1354(ra) # 80003a08 <writei>
    800054c6:	47c1                	li	a5,16
    800054c8:	0af51563          	bne	a0,a5,80005572 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054cc:	04491703          	lh	a4,68(s2)
    800054d0:	4785                	li	a5,1
    800054d2:	0af70863          	beq	a4,a5,80005582 <sys_unlink+0x18c>
  iunlockput(dp);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	3e6080e7          	jalr	998(ra) # 800038be <iunlockput>
  ip->nlink--;
    800054e0:	04a95783          	lhu	a5,74(s2)
    800054e4:	37fd                	addiw	a5,a5,-1
    800054e6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054ea:	854a                	mv	a0,s2
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	0a6080e7          	jalr	166(ra) # 80003592 <iupdate>
  iunlockput(ip);
    800054f4:	854a                	mv	a0,s2
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	3c8080e7          	jalr	968(ra) # 800038be <iunlockput>
  end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	bb0080e7          	jalr	-1104(ra) # 800040ae <end_op>
  return 0;
    80005506:	4501                	li	a0,0
    80005508:	a84d                	j	800055ba <sys_unlink+0x1c4>
    end_op();
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	ba4080e7          	jalr	-1116(ra) # 800040ae <end_op>
    return -1;
    80005512:	557d                	li	a0,-1
    80005514:	a05d                	j	800055ba <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005516:	00003517          	auipc	a0,0x3
    8000551a:	21250513          	addi	a0,a0,530 # 80008728 <syscalls+0x2e0>
    8000551e:	ffffb097          	auipc	ra,0xffffb
    80005522:	020080e7          	jalr	32(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005526:	04c92703          	lw	a4,76(s2)
    8000552a:	02000793          	li	a5,32
    8000552e:	f6e7f9e3          	bgeu	a5,a4,800054a0 <sys_unlink+0xaa>
    80005532:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005536:	4741                	li	a4,16
    80005538:	86ce                	mv	a3,s3
    8000553a:	f1840613          	addi	a2,s0,-232
    8000553e:	4581                	li	a1,0
    80005540:	854a                	mv	a0,s2
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	3ce080e7          	jalr	974(ra) # 80003910 <readi>
    8000554a:	47c1                	li	a5,16
    8000554c:	00f51b63          	bne	a0,a5,80005562 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005550:	f1845783          	lhu	a5,-232(s0)
    80005554:	e7a1                	bnez	a5,8000559c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005556:	29c1                	addiw	s3,s3,16
    80005558:	04c92783          	lw	a5,76(s2)
    8000555c:	fcf9ede3          	bltu	s3,a5,80005536 <sys_unlink+0x140>
    80005560:	b781                	j	800054a0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005562:	00003517          	auipc	a0,0x3
    80005566:	1de50513          	addi	a0,a0,478 # 80008740 <syscalls+0x2f8>
    8000556a:	ffffb097          	auipc	ra,0xffffb
    8000556e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005572:	00003517          	auipc	a0,0x3
    80005576:	1e650513          	addi	a0,a0,486 # 80008758 <syscalls+0x310>
    8000557a:	ffffb097          	auipc	ra,0xffffb
    8000557e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>
    dp->nlink--;
    80005582:	04a4d783          	lhu	a5,74(s1)
    80005586:	37fd                	addiw	a5,a5,-1
    80005588:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	004080e7          	jalr	4(ra) # 80003592 <iupdate>
    80005596:	b781                	j	800054d6 <sys_unlink+0xe0>
    return -1;
    80005598:	557d                	li	a0,-1
    8000559a:	a005                	j	800055ba <sys_unlink+0x1c4>
    iunlockput(ip);
    8000559c:	854a                	mv	a0,s2
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	320080e7          	jalr	800(ra) # 800038be <iunlockput>
  iunlockput(dp);
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	316080e7          	jalr	790(ra) # 800038be <iunlockput>
  end_op();
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	afe080e7          	jalr	-1282(ra) # 800040ae <end_op>
  return -1;
    800055b8:	557d                	li	a0,-1
}
    800055ba:	70ae                	ld	ra,232(sp)
    800055bc:	740e                	ld	s0,224(sp)
    800055be:	64ee                	ld	s1,216(sp)
    800055c0:	694e                	ld	s2,208(sp)
    800055c2:	69ae                	ld	s3,200(sp)
    800055c4:	616d                	addi	sp,sp,240
    800055c6:	8082                	ret

00000000800055c8 <sys_open>:

uint64
sys_open(void)
{
    800055c8:	7131                	addi	sp,sp,-192
    800055ca:	fd06                	sd	ra,184(sp)
    800055cc:	f922                	sd	s0,176(sp)
    800055ce:	f526                	sd	s1,168(sp)
    800055d0:	f14a                	sd	s2,160(sp)
    800055d2:	ed4e                	sd	s3,152(sp)
    800055d4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055d6:	08000613          	li	a2,128
    800055da:	f5040593          	addi	a1,s0,-176
    800055de:	4501                	li	a0,0
    800055e0:	ffffd097          	auipc	ra,0xffffd
    800055e4:	504080e7          	jalr	1284(ra) # 80002ae4 <argstr>
    return -1;
    800055e8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055ea:	0c054163          	bltz	a0,800056ac <sys_open+0xe4>
    800055ee:	f4c40593          	addi	a1,s0,-180
    800055f2:	4505                	li	a0,1
    800055f4:	ffffd097          	auipc	ra,0xffffd
    800055f8:	4ac080e7          	jalr	1196(ra) # 80002aa0 <argint>
    800055fc:	0a054863          	bltz	a0,800056ac <sys_open+0xe4>

  begin_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	a2e080e7          	jalr	-1490(ra) # 8000402e <begin_op>

  if(omode & O_CREATE){
    80005608:	f4c42783          	lw	a5,-180(s0)
    8000560c:	2007f793          	andi	a5,a5,512
    80005610:	cbdd                	beqz	a5,800056c6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005612:	4681                	li	a3,0
    80005614:	4601                	li	a2,0
    80005616:	4589                	li	a1,2
    80005618:	f5040513          	addi	a0,s0,-176
    8000561c:	00000097          	auipc	ra,0x0
    80005620:	972080e7          	jalr	-1678(ra) # 80004f8e <create>
    80005624:	892a                	mv	s2,a0
    if(ip == 0){
    80005626:	c959                	beqz	a0,800056bc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005628:	04491703          	lh	a4,68(s2)
    8000562c:	478d                	li	a5,3
    8000562e:	00f71763          	bne	a4,a5,8000563c <sys_open+0x74>
    80005632:	04695703          	lhu	a4,70(s2)
    80005636:	47a5                	li	a5,9
    80005638:	0ce7ec63          	bltu	a5,a4,80005710 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	e02080e7          	jalr	-510(ra) # 8000443e <filealloc>
    80005644:	89aa                	mv	s3,a0
    80005646:	10050263          	beqz	a0,8000574a <sys_open+0x182>
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	902080e7          	jalr	-1790(ra) # 80004f4c <fdalloc>
    80005652:	84aa                	mv	s1,a0
    80005654:	0e054663          	bltz	a0,80005740 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005658:	04491703          	lh	a4,68(s2)
    8000565c:	478d                	li	a5,3
    8000565e:	0cf70463          	beq	a4,a5,80005726 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005662:	4789                	li	a5,2
    80005664:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005668:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000566c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005670:	f4c42783          	lw	a5,-180(s0)
    80005674:	0017c713          	xori	a4,a5,1
    80005678:	8b05                	andi	a4,a4,1
    8000567a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000567e:	0037f713          	andi	a4,a5,3
    80005682:	00e03733          	snez	a4,a4
    80005686:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000568a:	4007f793          	andi	a5,a5,1024
    8000568e:	c791                	beqz	a5,8000569a <sys_open+0xd2>
    80005690:	04491703          	lh	a4,68(s2)
    80005694:	4789                	li	a5,2
    80005696:	08f70f63          	beq	a4,a5,80005734 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	082080e7          	jalr	130(ra) # 8000371e <iunlock>
  end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	a0a080e7          	jalr	-1526(ra) # 800040ae <end_op>

  return fd;
}
    800056ac:	8526                	mv	a0,s1
    800056ae:	70ea                	ld	ra,184(sp)
    800056b0:	744a                	ld	s0,176(sp)
    800056b2:	74aa                	ld	s1,168(sp)
    800056b4:	790a                	ld	s2,160(sp)
    800056b6:	69ea                	ld	s3,152(sp)
    800056b8:	6129                	addi	sp,sp,192
    800056ba:	8082                	ret
      end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	9f2080e7          	jalr	-1550(ra) # 800040ae <end_op>
      return -1;
    800056c4:	b7e5                	j	800056ac <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056c6:	f5040513          	addi	a0,s0,-176
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	748080e7          	jalr	1864(ra) # 80003e12 <namei>
    800056d2:	892a                	mv	s2,a0
    800056d4:	c905                	beqz	a0,80005704 <sys_open+0x13c>
    ilock(ip);
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	f86080e7          	jalr	-122(ra) # 8000365c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056de:	04491703          	lh	a4,68(s2)
    800056e2:	4785                	li	a5,1
    800056e4:	f4f712e3          	bne	a4,a5,80005628 <sys_open+0x60>
    800056e8:	f4c42783          	lw	a5,-180(s0)
    800056ec:	dba1                	beqz	a5,8000563c <sys_open+0x74>
      iunlockput(ip);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	1ce080e7          	jalr	462(ra) # 800038be <iunlockput>
      end_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	9b6080e7          	jalr	-1610(ra) # 800040ae <end_op>
      return -1;
    80005700:	54fd                	li	s1,-1
    80005702:	b76d                	j	800056ac <sys_open+0xe4>
      end_op();
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	9aa080e7          	jalr	-1622(ra) # 800040ae <end_op>
      return -1;
    8000570c:	54fd                	li	s1,-1
    8000570e:	bf79                	j	800056ac <sys_open+0xe4>
    iunlockput(ip);
    80005710:	854a                	mv	a0,s2
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	1ac080e7          	jalr	428(ra) # 800038be <iunlockput>
    end_op();
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	994080e7          	jalr	-1644(ra) # 800040ae <end_op>
    return -1;
    80005722:	54fd                	li	s1,-1
    80005724:	b761                	j	800056ac <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005726:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000572a:	04691783          	lh	a5,70(s2)
    8000572e:	02f99223          	sh	a5,36(s3)
    80005732:	bf2d                	j	8000566c <sys_open+0xa4>
    itrunc(ip);
    80005734:	854a                	mv	a0,s2
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	034080e7          	jalr	52(ra) # 8000376a <itrunc>
    8000573e:	bfb1                	j	8000569a <sys_open+0xd2>
      fileclose(f);
    80005740:	854e                	mv	a0,s3
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	db8080e7          	jalr	-584(ra) # 800044fa <fileclose>
    iunlockput(ip);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	172080e7          	jalr	370(ra) # 800038be <iunlockput>
    end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	95a080e7          	jalr	-1702(ra) # 800040ae <end_op>
    return -1;
    8000575c:	54fd                	li	s1,-1
    8000575e:	b7b9                	j	800056ac <sys_open+0xe4>

0000000080005760 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005760:	7175                	addi	sp,sp,-144
    80005762:	e506                	sd	ra,136(sp)
    80005764:	e122                	sd	s0,128(sp)
    80005766:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	8c6080e7          	jalr	-1850(ra) # 8000402e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005770:	08000613          	li	a2,128
    80005774:	f7040593          	addi	a1,s0,-144
    80005778:	4501                	li	a0,0
    8000577a:	ffffd097          	auipc	ra,0xffffd
    8000577e:	36a080e7          	jalr	874(ra) # 80002ae4 <argstr>
    80005782:	02054963          	bltz	a0,800057b4 <sys_mkdir+0x54>
    80005786:	4681                	li	a3,0
    80005788:	4601                	li	a2,0
    8000578a:	4585                	li	a1,1
    8000578c:	f7040513          	addi	a0,s0,-144
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	7fe080e7          	jalr	2046(ra) # 80004f8e <create>
    80005798:	cd11                	beqz	a0,800057b4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	124080e7          	jalr	292(ra) # 800038be <iunlockput>
  end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	90c080e7          	jalr	-1780(ra) # 800040ae <end_op>
  return 0;
    800057aa:	4501                	li	a0,0
}
    800057ac:	60aa                	ld	ra,136(sp)
    800057ae:	640a                	ld	s0,128(sp)
    800057b0:	6149                	addi	sp,sp,144
    800057b2:	8082                	ret
    end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	8fa080e7          	jalr	-1798(ra) # 800040ae <end_op>
    return -1;
    800057bc:	557d                	li	a0,-1
    800057be:	b7fd                	j	800057ac <sys_mkdir+0x4c>

00000000800057c0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800057c0:	7135                	addi	sp,sp,-160
    800057c2:	ed06                	sd	ra,152(sp)
    800057c4:	e922                	sd	s0,144(sp)
    800057c6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	866080e7          	jalr	-1946(ra) # 8000402e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057d0:	08000613          	li	a2,128
    800057d4:	f7040593          	addi	a1,s0,-144
    800057d8:	4501                	li	a0,0
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	30a080e7          	jalr	778(ra) # 80002ae4 <argstr>
    800057e2:	04054a63          	bltz	a0,80005836 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057e6:	f6c40593          	addi	a1,s0,-148
    800057ea:	4505                	li	a0,1
    800057ec:	ffffd097          	auipc	ra,0xffffd
    800057f0:	2b4080e7          	jalr	692(ra) # 80002aa0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057f4:	04054163          	bltz	a0,80005836 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057f8:	f6840593          	addi	a1,s0,-152
    800057fc:	4509                	li	a0,2
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	2a2080e7          	jalr	674(ra) # 80002aa0 <argint>
     argint(1, &major) < 0 ||
    80005806:	02054863          	bltz	a0,80005836 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000580a:	f6841683          	lh	a3,-152(s0)
    8000580e:	f6c41603          	lh	a2,-148(s0)
    80005812:	458d                	li	a1,3
    80005814:	f7040513          	addi	a0,s0,-144
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	776080e7          	jalr	1910(ra) # 80004f8e <create>
     argint(2, &minor) < 0 ||
    80005820:	c919                	beqz	a0,80005836 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	09c080e7          	jalr	156(ra) # 800038be <iunlockput>
  end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	884080e7          	jalr	-1916(ra) # 800040ae <end_op>
  return 0;
    80005832:	4501                	li	a0,0
    80005834:	a031                	j	80005840 <sys_mknod+0x80>
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	878080e7          	jalr	-1928(ra) # 800040ae <end_op>
    return -1;
    8000583e:	557d                	li	a0,-1
}
    80005840:	60ea                	ld	ra,152(sp)
    80005842:	644a                	ld	s0,144(sp)
    80005844:	610d                	addi	sp,sp,160
    80005846:	8082                	ret

0000000080005848 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005848:	7135                	addi	sp,sp,-160
    8000584a:	ed06                	sd	ra,152(sp)
    8000584c:	e922                	sd	s0,144(sp)
    8000584e:	e526                	sd	s1,136(sp)
    80005850:	e14a                	sd	s2,128(sp)
    80005852:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005854:	ffffc097          	auipc	ra,0xffffc
    80005858:	15c080e7          	jalr	348(ra) # 800019b0 <myproc>
    8000585c:	892a                	mv	s2,a0
  
  begin_op();
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	7d0080e7          	jalr	2000(ra) # 8000402e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005866:	08000613          	li	a2,128
    8000586a:	f6040593          	addi	a1,s0,-160
    8000586e:	4501                	li	a0,0
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	274080e7          	jalr	628(ra) # 80002ae4 <argstr>
    80005878:	04054b63          	bltz	a0,800058ce <sys_chdir+0x86>
    8000587c:	f6040513          	addi	a0,s0,-160
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	592080e7          	jalr	1426(ra) # 80003e12 <namei>
    80005888:	84aa                	mv	s1,a0
    8000588a:	c131                	beqz	a0,800058ce <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	dd0080e7          	jalr	-560(ra) # 8000365c <ilock>
  if(ip->type != T_DIR){
    80005894:	04449703          	lh	a4,68(s1)
    80005898:	4785                	li	a5,1
    8000589a:	04f71063          	bne	a4,a5,800058da <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	e7e080e7          	jalr	-386(ra) # 8000371e <iunlock>
  iput(p->cwd);
    800058a8:	15093503          	ld	a0,336(s2)
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	f6a080e7          	jalr	-150(ra) # 80003816 <iput>
  end_op();
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	7fa080e7          	jalr	2042(ra) # 800040ae <end_op>
  p->cwd = ip;
    800058bc:	14993823          	sd	s1,336(s2)
  return 0;
    800058c0:	4501                	li	a0,0
}
    800058c2:	60ea                	ld	ra,152(sp)
    800058c4:	644a                	ld	s0,144(sp)
    800058c6:	64aa                	ld	s1,136(sp)
    800058c8:	690a                	ld	s2,128(sp)
    800058ca:	610d                	addi	sp,sp,160
    800058cc:	8082                	ret
    end_op();
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	7e0080e7          	jalr	2016(ra) # 800040ae <end_op>
    return -1;
    800058d6:	557d                	li	a0,-1
    800058d8:	b7ed                	j	800058c2 <sys_chdir+0x7a>
    iunlockput(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	fe2080e7          	jalr	-30(ra) # 800038be <iunlockput>
    end_op();
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	7ca080e7          	jalr	1994(ra) # 800040ae <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	bfd1                	j	800058c2 <sys_chdir+0x7a>

00000000800058f0 <sys_exec>:

uint64
sys_exec(void)
{
    800058f0:	7145                	addi	sp,sp,-464
    800058f2:	e786                	sd	ra,456(sp)
    800058f4:	e3a2                	sd	s0,448(sp)
    800058f6:	ff26                	sd	s1,440(sp)
    800058f8:	fb4a                	sd	s2,432(sp)
    800058fa:	f74e                	sd	s3,424(sp)
    800058fc:	f352                	sd	s4,416(sp)
    800058fe:	ef56                	sd	s5,408(sp)
    80005900:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005902:	08000613          	li	a2,128
    80005906:	f4040593          	addi	a1,s0,-192
    8000590a:	4501                	li	a0,0
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	1d8080e7          	jalr	472(ra) # 80002ae4 <argstr>
    return -1;
    80005914:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005916:	0c054a63          	bltz	a0,800059ea <sys_exec+0xfa>
    8000591a:	e3840593          	addi	a1,s0,-456
    8000591e:	4505                	li	a0,1
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	1a2080e7          	jalr	418(ra) # 80002ac2 <argaddr>
    80005928:	0c054163          	bltz	a0,800059ea <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000592c:	10000613          	li	a2,256
    80005930:	4581                	li	a1,0
    80005932:	e4040513          	addi	a0,s0,-448
    80005936:	ffffb097          	auipc	ra,0xffffb
    8000593a:	3aa080e7          	jalr	938(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000593e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005942:	89a6                	mv	s3,s1
    80005944:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005946:	02000a13          	li	s4,32
    8000594a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000594e:	00391513          	slli	a0,s2,0x3
    80005952:	e3040593          	addi	a1,s0,-464
    80005956:	e3843783          	ld	a5,-456(s0)
    8000595a:	953e                	add	a0,a0,a5
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	0aa080e7          	jalr	170(ra) # 80002a06 <fetchaddr>
    80005964:	02054a63          	bltz	a0,80005998 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005968:	e3043783          	ld	a5,-464(s0)
    8000596c:	c3b9                	beqz	a5,800059b2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	186080e7          	jalr	390(ra) # 80000af4 <kalloc>
    80005976:	85aa                	mv	a1,a0
    80005978:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000597c:	cd11                	beqz	a0,80005998 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000597e:	6605                	lui	a2,0x1
    80005980:	e3043503          	ld	a0,-464(s0)
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	0d4080e7          	jalr	212(ra) # 80002a58 <fetchstr>
    8000598c:	00054663          	bltz	a0,80005998 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005990:	0905                	addi	s2,s2,1
    80005992:	09a1                	addi	s3,s3,8
    80005994:	fb491be3          	bne	s2,s4,8000594a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005998:	10048913          	addi	s2,s1,256
    8000599c:	6088                	ld	a0,0(s1)
    8000599e:	c529                	beqz	a0,800059e8 <sys_exec+0xf8>
    kfree(argv[i]);
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	058080e7          	jalr	88(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a8:	04a1                	addi	s1,s1,8
    800059aa:	ff2499e3          	bne	s1,s2,8000599c <sys_exec+0xac>
  return -1;
    800059ae:	597d                	li	s2,-1
    800059b0:	a82d                	j	800059ea <sys_exec+0xfa>
      argv[i] = 0;
    800059b2:	0a8e                	slli	s5,s5,0x3
    800059b4:	fc040793          	addi	a5,s0,-64
    800059b8:	9abe                	add	s5,s5,a5
    800059ba:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059be:	e4040593          	addi	a1,s0,-448
    800059c2:	f4040513          	addi	a0,s0,-192
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	194080e7          	jalr	404(ra) # 80004b5a <exec>
    800059ce:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059d0:	10048993          	addi	s3,s1,256
    800059d4:	6088                	ld	a0,0(s1)
    800059d6:	c911                	beqz	a0,800059ea <sys_exec+0xfa>
    kfree(argv[i]);
    800059d8:	ffffb097          	auipc	ra,0xffffb
    800059dc:	020080e7          	jalr	32(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059e0:	04a1                	addi	s1,s1,8
    800059e2:	ff3499e3          	bne	s1,s3,800059d4 <sys_exec+0xe4>
    800059e6:	a011                	j	800059ea <sys_exec+0xfa>
  return -1;
    800059e8:	597d                	li	s2,-1
}
    800059ea:	854a                	mv	a0,s2
    800059ec:	60be                	ld	ra,456(sp)
    800059ee:	641e                	ld	s0,448(sp)
    800059f0:	74fa                	ld	s1,440(sp)
    800059f2:	795a                	ld	s2,432(sp)
    800059f4:	79ba                	ld	s3,424(sp)
    800059f6:	7a1a                	ld	s4,416(sp)
    800059f8:	6afa                	ld	s5,408(sp)
    800059fa:	6179                	addi	sp,sp,464
    800059fc:	8082                	ret

00000000800059fe <sys_pipe>:

uint64
sys_pipe(void)
{
    800059fe:	7139                	addi	sp,sp,-64
    80005a00:	fc06                	sd	ra,56(sp)
    80005a02:	f822                	sd	s0,48(sp)
    80005a04:	f426                	sd	s1,40(sp)
    80005a06:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a08:	ffffc097          	auipc	ra,0xffffc
    80005a0c:	fa8080e7          	jalr	-88(ra) # 800019b0 <myproc>
    80005a10:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a12:	fd840593          	addi	a1,s0,-40
    80005a16:	4501                	li	a0,0
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	0aa080e7          	jalr	170(ra) # 80002ac2 <argaddr>
    return -1;
    80005a20:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a22:	0e054063          	bltz	a0,80005b02 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a26:	fc840593          	addi	a1,s0,-56
    80005a2a:	fd040513          	addi	a0,s0,-48
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	dfc080e7          	jalr	-516(ra) # 8000482a <pipealloc>
    return -1;
    80005a36:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a38:	0c054563          	bltz	a0,80005b02 <sys_pipe+0x104>
  fd0 = -1;
    80005a3c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a40:	fd043503          	ld	a0,-48(s0)
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	508080e7          	jalr	1288(ra) # 80004f4c <fdalloc>
    80005a4c:	fca42223          	sw	a0,-60(s0)
    80005a50:	08054c63          	bltz	a0,80005ae8 <sys_pipe+0xea>
    80005a54:	fc843503          	ld	a0,-56(s0)
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	4f4080e7          	jalr	1268(ra) # 80004f4c <fdalloc>
    80005a60:	fca42023          	sw	a0,-64(s0)
    80005a64:	06054863          	bltz	a0,80005ad4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a68:	4691                	li	a3,4
    80005a6a:	fc440613          	addi	a2,s0,-60
    80005a6e:	fd843583          	ld	a1,-40(s0)
    80005a72:	68a8                	ld	a0,80(s1)
    80005a74:	ffffc097          	auipc	ra,0xffffc
    80005a78:	bfe080e7          	jalr	-1026(ra) # 80001672 <copyout>
    80005a7c:	02054063          	bltz	a0,80005a9c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a80:	4691                	li	a3,4
    80005a82:	fc040613          	addi	a2,s0,-64
    80005a86:	fd843583          	ld	a1,-40(s0)
    80005a8a:	0591                	addi	a1,a1,4
    80005a8c:	68a8                	ld	a0,80(s1)
    80005a8e:	ffffc097          	auipc	ra,0xffffc
    80005a92:	be4080e7          	jalr	-1052(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a96:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a98:	06055563          	bgez	a0,80005b02 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a9c:	fc442783          	lw	a5,-60(s0)
    80005aa0:	07e9                	addi	a5,a5,26
    80005aa2:	078e                	slli	a5,a5,0x3
    80005aa4:	97a6                	add	a5,a5,s1
    80005aa6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005aaa:	fc042503          	lw	a0,-64(s0)
    80005aae:	0569                	addi	a0,a0,26
    80005ab0:	050e                	slli	a0,a0,0x3
    80005ab2:	9526                	add	a0,a0,s1
    80005ab4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ab8:	fd043503          	ld	a0,-48(s0)
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	a3e080e7          	jalr	-1474(ra) # 800044fa <fileclose>
    fileclose(wf);
    80005ac4:	fc843503          	ld	a0,-56(s0)
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	a32080e7          	jalr	-1486(ra) # 800044fa <fileclose>
    return -1;
    80005ad0:	57fd                	li	a5,-1
    80005ad2:	a805                	j	80005b02 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ad4:	fc442783          	lw	a5,-60(s0)
    80005ad8:	0007c863          	bltz	a5,80005ae8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005adc:	01a78513          	addi	a0,a5,26
    80005ae0:	050e                	slli	a0,a0,0x3
    80005ae2:	9526                	add	a0,a0,s1
    80005ae4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ae8:	fd043503          	ld	a0,-48(s0)
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	a0e080e7          	jalr	-1522(ra) # 800044fa <fileclose>
    fileclose(wf);
    80005af4:	fc843503          	ld	a0,-56(s0)
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	a02080e7          	jalr	-1534(ra) # 800044fa <fileclose>
    return -1;
    80005b00:	57fd                	li	a5,-1
}
    80005b02:	853e                	mv	a0,a5
    80005b04:	70e2                	ld	ra,56(sp)
    80005b06:	7442                	ld	s0,48(sp)
    80005b08:	74a2                	ld	s1,40(sp)
    80005b0a:	6121                	addi	sp,sp,64
    80005b0c:	8082                	ret
	...

0000000080005b10 <kernelvec>:
    80005b10:	7111                	addi	sp,sp,-256
    80005b12:	e006                	sd	ra,0(sp)
    80005b14:	e40a                	sd	sp,8(sp)
    80005b16:	e80e                	sd	gp,16(sp)
    80005b18:	ec12                	sd	tp,24(sp)
    80005b1a:	f016                	sd	t0,32(sp)
    80005b1c:	f41a                	sd	t1,40(sp)
    80005b1e:	f81e                	sd	t2,48(sp)
    80005b20:	fc22                	sd	s0,56(sp)
    80005b22:	e0a6                	sd	s1,64(sp)
    80005b24:	e4aa                	sd	a0,72(sp)
    80005b26:	e8ae                	sd	a1,80(sp)
    80005b28:	ecb2                	sd	a2,88(sp)
    80005b2a:	f0b6                	sd	a3,96(sp)
    80005b2c:	f4ba                	sd	a4,104(sp)
    80005b2e:	f8be                	sd	a5,112(sp)
    80005b30:	fcc2                	sd	a6,120(sp)
    80005b32:	e146                	sd	a7,128(sp)
    80005b34:	e54a                	sd	s2,136(sp)
    80005b36:	e94e                	sd	s3,144(sp)
    80005b38:	ed52                	sd	s4,152(sp)
    80005b3a:	f156                	sd	s5,160(sp)
    80005b3c:	f55a                	sd	s6,168(sp)
    80005b3e:	f95e                	sd	s7,176(sp)
    80005b40:	fd62                	sd	s8,184(sp)
    80005b42:	e1e6                	sd	s9,192(sp)
    80005b44:	e5ea                	sd	s10,200(sp)
    80005b46:	e9ee                	sd	s11,208(sp)
    80005b48:	edf2                	sd	t3,216(sp)
    80005b4a:	f1f6                	sd	t4,224(sp)
    80005b4c:	f5fa                	sd	t5,232(sp)
    80005b4e:	f9fe                	sd	t6,240(sp)
    80005b50:	d83fc0ef          	jal	ra,800028d2 <kerneltrap>
    80005b54:	6082                	ld	ra,0(sp)
    80005b56:	6122                	ld	sp,8(sp)
    80005b58:	61c2                	ld	gp,16(sp)
    80005b5a:	7282                	ld	t0,32(sp)
    80005b5c:	7322                	ld	t1,40(sp)
    80005b5e:	73c2                	ld	t2,48(sp)
    80005b60:	7462                	ld	s0,56(sp)
    80005b62:	6486                	ld	s1,64(sp)
    80005b64:	6526                	ld	a0,72(sp)
    80005b66:	65c6                	ld	a1,80(sp)
    80005b68:	6666                	ld	a2,88(sp)
    80005b6a:	7686                	ld	a3,96(sp)
    80005b6c:	7726                	ld	a4,104(sp)
    80005b6e:	77c6                	ld	a5,112(sp)
    80005b70:	7866                	ld	a6,120(sp)
    80005b72:	688a                	ld	a7,128(sp)
    80005b74:	692a                	ld	s2,136(sp)
    80005b76:	69ca                	ld	s3,144(sp)
    80005b78:	6a6a                	ld	s4,152(sp)
    80005b7a:	7a8a                	ld	s5,160(sp)
    80005b7c:	7b2a                	ld	s6,168(sp)
    80005b7e:	7bca                	ld	s7,176(sp)
    80005b80:	7c6a                	ld	s8,184(sp)
    80005b82:	6c8e                	ld	s9,192(sp)
    80005b84:	6d2e                	ld	s10,200(sp)
    80005b86:	6dce                	ld	s11,208(sp)
    80005b88:	6e6e                	ld	t3,216(sp)
    80005b8a:	7e8e                	ld	t4,224(sp)
    80005b8c:	7f2e                	ld	t5,232(sp)
    80005b8e:	7fce                	ld	t6,240(sp)
    80005b90:	6111                	addi	sp,sp,256
    80005b92:	10200073          	sret
    80005b96:	00000013          	nop
    80005b9a:	00000013          	nop
    80005b9e:	0001                	nop

0000000080005ba0 <timervec>:
    80005ba0:	34051573          	csrrw	a0,mscratch,a0
    80005ba4:	e10c                	sd	a1,0(a0)
    80005ba6:	e510                	sd	a2,8(a0)
    80005ba8:	e914                	sd	a3,16(a0)
    80005baa:	6d0c                	ld	a1,24(a0)
    80005bac:	7110                	ld	a2,32(a0)
    80005bae:	6194                	ld	a3,0(a1)
    80005bb0:	96b2                	add	a3,a3,a2
    80005bb2:	e194                	sd	a3,0(a1)
    80005bb4:	4589                	li	a1,2
    80005bb6:	14459073          	csrw	sip,a1
    80005bba:	6914                	ld	a3,16(a0)
    80005bbc:	6510                	ld	a2,8(a0)
    80005bbe:	610c                	ld	a1,0(a0)
    80005bc0:	34051573          	csrrw	a0,mscratch,a0
    80005bc4:	30200073          	mret
	...

0000000080005bca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bca:	1141                	addi	sp,sp,-16
    80005bcc:	e422                	sd	s0,8(sp)
    80005bce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bd0:	0c0007b7          	lui	a5,0xc000
    80005bd4:	4705                	li	a4,1
    80005bd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bd8:	c3d8                	sw	a4,4(a5)
}
    80005bda:	6422                	ld	s0,8(sp)
    80005bdc:	0141                	addi	sp,sp,16
    80005bde:	8082                	ret

0000000080005be0 <plicinithart>:

void
plicinithart(void)
{
    80005be0:	1141                	addi	sp,sp,-16
    80005be2:	e406                	sd	ra,8(sp)
    80005be4:	e022                	sd	s0,0(sp)
    80005be6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	d9c080e7          	jalr	-612(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bf0:	0085171b          	slliw	a4,a0,0x8
    80005bf4:	0c0027b7          	lui	a5,0xc002
    80005bf8:	97ba                	add	a5,a5,a4
    80005bfa:	40200713          	li	a4,1026
    80005bfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c02:	00d5151b          	slliw	a0,a0,0xd
    80005c06:	0c2017b7          	lui	a5,0xc201
    80005c0a:	953e                	add	a0,a0,a5
    80005c0c:	00052023          	sw	zero,0(a0)
}
    80005c10:	60a2                	ld	ra,8(sp)
    80005c12:	6402                	ld	s0,0(sp)
    80005c14:	0141                	addi	sp,sp,16
    80005c16:	8082                	ret

0000000080005c18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c18:	1141                	addi	sp,sp,-16
    80005c1a:	e406                	sd	ra,8(sp)
    80005c1c:	e022                	sd	s0,0(sp)
    80005c1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	d64080e7          	jalr	-668(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c28:	00d5179b          	slliw	a5,a0,0xd
    80005c2c:	0c201537          	lui	a0,0xc201
    80005c30:	953e                	add	a0,a0,a5
  return irq;
}
    80005c32:	4148                	lw	a0,4(a0)
    80005c34:	60a2                	ld	ra,8(sp)
    80005c36:	6402                	ld	s0,0(sp)
    80005c38:	0141                	addi	sp,sp,16
    80005c3a:	8082                	ret

0000000080005c3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c3c:	1101                	addi	sp,sp,-32
    80005c3e:	ec06                	sd	ra,24(sp)
    80005c40:	e822                	sd	s0,16(sp)
    80005c42:	e426                	sd	s1,8(sp)
    80005c44:	1000                	addi	s0,sp,32
    80005c46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	d3c080e7          	jalr	-708(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c50:	00d5151b          	slliw	a0,a0,0xd
    80005c54:	0c2017b7          	lui	a5,0xc201
    80005c58:	97aa                	add	a5,a5,a0
    80005c5a:	c3c4                	sw	s1,4(a5)
}
    80005c5c:	60e2                	ld	ra,24(sp)
    80005c5e:	6442                	ld	s0,16(sp)
    80005c60:	64a2                	ld	s1,8(sp)
    80005c62:	6105                	addi	sp,sp,32
    80005c64:	8082                	ret

0000000080005c66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c66:	1141                	addi	sp,sp,-16
    80005c68:	e406                	sd	ra,8(sp)
    80005c6a:	e022                	sd	s0,0(sp)
    80005c6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c6e:	479d                	li	a5,7
    80005c70:	06a7c963          	blt	a5,a0,80005ce2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c74:	0001d797          	auipc	a5,0x1d
    80005c78:	38c78793          	addi	a5,a5,908 # 80023000 <disk>
    80005c7c:	00a78733          	add	a4,a5,a0
    80005c80:	6789                	lui	a5,0x2
    80005c82:	97ba                	add	a5,a5,a4
    80005c84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c88:	e7ad                	bnez	a5,80005cf2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c8a:	00451793          	slli	a5,a0,0x4
    80005c8e:	0001f717          	auipc	a4,0x1f
    80005c92:	37270713          	addi	a4,a4,882 # 80025000 <disk+0x2000>
    80005c96:	6314                	ld	a3,0(a4)
    80005c98:	96be                	add	a3,a3,a5
    80005c9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c9e:	6314                	ld	a3,0(a4)
    80005ca0:	96be                	add	a3,a3,a5
    80005ca2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ca6:	6314                	ld	a3,0(a4)
    80005ca8:	96be                	add	a3,a3,a5
    80005caa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cae:	6318                	ld	a4,0(a4)
    80005cb0:	97ba                	add	a5,a5,a4
    80005cb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cb6:	0001d797          	auipc	a5,0x1d
    80005cba:	34a78793          	addi	a5,a5,842 # 80023000 <disk>
    80005cbe:	97aa                	add	a5,a5,a0
    80005cc0:	6509                	lui	a0,0x2
    80005cc2:	953e                	add	a0,a0,a5
    80005cc4:	4785                	li	a5,1
    80005cc6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005cca:	0001f517          	auipc	a0,0x1f
    80005cce:	34e50513          	addi	a0,a0,846 # 80025018 <disk+0x2018>
    80005cd2:	ffffc097          	auipc	ra,0xffffc
    80005cd6:	50c080e7          	jalr	1292(ra) # 800021de <wakeup>
}
    80005cda:	60a2                	ld	ra,8(sp)
    80005cdc:	6402                	ld	s0,0(sp)
    80005cde:	0141                	addi	sp,sp,16
    80005ce0:	8082                	ret
    panic("free_desc 1");
    80005ce2:	00003517          	auipc	a0,0x3
    80005ce6:	a8650513          	addi	a0,a0,-1402 # 80008768 <syscalls+0x320>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005cf2:	00003517          	auipc	a0,0x3
    80005cf6:	a8650513          	addi	a0,a0,-1402 # 80008778 <syscalls+0x330>
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>

0000000080005d02 <virtio_disk_init>:
{
    80005d02:	1101                	addi	sp,sp,-32
    80005d04:	ec06                	sd	ra,24(sp)
    80005d06:	e822                	sd	s0,16(sp)
    80005d08:	e426                	sd	s1,8(sp)
    80005d0a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d0c:	00003597          	auipc	a1,0x3
    80005d10:	a7c58593          	addi	a1,a1,-1412 # 80008788 <syscalls+0x340>
    80005d14:	0001f517          	auipc	a0,0x1f
    80005d18:	41450513          	addi	a0,a0,1044 # 80025128 <disk+0x2128>
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	e38080e7          	jalr	-456(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d24:	100017b7          	lui	a5,0x10001
    80005d28:	4398                	lw	a4,0(a5)
    80005d2a:	2701                	sext.w	a4,a4
    80005d2c:	747277b7          	lui	a5,0x74727
    80005d30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d34:	0ef71163          	bne	a4,a5,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d38:	100017b7          	lui	a5,0x10001
    80005d3c:	43dc                	lw	a5,4(a5)
    80005d3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d40:	4705                	li	a4,1
    80005d42:	0ce79a63          	bne	a5,a4,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d46:	100017b7          	lui	a5,0x10001
    80005d4a:	479c                	lw	a5,8(a5)
    80005d4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d4e:	4709                	li	a4,2
    80005d50:	0ce79363          	bne	a5,a4,80005e16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d54:	100017b7          	lui	a5,0x10001
    80005d58:	47d8                	lw	a4,12(a5)
    80005d5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d5c:	554d47b7          	lui	a5,0x554d4
    80005d60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d64:	0af71963          	bne	a4,a5,80005e16 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d68:	100017b7          	lui	a5,0x10001
    80005d6c:	4705                	li	a4,1
    80005d6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d70:	470d                	li	a4,3
    80005d72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d76:	c7ffe737          	lui	a4,0xc7ffe
    80005d7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d80:	2701                	sext.w	a4,a4
    80005d82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d84:	472d                	li	a4,11
    80005d86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d88:	473d                	li	a4,15
    80005d8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d8c:	6705                	lui	a4,0x1
    80005d8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d94:	5bdc                	lw	a5,52(a5)
    80005d96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d98:	c7d9                	beqz	a5,80005e26 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d9a:	471d                	li	a4,7
    80005d9c:	08f77d63          	bgeu	a4,a5,80005e36 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005da0:	100014b7          	lui	s1,0x10001
    80005da4:	47a1                	li	a5,8
    80005da6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005da8:	6609                	lui	a2,0x2
    80005daa:	4581                	li	a1,0
    80005dac:	0001d517          	auipc	a0,0x1d
    80005db0:	25450513          	addi	a0,a0,596 # 80023000 <disk>
    80005db4:	ffffb097          	auipc	ra,0xffffb
    80005db8:	f2c080e7          	jalr	-212(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dbc:	0001d717          	auipc	a4,0x1d
    80005dc0:	24470713          	addi	a4,a4,580 # 80023000 <disk>
    80005dc4:	00c75793          	srli	a5,a4,0xc
    80005dc8:	2781                	sext.w	a5,a5
    80005dca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dcc:	0001f797          	auipc	a5,0x1f
    80005dd0:	23478793          	addi	a5,a5,564 # 80025000 <disk+0x2000>
    80005dd4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005dd6:	0001d717          	auipc	a4,0x1d
    80005dda:	2aa70713          	addi	a4,a4,682 # 80023080 <disk+0x80>
    80005dde:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005de0:	0001e717          	auipc	a4,0x1e
    80005de4:	22070713          	addi	a4,a4,544 # 80024000 <disk+0x1000>
    80005de8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dea:	4705                	li	a4,1
    80005dec:	00e78c23          	sb	a4,24(a5)
    80005df0:	00e78ca3          	sb	a4,25(a5)
    80005df4:	00e78d23          	sb	a4,26(a5)
    80005df8:	00e78da3          	sb	a4,27(a5)
    80005dfc:	00e78e23          	sb	a4,28(a5)
    80005e00:	00e78ea3          	sb	a4,29(a5)
    80005e04:	00e78f23          	sb	a4,30(a5)
    80005e08:	00e78fa3          	sb	a4,31(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret
    panic("could not find virtio disk");
    80005e16:	00003517          	auipc	a0,0x3
    80005e1a:	98250513          	addi	a0,a0,-1662 # 80008798 <syscalls+0x350>
    80005e1e:	ffffa097          	auipc	ra,0xffffa
    80005e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	99250513          	addi	a0,a0,-1646 # 800087b8 <syscalls+0x370>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	9a250513          	addi	a0,a0,-1630 # 800087d8 <syscalls+0x390>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>

0000000080005e46 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e46:	7159                	addi	sp,sp,-112
    80005e48:	f486                	sd	ra,104(sp)
    80005e4a:	f0a2                	sd	s0,96(sp)
    80005e4c:	eca6                	sd	s1,88(sp)
    80005e4e:	e8ca                	sd	s2,80(sp)
    80005e50:	e4ce                	sd	s3,72(sp)
    80005e52:	e0d2                	sd	s4,64(sp)
    80005e54:	fc56                	sd	s5,56(sp)
    80005e56:	f85a                	sd	s6,48(sp)
    80005e58:	f45e                	sd	s7,40(sp)
    80005e5a:	f062                	sd	s8,32(sp)
    80005e5c:	ec66                	sd	s9,24(sp)
    80005e5e:	e86a                	sd	s10,16(sp)
    80005e60:	1880                	addi	s0,sp,112
    80005e62:	892a                	mv	s2,a0
    80005e64:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e66:	00c52c83          	lw	s9,12(a0)
    80005e6a:	001c9c9b          	slliw	s9,s9,0x1
    80005e6e:	1c82                	slli	s9,s9,0x20
    80005e70:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e74:	0001f517          	auipc	a0,0x1f
    80005e78:	2b450513          	addi	a0,a0,692 # 80025128 <disk+0x2128>
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	d68080e7          	jalr	-664(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e84:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e86:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e88:	0001db97          	auipc	s7,0x1d
    80005e8c:	178b8b93          	addi	s7,s7,376 # 80023000 <disk>
    80005e90:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e94:	8a4e                	mv	s4,s3
    80005e96:	a051                	j	80005f1a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e98:	00fb86b3          	add	a3,s7,a5
    80005e9c:	96da                	add	a3,a3,s6
    80005e9e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ea2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ea4:	0207c563          	bltz	a5,80005ece <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ea8:	2485                	addiw	s1,s1,1
    80005eaa:	0711                	addi	a4,a4,4
    80005eac:	25548063          	beq	s1,s5,800060ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005eb0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005eb2:	0001f697          	auipc	a3,0x1f
    80005eb6:	16668693          	addi	a3,a3,358 # 80025018 <disk+0x2018>
    80005eba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005ebc:	0006c583          	lbu	a1,0(a3)
    80005ec0:	fde1                	bnez	a1,80005e98 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ec2:	2785                	addiw	a5,a5,1
    80005ec4:	0685                	addi	a3,a3,1
    80005ec6:	ff879be3          	bne	a5,s8,80005ebc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005eca:	57fd                	li	a5,-1
    80005ecc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ece:	02905a63          	blez	s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ed2:	f9042503          	lw	a0,-112(s0)
    80005ed6:	00000097          	auipc	ra,0x0
    80005eda:	d90080e7          	jalr	-624(ra) # 80005c66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ede:	4785                	li	a5,1
    80005ee0:	0297d163          	bge	a5,s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ee4:	f9442503          	lw	a0,-108(s0)
    80005ee8:	00000097          	auipc	ra,0x0
    80005eec:	d7e080e7          	jalr	-642(ra) # 80005c66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ef0:	4789                	li	a5,2
    80005ef2:	0097d863          	bge	a5,s1,80005f02 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ef6:	f9842503          	lw	a0,-104(s0)
    80005efa:	00000097          	auipc	ra,0x0
    80005efe:	d6c080e7          	jalr	-660(ra) # 80005c66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f02:	0001f597          	auipc	a1,0x1f
    80005f06:	22658593          	addi	a1,a1,550 # 80025128 <disk+0x2128>
    80005f0a:	0001f517          	auipc	a0,0x1f
    80005f0e:	10e50513          	addi	a0,a0,270 # 80025018 <disk+0x2018>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	140080e7          	jalr	320(ra) # 80002052 <sleep>
  for(int i = 0; i < 3; i++){
    80005f1a:	f9040713          	addi	a4,s0,-112
    80005f1e:	84ce                	mv	s1,s3
    80005f20:	bf41                	j	80005eb0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f22:	20058713          	addi	a4,a1,512
    80005f26:	00471693          	slli	a3,a4,0x4
    80005f2a:	0001d717          	auipc	a4,0x1d
    80005f2e:	0d670713          	addi	a4,a4,214 # 80023000 <disk>
    80005f32:	9736                	add	a4,a4,a3
    80005f34:	4685                	li	a3,1
    80005f36:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f3a:	20058713          	addi	a4,a1,512
    80005f3e:	00471693          	slli	a3,a4,0x4
    80005f42:	0001d717          	auipc	a4,0x1d
    80005f46:	0be70713          	addi	a4,a4,190 # 80023000 <disk>
    80005f4a:	9736                	add	a4,a4,a3
    80005f4c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f50:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f54:	7679                	lui	a2,0xffffe
    80005f56:	963e                	add	a2,a2,a5
    80005f58:	0001f697          	auipc	a3,0x1f
    80005f5c:	0a868693          	addi	a3,a3,168 # 80025000 <disk+0x2000>
    80005f60:	6298                	ld	a4,0(a3)
    80005f62:	9732                	add	a4,a4,a2
    80005f64:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f66:	6298                	ld	a4,0(a3)
    80005f68:	9732                	add	a4,a4,a2
    80005f6a:	4541                	li	a0,16
    80005f6c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f6e:	6298                	ld	a4,0(a3)
    80005f70:	9732                	add	a4,a4,a2
    80005f72:	4505                	li	a0,1
    80005f74:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f78:	f9442703          	lw	a4,-108(s0)
    80005f7c:	6288                	ld	a0,0(a3)
    80005f7e:	962a                	add	a2,a2,a0
    80005f80:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f84:	0712                	slli	a4,a4,0x4
    80005f86:	6290                	ld	a2,0(a3)
    80005f88:	963a                	add	a2,a2,a4
    80005f8a:	05890513          	addi	a0,s2,88
    80005f8e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f90:	6294                	ld	a3,0(a3)
    80005f92:	96ba                	add	a3,a3,a4
    80005f94:	40000613          	li	a2,1024
    80005f98:	c690                	sw	a2,8(a3)
  if(write)
    80005f9a:	140d0063          	beqz	s10,800060da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f9e:	0001f697          	auipc	a3,0x1f
    80005fa2:	0626b683          	ld	a3,98(a3) # 80025000 <disk+0x2000>
    80005fa6:	96ba                	add	a3,a3,a4
    80005fa8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fac:	0001d817          	auipc	a6,0x1d
    80005fb0:	05480813          	addi	a6,a6,84 # 80023000 <disk>
    80005fb4:	0001f517          	auipc	a0,0x1f
    80005fb8:	04c50513          	addi	a0,a0,76 # 80025000 <disk+0x2000>
    80005fbc:	6114                	ld	a3,0(a0)
    80005fbe:	96ba                	add	a3,a3,a4
    80005fc0:	00c6d603          	lhu	a2,12(a3)
    80005fc4:	00166613          	ori	a2,a2,1
    80005fc8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fcc:	f9842683          	lw	a3,-104(s0)
    80005fd0:	6110                	ld	a2,0(a0)
    80005fd2:	9732                	add	a4,a4,a2
    80005fd4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fd8:	20058613          	addi	a2,a1,512
    80005fdc:	0612                	slli	a2,a2,0x4
    80005fde:	9642                	add	a2,a2,a6
    80005fe0:	577d                	li	a4,-1
    80005fe2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fe6:	00469713          	slli	a4,a3,0x4
    80005fea:	6114                	ld	a3,0(a0)
    80005fec:	96ba                	add	a3,a3,a4
    80005fee:	03078793          	addi	a5,a5,48
    80005ff2:	97c2                	add	a5,a5,a6
    80005ff4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005ff6:	611c                	ld	a5,0(a0)
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	4685                	li	a3,1
    80005ffc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005ffe:	611c                	ld	a5,0(a0)
    80006000:	97ba                	add	a5,a5,a4
    80006002:	4809                	li	a6,2
    80006004:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006008:	611c                	ld	a5,0(a0)
    8000600a:	973e                	add	a4,a4,a5
    8000600c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006010:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006014:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006018:	6518                	ld	a4,8(a0)
    8000601a:	00275783          	lhu	a5,2(a4)
    8000601e:	8b9d                	andi	a5,a5,7
    80006020:	0786                	slli	a5,a5,0x1
    80006022:	97ba                	add	a5,a5,a4
    80006024:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006028:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000602c:	6518                	ld	a4,8(a0)
    8000602e:	00275783          	lhu	a5,2(a4)
    80006032:	2785                	addiw	a5,a5,1
    80006034:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006038:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006044:	00492703          	lw	a4,4(s2)
    80006048:	4785                	li	a5,1
    8000604a:	02f71163          	bne	a4,a5,8000606c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000604e:	0001f997          	auipc	s3,0x1f
    80006052:	0da98993          	addi	s3,s3,218 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006056:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006058:	85ce                	mv	a1,s3
    8000605a:	854a                	mv	a0,s2
    8000605c:	ffffc097          	auipc	ra,0xffffc
    80006060:	ff6080e7          	jalr	-10(ra) # 80002052 <sleep>
  while(b->disk == 1) {
    80006064:	00492783          	lw	a5,4(s2)
    80006068:	fe9788e3          	beq	a5,s1,80006058 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000606c:	f9042903          	lw	s2,-112(s0)
    80006070:	20090793          	addi	a5,s2,512
    80006074:	00479713          	slli	a4,a5,0x4
    80006078:	0001d797          	auipc	a5,0x1d
    8000607c:	f8878793          	addi	a5,a5,-120 # 80023000 <disk>
    80006080:	97ba                	add	a5,a5,a4
    80006082:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006086:	0001f997          	auipc	s3,0x1f
    8000608a:	f7a98993          	addi	s3,s3,-134 # 80025000 <disk+0x2000>
    8000608e:	00491713          	slli	a4,s2,0x4
    80006092:	0009b783          	ld	a5,0(s3)
    80006096:	97ba                	add	a5,a5,a4
    80006098:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000609c:	854a                	mv	a0,s2
    8000609e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060a2:	00000097          	auipc	ra,0x0
    800060a6:	bc4080e7          	jalr	-1084(ra) # 80005c66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060aa:	8885                	andi	s1,s1,1
    800060ac:	f0ed                	bnez	s1,8000608e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060ae:	0001f517          	auipc	a0,0x1f
    800060b2:	07a50513          	addi	a0,a0,122 # 80025128 <disk+0x2128>
    800060b6:	ffffb097          	auipc	ra,0xffffb
    800060ba:	be2080e7          	jalr	-1054(ra) # 80000c98 <release>
}
    800060be:	70a6                	ld	ra,104(sp)
    800060c0:	7406                	ld	s0,96(sp)
    800060c2:	64e6                	ld	s1,88(sp)
    800060c4:	6946                	ld	s2,80(sp)
    800060c6:	69a6                	ld	s3,72(sp)
    800060c8:	6a06                	ld	s4,64(sp)
    800060ca:	7ae2                	ld	s5,56(sp)
    800060cc:	7b42                	ld	s6,48(sp)
    800060ce:	7ba2                	ld	s7,40(sp)
    800060d0:	7c02                	ld	s8,32(sp)
    800060d2:	6ce2                	ld	s9,24(sp)
    800060d4:	6d42                	ld	s10,16(sp)
    800060d6:	6165                	addi	sp,sp,112
    800060d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060da:	0001f697          	auipc	a3,0x1f
    800060de:	f266b683          	ld	a3,-218(a3) # 80025000 <disk+0x2000>
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	4609                	li	a2,2
    800060e6:	00c69623          	sh	a2,12(a3)
    800060ea:	b5c9                	j	80005fac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060ec:	f9042583          	lw	a1,-112(s0)
    800060f0:	20058793          	addi	a5,a1,512
    800060f4:	0792                	slli	a5,a5,0x4
    800060f6:	0001d517          	auipc	a0,0x1d
    800060fa:	fb250513          	addi	a0,a0,-78 # 800230a8 <disk+0xa8>
    800060fe:	953e                	add	a0,a0,a5
  if(write)
    80006100:	e20d11e3          	bnez	s10,80005f22 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006104:	20058713          	addi	a4,a1,512
    80006108:	00471693          	slli	a3,a4,0x4
    8000610c:	0001d717          	auipc	a4,0x1d
    80006110:	ef470713          	addi	a4,a4,-268 # 80023000 <disk>
    80006114:	9736                	add	a4,a4,a3
    80006116:	0a072423          	sw	zero,168(a4)
    8000611a:	b505                	j	80005f3a <virtio_disk_rw+0xf4>

000000008000611c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000611c:	1101                	addi	sp,sp,-32
    8000611e:	ec06                	sd	ra,24(sp)
    80006120:	e822                	sd	s0,16(sp)
    80006122:	e426                	sd	s1,8(sp)
    80006124:	e04a                	sd	s2,0(sp)
    80006126:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006128:	0001f517          	auipc	a0,0x1f
    8000612c:	00050513          	mv	a0,a0
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	ab4080e7          	jalr	-1356(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006138:	10001737          	lui	a4,0x10001
    8000613c:	533c                	lw	a5,96(a4)
    8000613e:	8b8d                	andi	a5,a5,3
    80006140:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006142:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006146:	0001f797          	auipc	a5,0x1f
    8000614a:	eba78793          	addi	a5,a5,-326 # 80025000 <disk+0x2000>
    8000614e:	6b94                	ld	a3,16(a5)
    80006150:	0207d703          	lhu	a4,32(a5)
    80006154:	0026d783          	lhu	a5,2(a3)
    80006158:	06f70163          	beq	a4,a5,800061ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000615c:	0001d917          	auipc	s2,0x1d
    80006160:	ea490913          	addi	s2,s2,-348 # 80023000 <disk>
    80006164:	0001f497          	auipc	s1,0x1f
    80006168:	e9c48493          	addi	s1,s1,-356 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000616c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006170:	6898                	ld	a4,16(s1)
    80006172:	0204d783          	lhu	a5,32(s1)
    80006176:	8b9d                	andi	a5,a5,7
    80006178:	078e                	slli	a5,a5,0x3
    8000617a:	97ba                	add	a5,a5,a4
    8000617c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000617e:	20078713          	addi	a4,a5,512
    80006182:	0712                	slli	a4,a4,0x4
    80006184:	974a                	add	a4,a4,s2
    80006186:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000618a:	e731                	bnez	a4,800061d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000618c:	20078793          	addi	a5,a5,512
    80006190:	0792                	slli	a5,a5,0x4
    80006192:	97ca                	add	a5,a5,s2
    80006194:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006196:	00052223          	sw	zero,4(a0) # 8002512c <disk+0x212c>
    wakeup(b);
    8000619a:	ffffc097          	auipc	ra,0xffffc
    8000619e:	044080e7          	jalr	68(ra) # 800021de <wakeup>

    disk.used_idx += 1;
    800061a2:	0204d783          	lhu	a5,32(s1)
    800061a6:	2785                	addiw	a5,a5,1
    800061a8:	17c2                	slli	a5,a5,0x30
    800061aa:	93c1                	srli	a5,a5,0x30
    800061ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061b0:	6898                	ld	a4,16(s1)
    800061b2:	00275703          	lhu	a4,2(a4)
    800061b6:	faf71be3          	bne	a4,a5,8000616c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061ba:	0001f517          	auipc	a0,0x1f
    800061be:	f6e50513          	addi	a0,a0,-146 # 80025128 <disk+0x2128>
    800061c2:	ffffb097          	auipc	ra,0xffffb
    800061c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>
}
    800061ca:	60e2                	ld	ra,24(sp)
    800061cc:	6442                	ld	s0,16(sp)
    800061ce:	64a2                	ld	s1,8(sp)
    800061d0:	6902                	ld	s2,0(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret
      panic("virtio_disk_intr status");
    800061d6:	00002517          	auipc	a0,0x2
    800061da:	62250513          	addi	a0,a0,1570 # 800087f8 <syscalls+0x3b0>
    800061de:	ffffa097          	auipc	ra,0xffffa
    800061e2:	360080e7          	jalr	864(ra) # 8000053e <panic>
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
