#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char** argv){
    fprintf(2, "This is our testing script\n\n\n");
    fprintf(2, "Now we're trying kill_system:\n\n");

    kill_system();

    fprintf(2, "kill_system is done\n");
    exit(0);
}