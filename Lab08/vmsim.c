// Virtual Memory Simulation

#include <stdlib.h>
#include <stdio.h>

typedef unsigned int uint;

// Page Table Entries

#define NotLoaded 0
#define Loaded    1
#define Modified  2

#define PAGESIZE  4096
#define PAGEBITS  12

#define actionName(A) (((A) == 'R') ? "read from" : "write to")

typedef struct {
   int status;        // Loaded or Modified or NotLoaded
   int frameNo;       // -1 if page not loaded
   int lastAccessed;  // -1 if never accessed
} PTE;

// Globals

uint nPages;         // how many process pages
uint nFrames;        // how many memory frames

PTE *PageTable;      // process page table
int *MemFrames;      // memory (each frame holds page #, or -1 if empty)

uint nLoads = 0;     // how many page loads
uint nSaves = 0;     // how many page writes (after modification)
uint nReplaces = 0;  // how many Page replacements

uint clock = 0;      // clock ticks

// Functions

void initPageTable();
void initMemFrames();
void showState();
int  physicalAddress(uint vAddr, char action);

// main:
// read memory references
// maintain VM data structures
// argv[1] = nPages, argv[2] = nFrames
// stdin contains lines of form
//   R Address
//   W Address
// R = read a byte, W = write a byte, Address = byte address
// Address is mapped to a page reference as per examples in lectures
// Note: pAddr is signed, because -ve used for errors

int main (int argc, char **argv)
{
   char line[100]; // line buffer
   char action;    // read or write
   uint vAddr;     // virtual address (unsigned)
   int  pAddr;     // physical address (signed)

   if (argc < 3) {
      fprintf(stderr, "Usage: %s #pages #frames < refFile\n", argv[0]);
      exit(1);
   }

   nPages = atoi(argv[1]);
   nFrames = atoi(argv[2]);
   // Value 2 also picks up invalid argv[x]
   if (nPages < 1 || nFrames < 1) {
      fprintf(stderr, "Invalid page or frame count\n");
      exit(1);
   }

   initPageTable(); initMemFrames();

   // read from standard input
   while (fgets(line,100,stdin) != NULL) {
      // get next line; check valid (barely)
      if ((sscanf(line, "%c %d\n", &action, &vAddr) != 2)
                     || !(action == 'R' || action == 'W')) {
         printf("Ignoring invalid instruction %s\n", line);
         continue;
      }
      // do address mapping
      pAddr = physicalAddress(vAddr, action);
      if (pAddr < 0) {
         printf("\nInvalid address %d\n", vAddr);
         exit(1);
      }
      // debugging ...
      printf("\n@ t=%d, %s pA=%d (vA=%d)\n",
             clock, actionName(action), pAddr, vAddr);
      // tick clock and show state
      showState();
      clock++;
   }
   printf("\n#loads = %d, #saves = %d, #replacements = %d\n", nLoads, nSaves, nReplaces);
   return 0;
}

// map virtual address to physical address
// handles regular references, page faults and invalid addresses

int physicalAddress(uint vAddr, char action)
{
   // TODO: write this function
   int phAddr;
   int lrPage;
   // Calculate page number and offset of vAddr
   uint pageno = vAddr / PAGESIZE;
   uint offset = vAddr % PAGESIZE;
   
   // Error check
   if(pageno < 0 || pageno >= nPages){
        return -1;
   }
   
   // If the page is already loaded
   if(PageTable[pageno].frameNo != -1){
        if(action == 'W'){
            PageTable[pageno].status = Modified;
        }
        PageTable[pageno].lastAccessed = clock;
        phAddr = PAGESIZE*PageTable[pageno].frameNo + offset;
   } else {
        // Look for unused frame
        for(int i = 0; i < nFrames; i++){
            if(MemFrames[i] == -1){
                MemFrames[i] = pageno;
                nLoads++;
                PageTable[pageno].status = Loaded;
                if(action == 'W'){
                    PageTable[pageno].status = Modified;
                }
                PageTable[pageno].lastAccessed = clock;
                PageTable[pageno].frameNo = i;
                phAddr = PAGESIZE*PageTable[pageno].frameNo + offset;
                return phAddr;
            } 
        }
        // Replace the least recent frame
        int tmp = clock;
        // Find least recent frame 
        for(int i = 0; i < nPages; i++){
            if(PageTable[i].lastAccessed > -1){
                if(tmp > PageTable[i].lastAccessed){
                    tmp = PageTable[i].lastAccessed;
                    lrPage = i;
                }
            }
        }
        nReplaces++;
        // If modified increment nSaved
        if(PageTable[lrPage].status == Modified)
            nSaves++;
        
        int frameToChange = PageTable[lrPage].frameNo;  
        // Set PTE to no longer loaded
        PageTable[lrPage].status = NotLoaded;
        PageTable[lrPage].frameNo = -1;
        PageTable[lrPage].lastAccessed = -1;
        nLoads++;
        // Change the Memory frame
        MemFrames[frameToChange] = pageno;
        PageTable[pageno].status = Loaded;
        if(action == 'W')
            PageTable[pageno].status = Modified;
        PageTable[pageno].frameNo = frameToChange;
        PageTable[pageno].lastAccessed = clock;
        phAddr = PageTable[pageno].frameNo * PAGESIZE + offset;
   }
   return phAddr; // replace this line
}

// allocate and initialise Page Table

void initPageTable()
{
   PageTable = malloc(nPages * sizeof(PTE));
   if (PageTable == NULL) {
      fprintf(stderr, "Insufficient memory for Page Table\n");
      exit(1);
   }
   for (int i = 0; i < nPages; i++) {
      PageTable[i].status = NotLoaded;
      PageTable[i].frameNo = -1;
      PageTable[i].lastAccessed = -1;
   }
}

// allocate and initialise Memory Frames

void initMemFrames()
{
   MemFrames = malloc(nFrames * sizeof(int));
   if (MemFrames == NULL) {
      fprintf(stderr, "Insufficient memory for Memory Frames\n");
      exit(1);
   }
   for (int i = 0; i < nFrames; i++) {
      MemFrames[i] = -1;
   }
}

// dump contents of PageTable and MemFrames

void showState()
{
   printf("\nPageTable (Stat,Acc,Frame)\n");
   for (int pno = 0; pno < nPages; pno++) {
      uint s; char stat;
      s = PageTable[pno].status;
      if (s == NotLoaded)
         stat = '-';
      else if (s & Modified)
         stat = 'M';
      else
         stat = 'L';
      int f = PageTable[pno].frameNo;
      printf("[%2d] %2c, %2d, %2d",
             pno, stat, PageTable[pno].lastAccessed, PageTable[pno].frameNo);
      if (f >= 0) printf(" @ %d", f*PAGESIZE);
      printf("\n");
   }
   printf("MemFrames\n");
   for (int fno = 0; fno < nFrames; fno++) {
      printf("[%2d] %2d @ %d\n", fno, MemFrames[fno], fno*PAGESIZE);
   }
}
