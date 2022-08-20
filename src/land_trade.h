/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef LAND_TRADE_H
#  define LAND_TRADE_H


#include "land.h"

/*
 * Helper functions.
 */
void commodity_exchange_open( unsigned int wid );
void commodity_regenList(unsigned int wid);
void commodity_update( unsigned int wid, char* str );
void commodity_updateOwnedCargo(void);
void commodity_buy( unsigned int wid, char* str );
void commodity_sell( unsigned int wid, char* str );
int  commodity_canBuy( const Commodity* com );
int  commodity_canSell( const Commodity* com );
int commodity_getMod (void);
void commodity_renderMod( double bx, double by, double w, double h, void *data );

#endif /* LAND_TRADE_H */
