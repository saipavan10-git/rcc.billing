#!/usr/bin/perl
while (<>){
    if (m/^SET/) { next };
    s/CHARACTER SET \S+ //;    # remove CHARACTER SET mumble
    s/COLLATE \S+ //;          # remove COLLATE mumble
    s/ENGINE=\S+ *//;          # remove ENGINE
    s/DEFAULT CHARSET=\S+ *//; # remove DEFAULT CHARSET
    s/COLLATE=\S+ *//;         # remove COLLATE
    if (m/^ALTER TABLE/) { next }; # remove ALTER TABLE
    if (m/^\s*ADD /) { next };     # Remove indented ADD. Note: this is very crude
    s/\\'/''/g;                # Use '' instead of \'
    s/\\"/"/g;                 # Use " instead of \"
    s/\\r\\n/\r\n/g;           # Convert escaped \r\n to literal
    s/\\\\/\\/g;               # Convert escaped \ to literal
    s/ auto_increment//g;      # Remove auto_increment
    s/^[UN]*?LOCK TABLES.*//g; # Remove locking statements
    print;
}
