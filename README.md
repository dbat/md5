# md5
Tiny, fast, versatile md5 asm lib (source code, sample and helper)

Also included this functional sample (see source code), EXE as tiny as 7KB (compressed), with the capabitlity as below:

And it's quite fast, 750 MB/s in i5-3570K 3.4GHz (memory test only, our mechanical hard disks couldn't even keep up with it).

md5 ?
 
    Copyright (c) 2003-2009
    Adrian H, Ray AF & Raisa NF of PT SOFTINDO, Jakarta
 
    MDX5sum Version: 0.1.15s - 2008.03.10
    https://github.com/dbat/md5
 

 SYNOPSYS:
 
        Calculate MD5 of files/wildcards or std input

 USAGE:
 
        md5 [ OPTIONS ] [ filenames/wildcards ]...

        -b      : Base-64 encoding
        -c, -x  : UPPERCASE HEX

        -n      : Don't print filename
        -s      : Print also stats (time & speed)
        -z      : Print also filesize

        -p      : Paused at the end (for drag-n-drop)

        --      : No more OPTIONS after this

        ?, -?   : Help
        -h      : Also help
        -t      : Test CPU speed for calculating MD5

 NOTES:
 
        OPTIONS can be specified by DASH (-) or SLASH (/)
        They are NOT case-sensitive, eg. /x equal with /X
        Can also be combined, eg. -z -s to: /zs or /zS

        The first HELP or TEST switch will take precedence

        If no filename has given, it will be fed from stdin

 EXAMPLES:
 
        md5 -z /S *.exe "%windir%\system32\*.sys" \*.txt

        echo.| md5 /z
        => Print MD5 for CRLF, also print size = 2

        md5 -zx notes.txt
        md5 /zx < notes.txt
        type notes.txt | md5 -Z /x
        => All above gives identical result
      
