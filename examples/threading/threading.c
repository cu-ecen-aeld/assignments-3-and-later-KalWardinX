#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    int ret;
    // wait time specified in milliseconds
    struct timespec waittime = { 0, (long)thread_func_args->wait_obt * 1000000 };
    nanosleep(&waittime,NULL);
    ret = pthread_mutex_lock(thread_func_args->mut);
    if ( ret )
    {
        ERROR_LOG("mutex lock failed, %d",ret);
        return thread_param;      	
    }
    waittime.tv_nsec = (long)thread_func_args->wait_rel * 1000000;
    nanosleep(&waittime,NULL);
    ret = pthread_mutex_unlock(thread_func_args->mut);
    if ( ret )
    {
        ERROR_LOG("mutex lock failed, %d",ret);
        return thread_param;
    }
    thread_func_args->thread_complete_success = true;

    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    int ret;
    struct thread_data *p_input_thread_data/*, *p_output_thread_data*/;
    p_input_thread_data = (struct thread_data *)malloc( sizeof(struct thread_data) );
    if ( !p_input_thread_data ) { 
	    ERROR_LOG("allocating thread data failed, %d",errno);
	    return false;
    }
    p_input_thread_data->wait_obt = wait_to_obtain_ms;
    p_input_thread_data->wait_rel = wait_to_release_ms;
    p_input_thread_data->mut = mutex;
    p_input_thread_data->thread_complete_success = false;
    ret = pthread_create(thread,NULL,threadfunc,p_input_thread_data);
    if ( ret ) {
	   ERROR_LOG("failed to create thread, %d",ret);
	   return false;
    }
    return true;
}

