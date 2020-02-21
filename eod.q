//typical call
//q cryptoScripts/eod.q schemaLoc LogFileLoc date

//Th idea is to pass in a date.It will then replay the data using -11! then once in correct tables
// save down the data in its seperate tables for that date.

//At least this way can execute a for loop and run multiple EODS at nce without the need of an rdb calling the EOD. Think it is better. Discuss with Deaglan and John.The data is 24hr ticking.

//Actually maybe it is better just to get rdb to save down the data. Since the rd will already have figured out the split of the data. 
//Endofday would be called data would be saved. then the next days data would be in tplog so then when it executes .u.rep the data would then be loaded in.

// rdb.q will be fairly simple 

//Load in Schemas
\l schema.q

// find locartion of log file 

// replay the log file 

//create the upd func to split it into multiple tables
//each exchange wil have its own tables(trade and quote)

//Going to partition it by date
