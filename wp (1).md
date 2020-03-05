

# Generating Statistics and Trend Indicators in kdb+  
  
## Introduction  
  
The compactness of kdb+ and the terseness of q means that the language is focused on high performing atomic capabilities  rather than wide range in-built functions. As a result users may sometimes develop libraries of often-used algorithms and  functions relevant to their specific domains for convenience and to support reuse. In this paper, we outline examples of  commonly used functions in finance that are built on native q functions.  
  
The code is developed on version 3.6 2019.03.07 of kdb+ . Cryptocurrency data for Bitcoin and Ethereum from multiple exchanges is used in the examples provided. Charts are displayed using Kx Analyst.  
  
This whitepaper has 3 main parts:  
  
1. Data Extraction  
2. Simple Statistics  
3. Trend Indicators  

## Data extraction  
  
Data was captured in a similar process to the one used in Eduard Silantyev's blog “Combining high-frequency cryptocurrency venue data using kdb+” . Trade and Quote tick data for Ethereum(ETH) and Bitcoin(BTC) denominated in the US dollar(USD) was collected from four exchanges:  
  
1. Bitfinex  
2. HitBtc  
3. Kraken  
4. Coinbase  
    
which span across May,June and July 2019. There is just over 2 months of data.  
  
A Python API was created which connected to a kdb+ tickerplant. The tickerplant processed the messages and sent them to RDB which was written down to a HDB at the end of the day. Such details will not be elaborated on as the main focus of this whitepaper is on Simple Statistics and Trend Indicators. Please view the following resources for help with tick capture:  
  
* [Kdb+tick profiling for throughput optimization](https://code.kx.com/v2/wp/tick-profiling/)  
* [Disaster-recovery planning for kdb+ tick systems](https://code.kx.com/v2/wp/disaster-recovery/)  
* [Query Routing: A kdb+ framework for a scalable, load balanced system](https://code.kx.com/v2/wp/query-routing/)  
  
# Technical Analysis
Trend/technical traders use a combination of patterns and indicators from price charts to help them make financial decisions. Technical traders analyse price charts to develop theories about what direction the market is likely to move.

## Pattern Recognition 
 A common chart used in trying to identify patterns in, say , open/high/low/close the Candlestick as illustrated below.
 ```q
 candlestick : {
    fillscale : .gg.scale.colour.cat 01b!(.gg.colour.Red; .gg.colour.Green);
    
    .qp.theme[enlist[`legend_use]!enlist 0b]
    .qp.stack (
        // open/close
       .qp.interval[x; `date; `open; `close]
            .qp.s.aes[`fill; `gain]
            , .qp.s.scale[`fill; fillscale]
            ,.qp.s.labels[`x`y!("Date";"Price")]
            , .qp.s.geom[`gap`colour!(0; .gg.colour.White)];
        // low/high
        .qp.segment[x; `date; `high; `date; `low]
            .qp.s.aes[`fill; `gain]
            , .qp.s.scale[`fill; fillscale]
            ,.qp.s.labels[`x`y!("Date";"Price")]
            , .qp.s.geom[enlist [`size]!enlist 1])
    };

.qp.go[700;300]
    .qp.theme[.gg.theme.clean]
    .qp.title["Candlestick chart BTC"]
    candlestick[update gain: close > open from select from wpData where sym=`BTC_USD,exch=`KRAKEN]
 ```

![Kraken Candle][krakenCandleStick]

Each candle shows the high/open/close/low and if closed higher than the open. This can be useful in predicting short term price movements.

## SMA-Simple Moving Averages- comparing different ranges 
The price of a security can be extremely volatile and large price movements can make it hard to pinpoint the general trend. Moving averages "smooth" price data by creating a single flowing line. The line represents the average price over a period of time. Which moving average the trader decides to use is determined by the time frame in which he or she trades. 

There are two commonly used moving averages: Simple Moving Average(SMA) and Exponential Moving Average(EMA). EMA gives a larger weighting to more recent prices when calculating the average. Below you can see the 5-Day moving average,10-Day moving average along with the close price.

Traders analyse where the current trade price lies in relation to the moving averages. If the current trade price is  above the MA (moving average) line this would indicate over-bought (decline in price expected), trade price below MA would indicate over-sold (increase in pricemay be seen).

It should be noted that a signal/trend indicator would not determine a trading strategy but would be analysed in conjunction with other factors. 

The graph below was used using Kx Analyst. A sample for this code can be seen below. All graphics of grammer code can be found in the git repository for this project. The following is a example:
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
Moving Average Convergence Divergence (MACD) is an important and popular analysis tool. It is a trend indicator that shows the relationship between two moving averages of a securities price. MACD is calculated by subtracting the long term EMA (26 periods) from the short term EMA (12 periods). In General period is class as a day but shorter/longer time spans can be used. Throughout this paper we will consider a period to be one day. EMAs place greater weight and significance on the more recent data points and react more significantly to price movements than SMA. The 9-day moving average of the MACD is also calculated and plotted. This line is known as the signal line and can be used to identify buy and sell signals.  
The code for calculating the MACD is very simple and leverages kdb/q's built in function of ema.
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

From the above graph, you can see how the close price interacts with the short and long EMA and how this then impacts the MACD and signal line relationship. There is a buy signal when the MACD line crosses over the signal line and there is a short signal when the MACD line crosses below the signal line.  

## RSI - Relative Strength Index  
![RSI ETH HITBTC][rsi]

Relative Strength Index (RSA) is a momentum oscillator that measures the speed and change of price movements. It oscillates between 0-100. It is said that security is overbought when above 70 and oversold when below 30. It is a general trend and momentum indicator. The default period is 14 days. This can be reduced or increased - the shorter the period the more sensitive it is to price changes. Short term traders sometimes look at 2 day RSIs to look for overbought readings above 80 and over sold ratings below 20.  

The calculation For RSI is as follows:
$$ RSI=100 - \frac{100}{1+RS}$$
$$ RS=\frac{Average Gain}{Avergae Loss}$$

The first calculation of the average gain/loss are simple 14 day averages.

 - First Average Gain=Sum of Gains over the past 14 days/14
 - First Average Loss=Sum of losses over the past 14 days/14

The subsequent calculations are based on the prior averages and the current gain/loss :
 $$ AvgGain=\frac{(prev Avg Gain)*13 + current Gain}{14}$$
 $$ AvgLoss=\frac{(prev Avg Loss)*13 + current Loss}{14}$$

Below is the code used for calculating the RSI. It consists of two functions rsiMain and relativeStrength. relativeStrength is a helper function that calculates the relative strength at each point.
```q
//Relative strentgh index- RSI
//close-close price
/n-number of periods
relativeStrength:{[num;y]
	begin:num#0Nf; 
	start:avg((num+1)#y);
	begin,start,{(y+x*(z-1))%z}\[start;(num+1)_y;num]}

rsiMain:{[close;n]
	diff:-[close;prev close];
	rs:relativeStrength[n;diff*diff>0]%relativeStrength[n;abs diff*diff<0];
	rsi:100*rs%(1+rs);
	rsi}
```
It is useful to use both  RSI and MACD together as both measure momentum in a market, but, because they measure different factors, they sometimes give contrary indications. Using both together can provide a clearer picture of the market. RSI could be showing a reading of greater than 70, this would indicate that the the security is overbought, but the MACD is signaling that the market is continuing in the upward direction. 

## MFI - Money Flow Index  

![RSI ETH HITBTC][mfi]

Money Flow Index (MFI) is a technical oscillator that is similar to RSI but instead uses price and volume for identifying overbought and oversold conditions. This indicator weighs in on volume and not just price to give it relative score. A low volume with a large price movement will have less impact on the relative score compared to a high volume move with a lower price move. You see new highs/lows,large price swings but is there any volume behind the move or is it just small trade. The market will generally correct itself. It can be used to spot divergences that warn traders of a change in trend. MFI is known as the volume-weighted RSI.  We leverage the relativeStrength function used in the RSI calculation below.
```q
mfiMain:{[h;l;c;n;v]
		TP:avg(h;l;c); /typical price
		rmf:TP*v; /real money flow
		diff:deltas[0n;TP]; /diffs
		mf:relativeStrength[n;rmf*diff*diff>0]%relativeStrength[n;abs rmf*diff*diff<0]; /money flow leveraging func for rsi.
		mfi:100*mf%(1+mf); /money flow as a percentage
		mfi}
```
 Below is the comparison between MFI graph and the RSI graph:

![MFI vs RSI][rsiVsMfi]

It can be useful to use both RSI and MFI together to make sure there is volume behind the price move and not just a price jump.
## CCI - Commodity channel index  
The Commodity Channel Index (CCI) is another tool used by technical analysts. Its primary use is for spotting new trends. It measures the current price level relative to an average price level over time. The CCI can be used for any market and is not just for commodities. It can be used to help identify if a security is approaching overbought and oversold levels. Its primary use is for spotting new trends. This can help traders make decisions on trades whether to add to position, exit position or take no part.

When CCI is positive it indicates it is above historical average and when it is negative it indicates it is below historical average. Moving from negative ratings to high positive ratings can be used as a signal for a possible uptrend. Similarly, the reverse will signal downtrends. CCI has no upper or lower bound so finding out what typical overbought and oversold levels should be determined on each asset individually looking at its historical CCI levels.

CCI calculation:
$$CCI= \frac{Typical Price- Moving Average}{.015 * Mean Deviation}$$
$$Typical Price= \frac {high+low+close}{3} $$

In order to calculate the Mean Deviation it was necessary to create a helper function called madFunc(moving average Deviation)
```q
maDev:{[tp;ma;n] 
		((n-1)#0Nf),{[x;y;z;num] reciprocal[num]*sum abs z _y#x}'[(n-1)_tp-/:ma;n+l;l:til -[count tp;n-1];n]}
```

This was calculated by subtracting the Moving Average from the Typical Price for the last n periods, summing the absolute values of these figures and then dividing by n periods.

```q
CCI:{[high;low;close;ndays]
	TP:avg(high;low;close);
	sma:mavg[ndays;TP];
	mad:maDev[TP;sma;n];
    reciprocal[0.015*mad]*TP-sma  
    }
```

![CCI Graph][cci]

## Bollinger Bands 

![Bollingard bands][bollingard] 

Bollinger Bands are used in technical analysis for pattern recognition. They are formed by plotting two lines that are two standard deviations from the simple moving average price, (one in the negative direction and one positive). Standard deviation is a measure of volatility in an asset, so when the market becomes more volatile the bands widen. Similarly, less volatility leads to the bands contracting. If the prices move towards the upper band the security is seen to be overbought and as the prices get close to the lower bound the security is considered oversold. This provides traders with information regarding price volatility. 90% of price action occurs between the bands. A breakout from this would be seen as a major event. The breakout is not considered a trading signal. Breakouts provide no clue as to the direction and extent of future price movements.
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
The Force Index is a technical indicator that measures the amount of power behind a price move. It uses price and volume to assess the force behind a move or a possible turning point. The technical indicator is an unbounded oscillator that oscillates between a negative and positive value.  There are three essential elements to stock price movement-direction, extent and volume. The Force Index combines all three in this oscillator.

![Force Index Graph][forceIndex]

The above graph is the 13-day EMA of the Force Index. It can be seen that the Force Index crosses the centre line the price begins to increase. This would indicate that bullish trading  is exerting a greater force. However, this changes towards the end of July where there is a significant change from a high positive force index to a negative one and the price drops dramatically. It suggests the emergence of a bear market.
 
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

The scale factor is chosen to produce a normal number. This is generally relative to the volume of shares traded.
 
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
A positive move in the ROC indicates that there was a sharp price advance.This can be seen on the graph between the 8th and 22nd of June. A downward drop indicates steep decline in the price. This oscillator is prone to whipsaw around the zero line as can be seen in the graph. For the graph  below n=9 is used, which is commonly used by short term traders. 

![roc][roc]

## Stochastic Oscillator 

![stochastic][stochastic]

The stochastic Oscillator is a momentum indicator comparing a particular closing price of a security to a range of its prices over a certain period of time. You can adjust the sensitivity of the indicator by adjusting the time period and by taking the moving average of the result. The indicator has a 0-100 range that can be used to indicate overbought and oversold signals. A security is considered over overbought when greater than 80 and oversold when less than 20. For this case n will be 14(14 days). It is calculated using the following :
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
### The Difference Between the Commodity Channel Index (CCI) and the Stochastic Oscillator
Both of these technical indicators are oscillators, but they are calculated quite differently. One of the main differences is that the  [Stochastic Oscillator](https://www.investopedia.com/terms/s/stochasticoscillator.asp)  is bound between zero and 100, while the CCI is unbounded. Due to the calculation differences, they will provide different signals at different times, such as overbought and oversold readings.

## Aroon Oscillator
Aroon Indicator is a technical indicator which is used to identify trend changes in the price of a security and the strength of that trend which is used in the Aroon oscillator . An Aroon Indicator has two parts: aroonUp and aroonDown which measure the time between highs and lows respectively over a period of time n (generally n=25days). The objective of the indicator is that strong uptrends will regularly see new highs and strong downtrends will regularly see new lows. The range of the indicator is between 0-100.
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
This paper outlines how trade functions can be created quite simply using built in q functions. This aper highlights how q/kdb+ can be used for trade analytics. The functions range from using different moving averages to more complex trend indicators and oscillator.
# Notes  
Ask price-(ap) is the price sellers are willing to sell at so if you want to buy on the market you will get the current ap. Bid price -(bp) is the price buyers are willing to buy at, so if you have your security and want to sell it you will get the current bp. In a normal market the ap>bp and the difference between the two is called the bid ask spread. Sometimes this is not the case and we enter a locked(ap=bp) or crossed(ap<bp) market.

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
