#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint8_t byte;
typedef uint16_t word;
typedef uint32_t dword;

typedef struct {
        byte jmpShortNOP[3];
        byte oemID[8];
        word bytesPerSector;
        byte sectorsPerCluster;
        word reservedSectors;
        byte nFAT;
        word nRootDirEntries;
        word nSectors;
        byte mediaDescriptorType;
        word sectorsPerFAT;
        word sectorsPerTrack;
        word nHeads;
        dword nHiddenSectors;
        dword largeSectorCount;
} __attribute__((packed)) BIOSParamBlock;

typedef struct {
        byte driveNumber;
        byte flags;
        byte signature;
        dword volumeID;
        byte volumeLabel[11];
        byte systemID[8];
} __attribute__((packed)) ExtendedBootRecord;
typedef struct {
        byte filename[8];
        byte extension[3];
        byte attrib;
        byte reserved;
        byte creationTimeTenths;
        word creationTime;
        word creationDate;
        word lastAccessedDate;
        word clusterNumberH;
        word lastModificationTime;
        word lastModificationDate;
        word clusterNumberL;
        dword fileSize;
} __attribute__((packed)) DirEntry;

BIOSParamBlock bpb;
ExtendedBootRecord ebr;
byte *FAT;
DirEntry *rootDir;
dword dataRegionStart;

bool readSectors(FILE *disk, dword lba, dword count, byte *dest) {
    bool ok = fseek(disk, lba * bpb.bytesPerSector, SEEK_SET) == 0;
    ok = ok && (fread(dest, bpb.bytesPerSector, count, disk) == count);
    return ok;
}

bool readBootRecord(FILE *disk) {
    return fread(&bpb, sizeof(bpb), 1, disk) &&
           fread(&ebr, sizeof(ebr), 1, disk);
}

bool readRootDirectory(FILE *disk) {
    dword lba = bpb.reservedSectors + bpb.sectorsPerFAT * bpb.nFAT;
    dword size = sizeof(DirEntry) * bpb.nRootDirEntries;
    dword sectors =
        (size / bpb.bytesPerSector) + (size % bpb.bytesPerSector > 0 ? 1 : 0);
    rootDir = (DirEntry *)malloc(bpb.bytesPerSector * sectors);
    dataRegionStart = lba + sectors;
    return readSectors(disk, lba, sectors, (byte *)rootDir);
}

DirEntry *findFile(char *filename) {
    for (DirEntry *file = rootDir; file - rootDir < bpb.nRootDirEntries;
         file++) {
        if (memcmp(file->filename, filename, 11) == 0)
            return file;
    }
    return NULL;
}

bool readFile(FILE *disk, DirEntry *fileEntry, byte *contentBuffer) {
    bool ok = true;
    word currentCluster = fileEntry->clusterNumberL;
    do {
        dword lba =
            dataRegionStart + (currentCluster - 2) * bpb.sectorsPerCluster;

        ok = ok && readSectors(disk, lba, bpb.sectorsPerCluster, contentBuffer);
        contentBuffer += bpb.sectorsPerCluster * bpb.bytesPerSector;

        dword fatIdx = currentCluster * 3 / 2;
        if (currentCluster % 2 == 0)
            currentCluster = (*(word *)(FAT + fatIdx)) & 0x0fff;
        else
            currentCluster = (*(word *)(FAT + fatIdx)) >> 4;
    } while (ok && currentCluster < 0x0ff8);
    return ok;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Syntax: %s <disk_image> <file_name>\n", argv[0]);
        return -1;
    }

    FILE *disk = fopen(argv[1], "rb");
    if (!disk) {
        fprintf(stderr, "Couldn't open disk %s\n", argv[1]);
        return -1;
    }

    if (!readBootRecord(disk)) {
        fprintf(stderr, "Could not read Boot Record\n");
        fclose(disk);
        return -2;
    }

    FAT = (byte *)malloc(bpb.sectorsPerFAT * bpb.bytesPerSector);
    if (!readSectors(disk, bpb.reservedSectors, bpb.sectorsPerFAT, FAT)) {
        fprintf(stderr, "Couldn't read FAT\n");
        free(FAT);
        fclose(disk);
        return -3;
    }

    if (!readRootDirectory(disk)) {
        fprintf(stderr, "Couldn't read Root Directory\n");
        free(FAT);
        free(rootDir);
        fclose(disk);
        return -4;
    }

    DirEntry *fileEntry = findFile(argv[2]);
    if (!fileEntry) {
        fprintf(stderr, "Couldn't find file %s\n", argv[2]);
        free(FAT);
        free(rootDir);
        fclose(disk);
        return -5;
    }

    byte *contentBuffer =
        (byte *)malloc(fileEntry->fileSize + bpb.bytesPerSector);
    if (!readFile(disk, fileEntry, contentBuffer)) {
        fprintf(stderr, "Couldn't read file %s\n", argv[2]);
        free(FAT);
        free(rootDir);
        free(contentBuffer);
        fclose(disk);
        return -5;
    }

    for (int i = 0; i < fileEntry->fileSize; i++) {
        if (isprint(contentBuffer[i]))
            fputc(contentBuffer[i], stdout);
        else
            printf("<%02x>", contentBuffer[i]);
    }
    printf("\n");

    free(FAT);
    free(rootDir);
    fclose(disk);
    return EXIT_SUCCESS;
}
