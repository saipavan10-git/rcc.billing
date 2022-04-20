#!/usr/bin/perl
while (<>){
    if (m/^SET/) { next };
    s/CHARACTER SET \S+ //;    # remove CHARACTER SET mumble
    s/ENGINE=\S+ *//;          # remove ENGINE
    s/DEFAULT CHARSET=\S+ *//; # remove DEFAULT CHARSET
    s/COLLATE [^, ]+//;         # remove COLLATE on column
    s/COLLATE=\S+ *//;         # remove COLLATE on table
    s/COMMENT '.+'//;          # remove COMMENT on column
    s/COMMENT='.+'//;          # remove COMMENT on table 
    s/enum\(.*\)/varchar(255)/;              # replace enum
    if (m/^ALTER TABLE/) { next }; # remove ALTER TABLE
    if (m/^\s*ADD /) { next };     # Remove indented ADD. Note: this is very crude
    if (m/^\s*MODIFY /) { next };  # Remove indented MODIFY. Note: this is very crude
    s/\\'/''/g;                # Use '' instead of \'
    s/\\"/"/g;                 # Use " instead of \"
    s/\\r\\n/\r\n/g;           # Convert escaped \r\n to literal
    s/\\\\/\\/g;               # Convert escaped \ to literal
    s/ auto_increment//gi;      # Remove auto_increment
    s/^[UN]*?LOCK TABLES.*//g; # Remove locking statements
    print;
}
