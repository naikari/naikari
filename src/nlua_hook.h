/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef NLUA_HOOK
#  define NLUA_HOOK

#include "nlua.h"


/* individual library stuff */
int nlua_loadHook( nlua_env env );


/* Misc. */
int hookL_getarg( unsigned long hook );
void hookL_unsetarg( unsigned long hook );


#endif /* NLUA_HOOK */
