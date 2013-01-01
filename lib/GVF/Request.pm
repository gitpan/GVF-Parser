package GVF::Request;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Carp;

our $VERSION = '1.03';

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
    my ( $self, $request ) = @_;
    
    if (! $request ) { die "No request provided for attribute request.\n"; }
    
    my $dbi = $self->get_dbixclass;
    
    my $orig_request = $request;
    $request =~ s/-//g;
    $request =~ s/_//g;
    $request = lc($request);

    # check if search is valid.
    my $attribute_result = $dbi->resultset('Attributes')->get_column("$request");
    if ( ! eval{$attribute_result->next} ) { die "No $orig_request in file\n" } 

    my @return_list;
    while (my $atts = $attribute_result->next) {
        push @return_list, $atts, if $atts;
    }
    $self->set_attribute_request(\@return_list);
    
    if ( $request eq 'varianteffect' ){
        @return_list = $self->tidyVariantEffect(\@return_list);
    }
    
    return wantarray ? @return_list : \@return_list;
}

#-----------------------------------------------------------------------------

sub featureRequest {
    
    my ( $self, $request ) = @_;
    
    my $dbi = $self->get_dbixclass;
    
    if (! $request ) { die "No request provided for feature request.\n"; }
    my $feature_result = $dbi->resultset('Features')->get_column("$request");

    # check if search is valid.
    if ( ! eval{$feature_result->next} ) { die "No $request in file\n" } 

    my @return_list;
    while (my $features = $feature_result->next) {
        push @return_list, $features if $features;
    }
    
    $self->set_feature_request(\@return_list);
    
    return wantarray ? @return_list : \@return_list;
}

#-----------------------------------------------------------------------------

sub sequenceRegions {
    my $self = shift;
    
    if (! $self->findPragma('sequence_region') ) {
        warn "Sequence-region not found in file\n";
    }
    else {
        return $self->findPragma('sequence_region');
    }
}

#-----------------------------------------------------------------------------

sub pragmaRequest {
    my ( $self, $request ) = @_;
    
    if ( ! $request ){ croak "Pragma request[s] not given.\n" }

    my @wanted;
    if ( ref($request) eq 'ARRAY') {
        foreach my $i ( @{$request} ){
            $i =~ s/-/_/g;
            my $value = $self->findPragma($i);
            push @wanted, $value;
        }
        return wantarray ? @wanted : \@wanted;
    }
    else {
        $request =~ s/-/_/g;
        my @request = $self->findPragma($request);    
        return wantarray ? @request : \@request;
    }
}

#-----------------------------------------------------------------------------

sub tidyVariantEffect {
    my ( $self, $line ) = @_;
    
    if ( ref($line) ne 'ARRAY' ) {
        my @line;
        push @line, $line;
        $line = \@line;
    }
    
    my (@varList, %variant);
    foreach my $i ( @{$line} ){
        
        my @effects = split /\,/, $i;
        
        foreach my $e (@effects){
            chomp $e;            
            
            my( $seqVar, $index, $seqFet, $id ) = split /\s/, $e;
            push @varList, $variant{ $seqVar } = {
		sequence_variant => $seqVar,
                index            => $index,
                feature_type     => $seqFet,
                feature_id       => $id,
            };
        }
    }
    return wantarray ? @varList : \@varList;
}

#-----------------------------------------------------------------------------

sub getAllPragmas {
    my $self = shift;
    
    my @pragmas = $self->getPragmas;

    my %pragma;
    foreach my $i (@pragmas){
        chomp $i;
        
        if ( $i->[1] =~ /;/ ){
            my @eachTag = split /;/, $i->[1];
            
            map {
                my ($tag, $value) = split /=/, $_;
                $pragma{ $i->[0] }{ $tag } = $value;
            } @eachTag;
        }
        else {
            $pragma{ $i->[0] } = $i->[1];
        }
    }
    return wantarray ? %pragma : \%pragma;
}

#-----------------------------------------------------------------------------

no Moose;
1;
