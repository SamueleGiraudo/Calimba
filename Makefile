# Author: Samuele Giraudo
# Creation: may 2022
# Modifications: may 2022, aug. 2022, nov. 2022, jul. 2023

CC = ocamlbuild
FLAGS = -r -cflags -w,A-4-70 -menhir "menhir --explain"
#-tag debug -tag "optimize(2)" -tag "optimization_rounds(4)"
LIBS =-package unix -package extlib -tag thread -use-menhir

SRC_DIR = Sources

NAME = calimba
EXEC = Calimba.native

.PHONY: all
all: $(NAME)

.PHONY: $(NAME)
$(NAME):
	$(CC) $(FLAGS) $(LIBS) $(SRC_DIR)/$(EXEC)
	mv -f $(EXEC) $(NAME)

.PHONY: noassert
noassert: FLAGS += -cflag -noassert
noassert: all

.PHONY: clean
clean:
	rm -rf _build
	rm -f $(NAME)

.PHONY: stats
stats:
	wc $(SRC_DIR)/*.ml $(SRC_DIR)/*.mly $(SRC_DIR)/*.mll

