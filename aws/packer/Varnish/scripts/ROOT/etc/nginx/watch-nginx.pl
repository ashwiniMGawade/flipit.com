#!/usr/bin/perl

@do = `/bin/netstat -anp |/bin/grep 8080|/bin/grep -v LISTEN |/bin/grep ESTABLISHED | /bin/grep tcp | /usr/bin/awk '{print \$5}' | /usr/bin/cut -f 1 -d : | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -n |/usr/bin/awk {'print \$1'}`;

$sum = 0;
foreach $conns (@do)
{
  chomp($conns);
  $sum += $conns;
}

if($sum == 0)
{
  print "Restarting nginx at " . time() . " due to zero established connections.\n";
  $do = `/usr/bin/service nginx restart`;
}
else
{
  print "OK.\n";
}
