# Run with:
# as mystery1.s -o mystery1.o && ld mystery1.o -o mystery1 && ./mystery1

.intel_syntax noprefix

.text
.global _start

# === CORE PART ===
# Comment this line to switch from the "fast" behavior to the "slow" one.
.set GO_FAST, 1

.ifdef GO_FAST
.set OFFSET1, 12
.set OFFSET2, 8
.else
.set OFFSET1, 8
.set OFFSET2, 12
.endif

# `r9` is initially set to zero.
# Then the main loop increments `r9` by 42 10^9 times.
#
# 42 and 10^9 are chosen arbitrarily. Only the locations
# of 42 and the current iteration count within the stack
# matter performance-wise.
#
# The number of cycles the main loop took is stored in `r8`.
core_part:
    # Reserve 64 bytes (an arbitrary amount) on the stack
    sub rsp, 64

    # Zero out the result
    xor r9, r9
    # Set the increment
    mov dword ptr [rsp + OFFSET1], 42
    # Zero out the iteration count
    mov dword ptr [rsp + OFFSET2], 0

    # Call rtdsc before the loop
    call get_cycles
    mov r8, rax

main_loop:
    # Load the increment from the stack
    mov eax, [rsp + OFFSET1]
    # Sign-extend the increment to a 64-bit value
    cdqe
    # Add the increment to the result
    add r9, rax
    # Increment the iteration count.
    add dword ptr [rsp + OFFSET2], 1
    # If we're not done, jump back to the beginning of the main loop.
    cmp dword ptr [rsp + OFFSET2], 999999999
    jle main_loop

    # Call rtdsc after the loop and compute the number of elapsed cycles
    call get_cycles
    sub rax, r8
    mov r8, rax

    # Restore the stack and exit
    add rsp, 64
    ret

# === PLUMBING ===
# The rest is just boring wrappers around the core part.
# You can safely ignore everything below this comment.

# Returns the full 64-bit timestamp counter in `rax`
get_cycles:
    rdtsc
    shl rdx, 32
    or rax, rdx
    ret

# Prints `rax` as a positive decimal number to stdout
print_int:
    sub rsp, 32

    mov byte ptr [rsp], '0'
    xor r10, r10
    mov r11, 10

.L_compute:
    test rax, rax
    jz .L_reverse
    xor rdx, rdx
    div r11
    add rdx, '0'
    mov [rsp + r10], rdx
    inc r10
    jmp .L_compute

.L_reverse:
    mov r12, rsp
    lea r13, [rsp + r10 - 1]

.L_reverse_loop:
    cmp r12, r13
    jae .L_epilogue
    mov r14b, [r12]
    mov r15b, [r13]
    mov [r12], r15b
    mov [r13], r14b
    inc r12
    dec r13
    jmp .L_reverse_loop

.L_epilogue:
    # write(STDOUT, rsp, max(1, r10))
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp
    mov r11, 1
    test r10, r10
    cmovz r10, r11
    mov rdx, r10
    syscall

    add rsp, 32
    ret

# Prints a string literal in `rsi` (with length of `rdx`) to the stdout
print_literal:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

print_nl:
    lea rsi, [rip + nl_str]
    mov rdx, 1
    call print_literal
    ret

# The entry point
_start:
    call core_part

    # Print the number of cycles from r8
    lea rsi, [rip + cycles_str]
    mov rdx, offset cycles_len
    call print_literal
    mov rax, r8
    call print_int
    call print_nl

    # Print the addition result from r9
    lea rsi, [rip + result_str]
    mov rdx, offset result_len
    call print_literal
    mov rax, r9
    call print_int
    call print_nl

    # exit(0)
    mov rax, 60
    mov rdi, 0
    syscall

.data
cycles_str:
    .ascii "cycles = "
    .set cycles_len, . - cycles_str
result_str:
    .ascii "result = "
    .set result_len, . - result_str
nl_str:
    .ascii "\n"
