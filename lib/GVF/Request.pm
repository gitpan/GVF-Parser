package GVF::Request;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Carp;

our $VERSION = '0.1';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'feature_request' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    writer    => 'set_feature_request',
    handles   => {
        _clean_features => 'uniq',
    },
);

has 'attribute_request' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    writer    => 'set_attribute_request',
    handles   => {
        _clean_attributes => 'uniq',
    },
);

#------------------------------------------------------------------------------
#------------------------------Methods-----------------------------------------
#------------------------------------------------------------------------------

sub attributeRequest {
    
    my ( $self, $request, $uniq ) = @_;
    
    my $dbi = $self->get_dbixclass;
    my $orig_request = $request;
    $request =~ s/-//g;
    $request =~ s/_//g;
    $request = lc($request);
    
    if (! $request ) { print "no request provided...skipping\n"; }
    my $attribute_result = $dbi->resultset('Attributes')->get_column("$request");
    
    # check if search is valid.
    if ( ! eval{$attribute_result->next} ) { die "No $orig_request in file\n" } 
    
    my @return_list;
    while (my $atts = $attribute_result->next) {
        push @return_list, $atts, if $atts;
    }
    $self->set_attribute_request(\@return_list);
    
    if ( $uniq ) { return $self->_clean_attributes; } # returns array.
    else { return @return_list; } # returns array

}
#-----------------------------------------------------------------------------

sub featureRequest {
    
    my ( $self, $request, $clean ) = @_;
    
    my $dbi = $self->get_dbixclass;
    
    if (! $request ) { print "no request provided...skipping\n"; }
    my $feature_result = $dbi->resultset('Features')->get_column("$request");

    # check if search is valid.
    if ( ! eval{$feature_result->next} ) { die "No $request in file\n" } 

    my @return_list;
    while (my $features = $feature_result->next) {
        push @return_list, $features if $features;
    }
    
    $self->set_feature_request(\@return_list);
    
    if ( $clean ) { return $self->_clean_features; } # returns array.
    else { return @return_list; } # returns array.
}

#-----------------------------------------------------------------------------

sub sequenceRegions {
    my $self = shift;
    return $self->getPragmas('sequence_region');
}

#-----------------------------------------------------------------------------

sub pragmaRequest {
    my ( $self, $request ) = @_;
    
    if ( ! $request ){ croak "Pragma term request not given.\n" }

    my @wanted;
    if ( ref($request) eq 'ARRAY') {
        foreach my $i ( @{$request} ){
            $i =~ s/-/_/g;
            my $value = $self->getPragmas($i);
            push @wanted, $value;
        }
        return \@wanted;
    }
    else {
        $request =~ s/-/_/g;
        return $self->getPragmas($request);
    }
}

#-----------------------------------------------------------------------------

sub effectHash {
    my ( $self, $line ) = @_;
  
    if ( ! $line ) { return }

    my @single = split /\,/, $line;
    
    my %variant;
    foreach my $i ( @single ){
        my @type = split /\s/, $i;

	my @featList;
	if (scalar @type > 4){ @featList = splice @type, 3, -1 }
	else { @featList = $type[3] }

	my $typeList = join(' ', @featList);

        $variant{ $type[0] } = {
            index        => $type[1],
            feature      => $type[2],
            feature_type => $typeList,
	    
        };
    }
    return \%variant;
}


#-----------------------------------------------------------------------------

=head2 attributeRequest

    Title    : attributeRequest
    Usage    : @attributes = $obj->attributeRequest('referenceseq');
               @attributes = $obj->attributeRequest('referenceseq', 'uniq');
    Function : Caputre requested attribute type.
    Returns  : Returns array of requested attribute types, or
              returns array of uniq attributes

=cut

=head2 featureRequest

    Title    : featureRequest
    Usage    : @features = $obj->featureRequest('seqid');
               @features = $obj->featureRequest('seqid', 'uniq');
    Function : Caputre requested feature types
    Returns  : Returns array of requested features or,
              returns array of uniq features.

=cut

=head2 sequenceRegions

    Title    : sequence_regions
    Usage    : $regions = $obj->sequence_regions
    Function : Capture all sequence regions from a GVF file.
    Returns  : Arrayref of all sequence regions.

=cut

=head2 pragmaRequest

    Title    : pragmaRequest
    Usage    : $wanted = $obj->pragmaRequest($request) or
              $wanted = $obj->pragmaRequest(\@arrayref)
    Function : Capture requested simple pragma term
    Returns  : Single request returns arrayref of value.
              Passing list returns arrayref of all values.
    Args     : simple pragma ($request)

=cut

=head2 effectHash

    Title    : effectHash
    Usage    : $wanted = $obj->effectHash( varianteffect line ); 
    Function : Will take individual Variant_effect line and return  
	      hashref of each feature type.
    Returns  : Hashref of Variant_effect. 
    Args     : Individual Variant_effect line.

    Example  :
	   From DBIx::Class resultset:
	   my $varInfo = $obj->effectHash( $result->varianteffect );
	   
    Result   :
	$_ = {
          'transcript_variant' => {
                                    'feature' => 'transcript',
                                    'index' => '0',
                                    'feature_type' => 'CD984159'
                                  },
          'coding_sequence_variant' => {
                                    'feature' => 'mRNA',
                                    'index' => '0',
                                    'feature_type' => 'CD984159'
                                  },
          'gene_variant' => {
                                    'feature' => 'gene',
                                    'index' => '0',
                                    'feature_type' => 'A2M'
                                  }
             };
=cut

1;

