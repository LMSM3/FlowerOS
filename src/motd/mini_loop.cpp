#include <cstdio>

#include <cstdlib>

#include <unistd.h>

#include <termios.h>

#include <signal.h>


class RawTerm {

public:

    RawTerm() : active(false) {

        if (tcgetattr(STDIN_FILENO, &oldt) == 0) {

            termios newt = oldt;

            newt.c_lflag &= static_cast<tcflag_t>(~(ICANON | ECHO));

            newt.c_cc[VMIN]  = 1;

            newt.c_cc[VTIME] = 0;

            if (tcsetattr(STDIN_FILENO, TCSANOW, &newt) == 0) {

                active = true;

            }

        }

    }


    ~RawTerm() {

        restore();

    }


    void restore() {

        if (active) {

            tcsetattr(STDIN_FILENO, TCSANOW, &oldt);

            active = false;

        }

    }


private:

    termios oldt{};

    bool active;

};


static RawTerm* g_term = nullptr;


static void on_signal(int) {

    if (g_term) g_term->restore();

    std::_Exit(128); // exit immediately, terminal restored

}


int main() {

    RawTerm term;

    g_term = &term;


    signal(SIGINT,  on_signal);

    signal(SIGTERM, on_signal);


    std::puts("Press keys. 'q' to quit.");


    for (;;) {

        unsigned char c = 0;

        ssize_t n = read(STDIN_FILENO, &c, 1);

        if (n != 1) break;


        if (c == 'q') break;


        if (c >= 32 && c < 127) std::printf("You pressed: %u ('%c')\n", c, c);

        else std::printf("You pressed: %u (non-printable)\n", c);


        std::fflush(stdout);

    }


    return 0;

}

