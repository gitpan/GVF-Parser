package GVF::Utils;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Carp;
use IO::File;

our $VERSION = '1.03';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'file_modifier' => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef',
    reader    => 'file_changes',
    predicate => 'has_modifiers',
    handles   => {
        _find        => 'get',
    },
);

#------------------------------------------------------------------------------
#------------------------------Methods-----------------------------------------
#------------------------------------------------------------------------------

sub _file_splitter {

    my ( $self, $request ) = @_;    

    my $obj_fh;
    if ( ref( $self->file ) ){
        $obj_fh = $self->gvf_file || die "File " .  $self->file . "cannot be opened\n";
    }
    else{
        open ( $obj_fh, "<", $self->file) || die "File " . $self->file . "cannot be opened\n";
    }

    my ( @pragma, @feature_line );
    foreach my $line ( <$obj_fh> ){
        chomp $line;
    
        $line =~ s/^\s+$//g;

        # captures pragma lines.        
        if ($line =~ /^#{1,}/) {
            push @pragma, $line;
        }
        # or feature_line
        else { push @feature_line, $line; }
    }

    if ( $request eq 'pragma') { return \@pragma }
    if ( $request eq 'feature') { return \@feature_line }
    $obj_fh->close;
}

#-----------------------------------------------------------------------------

sub _att_modifer {
    my ( $self, $atts ) = @_;

    my @values = $self->add;
    
    my @atts_list;
    foreach my $i ( @{$atts} ) {
        $i =~ /(.*)=(.*)/;
  
        foreach my $e ( @values) {
            if ($1 eq $e){
                if ( $self->_find('add_attribute1') && $1 eq $self->_find('add_attribute1') ) { $i = "added_attribute1=$2"; }
                if ( $self->_find('add_attribute2') && $1 eq $self->_find('add_attribute2') ) { $i = "added_attribute2=$2"; }
                if ( $self->_find('add_attribute3') && $1 eq $self->_find('add_attribute3') ) { $i = "added_attribute3=$2"; }
                if ( $self->_find('add_attribute4') && $1 eq $self->_find('add_attribute4') ) { $i = "added_attribute4=$2"; }
                if ( $self->_find('add_attribute5') && $1 eq $self->_find('add_attribute5') ) { $i = "added_attribute5=$2"; }
            }
        push @atts_list, $i;
      }
    }
    return(\@atts_list);
}

#-----------------------------------------------------------------------------

sub duplicates {
    my @list = @_;
    
    my %seen;
    my @uniq = grep {! $seen{$_}++ } @list;
    
    return @uniq;
}

#-----------------------------------------------------------------------------
#
#sub value_parse {
#    my ( $self, $line ) = @_;
#    
#    my @items = split /;/, $line;
#    
#    my %h;    
#    foreach my $i (@items) {
#        $i =~ /(.*)=(.*)/g;
#        $h{$1} = $2;
#    }
#    return (\%h);
#}
#=head2 value_parse 
#
#    Title    : value_parse
#    Usage    : $obj->value_parse(\@values)
#    Function : Take arrayref of pragma values seperated by ';'
#               and returns a hashref of key values pair
#               example key=value;value
#    Returns  : Hashref of pragma key-values pairs.
#    
#=cut



#-----------------------------------------------------------------------------

no Moose;
1;
