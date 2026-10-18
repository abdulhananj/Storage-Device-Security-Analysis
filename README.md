# Storage Device Security Analysis & Digital Forensics

A comprehensive security analysis investigating data persistence, secure media disposal failures, and digital forensics methodologies for removable flash storage media.

---

## 1. Overview and Problem Statement

Digital storage devices, including HDDs, SSDs, and USB flash drives, are routinely used to store personal and sensitive information. A common misconception is that performing a quick format permanently removes all stored data. In practice, quick formatting typically removes or resets file system references without securely erasing all underlying data, potentially leaving information recoverable from unallocated space.

This project demonstrates the limitations of quick formatting as a data sanitization method. Using open-source digital forensics tools, an apparently empty, formatted USB drive was examined to recover deleted files, extract digital communication artifacts, and reconstruct historical activity timelines.

## 2. Security Lifecycle Framework

The study examines removable storage security through a structured, three-phase defense model.

```text
+--------------------------------------------------------------------------------------+
|                         STORAGE SECURITY FRAMEWORK                                   |
+--------------------------------+--------------------------------+--------------------+
|          PREVENTION            |           DETECTION            |      RESPONSE      |
|   (Confidentiality at Rest)    |    (Host-Level Monitoring)     | (Digital Forensics)|
+--------------------------------+--------------------------------+--------------------+
| - Full-volume AES-256          | - Wazuh SIEM alerts            | - Write-blocked    |
|   encryption using VeraCrypt  | - USB connection logging       |   E01 acquisition  |
| - NIST SP 800-88 sanitization  | - Unauthorized copy detection  | - File system      |
| - Secure media disposal        | - Host activity monitoring     |   reconstruction   |
|                                |                                | - File carving     |
+--------------------------------+--------------------------------+--------------------+
```

### 2.1 Prevention

- Apply full-volume encryption using tools such as VeraCrypt.
- Follow NIST SP 800-88 guidance for media sanitization.
- Use appropriate cryptographic erasure or physical destruction when required.

### 2.2 Detection

- Monitor USB connection events and removable media activity.
- Configure Wazuh SIEM alerts for suspicious activity.
- Record and investigate unauthorized data transfers.

### 2.3 Response

- Acquire forensic images using appropriate write-blocking controls.
- Reconstruct file system metadata and directory structures.
- Perform file carving and recover relevant digital artifacts.

## 3. Technical Specifications and Toolchain

| Category | Tools and Technologies | Implementation Details |
|---|---|---|
| Evidence Acquisition | Exterro FTK Imager, Windows Registry | Acquisition of bit-stream images in Expert Witness Format (`.E01`) and configuration of host-level write protection. |
| Integrity Verification | Hashdeep, HashMyFiles | MD5 and SHA-1 hashes recorded and compared during acquisition and subsequent analysis. |
| Lab Environment | VMware Workstation, SIFT Workstation | An isolated forensic environment using a SANS SIFT-based Linux workstation. |
| File System Analysis | The Sleuth Kit (TSK), Autopsy 4.23 | Partition inspection with `mmls`, file system analysis with `fsstat`, and timeline generation with `fls` and `mactime`. |
| Raw Image Conversion | `ewfexport` (libewf) | Conversion of an `.E01` evidence container into a raw disk image for low-level analysis. |
| Artifact and File Carving | Bulk Extractor, PhotoRec, Scalpel | Extraction of file signatures, email addresses, URLs, and recoverable file content from disk image data. |

## 4. End-to-End Investigation Workflow

### Phase 1: Write Protection and Forensic Acquisition

1. Configure host-level write protection before connecting or accessing the evidence device, where supported.

   Run the following command in an elevated Windows Command Prompt:

   ```cmd
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" /v WriteProtect /t REG_DWORD /d 1 /f
   ```

   **Important:** This registry setting is not a substitute for a validated hardware write blocker. Its effectiveness depends on the Windows configuration and device. For forensic acquisition, use a validated write-blocking solution whenever possible.

2. Use FTK Imager to acquire a bit-for-bit forensic image of the physical USB device in `.E01` format.

   Example evidence image:

   `evidence001.E01`

3. Record the initial integrity values reported during acquisition.

   - **MD5:** `60776ebb25da23f964431862f5d8dfb8`
   - **SHA-1:** `11face8155a7b8e682d6eec011395bea79f3ddc`
   - **Reported bad sectors:** 0

   These values are the reported results and should be verified against the original acquisition logs.

4. If write protection was enabled through the Windows registry specifically for this examination, restore the original configuration after acquisition, according to laboratory policy.

   The following command disables that registry setting:

   ```cmd
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" /v WriteProtect /t REG_DWORD /d 0 /f
   ```

   Do not disable write protection on a system that must remain protected. Document configuration changes in the examination record.

### Phase 2: Structural and File System Analysis

The forensic image is analyzed in the SIFT Workstation environment.

#### 2.1 Partition Table Analysis

Use `mmls` to inspect the partition layout:

```bash
mmls /mnt/hgfs/Forensics/evidence001.E01
```

The reported analysis identified an NTFS partition beginning at sector offset `2048`. Confirm this offset from the actual command output before using it in subsequent commands.

#### 2.2 File System Metadata Inspection

Use `fsstat` to examine file system metadata:

```bash
fsstat -o 2048 /mnt/hgfs/Forensics/evidence001.E01
```

The analysis records the following reported properties:

- Cluster size: 4,096 bytes
- Sector size: 512 bytes
- Volume serial number: `648452ABE4527F6C`
- Master File Table (MFT) information

These values should be confirmed against the actual `fsstat` output. The `-o` option specifies the partition's starting sector offset.

#### 2.3 MAC Timeline Reconstruction

Generate a file listing containing file system metadata:

```bash
fls -r -m / -o 2048 /mnt/hgfs/Forensics/evidence001.E01 > /home/sansforensics/file_listing.txt
```

Convert the listing into a chronological timeline:

```bash
mactime -b /home/sansforensics/file_listing.txt -d > /home/sansforensics/timeline.csv
```

The resulting timeline supports the examination of file modification, access, and metadata-change timestamps where those timestamps are available.

**Note:** File system timestamps are not a complete record of historical activity. They can be missing, altered, or affected by system behavior and should be interpreted alongside other evidence.

### Phase 3: Raw Image Conversion and Integrity Validation

#### 3.1 Export the Evidence Image

Convert the E01 image into a raw image using `ewfexport`:

```bash
ewfexport -t /home/sansforensics/evidence_raw /mnt/hgfs/Forensics/evidence001.E01
```

Follow the interactive prompts and verify the actual output filename and location. Depending on the tool version and export settings, the resulting file may be named `evidence_raw.raw`.

#### 3.2 Validate Image Integrity

The reported raw-image MD5 hash is:

`60776ebb25da23f964431862f5d8dfb8`

Compare the hash against the acquisition baseline and document the result.

A matching hash supports the conclusion that the compared data streams are identical for the purposes of that hash comparison. Record the hashing algorithm, the exact files compared, and the verification logs.

### Phase 4: Data Carving and Artifact Recovery

#### 4.1 Bulk Extractor Analysis

Run Bulk Extractor against the raw image:

```bash
bulk_extractor -o /home/sansforensics/bulk_output/ /home/sansforensics/evidence_raw.raw
```

Bulk Extractor examines raw data for recognizable features, including email addresses, URLs, and other supported artifacts. It can identify features without relying exclusively on the file system's directory structure.

#### 4.2 Signature-Based File Carving

Run Scalpel:

```bash
scalpel /home/sansforensics/evidence_raw.raw -o /home/sansforensics/scalpel_output
```

Run PhotoRec:

```bash
sudo photorec /home/sansforensics/evidence_raw.raw
```

These tools can recover files by identifying recognizable file signatures and structures in the underlying data. Recovery depends on the file format, the condition of the data, overwriting, fragmentation, and the tool's configuration.

Supported file types may include JPEG, PNG, PDF, ZIP, text, and executable formats, depending on the configured signatures and carving capabilities.

Recovered files should be preserved separately from the original evidence image and assessed for relevance, integrity, and evidentiary value.

## 5. Investigation Findings and Results

The following findings reflect the reported results of the investigation. They should be supported by acquisition logs, tool output, and case documentation.

### 5.1 Cryptographic Consistency

The reported MD5 hash was:

`60776ebb25da23f964431862f5d8dfb8`

The same value was reported for the acquired image and its raw export. This indicates a matching MD5 result for the compared data, subject to confirmation of the files and hashing procedures used.

### 5.2 Recovery of Formatted User Files

File carving reportedly recovered files after the USB device had been quick-formatted. Examples included:

- `passwords_backup.txt`
- `bank_statement.txt`
- Application binaries
- Image files

These filenames are reported examples and should be verified against the actual recovery output. Their recovery illustrates why quick formatting should not be treated as secure data sanitization.

### 5.3 Artifact Discovery in Unallocated Space

Bulk Extractor reportedly processed approximately 8,009 MB of image data and identified 10,474 email-related features, along with URL artifacts, network-related fragments, and other communication indicators.

The number of extracted features does not necessarily represent the same number of unique messages, accounts, or individuals. Artifacts must be validated and interpreted in context.

### 5.4 Autopsy Case Analysis

Autopsy reportedly identified:

- 6,795 deleted file records
- 291 communication-account artifacts
- Media categorized across multiple MIME types

These figures represent reported tool output. Deleted-file records may include metadata entries, duplicates, or incomplete records and should not automatically be interpreted as equivalent numbers of independently recovered, usable files or verified accounts.

## 6. Repository Layout

```text
Storage-Device-Security-Analysis/
├── configs/
│   └── scalpel.conf
├── docs/
│   └── STORAGE_DEVICE_Report.pdf
├── evidence_logs/
│   ├── hash_verification.txt
│   └── bulk_extractor_summary.txt
├── scripts/
│   ├── analyze_image.sh
│   ├── disable_write_protect.bat
│   └── enable_write_protect.bat
├── .gitignore
└── README.md
```

### 6.1 Directory Descriptions

- **`configs/`** — Contains Scalpel configuration settings for file carving.
- **`docs/`** — Contains the full investigation report.
- **`evidence_logs/`** — Stores hash verification records and artifact extraction summaries.
- **`scripts/`** — Contains automation scripts for forensic analysis and write-protection configuration.
- **`.gitignore`** — Excludes raw evidence images and case dumps from version control.

**Evidence handling recommendation:** Do not commit raw disk images, recovered sensitive files, passwords, private communications, or confidential case data to a public repository. Restrict access to evidence and preserve the original acquisition separately.

## 7. Conclusion

This investigation demonstrates that quick formatting alone does not reliably sanitize removable storage media. Depending on the file system, device behavior, and whether data has been overwritten, deleted content and residual artifacts may remain recoverable through forensic examination.

The combination of write-protected acquisition, cryptographic integrity verification, file system analysis, timeline reconstruction, and file carving provides a structured approach to examining removable media.

For secure disposal, organizations should follow an appropriate media-sanitization process based on the device type, data sensitivity, and applicable requirements, using current NIST SP 800-88 guidance.

## 8. Author

**Abdul Hanan**

**Student ID:** `CSEC231102033`
