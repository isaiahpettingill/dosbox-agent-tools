#if defined(TYPEFURY_TEST)
#include <assert.h>
#else
#include <conio.h>
#include <dos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#endif

#define ROUNDS 5
#define PASSAGE_COUNT 12
#define INPUT_SIZE 192
#define INPUT_ROW 11
#define MISTAKES_ROW 20
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25

#if !defined(TYPEFURY_TEST)

static const char *passages[PASSAGE_COUNT] = {
    "The life of man, solitary, poor, nasty, brutish, and short.",
    "The nature of man is a perpetual and restless desire of power after power, that ceaseth only in death.",
    "Quoth the Raven, Nevermore.",
    "Deep into that darkness peering, long I stood there wondering, fearing.",
    "God, what a good vassal, if only he had a good lord!",
    "He was a bold man that first ate an oyster.",
    "There are more things in heaven and earth, Horatio, than are dreamt of in your philosophy.",
    "Now is the winter of our discontent made glorious summer by this sun of York.",
    "I was a child and she was a child, in a kingdom by the sea.",
    "The world is full of obvious things which nobody by any chance ever observes.",
    "It is a melancholy object to those who walk through this great town or travel in the country.",
    "Begin at the beginning and go on till you come to the end: then stop."
};

static const char *sources[PASSAGE_COUNT] = {
    "Thomas Hobbes, Leviathan",
    "Thomas Hobbes, Leviathan",
    "Edgar Allan Poe, The Raven",
    "Edgar Allan Poe, The Raven",
    "The Cantar de mio Cid",
    "Jonathan Swift, Polite Conversation",
    "William Shakespeare, Hamlet",
    "William Shakespeare, Richard III",
    "Edgar Allan Poe, Annabel Lee",
    "Arthur Conan Doyle, The Hound of the Baskervilles",
    "Jonathan Swift, A Modest Proposal",
    "Lewis Carroll, Alice's Adventures in Wonderland"
};

#endif

static int update_input(int key, const char *passage, char *typed,
                        unsigned int *length, unsigned long *mistakes)
{
    if (key == 27) {
        return 1;
    }
    if (key == 8) {
        if (*length > 0) {
            --*length;
            typed[*length] = '\0';
        }
    } else if ((unsigned char) key ==
               (unsigned char) passage[*length]) {
        typed[*length] = (char) key;
        ++*length;
        typed[*length] = '\0';
    } else {
        ++*mistakes;
    }
    return 0;
}

static int is_extended_key(int key)
{
    return key == 0 || key == 0xe0;
}

#if defined(TYPEFURY_TEST)

int main(void)
{
    char typed[INPUT_SIZE];
    unsigned int length;
    unsigned long mistakes;

    length = 0;
    mistakes = 0;
    typed[0] = '\0';
    assert(update_input('A', "A b", typed, &length, &mistakes) == 0);
    assert(typed[0] == 'A');
    assert(typed[1] == '\0');
    assert(length == 1);
    assert(mistakes == 0);
    assert(update_input('x', "A b", typed, &length, &mistakes) == 0);
    assert(typed[0] == 'A');
    assert(typed[1] == '\0');
    assert(mistakes == 1);
    assert(update_input(8, "A b", typed, &length, &mistakes) == 0);
    assert(length == 0);
    assert(typed[0] == '\0');
    assert(mistakes == 1);
    assert(update_input(27, "A b", typed, &length, &mistakes) == 1);
    assert(is_extended_key(0));
    assert(is_extended_key(0xe0));
    assert(!is_extended_key('A'));
    return 0;
}

#else

static void move_cursor(unsigned char row, unsigned char column)
{
    union REGS regs;

    regs.h.ah = 0x02;
    regs.h.bh = 0;
    regs.h.dh = row - 1;
    regs.h.dl = column - 1;
    int86(0x10, &regs, &regs);
}

static void clear_screen(void)
{
    unsigned char row;

    for (row = 1; row <= SCREEN_HEIGHT; ++row) {
        move_cursor(row, 1);
        cprintf("%80s", "");
    }
    move_cursor(1, 1);
}

static void position_input_cursor(unsigned int length)
{
    move_cursor(INPUT_ROW + length / SCREEN_WIDTH,
                1 + length % SCREEN_WIDTH);
}

static void draw_mistakes(unsigned long mistakes)
{
    move_cursor(MISTAKES_ROW, 1);
    cprintf("Mistakes: %lu", mistakes);
}

static void draw_round(int round, const char *passage, const char *source,
                       const char *typed, unsigned long mistakes)
{
    clear_screen();
    cprintf("TYPE FURY: THE DEAD AUTHORS FIGHT BACK\r\n");
    cprintf("Round %d of %d   Esc quits this game\r\n\r\n", round, ROUNDS);
    cprintf("TYPE THIS EXACTLY:\r\n");
    cprintf("%s\r\n", passage);
    cprintf("%s\r\n\r\n", source);
    cprintf("Your line:\r\n");
    draw_mistakes(mistakes);
    position_input_cursor(0);
    cprintf("%s", typed);
}

static void update_round_display(const char *typed, unsigned int previous_length,
                                 unsigned int length, unsigned long mistakes)
{
    if (length < previous_length) {
        position_input_cursor(length);
        cprintf(" ");
    } else if (length > previous_length) {
        position_input_cursor(previous_length);
        cprintf("%c", typed[previous_length]);
    }
    draw_mistakes(mistakes);
    position_input_cursor(length);
}

static void show_intro(void)
{
    clear_screen();
    cprintf("TYPE FURY\r\n");
    cprintf("=========\r\n\r\n");
    cprintf("Five ridiculous sentences have escaped from public-domain books.\r\n");
    cprintf("Type each sentence exactly as shown, including capitals and punctuation.\r\n");
    cprintf("Wrong keys count as mistakes; Backspace removes your last good key.\r\n\r\n");
    cprintf("Press any key to confront the classics.");
    getch();
}

static void show_results(clock_t elapsed, unsigned long characters,
                         unsigned long mistakes)
{
    double seconds;
    double words_per_minute;
    double accuracy;

    seconds = (double) elapsed / (double) CLOCKS_PER_SEC;
    if (seconds < 0.1) {
        seconds = 0.1;
    }
    words_per_minute = ((double) characters / 5.0) * 60.0 / seconds;
    accuracy = ((double) characters * 100.0) /
               ((double) characters + (double) mistakes);

    clear_screen();
    cprintf("THE LIBRARY SURVIVED\r\n\r\n");
    cprintf("Characters: %lu\r\n", characters);
    cprintf("Mistakes:   %lu\r\n", mistakes);
    cprintf("Time:       %.1f seconds\r\n", seconds);
    cprintf("Speed:      %.1f WPM\r\n", words_per_minute);
    cprintf("Accuracy:   %.1f%%\r\n\r\n", accuracy);
    if (mistakes == 0) {
        cprintf("Remember this: The key is MICHAELANGELO\r\n\r\n");
    }
    cprintf("Press any key to return to DOS.");
    getch();
}

int main(void)
{
    int order[PASSAGE_COUNT];
    int i;
    int j;
    int pick;
    int key;
    unsigned int length;
    unsigned int previous_length;
    unsigned long characters;
    unsigned long mistakes;
    char typed[INPUT_SIZE];
    clock_t started;
    clock_t finished;

    srand((unsigned int) time(NULL));
    for (i = 0; i < PASSAGE_COUNT; ++i) {
        order[i] = i;
    }
    for (i = 0; i < ROUNDS; ++i) {
        pick = i + rand() % (PASSAGE_COUNT - i);
        j = order[i];
        order[i] = order[pick];
        order[pick] = j;
    }

    show_intro();
    characters = 0;
    mistakes = 0;
    started = clock();

    for (i = 0; i < ROUNDS; ++i) {
        length = 0;
        typed[0] = '\0';
        draw_round(i + 1, passages[order[i]], sources[order[i]], typed, mistakes);

        while (typed[length] != passages[order[i]][length]) {
            key = getch();
            previous_length = length;
            if (is_extended_key(key)) {
                getch();
                ++mistakes;
            } else if (update_input(key, passages[order[i]], typed, &length,
                                    &mistakes)) {
                clear_screen();
                return 0;
            }
            update_round_display(typed, previous_length, length, mistakes);
        }
        characters += length;
    }

    finished = clock();
    show_results(finished - started, characters, mistakes);
    return 0;
}

#endif
