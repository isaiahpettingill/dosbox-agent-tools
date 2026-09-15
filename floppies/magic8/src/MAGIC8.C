#if defined(MAGIC8_TEST)
#include <assert.h>
#else
#include <conio.h>
#include <dos.h>
#include <string.h>
#endif

#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25
#define SHAKE_KEYS 12
#define VIDEO_SEGMENT 0xB800

static const char *answers[] = {
    "IT IS CERTAIN",
    "IT IS DECIDEDLY SO",
    "WITHOUT A DOUBT",
    "YES, DEFINITELY",
    "YOU MAY RELY ON IT",
    "AS I SEE IT, YES",
    "MOST LIKELY",
    "OUTLOOK GOOD",
    "YES",
    "SIGNS POINT TO YES",
    "REPLY HAZY, TRY AGAIN",
    "ASK AGAIN LATER",
    "BETTER NOT TELL YOU NOW",
    "CANNOT PREDICT NOW",
    "CONCENTRATE AND ASK AGAIN",
    "DON'T COUNT ON IT",
    "MY REPLY IS NO",
    "MY SOURCES SAY NO",
    "OUTLOOK NOT SO GOOD",
    "VERY DOUBTFUL"
};

static unsigned long mix_seed(unsigned long seed, unsigned char key,
                              unsigned int cycles)
{
    seed ^= ((unsigned long) key * 257UL) ^ ((unsigned long) cycles * 65537UL);
    return seed * 25173UL + 13849UL;
}

static unsigned int answer_index(unsigned long seed)
{
    return (unsigned int) (seed % (sizeof(answers) / sizeof(answers[0])));
}

#if defined(MAGIC8_TEST)

int main(void)
{
    unsigned long seed;

    seed = mix_seed(0x8BADC0DEUL, 'A', 0x1234);
    assert(seed == mix_seed(0x8BADC0DEUL, 'A', 0x1234));
    assert(seed != mix_seed(0x8BADC0DEUL, 'B', 0x1234));
    assert(answer_index(seed) < 20);
    return 0;
}

#else

static void set_cursor_visible(int visible)
{
    union REGS regs;

    regs.h.ah = 0x01;
    regs.h.ch = visible ? 0x06 : 0x20;
    regs.h.cl = 0x07;
    int86(0x10, &regs, &regs);
}

static void put_cell(unsigned int row, unsigned int column, char character,
                     unsigned char color)
{
    unsigned short far *video;

    video = (unsigned short far *) MK_FP(VIDEO_SEGMENT, 0);
    video[row * SCREEN_WIDTH + column] =
        ((unsigned short) color << 8) | (unsigned char) character;
}

static void clear_screen(unsigned char color)
{
    unsigned int row;
    unsigned int column;

    for (row = 0; row < SCREEN_HEIGHT; ++row) {
        for (column = 0; column < SCREEN_WIDTH; ++column) {
            put_cell(row, column, ' ', color);
        }
    }
}

static void draw_text(unsigned int row, unsigned int column, const char *text,
                      unsigned char color)
{
    while (*text != '\0' && column < SCREEN_WIDTH) {
        put_cell(row, column, *text, color);
        ++text;
        ++column;
    }
}

static void draw_centered(unsigned int row, const char *text, unsigned char color)
{
    unsigned int length;

    length = (unsigned int) strlen(text);
    draw_text(row, (SCREEN_WIDTH - length) / 2, text, color);
}

static unsigned int timer_cycles(void)
{
    unsigned int low;
    unsigned int high;

    /* Latch PIT channel 0 without changing its normal DOS timer setup. */
    outp(0x43, 0x00);
    low = (unsigned int) inp(0x40);
    high = (unsigned int) inp(0x40);
    return low | (high << 8);
}

static unsigned long next_noise(unsigned long *seed)
{
    *seed = *seed * 25173UL + 13849UL;
    return *seed;
}

static void discard_buffered_keys(void)
{
    while (kbhit()) {
        getch();
    }
}

static void draw_noise(unsigned long *seed, unsigned int shake_count)
{
    static const char glyphs[] = "*+x#@%!?/\\|<>=~.";
    unsigned int row;
    unsigned int column;
    unsigned long value;
    unsigned char color;

    clear_screen(0x01);
    draw_centered(1, "THE COSMIC EIGHT BALL", 0x0E);
    draw_centered(3, "SHAKE IT WITH RANDOM KEYS", 0x0B);
    draw_centered(5, "THE ORACLE IS MIXING THE STARS...", 0x0D);

    for (row = 7; row < 19; ++row) {
        for (column = 8; column < 72; ++column) {
            value = next_noise(seed);
            color = (unsigned char) (0x01 + ((value >> 8) % 14));
            put_cell(row, column, glyphs[value % (sizeof(glyphs) - 1)], color);
        }
    }

    draw_centered(21, "KEEP SHAKING!", 0x0A);
    draw_text(23, 29, "KEYS:             / 12", 0x0F);
    put_cell(23, 35, (char) ('0' + shake_count / 10), 0x0F);
    put_cell(23, 36, (char) ('0' + shake_count % 10), 0x0F);
    draw_centered(24, "Q QUITS", 0x08);
}

static const char *choose_answer(unsigned long seed)
{
    return answers[answer_index(seed)];
}

static int show_answer(unsigned long seed)
{
    static const char *eight[] = {
        "  88888888  ",
        " 88      88 ",
        " 88      88 ",
        "  88888888  ",
        " 88      88 ",
        " 88      88 ",
        "  88888888  "
    };
    unsigned int line;
    int key;

    clear_screen(0x01);
    draw_centered(2, "THE EIGHT HAS SPOKEN", 0x0E);
    for (line = 0; line < 7; ++line) {
        draw_centered(5 + line, eight[line], 0x0B);
    }
    draw_centered(14, choose_answer(seed), 0x0F);
    draw_centered(18, "PRESS ENTER TO ASK AGAIN", 0x0A);
    draw_centered(20, "PRESS Q TO QUIT", 0x08);
    for (;;) {
        key = getch();
        if (key == 0 || key == 0xE0) {
            getch();
        } else if (key == 'q' || key == 'Q') {
            return 1;
        } else if (key == 13) {
            discard_buffered_keys();
            return 0;
        }
    }
}

int main(void)
{
    unsigned int shake_count;
    unsigned int cycles;
    unsigned long seed;
    int key;

    set_cursor_visible(0);
    for (;;) {
        seed = 0x8BADC0DEUL ^ timer_cycles();
        shake_count = 0;
        while (shake_count < SHAKE_KEYS) {
            draw_noise(&seed, shake_count);
            key = getch();
            if (key == 0 || key == 0xE0) {
                key = getch() | 0x80;
            }
            if (key == 'q' || key == 'Q') {
                set_cursor_visible(1);
                return 0;
            }
            cycles = timer_cycles();
            seed = mix_seed(seed, (unsigned char) key, cycles);
            ++shake_count;
        }
        /* Ignore surplus shake keys before accepting a deliberate response. */
        discard_buffered_keys();
        if (show_answer(seed)) {
            break;
        }
    }
    set_cursor_visible(1);
    return 0;
}

#endif
