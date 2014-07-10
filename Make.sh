#!/bin/bash
coffee --compile --output lib/ src/
node generate.js
node test.js