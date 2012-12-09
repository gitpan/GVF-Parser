package GVF::Roles;
use Moose::Role;

our $VERSION = '1.03';

with ('GVF::Utils', 'GVF::Storage::SQLite_GVF', 'GVF::Request');

no Moose;
1;
