#!/usr/bin/tclsh
#
# SQLite Cipher
# codec-speedtest.tcl developed by Stephen Lombardo (Zetetic LLC) 
# sjlombardo at zetetic dot net
# http://zetetic.net
# 
# Copyright (c) 2008, ZETETIC LLC
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the ZETETIC LLC nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY ZETETIC LLC ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL ZETETIC LLC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Run this script using TCLSH to do a speed comparison between
# a single version of sqlite running with and without the codec
# based heavily on tools/speetest.tcl in the standard SQLite package
#

# Run a test
#
set cnt 1
proc runtest {title} {
  global cnt
  set sqlfile test$cnt.sql
  set logfile test$cnt.log
  puts "<h2>Test $cnt: $title</h2>"
  incr cnt
  set fd [open $sqlfile r]
  set sql [string trim [read $fd [file size $sqlfile]]]
  close $fd
  set sx [split $sql \n]
  set n [llength $sx]
  if {$n>8} {
    set sql {}
    for {set i 0} {$i<3} {incr i} {append sql [lindex $sx $i]<br>\n}
    append sql  "<i>... [expr {$n-6}] lines omitted</i><br>\n"
    for {set i [expr {$n-3}]} {$i<$n} {incr i} {
      append sql [lindex $sx $i]<br>\n
    }
  } else {
    regsub -all \n [string trim $sql] <br> sql
  }
  puts "<blockquote>"
  puts "$sql"
  puts "</blockquote><table border=0 cellpadding=0 cellspacing=0>"
  set format {<tr><td>%s</td><td align="right">&nbsp;&nbsp;&nbsp;%.3f</td></tr>}
  set delay 10

  exec sync; after $delay;
  set t [time "exec cat perftest0.sql $sqlfile | ./sqlite3 perftest0.db 2>&1" 1]
  set t [expr {[lindex $t 0]/1000000.0}]
  puts [format $format {Config0:} $t]
  exec sync; after $delay;

  set t0 $t;

  set t [time "exec cat perftest1.sql $sqlfile | ./sqlite3 perftest1.db 2>&1" 1]
  set t [expr {[lindex $t 0]/1000000.0}]
  puts [format $format {Config1:} $t]
  exec sync; after $delay;

  set slowdown [expr {(($t - $t0)/$t0)*100.0}]
  puts [format $format {Slowdown:} $slowdown]

  puts "</table>"
}

# Initialize the environment
#

file delete perftest0.db
file delete perftest1.db

expr srand(1)
catch {exec /bin/sh -c {rm -f perftest*.db}}

set fd [open perftest0.sql w]
puts $fd {
}
close $fd

set fd [open perftest1.sql w]
puts $fd {
PRAGMA key='xyzzy';
}
close $fd

exec cat perftest0.sql | ./sqlite3 perftest0.db
exec cat perftest1.sql | ./sqlite3 perftest1.db

set ones {zero one two three four five six seven eight nine
          ten eleven twelve thirteen fourteen fifteen sixteen seventeen
          eighteen nineteen}
set tens {{} ten twenty thirty forty fifty sixty seventy eighty ninety}
proc number_name {n} {
  if {$n>=1000} {
    set txt "[number_name [expr {$n/1000}]] thousand"
    set n [expr {$n%1000}]
  } else {
    set txt {}
  }
  if {$n>=100} {
    append txt " [lindex $::ones [expr {$n/100}]] hundred"
    set n [expr {$n%100}]
  }
  if {$n>=20} {
    append txt " [lindex $::tens [expr {$n/10}]]"
    set n [expr {$n%10}]
  }
  if {$n>0} {
    append txt " [lindex $::ones $n]"
  }
  set txt [string trim $txt]
  if {$txt==""} {set txt zero}
  return $txt
}



set fd [open test$cnt.sql w]
puts $fd "CREATE TABLE t1(a INTEGER, b INTEGER, c VARCHAR(100));"
for {set i 1} {$i<=1000} {incr i} {
  set r [expr {int(rand()*100000)}]
  puts $fd "INSERT INTO t1 VALUES($i,$r,'[number_name $r]');"
}
close $fd
runtest {1000 INSERTs}



set fd [open test$cnt.sql w]
puts $fd "BEGIN;"
puts $fd "CREATE TABLE t2(a INTEGER, b INTEGER, c VARCHAR(100));"
for {set i 1} {$i<=25000} {incr i} {
  set r [expr {int(rand()*500000)}]
  puts $fd "INSERT INTO t2 VALUES($i,$r,'[number_name $r]');"
}
puts $fd "COMMIT;"
close $fd
runtest {25000 INSERTs in a transaction}



set fd [open test$cnt.sql w]
for {set i 0} {$i<100} {incr i} {
  set lwr [expr {$i*100}]
  set upr [expr {($i+10)*100}]
  puts $fd "SELECT count(*), avg(b) FROM t2 WHERE b>=$lwr AND b<$upr;"
}
close $fd
runtest {100 SELECTs without an index}



set fd [open test$cnt.sql w]
for {set i 1} {$i<=100} {incr i} {
  puts $fd "SELECT count(*), avg(b) FROM t2 WHERE c LIKE '%[number_name $i]%';"
}
close $fd
runtest {100 SELECTs on a string comparison}



set fd [open test$cnt.sql w]
puts $fd {CREATE INDEX i2a ON t2(a);}
puts $fd {CREATE INDEX i2b ON t2(b);}
close $fd
runtest {Creating an index}



set fd [open test$cnt.sql w]
for {set i 0} {$i<5000} {incr i} {
  set lwr [expr {$i*100}]
  set upr [expr {($i+1)*100}]
  puts $fd "SELECT count(*), avg(b) FROM t2 WHERE b>=$lwr AND b<$upr;"
}
close $fd
runtest {5000 SELECTs with an index}



set fd [open test$cnt.sql w]
puts $fd "BEGIN;"
for {set i 0} {$i<1000} {incr i} {
  set lwr [expr {$i*10}]
  set upr [expr {($i+1)*10}]
  puts $fd "UPDATE t1 SET b=b*2 WHERE a>=$lwr AND a<$upr;"
}
puts $fd "COMMIT;"
close $fd
runtest {1000 UPDATEs without an index}



set fd [open test$cnt.sql w]
puts $fd "BEGIN;"
for {set i 1} {$i<=25000} {incr i} {
  set r [expr {int(rand()*500000)}]
  puts $fd "UPDATE t2 SET b=$r WHERE a=$i;"
}
puts $fd "COMMIT;"
close $fd
runtest {25000 UPDATEs with an index}


set fd [open test$cnt.sql w]
puts $fd "BEGIN;"
for {set i 1} {$i<=25000} {incr i} {
  set r [expr {int(rand()*500000)}]
  puts $fd "UPDATE t2 SET c='[number_name $r]' WHERE a=$i;"
}
puts $fd "COMMIT;"
close $fd
runtest {25000 text UPDATEs with an index}



set fd [open test$cnt.sql w]
puts $fd "BEGIN;"
puts $fd "INSERT INTO t1 SELECT * FROM t2;"
puts $fd "INSERT INTO t2 SELECT * FROM t1;"
puts $fd "COMMIT;"
close $fd
runtest {INSERTs from a SELECT}



set fd [open test$cnt.sql w]
puts $fd {DELETE FROM t2 WHERE c LIKE '%fifty%';}
close $fd
runtest {DELETE without an index}



set fd [open test$cnt.sql w]
puts $fd {DELETE FROM t2 WHERE a>10 AND a<20000;}
close $fd
runtest {DELETE with an index}



set fd [open test$cnt.sql w]
puts $fd {INSERT INTO t2 SELECT * FROM t1;}
close $fd
runtest {A big INSERT after a big DELETE}



set fd [open test$cnt.sql w]
puts $fd {BEGIN;}
puts $fd {DELETE FROM t1;}
for {set i 1} {$i<=3000} {incr i} {
  set r [expr {int(rand()*100000)}]
  puts $fd "INSERT INTO t1 VALUES($i,$r,'[number_name $r]');"
}
puts $fd {COMMIT;}
close $fd
runtest {A big DELETE followed by many small INSERTs}



set fd [open test$cnt.sql w]
puts $fd {DROP TABLE t1;}
puts $fd {DROP TABLE t2;}
close $fd
runtest {DROP TABLE}

