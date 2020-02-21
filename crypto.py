import sys

#print(sys.path)
#sys.path.append('/mnt/c/User/James/OneDrive/Documents/cryptofeed-master/cryptofeed')
#print(sys.path)

from cryptofeed.callback import TickerCallback, TradeCallback, BookCallback, FundingCallback
from cryptofeed.feedhandler import FeedHandler
from cryptofeed.exchanges import Coinbase,Kraken,Bitmex,Gemini,HitBTC,Huobi,Bitfinex,Bitstamp
from cryptofeed.defines import TRADES, TICKER

import time
from qpython import qconnection

q=qconnection.QConnection(host='localhost',port=5100,pandas=True)
q.open()
#q("""trade:([]time:`timestamp$();date:`date$();id:`symbol$();exch:`symbol$();side:`symbol$();ts:`float$();tp:`float$())""")
#q("""quote:([]time:`timestamp$();date:`date$();id:`symbol$();exch:`symbol$();ap:`float$();bp:`float$())""")

async def ticker(feed, pair, bid, ask):
    print(f'Feed: {feed} Pair: {pair} Bid: {bid} Ask: {ask}')
    q.sendAsync('.u.upd[`quote;(.z.p;.z.d;`{};`{};{};{})]'.format(str(pair.replace("-","_")),str(feed),float(bid),float(ask)))


async def trade(feed, pair, order_id, timestamp, side, amount, price):
    print(f"Timestamp: {timestamp} Feed: {feed} Pair: {pair} ID: {order_id} Side: {side} Amount: {amount} Price: {price}")
    ##q.sendAsync('`trade insert (.z.p;.z.d;`{};`{};`{};{};{})'.format(str(pair.replace("-","_")),str(feed),str(side),float(amount),float(price)))
    q.sendAsync('`.u.upd[`trade;(.z.p;.z.d;`{};`{};`{};{};{})]'.format(str(pair.replace("-","_")),str(feed),str(side),float(amount),float(price)))

##works for Coinbase/Kraken/Bitfinex _feed(Coinbase(pairs....
##Bitmex/Bitstamp ->No ticker callback
##Binance/Poleniex=No
def main():
    f = FeedHandler()
    f.add_feed(Coinbase(pairs=['BTC-USD','ETH-USD'], channels=[TRADES, TICKER], callbacks={TICKER: TickerCallback(ticker), TRADES: TradeCallback(trade)}))
    f.add_feed(Kraken(pairs=['BTC-USD','ETH-USD'],channels=[TRADES,TICKER],callbacks={TICKER: TickerCallback(ticker),TRADES: TradeCallback(trade)}))
    f.add_feed(Bitfinex(pairs=['BTC-USD','ETH-USD'],channels=[TRADES,TICKER], callbacks={TICKER: TickerCallback(ticker), TRADES:TradeCallback(trade)}))
#    f.add_feed(Bitmex(pairs=['XBTUSD','ETHUSD'],channels=[TRADES],callbacks={TRADES:TradeCallback(trade)}))
#    f.add_feed(Bitstamp(pairs=['BTC-USD','ETH-USD'],channels=[TRADES],callbacks={TRADES:TradeCallback(trade)}))
#    f.add_feed(Gemini(pairs=['ETH-USD'], callbacks={TRADES:TradeCallback(trade)}))
#    f.add_feed(Gemini(pairs=['BTC-USD'], callbacks={TRADES:TradeCallback(trade)}))
    f.add_feed(HitBTC(channels=[TRADES,TICKER],pairs=['BTC-USD','ETH-USD'],callbacks={TRADES:TradeCallback(trade),TICKER:TickerCallback(ticker)}))
#    f.add_feed(Huobi(pairs=['BTC-USD','ETH-USD'],channels=[TRADES],callbacks={TRADES:TradeCallback(trade)}))
    f.run()


if __name__ == '__main__':
    main()
