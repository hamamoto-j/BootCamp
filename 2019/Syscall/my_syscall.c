#include <linux/kernel.h>
#include <linux/syscalls.h>

asmlinkage void sys_my_syscall(char* msg)
{
printk("%s\n",msg);
}
