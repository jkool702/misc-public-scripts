high-level overview:

subshells + bg forks:

1. normal commands and simple forks of builtins will have their log line written the next time a debug trap fires at that nesting level. if there are subshells / bg forks (that dont fire a debug trap at that nesting lvl) first then they will write a file under .endtime which , if it exists, will be read and the min end time chosen for the command's ending timestamp
2. the exit trap is set to : to ensure the final command in a subshell gets 1 debug trap firing after said command to log it
3. when entering a subshell or spawning a bg fork, the child process will append the endtime timestamp (recorded at the start of the current debug trap fire) to the previous command's .endtime file, then write a line in the parent's log indicating that at timep_NEXEC_STR a subshell/ bg fork / ambiguous (if it detects bg fork and BASH_SUBSHELL increases by 2+) was spawned with pid ${timep_NPIDWRAP}.${BASHPID}. then reset the exit trap, if its a bg fork increment timep_NBG, increment+nest  NEXEC and related variables. if bash_subshell increases by 2+, either read the pid chain from the .pidchain file or figure it out (using /proc) and then write it to the .pidchain file. finally write log header for new (currently empty) log at new nesting depth. then the 1st command is run, and the next debug trap logs  it as a normal command (or whatever it is)
4. anytime $! is detected as changing, write $! to the bg-pid.log file. this file will be utalized in post-processing to resolve ambiguous subshells/bg_forks
5. everything is keyed on ${timep_NEXEC_STR}_${timep_NPIDWRAP}.${BASHPID}. timep_NPIDWRAP increments whenever a subshell/bg fork has a pid lower than the previous nesting lvl pid


functions:

1. the initial debug trap that fires in the parent will log the previous (before the function) command and record the function invocation (to be logged later in the parent's log)
2. the next debug trap that fires (BASH_COMMAND is the func name, but we are now in the child) can detect that we just entered a function since ${#FUNCNAME[@]} increases. this debug trap will increase nesting depth in all the needed variables but wont generate a log line
3. next the function runs, and the commands are processed/logged the same as they would be outside a function
4. on function exit, the return trap will first set the flag variable that disables the debug trap (when will generate 1 debug trap firing before the debug trap is disabled....this initial fire will log the last command from the function). the return trap will then (with the debug trap disabled) write the endtime from the final function command to the .endtime file 1 nesting level up (corresponding to the "saved in the timep_* variables but not yet logged" function call log line in the parent). it will then remove 1 nesting level off the end of all the nesting/funcdepth variables. finally, it will unset the variable that disables the debug trap (which wont make the debug trap fire, but will make it fire for the next command run)
5. the next command (after the function returns) at the parent's nesting level will pickup the correct endtime from the file written during the return trap, then log the line for the function call at the parent's nesting level


post processing:

pipelines: 

take each log, version-sort them based on timep_NEXEC_STR_timep_NPIDWRAP.BASHPID, then read the lines in reverse order. the NPIPE on each log line represents the number of previous commands (including that one)  form the pipeline (if NPIPE=1 then it is only that command and as such isnt a pipeline). reading lines in reverse order means that if NPIPE=N it'll be that command + the next N-1 command. any pipeline elements containing brace groups with many commands will have that brace group logged as a single << subshell >> command at that nesting lvl. i.e., each pipeline element always gets a single log line at the current nesting lvl.

Edge case: when a pipeline’s last element is a brace group ({ …; }), Bash actually spawns a subshell behind the scenes if you use lastpipe or shopt -s lastpipe. If you’re not relying on that feature, you’re safe; but if you do support lastpipe, you may see a pipeline whose final element is run in the parent rather than a subshell. In that case NPIPE can still be >1, but you’ll only see a single DEBUG for the brace‐group. You can detect it by checking for an << subshell >> at the end and lastpipe being set, and then treat it as “one pipeline element that happens in‐place.”
NOTE: i may need to consider a special case where lastpipe is set and the last pipeline element is a curly brace group....this is the only time where 1 line per pipeline element might not be true. ill need to check that one.

merging upward, summing runtime and collapsing loops - these will all sort of happen together. starting with the most deeply nested logs, i will:

1. compute the runtime of each command from the start/end timestamps
2. compute the total runtime from all commands at that nesting level
3. look for repeated commands / loops and collapse them into a counter + total runtime. ill probably generate 2 "final output" logs - one with loops collapsed (that will be printed to the screen) and one without loops collapsed (in a file, in csse deeper analysis is needed)
4. merge the log upward (unless it was the start oif a bg fork). still working out how exactly to do this, but considering leaving the original "marker line" in and then immediately below it insert the merged log with something like |--  prepended to the beginning of each line (unless the line already begins with "|-- ", then instead prepend "|   "
5. repeat the process at the next higher nesting level, but for any subshells/function calls that were merged up use the summed runtime from the merged log instead of end_timestamp - start_timestamp. keep repeating until you hit the top level log.

the resulting log might look a bit like

```
cmd 1
<<subshell 2>>
|-- cmd 2.1
|-- cmd 2.2
|-- <<subshell 2.3>>
|    |-- cmd 2.3.1
|    |-- cmd 2.3.2
|-- cmd 2.4
cmd 3
```

collapsing loops (logic from previous implementation):

1. pull out the LINENO and BASH_COMMAND from each log line and run this combination through sort -u to gert unique lineno+command combinations
2. loop through each unique lineno+command combination. for each unique combination, grep the log to find lines with both that lineno and that command. get a count of the number of grep matches, and pull the runtime out of each match and sum. then remove all but the 1st match from the log, and for that 1st match add the counter and  replace the runtime with the summed runtime.
