#!/bin/bash

sqlite3 -batch nowire.db << EOF

CREATE TABLE nowire_otp (user TEXT,secret TEXT);

EOF
