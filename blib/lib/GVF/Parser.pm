package GVF::Parser;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.1';

# master list of roles.
with 'GVF::Roles';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'file' => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'file',
    required => 1,
);

has 'pragmas' => (
    traits     => ['Hash'],
    is         => 'rw',
    isa        => 'HashRef',
    writer     => 'set_pragmas',
    lazy_build => 1,
    handles    => {
        getPragma    => 'get',
        pragmaKeys   => 'keys',
        pragmaValues => 'values',
    },
);

around 'features' => sub {
    my ( $orig, $self ) = @_;
    my $dbfile = $self->dbfile;
    
    if ( -e $dbfile ){
        return $dbfile;
    }
    else {
        $self->$orig;
    }
};

#------------------------------------------------------------------------------
#------------------------------Methods-----------------------------------------
#------------------------------------------------------------------------------

sub _build_pragmas {

    my $self = shift;
    
    # grab only pragma lines
    my $pragma_line = $self->_file_splitter('pragma');
    warn "File contains no pragmas\n" if ! $pragma_line;
        
    my %p;
    foreach my $i( @{$pragma_line} ) {
        chomp $i;
        
        my ($tag, $value) = $i =~ /##(\S+)\s?(.*)$/g;
        $tag =~ s/\-/\_/g;
        $p{$tag} = $value;
    }
    $self->set_pragmas(\%p);
}

#------------------------------------------------------------------------------

sub features {
    
    my $self = shift;
    my $feature_line = $self->_file_splitter('feature');

    my ( @return_list );
    foreach my $lines( @$feature_line ) {
        chomp $lines;
        
        my ($seq_id, $source, $type, $start, $end, $score, $strand, $phase, $attribute) = split(/\t/, $lines);
        my @attributes_list = split(/\;/, $attribute) if $attribute;

        # set to modify database if user needs to add attributes.
        my $attributes_list = $self->_att_modifer(\@attributes_list) if $self->has_modifiers;
        @attributes_list = @$attributes_list if $self->has_modifiers; 
        
        my %atts;    
        foreach my $attributes (@attributes_list) {
            $attributes =~ /(.*)=(.*)/g;
            $atts{$1} = $2;
        }

        my $feature = {
            seqid     => $seq_id,
            source    => $source,
            type      => $type,
            start     => $start,
            end       => $end,
            score     => $score,
            strand    => $strand,
            phase     => $phase,
            attribute => {
                %atts
            },
        };
        push @return_list, $feature;
    }
    # send data to db.
    $self->database_add_features(\@return_list);
}

#------------------------------------------------------------------------------

no Moose;
1;

__END__

=head1 NAME

GVF::Parser - A parser for Genome Variation Format files.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use GVF::Parser;

	# Add unsupported attributes to the database. Currently five extra tags are allowed

	# Example:
	my $unsupported = {
	    add_attribute1 => 'hgmd_disease',
	    add_attribute2 => 'hgmd_location',
	};

	my $obj = GVF::Parser->new(
	    file           => $gvf,          # required
	    file_modifier  => $unsupported,  # pass the unsupported tags to GVF::Parser
	);

	# pragmas are stored in the object
	# features are use to build sqlite database

	$obj->pragmas;
	$obj->features;

	#---------------------------------------------------------

	# Example one
	# DBIx::Class approach.

	# connection to db via DBIx::Class object
	my $dbi = $obj->get_dbixclass;

	# a simple example using DBIx::Class.
	my $features   = $dbi->resultset('Features');
	my $attributes = $dbi->resultset('Attributes');

	# create a hash of all the feature items wanted
	# using feature table primary key
	my %feats;
	while (my $f = $features->next) {
	    $feats{ $f->id } = {
		type  => $f->type,
		start => $f->start,
		end   => $f->end,
	    };
	}

	# use attribure resultset to access desired parts of file
	# using attributes foreign_key to maintain relationship with features
	while (my $i = $attributes->next ){
	    if ( $feats{ $i->features_id } ){
		my $varInfo = $obj->effectHash( $i->varianteffect );

		if ( $varInfo->{'three_prime_UTR_variant'}) {
			print $varInfo->{'three_prime_UTR_variant'}->{'feature_type'}, "\t";
			print $varInfo->{'three_prime_UTR_variant'}->{'feature'}, "\t";
			print $feats{ $i->features_id }->{'start'}, "\t";
			print $feats{ $i->features_id }->{'type'}, "\t";
			print $i->referenceseq, "\t";
			print $i->variantseq, "\n";
		}
	    }
	}

	#------------------------------------------------------------------------------

	# Example two.
	# accessing data in parts

	# Example of using request methods.
	my @feats   = $obj->featureRequest('seqid', 'uniq');
	my @atts    = $obj->attributeRequest('Variant_effect');
	my $regions = $obj->sequenceRegions;

	# pragma can be requested with list or individually.
	my @wantList  = qw/ multi-individual population  /;
	my $foundList = $obj->pragmaRequest(\@list);
	my $foundIndv = $obj->pragmaRequest('gvf-version');

	#------------------------------------------------------------------------------

=head1 DESCRIPTION

Takes a given GVF file and creates a DBIx::Class sqlite3 database.  In addition to having the ability to retrive sections of pragma and feature data directly via methods provided.

GVF::Parser partitions GVF files into pragma and feature data, and the feature data is further split into features and attributes.  Pragma data is stored in object, and can be requested using the pragmaRequest method.  Attribute information is stored/saved in a sqlite datafile, and can be accessed using the attributeRequest method, or more preferably via DBIx::Class requestset

=head1 SUBROUTINES/METHODS


=head2 pragmas

    Title    : pragmas
    Usage    : $obj->pragmas
    Returns  : None.

 Pragma data is stored in object and requested via <L<https://metacpan.org/module/GVF::Parser#pragmaRequest> or <L<https://metacpan.org/module/GVF::Parser#getPragma>

=cut

=head2 features

    Title    : features
    Usage    : $obj->features
    Function : Builds a SQLite3 database of feature values.
    Returns  : None

 This will populate a sqlite3 database creating a features and attributes table, parts of which can be accessed via <L<https://metacpan.org/module/GVF::Parser#featureRequest> or <L<https://metacpan.org/module/GVF::Parser#attributeRequest>

=cut

=head2 getPragma

    Title    : getPragma
    Usage    : $obj->getPragmas($pragma)
    Function : Allow you to search for a specific pragma.
    Returns  : requested pragma

 Allows you to search for a single pragma key.  <L<https://metacpan.org/module/GVF::Parser#pragmaRequest> offers more functionality.

=cut

=head2 pragmaKeys

    Title    : pragmaKeys
    Usage    : $obj->pragmaKeys
    Function : Grabs a list of all pragma keys in a given file
    Returns  : Array of all pragma keys

=cut

=head2 pragmaValues

    Title    : pragmaValues
    Usage    : $obj->pragmaValues
    Function : Grabs a list of all pragma values in a given file
    Returns  : Array of all pragma values

=cut

=head2 pragmaRequest

    Title    : pragmaRequest
    Usage    : $wanted = $obj->pragmaRequest($request) or
               $wanted = $obj->pragmaRequest(\@arrayref)
    Function : Capture requested simple pragma term
    Returns  : Single request returns arrayref of value.
               Passing list returns arrayref of all values.

=cut

=head2 sequenceRegions

    Title    : sequenceRegions
    Usage    : $regions = $obj->sequenceRegions
    Function : Capture all sequence regions from a GVF file.
    Returns  : Arrayref of all sequence regions.

=cut

=head2 featureRequest

    Title    : featureRequest
    Usage    : @features = $obj->featureRequest('seqid');
               @features = $obj->featureRequest('seqid', 'uniq');
    Function : Caputre requested feature types
    Returns  : Returns array of requested features or,
               returns array of uniq features of requested type

=cut

=head2 attributeRequest

    Title    : attributeRequest
    Usage    : @attributes = $obj->attributeRequest('reference_seq');
               $attributes = $obj->attributeRequest('reference_seq', 'uniq');
    Function : Caputre requested attribute type.
    Returns  : Returns array of requested attribute types, or
               returns array of uniq attributes of requested type
  
=cut

=head2 tidyVariantEffect

    Title    : tidyVariantEffect
    Usage    : $wanted = $obj->tidyVariantEffect( "variant_effect line" ); 
    Function : Will take individual Variant_effect line and return  
               hashref of each feature type.
    Returns  : Hashref of Variant_effect. 
    Args     : Individual Variant_effect line.

 Example  :
       From DBIx::Class resultset:
       my $varInfo = $obj->tidyVariantEffect( $result->varianteffect );
       
 Results:
 $_ = {
          'coding_sequence_variant' => {
                                         'feature_type' => 'mRNA',
                                         'index' => '0',
                                         'feature_id' => 'NM_000271'
                                       },
          'frameshift_variant' => {
                                    'feature_type' => 'mRNA',
                                    'index' => '0',
                                    'feature_id' => 'NM_000271'
                                  },
          'gene_variant' => {
                              'feature_type' => 'gene',
                              'index' => '0',
                              'feature_id' => 'NPC1'
                            }
        };

=cut

=head2 get_dbixclass

    Title    : get_dbixclass
    Usage    : $obj->get_dbixclass
    Function : Handle, used to connect to DBIx::Class
    Returns  : DBIx::Class object

=cut


=head1 AUTHOR

Shawn Rynearson, C<< <shawn.rynerson at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gvf-parser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GVF-Parser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

    perldoc GVF::Parser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GVF-Parser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GVF-Parser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GVF-Parser>

=item * Search CPAN

L<http://search.cpan.org/dist/GVF-Parser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shawn Rynearson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
