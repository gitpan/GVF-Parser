package GVF::Storage::SQLite_GVF;
use Moose::Role;
use Moose::Util::TypeConstraints;
use GVF::DB::File;
use Carp;
use DBI;

our $VERSION = '1.04';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'dbh' => (
  is         => 'rw',
  isa        => 'Object',
  writer     => '_set_dbh',
  reader     => 'dbh',
  lazy_build => 1,
);

has 'dbfile' => (
  is         => 'rw',
  isa        => 'Str',
  writer     => '_set_dbfile',
  reader     => 'dbfile',
  lazy_build => 1,
);

has 'dbixclass' => (
  is         => 'rw',
  isa	     => 'Object',
  writer     => '_set_dbixclass',
  reader     => 'get_dbixclass',
  lazy_build => 1,
);

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _build_dbfile {
  
  my $self = shift;

  my $dbfile = $self->file;
  $dbfile =~ s/(.*).gvf/$1.sqlite/g;
  
  $self->_set_dbfile($dbfile);
}

#-----------------------------------------------------------------------------

sub _build_dbh {

  my $self = shift;
  
  my $dbfile = $self->dbfile;

  my $dbh;
  if ( -e $dbfile ) {
    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
  }
  else {
    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
    $self->create_database;
  }

  $self->_set_dbh($dbh);
}

#-----------------------------------------------------------------------------

sub _build_dbixclass {

    my $self = shift;

    my $dbfile = $self->dbfile;
    my $dbixclass = GVF::DB::File->connect("dbi:SQLite:$dbfile");

    $self->_set_dbixclass($dbixclass);
}

#-----------------------------------------------------------------------------

sub create_database {
  
  my $self = shift;
  
  my $dbh = $self->dbh;
  
  # check that user has sqlite3
  my $sqlite_check = `sqlite3 -version`;
  if ( ! $sqlite_check ) { croak "sqlite3 is required\n"; }
  
  $dbh->do("PRAGMA foreign_keys = ON");
  
  my $features = 
      'CREATE TABLE "FEATURES"(
	"ID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	"Seqid" VARCHAR(20) NOT NULL,
	"Source" VARCHAR(20) NOT NULL,
	"Type" VARCHAR(20) NOT NULL,
	"Start" INTEGER NOT NULL,
	"End" INTEGER NOT NULL,
	"Score" FLOAT,
	"Strand" VARCHAR(20)
      );';
      
  my $attributes = 
      'CREATE TABLE "ATTRIBUTES"(
	"ID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	"AttributeID" VARCHAR(30) NOT NULL,
	"Alias" VARCHAR(30),
	"DBxref" VARCHAR(30),
	"VariantSeq" VARCHAR(30),
	"ReferenceSeq" VARCHAR(30),
	"VariantReads" VARCHAR(30),
	"TotalReads" VARCHAR(30),
	"Zygosity" VARCHAR(30),
	"VariantFreq" VARCHAR(30),
	"VariantEffect" VARCHAR(30),
	"StartRange" VARCHAR(30),
	"EndRange" VARCHAR(30),
	"Phased" VARCHAR(30),
	"Genotype" VARCHAR(30),
	"Individual" VARCHAR(30),
	"VariantCodon" VARCHAR(30),
	"ReferenceCodon" VARCHAR(30),
	"VariantAA" VARCHAR(30),
	"ReferenceAA" VARCHAR(30),
	"BreakpointDetail" VARCHAR(30),
	"SequenceContext" VARCHAR(30),
	"added_attribute1" VARCHAR(30),
	"added_attribute2" VARCHAR(30),
	"added_attribute3" VARCHAR(30),
	"added_attribute4" VARCHAR(30),
	"added_attribute5" VARCHAR(30),
	"FEATURES_ID" INTEGER NOT NULL,
	CONSTRAINT "fk_ATTRIBUTES_FEATURES"
	  FOREIGN KEY("FEATURES_ID")
	  REFERENCES "FEATURES"("ID")
      );';
 
  my $index = 'CREATE INDEX "ATTRIBUTES.fk_ATTRIBUTES_FEATURES" ON "ATTRIBUTES"("FEATURES_ID");';
  
  $dbh->do( $features ); 
  $dbh->do( $attributes );
  $dbh->do( $index ); 
  
  $dbh->disconnect;
}  

#-----------------------------------------------------------------------------

sub database_add_features {
  my ( $self, $featureList ) = @_;
  
  # grab the dbh.
  my $dbh = $self->dbh;

  my $count = 1;
  foreach my $features ( @$featureList ){

    if ( ! $features->{'seqid'} ) { next }
  
    #load the FEATURE table.
    my $feature_handle = $dbh->prepare('INSERT INTO FEATURES (SeqId, Source, Type, Start, End, Score, Strand ) VALUES (?,?,?,?,?,?,?)');
    $feature_handle->execute(
      $features->{'seqid'},
      $features->{'source'},
      $features->{'type'},
      $features->{'start'},
      $features->{'end'},
      $features->{'score'},
      $features->{'strand'}
      );
    
    # Add all the available attributes to the database.
    my $attributes_handle = $dbh->prepare(
    'INSERT INTO ATTRIBUTES (AttributeID, Alias, DBxref, VariantSeq, ReferenceSeq, VariantReads, TotalReads,
    Zygosity, VariantFreq, VariantEffect, StartRange, EndRange, Phased, Genotype,
    Individual, VariantCodon, ReferenceCodon, VariantAA, BreakpointDetail, SequenceContext, added_attribute1,
    added_attribute2, added_attribute3, added_attribute4, added_attribute5, FEATURES_ID )
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
    
    $attributes_handle->execute(
      $features->{'attribute'}->{'ID'},
      $features->{'attribute'}->{'Alias'},
      $features->{'attribute'}->{'Dbxref'},
      $features->{'attribute'}->{'Variant_seq'},
      $features->{'attribute'}->{'Reference_seq'},
      $features->{'attribute'}->{'Variant_reads'},
      $features->{'attribute'}->{'Total_reads'},
      $features->{'attribute'}->{'Zygosity'},
      $features->{'attribute'}->{'Variant_freq'},
      $features->{'attribute'}->{'Variant_effect'},
      $features->{'attribute'}->{'Start_range'},
      $features->{'attribute'}->{'End_range'},
      $features->{'attribute'}->{'Phased'},
      $features->{'attribute'}->{'Genotype'},
      $features->{'attribute'}->{'Individual'},
      $features->{'attribute'}->{'Variant_codon'},
      $features->{'attribute'}->{'Reference_codon'},
      $features->{'attribute'}->{'Variant_aa'},
      $features->{'attribute'}->{'Breakpoint_detail'},
      $features->{'attribute'}->{'Sequence_context'},
      $features->{'attribute'}->{'added_attribute1'},
      $features->{'attribute'}->{'added_attribute2'},
      $features->{'attribute'}->{'added_attribute3'},
      $features->{'attribute'}->{'added_attribute4'},
      $features->{'attribute'}->{'added_attribute5'},
      $count,
    );
    $count++;
  }
    $dbh->disconnect;
}

#-----------------------------------------------------------------------------

no Moose; 
1;  
