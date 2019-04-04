#!/bin/bash

WANT_PERL="perl-5.28.1"
NEED_PERLBREW=1
NEED_PERL=1
if [ -n '$(which perlbrew)' ]; then
  echo perlbrew installed ... looking for ${WANT_PERL}
  NEED_PERLBREW=0
  if [ -n '$(perlbrew list | grep "${WANT_PERL}")' ]; then
    echo found ${WANT_PERL}..
    NEED_PERL=0
  fi
fi

if [ 1 == ${NEED_PERLBREW} ]; then
  curl -L https://install.perlbrew.pl | bash              && \
  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.profile && \
  . ~/.profile
fi
if [ 1 == ${NEED_PERL} ]; then
  perlbrew install ${WANT_PERL}
fi
if [ -n '$(which perl | grep "perlbrew/perls/${WANT_PERL}")' ]; then
which perl | grep "perlbrew/perls/${WANT_PERL}"
  echo looks like perlbrew\'s \"${WANT_PERL}\" is already in use
else
  perlbrew ${WANT_PERL}
  which perl
  perl -v
fi

if [ -z '$(which cpanm | grep "perlbrew/bin/cpanm")' ]; then
  perlbrew install-cpanm
else
  echo cpanm is already installed
fi

for m in $(cat ./MANIFEST); do
  if [ -n "$(perldoc -l $m 2>&1 | grep 'No documentation' )" ]; then
    echo $m is not installed
    cpanm install $m
  else
    echo Found Perl module, $m
  fi 
done
