#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char** argv){
    fprintf(2, "Killing system (except shell and init)\n\n");

    kill_system();

    exit(0);
}