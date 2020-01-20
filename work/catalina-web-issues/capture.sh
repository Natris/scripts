eval GATHER="~/Documents/avast_capture"

echo "creating or recreating $GATHER directory"
rm -rf "$GATHER"
mkdir -p "$GATHER"


#sample function that runs sample in the background, killing the sampling process if it does not finish in time
sample() {
    i=$1
    target=$2
    #run sample command in the background
    ( sudo /usr/bin/sample $i 1 -f "$GATHER/$target.sample" ) & pid=$!
    #run process that kills the sampling process after timeout
    ( sleep 20 && echo "timed out; killing sample process"; sudo pkill -9 -P $pid; sudo kill -9 $pid ) 2>/dev/null & watcher=$!
    #wait for sample command to finish
    wait $pid 2>/dev/null
    sc_ec=$?
    if [ $sc_ec -eq 0 ] ; then
        echo "sampling succeeded"
        sudo pkill -HUP -P $watcher
        wait $watcher
        return 0
    elif [ $sc_ec -eq 137 ] ; then
        echo sampling stopped due to timeout
        return 1
    else
        echo "sampling interrupted due to $sc_ec"
        sudo pkill -HUP -P $watcher
        wait $watcher
        return 1
    fi
}

#sample apps which match $1, saving samples into $2_pid.sample.
sample_match() {
    echo "going through $1 apps, trying to sample them"
    ps -e | grep "$1"|grep -v grep
    for i in $(ps -e|grep "$1"|grep -v grep| awk '{print $1}'); do
        sample $i "$2_$i"
    done
}

#sample apps which match $1, saving samples into $2_pid.sample. Afterwards for thise which we have failed to sample, crash them to generate crash file
sample_and_crash() {
    echo "go through $1 apps again, killing processes whose sampling fails"
    for i in $(ps -e|grep "$1"|grep -v grep| awk '{print $1}'); do
        sample $i "$2_${i}_2"
        if [ $? -ne 0 ]; then
            echo "failed to sample $1 app $i; will try to crash it"
            sudo kill -SIGSEGV $i
        fi
    done
}


echo "and storing log of this script into it"
exec &> >(tee -a "$GATHER/gather.log")

date

echo "ensuring password is entered for other sudo commands; please enter your password"
sudo pwd

echo "copying fileshield logs"
cp /Library/Logs/Avast/fileshield.* "$GATHER"

echo "save list of currently running processes"
ps -e >"$GATHER/initial_ps_e"
ps aux >"$GATHER/initial_ps_aux"


echo "sampling Mail apps, crashing them if that fails"
sample_match "/Contents/MacOS/Mail" mail
sample_and_crash "/Contents/MacOS/Mail" mail2

echo "sampling Safari processes, crashing them if that fails"
#first the main safari process
sample_match "app/Contents/MacOS/Safari" safari_app
#afterwards the safari's helper processes
sample_match "/Contents/MacOS/com.apple.WebKit" safari_helper
#now we can afford to crash the processes...
sample_and_crash "/Contents/MacOS/com.apple.WebKit" safari_helper2
sample_and_crash "app/Contents/MacOS/Safari" safari_app2


echo "sampling Chrome processes"
sample_match "app/Contents/MacOS/Google Chrome [^H]" chrome_app
sample_match "Google Chrome Helper" chrome_helper


echo "going through all currently running processes and storing their sample to $GATHER directory"
ps -e >"$GATHER/sample_all_ps_e"
ps aux >"$GATHER/sample_all_ps_aux"
for i in $(ps -e|awk '{print $1}'|sort -n|tail -n +3); do echo "sampling process with process id $i:"; sample $i "pid_$i"; done

echo "waiting for a minute here for the crashes to settle"
sleep 60

echo "copying all crash reports (hopefully caused by sample_and_crash above)"
cp /Library/Logs/DiagnosticReports/*.crash "$GATHER"
cp ~/Library/Logs/DiagnosticReports/*.crash "$GATHER"

echo "storing gathered data to an archive"
tar -cjf ~/Documents/avast_capture_v2.tar.bz2 "$GATHER" ~/Documents/avast_system.log

echo "script has finished gathering data into ~/Documents/avast_capture_v2.tar.bz2"
