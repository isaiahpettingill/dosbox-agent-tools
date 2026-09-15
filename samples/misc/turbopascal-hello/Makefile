.PHONY: build test clean

build:
	mkdir -p build
	cp HELLO.PAS build/HELLO.PAS
	$(MAKE) -C ../../../toolchains/turbopascal compile WORKDIR="$(CURDIR)/build" PROGRAM=HELLO.PAS ARGS=-B

test: build
	$(MAKE) -C ../../../toolchains/ntvdm run WORKDIR="$(CURDIR)/build" PROGRAM=HELLO.EXE > build/output.txt
	grep -F 'Hello from Turbo Pascal 7!' build/output.txt

clean:
	rm -rf build
