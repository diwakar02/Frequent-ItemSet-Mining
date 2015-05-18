 
/****************************************************** 
** Team20
** Project - Project2
** Team Members:-
** Stevie Marie Hawkins - sdh65@drexel.edu
** Diwakar Sharma - ds3222@drexel.edu
** Filename: team_20.pig
Description: Apriori implementation in PIG LATIN
******************************************************/

--Deleting the output directory for cleaning purposes
fs -rm -r $output

--Loading input files
A = LOAD '$input' USING PigStorage('\t') AS (lid: chararray, item: int) ;
A1 = LOAD '$input' USING PigStorage('\t') AS (lid: chararray, item: int) ;
A2 = LOAD '$input' USING PigStorage('\t') AS (lid: chararray, item: int) ;

--groups by each item
B = GROUP A BY item ;
B1 = GROUP A1 BY item ;
B2 = GROUP A2 BY item;

--items and frequencies
I_F = FOREACH B GENERATE group, (long)COUNT(A) AS freq;
I_F1 = FOREACH B1 GENERATE group, (long)COUNT(A1) AS freq1;
I_F2 = FOREACH B2 GENERATE group, (long)COUNT(A2) AS freq2;

--filter out items with frequencies that are less than the support
FILTERED_items = FILTER I_F BY (freq >= $support);
FILTERED_items1 = FILTER I_F1 BY (freq1 >= $support);
FILTERED_items2 = FILTER I_F2 BY (freq2 >= $support);

--Joins DB to itself
C = JOIN A by lid, A1 by lid;
C1 = JOIN A by lid, A1 by lid, A2 by lid;


--Removes the lids
D = FOREACH C GENERATE A::item AS leftside, A1::item AS rightside;
D1 = FOREACH C1 GENERATE A::item AS leftside, A1::item AS middleside, A2::item AS rightside;

--Keep the tuples that can be used
E = FILTER D BY leftside < rightside;
E2 = FILTER D1 BY (leftside < middleside AND middleside < rightside);
--E2 = FILTER E1 BY middleside < rightside;

--Making 2-itemset Candidates out of 1-itemsets
one = foreach FILTERED_items GENERATE $0;
one1 = foreach FILTERED_items1 GENERATE $0;
two_itemsets = CROSS one,one1;
filter2s = FILTER two_itemsets BY one::group < one1::group;
two_items = FILTER filter2s BY one::group != one1::group;
two_item = FOREACH two_items GENERATE one::group as lefty, one1::group as righty;

--Finding the 2-itemsets and their frequencies
TEST = CROSS E, two_item;
TEST1 = FILTER TEST by E::leftside == two_item::lefty;
TEST2 = FILTER TEST1 by E::rightside == two_item::righty;
TEST3 = GROUP TEST2 by (E::leftside,E::rightside);
--DUMP TEST3;

two_itemsets = FOREACH TEST3 GENERATE group as pairs:(lside:int,rside:int), (long)COUNT (TEST2) as frequency;

--2-itemsets that meet the support
X = FILTER two_itemsets by frequency >= $support;
DUMP X;

--Making 3-itemset candidates out of 2-itemsets
one2 = foreach FILTERED_items2 GENERATE $0;
three_itemsets = CROSS one,one1,one2;
filter3s = FILTER three_itemsets BY one::group < one1::group AND one1::group < one2::group;
three_items = FILTER filter3s BY one::group != one1::group AND one1::group != one2::group;
three_item = FOREACH three_items GENERATE one::group as lefty, one1::group as middle, one2::group as righty;

--Finding the 3-itemset and their frequencies
TEST4 = CROSS E2, three_item;
TEST5 = FILTER TEST4 by E2::leftside == three_item::lefty;
TEST6 = FILTER TEST5 by E2::middleside == three_item::middle;
TEST7 = FILTER TEST6 by E2::rightside == three_item::righty;
TEST8 = GROUP TEST7 by (E2::leftside,E2::middleside,E2::rightside);

three_itemsets = FOREACH TEST8 GENERATE group as triple:(lside:int,mside:int,rside:int), (long)COUNT(TEST7) as frequency;

--3-itemsets that meet the support
Y = FILTER three_itemsets by frequency >=$support;
DUMP Y;

--Storing 2-itemsets in output file X
STORE X INTO '$output/X';

--Storing 3-itemsets in output file X
STORE Y INTO '$output/Y';