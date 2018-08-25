
.include "record-def.s"
.include "linux.s"

# 目的: 此函数从文件描述符读取一条记录
# 
# 输入: 文件描述及缓冲区
# 
# 输出: 本函数将数据写入缓冲区
# 		并返回状态码
#

# 栈局部变量
.equ ST_READ_BUFFER, 8
.equ ST_FILEDES, 12
.section .text
.globl read_record
.type read_record, @function
read_record:
pushl %ebp
movl %esp, %ebp

pushl %ebx
movl ST_FILEDES(%ebp), %ebx
movl ST_READ_BUFFER(%ebp), %ecx
movl $RECORD_SIZE, %edx
movl $SYS_READ, %eax
int $LINUX_SYSCALL

# 注意 - %eax中含返回值, 我们将该值传回调用程序
popl %ebx

movl %ebp, %esp
popl %ebp
ret
