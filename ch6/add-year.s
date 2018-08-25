.include "linux.s"
.include "record-def.s"
.section .data
input_file_name:
.ascii "test.dat\0"

output_file_name:
.ascii "testout.dat\0"

.section .bss
.lcomm record_buffer, RECORD_SIZE

# 局部变量的栈偏移量
.equ ST_INPUT_DESCRIPTOR, -4
.equ ST_OUTPUT_DESCRIPTOR, -8

.section .text
.globl _start
_start:
# 复制栈指针并为局部变量分配空间
movl %esp, %ebp
subl $8, %esp

# 打开用于写入的文件
movl $SYS_OPEN, %eax
movl $output_file_name, %ebx
movl $0101, %ecx

movl $0666, %edx
int $LINUX_SYSCALL

movl %eax, ST_OUTPUT_DESCRIPTOR(%ebp)

loop_begin:
pushl ST_INPUT_DESCRIPTOR(%ebp)
pushl $record_buffer
call read_record
addl $8, %esp

# 返回读取的字节数
# 如果字节数与我们请求的字节数不同
# 说明已到达文件结束处或出现错误,
# 我们就要退出
cmpl $RECORD_SIZE, %eax
jne loop_end

# 递增年龄
incl record_buffer + RECORD_AGE

# 写记录
pushl ST_OUTPUT_DESCRIPTOR(%ebp)
pushl $record_buffer
call write_record
addl $8, %esp

jmp loop_begin

loop_end:
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL
