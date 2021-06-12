/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef DEV_SYSEDIT_H
#  define DEV_SYSEDIT_H


#include "space.h"


void sysedit_open( StarSystem *sys );
void sysedit_sysScale( StarSystem *sys, double factor );

void sysedit_renderMap( double bx, double by, double w, double h, double x, double y, double r );


#endif /* DEV_SYSEDIT_H */
