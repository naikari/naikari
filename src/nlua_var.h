/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef NLUA_VAR
#  define NLUA_VAR

#include "nlua.h"


/* checks if a flag exists on the variable stack */
int var_checkflag( const char* str );
void var_cleanup (void);

/* individual library stuff */
int nlua_loadVar( nlua_env env );


#endif /* NLUA_VAR */
