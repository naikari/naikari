/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef LAND_TRADE_H
#  define LAND_TRADE_H


#include "land.h"
#include "toolkit.h"

/*
 * Helper functions.
 */
void commodity_exchange_open(wid_t wid);
void commodity_regenList(wid_t wid);
void commodity_update(wid_t wid, char* str);
void commodity_buy(wid_t wid, char* str);
void commodity_sell(wid_t wid, char* str);
int commodity_canBuy(const Commodity* com);
int commodity_canSell(const Commodity* com);
int commodity_getMod(void);
void commodity_renderMod(double bx, double by, double w, double h, void *data);

#endif /* LAND_TRADE_H */
