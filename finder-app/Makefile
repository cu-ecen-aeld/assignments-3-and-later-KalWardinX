# Author : Akash Rawat (KalWardinX)
# date   : 19/07/2022

CC=gcc
CFLAGS:=-Wall

# check if CROSS_COMPILE is mentioned
ifeq (${CROSS_COMPILE}, aarch64-none-linux-gnu-)
	CC:=${CROSS_COMPILE}${CC}
endif

all: writer

writer: writer.o
	${CC} ${CFLAGS} $^ -o $@

writer.o: writer.c
	${CC} ${CFLAGS} -c $^

clean: 
	rm -f writer *.o