# 目的: 对字符进行计算, 直到遇到空字符 
#  		(如果你用过C语言, 就会发现这与strlen函数的功能相同)
# 
# 输入: 字符串地址
#
# 输出: 将计数值返回到%eax
#
# 过程:
#	用到的寄存器
#	%ecx - 当前计数
#	%al - 当前字符
#	%edx - 当前字符地址
#

.type count_chars, @function
.globl count_chars

# 这是我们的一个参数在栈上的位置
.equ ST_STRING_START_ADDRESS, 8
count_chars:
pushl %ebp
movl %esp, %ebp

# 计数器从0开始
movl $0, %ecx
# 数据的起始地址
movl ST_STRING_START_ADDRESS(%ebp), %edx

count_loop_begin:
# 获取当前字符
movb (%ebx), %al
# 是否为空字符?
cmpb $0, %al
# 若为空字符则结束
je count_loop_end
# 否则, 递增计数器和指针
incl %ecx
incl %edx
# 返回循环起始地址
jmp count_loop_begin

count_loop_end:
# 结束循环, 将计数值移入%eax并返回
movl %ecx, %eax

popl %ebp
ret
