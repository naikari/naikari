/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef BOARD_H
#  define BOARD_H


#include "pilot.h"


enum {
   PLAYER_BOARD_OK,
   PLAYER_BOARD_RETRY,
   PLAYER_BOARD_IMPOSSIBLE,
   PLAYER_BOARD_ERROR
};


int player_isBoarded (void);
int player_board(void);
void board_unboard (void);
int pilot_board( Pilot *p );
void pilot_boardComplete( Pilot *p );
void board_exit( unsigned int wdw, char* str );


#endif
