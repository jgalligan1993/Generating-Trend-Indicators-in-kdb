///Trade and Quote Exchanges
//Coinbase
trade_Coinbase:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());
quote_Coinbase:([] time:"p"$();date:`$();sym:`$();exch:`$();ap:"f"$();bp:"f"$());

//Kraken
trade_Kraken:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());
quote_Kraken:([] time:"p"$();date:`$();sym:`$();exch:`$();ap:"f"$();bp:"f"$());

//Bitfinex
trade_Bitfinex:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());
quote_Bitfinex:([] time:"p"$();date:`$();sym:`$();exch:`$();ap:"f"$();bp:"f"$());

//HitBTC
trade_HitBTC:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());
quote_HitBTC:([] time:"p"$();date:`$();sym:`$();exch:`$();ap:"f"$();bp:"f"$());

///Trade only Exchanges
//Bitmex
trade_Bitmex:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());

//Bitstamp
trade_Bitstamp:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());

//Gemini
trade_Gemini:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());

//Huobi
trade_Huobi:([] time:"p"$();date:`$();sym:`$();exch:`$();side:`$();ts:"f"$();tp:"f"$());

//distionaries to be used by .u.upd func in tickerpant
tradeDict:`COINBASE`KRAKEN`HITBTC`BITFINEX!`quote_Coinbase`quote_Kraken`quote_HitBTC`quote_Bitfinex;
quoteDict:`COINBASE`KRAKEN`HITBTC`BITFINEX`BITMEX`BITSTAMP`GEMINI`HUOBI!`trade_Coinbase`trade_Kraken`trade_Bitfinex`trade_HitBTC`trade_Bitmex`trade_Bitstamp`trade_Gemini`trade_Huobi;

//sample .u.upd

//.u.upd:{$[x=`trade;tradeDict[y[3]] insert y; quoteDict[y[3]] insert y]}
