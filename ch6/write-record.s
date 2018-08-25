
.include "linux.s"
.include "record-def.s"
# 目的: 本函数将一条记录写入给定文件描述符
# 
# 输入: 文件描述符和缓冲区
#
# 输出: 本函数产生状态码
# 
# 栈局部变量
.equ ST_WRITE_BUFFER, 8
.equ ST_FILEDES, 12
.section .text
.globl write_record
.type write_record, @function
write_record:
pushl %ebp
movl %esp, %ebp

pushl %ebx
movl $SYS_WRITE, %eax
movl ST_FILEDES(%ebp), %ebx
movl ST_WRITE_BUFFER(%ebp), %ecx
movl $RECORD_SIZE, %edx
int $LINUX_SYSCALL

# 注意 - %eax含返回值, 我们将之传回调用程序
popl %ebx

movl %ebp, %esp
popl %ebp
ret 
