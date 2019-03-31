TARGET = test_fmath

CC = gcc
CFLAGS = -c -Wall
LDFLAGS = -lm

SRC = test_fmath.c
OBJ = $(SRC:.c=.o)

all:$(TARGET)
	./$(TARGET)

$(TARGET):$(OBJ)
	$(CC) -o $@ $(OBJ) $(LDFLAGS)

.SUFFIXES: .c .o

.c.o:
	$(CC) $(CFLAGS) $<

clean:
	rm -f $(TARGET) $(TARGET).exe
	rm -f *.o
