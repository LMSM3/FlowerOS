#include <stdio.h>

#include <unistd.h>

#include <termios.h>


static struct termios oldt;


static void raw_on(void) {

    struct termios newt;

    tcgetattr(STDIN_FILENO, &oldt);

    newt = oldt;

    newt.c_lflag &= (tcflag_t) ~(ICANON | ECHO);   // no line buffering, no echo

    newt.c_cc[VMIN]  = 1;

    newt.c_cc[VTIME] = 0;

    tcsetattr(STDIN_FILENO, TCSANOW, &newt);

}


static void raw_off(void) {

    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);

}


int main(void) {

    raw_on();

    puts("Press keys. 'q' to quit.");


    for (;;) {

        unsigned char c;

        if (read(STDIN_FILENO, &c, 1) != 1) break;


        if (c == 'q') break;


        if (c >= 32 && c < 127) printf("You pressed: %u ('%c')\n", c, c);

        else printf("You pressed: %u (non-printable)\n", c);

        fflush(stdout);

    }


    raw_off();

    return 0;

}

