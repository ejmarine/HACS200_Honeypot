warning: in the working copy of 'clean.sh', LF will be replaced by CRLF the next time Git touches it
[1mdiff --git a/clean.sh b/clean.sh[m
[1mindex 50562d4..e4f77f6 100644[m
[1m--- a/clean.sh[m
[1m+++ b/clean.sh[m
[36m@@ -1,20 +1,20 @@[m
 #!/bin/bash[m
 [m
[31m-input -m "Are you sure you want to clean the logs? This will delete all logs and data_zips"[m
[32m+[m[32mread -p "Are you sure you want to clean the logs? This will delete all logs and data_zips" input[m
 [m
 if [ "$input" != "y" ]; then[m
     echo "Exiting..."[m
     exit 1[m
 fi[m
 [m
[31m-input -m "Are you sure you ABSOLUTELY SURE YOU WANT TO DELETE ALL LOGS AND DATA_ZIPS? This will delete all logs and data_zips"[m
[32m+[m[32mread -p "Are you sure you ABSOLUTELY SURE YOU WANT TO DELETE ALL LOGS AND DATA_ZIPS? This will delete all logs and data_zips" input[m
 [m
 if [ "$input" != "y" ]; then[m
     echo "Exiting..."[m
     exit 1[m
 fi[m
 [m
[31m-input -m "FINAL WARNING"[m
[32m+[m[32mread -p "FINAL WARNING" input[m
 [m
 if [ "$input" != "y" ]; then[m
     echo "Exiting..."[m
