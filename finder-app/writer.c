/*
    Author : Akash Rawat (KalWardinX)
    date   : 19/07/2022
*/
#include <stdio.h>
#include <syslog.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
int main ( int argc , char **argv ){
    if ( argc != 3){
        openlog(NULL, 0, LOG_USER);
        syslog(LOG_ERR,"usage: ./writer [writefile] [writestr]");
        closelog();
        exit(1);
    }
    const char* writefile   = argv[1];
    const char* writestr    = argv[2];
    FILE* filename  = fopen(writefile, "w");
    if ( filename == NULL ){
        int err = errno;
        openlog(NULL, 0, LOG_USER);
        syslog(LOG_ERR,"Error opening file: %s", strerror(err));
        closelog();
        exit(1);
    }
    openlog(NULL, 0, LOG_USER);
    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);
    closelog();
    fprintf(filename, "%s", writestr);
    fclose(filename);
    return 0;
}