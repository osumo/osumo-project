#! /usr/bin/env bash

result=0

which mongod &> /dev/null
x=$?
if ((x!=0)) ; then
  echo "Missing MongoDB"
  result=1
fi

which Rscript &> /dev/null
x=$?
if ((x!=0)) ; then
  echo "Missing Rscript"
  result=1
else
  for mod in shiny jsonlite pheatmap survival igraph cccd ; do
    Rscript --slave --no-save --no-restore-history -e "
      if(!('$mod' %in% installed.packages())) { stop() }" &> /dev/null
    x=$?

    if ((x!=0)) ; then
      echo "Missing R Library $mod"
      result=1
    fi
  done
fi

which python &> /dev/null
x=$?
if ((x!=0)) ; then
  echo "Missing Python"
  result=1
fi

which virtualenv &> /dev/null
x=$?
if ((x!=0)) ; then
  echo "Missing Python virtualenv"
  result=1
fi

which node &> /dev/null
x=$?
if ((x!=0)) ; then
  echo "Missing Nodejs"
  result=1
fi


which npm &> /dev/null
x=$?
if ((x!=0)) ; then
  echo "Missing NPM"
  result=1
fi

exit $result

