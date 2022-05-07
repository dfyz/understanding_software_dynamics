#!/bin/sh

as amd_puzzler.s -o tmp.o && \
ld tmp.o -o amd_puzzler_fast && \
rm tmp.o

echo "FAST VERSION (bin size = `wc -c < amd_puzzler_fast`)" && ./amd_puzzler_fast

sed 's@.set .L_GO_FAST, 1@.set .L_GO_FAST, 0@' amd_puzzler.s | as -o tmp.o && \
ld tmp.o -o amd_puzzler_slow && \
rm tmp.o

echo "SLOW VERSION (bin size = `wc -c < amd_puzzler_slow`)" && ./amd_puzzler_slow
