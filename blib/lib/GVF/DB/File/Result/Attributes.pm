package GVF::DB::File::Result::Attributes;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

our $VERSION = '0.1';

__PACKAGE__->table('ATTRIBUTES');

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "attributeid",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "alias",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "dbxref",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "variantseq",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "referenceseq",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "variantreads",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "totalreads",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "zygosity",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "variantfreq",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "varianteffect",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "startrange",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "endrange",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "phased",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "genotype",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "individual",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "variantcodon",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "referencecodon",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "variantaa",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "referenceaa",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "breakpointdetail",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "sequencecontext",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "added_attribute1",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "added_attribute2",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "added_attribute3",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "added_attribute4",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "added_attribute5",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "features_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);


__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    "feature",
    'GVF::DB::File::Result::Features',
    { id => "features_id" },
);

1;
