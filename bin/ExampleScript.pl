#!/usr/bin/perl
use warnings;
use strict;
use lib '/Users/shawn/GVF-Parser/lib';
use GVF::Parser;


my $gvf = $ARGV[0] || die "Please enter gvf/db file\n";

# adding attributes to the database.
# this will allow you to add desired unsupported attribute tags to the database.
# they are accessed via hash tag values,
# currently five extra tag are allowed.
# Example: 'add_attribute1'
 
my $file_adds = {
    add_attribute1 => 'hgmd_disease',
    add_attribute2 => 'hgmd_location',
};

my $obj = GVF::Parser->new(
    file           => $gvf,        # required
    file_modifier  => $file_adds,  # pass the unsupported tags to GVF::Parser
);

# pass the request to set values.
# pragmas are stored in the object
# features are use to build sqlite database

$obj->pragmas;
$obj->features;

#---------------------------------------------------------

# Example one
# DBIx::Class approach.

# connection to db via DBIx::Class object
my $dbix       = $obj->get_dbixclass;

# use DBIx::Class as standard from this point.
my $features   = $dbix->resultset('Features');
my $attributes = $dbix->resultset('Attributes');

# create a hash of all the feature items wanted
# using feature table primary key
my %feats;
while (my $f = $features->next){
    $feats{ $f->id } = {
        type  => $f->type,
        start => $f->start,
        end   => $f->end,
    };
}

# use attribure resultset to access desired parts of file
# using attributes foreign_key to maintain relationship with features
while (my $a = $attributes->next ){
    if ( $feats{ $a->features_id } ){
        
        my $varInfo = $obj->tidyVariantEffect( $a->varianteffect);

        foreach my $i ( @{$varInfo} ){
            if ( $i->{sequence_variant} eq 'frameshift_variant' ) {
                print $i->{'feature_type'}, "\t";
                print $i->{'feature_id'}, "\t";
                print $feats{ $a->features_id }->{'start'}, "\t";
                print $feats{ $a->features_id }->{'type'}, "\t";
                print $a->referenceseq, "\t";
                print $a->variantseq, "\n";
            }
        }
    }
}

#------------------------------------------------------------------------------

# Example two.
# accessing data in parts

# Example of using request methods.
my $feats   = $obj->featureRequest('seqid');
my $atts    = $obj->attributeRequest('Variant_effect');
my @regions = $obj->sequenceRegions;

# pragma can be requested with list or individually.
my @wantList  = qw/ multi-individual population data-source /;
my $foundList = $obj->pragmaRequest(\@wantList);
my $foundMore = $obj->pragmaRequest('data-source');
my $foundprag = $obj->getAllPragmas;
my @foundIndv = $obj->pragmaRequest('data-source');

#------------------------------------------------------------------------------
