package GVF::Parser;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '1.03';

# master list of roles.
with 'GVF::Roles';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'file' => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'file',
    #required => 1,
);

has 'pragmas' => (
    traits     => ['Hash'],
    is         => 'rw',
    isa        => 'HashRef',
    writer     => 'set_pragmas',
    lazy_build => 1,
    handles    => {
        findPragma => 'get',
        pragmaKeys => 'keys',
        getPragmas => 'kv',
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
    my @regions;
    foreach my $i( @{$pragma_line} ) {
        chomp $i;
        
        my ($tag, $value) = $i =~ /##(\S+)\s?(.*)$/g;
        $tag =~ s/\-/\_/g;
        
        if ( $tag eq 'sequence_region' ){
            push @{$p{$tag}}, $value;
        }
        else {
            $p{$tag} = $value;
        }
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

=head1 DESCRIPTION

Takes a given GVF file and creates a DBIx::Class sqlite3 database.  In addition to having the ability to retrive sections of pragma and feature data directly via methods provided.

This module is not intended to provide a method to do complex analysis with GVF data, but to provide a manner to parse desired data out or in cordonation with a user pipeline.

GVF::Parser partitions GVF files into pragma and feature data, and the feature data is further split into features and attributes.  Pragma data is stored in object, and can be requested using the provided methods.  Attribute information is stored/saved in a sqlite datafile, and can be accessed using the attributeRequest method, or more via DBIx::Class.

This parser looks at feature line data in the following way:

                                 features                                                                attributes
|--------------------------------------------------------------------------------------||---------------------------------------|
chr16   samtools        SNV     49291141        49291141        .       +       .        ID=ID_1;Variant_seq=A,G;Reference_seq=G;

featureRequest calls will access the first eight elements of a feature line, and attributeRequest calls encompass the eighth column.


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

=head1 SUBROUTINES/METHODS

=head2 new

    Title    : new
    Usage    : $obj = GVF::Parser->new()
    Function : Builds GVF::Parser object.
    Returns  : GVF::Parser object

 Options
    file (required):
        Accepts scalar, command argument or path to GVF file.
    file_modifier (optional):
        Accepts hash ref of add_attribute.
        This option allow users to include attrbute key[s] not currently
        supported in the GVF spec.  Currently five additional attributes are allowed.

 Example:
    my $mod_hashref = {
        add_attribute1 => 'hgmd_disease',
    };

    my $obj = GVF::Parser->new(
        file           => $ARGV[0],
        file_modifier  => $mod_hashref,
    );

=cut

=head2 pragmas

    Title    : pragmas
    Usage    : $obj->pragmas
    Function : Build pragma data into the object.
    Returns  : None.

Pragma data is stored in object and requested via pragmaRequest, getAllPragmas.  If this method is not used the object will not build pragma data.

=cut

=head2 features

    Title    : features
    Usage    : $obj->features
    Function : Builds a SQLite3 database of feature values.
    Returns  : None

This will populate a sqlite3 database creating a features and attributes table, parts of which can be accessed via featureRequest or attributeRequest.
If this method is not used the object will not build a feature database.

=cut

=head2 getAllPragmas

    Title    : getAllPragmas
    Usage    : $obj->getAllPragmas
    Function : Retrieves a hash of all pragmas and values in a given file.
    Returns  : hash or (reference) of "pragma => value".

Simple pragmas values are returned as simple key values pair e.g. gvf_version => '1.06'.  Structured pragma are returned as hash of hash e.g. data_source => { 'Type' => 'SNV' }.

=cut

=head2 pragmaRequest

    Title    : pragmaRequest
    Usage    : $wanted = $obj->pragmaRequest($request) or
               $wanted = $obj->pragmaRequest($arrayref)
    Function : Capture requested pragma term
    Returns  : Array or (reference) of requested pragma term in its original form.  Structured pragmas are not further broken down.

This method allow you to request only a specfic pragma term, or a list of terms passed as an array reference.  All are returned in original form.
 
=cut

=head2 sequenceRegions

    Title    : sequenceRegions
    Usage    : $regions = $obj->sequenceRegions
    Function : Captures all sequence regions from a GVF file.
    Returns  : Arrayref of all sequence regions.

=cut

=head2 featureRequest

    Title    : featureRequest
    Usage    : $features = $obj->featureRequest('seqid');
    Function : Caputre requested feature types.
    Returns  : Returns array or (reference) of requested feature.

=cut

=head2 attributeRequest

    Title    : attributeRequest
    Usage    : $attributes = $obj->attributeRequest('reference_seq');
    Function : Caputre requested attribute type.
    Returns  : Returns array or (reference) of requested attribute.
  
=cut

=head2 tidyVariantEffect

    Title    : tidyVariantEffect
    Usage    : $effect = $obj->tidyVariantEffect( "variant_effect line" ); 
    Function : Will take individual Variant_effect from feature line and return
               line as hashref of each space delimited field.
    Returns  : array of hashref or (arrayref of hashref) of variant effects. 
    Args     : Individual Variant_effect line.

This method is only designed to work with an individual Variant_effect from a feature line.  It's not needed when using attributeRequest as that method preforms the tidying for you.

Example of method return structure:
 [
    {
        feature_id         "CM990001",
        feature_type       "mRNA",
        index              0,
        sequence_variant   "coding_sequence_variant"
    },
 ]

The hashref's keys will always be as the example shows.  Please see "Example one DBIx::Class approach for individual usage example.

=cut

=head2 get_dbixclass

    Title    : get_dbixclass
    Usage    : $obj->get_dbixclass
    Function : Handle used to connect to DBIx::Class
    Returns  : DBIx::Class object

When assigning resultset the sqlite3 column names for features are the first eight columns of a feature line, and attribute columns are the allow GVF column names, lowercased with no underscores, e.g. referencecodon.
Also allow are the five "added_attribute1" which can be added at object construction, and feature_id which is the foreign key to the feature table.

=cut

=head1 AUTHOR

Please contact me with any issue, method ideas/improvments or documentation matters. 

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

This module would not be complete with out acknowledging all the help I've had from the SO community, special thanks to Barry Moore for ideas and guidance.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shawn Rynearson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
