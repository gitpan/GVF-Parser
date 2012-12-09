package GVF::DB::File::Result::Features;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

our $VERSION = '0.1';

__PACKAGE__->table('FEATURES');

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "seqid",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "source",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "start",
  { data_type => "integer", is_nullable => 0 },
  "end",
  { data_type => "integer", is_nullable => 0 },
  "score",
  { data_type => "float", is_nullable => 1 },
  "strand",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);
 
# set the primary key
__PACKAGE__->set_primary_key('id');


# set relationships to other tables.
__PACKAGE__->has_many(
    'attributes' =>
    'GVF::DB::File::Result::Attributes',
    { "foreign.features_id" => "self.id" },
);


1;
