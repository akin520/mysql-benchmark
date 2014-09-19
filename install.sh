#!/bin/bash

echo "install dbt2..."
cd dbt2-0.40/
./configure --with-mysql
make -j
cd ..

echo "install fio..."
cd fio-2.1.12/
./configure
make -j
cd ..

echo "install sysbench..."
cd sysbench/
./configure --with-mysql
make -j
cd ..

echo "echo tpcc-mysql..."
cd tpcc-mysql/src
make all
cd ../../



