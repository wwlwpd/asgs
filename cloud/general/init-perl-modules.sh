#!/bin/bash

# unconditionally attempts to install the Perl modules that are required
#for the operation of ASGS.

source ~/perl5/perlbrew/etc/bashrc

if [ ! -e $HOME/perl5/perlbrew/bin/cpanm ]; then
  perlbrew install-cpanm
fi
#cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

echo Installing Perl modules required for ASGS
for module in $(cat ./PERL-MODULES); do
  cpanm install $module || exit 1
done

# interactive (selects "p" option for "pure pure"), skips testing
echo Installing Date::Pcalc using --force and --interactive due to known issue
cpanm --force --interactive Date::Pcalc <<EOF
p
EOF
# crude check for install
perldoc -l Date::Pcalc > /dev/null 2>&1 || exit 1
