all: build

build:
	cobc -x -o calculator calculator.cob

test: build
	./run_tests.sh

clean:
	rm -f calculator

.PHONY: all build test clean
