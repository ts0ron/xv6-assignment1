#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char** argv){
    fprintf(2, "Pausing system\n\n");
    pause_system(5);

    fprintf(2, "pause instruction is done.\n");
    exit(0);
}