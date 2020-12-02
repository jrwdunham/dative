#!/bin/bash

BIRTHDAY="Tue Apr 20 12:00:00 EDT 2012";
BIRTHDAY_TIMESTAMP=1334941200;

today="$(echo `date`)"
todayTimestamp="$(echo `date  +%s`)"

echo ""
echo "____========== Getting the version code for today =============_______"
echo " Birthday: $BIRTHDAY"
echo " Today: $today"
echo " Birthday: $BIRTHDAY_TIMESTAMP "
echo " Today: $todayTimestamp"
echo ""
echo ""

let WEEK_DIFF=`expr $todayTimestamp - $BIRTHDAY_TIMESTAMP`/60/60/24/7 || exit 4;

if [ "$WEEK_DIFF" -gt 208 ]
  then
  YEAR_DIFF=4
  WEEK_DIFF=`expr $WEEK_DIFF - 208`
elif [ "$WEEK_DIFF" -gt 156 ]
  then
  YEAR_DIFF=3
  WEEK_DIFF=`expr $WEEK_DIFF - 156`
elif [ "$WEEK_DIFF" -gt 104 ]
  then
  YEAR_DIFF=2
  WEEK_DIFF=`expr $WEEK_DIFF - 104`
elif [ "$WEEK_DIFF" -gt 52 ]
  then
  YEAR_DIFF=1
  WEEK_DIFF=`expr $WEEK_DIFF - 52`
else
  YEAR_DIFF=0
fi
# NOW=`date +%Y.%m.%d.%H.%M`
MINOR_VERSION=`date +%d.%H.%M`
DAY=`date +%d`

SHORT_VERSION="$YEAR_DIFF.$WEEK_DIFF.$DAY"
version="$YEAR_DIFF.$WEEK_DIFF.$MINOR_VERSION"
echo " Birthday: $BIRTHDAY"
echo " Today: $today"
echo " Years: $YEAR_DIFF"
echo " Weeks: $WEEK_DIFF"
echo "  ->    Version: $version"
echo ""

echo "... setting version on dative package"
sed 's/"version": "[^,]*"/"version": "'$SHORT_VERSION'"/' package.json  > output
mv output package.json

mkdir dist
cp package.json dist/
# echo "... setting Continuous Integration version on dative dist"
# sed "s/\"\(version\": \"[^,]*\)\"/\1.$MINOR_VERSION\"/" dist/package.json  > output
# mv output dist/package.json
# echo $MINOR_VERSION


echo "..... Done."

exit 0;
