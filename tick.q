/ q tick.q sym . -p 5001 </dev/null >foo 2>&1 &
//This tickerplant is a bit complicated.
//Essentially all we need it to do is save the data to a logFile Which will be later replayed by in the EOD process.
//

"kdb+tick 3.6"

/q tick.q SRC [DST] [-p 5010] [-o h]
//system"l tick/",(src:first .z.x,enlist"sym"),".q"
src:first .z.x,enlist"sym"
//loading in schemas
\l cryptoScripts/schema2.q
if[not system"p";system"p 5010"]



\l cryptoScripts/tick/u.q
\d .u
ld:{
	if[not type key L::`$(-10_string L),string x;
		.[L;();:;()]];
	i::j::-11!(-2;L);
	if[0<=type i;
	    -2 (string L)," is a corrupt log. Truncate to length ",(string last i)," and restart";
	    exit 1];
	    hopen L};

tick:{
	init[];
	if[not min(`time`date`sym~3#key flip value@)each t;'`timesym];
	@[;`sym;`g#]each t;
	d::.z.d;
	if[l::count y;L::`$":",y,"/",x,10#".";l::ld d]};

endofday:{
	end d;
	d+:1;
	if[l;hclose l;l::0(`.u.ld;d)]
	};

ts:{
	if[d<x;
		if[d<x-1;system"t 0";'"more than one day?"];
		endofday[]]};

if[system"t";
	.z.ts:{
		pub'[t;value each t];
		@[`.;t;@[;`sym;`g#]0#];
		i::j;
		ts .z.d};

	upd:{[t;x]
 	// rather than looking for time, we're looking for a timestamp
		if[-12=type first first x;
			if[d<"d"$a:.z.p;
		 		.z.ts[]];
	 		a:"n"$a;
	 		x:$[0>type first x;
		 		a,x;
		 		(enlist(count first x)#a),x]];
		t insert x;
 		if[l;l enlist (`upd;t;x);j+:1];
 	};]

if[not system"t";system"t 1000";
	.z.ts:{ts .z.d};
 		//timer for logging
 		//need to add in memory information
		upd:{[t;x]ts"d"$a:.z.p;
 	
 	// rather than looking for time, we're looking for a timestamp
 	if[not -12=type first first x;a:"n"$a;x:$[0>type first x;a,x;(enlist(count first x)#a),x]];
	f:key flip value t;
	pub[t;$[0>type first x;enlist f!x;flip f!x]];
	if[l;l enlist (`upd;t;x);i+:1;cnt[t]+:1];}];

//sTime:`second$.z.p




// number of msgs
//lg.test:{{0N!string[.z.p]," Number of messages for table ",string[x]," is:",string cnt x}each t;
// Sub deta	ils
 
 //{0N!string[.z.p]," For table ",string[x]," there are ",string[count w x]," subscribers"}each t;}



\d .
.u.tick[src;.z.x 1];

// counter for each table 
.u.cnt:.u.t!count[.u.t]#0

\
 globals used
 .u.w - dictionary of tables->(handle;syms)
 .u.i - msg count in log file
 .u.j - total msg count (log file plus those held in buffer)
 .u.t - table names
 .u.L - tp log filename, e.g. `:./sym2008.09.11
 .u.l - handle to tp log file
 .u.d - date

/test
>q tick.q
>q tick/ssl.q

/run
>q tick.q sym  .  -p 5010	/tick
>q tick/r.q :5010 -p 5011	/rdb
>q sym            -p 5012	/hdb
>q tick/ssl.q sym :5010		/feed
