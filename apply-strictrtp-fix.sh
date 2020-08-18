#!/bin/bash

verbose=false
debug=false
tmp=""

# Determine STARFACE Version...
if [[ -s "/var/starface/fs-interface/version" ]]; then
    # Fastest way to get the version, querying RPM takes time
    # If avaible, us fs-interface.
    ver="$(cut -f1,2,3 -d. </var/starface/fs-interface/version).x"
else
    ver="$(rpm -q --queryformat '%{VERSION}' starface-pbx | cut -f1,2,3 -d.).x"
fi

# ... and set CDN URI accordingly
baseURI="https://www.starface-cdn.de/starface/asterisk-rtp-fix/$ver"

vecho() {
  if [[ $verbose = true ]]; then
    echo "$1"
  fi
}

downloadRpms() {
    local file
    
    # Highly stupid, but whatever. LGTM ;)
    # TODO: Use rpm -q output to determine filenames
    case "$ver" in
        6.6.0.x)
            file[0]="starface-asterisk-11.25.3-1.el6.21.sf.2.x86_64.rpm"
            file[1]="starface-asterisk-datafiles-11.25.3-1.el6.21.sf.2.x86_64.rpm"
            file[2]="starface-asterisk-extras-11.25.3-1.el6.21.sf.2.x86_64.rpm"
            file[3]="starface-asterisk-kernel-11.25.3-1.el6.21.sf.2.x86_64.rpm"
            ;;
        6.7.0.x)
            file[0]="starface-asterisk-11.25.3-1.el6.25.sf.2.x86_64.rpm"
            file[1]="starface-asterisk-datafiles-11.25.3-1.el6.25.sf.2.x86_64.rpm"
            file[2]="starface-asterisk-extras-11.25.3-1.el6.25.sf.2.x86_64.rpm"
            file[3]="starface-asterisk-kernel-11.25.3-1.el6.25.sf.2.x86_64.rpm"
            ;;
        6.7.1.x)
            file[0]="starface-asterisk-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            file[1]="starface-asterisk-datafiles-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            file[2]="starface-asterisk-extras-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            file[3]="starface-asterisk-kernel-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            ;;
        6.7.2.x)
            file[0]="starface-asterisk-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            file[1]="starface-asterisk-datafiles-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            file[2]="starface-asterisk-extras-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            file[3]="starface-asterisk-kernel-11.25.3-1.el6.27.sf.2.x86_64.rpm"
            ;;
        6.7.3.x)
            file[0]="starface-asterisk-11.25.3-1.el6.30.sf.2.x86_64.rpm"
            file[1]="starface-asterisk-datafiles-11.25.3-1.el6.30.sf.2.x86_64.rpm"
            file[2]="starface-asterisk-extras-11.25.3-1.el6.30.sf.2.x86_64.rpm"
            file[3]="starface-asterisk-kernel-11.25.3-1.el6.30.sf.2.x86_64.rpm"
            ;;
        *)
            echo "SF $ver has no patch candidates :("
            exit 1
            ;;
    esac

    tmp="$(mktemp -qd --tmpdir)"

    # Make sure we delete the tmp folder, even if we're SIG{INT,TERM}ed
    trap cleanup EXIT
    trap cleanup SIGINT SIGTERM

    for f in "${file[@]}"
    do
        local uri="$baseURI/$f"
        vecho "Downloading $uri"
        wget -q "$uri" -P "$tmp"
        
        # Check if the file exists, >0byte and is readable. If not: die.
        [[ ! -s "$tmp/$f" || ! -r "$tmp/$f" ]] && echo "$tmp/$f is not readable!" 1>&2 && exit 3
    done

    return 0
}

updateRpms() {
    vecho "Updating pakets..."
    
    # Build RPM parameters
    local param="-U"
    [[ $verbose ]] && param+="v"
    [[ $debug ]] && param+=" --test"

    # Stop the Asterisk daemon
    service asterisk stop

    # Word splitting should be done here, hush
    # shellcheck disable=SC2086
    rpm $param "$tmp/*.rpm"

    # We're done, start Asterisk again
    service asterisk start
}

cleanup() {
    vecho "Cleaning up: ${tmp:?}/"
    [[ -d "$tmp" ]] && rm -rf "${tmp:?}/"

    vecho "Checking in on the Asterisk daemon"
    if ! service asterisk status>/dev/null ; then service asterisk start ; fi

    # Return proper exit code
    trap 'exit $?' EXIT
}

main() {
    vecho "Determined the following:"
    vecho "SF Version: $ver"
    vecho "URI path to be: $baseURI"

    downloadRpms && updateRpms
}

if [[ -n "$*" ]]; then
    # Get cmdline parameters, fill variables
    for i in "$@"
	do
	    case $i in
            -v)
            verbose=true
            ;;
            -d)
            debug=true
            ;;
            *)
            echo "Unknown option ${i}, ignoring."
        esac
    done
fi

main
