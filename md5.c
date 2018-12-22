#include <stdlib.h>
//#include <string.h>
#include <stdio.h>
#include <conio.h>
#include <time.h>
#include <windows.h>

#pragma warning(disable : 4996)

typedef long long int64;
typedef unsigned int dword;
typedef unsigned char byte;
typedef struct md5digest { byte b[16]; } tmd5digest;

#define evie extern int
evie mdx5init(tmd5digest *digest);
evie mdx5fetch(tmd5digest *digest, byte *Buf64, dword Count);
evie mdx5calc(tmd5digest *digest, byte *Buf64, dword length);
evie mdx5finalize(tmd5digest *digest, byte *Buf64, int64 length);
// evie mdx5finalizer(tmd5digest *digest, byte *Buf64, dword length, dword LengthHi);
evie base64encode(void *source, void *dest, int length);

char* getbasename(char* fullpathname) {
	char *s = fullpathname;
	char *p = strchr(s, '\\');
	while (p) {
		s = ++p;
		p = strchr(p, '\\');
	}
	return(s);
}

char *csSTDIN = "(stdin)";
static const char *csReading = "Reading";
static const char *csOpening = "Opening";
//static const char *csResetting = "Resetting";
//static const char *csWhileRead = "While reading";

int Help(char *arg)
{
	char *s = getbasename(arg);
/*
 Copyright (c) 2003-2009\n
 Adrian H, Ray AF & Raisa NF of PT SOFTINDO, Jakarta\n
 Email: aa _AT_ softindo.net\n\
 Created: 2005.11.03, Last revised: 2008.03.23\n

 See also:\n
   obj2asm	http://www.openwatcom.org\n
   tinyCC	https://bellard.org/tcc/\n
   objconv	https://github.com/gitGNU/objconv\n
*/
	printf(" ====================================================\n");
	printf(" Copyright (c) 2003-2009\n");
	printf(" Adrian H, Ray AF & Raisa NF of PT SOFTINDO, Jakarta\n");
	printf(" ----------------------------------------------------\n");
	printf(" MDX5sum Version: 0.1.16 - 2008.03.23\n");
	printf(" https://github.com/dbat/md5\n");
	printf(" ====================================================\n");

	//printf(" Compatible TASM/MASM, Visual Studio, TinyC\n");

	printf(" SYNOPSYS:\n");
	printf(" \tCalculate MD5 of files/wildcards or std input\n");
	printf(" \t\n");

	printf(" USAGE:\n");
	printf(" \t%s [ OPTIONS ] [ filenames/wildcards ]...\n", s);
	printf(" \t\n");
	printf(" \t-b\t: Base-64 encoding\n");
	printf(" \t-c, -x\t: UPPERCASE HEX\n");
	printf(" \t\n");
	printf(" \t-n\t: Don't print filename\n");
	printf(" \t-s\t: Print also stats (time & speed)\n");
	printf(" \t-z\t: Print also filesize\n");
	printf(" \t\n");
	printf(" \t-p\t: Paused at the end (for drag-n-drop)\n");
	printf(" \t\n");
	printf(" \t--\t: No more OPTIONS after this\n\n");
	printf(" \t?, -?\t: Help\n");
	printf(" \t-h\t: Also help\n");
	printf(" \t-t\t: Test CPU speed for calculating MD5\n");
	printf(" \t\n");

	printf(" NOTES:\n");
	printf(" \tOPTIONS can be specified by DASH (-) or SLASH (/)\n");
	printf(" \tThey are NOT case-sensitive, eg. /x equal with /X\n");
	printf(" \tCan also be combined, eg. -z -s to: /zs or /zS\n\n");
	printf(" \tThe first HELP or TEST switch will take precedence\n");
	//printf(" \tother arguments will be rendered useless\n");
	printf(" \t\n");

	//printf(" \tFiles will be calculated everytime they specified\n");
	//printf(" \tFor example: %s * *exe *e file*\n", s);
	//printf(" \t-> will recalculated filename.exe more than once\n", s);
	//printf(" \n");

	printf(" \tIf no filename has given, it will be fed from stdin\n");
	printf(" \n");

	//printf(" \tOn console/stdin, type CTRL-Z to signal end-of-file\n");
	//printf(" \n");

	printf(" EXAMPLES:\n");
	printf(" \t%s -z /S *.exe \"%%windir%%\\system32\\*.sys\" \\*.txt\n\n", s);
	printf(" \techo.| %s /z\n", s);
	printf(" \t=> Print MD5 for CRLF, also print size = 2\n\n");
	printf(" \t%s -zx notes.txt\n", s);
	printf(" \t%s /zx < notes.txt\n", s);
	printf(" \ttype notes.txt | %s -Z /x\n", s);
	printf(" \t=> All above gives identical result\n");

	//printf(" \n");
	//printf(" \t%s -ub /szTb?X *txt *exe * (will only run test)\n");
	//printf(" \t%s /ub -hszTbX *txt *exe * (will only run help)\n");
	//printf(" Press any key to continue..\n"); //getch();

	return 1;
}

int stdinSum();
int fileSum(char * dirname, char * cFileName);
//int showLastErr(HANDLE h, DWORD error);

//#define null ((void*)0)
tmd5digest md5;
int fmt = 0, totalCount = 0;

clock_t totalTicks = 0;
int64 fileSize, totalSize = 0;

//#this is very conservative, 1MB (4096 * 256) should be a more reasonable minimum
//#define PAGE8BLOCKS (4096 * 8)
#define PAGE8BLOCKS (4096 * 1024)
#define PAGE4BLOCKS (4096 * 4)
byte Buffy[PAGE8BLOCKS];

const char sERROR[] = "ERROR:\0";

#define FORMAT_UPPERCASE 1
#define FORMAT_FILESIZE 2
#define FORMAT_NOFILENAME 4
#define FORMAT_PRINTSTAT 8
#define FORMAT_PAUSE 16
#define FORMAT_BASE64 64

int printer0(HANDLE h, const char* action, const char* object)
{
	if (h) CloseHandle(h);
	fprintf(stderr, "%s %s \"%s\"\n", sERROR, action, object);
	return 1;
}

//int printerr(const char* action, const char* object){ return printer0(0, action, object); }
#define printerr(a, b) printer0(0, a, b)

int printLine(char *filename, int64 fileSize)
{
	static char md5s[28] = { 0 };
	static char md5fx[8] = "%.2x\0";
	if (fmt & FORMAT_BASE64) {
		base64encode(&md5, &md5s, sizeof md5);
		printf("%s", md5s);
	}
	else {
		md5fx[3] = (fmt & FORMAT_UPPERCASE) ? 'X' : 'x';
		for (int i = 0; i < 16; i++) printf(md5fx, md5.b[i]);
	}
	if (fmt & FORMAT_FILESIZE) printf("%12lld", fileSize);
	if (!(fmt & FORMAT_NOFILENAME)) printf(" %s", filename);
	printf("\n");
	return 0;
}

//int effn(const char *fn) { return printerr("File not found:", fn); }

int printStat() // (clock_t totalTicks, int64 totalSize)
{
	double ratio = 0;
	static const char * es = "\0s\0";
	int ms = totalTicks * 1000LL / CLOCKS_PER_SEC;
	//double ratio = ms ? (double)totalSize / 1024 / 1024 * 1000 / ms : 0;
	if (ms) ratio = (double)totalSize / 1024 / 1024 * 1000 / ms;
	printf("Done processing");
	if (totalCount) printf(" %d file%s,", totalCount, &es[(totalCount>1)&1]);
	printf(" %lld bytes in %d ms. (%.2f MB/s)", totalSize, ms, ratio);
	return ms;
}

int testSpeed()
{
	#define TESTBLOCK (1024 * 1024)
	#define TESTROUND 1024
	//int i;
	totalSize = TESTBLOCK;
	char *base = (char*)malloc(TESTBLOCK);
	printf("- CPU test benchmark %d MB -\n", TESTROUND);
	if (base){
		totalTicks = clock(); //QueryPerformanceCounter(&tic);
		for (int i = 0; i < TESTROUND; i++){
			mdx5init(&md5);
			mdx5fetch(&md5, base, (DWORD)(totalSize >> 6));
			mdx5finalize(&md5, base, totalSize);
		}
		totalTicks = clock() - totalTicks; //QueryPerformanceCounter(&tic);
		free(base);
	}
	totalSize *= TESTROUND;
	return printStat(); //(tic, testSize * 2);
}

int main(int argc, char **argv) {
	//fprintf(stderr, "debug: start. argc=%d, argv=%p\n", argc, argv);
	HANDLE fh;
	WIN32_FIND_DATA shrek;
	int c, n, found, broken=0, done=0;
	char *b = argv[0];
	char dirname[MAX_PATH];
	//fprintf(stderr, "DEBUG: start. argc=%d, argv=%p argv[0]=\"%s\"\n", argc, argv, argv[0]);
	argc--; argv++;
	while (argc > 0) {
		char *a = argv[0];
		if (!a[1] && *a == '?') return Help(b);
		found = a[1] && (*a == '-' || *a == '/');
		if (found) {
			//if (!a[1]) return printerr("Invalid switch:", argv[0]);
			while (*++a) {
				switch (*a | 0x20) {
					case '-': if (!a[1]) done = TRUE; break;
					case '?': case 'h': return Help(b);
					case 'b': fmt |= FORMAT_BASE64; break;
					case 'c':; case 'x': fmt |= FORMAT_UPPERCASE; break;
					case 'n': fmt |= FORMAT_NOFILENAME; break;
					case 'p': fmt |= FORMAT_PAUSE; break;
					case 's': fmt |= FORMAT_PRINTSTAT; break;
					case 't': return testSpeed();
					case 'z': fmt |= FORMAT_FILESIZE; break;
					default: return printerr("Unknown switch:", argv[0]);
				}
			}
			if (found) { argc--; argv++; }
			if (done) break;
		}
		else break;
	}
	//fprintf(stderr, "DEBUG: start. argc=%d, argv=%p argv[0]=\"%s\"\n", argc, argv, argv[0]);
	if (argc == 0) stdinSum();
	else
		for (c = 0; c < argc; c++){
			if (c) printf("\n");
			fh = FindFirstFile(argv[c], &shrek);
			found = fh != INVALID_HANDLE_VALUE;
			if (!found) fprintf(stderr, "%s File not found: \"%s\"", sERROR, argv[c]);
			else {
				b = getbasename(argv[c]);
				n = b - argv[c];
				if (n) strncpy(dirname, argv[c], n);
				dirname[n] = '\0';
				while (found) {
					if (!(shrek.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
						fileSum(dirname, shrek.cFileName);
					found = FindNextFile(fh, &shrek);
				}
				FindClose(fh);
			}
		}
	if (fmt & FORMAT_PRINTSTAT) printStat(); //(totalTicks, totalSize);
	if (fmt & FORMAT_PAUSE) {
		fprintf(stderr, "(paused)");
		getch(); //(totalTicks, totalSize);
	}

}

int fileSum(char* dirname, char* cFileName) {
#define ShareMode (FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE)
#define OpenFlags (FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN)
	DWORD got;
	HANDLE fh = 0;
	//int64 fileSize = 0;
	LARGE_INTEGER sz;
	clock_t tac;
	char *filename;
	char pathname[MAX_PATH];
	if (*dirname) {
		strcpy(pathname, dirname);
		strcat(pathname, cFileName);
		filename = pathname;
	}
	else filename = cFileName;
	fh = CreateFile(filename, GENERIC_READ, ShareMode, NULL, OPEN_EXISTING, OpenFlags, 0);
	if (fh == INVALID_HANDLE_VALUE)
		return printerr(csOpening, filename);
	if (SetFilePointer(fh, 0, 0, 0) == INVALID_SET_FILE_POINTER)
		return printer0(fh, "Resetting", filename);
	if (!(ReadFile(fh, Buffy, sizeof Buffy, &got, NULL)))
		return printer0(fh, csReading, filename);
	sz.LowPart = GetFileSize(fh, &sz.HighPart);
	fileSize = sz.QuadPart;
	tac = clock();
	if (fileSize <= sizeof Buffy)
		// if the whole file fits in the buffer, it can be directly calculated
		mdx5calc(&md5, Buffy, sz.LowPart);
	else {
		// otherwise, do it the hard way
		fileSize = 0;
		mdx5init(&md5);
		while (got == sizeof Buffy) {
			fileSize += sizeof Buffy;
			mdx5fetch(&md5, Buffy, sizeof Buffy >> 6);
			if (!(ReadFile(fh, Buffy, sizeof Buffy, &got, NULL)))
				return printer0(fh, "Caching", filename);
		}
		mdx5fetch(&md5, Buffy, got >> 6);
		fileSize += got;
		//got &= ~63;
		mdx5finalize(&md5, &Buffy[got & ~63], fileSize);
	}
	tac = clock() - tac;
	totalTicks += tac;
	totalSize += fileSize;
	totalCount++;
	CloseHandle(fh);
	return printLine(cFileName, fileSize);
	//printf("DEBUG5: filename: %s, got:%d\n", filename, got);
}

int stdinSum() {
	HANDLE fh;
	clock_t tac;
	DWORD got;
	int n = 0, r = 0;
	fileSize = 0;
	fh = GetStdHandle(STD_INPUT_HANDLE);
	if (fh == INVALID_HANDLE_VALUE)
		return printerr(csOpening, csSTDIN);
	if (GetFileType(fh) == FILE_TYPE_CHAR)
		fprintf(stderr, "(Waiting for input. Type [CTRL-Z], alone in the line, to signal EOF)\n");
	tac = clock();
	mdx5init(&md5);
	while (TRUE) {
		if (ReadFile(fh, &Buffy[n], PAGE4BLOCKS - n, &got, NULL)) {
			if (!got) break; // read OK but got zero => CTR-Z pressed
			else {
				n += got;
				if (n >= PAGE4BLOCKS) {
					mdx5fetch(&md5, Buffy, PAGE4BLOCKS >> 6);
					fileSize += PAGE4BLOCKS;
					n = 0;
				}
			}
		}
		else {
			int e = GetLastError();
			if (e == ERROR_HANDLE_EOF || e == ERROR_BROKEN_PIPE) break;
			else return printer0(fh, csReading, csSTDIN);//showLastErr(fh, e); //(error_reading)
		}

	}
	got = n;
	fileSize += got;
	mdx5fetch(&md5, Buffy, got >> 6);
	// got &= ~63;
	mdx5finalize(&md5, &Buffy[got & ~63], fileSize);
	tac = clock() - tac;
	totalTicks += tac;
	totalSize += fileSize;
	CloseHandle(fh);
	return printLine(csSTDIN, fileSize);
}

// // Retrieve the system error message for the last-error code
// LPCTSTR ErrorMessage(DWORD error) { 
// 	LPVOID lpMsgBuf;
// 	FormatMessage(
// 		FORMAT_MESSAGE_ALLOCATE_BUFFER | 
// 		FORMAT_MESSAGE_FROM_SYSTEM |
// 		FORMAT_MESSAGE_IGNORE_INSERTS,
// 		NULL, error,
// 		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
//         (LPTSTR) &lpMsgBuf,	0, NULL
// 	);
//     return((LPCTSTR)lpMsgBuf);
// }
// 
// int showLastErr(HANDLE h, DWORD error) {
// 	char *errStr = (char*) ErrorMessage(error);
// 	printf("%s", errStr);
// 	LocalFree(errStr);
// 	if (h) CloseHandle(h);
// 	return error;
// } 