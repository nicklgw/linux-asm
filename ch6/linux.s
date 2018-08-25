# Linux常量定义

# 系统调用号
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ SYS_BRK, 45

# 系统调用中断号
.equ LINUX_SYSCALL, 0x80

# 标准文件描述符
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

# 通用状态码
.equ END_OF_FILE, 0
