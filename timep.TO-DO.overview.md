high-level overview:

#####################################################################################

subshells + bg forks:

1. normal commands and simple forks of builtins will have their log line written the next time a debug trap fires at that nesting level. if there are subshells / bg forks (that dont fire a debug trap at that nesting lvl) first then they will write a file under .endtime which , if it exists, will be read and the min end time chosen for the command's ending timestamp
2. the exit trap is set to `:` to ensure the final command in a subshell gets 1 debug trap firing after said command to log it (see code below)
3. when entering a subshell or spawning a bg fork, the child process will append the endtime timestamp  to the previous command's .endtime file, then write a line in the parent's log indicating that at `timep_NEXEC_STR` a subshell/ bg fork / ambiguous (if it detects bg fork and `BASH_SUBSHELL` increases by 2+) was spawned with pid `${timep_NPIDWRAP}.${BASHPID}`. the start time for this line will be the "end time" recorded at the start of the current debug trap fire (which is the endtime for the command before the subshell / bg fork) + 0.000001 s, and its end time will be blank (to be filled in in post-processing as the endtime of the last command in the child + 0.000001 s). then re-set the exit trap, if its a bg fork increment timep_NBG, increment+nest  NEXEC and related variables. if bash_subshell increases by 2+, either read the pid chain from the .pidchain file or figure it out (using /proc) and then write it to the .pidchain file. finally write log header for new (currently empty) log at new nesting depth. then the 1st command is run, and the next debug trap logs  it as a normal command (or whatever it is)
4. anytime `$!` is detected as changing, write `$!` to the bg-pid.log file. this file will be utalized in post-processing to resolve ambiguous subshells/bg_forks
5. everything is keyed on `${timep_NEXEC_STR}_${timep_NPIDWRAP}.${BASHPID}`. `timep_NPIDWRAP` increments whenever a subshell/bg fork has a pid lower than the previous nesting lvl pid

note: `timep_NPIDWRAP` is initialized to 0; then in the debug trap, add `(( BASHPID < timep_BASHPID_prev )) && ((timep_NPIDWRAP++))`

endtime read code:

```
if [[ -s "${timep_TMPDIR}/.endtimes/${timep_NEXEC_STR}_${timep_NPIDWRAP}.${BASHPID}" ]]; then
    {
        while read -r -u $fd_endtime timep_ENDTIME0; do
            (( ${timep_ENDTIME0//./} < $[timep_ENDTIME//./} )) && timep_ENDTIME="${timep_ENDTIME0}"
        done
    } {fd_endtime}<"${timep_TMPDIR}/.endtimes/${timep_NEXEC_STR}_${timep_NPIDWRAP}.${BASHPID}"
fi
```

#####################################################################################

functions:

1. the initial debug trap that fires in the parent will log the previous (before the function) command and record the function invocation (to be logged later in the parent's log)
2. the next debug trap that fires (BASH_COMMAND is the func name, but we are now in the child) can detect that we just entered a function since `${#FUNCNAME[@]}` increases. this debug trap will increase nesting depth in all the needed variables but wont generate a log line
3. next the function runs, and the commands are processed/logged the same as they would be outside a function
4. on function exit, the return trap will first set the flag variable that disables the debug trap (when will generate 1 debug trap firing before the debug trap is disabled....this initial fire will log the last command from the function). the return trap will then (with the debug trap disabled) write the endtime from the final function command to the .endtime file 1 nesting level up (corresponding to the "saved in the timep_* variables but not yet logged" function call log line in the parent). it will then remove 1 nesting level off the end of all the nesting/funcdepth variables. finally, it will unset the variable that disables the debug trap (which wont make the debug trap fire, but will make it fire for the next command run)
5. the next command (after the function returns) at the parent's nesting level will pickup the correct endtime from the file written during the return trap, then log the line for the function call at the parent's nesting level

#####################################################################################

NOTE: differences in subshell vs function logging.

say you have a sequence of command A, subshell/function B, command C, command D. Within subshell/function B you have commands B1, B2, ..., BN

subshell: you get debug traps just before A, B1, B2, ..., BN, <exit_trap>, C, D

The debug trap for B1 adds the endtime for A in its .endtime file and writes the log line for subshell B in the parent (without a endtime specified), and nests all required variables 1 level deper. Then B2's debug trap logs B1. ... . The debug trap fire for the exit trap logs BN. And the debug trap fire for C reads in the endtime for A (which, from its view, is the previous command) choosing the lowest endtime if multiple endtimes are present and logs A. THE LOG FOR A WILL BE WRITTEN OUT OF ORDER...This will be fixed in post processing. Finally the debug trap for D logs C.

if C is a subshell too, then from its point of view A is still the previous command. So it appends another endtime for A in A's .endtime file (that wont be used since it wont be the minimum endtime). then the rest of the subshell proceeds as before. then D reads in the endtime for A (which, from its view, is the previous command) choosing the lowest endtime out of the multiple endtimes that are present, and logs A

function: you get debug traps A, B, B0, B1, B2, ..., BN, <return_trap>, C, D

note: B and B0 both list the function name as the BASH_COMMAND. B is run in the parent, B0 is run in the child.

The debug trap for B logs A. The debug trap for B0 nests all required variables 1 level deeper, but does not write any log lines. The debug trap for B1 logs B0, then B2's debug trap logs B1. ... . The debug trap fire for the return trap logs BN and then reduces nesting level in all required variables by 1. And the debug trap fire for C logs B (the "function indicator line" in the parent). Finally the debug trap for D logs C.

In both cases the last thing that fires a debug trap before the subshell/function is logged by the next debug trap (at the parent scope) after the subshell/function, with endtime preserved via the .endtime file (when needed). this ensures that each command and each indicator line in the parent is logged exactly once with the correct start and end times. the downside is that the last connand before a subshell is logged out of order, but this is easily fixed in post-processing.

#####################################################################################

post processing:

The following tasks will need to be done in the order shown. re-order, then merge pipelines, then merge upwards (with+without collapsing loops)

reorder:

due to a quirk with this logging method, subshells and bg forks will have their indicator line in the parent logged before the command immediately prooceeding the (group of back-to-back) subshell / bg fork commands. the 1st post-processing step will be to reorder the logs by version-sorting each of them (independently) based on their `${timep_NEXEC_STR}_${timep_NPIDWRAP}.${BASHPID}`

pipelines: 

take each log, version-sort them based on `${timep_NEXEC_STR}_${timep_NPIDWRAP}.${BASHPID}`, then read the lines in reverse order. the NPIPE on each log line represents the number of previous commands (including that one)  form the pipeline (if NPIPE=1 then it is only that command and as such isnt a pipeline). reading lines in reverse order means that if NPIPE=N it'll be that command + the next N-1 command. any pipeline elements containing brace groups with many commands will have that brace group logged as a single `<< subshell >>` command at that nesting lvl. i.e., each pipeline element always gets a single log line at the current nesting lvl.

Edge case: when a pipeline’s last element is a brace group ({ …; }), Bash actually spawns a subshell behind the scenes if you use lastpipe or shopt -s lastpipe. If you’re not relying on that feature, you’re safe; but if you do support lastpipe, you may see a pipeline whose final element is run in the parent rather than a subshell. In that case NPIPE can still be >1, but you’ll only see a single DEBUG for the brace‐group. You can detect it by checking for an << subshell >> at the end and lastpipe being set, and then treat it as “one pipeline element that happens in‐place.”
NOTE: i may need to consider a special case where lastpipe is set and the last pipeline element is a curly brace group....this is the only time where 1 line per pipeline element might not be true. ill need to check that one.

merging upward, summing runtime and collapsing loops - these will all sort of happen together. starting with the most deeply nested logs, i will:

1. set the "end time" of the subshell / bg fork marker (in the parent) as the endtime of the final command in the child log + 0.000001 s
2. compute the runtime of each command from the start/end timestamps and sum to compute the total runtime from all commands at that nesting level
3. look for repeated commands / loops and collapse them into a counter + total runtime. ill probably generate 2 "final output" logs - one with loops collapsed (that will be printed to the screen) and one without loops collapsed (in a file, in case deeper analysis is needed). See "**collapsing loops" section below for implementation details.
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

**collapsing loops (logic from previous implementation):

1. pull out the LINENO and BASH_COMMAND from each log line and run this combination through sort -u to get unique lineno+command combinations
2. loop through each unique lineno+command combination. for each unique combination, grep the log to find lines with both that lineno and that command. get a count of the number of grep matches, and pull the runtime out of each match and sum. then remove all but the 1st match from the log, and for that 1st match add the counter and  replace the runtime with the summed runtime.
