#!/bin/bash

# Copyright 2016, 2017 G. Bartsch
# Copyright 2015 Language Technology, Technische Universitaet Darmstadt (author: Benjamin Milde)
# Copyright 2014 QCRI (author: Ahmed Ali)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# adapted from kaldi-tuda-de run.sh
# adapted from wsj's run.sh

#
# adapt our srilm-generated LM for kaldi
#

# remove old lang dir if it exists
rm -rf data/lang

# now start preprocessing with KALDI scripts

if [ -f cmd.sh ]; then
      . cmd.sh; else
         echo "missing cmd.sh"; exit 1;
fi

#Path also sets LC_ALL=C for Kaldi, otherwise you will experience strange (and hard to debug!) bugs. It should be set here, after the python scripts and not at the beginning of this script
if [ -f path.sh ]; then
      . path.sh; else
         echo "missing path.sh"; exit 1;

fi

# echo "Runtime configuration is: nJobs $nJobs, nDecodeJobs $nDecodeJobs. If this is not what you want, edit cmd.sh"

#Make sure that LC_ALL is C for Kaldi, otherwise you will experience strange (and hard to debug!) bugs
export LC_ALL=C

#Prepare phoneme data for Kaldi
# utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
utils/prepare_lang.sh data/local/dict "nspc" data/local/lang data/lang

lmdir=data/local/lm
lang=data/lang_test

# export PATH=$KALDI_ROOT/tools/srilm/bin:$KALDI_ROOT/tools/srilm/bin/i686-m64:$PATH
# export LD_LIBRARY_PATH="$KALDI_ROOT/tools/liblbfgs-1.10/lib/.libs:$LD_LIBRARY_PATH"

rm -rf data/lang_test
cp -r data/lang data/lang_test

echo
echo "creating G.fst..."

cat lm/lm.arpa | utils/find_arpa_oovs.pl $lang/words.txt  > $lmdir/oovs_lm.txt

cat lm/lm.arpa | \
    grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    arpa2fst - | fstprint | \
    utils/remove_oovs.pl $lmdir/oovs_lm.txt | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang/words.txt \
      --osymbols=$lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon > $lang/G.fst

