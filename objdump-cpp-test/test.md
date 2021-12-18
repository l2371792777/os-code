```c++
int test()
{
    int i=0;
    i=i+2;
    return i;
}
```
```
0000000000001129 <_Z4testv>:
    1129:	f3 0f 1e fa          	endbr64 
    112d:	55                   	push   %rbp
    112e:	48 89 e5             	mov    %rsp,%rbp
    1131:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
    1138:	83 45 fc 02          	addl   $0x2,-0x4(%rbp)
    113c:	8b 45 fc             	mov    -0x4(%rbp),%eax
    113f:	5d                   	pop    %rbp
    1140:	c3                   	retq   ;返回main函数

```

```c++
int main()
{
    test();
    return 0;
}
```
```
0000000000001141 <main>:
    1141:	f3 0f 1e fa          	endbr64 
    1145:	55                   	push   %rbp
    1146:	48 89 e5             	mov    %rsp,%rbp
    1149:	e8 db ff ff ff       	callq  1129 <_Z4testv> ;调用test函数，将下一条指令地址入栈
    114e:	b8 00 00 00 00       	mov    $0x0,%eax
    1153:	5d                   	pop    %rbp
    1154:	c3                   	retq   
    1155:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
    115c:	00 00 00 
    115f:	90    
```