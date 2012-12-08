use inc::Module::Install;

name     'GVF-Parser';
all_from 'lib/GVF/Parser.pm';
author   q{Shawn Rynearson <shawn.rynerson@gmail.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

