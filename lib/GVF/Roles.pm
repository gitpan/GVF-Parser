package GVF::Roles;
use Moose::Role;

our $VERSION = '0.1';

with ('GVF::Utils', 'GVF::Storage::SQLite_GVF', 'GVF::Request');

1;
