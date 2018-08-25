# 目的: 本程序将输入文件的所有字母转换为大写字母
#		然后输出到输出文件
#
# 处理过程: (1) 打开输入文件
#			(2) 打开输出文件
#			(3) 如果未达到输入文件尾部:
#				(a) 将部分文件读入内存缓冲区
#				(b) 读取内存缓冲区的每个字节,如果该字节为小写字母,
#					就将其转换为大写字母
#				(c) 将内存缓冲区写入输出文件

.section .data

###########常数##############

# 系统调用号
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 1

# 文件打开选项(不同的值请参见/usr/include/asm/fcntl.h
# 你可以通过将选项值相加或进行OR操作组合使用选项)
# 这将在10.1.2中深入阐述
.equ O_RDONLY, 0
.equ O_CREAT_WRONL_TRUNC, 03101

# 标准文件描述符
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

# 系统调用中断
.equ LINUX_SYSCALL, 0x80

.equ END_OF_FILE, 0 	# 这是读操作返回值
						# 表明到达文件结束处

.equ NUMBER_ARGUMENTS, 2

.section .bss
# 缓冲区 - 	从文件中将数据加载到这里, 
#			也要从这里将数据写入输出文件
#			由于种种原因, 缓冲区大小不应
#			超过16 000字节
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text

# 栈位置
.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0				# 参数数目
.equ ST_ARGV_0, 4			# 程序名
.equ ST_ARGV_1, 8			# 输入文件名
.equ ST_ARGV_2, 12			# 输出文件名

.globl _start
_start:
###程序初始化###
# 保存栈指针
movl %esp, %ebp

# 在栈上文件描述符分配空间
subl $ST_SIZE_RESERVE, %esp


open_files:
open_fd_in:
###打开输入文件###
# 打开系统调用
movl $SYS_OPEN, %eax
# 将输入文件名放入`%ebx`
movl ST_ARGV_1(%ebp), %ebx
# 只读标志
movl $O_RDONLY, %ecx
# 这实际上并不影响读操作
movl $0666, %edx
# 调用Linux
int $LINUX_SYSCALL

store_fd_in:
# 保存给定的文件描述符
movl %eax, ST_FD_IN(%ebp)

open_fd_out:
###打开输出文件###
# 打开文件
movl $SYS_OPEN, %eax
# 将输出文件名放入%ebx
movl ST_ARGV_2(%ebp), %ebx
# 写入文件标志
movl $O_CREAT_WRONL_TRUNC, %ecx
# 新文件模式(如果已创建)
movl $0666, %edx
# 调用Linux
int $LINUX_SYSCALL


store_fd_out:
# 这里存储文件描述符
movl %eax, ST_FD_OUT(%ebp)

###主循环开始###
read_loop_begin:

###从输入文件中读取一个数据块###
movl $SYS_READ, %eax
# 获取输入文件描述符
movl ST_FD_IN(%ebp), %ebx
# 放置读取数据的存储位置
movl $BUFFER_DATA, %ecx
# 缓冲区大小
movl $BUFFER_SIZE, %edx
# 读取缓冲区大小返回到%eax中
int $LINUX_SYSCALL

###如到达文件结束处就退出###
# 检查文件结束标记
cmpl $END_OF_FILE, %eax
# 如果发现文件结束或出现错误, 就跳转到程序结束处
jle end_loop


continue_read_loop:
###将字符块内容转换成大写形式###
pushl $BUFFER_DATA		# 缓冲区位置
pushl %eax				# 缓冲区大小
call convert_to_upper		
popl %eax				# 重新获取大小
addl $4, %esp			# 恢复%esp

###将字符块写入输出文件###
# 缓冲区大小
movl %eax, %edx
movl $SYS_WRITE, %eax
# 要使用的文件
movl ST_FD_OUT(%ebp), %ebx
# 缓冲区位置
movl $BUFFER_DATA, %ecx
int $LINUX_SYSCALL


###循环继续###
jmp read_loop_begin

end_loop:
###关闭文件###
# 注意 - 这里我们无需进行错误检测
#		 因为错误情况不代表任何特殊含义
movl $SYS_CLOSE, %eax
movl ST_FD_OUT(%ebp), %ebx
int $LINUX_SYSCALL

movl $SYS_CLOSE, %eax
movl ST_FD_IN(%ebp), %ebx
int $LINUX_SYSCALL

###退出###
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL

# 目的: 这个函数实际上将字符快内容转换为大写形式
# 
# 输入: 第一个参数是要转换的内存块的位置
# 		第二个参数是缓冲区的长度
#
# 输出: 这个函数以大写字符块覆盖当前缓冲区
# 
# 变量: 
#		%eax - 缓冲区起始地址
#		%ebx - 缓冲区长度
#		%edi - 当前缓冲区偏移量
#		%cl	 - 当前正在检测的字节
#						(%ecx的第一部分)
#

###常数###
# 我们搜索的下边界
.equ LOWERCASE_A, 'a'
# 我们搜索的上边界
.equ LOWERCASE_Z, 'z'
# 大小写转换
.equ UPPER_CONVERSION, 'A' - 'a'

###栈相关信息###
.equ ST_BUFFER_LEN, 8		# 缓冲区长度
.equ ST_BUFFER, 12			# 实际缓冲区
convert_to_upper:
pushl %ebp
movl %esp, %ebp

###设置变量###
movl ST_BUFFER(%ebp), %eax
movl ST_BUFFER_LEN(%ebp), %ebx
movl $0, %edi

# 如果给定的缓冲区长度为0即离开
cmpl $0, %ebx
je end_convert_loop

convert_loop:
# 获取当前字节
movb (%eax, %edi, 1), %cl

# 除非该字节在'a'和'z'之间, 否则读取下一个字节
cmpb $LOWERCASE_A, %cl
jl next_byte
cmpb $LOWERCASE_Z, %cl
jg next_byte

# 否则将字节转换为大写字母
addb $UPPER_CONVERSION, %cl
# 并存回原处
movb %cl, (%eax, %edi, 1)
next_byte:
incl %edi				# 下一字节
cmpl %edi, %ebx			# 继续执行程序
						# 直到文件结束
jne convert_loop		

end_convert_loop:
# 无返回值, 离开程序即可
movl %ebp, %esp
popl %ebp
ret
