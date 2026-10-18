#!/usr/bin/env bash
# SIFT Workstation Automated Examination Pipeline
# Usage: ./analyze_image.sh /path/to/evidence001.E01 2048

EVIDENCE_IMAGE="$1"
PARTITION_OFFSET="${2:-2048}"
OUTPUT_DIR="./investigation_output"

if [ -z "$EVIDENCE_IMAGE" ]; then
    echo "Usage: $0 <path_to_e01> [partition_offset_sector]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "[*] Parsing partition structure (mmls)..."
mmls "$EVIDENCE_IMAGE" > "$OUTPUT_DIR/partition_table.txt"

echo "[*] Extracting File System Details (fsstat)..."
fsstat -o "$PARTITION_OFFSET" "$EVIDENCE_IMAGE" > "$OUTPUT_DIR/filesystem_info.txt"

echo "[*] Generating File & Folder Listing (fls)..."
fls -r -m / -o "$PARTITION_OFFSET" "$EVIDENCE_IMAGE" > "$OUTPUT_DIR/file_listing.txt"

echo "[*] Generating MAC Timeline (mactime)..."
mactime -b "$OUTPUT_DIR/file_listing.txt" -d > "$OUTPUT_DIR/timeline.csv"

echo "[+] Preliminary examination complete. Outputs saved to: $OUTPUT_DIR"