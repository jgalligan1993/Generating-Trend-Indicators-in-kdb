/q tick/r.q [host]:port[:usr:pwd] [host]:port[:usr:pwd]
/2008.09.09 .k ->.q

if[not "w"=first string .z.o;system "sleep 1"];

upd:insert;

/ get the ticker plant and history ports, defaults are 5010,5012
//.u.x:.z.x,(count .z.x)_(":5010";":5012");

/ end of day: save, clear, hdb reload
.u.end:{
	t:tables`.;
	t@:where `g=attr each t@\:`sym;
	.Q.hdpf[`$":",.u.x 1;`:.;x;`sym];
	@[;`sym;`g#] each t;};

/ init schema and sync up from log file;cd to hdb(so client save can run)
/ enlist the x as we're subbing to one table at a time
/.u.rep:{(.[;();:;].)each enlist x;if[null first y;:()];-11!y;system "cd ",1_-10_string first reverse y};

// added the if statement so that the rdb only replays the log in the last call of .u.rep -- i.e. when all the schemas have been initalised that we want
/.u.rep:{
/	(.[;();:;].)each enlist x;
/	if[all not null y;
/	    -11!y]}
/ HARDCODE \cd if other than logdir/db

/ connect to ticker plant for (schema;(logcount;log))
//.u.rep .(h:hopen `$":",.u.x 0)"(.u.sub[`trade;`];`)";
//.u.rep .(h)"(.u.sub[`quote;`];`.u `i`L)";
/.u.rep1 @(hopen `$":",.u.x 0)"(.u.sub[`quote;`])";

