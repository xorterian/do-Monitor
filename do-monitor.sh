#!/usr/bin/env bash

VARS="vars.ini"

# --- INITIATE VARIABLES ---
init() {
    echo "This is the do-Monitor. Welcome!"
    LOG="codes/geo_$(date +%Y%m%d_%H%M%S).csv"
    GEO1=""
    GEO2=""
    GEO3=""
    STATE="IDLE"
    
    while read line; do
        if [[ "$line" != "[vars]" ]]; then
            eval "$line"
        fi
    done < "$VARS"
    
    if [[ "$TARGET" == "" ]]; then
        echo "[INIT] Setup Tailscale following the instruction in the readme file."
        TARGET=$(printf '%s' '[INIT] Enter the tailscale IP address of the target device (100.x.y.z): ' >&2; read x && printf '%s' "$x")
        IS_GEOLOG=$(printf '%s' 'Do you wish to log geolocations (y/n): ' >&2; read x && printf '%s' "$x")
        if [[ $IS_GEOLOG == [yY1] ]]; then
            IS_GEOLOG=1
            DT=$(printf '%s' '[INIT] Please, give how frequent the geolocation should be logged in seconds (60): ' >&2; read x && printf '%s' "$x")
            if [[ "$DT" == "" ]]; then
                DT=60
            fi
        else
            IS_GEOLOG=0
            DT=60
        fi
        IS_USSD=$(printf '%s' '[INIT] Do you wish to authorize the device to use the USSD-like codes (y/n): ' >&2; read x && printf '%s' "$x")
        if [[ $IS_USSD == [yY1] ]]; then
            IS_USSD=1
            USSD_PRIME=$(printf '%s' '[INIT] Please, create a prime code for the USSD-like codes (111222333): ' >&2; read x && printf '%s' "$x")
            if [[ "USSD_PRIME" == "" ]]; then
                USSD_PRIME="111222333"
            fi
        else
            IS_USSD=0
            USSD_PRIME="111222333"
        fi
        IS_REC=$(printf '%s' '[INIT] Do you wish to record the phone calls (y/n): ' >&2; read x && printf '%s' "$x")
        if [[ $IS_REC == [yY1] ]]; then
            IS_REC=1
        else
            IS_REC=0
        fi
        
        rm "$VARS"
        echo "[vars]" >> "$VARS"
        echo "TARGET=$TARGET" >> "$VARS"
        echo "IS_GEOLOG=$IS_GEOLOG" >> "$VARS"
        echo "DT=$DT" >> "$VARS"
        echo "IS_USSD=$IS_USSD" >> "$VARS"
        echo "USSD_PRIME=$USSD_PRIME" >> "$VARS"
        echo "IS_REC=$IS_REC" >> "$VARS"
    fi

    echo "[INIT] The system is initiated."
}

init

# --- CLEANUP ON EXIT ---
cleanup() {
    echo -e "\n[!] Shutting down..."
    # Kill the location timer and any active scrcpy recordings
    [[ -n "$TIMER_PID" ]] && kill "$TIMER_PID" 2>/dev/null
    [[ -n "$SCRCPY_PID" ]] && kill "$SCRCPY_PID" 2>/dev/null
    # Kill any lingering adb logcat processes started by this script
    pkill -P $$ adb 2>/dev/null
    location_mapper
    echo "[OK] Cleanup complete. Goodbye."
    exit 0
}

# Capture Ctrl+C (SIGINT) and Termination (SIGTERM)
trap cleanup SIGINT SIGTERM

# --- HELPER FUNCTIONS ---

connect_adb() {
    echo "[*] Ensuring ADB connection to $TARGET..."
    while true; do
        if adb devices | grep "$TARGET" | grep -q "device"; then
            echo "[OK] Connected."
            adb -s "$TARGET" logcat -c
            break
        fi
        echo "[WARN] Device offline. Reconnecting..."
        adb disconnect "$TARGET" >/dev/null 2>&1
        sleep 1
        adb connect "$TARGET"
        sleep 10
    done
}

# Geolocation & Health Loop (Runs in background)
location_timer() {
    local T1=0
    while true; do
        local T2=$(date +%s)
        if (( T2 - T1 > DT )); then
            # Check if device is still there
            if ! adb -s "$TARGET" shell getprop sys.boot_completed >/dev/null 2>&1; then
                echo "[!] Health Check: Connection lost. Killing logcat listener..."
                pkill -P $$ adb  # Kill the current logcat process to trigger main loop restart
                return           # Exit this function to restart everything
            fi

            # Log location
            LINE=$(adb -s "$TARGET" shell dumpsys location | grep -m 1 "Location\[" | tr -d '[:space:]')
            if [[ "$LINE" =~ ([0-9]+\.[0-9]+),([0-9]+\.[0-9]+) ]]; then
                LAT="${BASH_REMATCH[1]}"
                LONG="${BASH_REMATCH[2]}"
                GEO3="$LONG,$LAT"
                if [[ "$GEO3" == "$GEO2" || "$GEO3" == "$GEO1" ]]; then
                    GEO1="$GEO2"
                    GEO2="$GEO3"
                    echo "$GEO3" >> "$LOG"
                fi
                #echo "$LONG,$LAT" >> "$LOG"
                echo "[LOC] $(date -Iseconds) -> ($LONG,$LAT)"
                T1="$T2"
            fi
        fi
        sleep 5
    done
}

# Generating online map plot...
location_mapper() {
    WEB=""
    s=0
    while read line; do
        if [[ "$WEB" == "" ]]; then
            WEB="https://www.keene.edu/campus/maps/tool/?coordinates="
        else
            WEB+="$line %0A"
            s+=1
        fi
    done < "$LOG"

    if [[ $s > 1 ]]; then
        echo "$WEB" | tr -d ' '
        echo "$WEB" | tr -d ' ' >> "$LOG"
    else
        rm "$LOG"
    fi
}


# --- MAIN ENGINE ---

mkdir -p calls codes 2>/dev/null
echo "longitude,latitude ($(date -Iseconds))" >> "$LOG"
connect_adb

while true; do
    echo "[INFO] Starting Location Timer and Logcat Monitor..."
    
    # Start the location/health check in the background
    if [[ "$IS_GEOLOG" > 0 ]]; then
        location_timer &
        TIMER_PID=$!
    else
        TIMER_PID=$!
    fi
    
    # Start the logcat stream
    # We filter by 'Telecom|Telephony|ActivityTaskManager' to reduce CPU usage
    adb -s "$TARGET" shell logcat -v brief | while read -r line; do
        
        # 1. TRIGGER: CALL STARTED
        if [[ "$IS_REC" > 0 && "$line" == *"CALL_STARTED"* && "$STATE" == "IDLE" ]]; then
            FILENAME="calls/call_$(date +%Y%m%d_%H%M%S).mp4"
            echo "[INFO] Call detected. Starting recording: $FILENAME"
            setsid scrcpy --no-control --no-video --audio-source=voice-call --record "$FILENAME" >/dev/null 2>&1 &
            SCRCPY_PID=$!
            STATE="RECORDING"
        fi

        # 2. TRIGGER: CALL ENDED
        if [[ "$line" == *"CALL_ENDED"* && "$STATE" == "RECORDING" ]]; then
            echo "[INFO] Call ended. Stopping scrcpy (PID $SCRCPY_PID)"
            kill "$SCRCPY_PID" 2>/dev/null
            STATE="IDLE"
        fi

        # 3. TRIGGER: USSD-LIKE DIAL
        # We only run dumpsys if we see a Dial/Start activity to save battery/CPU
        if [[ "$IS_USSD" > 0 && "$line" == *"START_CALL"* ]]; then
            DIAL=$(adb shell dumpsys activity | grep "PHONE_NUMBER")
            echo "$DIAL"
            
            if [[ "$DIAL" =~ (\*\#|=\*|=\#)($USSD_PRIME)(\*[0-9]+){0,1}(\*[0-9]+){0,1}(\*[0-9]+){0,1}(\*[0-9]+){0,1}(\*[0-9]+){0,1}\# ]]; then
                MODE="${BASH_REMATCH[1]}"
                CMD="${BASH_REMATCH[3]}"
                ARG1="${BASH_REMATCH[4]}"
                ARG2="${BASH_REMATCH[5]}"
                ARG3="${BASH_REMATCH[6]}"
                ARG4="${BASH_REMATCH[7]}"
                CMD=${CMD#\*}
                ARG1=${ARG1#\*} # Remove leading asterisk if exists
                ARG2=${ARG2#\*}
                ARG3=${ARG3#\*}
                ARG4=${ARG4#\*}
                #[[ -z "$ARG" ]] && ARG=0

                case "$MODE" in
                    '=*') INP="1" ;;
                    '=#') INP="0" ;;
                    '*#') INP="2" ;;
                esac

                echo "[CMD] Running code_$CMD.sh with Args:$ARG1, $ARG2, $ARG3, $ARG4 Mode:$INP"
                RESULT=$(./codes/code_"$CMD".sh "$INP" "$ARG1" "$ARG2" "$ARG3" "$ARG4" -p "$$" -s "$STATE" -g "$GEO3")
                [[ -z "$RESULT" ]] && adb -s "$TARGET" shell cmd notification post ussd_cmd "'$RESULT'"
                
                # Clear logcat buffer after a successful command to prevent re-reading the same dial
                adb -s "$TARGET" logcat -c
                
                while read line; do
                    if [[ "$line" != "[vars]" ]]; then
                        eval "$line"
                    fi
                done < "$VARS"
                sleep 3
            fi
        fi
    done

    # If we are here, logcat crashed or was killed by the health check
    echo "[WARN] Logcat stream broken. Cleaning up and restarting..."
    kill "$TIMER_PID" 2>/dev/null
    connect_adb
done
