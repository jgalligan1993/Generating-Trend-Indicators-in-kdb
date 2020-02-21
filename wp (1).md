

# Simple Statistics in kdb+: Generating Statistics and Trend Indicators  
  
## Introduction  
  
The compactness of kdb+ and the terseness of q means that the language is focused on high performing atomic capabilities  rather than wide range in-built functions. As a result users may sometimes develop libraries of often-used algorithms and  functions relevant to their specific domains for convenience and to support reuse. In this paper, we outline examples of  commonly used functions in finance that are built on native q functions.  
  
The code is developed on ver 3.6 of kdb+ . Cryptocurrency data for Bitcoin and Ethereum from multiple exchanges is used in the examples provided.Graphs are displayed using Kx Analyst.  
  
This whitepaper has 3 main parts:  
  
1. Data Extraction  
2. Simple Statistics  
3. Trend Indicators  

## Data extraction  
  
Data was captured in a similar process to the one used in the following [cryptocurrency blog](https://kx.com/blog/combining-high-frequency-cryptocurrency-venue-data-using-kdb/). Trade and Quote tick data for Etherium(ETH) and Bitcoin(BTC) dominated in the US dollar(USD) was collected from four exchanges:  
  
1. Bitfinex  
2. HitBtc  
3. Kraken  
4. Coinbase  
  
  
  
which span across May/June/July 2019. There is just over 2 months of data.  
  
A Python API was created which connected to a kdb+ tickerplant. The tickerplant processed the messages and sent them to RDB which was written down to a HDB at the end of the day. Such details will not be elaborated on as the main focus of this whitepaper is on Simple Statistics and Trend Indicators. Please view the following resources for help with tick capture:  
  
* [Kdb+tick profiling for throughput optimization](https://code.kx.com/v2/wp/tick-profiling/)  
* [Disaster-recovery planning for kdb+ tick systems](https://code.kx.com/v2/wp/disaster-recovery/)  
* [Query Routing: A kdb+ framework for a scalable, load balanced system](https://code.kx.com/v2/wp/query-routing/)  
  
  
## Simple Statistics  
It is extremely easy and quick to calculate useful statistics using q/kdb as illustrated below.   
```q  
q)select minTp:min tp,cnt:count tp by date,sym,exch from trade where date=2019.05.08   
date 		sym 	exch 	| minTp 	cnt  
---------------------------	| ---------------- 
2019.05.08 BTC_USD BITFINEX	| 6007.8 	35326  
2019.05.08 BTC_USD COINBASE	| 5656.26 	53512  
2019.05.08 BTC_USD HITBTC 	| 5785.19 	151747 
2019.05.08 BTC_USD KRAKEN 	| 5660 		13483  
2019.05.08 ETH_USD BITFINEX	| 169.23 	24892 
2019.05.08 ETH_USD COINBASE	| 162 		28067  
2019.05.08 ETH_USD HITBTC 	| 164.84 	20197  
2019.05.08 ETH_USD KRAKEN 	| 163.5 	10163  
```  
### Trade Functions  
It can be useful to create a dictionary of functions that will be used continuously.. Below is sample of useful trade functions that are commonly used in analysis 
```q  
q)tradeFuncs  
lowPr 		| (min;`tp)  
highPr 		| (max;`tp)  
tcnt 		| (#:;`tp)  
avgPr 		| (avg;`tp)  
vwap 		| (wavg;`ts;`tp)  
volatility 	| ({100*dev[x]%avg[x]};`tp)  
totalReturn	| ({100*reciprocal[last[x]]*max[x]-min[x]};`tp)  
volume 		| (sum;`ts)  
dollarVol 	| ({[ts;tp] sum[tp*ts]};`ts;`tp)  
open 		| (*:;`tp)  
close 		| (last;`tp)  
twap 		| ({[t;p] reciprocal(sum td) %sum p*td:1_deltas[t],0D00:00:00.000000000};`time;`tp)  
twas 		| ({[t;p] reciprocal(sum td) %sum p*td:1_deltas[t],0D00:00:00.000000000};`time;`ts)  
avgSz 		| (avg;`ts)  
minSz 		| (min;`ts)  
maxSz 		| (max;`ts)  
startTime 	| (min;`time)  
endTime 	| (max;`time)  

```  
  
These stats are easy to compute like open/close/min/max of price/size or count of trades to more complex calculations like avg price, volume weighted price(vwap), volume, dollar Volume. These functions all use aggregation functions in kdb+.  An example of how to calculate time-weighted calculations is seen in twap.  The below example shows how simple it is to compute.  

```q  
/Example 
?[trade;((=;`date;2019.05.08);(=;`sym;enlist `ETH_USD));{x!x} `date`exch`sym;tradeFuncs] 
```  
  
### Quote Functions  
In addition to trade functions we can create a dictionary of quote-based statistics that are very common in data analysis.  
    
```q  
q)quoteFuncs
minAp  | (min;`ap)
maxAp  | (max;`ap)
minBp  | (min;`bp)
maxBp  | (max;`bp)
qcnt   | (#:;`ap)
avgSprd| (avg;(-;`ap;`bp))
maxSprd| (max;(-;`ap;`bp))
minSprd| (min;(-;`ap;`bp))
twAsk  | ({[t;p] reciprocal(sum td) %sum p*td:1_deltas[t],0D00:00:00.000000000};`time;`ap)
twBid  | ({[t;p] reciprocal(sum td) %sum p*td:1_deltas[t],0D00:00:00.000000000};`time;`bp)
twSprd | ({[t;p] reciprocal(sum td) %sum p*td:1_deltas[t],0D00:00:00.000000000};`time;(-;`ap;`bp))  
/Example execution
?[quote;((within;`date;2019.05.07 2019.05.09);(=;`sym;enlist `BTC_USD));{x!x} `date`exch`sym;quoteFuncs]
```  
A common request would be to find the last trade, or last trade at a particular time, and along with where it was traded and at what price and size . This can be done by using a simple select seen below  
```q
/Raw select-
q)select last sym,last time,last date,last exch,last side,last tp,last ts from trade where date=2019.05.08,sym=`ETH_USD,time<2019.05.08D12:00:00.000000000
sym     time                          date       exch   side tp      ts
----------------------------------------------------------------------------
ETH_USD 2019.05.08D11:59:56.631496000 2019.05.08 HITBTC sell 171.238 21.2405
```

### Using Asof joins
A useful tool for calculating the above is using an asof join.  
```q
/AJ-
q)t:([] sym:enlist `ETH_USD;time:enlist 2019.05.08D12:00:00.000000000)
q)t
sym     time
-------------------------------------
ETH_USD 2019.05.08D12:00:00.000000000
q)aj[`sym`time;t;select from trade where date=2019.05.08]
sym     time                          date       exch   side ts      tp
----------------------------------------------------------------------------
ETH_USD 2019.05.08D12:00:00.000000000 2019.05.08 HITBTC sell 21.2405 171.238
```

### Binned price
You can leverage this further when requesting trades executed at a particular time.  Below is a function the can be used to generate bins between a particular start and end time for whatever size is needed. A sample table is created below using  ETH_USD for the sym with the specified bins.
```q  
q)getBins  
{[st;et;binSize]  
	binS:16h$`second$binSize;  
	tSpan:et-st;  
	numBins:ceiling tSpan%binS;  
	st+binS*til numBins}  

q)getBins[2019.05.08D12:00:00.000000000;2019.05.08D12:10:00.000000000;60]
2019.05.08D12:00:00.000000000 
2019.05.08D12:01:00.000000000 
2019.05.08D12:02:00.000000000 
2019.05.08D12:03:00.000000000
...

q)bins:getBins[2019.05.08D12:00:00.000000000;2019.05.08D12:10:00.000000000;60]
q)tab:(([]sym:(),`ETH_USD) cross ([]time:bins))
q)tab
sym     time
-------------------------------------
ETH_USD 2019.05.08D12:00:00.000000000
ETH_USD 2019.05.08D12:01:00.000000000
ETH_USD 2019.05.08D12:02:00.000000000
...
q)aj[`sym`time;tab;select from trade where date=2019.05.08]
sym     time                          date       exch     side ts         tp
---------------------------------------------------------------------------------
ETH_USD 2019.05.08D12:00:00.000000000 2019.05.08 HITBTC   sell 21.2405    171.238
ETH_USD 2019.05.08D12:01:00.000000000 2019.05.08 KRAKEN   buy  4.969261   168.83
ETH_USD 2019.05.08D12:02:00.000000000 2019.05.08 BITFINEX sell 1.199      177.68
ETH_USD 2019.05.08D12:03:00.000000000 2019.05.08 HITBTC   buy  0.0039     171.5
...
```
### Using bin to return stats  
You can use bin to returned binned stats. Bin uses binary search.
```q
q)select sym,date,last exch,last tp,last ts by sym,date,bins bins bin time from trade where date=2019.05.08,time within (first bins;last bins),sym=`ETH_USD
sym     date       time                         | exch     tp      ts
------------------------------------------------| ---------------------------
ETH_USD 2019.05.08 2019.05.08D12:00:00.000000000| KRAKEN   168.83  4.969261
ETH_USD 2019.05.08 2019.05.08D12:01:00.000000000| BITFINEX 177.68  1.199
ETH_USD 2019.05.08 2019.05.08D12:02:00.000000000| HITBTC   171.5   0.0039
ETH_USD 2019.05.08 2019.05.08D12:03:00.000000000| HITBTC   171.589 0.0229
...
q)select sym,date,last exch,avgPr:avg tp,vwap:wavg[ts;tp],vol:sum ts by sym,date,bins bins bin time from trade where date=2019.05.08,time within (first bins;last bins),sym=`ETH_USD
sym     date       time                         | exch     avgPr    vwap     vol
------------------------------------------------| -----------------------------------
ETH_USD 2019.05.08 2019.05.08D12:00:00.000000000| KRAKEN   172.5252 170.6567 179.1426
ETH_USD 2019.05.08 2019.05.08D12:01:00.000000000| BITFINEX 172.6061 171.0637 50.10987
ETH_USD 2019.05.08 2019.05.08D12:02:00.000000000| HITBTC   171.8744 172.4022 95.00255
...
/fucntional execution
?[trade;((=;`date;2019.05.08);(within;`time;(first;last)@\:bins);(=;`sym;enlist `ETH_USD));`sym`time!(`sym;(`bins;(bin;`bins;`time)));5#tradeFuncs]
sym     time                         | lowPr  highPr   tcnt avgPr    vwap
-------------------------------------| --------------------------------------
ETH_USD 2019.05.08D12:00:00.000000000| 168.75 177.65   27   172.5252 170.6567
ETH_USD 2019.05.08D12:01:00.000000000| 168.76 177.68   25   172.6061 171.0637
ETH_USD 2019.05.08D12:02:00.000000000| 168.85 177.7915 45   171.8744 172.4022
...
```
  
 ## fby
Another useful tool  used when completing analysis is the fby.
 ```q
 q)select from trade where date=2019.05.08,(`hh$time) within (12;13),sym=`ETH_USD,tp=(min;tp) fby sym
date       sym     time                          exch   side ts       tp
----------------------------------------------------------------------------
2019.05.08 ETH_USD 2019.05.08D13:19:27.741667000 KRAKEN sell 6.794449 167.77
2019.05.08 ETH_USD 2019.05.08D13:19:27.742228000 KRAKEN sell 41.16946 167.77
2019.05.08 ETH_USD 2019.05.08D13:19:43.173131000 KRAKEN sell 22       167.77

q)select vol:sum ts,first tp by sym,exch from trade where date=2019.05.08,(`hh$time) within (12;13),sym=`ETH_USD,tp=(min;tp) fby ([] sym;exch)
sym     exch    | vol      tp
----------------| ----------------
ETH_USD BITFINEX| 210.7004 176.3
ETH_USD COINBASE| 2.029625 167.87
ETH_USD HITBTC  | 9.1408   170.192
ETH_USD KRAKEN  | 69.96391 167.77
 ```

# Technical Analysis
Trend/technical traders use a combination of patterns and indicators from price charts to help them make financial decisions. Technical traders analyze price charts to develop theories about what direction the market is likely to move.

## Pattern Recognition 
 A common chart used in trying to identify patterns in, say , open/high/low/close the Candlestick as illustrated below. 
![Kraken Candle][krakenCandleStick]

Each candle shows the high/open/close/low and if closed higher than the open. This can be useful in predicting short term price movements.
## SMA-Simple Moving Averages- comparing different ranges 
The price of a security can be extremely volatile and large price movements can make it hard to pinpoint the general trend. Moving averages "smooth" price data by creating a single flowing line. The line represents the average price over a period of time. Which moving average the trader decides to use is determined by the time frame in which he or she trades. 

There are two commonly used moving averages: Simple Moving Average(SMA) and Exponential Moving Average(EMA). EMA gives a larger weighting to more recent prices when calculation the average. Below You can see the 5-Day moving average,10-Day moving average along with the close price.

Traders analyze where the current trade price lies in relation to the moving averages. If the current trade price is  above the MA(moving average) line this would indicate over bought(decline expected), trade price below MA would indicate over sold(increase may be seen).

It should be noted that a signal/trend indicator would not determine a trading strategy but would be analysed in conjustion with other factors. 

The graph below was used using Kx Analyst. A sample for this code can be seen below. I wont be showing all graphing code but all Analyst code can be found **here**.
```q
sma:{[x]
    .qp.go[700;300]
        .qp.title["SMA BTC Kraken"]
        .qp.theme[.gg.theme.clean]
            .qp.stack(
                .qp.line[x; `date; `sma10]
                    .qp.s.geom[enlist[`fill]!enlist .gg.colour.Blue]
                    ,.qp.s.scale [`y; .gg.scale.limits[6000 0N] .gg.scale.linear]
                    ,.qp.s.legend[""; `sma10`sma20`close!(.gg.colour.Blue;.gg.colour.Red;.gg.colour.Green)]
                    , .qp.s.labels[`x`y!("Date";"Price")];
                .qp.line[x; `date; `sma20]
                    .qp.s.geom[enlist[`fill]!enlist .gg.colour.Red]
                    ,.qp.s.scale [`y; .gg.scale.limits[6000 0N] .gg.scale.linear]
                    , .qp.s.labels[`x`y!("Date";"Price")];
                .qp.line[x; `date; `close]
                    .qp.s.geom[enlist[`fill]!enlist .gg.colour.Green]
                    ,.qp.s.scale [`y; .gg.scale.limits[6000 0N] .gg.scale.linear]
                    , .qp.s.labels[`x`y!("Date";"Price")])}
  
  sma[update sma10:mavg[10;close],sma20:mavg[20;close] from select from wpData where sym=`BTC_USD,exch=`KRAKEN]
```
![Kraken sma BTC][sma]
## MACD - Moving Average Convergence Divergence  
Moving Average Convergence Divergence(MACD) is an important and popular analysis tool. It is a trend indicator that shows the relationship between two moving averages of a securities price. MACD is calculated by subtracting the long term EMA(26 periods) from the short term EMA(12 periods).  EMAs place greater weight and significance on the more recent data points and reacts more significantly to price movements than SMA. The 9-day moving average of the MACD  is also calculated and plotted. This line is known as the signal line and can used to identify buy and sell signals.  
The code for calculating the MACD is very simple an leverages kdb/q's built in function of ema.
```q
/tab-table input
/id-ID you want `ETH_USD/BTC_USD
/ex-exchange you want
/output is a table with the close,ema12,ema26,macd,signal line calculated
macd:{[tab;id;ex]
        macd:{[x] ema[2%13;x]-ema[2%27;x]}; /macd line 
        signal:{ema[2%10;x]}; /signal line
        res:select sym,date,exch,close,ema12:ema[2%13;close],ema26:ema[2%27;close],macd:macd[close] from tab where sym=id,exch=ex;
        update signal:signal[macd] from res
        }
``` 
Below is a graph of the MACD for ETH_USD on HITBTC. 
![MACD ETH HITBT][macd]

From the above graph, you can see how the close price interacts with the short and long EMA and how this then impacts the MACD and signal line relationship. There is a buy signal when the MACD line crosses over the signal line and there is a short signal when the MACD line cross below the signal line.  
## RSI - Relative Strenght Index  
![RSI ETH HITBTC][rsi]

RSI(Relative Strength Index) is a momentum oscillator that measures the speed and change of price movements. It oscillates between 0-100. It is said that security is overbought when above 70 and oversold when below 30. It is a general trend and momentum indicator. The default period is 14 days, the lower the value the more sensitive it is to price changes. Short term traders sometimes look at 2 period RSI to look for overbought readings above 80 and over sold ratings below 20.  

The calculation For RSI is as follows:
$$ RSI=100 - \frac{100}{1+RS}$$
$$ RS=\frac{Average Gain}{Avergae Loss}$$

The first calculation of the average gain/loss are simple 14 day averages.

 - First Average Gain=Sum of Gains over the past 14 days/14
 - First Average Loss=Sum of losses over the past 14 days/14

The subsequent calculations are based on the prior averages and the current gain/loss :
 $$ AvgGain=\frac{(prev Avg Gain)*13 + current Gain}{14}$$
 $$ AvgLoss=\frac{(prev Avg Loss)*13 + current Loss}{14}$$

Below is the code used for calculating the RSI. It consists of two functions rsiMian and rsFunc. rsFunc is a helper function that calculates the relative strength at each point it  is also used in the next calculation for Money Flow Index.
```q
//Relative strentgh index- RSI
//close-close price
/n-number of periods
rsFunc:{[num;y]
	begin:num#0Nf; 
	start:avg((num+1)#y);
	begin,start,{(y+x*(z-1))%z}\[start;(num+1)_y;num]}

rsiMain:{[close;n]
	diff:-[close;prev close];
	rs:rsiFunc[n;diff*diff>0]%rsiFunc[n;abs diff*diff<0];
	rsi:100*rs%(1+rs);
	rsi}
```
It is useful to use both  RSI and MACD together as both  measure momentum in a market, but, because they measure different factors, they sometimes give contrary indications. This may help you identify the current trend of the market. 

## MFI - Money Flow Index  
![RSI ETH HITBTC][mfi]
MFI(Money Flow Index) is a technical oscillator that is similar to RSI but instead uses price and volume for identifying overbought and oversold conditions. This indicator weighs in volume to give it relative score, low volume high price movement will less impact the score compared to a high volume move. It may sometimes be used to spot divergences that warn of a trend change in price. MFI is known as the volume-weighted RSI.  We leverage the same rsFunc used in the RSI calculation below.
```q
mfiMain:{[h;l;c;n;v]
		TP:avg(h;l;c); /typical price
		rmf:TP*v; /real money flow
		diff:deltas[0n;TP]; /diffs
		mf:rsFunc[n;rmf*diff*diff>0]%rsFunc[n;abs rmf*diff*diff<0]; /money flow leveraging func for rsi.
		mfi:100*mf%(1+mf); /money flow as a percentage
		mfi}
```
 Below is the comparison between MFI graph and the RSI graph:
 ![MFI vs RSI][rsiVsMfi]

It can useful to use both together to make sure there is volume behind the price move and not just a price jump.
## CCI - Commodity channel index  
The Commodity Channel Index (CCI) is another tool used by technical-analysts. Its primary use is for spotting new trends. It measures the current price level relative to an average price level over time . The CCI can be used for any market and is not just for commodities.  It can be used to help identify if a security is approaching overbought and oversold levels. Its primary use is for spotting new trends. This can help traders make decisions on trades whether to add to position,exit position or take no part.

When CCI is positive it indicates it is above historical average and when it is negative it indicates it is below historical average. Moving from negative ratings to high positive ratings can be used as signal for a possible uptrend. Similarly the reverse will signal downtrends. CCI has no upper or lower bound so finding out what typical overbought and oversold levels should be determined on each asset individually looking at its historical CCI levels.

CCI calculation:
$$CCI= \frac{Typical Price- Moving Average}{.015 * Mean Deviation}$$
$$Typical Price= \frac {high+low+close}{3} $$

In order to calculate the Mean Deviation it was necessary to create a helper function called madFunc(moving average Deviation)
```q
madFunc:{[tp;ma;n] 
		((n-1)#0Nf),{[x;y;z;num] reciprocal[num]*sum abs z _y#x}'[(n-1)_tp-/:ma;n+l;l:til -[count tp;n-1];n]}
```

This was calculated by subtracting the Moving Average from the Typical Price for the last n periods, summing the absolute values of these figures and then dividing by n periods.

```q
CCI:{[high;low;close;ndays]
	TP:avg(high;low;close);
	sma:mavg[ndays;TP];
	mad:madFunc[TP;sma;n];
    reciprocal[0.015*mad]*TP-sma  
    }
```
![CCI Graph][cci]

## Bollinger Bands 
![Bollingard bands][bollingard] 
Bollinger Bands are used in technical analysis that can be used for pattern recognition. They are formed by plotting two lines that are  two standard deviations from the simple moving average price, (one in the negative direction and one positive). Standard deviation is a measure of volatility in an asset, so when the market becomes more volatile the bands widen. Similarly, less volatility leads to the bands contracting. If the prices move towards the upper band the security is seen to be overbought and as the prices get close to the lower bound the security is considered oversold. Provides traders with information regarding price volatility. 90% of price action occurs between the bands. A breakout from this would be seen as a major event. The breakout is not consider a trading signal. Breakouts provide no clue as to the direction and extent of future price movements.
```q
/tab-input table
/n-number of days
/ex-exchange
/id-id to run for 
bollB:{[tab;n;ex;id]
	tab:select from wpData where sym=id,exch=ex;
	tab:update sma:mavg[n;TP],sd:mdev[n;TP] from update TP:avg(high;low;close) from tab;
	select date,sd,TP,sma,up:sma+2*sd,down:sma-2*sd from tab}
/Execute
bollB[wpData;20;`KRAKEN;`BTC_USD]	
```
## Force Index  
The Force Index is a technical indicator that measures the amount of power behind a price move. It uses price and volume to assess the force behind a move or a possible turning point. The technical indicator is an unbounded oscillator that oscillates between a negative and positive values.  There are three essential elements to stock price movement-direction, extent and volume. The Force Index combines all three in this oscillator.
![Force Index Graph][forceIndex]

The above graph is the 13-day EMA of the Force Index. It can be seen that the Force Index crosses the centre line the price begins to increase. This would seem to indicate the bullish trading  is exerting a greater force. This changes towards the end July where there is a significant change from a high positive force index to a negative one and the price drops dramatically. It suggested the emergence of a bear market.
 
 The Force Index calculation subtracts today's close from the prior day's close and multiplies it by the daily volume. The next step is to calculate the 13 day EMA of this value. The code used is shown below:
 
```q
 //Force Index Indicator
/c-close
/v-volume
/n-num of periods
//ForceIndex1 is the force index for one period
forceIndex:{[c;v;n]
		forceIndex1:1_deltas[0nf;c]*v;
		n#0nf,(n-1)_ema[2%1+n;forceIndex1]}
```

## EMV - Ease of Movement Value  

Ease of Movement Value(EMV) is another technical indicator that combines momentum and volume information into one value. The idea is to use this value to decide if the prices are able to rise or fall with little resistance in directional movement. 
$$Distance Moved= \frac{High + Low}{2}- \frac{Prior High + Prior Low}{2}$$
$$Box Ratio= \frac{\frac{Volume}{scaleFactor}}{High- Low}$$
$$ EMV= \frac{Distance moved}{Box Ratio}$$
14 period EMV= 14 day simple average of EMV

Scale factor is chosen to produce a normal number. This is generally relative to to the volume of shares traded.
 
```q
//Eae of movement value -EMV
/h-high
/l-low
/v-volume
/s-scale
/n-num of periods
emv:{[h;l;v;s;n]
		boxRatio:reciprocal[-[h;l]]*v%s;
		distMoved:deltas[0n;avg(h;l)];
		(n#0nf),n _mavg[n;distMoved%boxRatio]
		}
```
![emv][emv]
## ROC - Rate of Change
  The Rate of Change (ROC) indicator measures the percentage change in the close price over a specific period of time. 
  $$ROC = \frac{Close - Close n days ago}{Close n days ago} *100$$
Code snippet below shows how easy this can be constructed:
```q
//Price Rate of change Inicator (ROC)
/c-close
/n-number of days prior to compare
roc:{[c;n]
		curP:_[n;c];
		prevP:_[neg n;c];
		(n#0nf),100*reciprocal[prevP]*curP-prevP
		}
```
A positive move in the ROC indicates that there was a sharp price advance. A downward drop indicates steep decline in the price. This oscillator is prone to whipsaw around the zero line as can be seen in the graph. For the graph  below n=9 is used, which is commonly used by short term traders. 
![roc][roc]

## Stochastic Oscillator  
![stochastic][stochastic]
The stochastic Oscillator is a momentum indicator comparing a particular closing price of a security to a range of its prices over a certain periods of time. You can adjust the sensitivity of the indicator by adjusting the time period and by taking the moving average of the result. The indicator has a 0-100 range that can be used to indicate overbought and oversold signals.   A security is considered over overbought when greater than 80 and oversold when less than 20. For this case n will be 14. It is calculated using the following :
$$ \%K = \frac{C-L(n)}{H(n)-L(n)} $$  
where C=Current Close,
L(n)=Low across last n days,
H(n)=High over the last n days.
%K= slow stochastic indicator
%D= fast stochastic indicator which is the n day moving average of %K (generally n=3)

```q
//null out first 13days if 14 days moving avg
//Stochastic Oscillator
/h-high
/l-low
/n-num of periods
/c-close price
/o-open
stoOscCalc:{[c;h;l;n]
		lows:mmin[n;l];
		highs:mma[n;h];
		(a#0n),(a:n-1)_100*reciprocal[highs-lows]*c-lows
		}
/k-smoothing for %D
/for fast stochastic oscillation smoothing is set to one k=1/slow k=3 default
/d-smoothing for %D -  this generally set for 3
/general set up n=14,k=1(fast),slow(slow),d=3

stoOcsK:{[c;h;l;n;k]
		(a#0nf),(a:n+k-2)_mavg[k;stoOscCalc[c;h;l;n]]
		}

stoOscD:{[c;h;l;n;k]
		(a#0n),(a:n+k+d-3)_mavg[d;stoOscK[c;h;l;n;k]]
		}

```
## Aroon Oscillator
Aroon Indicator is a technical indicator which is used to identify trend changes in the price of a security and the strength of that trend which is used in the Aroon oscillator . An Aroon Indicator has two parts: aroonUp and aroonDown which measure the time between highs and lows respectively over a period a time n (generally n=25). The objective of the indicator is that strong uptrends will regularly see new highs and strong downtrends will regularly see new lows. The range of the indicator is between 0-100.
$$ aroonUp=\frac{n-periodsSinceNPeriodHigh}{n}*100$$
 $$ aroonDown=\frac{n-periodsSinceNPeriodLow}{n}*100$$
![aroon][aroon]
```q
//Aroon indicator
aroonFunc:{[c;n;f] 
		m:reverse each a _'(n+1+a:til count[c]-n)#\:c;
		#[n;0ni],{x? y x}'[m;f]}

aroon:{[c;n;f] 
	100*reciprocal[n]*n-aroonFunc[c;n;f]}
//aroon[tab`high;25;max]-- aroon up
``` 
 Aroon Oscillator subtracts aroonUp from aroonDown making the range of this Oscillator between -100 and 100. 
$$ aroonOsc= aroonUp - aroonDown $$
The oscillator moves above the zero line when aroonUp moves above the aroonDown. The oscillator drops below zero line when the aroonDown moves above the aroonDown.
 
# Conclusion  
This paper outlines how useful trade functions can be created quite simply using built in q functions. This shows how q/kdb+ can be used for trade analytics.This ranges from simple trade stats to more complex trend indicators and oscillator.
# Notes  
Ask price-(ap) is the price sellers are willing to sell at so if you want to buy on the market you will get the current ap. Bid price -(bp) is the price buyers are willing to buy at, so if you have your security and want to sell it you will get the current bp. In a normal market the ap>bp and the difference between the two is called the bid ask spread. Sometimes this is not the case and we enter a locked(ap=bp) or crossed(ap<bp) market.

### The Difference Between the Commodity Channel Index (CCI) and the Stochastic Oscillator

Both of these technical indicators are oscillators, but they are calculated quite differently. One of the main differences is that the  [Stochastic Oscillator](https://www.investopedia.com/terms/s/stochasticoscillator.asp)  is bound between zero and 100, while the CCI is unbounded. Due to the calculation differences, they will provide different signals at different times, such as overbought and oversold readings.
image urls
### The Difference Between the Force Index and the Money Flow Index (MFI)

The  [money flow index](https://www.investopedia.com/terms/m/mfi.asp)  (MFI), like the force index, uses price and volume to help assess the strength of a trend and spot potential price reversals. The calculations of the indicators are quite different, though, with MFI using a more complex formula which includes the typical price (high + low + close / 3) instead of just using closing prices. The MFI is also bound between zero and 100. Because the MFI is bound and uses a different calculation, it will provide different information than the force index.


[sma]:https://drive.google.com/uc?id=1ycwHipo2eg93VBbWdsUexe9FSGbfXf5d
[krakenCandleStick]: https://drive.google.com/uc?id=1BQjcd4ijPdsQ7NuRkt1d22JPcYhAoG42
[macd]: https://drive.google.com/uc?id=1yIrvFgyxjBZYDaYgL7GHg8afLMsCpS7j
[rsi]: https://drive.google.com/uc?id=1UPT2PWI8No2XtJXlm74ma9wIEtii5z0-
[mfi]: https://drive.google.com/uc?id=1EwReDlRvdY6u0ytIE1mSZ-qAm7bQ5tve
[rsiVsMfi]: https://drive.google.com/uc?id=1x9HHmpJFq7NV11wZQCL1HHmm7OrGo3NT
[emv]: https://drive.google.com/uc?id=1CId2y1cK-KlqvT7jsbOsrDA_tm-9jxUy
[bollingard]: https://drive.google.com/uc?id=1KqQ_XYKVCBWw4gk41T3kNWr6yEPnkZZp
[forceIndex]: https://drive.google.com/uc?id=1PFKDwSoYC2wQTYIpxNCzJH_b9kI3A0z1
[roc]: https://drive.google.com/uc?id=1byQUh6T0OFrzFtX1r5OLFn0j7pQYnBdj
[stochastic]: https://drive.google.com/uc?id=1uTEQtKAu_wljnAswYXGQOVR_s_FxhSTW
[cci]: https://drive.google.com/uc?id=1_9GoEFLLzGo3zHFqRSNczVN8S5ReqJAy
[aroon]:https://drive.google.com/uc?id=1B6XRtmXJwwt-eEMYDNP8k11yQltm7szs


> Written with [StackEdit](https://stackedit.io/).
