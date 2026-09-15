FLOPPIES := $(sort $(notdir $(patsubst %/Makefile,%,$(wildcard */Makefile))))

.PHONY: all clean $(FLOPPIES)

all: $(FLOPPIES)

$(FLOPPIES):
	$(MAKE) -C $@ image

clean:
	@for floppy in $(FLOPPIES); do $(MAKE) -C $$floppy clean; done
