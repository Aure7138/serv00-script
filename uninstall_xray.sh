#!/bin/bash

pkill -f "./xray run -config config.json" > /dev/null 2>&1
rm -rf ~/xray > /dev/null 2>&1