#!/bin/sh

start() {
    nohup xdg-open "$*" > /dev/null 2>&1 &
}

DOI=$1
if [ -z "$DOI" ]; then
    echo "ERR: Provide DOI for paper to download!" >&2
    exit 1
fi
DOI_REGEX='10\.\d{4,9}\/[-._;()/:A-Za-z0-9]+'
if ! echo "$DOI" | grep -P "^$DOI_REGEX$"; then
    echo "WRN: Provided string is not recognized as a DOI"
    if NEWDOI=$(echo "$DOI" | grep -Po "$DOI_REGEX"); then
        echo "Extracted DOI"
        DOI=$NEWDOI
    else
        echo "Failed to extaact DOI. Exit!"
        exit 1
    fi
fi

echo "Proceeding with DOI '$DOI'"
fileName="$(echo "$DOI" | sed 's/\//_/g').pdf"
outPath="/mnt/Data/Papers/DB/$fileName"
echo "Output file will be '$outPath'"

# Check for Arxiv
if expr "$DOI" : '^10.48550' >/dev/null ; then
    echo "Detected Arxiv Prefix"
    id=$(echo DOI | cut -d'/' -f2 | cut -d'.' -f2-)
    pdfPath="https://arxiv.org/pdf/${id}"
fi

if [ -z "$pdfPath" ]; then
    echo "Trying Sci-Hub..."
    # Check for Sci-Hub
    SCIHUB_URL='https://www.sci-hub.box'
    # Test run
    if ! curl "${SCIHUB_URL}" 2>/dev/null ; then
        echo "ERR: Cannot connet to sci-hub! Check if '$SCIHUB_URL' is still valid" >&2
    else
        pdfPath="${SCIHUB_URL}/$(curl -L "${SCIHUB_URL}/$DOI" 2>/dev/null | grep -o "/download.*\.pdf")"
        if [ $? != 0 ]; then
            echo "Failed to find pdf from Sci-Hub"
            pdfPath=""
        fi
    fi
fi

if ! [ -z "$pdfPath" ]; then
    # Download the pdf
    echo "Downloading from '$pdfPath'"
    if ! curl --http1.1 -o "$outPath" "$pdfPath" ; then
        echo "ERR: Failed to download!" >&2
        exit 1
    fi
    echo "Successfully downloaded file!"
    printf "Open pdf (y/n)? "
    read -r reply
    if [ "$reply" = 'y' ]; then
        start "$outPath"
    fi
else
    echo "Fallback: Open from SNU libproxy"
    start "https://libproxy.snu.ac.kr/link.n2s?url=https://doi.org/$DOI"
    echo "$outPath" | wl-copy
fi
