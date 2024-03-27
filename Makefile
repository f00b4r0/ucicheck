MAIN := ucicheck
CFLAGS := -Wall -O2

# don't touch below this line

OBJS := parser.tab.o scanner.lex.o

all:	$(MAIN)

%.lex.c: %.l parser.tab.h
	flex --never-interactive -o$@ $<

%.tab.h %.tab.c: %.y
	bison -d $<

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS)  -o $@ $^

clean:
	$(RM) $(MAIN) *.output *.tab.h *.tab.c *.lex.c *.o
